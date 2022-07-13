require 'colorize'

module Codeable
  COLORS = %w[red yellow green blue magenta black]

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

class Game
  include Codeable

  def initialize
    @turn = 1
  end

  def setup
    @game_board = GameBoard.new(self)

    if prompt_maker_or_breaker == 'BREAKER'
      @code_maker = ComputerPlayer.new(@game_board, self)
      @code_breaker = HumanPlayer.new(@game_board, self)
      @code = @code_maker.generate_code
      play_human_breaker
    else
      @code_maker = HumanPlayer.new(@game_board, self)
      @code_breaker = ComputerPlayer.new(@game_board, self)
      @code = prompt_code
      play_computer_breaker
    end
  end

  def play_human_breaker
    guess = @code_breaker.guess(prompt_guess)
    @game_board.show

    if win?(guess)
      puts 'You won!'
    elsif @turn > 12
      puts 'Game over, 12 guesses!'
    else
      @turn += 1
      play_human_breaker
    end
  end

  def play_computer_breaker
    guess = @code_breaker.guess
    print 'The computer guessed '
    guess.each { |color| print "#{color.send(color)} " }
    print "\n"
    @game_board.show
    @code_breaker.log_evaluation(evaluate(guess), guess)

    if win?(guess)
      puts 'The computer wins!'
    elsif @turn > 12
      puts 'Game over, 12 guesses!'
    else
      sleep(1)
      @turn += 1
      play_computer_breaker
    end
  end

  def prompt_guess
    puts 'Please guess four colors from the list below:'
    print_all_colors
    gets.chomp
  end

  def evaluate(guess, code = @code)
    evaluation = []
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

    guess_non_perfect_colors.each do |color|
      if code_non_perfect_colors.include?(color)
        evaluation.push('exists')
        code_non_perfect_colors.delete_at(code_non_perfect_colors.index(color))
      end
    end
    evaluation
  end

  private

  def win?(guess)
    evaluation = evaluate(guess)
    evaluation.length == 4 && evaluation.all?('perfect')
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
    gets.chomp.split
  end
end

class Player
  def initialize(game_board, game)
    @game_board = game_board
    @game = game
  end
end

class HumanPlayer < Player
  def guess(input)
    code = input.split
    @game_board.add_code(code)
    code
  end
end

class ComputerPlayer < Player
  include Codeable

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
