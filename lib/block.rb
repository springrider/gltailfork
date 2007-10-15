# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Block
  attr_reader :name, :position, :order, :bottom_position

  def initialize(options)
    @name = options[:name]
    @position = options[:position] || :left
    @size = options[:size] || 10
    @clean = options[:auto_clean] || true
    @order = options[:order] || 100
    @color = options[:color]

    @show = case options[:show]
            when :rate: 0
            when :total: 1
            when :average: 2
            else
              0
            end

    @header = Element.new(@name.upcase , [1.0, 1.0, 1.0, 1.0], @show, @position == :right)

    @elements = { }
    @bottom_position = -$TOP
  end

  def render(num)
    return num if @elements.size == 0

    @header.wy = $TOP - (num * $LINE_SIZE)
#    @header.y = @header.wy if @header.y == -$TOP
    @header.render
    num += 1

    sorted = case @show
               when 0: @elements.values.sort { |k,v| v.rate <=> k.rate}[0..@size-1]
               when 1: @elements.values.sort { |k,v| v.total <=> k.total}[0..@size-1]
               when 2: @elements.values.sort { |k,v| v.average <=> k.average}[0..@size-1]
             end

    sorted.each do |e|
      e.wy = $TOP - (num * $LINE_SIZE)
      e.render
      $STATS[0] += 1
      if e.rate <= 0.0001 && e.active && e.updates > 59 && @clean
        @elements.delete(e.name)
      end
      num += 1
    end
    (@elements.values - sorted).each do |e|
      $STATS[0] += 1
      e.activities.each do |a|
        a.render
        if a.x > 1.0 || a.x < -1.0 || a.y > $ASPECT
          e.activities.delete a
        end
      end
      if e.activities.size == 0 && @clean && e.updates > 4
        @elements.delete(e.name)
      end
    end
    @elements.delete_if { |k,v| (!sorted.include? v) && v.active && v.activities.size == 0} if @clean
    @bottom_position = $TOP - ((sorted.size > 0 ? (num-1) : num) * $LINE_SIZE)
    num + 1
  end

  def add_activity(options = { })
    @elements[options[:name]] ||= Element.new(options[:name], @color || options[:color], @show, @position == :right)
    @elements[options[:name]].add_activity(options[:message], options[:size] || 0.01, options[:type] || 0 )
  end

  def add_event(options = { })
    @elements[options[:name]] ||= Element.new(options[:name], options[:color], @show, @position == :right)
    @elements[options[:name]].add_event(options[:message], options[:update_stats] || false)
  end

  def update
    @elements.each_value do |e|
      e.update
    end
  end
end
