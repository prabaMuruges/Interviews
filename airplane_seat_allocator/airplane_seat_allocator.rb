class Seat
  attr_accessor :col, :row, :placement
  
  SEAT_POSITION = {
      windows: {
          label: 'W',
          priority: 20
      },
      aisle: {
          label: 'A',
          priority: 10
      },
      centre: {
          label: 'C',
          priority: 30
      }
  }
  
  def initialize(row, col, visited_cols, total_block_cols)
      self.row = row
      self.col = col + visited_cols
      self.placement = find_placement(total_block_cols, visited_cols)
  end

  def to_s
      "-#{SEAT_POSITION[placement][:label]}-"
  end

  class << self
      SEAT_POSITION.each do |position, _prop|
          define_method(position.to_s) do |seats|
              seats.select { |seat| seat.placement == position }
          end
      end
  end
  
  private
  
  def find_placement(total_block_cols, visited_cols)
      case col - visited_cols
      when 1
          :aisle
      when total_block_cols
          :aisle
      else
          :centre
      end
  end
end

class Block
  attr_accessor :seats, :rows, :cols
 
  def initialize(cols_in_block, rows_in_block, visited_cols)
      self.rows = rows_in_block
      self.cols = cols_in_block
      
      self.seats = []
      (1..rows_in_block).each do |block_row|
          (1..cols_in_block).each do |block_col|
              self.seats << Seat.new(block_row, block_col, visited_cols, cols_in_block)
          end
      end
  end
 
  def seats_to_allocate
      Seat.aisle(seats) + Seat.windows(seats) + Seat.centre(seats)
  end
end

class Airplane
  attr_accessor :blocks
  
  def initialize(blocks_input)
      self.blocks = []
      blocks_input.each_with_index do |block_input, index|
          visited_cols = index > 0 ? blocks_input[0..index-1].map { |bi| bi[0] }.flatten.inject(0) {|sum,x| sum + x } : 0
          self.blocks << Block.new(block_input[0], block_input[1], visited_cols)
      end
      adjust_seat_positions(blocks_input)
  end
  
  def seats_to_allocate
      blocks.map(&:seats_to_allocate).flatten.sort_by { |seat| [Seat::SEAT_POSITION[seat.placement][:priority], seat.row] }
  end
  
  def adjust_seat_positions(blocks_input)
      total_cols = blocks_input[0..-1].map { |bi| bi[0] }.flatten.inject(0) {|sum,x| sum + x }
      blocks.each_with_index do |block, bi|
          block.seats.each_with_index do |seat, si|
              if blocks_input[bi][0] == 1
                  seat.placement = :aisle
              elsif (bi == 0 && seat.col == 1) || (bi == (blocks.size - 1) && seat.col == total_cols)
                  seat.placement = :windows
              end
          end
      end
  end
end

class Passenger
 attr_accessor :identifier
 
 def initialize(n_in_queue)
      self.identifier = format('%03d', n_in_queue)
 end
 
 def to_s
    identifier
 end
end

class SeatAllocator
  attr_accessor :airplane, :total_passengers, :allocated_seats
  
  def initialize(airplane, total_passengers)
     self.airplane = airplane
     self.total_passengers = total_passengers
     self.allocated_seats = {}
  end
  
  def allocate
      (1..total_passengers).each_with_index do |passenger, index|
          next_free_seat = seats_to_allocate[index]
          allocated_seats[next_free_seat] = Passenger.new(passenger) unless next_free_seat.nil?
      end
      self
  end
  
  def generate_report
      rows = airplane.blocks.map(&:rows).max
      cols = 0
      airplane.blocks.each { |block| cols += block.cols }

      result = form_seat_rows(airplane, rows, cols)
      print_seat_info(result, airplane)
  end
  
  private
  
  def seats_to_allocate
      airplane.seats_to_allocate
  end
  
  def form_seat_rows(airplane, rows, cols)
      result = Array.new(rows){Array.new(cols, '---')}
      airplane.blocks.each_with_index do |block, bi|
          block.seats.each_with_index do |seat, si|
              i = (si) / block.cols
              j = (si % block.cols)
              j += airplane.blocks[0..bi - 1].map { |b| b.cols }.flatten.inject(0) {|sum,x| sum + x } if bi > 0
              result[i][j] = allocated_seats[seat] ? allocated_seats[seat].to_s : seat.to_s
          end
     end
     result
  end
  
  def print_seat_info(result, airplane)
     result.each do |rows|
          block_cols = airplane.blocks.map(&:cols)
          visited = 0
          block_cols.each do |bc|
              print rows[visited..bc+visited].join(" ") + " | " 
              visited += bc
          end
          print "\n"
      end 
  end
end

total_passengers = gets.chomp.to_i
block_inputs = []
while(block_input = gets&.chomp)
  block_inputs << block_input.split(" ").map(&:to_i)
end

seat_allocator = SeatAllocator.new(Airplane.new(block_inputs), total_passengers)
seat_allocator.allocate.generate_report