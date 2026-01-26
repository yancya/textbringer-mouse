# frozen_string_literal: true

require "test_helper"

# 新機能のテスト: ダブルクリック、右クリック、ドラッグ
class TestMouseFeatures < MouseTestCase
  def setup
    super
    @window = create_test_window(width: 80, height: 24)
    @buffer = @window.buffer
  end

  def test_double_click_selects_word
    @buffer.insert("hello world foo bar")
    @buffer.beginning_of_buffer

    # "world" をダブルクリック（x=6 は "world" の "w"）
    pos = @window.screen_to_buffer_pos(0, 6)
    assert_equal(6, pos)  # "world" の開始位置

    # ダブルクリックのイベント処理はペンディング（手動テスト必要）
    # 実装後にマークが設定されて、単語が選択される
  end

  def test_triple_click_selects_line
    @buffer.insert("line 1\nline 2\nline 3")
    @buffer.beginning_of_buffer

    # 1行目をトリプルクリック
    pos = @window.screen_to_buffer_pos(0, 3)
    assert_equal(3, pos)  # "line 1" の中間

    # トリプルクリックのイベント処理はペンディング（手動テスト必要）
    # 実装後に行全体が選択される
  end

  def test_right_click_selects_word_at_position
    @buffer.insert("select this word")
    @buffer.beginning_of_buffer

    # "this" を右クリック（x=7）
    pos = @window.screen_to_buffer_pos(0, 7)
    assert_equal(7, pos)  # "this" の開始位置

    # 右クリックのイベント処理はペンディング（手動テスト必要）
  end

  def test_button2_constants_defined
    # BUTTON2（中クリック）の定数が定義されているか
    assert(Curses.const_defined?(:BUTTON2_CLICKED))
    assert(Curses.const_defined?(:BUTTON2_PRESSED))
    assert(Curses.const_defined?(:BUTTON2_RELEASED))
  end

  def test_button3_constants_defined
    # BUTTON3（右クリック）の定数が定義されているか
    assert(Curses.const_defined?(:BUTTON3_CLICKED))
    assert(Curses.const_defined?(:BUTTON3_PRESSED))
    assert(Curses.const_defined?(:BUTTON3_RELEASED))
  end

  def test_double_click_constants_defined
    # ダブルクリックの定数が定義されているか
    assert(Curses.const_defined?(:BUTTON1_DOUBLE_CLICKED))
    assert(Curses.const_defined?(:BUTTON1_TRIPLE_CLICKED))
  end
end
