require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_AMOUNT = 17
INITIAL_CREDIT = 500

helpers do
  def calculate_total(cards)
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end

    total
  end

  def display_card(card)

    if session[:hide_card] && @first_card
      @first_card = false
      "<img src='/images/cards/cover.jpg' class='card_image'>"
    else

      case card[0]
        when 'C' then suit = 'clubs'
        when 'D' then suit = 'diamonds'
        when 'H' then suit = 'hearts'
        when 'S' then suit = 'spades'
      end
      case card[1]
        when 'A' then face = 'ace'
        when 'J' then face = 'jack'
        when 'Q' then face = 'queen'
        when 'K' then face = 'king'
        else face = card[1]
      end
      "<img src='/images/cards/#{suit}_#{face}.jpg' class='card_image'>"
    end
  end

  def create_deck
    cards = []
    ['H','D','S','C'].each do |x|
      ['A','2','3','4','5','6','7','8','9','10','J','Q','K'].each do |y|
        cards << [x,y]
      end
    end
    cards.shuffle
  end

  def all_letters(str)
    str[/[a-zA-Z]+/]  == str
  end

  def win
    @success = "You win!!!"
    @display_buttons = false
    session[:hide_card] = false
    session[:player_credit] += 2*(session[:bet])
    @finish = true
    session[:bet] = false
  end

  def lose
    @error = "You lose!!!"
    @display_buttons = false
    session[:hide_card] = false
    @finish = true
    session[:bet] = false
  end
end
before do
  @display_buttons = true
  @first_card = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    erb :set_name
  end

end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name can't be empty"
    halt erb(:set_name)
  elsif !all_letters(params[:player_name])
    @error = "Name can only have letters"
    halt erb(:set_name)
  end
  session[:player_name] = params[:player_name]
  session[:player_credit] = INITIAL_CREDIT
  redirect '/game'
end

post '/set_bet' do
  if params[:bet].to_i > session[:player_credit]
    @error = "Not enough credits"
    halt erb(:bet)
  elsif params[:bet].to_i < 1
    @error = "Bet must be at least 1"
    halt erb(:bet)
  end
  session[:bet] = params[:bet].to_i
  session[:player_credit] -= session[:bet]
  redirect '/game'

end
get '/game' do

  if session[:bet]
    session[:deck] = create_deck
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:player_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:hide_card] = true
    if calculate_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
      lose
    elsif calculate_total(session[:dealer_cards]) > BLACKJACK_AMOUNT
      win
    end
    erb :game
  else
    erb :bet
  end
end

post '/dealer_hit' do
  session[:dealer_cards] << session[:deck].pop
  if calculate_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
    lose
  elsif calculate_total(session[:dealer_cards]) > BLACKJACK_AMOUNT
    win
  else
    redirect '/dealer_turn'
  end
  erb :game
end

get '/dealer_stay' do
  if calculate_total(session[:dealer_cards]) < calculate_total(session[:player_cards])
    win
  else
    lose
  end
  erb :game
end

get '/dealer_turn' do
  if calculate_total(session[:dealer_cards]) < DEALER_MIN_AMOUNT
    @dealer_hit = true
    erb :game
  else
    redirect '/dealer_stay'
  end
end

post '/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    win

  elsif calculate_total(session[:player_cards]) > BLACKJACK_AMOUNT
    lose
  end
  erb :game, layout: false
end

post '/stay' do
  session[:hide_card] = false
  redirect '/dealer_turn'
end

post '/reset' do
  erb :set_name
end

get '/new_player' do
  erb :set_name
end