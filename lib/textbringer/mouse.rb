# frozen_string_literal: true

require "textbringer"
require_relative "mouse/version"

# プラグインロード時にマウスを有効化
Curses.mousemask(Curses::ALL_MOUSE_EVENTS | Curses::REPORT_MOUSE_POSITION)

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
        return nil  # マウスイベントは通常のキーとして処理しない
      end

      key
    end

    # マウスイベントハンドラ
    def handle_mouse_event
      _id, x, y, _z, bstate = Curses.getmouse

      # スクロール処理
      if bstate & Curses::BUTTON4_PRESSED != 0
        handle_mouse_scroll_up
        return
      elsif bstate & Curses::BUTTON5_PRESSED != 0
        handle_mouse_scroll_down
        return
      end

      # クリック処理 (CLICKED, PRESSED, RELEASEDのいずれかで反応)
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
end
