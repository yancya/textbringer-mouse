# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "textbringer"
require "textbringer/mouse"

# Cursesモック機能の実装
# textbringerのテストインフラを参考にしつつ、マウスイベント機能を拡張

module Curses
  # マウス定数（未定義の場合に定義）
  KEY_MOUSE = 409 unless defined?(KEY_MOUSE)

  BUTTON1_PRESSED = 0x2 unless defined?(BUTTON1_PRESSED)
  BUTTON1_RELEASED = 0x1 unless defined?(BUTTON1_RELEASED)
  BUTTON1_CLICKED = 0x4 unless defined?(BUTTON1_CLICKED)
  BUTTON4_PRESSED = 0x8 unless defined?(BUTTON4_PRESSED)    # スクロール上
  BUTTON5_PRESSED = 0x80 unless defined?(BUTTON5_PRESSED)   # スクロール下

  ALL_MOUSE_EVENTS = 0xfffffff unless defined?(ALL_MOUSE_EVENTS)
  REPORT_MOUSE_POSITION = 0x8000000 unless defined?(REPORT_MOUSE_POSITION)

  # マウスイベントキュー
  @mouse_event_queue = []
  @mouse_mask = 0

  class << self
    attr_accessor :mouse_event_queue, :mouse_mask

    # マウスマスク設定（モック）
    def mousemask(mask)
      @mouse_mask = mask
      mask  # 成功時はマスクを返す
    end

    # マウスイベント取得（モック）
    def getmouse
      if @mouse_event_queue.empty?
        raise "No mouse event in queue"
      end
      @mouse_event_queue.shift
    end

    # テスト用：マウスイベントをキューに追加
    def push_mouse_event(bstate:, x:, y:, id: 0, z: 0)
      @mouse_event_queue << [id, x, y, z, bstate]
    end
  end
end

# ミニマルなテストケースベースクラス
require "test/unit"

class MouseTestCase < Test::Unit::TestCase
  include Textbringer

  def setup
    # 各テスト前にマウスイベントキューをクリア
    Curses.mouse_event_queue.clear

    # Bufferの初期化
    Buffer.instance_variable_set(:@list, [])
    Buffer.instance_variable_set(:@current, nil)

    # Windowの初期化
    Window.instance_variable_set(:@list, [])
    Window.instance_variable_set(:@current, nil)
  end

  def teardown
    Curses.mouse_event_queue.clear

    # 後片付け
    Buffer.instance_variable_set(:@list, [])
    Buffer.instance_variable_set(:@current, nil)
    Window.instance_variable_set(:@list, [])
    Window.instance_variable_set(:@current, nil)
  end

  # テスト用の簡易Window/Buffer生成ヘルパー
  def create_test_window(name: "*test*", width: 80, height: 24, x: 0, y: 0, content: nil)
    buffer = Buffer.new_buffer(name)
    buffer.insert(content) if content
    buffer.beginning_of_buffer

    # Window.new(lines, columns, y, x) の順番で引数を渡す
    window = Window.new(height, width, y, x)
    window.buffer = buffer

    # top_of_windowを設定
    window.instance_variable_set(:@top_of_window, buffer.new_mark)

    Window.instance_variable_get(:@list) << window
    Window.instance_variable_set(:@current, window)
    Buffer.instance_variable_set(:@current, buffer)

    window
  end
end
