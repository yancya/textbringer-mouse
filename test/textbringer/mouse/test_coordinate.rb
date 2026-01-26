# frozen_string_literal: true

require "test_helper"

class TestMouseCoordinate < MouseTestCase
  def setup
    super
    @window = create_test_window(width: 80, height: 24)
    @buffer = @window.buffer
  end

  def test_simple_text_click
    @buffer.insert("Hello World")
    @buffer.beginning_of_buffer

    # (0, 6) = "W"の位置をクリック
    pos = @window.screen_to_buffer_pos(0, 6)
    assert_equal(6, pos)
  end

  def test_click_at_beginning
    @buffer.insert("Hello World")
    @buffer.beginning_of_buffer

    # (0, 0) = "H"の位置をクリック
    pos = @window.screen_to_buffer_pos(0, 0)
    assert_equal(0, pos)
  end

  def test_click_at_end_of_line
    @buffer.insert("Hello")
    @buffer.beginning_of_buffer

    # (0, 5) = 行末（末尾の次）をクリック
    pos = @window.screen_to_buffer_pos(0, 5)
    assert_equal(5, pos)
  end

  def test_tab_character_handling
    @buffer.insert("abc\tdef")  # タブは8カラム幅と仮定
    @buffer.beginning_of_buffer

    # タブ後の "d" をクリック（表示上x=8の位置）
    pos = @window.screen_to_buffer_pos(0, 8)
    assert_equal(4, pos)  # "d"のバッファ位置
  end

  def test_tab_character_click_before_expansion
    @buffer.insert("abc\tdef")
    @buffer.beginning_of_buffer

    # タブ文字自体をクリック（x=3-7の範囲）
    pos = @window.screen_to_buffer_pos(0, 4)
    assert_equal(3, pos)  # タブ文字の位置で止まる
  end

  def test_multibyte_character_click
    @buffer.insert("あいうえお")
    @buffer.beginning_of_buffer

    # "う"をクリック（全角2カラム幅 × 2文字 = x=4）
    # UTF-8では1文字3バイト: あ(0-2), い(3-5), う(6-8)
    pos = @window.screen_to_buffer_pos(0, 4)
    assert_equal(6, pos)  # "う"のバッファ位置（バイトオフセット）
  end

  def test_multibyte_character_first_column
    @buffer.insert("あいうえお")
    @buffer.beginning_of_buffer

    # "あ"の最初のカラムをクリック
    pos = @window.screen_to_buffer_pos(0, 0)
    assert_equal(0, pos)
  end

  def test_multibyte_character_second_column
    @buffer.insert("あいうえお")
    @buffer.beginning_of_buffer

    # "あ"の2番目のカラムをクリック（x=1）
    # 文字の途中なので文字の先頭で止まる
    pos = @window.screen_to_buffer_pos(0, 1)
    assert_equal(0, pos)  # "あ"のバッファ位置（バイトオフセット）
  end

  def test_multiline_click_first_line
    @buffer.insert("line1\nline2\nline3")
    @buffer.beginning_of_buffer

    # 1行目の "i" をクリック
    pos = @window.screen_to_buffer_pos(0, 1)
    assert_equal(1, pos)  # "i"
  end

  def test_multiline_click_second_line
    @buffer.insert("line1\nline2\nline3")
    @buffer.beginning_of_buffer

    # 2行目の "i" をクリック
    pos = @window.screen_to_buffer_pos(1, 1)
    assert_equal(7, pos)  # "line1\n" + "i"
  end

  def test_multiline_click_third_line
    @buffer.insert("line1\nline2\nline3")
    @buffer.beginning_of_buffer

    # 3行目の "i" をクリック
    pos = @window.screen_to_buffer_pos(2, 1)
    assert_equal(13, pos)  # "line1\nline2\n" + "i"
  end

  def test_modeline_click_returns_nil
    @buffer.insert("test")
    @buffer.beginning_of_buffer

    # モードライン（最終行）をクリック
    modeline_y = @window.instance_variable_get(:@y) + @window.instance_variable_get(:@lines) - 1
    pos = @window.screen_to_buffer_pos(modeline_y, 0)
    assert_nil(pos)
  end

  def test_click_beyond_line_length
    @buffer.insert("short")
    @buffer.beginning_of_buffer

    # 行の長さを超えた位置をクリック
    pos = @window.screen_to_buffer_pos(0, 100)
    assert_equal(5, pos)  # 行末で止まる
  end

  def test_empty_buffer_click
    # 空のバッファでクリック
    pos = @window.screen_to_buffer_pos(0, 0)
    assert_equal(0, pos)  # バッファの先頭
  end

  def test_click_with_mixed_content
    @buffer.insert("ab\tあい\tcd")
    @buffer.beginning_of_buffer

    # タブと全角文字が混在する行で "c" をクリック
    # "ab\t" = 2 + 6(tab padding) = 8 (バイト: 3)
    # "あい\t" = 4 + 4(tab padding) = 8 (バイト: 6+1)
    # 合計 x=16 で "c" (バイト: 3 + 6 + 1 = 10)
    pos = @window.screen_to_buffer_pos(0, 16)
    assert_equal(10, pos)  # "c"の位置（バイトオフセット）
  end
end
