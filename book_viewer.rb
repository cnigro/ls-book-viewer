require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @toc = File.readlines("./data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def strong(text)
    text.gsub!(params[:query], "<strong>#{params[:query]}</strong>")
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:chapter" do |chp|
  @chp = chp.to_i
  @name = @toc[@chp - 1]

  redirect "/" unless (1..@toc.size).cover? @chp

  @title = "Chapter #{chp}: #{@name}"
  
  @chapter = File.read("./data/chp#{chp}.txt")

  erb :chapter
end

def each_chapter
  @toc.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []
  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include?(query)
    end
    results << {number: number, name: name, paragraphs: matches} if matches.any?
  end

  results
end

# def paragraphs_matching(query)
#   results = []
#   return results if !query || query.empty?

#   each_chapter do |number, name, contents|
#     paragraphs = contents.split("\n\n")
#     paragraphs.each do |paragraph|
#       results << {number: number, name: name, paragraph: paragraph} if paragraph.include?(query)
#     end
#   end

#   results
# end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end