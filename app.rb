#!/usr/bin/env ruby
# vim: et ts=2 sw=2

require "set"
require "date"
require "health_graph"
require "sinatra"
require "sass"


HealthGraph.configure do |config|
  config.client_id = ENV["CLIENT_ID"]
  config.client_secret = ENV["CLIENT_SECRET"]
  config.authorization_redirect_url = ENV["REDIRECT_URL"]
end


helpers do
  def is_checked day
    @chain.include? day.date
  end
end


get "/" do
  token = request.cookies["token"]
  redirect "/auth" unless token

  user = HealthGraph::User.new token
  @chain = get_chain get_checked_days! user
  @month = Month.new Date.today

  erb :calendar
end

get "/style.css" do
  scss :style
end

get "/auth" do
  redirect HealthGraph.authorize_url
end

get "/callback" do
  token = HealthGraph.access_token params[:code]
  response.set_cookie "token", token
  redirect "/"
end


def get_checked_days! user
  Set.new.tap do |days|
    feed = user.fitness_activities

    while feed
      feed.items.each do |item|
        days.add item.start_time.to_date
      end

      feed = feed.next_page
    end
  end
end

def get_chain days
  Set.new.tap do |chain|
    day = Date.today

    while days.include? day
      chain.add day
      day -= 1
    end
  end
end


class Month
  def initialize date
    @prng = Random.new date.month
    @date = date
  end

  def weeks
    first_day.step(last_day, 7).map do |date|
      Week.new date
    end
  end

  def weekdays
    sunday = Date.today - Date.today.wday
    sunday.upto(sunday + 6).map do |date|
      Day.new date
    end
  end

  def include? date
    (date.year == @date.year) and (date.month == @date.month)
  end

  def strftime fmt
    @date.strftime fmt
  end

  def random_angle
    20 - @prng.rand(40)
  end

  private

  def first_day
    DateTime.new @date.year, @date.month, 1
  end

  def last_day
    first_day.next_month.prev_day
  end
end

class Week
  def initialize date
    @date = date
  end

  def days
    first_day.upto(last_day).map do |date|
      Day.new date
    end
  end

  private

  def first_day
    @date - @date.wday
  end

  def last_day
    first_day + 6
  end
end

class Day
  attr_reader :date

  def initialize date
    @date = date
  end

  def today?
    @date == Date.today
  end

  def weekend?
    @date.saturday? or @date.sunday?
  end

  def method_missing method_name, *args, &block
    @date.send method_name, *args, &block
  end
end
