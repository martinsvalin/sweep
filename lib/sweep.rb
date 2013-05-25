class Sweep
  class GameOver < StandardError; end

  def initialize(opts = {})
    @rows = 0..opts.fetch(:rows).to_i - 1
    @cols = 0..opts.fetch(:cols).to_i - 1
    @x, @y = 0, 0
    @flags = []
    @opened = []
    @mines = [100, rows.end ** cols.end / 2].min
               .times.map { [Random.rand(@cols), Random.rand(@rows)] }
  end
  attr_reader :rows, :cols
  attr_accessor :x, :y, :flags, :opened, :mines
  alias :current_col :x
  alias :current_row :y

  def move(dx, dy)
    dx, dy = dx.to_i, dy.to_i
    return unless valid_move? x + dx, y + dy
    self.x += dx
    self.y += dy
  end

  def open
    raise GameOver if mined?
    opened << current_position
  end

  def toggle_flag
    return if opened?
    if flagged?
      flags.delete current_position
    else
      flags << current_position
    end
  end

  def valid_move?(to_x, to_y)
     cols.include?(to_x) && rows.include?(to_y)
  end

  def mined?
    mines.include? current_position
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
    return :flagged if flagged?
    return :opened if opened?
  end

  def nearby_mines_count
    (mines & surrounding_tiles).count
  end

  def surrounding_tiles
    ([x - 1, x, x + 1].product([y - 1, y, y + 1]) - [current_position]).
      select { |(x, y)| valid_move? x, y }
  end
end
