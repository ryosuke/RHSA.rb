#!/usr/bin/env ruby
#
#  Usage: ruby check_cesa.rb RHSA-YYYY-NNNN rpmlist.txt
#
#  Written by Ryosuke KUTSUNA <ryosuke@deer-n-horse.jp>
#  Init: Mar 28 2017
#
#  rpmlistは対象システムで"rpm -qa > rpmlist.txt"したテキスト
#  ファイルを指定する。
#

require "./rhsa"

production="Red Hat Enterprise Linux Server (v. 7)"
architecture="x86_64:"

rhsa_num = ARGV[0] 
rpmlist =  ARGV[1]

rhsa_array = rhsa_num.split("-")

rhsa = RHSA.new(rhsa_array[0], rhsa_array[1], rhsa_array[2])
rhsa.getRHSAPackages.each do |p|
  if p[0] == production && p[1] == architecture then
    File.open(rpmlist, "r") do |f|
      while line = f.gets
        #puts "line: #{line.chomp}H"
        #puts "rpm : #{p[2].gsub(/\.rpm$/, '')}H"
        if line.chomp == p[2].gsub(/\.rpm$/, '') then
          puts "match: #{p[2]}"
        end
      end
    end
  end
end

