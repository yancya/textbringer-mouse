# frozen_string_literal: true

require "test_helper"

# モードラインクリックによるウィンドウフォーカス切り替えのテスト
class TestModeLineClick < MouseTestCase
  def setup
    super
    @window_a = create_test_window(name: "a", height: 12, y: 0, content: "a1\na2\na3")
    @window_b = create_test_window(name: "b", height: 12, y: 12, content: "b1\nb2\nb3")
    # create_test_window は呼ぶたびに Window.current を更新するので、
    # 直近に作った window_b が現在アクティブなウィンドウになっている
  end

  def modeline_y(window)
    window.y + window.lines - 1
  end

  def test_click_on_modeline_of_other_window_focuses_it
    refute(@window_a.current?)

    Curses.push_mouse_event(bstate: Curses::BUTTON1_CLICKED, x: 0, y: modeline_y(@window_a))
    @window_a.send(:handle_mouse_event)

    assert(@window_a.current?)
  end

  def test_click_on_modeline_does_not_move_point
    @window_b.buffer.beginning_of_buffer
    @window_b.buffer.forward_char(1)
    point_before = @window_b.buffer.point

    Curses.push_mouse_event(bstate: Curses::BUTTON1_CLICKED, x: 0, y: modeline_y(@window_b))
    @window_b.send(:handle_mouse_event)

    assert_equal(point_before, @window_b.buffer.point)
  end

  def test_click_on_modeline_of_current_window_is_noop_focus_wise
    assert(@window_b.current?)

    Curses.push_mouse_event(bstate: Curses::BUTTON1_CLICKED, x: 0, y: modeline_y(@window_b))
    assert_nothing_raised do
      @window_b.send(:handle_mouse_event)
    end

    assert(@window_b.current?)
  end

  def test_double_click_on_modeline_does_not_select
    @window_a.buffer.insert("hello world")
    @window_a.buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON1_DOUBLE_CLICKED, x: 0, y: modeline_y(@window_a))
    @window_a.send(:handle_mouse_event)

    assert(@window_a.current?)
    refute(@window_a.buffer.mark_active)
  end

  def test_triple_click_on_modeline_does_not_select
    @window_a.buffer.insert("hello world")
    @window_a.buffer.beginning_of_buffer

    Curses.push_mouse_event(bstate: Curses::BUTTON1_TRIPLE_CLICKED, x: 0, y: modeline_y(@window_a))
    @window_a.send(:handle_mouse_event)

    assert(@window_a.current?)
    refute(@window_a.buffer.mark_active)
  end

  def test_window_at_has_no_focus_side_effect
    refute(@window_a.current?)

    found = @window_b.send(:window_at, modeline_y(@window_a), 0)

    assert_equal(@window_a, found)
    refute(@window_a.current?) # window_at自体はフォーカスを変えない
  end
end
