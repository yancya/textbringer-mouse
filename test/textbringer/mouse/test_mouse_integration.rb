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

  def test_handle_mouse_scroll_up_moves_top_of_window_up_by_default_lines
    # 7行のバッファで、top_of_windowを3行目の先頭にしておく
    @buffer.insert("\nLine A\nLine B\nLine C\nLine D\nLine E\nLine F")
    @buffer.beginning_of_buffer
    @buffer.forward_line(3)
    @window.top_of_window.location = @buffer.point

    Curses.push_mouse_event(bstate: Curses::BUTTON4_PRESSED, x: 0, y: 0)
    @window.send(:handle_mouse_event)

    assert_equal(0, @window.top_of_window.location)
  end

  def test_handle_mouse_scroll_down_moves_top_of_window_down_by_default_lines
    @buffer.insert("Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7")
    @buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON5_PRESSED, x: 0, y: 0)
    @window.send(:handle_mouse_event)

    @buffer.beginning_of_buffer
    @buffer.forward_line(CONFIG[:mouse_wheel_scroll_lines])
    assert_equal(@buffer.point, @window.top_of_window.location)
  end

  def test_handle_mouse_scroll_down_drags_point_when_hidden_above_new_top
    # pointがバッファ先頭のまま下スクロールすると、新しいtop_of_windowより
    # 前(画面外)に隠れてしまうため、Emacs風にpointが追従するはず
    @buffer.insert("Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7")
    @buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON5_PRESSED, x: 0, y: 0)
    @window.send(:handle_mouse_event)

    assert_equal(@window.top_of_window.location, @buffer.point)
  end

  def test_handle_mouse_scroll_up_is_safe_noop_at_buffer_top
    @buffer.insert("Line 1\nLine 2\nLine 3")
    @buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON4_PRESSED, x: 0, y: 0)
    assert_nothing_raised do
      @window.send(:handle_mouse_event)
    end
    assert_equal(0, @window.top_of_window.location)
  end

  def test_handle_mouse_scroll_down_is_safe_at_buffer_bottom
    @buffer.insert("Line 1\nLine 2")
    @buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON5_PRESSED, x: 0, y: 0)
    assert_nothing_raised do
      @window.send(:handle_mouse_event)
    end
    # 2行しかないバッファなので、規定の3行分は進めずバッファ末尾までしか進まない
    assert(@window.top_of_window.location <= @buffer.bytesize)
  end

  def test_handle_mouse_scroll_falls_back_to_page_scroll_when_config_disabled
    original = CONFIG[:mouse_wheel_scroll_lines]
    CONFIG[:mouse_wheel_scroll_lines] = 0
    begin
      @buffer.insert("Line 1\nLine 2\nLine 3")
      @buffer.beginning_of_buffer

      Curses.push_mouse_event(bstate: Curses::BUTTON4_PRESSED, x: 0, y: 0)

      scroll_down_called = false
      original_scroll_down = Commands.method(:scroll_down)
      Commands.define_singleton_method(:scroll_down) { scroll_down_called = true }

      @window.send(:handle_mouse_event)

      assert(scroll_down_called, "Commands.scroll_down should be called when CONFIG[:mouse_wheel_scroll_lines] is 0")

      Commands.define_singleton_method(:scroll_down, original_scroll_down)
    ensure
      CONFIG[:mouse_wheel_scroll_lines] = original
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
    # Window.start時に mousemask が呼ばれるように変更されたため、
    # このテストはペンディング（実際のWindow.start実行が必要）
    pend "Requires Window.start to be called"
  end

  def test_screen_to_buffer_pos_returns_nil_for_modeline
    # モードライン（最終行）をクリックした場合、nil が返されるか確認
    modeline_y = @window.y + @window.lines - 1
    pos = @window.screen_to_buffer_pos(modeline_y, 0)
    assert_nil(pos)
  end
end
