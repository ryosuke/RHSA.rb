#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
#  rhsa.rb
#
#  Author: Ryosuke KUTSUNA <ryosuke@deer-n-horse.jp>
#
require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'tmpdir'
require 'tempfile'

class RHSA
  def initialize(type, year=nil, num)
    @rhn = "https://rhn.redhat.com"

    unless type then
      @rhtype = "RHSA"
    else
      @rhtype = type
    end

    unless num then
      puts "RHSA number not exist."
      exit 1
    else
      @rhsa_num = num
    end

    if year == nil then
      t = Time.new
      @year = t.year
    else
      @year = year
    end

    @tmpfile = Tempfile.new('rhsa')
    getRHSAHtml()
    parseRHSA()
    @tmpfile.close
    @tmpfile.unlink
  end

  def getURL
    return "#{@rhn}/errata/#{@rhtype}-#{@year}-#{@rhsa_num}.html"
  end

  def getRHSATitle
    return @rhsa_title
  end

  def getRHSAAdvisory
    return @rhsa_advisory
  end

  def getRHSAType
    return @rhsa_type
  end

  def getRHSASeverity
    return @rhsa_severity
  end

  def getRHSAIssue
    return @rhsa_issue
  end

  def getRHSAUpdate
    return @rhsa_update
  end

  def getRHSAAffected
    return @rhsa_affected
  end

  def getRHSACve
    return @rhsa_cve
  end

  def getRHSAPackages
    return @rhsa_packages
  end

  private
  # get RHSA Announce HTML
  def getRHSAHtml() 
    dlrhsa = getURL
    begin
      open(dlrhsa) do |s|
          @tmpfile.print(s.read)
      end
    rescue => e
      p e.message
      print "Not found: #{dlrhsa}\n"
      exit 1
    end
  end
  
  # parse RHSA Announce HTML
  def parseRHSA()
    doc = Nokogiri::HTML(open(@tmpfile))

    doc.xpath('//h1').each do |title|
      @rhsa_title = title.text
    end

    # parse details.
    doc.xpath("//table[@class='details']").each do |det|
      @rhsa_advisory = det.xpath('./tr/td')[0].text
      @rhsa_type = det.xpath('./tr/td')[1].text
      @rhsa_severity = det.xpath('./tr/td')[2].text
      @rhsa_issue = det.xpath('./tr/td')[3].text
      @rhsa_update = det.xpath('./tr/td')[4].text
      @rhsa_affected = []
      det.xpath('./tr/td')[5].xpath('./a').each do |prod|
        @rhsa_affected << prod.text
      end
      @rhsa_cve = []
      if det.xpath('./tr/td')[6] != nil then
        det.xpath('./tr/td')[6].xpath('./a').each do |cve|
          @rhsa_cve << cve.text
        end
      end
    end

    # parse update packages.
    rh_pro = ""
    rh_arc = ""
    rh_pac = ""
    @rhsa_packages = []
    doc.xpath("//table[@border='0']/tr/td").each do |a|
      if @rhsa_affected.include?(a.text) then
        if rh_pro != a.text then
           rh_pro = ""
           rh_arc = ""
           rh_pac = ""
           rh_pro = a.text
        next
        end
      end
      if a.text =~ /.:$/ then
        if rh_arc != a.text then
          rh_arc = ""
          rh_pac = ""
        end
        rh_arc = a.text
        next
      end
      if a.text =~ /\.rpm$/ then
        if rh_pac != a.text then
           rh_pac = a.text
           next
        end
      end
      if rh_pro != "" && rh_arc != "" && rh_pac != "" then
        @rhsa_packages << [ rh_pro, rh_arc, rh_pac ]
        rh_pac = ""
      end
    end
  end
end

### main ###
if __FILE__ == $0

  production="Red Hat Enterprise Linux Server (v. 7)"
  architecture="x86_64:"

  rhsa = RHSA.new("RHSA", "2017", "0182")
  print "----------\n#{rhsa.getRHSATitle}\n----------\n"
  print "Advisory   : #{rhsa.getRHSAAdvisory}\n"
  print "Type       : #{rhsa.getRHSAType}\n"
  print "Severity   : #{rhsa.getRHSASeverity}\n"
  print "Issue      : #{rhsa.getRHSAIssue}\n"
  print "Update     : #{rhsa.getRHSAUpdate}\n"
  print "Affected   : #{rhsa.getRHSAAffected}\n"
  print "CVEs       : #{rhsa.getRHSACve}\n"
  #print "Packages   : #{rhsa.getRHSAPackages}\n"

  print "---- Packages in #{production}, #{architecture} ----\n"
  
  rhsa.getRHSAPackages.each do |p|
    if p[0] == production && p[1] == architecture then
      puts p[2]
    end
  end
end

# EOF
