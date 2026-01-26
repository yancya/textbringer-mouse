# frozen_string_literal: true

require "textbringer"
require_relative "mouse/version"

# BUTTON5_PRESSED が定義されていない環境用の定義
# 通常はスクロールダウン用だが、環境によっては未定義
module Curses
  BUTTON5_PRESSED = 0x8000000 unless defined?(BUTTON5_PRESSED)
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

    # マウススクロール処理 - 上にスクロール
    def handle_mouse_scroll_up
      begin
        Commands.scroll_down  # 画面を上にスクロール = 内容を下に
      rescue RangeError
        # バッファの先頭に到達
      end
    end

    # マウススクロール処理 - 下にスクロール
    def handle_mouse_scroll_down
      begin
        Commands.scroll_up  # 画面を下にスクロール = 内容を上に
      rescue RangeError
        # バッファの末尾に到達
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
    def screen_to_buffer_pos(screen_y, screen_x)
      # ウィンドウ相対座標
      rel_y = screen_y - @y
      rel_x = screen_x - @x

      # モードライン上のクリックは無視
      return nil if rel_y >= @lines - 1

      @buffer.save_point do
        # top_of_windowから開始
        @buffer.point_to_mark(@top_of_window)

        # Y行分進む
        rel_y.times do
          break if @buffer.end_of_buffer?
          @buffer.end_of_line
          @buffer.forward_char  # 改行を越える
        end

        # X列分進む（表示幅を考慮）
        @buffer.beginning_of_line
        display_col = 0
        while display_col < rel_x && !@buffer.end_of_line?
          c = @buffer.char_after
          if c == "\t"
            width = calc_tab_width(display_col)
          else
            width = Buffer.display_width(c)
          end

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
