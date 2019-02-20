require 'json'
require 'open-uri'
require 'nokogiri'
require 'date'

## SEED ITINERARIES FROM CAMP_TO_CAMP
puts "Seeding Itineraries..."

def api_call(itinerary, id)
  url = "https://api.camptocamp.org/#{itinerary}/#{id.to_s}"
  JSON.parse(open(url).read)
end

def convert_epsg_3857_to_4326(web_mercator_x, web_mercator_y)
  url = "https://epsg.io/trans?x=#{web_mercator_x}&y=#{web_mercator_y}&s_srs=3857&t_srs=4326"
  response = JSON.parse(open(url).read)
  { long: response["x"], lat: response["y"] }
end

Itinerary.destroy_all

sitemap0 = Nokogiri::HTML(open("https://www.camptocamp.org/sitemaps/r/0.xml"))
sitemap1 = Nokogiri::HTML(open("https://www.camptocamp.org/sitemaps/r/1.xml"))
itinerary_ids = []

sitemap0.xpath("//loc").each do |url|
  itinerary_ids << url.to_s.split("/")[4]
end

sitemap1.xpath("//loc").each do |url|
  itinerary_ids << url.to_s.split("/")[4]
end

# Taking random ids for the seed

init = itinerary_ids[0..-31].sample(20)

puts "#Seed with id #{init}"

# Seeding itineraries

init.each do |id|
  itinerary = Itinerary.new
  itinerary_hash = api_call("routes", id)
  itinerary.coord_x = itinerary_hash["geometry"]["geom"][17..-1].split(",")[0]
  itinerary.coord_y = itinerary_hash["geometry"]["geom"][17..-1].split(",")[1][1..-2]
  itinerary.diffculty = itinerary_hash["global_rating"]
  itinerary.elevation_max = itinerary_hash["elevation_max"]
  itinerary.height_diff_up = itinerary_hash["height_diff_up"]
  itinerary.engagement_rating = itinerary_hash["engagement_rating"]
  itinerary.equipment_rating = itinerary_hash["equipment_rating"]
  itinerary.activities = itinerary_hash["activities"]
  itinerary.orientations = itinerary_hash["orientations"]

  #Add gps coords
  gps_coords = convert_epsg_3857_to_4326(itinerary.coord_x, itinerary.coord_y)
  itinerary.coord_long = gps_coords[:long]
  itinerary.coord_lat = gps_coords[:lat]

  if itinerary_hash["associations"]["images"][0] != nil
    itinerary.picture_url = "https://media.camptocamp.org/c2corg-active/#{itinerary_hash["associations"]["images"][0]["filename"]}"
  else
    itinerary.picture_url = "http://woodspringtrust.org/wp-content/uploads/2013/04/placeholder.jpg"
    # itinerary.picture_url = "https://source.unsplash.com/collection/357786/600x300"
  end

  itinerary_hash["locales"].each do |locale|
    if locale["lang"] == "fr" && locale["title"] != nil
      itinerary.title = "#{locale["title_prefix"]} #{locale["title"]}"
      itinerary.content = locale["description"]
    elsif locale["lang"] == "fr" && locale["title"].nil?
      itinerary.title = locale["title"]
    end
  end

  itinerary.number_of_outings = api_call("outings", id)["associations"]["recent_outings"]["total"]
  itinerary.save
  sleep(1)
  print "."
end

puts "Itineraries seeding completed"

## SEED FAKE USERS
puts "Seeding users..."

User.destroy_all

User.create!(user_name: "Nico", email: "nico@crux.io", password: "qwertyuiop")
User.create!(user_name: "Aymeric", email: "aymeric@crux.io", password: "qwertyuiop")
User.create!(user_name: "Ouramdane", email: "ouramadane@crux.io", password: "qwertyuiop")
User.create!(user_name: "Jordi", email: "jordi@crux.io", password: "qwertyuiop")

puts "User seeding completed"

## SEED FAKE TRIPS
puts "Seeding trips..."

# First we need to destroy messages

Message.destroy_all

Trip.destroy_all

User.all.each do |cur_user|
  cur_itinerary = Itinerary.all.sample
  Trip.create!(start_date: DateTime.new(2019,3,10,8,0,0), end_date: DateTime.new(2019,3,10,19,0,0), user: cur_user, itinerary: cur_itinerary, title: "Super weekend" )
end

User.all.each do |cur_user|
  cur_itinerary = Itinerary.all.sample
  Trip.create!(start_date: DateTime.new(2019,3,15,8,0,0), end_date: DateTime.new(2019,3,15,19,0,0), user: cur_user, itinerary: cur_itinerary, title: "Semaine au ski" )
end

puts "Trip seeding completed"
