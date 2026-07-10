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

  # 折り返し（wrap）行のテスト
  # ウィンドウ幅を超える行は、redisplayが画面上で複数行に折り返して表示する。
  # screen_to_buffer_pos は「画面1行 = バッファ1行」という誤った前提を持っていたため、
  # 折り返し2行目以降のクリックが正しいバッファ位置を返さないバグがあった。

  def test_wrapped_line_click_first_row
    @window = create_test_window(width: 20, height: 24)
    @buffer = @window.buffer
    @buffer.insert("a" * 25) # 20カラムで折り返り、2画面行になる
    @buffer.beginning_of_buffer

    pos = @window.screen_to_buffer_pos(0, 5)
    assert_equal(5, pos)
  end

  def test_wrapped_line_click_second_row
    @window = create_test_window(width: 20, height: 24)
    @buffer = @window.buffer
    @buffer.insert("a" * 25)
    @buffer.beginning_of_buffer

    # 折り返り2行目（画面上のy=1）の先頭・途中をクリック
    pos_start = @window.screen_to_buffer_pos(1, 0)
    assert_equal(20, pos_start)

    pos_mid = @window.screen_to_buffer_pos(1, 4)
    assert_equal(24, pos_mid)
  end

  def test_click_on_row_after_wrapped_line
    @window = create_test_window(width: 20, height: 24)
    @buffer = @window.buffer
    @buffer.insert(("a" * 25) + "\nSecond line")
    @buffer.beginning_of_buffer

    # 1行目が折り返って画面2行を占めるので、"Second line" は画面上3行目(y=2)になる
    pos = @window.screen_to_buffer_pos(2, 3)
    assert_equal(25 + 1 + 3, pos) # "a"*25 + "\n" + "Sec" の "o" の直前まで
  end

  def test_wrapped_line_click_with_multibyte_across_boundary
    @window = create_test_window(width: 10, height: 24)
    @buffer = @window.buffer
    @buffer.insert(("a" * 9) + "あ" + "b") # "あ"が幅2のため9カラム目で折り返る
    @buffer.beginning_of_buffer

    # row0 最終カラム（9カラム目、"あ"が入らずブランクになる位置）をクリック
    pos_row0_end = @window.screen_to_buffer_pos(0, 9)
    assert_equal(9, pos_row0_end) # "あ"の開始バイト位置

    # row1 先頭（"あ"の開始位置）をクリック
    pos_row1_start = @window.screen_to_buffer_pos(1, 0)
    assert_equal(9, pos_row1_start)

    # row1 の "あ"の直後（"b"の位置）をクリック
    pos_row1_after_wide_char = @window.screen_to_buffer_pos(1, 2)
    assert_equal(12, pos_row1_after_wide_char) # "a"*9(9バイト) + "あ"(3バイト)
  end
end
