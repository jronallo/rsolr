require 'spec_helper'
describe "RSolr::Client" do
  
  module ClientHelper
    def client
      @client ||= (
        connection = RSolr::Http.new :url => "http://localhost:9999/solr"
        RSolr::Client.new connection
      )
    end
  end
  
  context "initialize" do
    it "should accept whatevs and set it as the @connection" do
      RSolr::Client.new(:whatevs).connection.should == :whatevs
    end
  end
  
  context "send_request" do
    include ClientHelper
    it "should forward these method calls the #connection object" do
      [:get, :post, :head].each do |meth|
        client.connection.should_receive(:send_request).
            and_return({:status => 200, :body => "{}", :headers => {}})
        client.send_request '', :method => meth, :params => {}, :data => nil, :headers => {}
      end
    end
  end

  context "post" do
    include ClientHelper
    it "should pass the expected params to the connection's #post method" do
      client.connection.should_receive(:send_request).
        with(
          "update", {:headers=>{"Content-Type"=>"text/plain"}, :method=>:post, :data=>"the data"}
        ).
          and_return(
            :params=>{:wt=>:ruby},
            :query=>"wt=ruby",
            :path => "update",
            :data=>"the data",
            :method=>:post,
            :headers=>{"Content-Type"=>"text/plain"}
          )
      client.post "update", :data => "the data", :headers => {"Content-Type" => "text/plain"}
    end
  end
  
  context "xml" do
    include ClientHelper
    it "should return an instance of RSolr::Xml::Generator" do
      client.xml.should be_a RSolr::Xml::Generator
    end
  end
  
  context "add" do
    include ClientHelper
    it "should send xml to the connection's #post method" do
      client.connection.should_receive(:send_request).
        with(
          "update", {:headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :data=>"<xml/>"}
        ).
          and_return(
            :path => "update",
            :data => "<xml/>",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :query => "wt=ruby",
            :params => {:wt=>:ruby}
          )
      # the :xml attr is lazy loaded... so load it up first
      client.xml
      client.xml.should_receive(:add).
        with({:id=>1}, {:commitWith=>10}).
          and_return("<xml/>")
      client.add({:id=>1}, :add_attributes => {:commitWith=>10})
    end
  end
  
  context "update" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:send_request).
        with(
          "update", {:headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :data=>"<optimize/>"}
        ).
          and_return(
            :path => "update",
            :data => "<optimize/>",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :query => "wt=ruby",
            :params => {:wt=>:ruby}
          )
      client.update(:data => "<optimize/>")
    end
  end
  
  context "post based helper methods:" do
    include ClientHelper
    [:commit, :optimize, :rollback].each do |meth|
      it "should send a #{meth} message to the connection's #post method" do
        client.connection.should_receive(:send_request).
          with(
            "update", {:headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :data=>"<?xml version=\"1.0\" encoding=\"UTF-8\"?><#{meth}/>"}
          ).
            and_return(
              :path => "update",
              :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><#{meth}/>",
              :headers => {"Content-Type"=>"text/xml"},
              :method => :post,
              :query => "wt=ruby",
              :params => {:wt=>:ruby}
            )
        client.send meth
      end
    end
  end
  
  context "delete_by_id" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:send_request).
        with(
          "update", {:headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :data=>"<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><id>1</id></delete>"}
        ).
          and_return(
            :path => "update",
            :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><id>1</id></delete>",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :query => "wt=ruby",
            :params => {:wt=>:ruby}
          )
      client.delete_by_id 1
    end
  end
  
  context "delete_by_query" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:send_request).
        with(
          "update", {:headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :data=>"<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><query fq=\"category:&quot;trash&quot;\"/></delete>"}
        ).
          and_return(
            :path => "update",
            :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><query fq=\"category:&quot;trash&quot;\"/></delete>",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :query => "wt=ruby",
            :params => {:wt=>:ruby}
          )
      client.delete_by_query :fq => "category:\"trash\""
    end
  end
  
end