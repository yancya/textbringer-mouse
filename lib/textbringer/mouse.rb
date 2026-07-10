# frozen_string_literal: true

require "textbringer"
require_relative "mouse/version"

# BUTTON5_PRESSED が定義されていない環境用の定義
# 通常はスクロールダウン用だが、環境によっては未定義
module Curses
  BUTTON5_PRESSED = 0x8000000 unless defined?(BUTTON5_PRESSED)
end

module Textbringer
  # ホイール1ノッチあたりのスクロール行数。0/nil でページ単位スクロールにフォールバック
  CONFIG[:mouse_wheel_scroll_lines] ||= 3
end

module Textbringer
  module Mouse
    # Mouse機能を初期化
  end

  # Window#get_charの拡張 - マウスイベント検出
  module WindowMouseExtension
    def get_char
      key = super

      if key == Curses::KEY_MOUSE
        handle_mouse_event

        # マウスイベント処理後に画面を再描画
        Window.redisplay

        return nil  # マウスイベントは通常のキーとして処理しない
      end

      key
    end

    # マウスイベントハンドラ
    def handle_mouse_event
      # Ruby 4.0のcursesライブラリの警告を抑制
      # "warning: undefining the allocator of T_DATA class Curses::MouseEvent"
      old_verbose = $VERBOSE
      $VERBOSE = nil
      event = Curses.getmouse
      $VERBOSE = old_verbose

      x = event.x
      y = event.y
      bstate = event.bstate

      # スクロール処理
      if bstate & Curses::BUTTON4_PRESSED != 0
        handle_mouse_scroll_up
        return
      elsif bstate & Curses::BUTTON5_PRESSED != 0
        handle_mouse_scroll_down
        return
      end

      # ダブルクリック処理
      if bstate & Curses::BUTTON1_DOUBLE_CLICKED != 0
        handle_double_click(y, x)
        return
      end

      # トリプルクリック処理
      if bstate & Curses::BUTTON1_TRIPLE_CLICKED != 0
        handle_triple_click(y, x)
        return
      end

      # 右クリック処理
      if bstate & Curses::BUTTON3_CLICKED != 0
        handle_right_click(y, x)
        return
      end

      # 左クリック処理 (CLICKED, PRESSED, RELEASEDのいずれかで反応)
      if (bstate & Curses::BUTTON1_CLICKED != 0) ||
         (bstate & Curses::BUTTON1_PRESSED != 0) ||
         (bstate & Curses::BUTTON1_RELEASED != 0)
        handle_mouse_click(y, x)
      end
    end

    # マウススクロール処理 - 上にスクロール（内容を下に = top_of_windowを後方へ）
    def handle_mouse_scroll_up
      lines = CONFIG[:mouse_wheel_scroll_lines]
      if lines && lines > 0
        scroll_window_by_lines(-lines)
      else
        begin
          Commands.scroll_down
        rescue RangeError
          # バッファの先頭に到達
        end
      end
    end

    # マウススクロール処理 - 下にスクロール（内容を上に = top_of_windowを前方へ）
    def handle_mouse_scroll_down
      lines = CONFIG[:mouse_wheel_scroll_lines]
      if lines && lines > 0
        scroll_window_by_lines(lines)
      else
        begin
          Commands.scroll_up
        rescue RangeError
          # バッファの末尾に到達
        end
      end
    end

    # top_of_window を n行分（負値で後方へ）動かす。
    # Buffer#forward_line はバッファ端で例外を出さず可能な範囲まで進むので、
    # 境界での安全なノーオペレーションが自然に得られる。
    def scroll_window_by_lines(n)
      return if @buffer.nil?

      @buffer.save_point do
        @buffer.point_to_mark(@top_of_window)
        @buffer.forward_line(n)
        @buffer.mark_to_point(@top_of_window)
      end

      # 下スクロールでpointが画面外(上)に隠れた場合、Emacs風にpointを
      # 新しいtop_of_windowへ追従させる。上スクロールでpointが下端の外に
      # 出るケースは、ここでは扱わない — Window#redisplay は呼び出しの都度
      # Window#framer (shugo/textbringer lib/textbringer/window.rb) を実行し、
      # pointが可視範囲外ならtop_of_windowを自動的に前進/後退させて再度
      # pointを可視化するため、次の再描画で自然に解消される（v1の既知の制約）。
      if @buffer.point_before_mark?(@top_of_window)
        @buffer.point_to_mark(@top_of_window)
      end
    end

    # マウスクリック処理
    def handle_mouse_click(screen_y, screen_x)
      # クリックされたウィンドウを検索
      window = Window.list(include_echo_area: true).find do |w|
        w.y <= screen_y && screen_y < w.y + w.lines &&
          w.x <= screen_x && screen_x < w.x + w.columns
      end

      return unless window
      return if window.echo_area?  # エコーエリアは無視

      # ウィンドウをアクティブにする
      Window.current = window unless window.current?

      # バッファ位置を計算してカーソルを移動
      pos = window.screen_to_buffer_pos(screen_y, screen_x)
      Buffer.current.goto_char(pos) if pos
    end

    # ダブルクリック処理 - 単語選択
    def handle_double_click(screen_y, screen_x)
      window = find_window_at(screen_y, screen_x)
      return unless window

      pos = window.screen_to_buffer_pos(screen_y, screen_x)
      return unless pos

      buffer = Buffer.current
      buffer.goto_char(pos)

      # 単語の範囲を選択
      buffer.backward_word
      Commands.push_mark
      buffer.forward_word
    end

    # トリプルクリック処理 - 行選択
    def handle_triple_click(screen_y, screen_x)
      window = find_window_at(screen_y, screen_x)
      return unless window

      pos = window.screen_to_buffer_pos(screen_y, screen_x)
      return unless pos

      buffer = Buffer.current
      buffer.goto_char(pos)

      # 行の範囲を選択
      buffer.beginning_of_line
      Commands.push_mark
      buffer.end_of_line
    end

    # 右クリック処理 - 単語選択（ダブルクリックと同じ動作）
    def handle_right_click(screen_y, screen_x)
      handle_double_click(screen_y, screen_x)
    end

    # ウィンドウ検索ヘルパー
    def find_window_at(screen_y, screen_x)
      window = Window.list(include_echo_area: true).find do |w|
        w.y <= screen_y && screen_y < w.y + w.lines &&
          w.x <= screen_x && screen_x < w.x + w.columns
      end

      return nil unless window
      return nil if window.echo_area?

      # ウィンドウをアクティブにする
      Window.current = window unless window.current?

      window
    end

    # 座標変換 - スクリーン座標からバッファ位置へ
    #
    # redisplay (shugo/textbringer lib/textbringer/window.rb) は
    # ウィンドウ幅を超える行を画面上で折り返して表示するため、
    # 「画面1行 = バッファ1行」ではない。折り返しを再現しながら
    # 対象の画面行の先頭まで進めたうえで、列方向に走査する。
    def screen_to_buffer_pos(screen_y, screen_x)
      # ウィンドウ相対座標
      rel_y = screen_y - @y
      rel_x = screen_x - @x

      # モードライン上のクリックは無視
      return nil if rel_y >= @lines - 1

      @buffer.save_point do
        # top_of_windowから開始
        @buffer.point_to_mark(@top_of_window)

        # 対象の画面行の先頭まで、折り返しを考慮して進める
        cury = 0
        curx = 0
        until @buffer.end_of_buffer? || cury == rel_y
          c = @buffer.char_after
          if c == "\n"
            cury += 1
            curx = 0
            @buffer.forward_char
            next
          end

          width = c == "\t" ? calc_tab_width(curx) : Buffer.display_width(c)
          if curx + width > @columns
            # 折り返り: この文字は次の画面行の先頭に描画される
            cury += 1
            curx = 0
            next
          end

          curx += width
          @buffer.forward_char
        end

        # 対象の画面行内をX列分進む（表示幅・折り返りを考慮）
        display_col = 0
        while display_col < rel_x && !@buffer.end_of_line? && !@buffer.end_of_buffer?
          c = @buffer.char_after
          width = c == "\t" ? calc_tab_width(display_col) : Buffer.display_width(c)

          break if display_col + width > @columns   # この画面行の折り返り境界
          break if display_col + width > rel_x

          display_col += width
          @buffer.forward_char
        end

        @buffer.point
      end
    end
  end

  Window.prepend(WindowMouseExtension)

  # Window.startをフックして、Curses初期化後にマウスを有効化
  class << Window
    alias_method :original_start, :start

    def start(&block)
      original_start do
        # Curses.init_screen後にマウスを有効化
        Curses.mousemask(Curses::ALL_MOUSE_EVENTS | Curses::REPORT_MOUSE_POSITION)

        block.call
      end
    end
  end
end
