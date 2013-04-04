class Sweep
  class GameOver < StandardError; end

  FLAGGED = 1
  OPENED = 2

  def initialize(opts = {})
    @rows = 0..opts.fetch(:rows).to_i - 1
    @cols = 0..opts.fetch(:cols).to_i - 1
    @x, @y = rows.first, cols.first
    @flags = []
    @opened = []
    @mines = [[0,0], [10,10]]
  end
  attr_reader :rows, :cols
  attr_accessor :x, :y, :flags, :opened, :mines
  alias :current_col :x
  alias :current_row :y

  def move(dx, dy)
    dx, dy = dx.to_i, dy.to_i
    return unless valid_move? dx, dy
    self.x += dx
    self.y += dy
  end

  def open
    raise GameOver if mines.include? current_position
    opened << current_position
  end

  def toggle_flag
    return if opened.include? current_position
    if flags.include? current_position
      flags.delete current_position
    else
      flags << current_position
    end
  end

  def valid_move?(dx, dy)
     cols.include?(x + dx) && rows.include?(y + dy)
  end

  def opened?
    opened.include? current_position
  end

  def flagged?
    flags.include? current_position
  end

  def remaining_mines
    mines.count - flags.count
  end

  def current_position
    [current_col, current_row]
  end

  def status_for_current_position
    return FLAGGED if flagged?
    return OPENED if opened?
  end

  def nearby_mines_count
    (mines & surrounding_tiles).count
  end

  def surrounding_tiles
    [x - 1, x, x + 1].product([y - 1, y, y + 1]) -  [current_position]
  end
end
