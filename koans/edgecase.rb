#!/usr/bin/env ruby
# -*- ruby -*-

require 'test/unit/assertions'

class FillMeInError < StandardError
end

def __(value="FILL ME IN")
  value
end

def ___(value=FillMeInError)
  value
end

module EdgeCase
  class Sensei
    attr_reader :failure, :failed_test

	begin
	  AssertionError = Test::Unit::AssertionFailedError
	rescue
	  AssertionError = MiniTest::Assertion
	end

    def initialize
      @pass_count = 0
      @failure = nil
      @failed_test = nil
    end

    def accumulate(test)
      if test.passed?
        @pass_count += 1
        puts "  #{test.name} has expanded your awareness."
      else
        puts "  #{test.name} has damaged your karma."
        @failed_test = test
        @failure = test.failure
        throw :edgecase_exit
      end
    end

    def failed?
      ! @failure.nil?
    end

    def assert_failed?
      failure.is_a?(AssertionError)
    end

    def report
      if failed?
        puts
        puts "You have not yet reached enlightenment ..."
        puts failure.message
        puts
        puts "Please meditate on the following code:"
        if assert_failed?
          puts find_interesting_lines(failure.backtrace)
        else
          puts failure.backtrace
        end
        puts
      end
      say_something_zenlike
    end

    def find_interesting_lines(backtrace)
      backtrace.reject { |line|
        line =~ /test\/unit\/|edgecase\.rb/
      }
    end

    # Hat's tip to Ara T. Howard for the zen statements from his
    # metakoans Ruby Quiz (http://rubyquiz.com/quiz67.html)
    def say_something_zenlike
      puts
      if !failed?
        puts "Mountains are again merely mountains"
      else
        case (@pass_count % 10)
        when 0
          puts "mountains are merely mountains"
        when 1, 2
          puts "learn the rules so you know how to break them properly"
        when 3, 4
          puts "remember that silence is sometimes the best answer"
        when 5, 6
          puts "sleep is the best meditation"
        when 7, 8
          puts "when you lose, don't lose the lesson"
        else
          puts "things are not what they appear to be: nor are they otherwise"
        end
      end
    end
  end      

  class Koan
    include Test::Unit::Assertions

    attr_reader :name, :failure

    def initialize(name)
      @name = name
      @failure = nil
    end

    def passed?
      @failure.nil?
    end

    def failed(failure)
      @failure = failure
    end

    def setup
    end

    def teardown
    end

    # Class methods for the EdgeCase test suite.
    class << self
      def inherited(subclass)
        subclasses << subclass
      end

      def method_added(name)
        testmethods << name unless tests_disabled?
      end

      def run_tests(accumulator)
        puts
        puts "Thinking #{self}"
        testmethods.each do |m|
          self.run_test(m, accumulator) if Koan.test_pattern =~ m.to_s
        end
      end

      def run_test(method, accumulator)
        test = self.new(method)
        test.setup
        begin
          test.send(method)
        rescue StandardError => ex
          test.failed(ex)
        ensure
          begin
            test.teardown
          rescue StandardError => ex
            test.failed(ex) if test.passed?
          end
        end
        accumulator.accumulate(test)
      end

      def end_of_enlightenment
        @tests_disabled = true
      end

      def command_line(args)
        args.each do |arg|
          case arg
          when /^-n\/(.*)\/$/
            @test_pattern = Regexp.new($1)
          when /^-n(.*)$/
            @test_pattern = Regexp.new(Regexp.quote($1))
          else
            if File.exist?(arg)
              load(arg)
            else
              fail "Unknown command line argument '#{arg}'"
            end              
          end
        end
      end

      # Lazy initialize list of subclasses
      def subclasses
        @subclasses ||= []
      end

       # Lazy initialize list of test methods.
      def testmethods
        @test_methods ||= []
      end

      def tests_disabled?
        @tests_disabled ||= false
      end

      def test_pattern
        @test_pattern ||= /^test_/
      end

    end
  end
end

END {
  EdgeCase::Koan.command_line(ARGV)
  zen_master = EdgeCase::Sensei.new
  catch(:edgecase_exit) {
    EdgeCase::Koan.subclasses.each do |sc|
      sc.run_tests(zen_master)
    end
  }
  zen_master.report
}
