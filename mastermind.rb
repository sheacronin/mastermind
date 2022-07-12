require 'colorize'

module Codeable
  COLORS = ['red', 'yellow', 'green', 'blue', 'magenta', 'black']

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

  def setup
    @game_board = GameBoard.new(self)
    @code_maker = ComputerPlayer.new(@game_board)
    @code_breaker = HumanPlayer.new(@game_board)
    @code = @code_maker.generate_code
  end

  def play
    guess = @code_breaker.guess(prompt_guess)
    @game_board.show

    if win?(guess)
      puts 'You won!'
    else
      play
    end
  end

  def prompt_guess
    puts 'Please guess four colors from the list below:'
    print_all_colors
    gets.chomp
  end

  def evaluate(guess)
    evaluation = []
    code_non_perfect_colors = []
    guess_non_perfect_colors = []

    guess.each_with_index do |color, i|
      if @code[i] == color
        evaluation.push('perfect')
      else
        code_non_perfect_colors.push(@code[i])
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
end

class Player
  def initialize(game_board)
    @game_board = game_board
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

  def generate_code
    code = []
    4.times { code.push(random_color) }
    code
  end
end

game = Game.new
game.setup
game.play
