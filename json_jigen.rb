require 'json'
require 'open-uri'
# "rubocop": false

# prompts user for input, usually begins with romaji, which is the romanized form of Japanese
def ask_user_for(missing_field, question)
    puts "Cannot find the #{missing_field} of #{question}"
    puts "Please enter value:"
  return gets.chomp
end

# The file that the output will be written to. Name it whatever you like but make sure to end with .json
target_file = "food.json"

# Where the program begins its search. The below works for this example. 
# However, when I was acutally using it the filepath would look something like "~/code/ryellingson/japanesequizzer-rails/app/assets/problem_icons/food"
path_to_folder = "./food_icons"

# put all of our icons into an array
question_values = `ls #{path_to_folder}`.split

# turns icons that have already been formatted into a ruby array or sets an empty array
if File.exist?(target_file)
  filled_keys = JSON.parse(File.read(target_file))
else
  filled_keys = []
end

json = []

# for calling the Jisho API
BASE_URI = "https://jisho.org/api/v1/search/words?keyword="

def fill_out_question(question)
  # removes filename extension ".png"
  human_question = question.split(".").first.gsub("-", " ")
  # passes question to the API
  result = JSON.parse(open(BASE_URI + human_question).read)
  # the API has many extraneous definitions, usually the first one is the most relevant
  data = result["data"][0] || {}
  # sets the desired format, if the app can't find the value it asks the user for input
  question_hash = {
    question: question,
    # slug is what the API defines as kanji
    kanji: data["slug"] || ask_user_for("kanji", human_question),
    kana: data.dig("japanese", 0, "reading") || ask_user_for("kana", human_question),
    romaji: ask_user_for("romaji", human_question),
    is_common: data["is_common"] || ask_user_for("is_common", human_question),
    jlpt: data.dig("jlpt", 0) || ask_user_for("jlpt", human_question),
    parts_of_speech: data.dig("senses", 0, "parts_of_speech") || ask_user_for("parts_of_speech", human_question)
  }
end

# checks to see if question has already been written
# if it has the user is informed, if it hasn't the question is put through the formatting process
question_values.each do |question|
  prefilled_question = filled_keys.find { |hash| hash["question"] == question }
  if prefilled_question
    json << prefilled_question
    puts "--- #{question} - Already in file - もうある ---"
  else
    json << fill_out_question(question)
    puts "--- #{question} - Written to JSON - 保存する ---"
  end
  # writes formatted question to the target_file
  File.open(target_file, "w") do |file|
    file.write(JSON.pretty_generate(json, object_nl: "\n"))
  end
end

puts "!All done --- おわり!"
