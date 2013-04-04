require "curses"

class Sweep::TerminalGUI
  def self.play(game)
    new(game).play
  end

  def self.init_screen
    Curses.noecho # do not show typed keys
    Curses.curs_set 0 # hide cursor
    Curses.stdscr.keypad(true) # enable arrow keys
    Curses.init_screen
    begin
      yield
    ensure
      Curses.close_screen
    end
  end

  def self.cols
    Curses.cols
  end

  def self.rows
    Curses.lines - 1 # make room for status line
  end

  def initialize(game)
    @game = game
  end
  attr_reader :game

  def play
    draw_untouched_board
    move 0, 0
    display_instructions
    display_remaining_mines
    game_loop
  end

  def game_loop
    loop do
      case Curses.getch
      # Quit
      when /[qQ]/ then break

      # Movement
      when Curses::Key::LEFT then move -1, 0
      when Curses::Key::DOWN then move 0, 1
      when Curses::Key::UP then move 0, -1
      when Curses::Key::RIGHT then move 1, 0
      when ?h then move -1,  0
      when ?j then move  0,  1
      when ?k then move  0, -1
      when ?l then move  1,  0

      # Game controls
      when /\s/ then open
      when /[fF]/ then toggle_flag
      end
    end
  end

  def draw_untouched_board
    write game.rows, 0, "." * game.cols.count
  end

  def move(dx, dy)
    reset_old_position
    game.move dx, dy
    display_new_position
  end

  def open
    game.open
    update_board_at_current_position
    display_new_position
  rescue Sweep::GameOver
    display_game_over
  end

  def toggle_flag
    game.toggle_flag
    update_board_at_current_position
    display_new_position
    display_remaining_mines
  end

  def display_new_position
    Curses.standout
    update_board_at_current_position
    Curses.standend
  end

  def reset_old_position
    update_board_at_current_position
  end

  def status_line
    game.rows.last + 1
  end

  def display_instructions
    write status_line, 0, "q=Quit, space=Open, f=Flag"
  end

  def display_remaining_mines
    write status_line, 30, "Mines left: #{game.remaining_mines}"
    Curses.clrtoeol
  end

  def display_game_over
    middle_line = game.rows.last / 2
    center = game.cols.last / 2 - 5
    write middle_line - 2, center, "***************"
    write middle_line - 1, center, "*             *"
    write middle_line, center,     "*  GAME OVER  *"
    write middle_line + 1, center, "*             *"
    write middle_line + 2, center, "***************"
  end

  def write(lines, column, text = nil)
    Array(lines).each do |line|
      Curses.setpos line, column
      Curses.addstr text || Curses.inch.chr
    end
  end

  def update_board_at_current_position
    write game.current_row, game.current_col, char_for_current_position
  end

  def char_for_current_position
    case game.status_for_current_position
    when Sweep::FLAGGED then ?F
    when Sweep::OPENED then game.nearby_mines_count.to_s
    else ?.
    end
  end
end
