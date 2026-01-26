# frozen_string_literal: true

require "test_helper"

# 統合テスト: マウスイベント処理の基本的な動作をテスト
# NOTE: 一部のテストはtextbringerの内部実装に深く依存するため、
# 実際のマウス操作による動作確認が必要です。
# ここでは基本的なメソッドの呼び出しと、モック可能な範囲のテストのみ実施。
class TestMouseIntegration < MouseTestCase
  def setup
    super
    @window = create_test_window(content: "Line 1\nLine 2\nLine 3")
    @buffer = @window.buffer
  end

  def test_handle_mouse_click_moves_cursor
    # このテストはWindow.listの内部実装に依存するためスキップ
    # 実際の動作確認はマニュアルテストで行う
    pend "Requires full Window/Buffer initialization"
  end

  def test_handle_mouse_click_with_button1_pressed
    pend "Requires full Window/Buffer initialization"
  end

  def test_handle_mouse_click_with_button1_released
    pend "Requires full Window/Buffer initialization"
  end

  def test_handle_mouse_scroll_up
    # スクロール上（内容を下に）イベント
    Curses.push_mouse_event(
      bstate: Curses::BUTTON4_PRESSED,
      x: 0,
      y: 0
    )

    # Commands.scroll_downが呼ばれることを確認するため、モックを用意
    scroll_down_called = false
    original_scroll_down = Commands.method(:scroll_down) rescue nil

    Commands.define_singleton_method(:scroll_down) do
      scroll_down_called = true
    end

    @window.send(:handle_mouse_event)

    assert(scroll_down_called, "Commands.scroll_down should be called")

    # 後片付け
    if original_scroll_down
      Commands.define_singleton_method(:scroll_down, original_scroll_down)
    end
  end

  def test_handle_mouse_scroll_down
    # スクロール下（内容を上に）イベント
    Curses.push_mouse_event(
      bstate: Curses::BUTTON5_PRESSED,
      x: 0,
      y: 0
    )

    # Commands.scroll_upが呼ばれることを確認
    scroll_up_called = false
    original_scroll_up = Commands.method(:scroll_up) rescue nil

    Commands.define_singleton_method(:scroll_up) do
      scroll_up_called = true
    end

    @window.send(:handle_mouse_event)

    assert(scroll_up_called, "Commands.scroll_up should be called")

    # 後片付け
    if original_scroll_up
      Commands.define_singleton_method(:scroll_up, original_scroll_up)
    end
  end

  def test_handle_mouse_click_on_second_line
    pend "Requires full Window/Buffer initialization"
  end

  def test_handle_mouse_click_switches_window_focus
    pend "Requires full Window/Buffer initialization"
  end

  def test_handle_mouse_click_outside_windows
    pend "Requires full Window/Buffer initialization"
  end

  def test_mousemask_initialization
    # プラグインロード時に mousemask が呼ばれているか確認
    # lib/textbringer/mouse.rb:7 で Curses.mousemask が呼ばれている
    expected_mask = Curses::ALL_MOUSE_EVENTS | Curses::REPORT_MOUSE_POSITION

    # Curses.mousemask はモックで実装されており、呼び出されると値を保存する
    # プラグインがロードされた時点で既に呼ばれているはず
    assert_equal(expected_mask, Curses.mouse_mask)
  end

  def test_screen_to_buffer_pos_returns_nil_for_modeline
    # モードライン（最終行）をクリックした場合、nil が返されるか確認
    modeline_y = @window.y + @window.lines - 1
    pos = @window.screen_to_buffer_pos(modeline_y, 0)
    assert_nil(pos)
  end
end
