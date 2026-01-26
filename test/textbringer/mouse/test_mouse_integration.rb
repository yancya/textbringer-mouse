# frozen_string_literal: true

require "test_helper"

# 統合テスト: マウスイベント処理の基本的な動作をテスト
# NOTE: これらのテストは、実際のWindow#get_charの内部実装に依存するため、
# handle_mouse_event メソッドを直接呼び出すことでテストする
class TestMouseIntegration < MouseTestCase
  def setup
    super
    @window = create_test_window(content: "Line 1\nLine 2\nLine 3")
    @buffer = @window.buffer
  end

  def test_handle_mouse_click_moves_cursor
    @buffer.beginning_of_buffer

    # 初期位置は先頭
    assert_equal(0, @buffer.point)

    # クリックイベントを注入（Line 1の "1" の位置、x=5, y=0）
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_CLICKED,
      x: 5,
      y: 0
    )

    # handle_mouse_event を直接呼び出す
    @window.send(:handle_mouse_event)

    # カーソルがクリック位置に移動しているか確認
    assert_equal(5, @buffer.point)
  end

  def test_handle_mouse_click_with_button1_pressed
    @buffer.beginning_of_buffer

    # BUTTON1_PRESSEDでもカーソル移動するか確認
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_PRESSED,
      x: 3,
      y: 0
    )

    @window.send(:handle_mouse_event)

    assert_equal(3, @buffer.point)
  end

  def test_handle_mouse_click_with_button1_released
    @buffer.beginning_of_buffer

    # BUTTON1_RELEASEDでもカーソル移動するか確認
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_RELEASED,
      x: 2,
      y: 0
    )

    @window.send(:handle_mouse_event)

    assert_equal(2, @buffer.point)
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
    @buffer.beginning_of_buffer

    # 2行目の先頭をクリック（y=1, x=0）
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_CLICKED,
      x: 0,
      y: 1
    )

    @window.send(:handle_mouse_event)

    # "Line 1\n" = 7文字後の位置
    assert_equal(7, @buffer.point)
  end

  def test_handle_mouse_click_switches_window_focus
    # ウィンドウ2つ作成
    window1 = @window
    window2 = create_test_window(
      name: "*test2*",
      width: 80,
      height: 12,
      x: 0,
      y: 12,
      content: "Window 2 content"
    )

    # window1をアクティブにする
    Window.instance_variable_set(:@current, window1)
    Buffer.instance_variable_set(:@current, window1.buffer)

    # window2の座標をクリック（y=12はwindow2の先頭行）
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_CLICKED,
      x: 5,
      y: 12
    )

    # window1 からマウスイベントを処理
    window1.send(:handle_mouse_event)

    # フォーカスがwindow2に切り替わっているか
    assert_equal(window2, Window.current)
  end

  def test_handle_mouse_click_outside_windows
    initial_point = @buffer.point

    # ウィンドウの範囲外（y=100）をクリック
    Curses.push_mouse_event(
      bstate: Curses::BUTTON1_CLICKED,
      x: 0,
      y: 100
    )

    @window.send(:handle_mouse_event)

    # カーソル位置は変わらない
    assert_equal(initial_point, @buffer.point)
  end

  def test_mousemask_initialization
    # プラグインロード時に mousemask が呼ばれているか確認
    # test_helper.rb で Curses.mousemask が呼ばれた記録を確認
    expected_mask = Curses::ALL_MOUSE_EVENTS | Curses::REPORT_MOUSE_POSITION

    # プラグインロード時に設定されたマスクを確認
    # （lib/textbringer/mouse.rb:17 で Curses.mousemask が呼ばれている）
    assert_equal(expected_mask, Curses.mouse_mask)
  end

  def test_screen_to_buffer_pos_returns_nil_for_modeline
    # モードライン（最終行）をクリックした場合、nil が返されるか確認
    modeline_y = @window.y + @window.lines - 1
    pos = @window.screen_to_buffer_pos(modeline_y, 0)
    assert_nil(pos)
  end
end
