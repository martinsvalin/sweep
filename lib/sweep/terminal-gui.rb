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
      when /[qQ]/; break

      # Movement
      when ?h, Curses::Key::LEFT;  move -1,  0
      when ?j, Curses::Key::DOWN;  move  0,  1
      when ?k, Curses::Key::UP;    move  0, -1
      when ?l, Curses::Key::RIGHT; move  1,  0

      # Game controls
      when /\s/; open
      when /[fF]/; toggle_flag
      end
    end
  end

  def draw_untouched_board
    write game.rows, 0, ?. * game.cols.count
  end

  def move(dx, dy)
    reset_old_position
    game.move dx, dy
    display_new_position
  end

  def open_surrounding_tiles(x, y)
    game.x, game.y = x, y

    game.surrounding_tiles.each do |tile|
      game.x, game.y = *tile
      open if !game.opened? && !game.mined? && game.nearby_mines_count == 0
    end
  end

  def open
    game.open
    update_board_at_current_position
    display_new_position
    open_surrounding_tiles *game.current_position
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

  def reveal_mines
    game.rows.each do |y|
      game.cols.each do |x|
        write(y, x, ?#) if game.mines.include? [x, y]
      end
    end
  end

  def display_game_over
    reveal_mines
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
    when :flagged; ?F
    when :opened; game.nearby_mines_count.to_s
    else ?.
    end
  end
end
