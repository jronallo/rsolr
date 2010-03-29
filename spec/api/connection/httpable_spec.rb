describe RSolr::Connection::Httpable do
  
  # calls #let to set "net_http" as method accessor
  class R
    include RSolr::Connection::Httpable
  end
  
  module HttpableHelper
    def self.included base
      base.let(:requestable){R.new}
    end
  end
  
  context 'new' do
    
    include HttpableHelper
    
    it 'should define an intialize method that accepts a hash argument' do
      lambda{R.new({})}.should_not raise_error 
    end
  
    it 'should have an #opts attribute after creation' do
      requestable.should respond_to(:opts)
    end
  
    it 'should have an #uri attribute after creation' do
      requestable.should respond_to(:uri)
    end
    
  end
  
  context 'opts and uri' do
    
    it 'should allow setting the opts' do
      opts = {:url=>'blah'}
      r = R.new(opts)
      r.opts.should == opts
    end
    
    it 'should parser the url option into a URI object' do
      opts = {:url => 'http://xyz:1010/solr'}
      r = R.new(opts)
      r.uri.should be_a(URI)
      r.uri.host.should == 'xyz'
    end
    
  end
  
  context :build_url do
    
    include HttpableHelper
    
    it 'should build a full path and create a query string' do
      r = requestable
      r.build_url("/select", :q=>1).should == '/solr/select?q=1'
    end
    
    it 'should build a full path without a query string' do
      r = requestable
      r.build_url("/select").should == '/solr/select'
    end
    
  end
  
  context :create_request_context do
    
    include HttpableHelper
    
    it "should build a simple GET context" do
      r = requestable
      result = r.create_request_context('/select', :q=>'a', :fq=>'b')
      expected = {:path=>"/solr/select?q=a&fq=b", :params=>{:q=>"a", :fq=>"b"}, :data=>nil, :query=>"q=a&fq=b", :host=>"http://127.0.0.1:8983"}
      
      result.keys.all? {|v| expected.keys.include?(v) }
      result.values.all? {|v| expected.values.include?(v) }
    end
    
    it "should build a POST context" do
      r = requestable
      result = r.create_request_context('/select', {:wt => :xml}, '<commit/>')
      expected = {:path=>"/solr/select", :params=>{:wt=>:xml}, :headers=>{"Content-Type"=>"text/xml; charset=utf-8"}, :data=>"<commit/>", :query=>"wt=xml", :host=>"http://127.0.0.1:8983"}
      result.should == expected
    end
    
    it "should raise an exception when trying to use POST data AND :method => :post" do
      r = requestable
      lambda{
        r.create_request_context('/select', {:wt => :xml}, '<commit/>', :method => :post)
      }.should raise_error("Don't send POST data when using :method => :post")
    end
    
    it "should form-encoded POST context" do
      r = requestable
      result = r.create_request_context('/select', {:q => 'some gigantic query string that is too big for GET (for example)'}, nil, :method => :post)
      result.should == {:path=>"/solr/select", :params=>{:q=>"some gigantic query string that is too big for GET (for example)"}, :headers=>{"Content-Type"=>"application/x-www-form-urlencoded"}, :data=>"q=some+gigantic+query+string+that+is+too+big+for+GET+%28for+example%29", :query=>"q=some+gigantic+query+string+that+is+too+big+for+GET+%28for+example%29", :host=>"http://127.0.0.1:8983"}
    end
    
  end
  
  context :request do
    
    include HttpableHelper
    
    it "should be able to build a request context, pass the url to #get and return a full context" do
      requestable.should_receive(:create_request_context).
        with("/admin/ping", {}, nil, {}).
          and_return({:path => '/solr/admin/ping'})
      requestable.should_receive(:get).
        with('/solr/admin/ping').
          and_return(["asdfasdf", 200, "OK"])
      response = requestable.request '/admin/ping'
      response.should == {:status_code=>200, :message=>"OK", :path=>"/solr/admin/ping", :body=>"asdfasdf"}
    end
    
    it 'should send a get to itself with params' do
      requestable.should_receive(:get).
        with("/solr/blahasdf?id=1").
          and_return(["", 200, "OK"])
      r = requestable.request('/blahasdf', :id=>1)
      r.should == {:status_code=>200, :path=>"/solr/blahasdf?id=1", :params=>{:id=>1}, :message=>"OK", :data=>nil, :query=>"id=1", :host=>"http://127.0.0.1:8983", :body=>""}
    end
    
    it 'should raise an error if the status_code is not 200' do
      requestable.should_receive(:get).
        with("/solr/blah?id=1").
          and_return( ["", 404, "Not Found"] )
      lambda{
        requestable.request('/blah', :id=>1).should == true
      }.should raise_error(/Not Found/)
    end
    
    it 'should send a post to itself if data is supplied' do
      requestable.should_receive(:post).
        with("/solr/blah", "<commit/>", {"Content-Type"=>"text/xml; charset=utf-8"}).
          and_return(["", 200, "OK"])
      requestable.request('/blah', {:id=>1}, "<commit/>")#.should == expected_response
    end
    
    it 'should send a post to itself when :method=>:post is set even if no POST data is supplied' do
      requestable.should_receive(:post).
        with("/solr/blah", "q=testing", {"Content-Type"=>"application/x-www-form-urlencoded"}).
          and_return(["", 200, "OK"])
      response = requestable.request('/blah', {:q => "testing"}, :method => :post)#.should == expected_response
      response[:body].should == ""
      response[:path].should == "/solr/blah"
      response[:message].should == "OK"
      response[:status_code].should == 200
      response[:params].should == {:q=>"testing"}
      response[:headers].should == {"Content-Type"=>"application/x-www-form-urlencoded"}
      response[:data].should == "q=testing"
      response[:query].should == "q=testing"
      response[:host].should == "http://127.0.0.1:8983"
    end
    
  end
  
end