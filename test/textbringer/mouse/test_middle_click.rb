# frozen_string_literal: true

require "test_helper"

# 中クリックペースト（yank at click）のテスト
class TestMiddleClick < MouseTestCase
  def setup
    super
    @window = create_test_window(width: 80, height: 24, content: "abc   xyz")
    @buffer = @window.buffer
    KILL_RING.clear
  end

  def teardown
    super
    KILL_RING.clear
  end

  def test_middle_click_moves_point_and_yanks
    KILL_RING.push("HELLO")

    # "xyz" の "x" (x=6) を中クリック
    Curses.push_mouse_event(bstate: Curses::BUTTON2_CLICKED, x: 6, y: 0)
    @window.send(:handle_mouse_event)

    assert_equal("abc   HELLOxyz", @buffer.to_s)
    assert_equal(6 + "HELLO".bytesize, @buffer.point)
  end

  def test_middle_click_with_empty_kill_ring_moves_point_without_crash
    # KILL_RINGは空 (setupでclear済み)
    assert_nothing_raised do
      Curses.push_mouse_event(bstate: Curses::BUTTON2_CLICKED, x: 6, y: 0)
      @window.send(:handle_mouse_event)
    end

    assert_equal("abc   xyz", @buffer.to_s) # 挿入は起きない
    assert_equal(6, @buffer.point) # pointはクリック位置まで移動している
  end

  def test_middle_click_on_modeline_does_not_yank
    KILL_RING.push("HELLO")
    modeline_y = @window.y + @window.lines - 1

    Curses.push_mouse_event(bstate: Curses::BUTTON2_CLICKED, x: 0, y: modeline_y)
    @window.send(:handle_mouse_event)

    assert_equal("abc   xyz", @buffer.to_s)
  end

  def test_button2_clicked_dispatches_to_middle_click_handler
    called_with = nil
    @window.define_singleton_method(:handle_middle_click) do |y, x|
      called_with = [y, x]
    end

    Curses.push_mouse_event(bstate: Curses::BUTTON2_CLICKED, x: 3, y: 0)
    @window.send(:handle_mouse_event)

    assert_equal([0, 3], called_with)
  end
end
