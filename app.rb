require 'deepl'
require 'dotenv/load'

class Deepl
  def initialize
    @client = DeepL.configure do |config|
      config.auth_key = ENV.fetch('DEEPL_AUTH_KEY')
      config.host = 'https://api-free.deepl.com'
    end
  end

  # TODO: 引数で言語を指定できるようにする
  def translate_from_ja_to_en(texts)
    DeepL.translate(texts, 'JA', 'EN')
  end
end

class SrtFile
  def subtitles
    srt_file = File.open('tmp/captions.srt')
    subtitles = []

    srt_file.each_line.with_index do |line, index|
      # 字幕の本文は 2行目 からはじまり、等差が 4 の行目 に出現する
      next unless index % 4 == 2

      # 各業の末尾には "\r\n" が存在するのでそれは削除する
      subtitles << line.chomp
    end

    subtitles
  end

  def translations_to_translation_texts(translations)
    srt_file = File.open('tmp/captions.srt')
    translated_texts = []

    srt_file.each_line.with_index do |line, index|
      # 2, 6, 10... 以外の行の場合はそのまま @srt_file の line をコピーし、
      # そうでない場合は translations の line をコピーするが、その行数目は index を 4 で割った商になる
      translated_texts << (index % 4 == 2 ? translations[index / 4].text : line)
    end

    translated_texts
  end

  def write_to_translated_file(file_path, translated_texts)
    File.open("#{file_path}.translated.srt", 'w') do |file|
      translated_texts.each do |text|
        file.puts text
      end
    end
  end
end

s = SrtFile.new
subtitles = s.subtitles
o = Deepl.new
translations = o.translate_from_ja_to_en(subtitles)
translation_texts = s.translations_to_translation_texts(translations)
s.write_to_translated_file('tmp/captions.srt', translation_texts)
