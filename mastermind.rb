# frozen_string_literal: true

require 'colorize'

# Deals with the colors used to make the codes
module Codeable
  COLORS = %w[red yellow green blue magenta black].freeze

  def random_color
    COLORS[rand(0..5)]
  end

  def print_all_colors
    COLORS.each do |color|
      print "#{color.send(color)} "
    end
    print "\n"
  end
end

# Stores the values of the guesses and shows feedback on them
class GameBoard
  include Codeable
  attr_reader :guesses

  def initialize(game)
    @guesses = []
    @game = game
  end

  def add_code(code)
    @guesses.push(code)
  end

  def show
    @guesses.each do |guess|
      guess.each do |color|
        print ' ● '.send(color)
      end
      print ' | '
      show_evaulation(guess)
      print "\n"
    end
  end

  private

  def show_evaulation(guess)
    evaluation = @game.evaluate(guess)
    evaluation.each do |value|
      case value
      when 'perfect'
        print '•'.red
      when 'exists'
        print '•'
      end
    end
  end
end

# Handles the logic of the mastermind game
class Game
  include Codeable

  def initialize
    @turn = 1
  end

  def setup
    @game_board = GameBoard.new(self)
    @messages = GameMessage.new

    @messages.welcome

    if @messages.prompt_maker_or_breaker == 'BREAKER'
      setup_human_breaker
    else
      setup_computer_breaker
    end
  end

  def play_human_breaker
    guess = @code_breaker.guess(@messages.prompt_guess)
    @game_board.show

    if win?(guess)
      @messages.human_win
    elsif @turn > 12
      @messages.guess_limit
    else
      @turn += 1
      play_human_breaker
    end
  end

  def play_computer_breaker
    guess = @code_breaker.guess
    @messages.print_computer_guess(guess)
    @game_board.show
    @code_breaker.log_evaluation(evaluate(guess), guess)

    if win?(guess)
      @messages.computer_win
    elsif @turn > 12
      @messages.guess_limit
    else
      sleep(1)
      @turn += 1
      play_computer_breaker
    end
  end

  def evaluate(guess, code = @code)
    evaluation = []
    code_non_perfect_colors, guess_non_perfect_colors = evaluate_perfect_colors(guess, code, evaluation)

    guess_non_perfect_colors.each do |color|
      if code_non_perfect_colors.include?(color)
        evaluation.push('exists')
        code_non_perfect_colors.delete_at(code_non_perfect_colors.index(color))
      end
    end
    evaluation
  end

  private

  def setup_human_breaker
    @code_maker = ComputerPlayer.new(@game_board, self)
    @code_breaker = HumanPlayer.new(@game_board, self)
    @code = @code_maker.generate_code
    play_human_breaker
  end

  def setup_computer_breaker
    @code_maker = HumanPlayer.new(@game_board, self)
    @code_breaker = ComputerPlayer.new(@game_board, self)
    @code = @messages.prompt_code
    play_computer_breaker
  end

  def win?(guess)
    evaluation = evaluate(guess)
    evaluation.length == 4 && evaluation.all?('perfect')
  end

  def evaluate_perfect_colors(guess, code, evaluation)
    code_non_perfect_colors = []
    guess_non_perfect_colors = []
    guess.each_with_index do |color, i|
      if code[i] == color
        evaluation.push('perfect')
      else
        code_non_perfect_colors.push(code[i])
        guess_non_perfect_colors.push(color)
      end
    end
    [code_non_perfect_colors, guess_non_perfect_colors]
  end
end

# Handles all messages to the terminal
class GameMessage
  include Codeable

  def welcome
    puts 'Welcome to Mastermind!'
    puts 'You will either make or guess a four-color code.'
    puts 'With each guess, you will see up to four dots to the right of the board.'
    puts "A #{'red'.red} dot means a color is in the correct position,"
    puts "and a #{'white'.on_white} dot means that a color exists in the code but is in the incorrect position."
  end

  def prompt_maker_or_breaker
    puts 'Would you like to be the code MAKER or code BREAKER?'
    maker_or_breaker = gets.chomp.upcase
    unless %w[MAKER BREAKER].include?(maker_or_breaker)
      puts 'Please type "MAKER" or "BREAKER"'
      return prompt_maker_or_breaker
    end
    maker_or_breaker
  end

  def prompt_code
    puts 'Please enter a four-color code using the following six colors:'
    print_all_colors
    code = gets.chomp.split
    return prompt_code unless validate_code(code)

    code
  end

  def prompt_guess
    puts 'Please guess four colors from the list below:'
    print_all_colors
    guess = gets.chomp.split
    return prompt_guess unless validate_code(guess)

    guess
  end

  def print_computer_guess(guess)
    print 'The computer guessed '
    guess.each { |color| print "#{color.send(color)} " }
    print "\n"
  end

  def human_win
    puts 'You won!'
  end

  def computer_win
    puts 'The computer wins!'
  end

  def guess_limit
    puts 'Game over, 12 guesses!'
  end

  private

  def validate_code(code)
    code.length == 4 && code.all? { |color| COLORS.include?(color) }
  end
end

# Base class for players of the mastermind game
class Player
  include Codeable

  def initialize(game_board, game)
    @game_board = game_board
    @game = game
  end
end

# Class for human players that handles getting input for a guess
class HumanPlayer < Player
  def guess(code)
    @game_board.add_code(code)
    code
  end
end

# Class for computer players that handles logic for guessing and generating a code
class ComputerPlayer < Player
  def initialize(game_board, game)
    super(game_board, game)
    @possible_codes = []
    COLORS.repeated_permutation(4) { |permutation| @possible_codes.push(permutation) }
  end

  def generate_code
    code = []
    4.times { code.push(random_color) }
    code
  end

  def guess
    code = @possible_codes.sample
    @game_board.add_code(code)
    code
  end

  def log_evaluation(evaluation, guess)
    @possible_codes.select! do |code|
      @game.evaluate(code, guess) == evaluation
    end
  end
end

game = Game.new
game.setup
