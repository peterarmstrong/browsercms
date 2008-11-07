require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Connector do
  it_should_validate_presence_of :container  
  it "should be able to find by block" do
    foo = create_html_block(:name => "foo")
    bar = create_html_block(:name => "bar")
    create_connector(:content_block => foo, :content_block_version => foo.version)
    blocks = Connector.for_block(foo).map(&:content_block)
    blocks.should include(foo)
    blocks.should_not include(bar)
  end

  it "should only find connectors for a block that match the current version" do
    @foo = create_html_block(:name => "foo")
    @foo.update_attribute(:name, "foo v2")
    @bar = create_html_block(:name => "bar")
    @con = create_connector(:content_block => @foo)
    @con.update_attribute(:content_block_version, 99)
    reset(:con)
    lambda { @con.content_block }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should only find connectors for the current version of the page" do
    @page = create_page(:section => root_section)
    @connector = create_connector(:page => @page)
    @page.update_attributes(:name => "Updated")
    @page.connectors.reload.size.should == 1
  end

  it "should not delete blocks when deleting a connector" do
    b = create_html_block
    c = create_connector(:content_block => b)
    lambda{ c.destroy }.should change(Connector, :count).by(-1)
    HtmlBlock.find(b).should_not be_nil
  end

  it "should be able to be re-order blocks within a connector" do
    page = create_page
    one = create_connector(:page => page, :container => "foo")
    two = create_connector(:page => page, :container => "foo")
    three = create_connector(:page => page, :container => "foo")
    
    two.reload.move_up
    page.connectors.for_container("foo").map(&:id).should == [two, one, three].map(&:id)
    
    two.reload.move_down
    page.connectors.for_container("foo").should == [one, two, three]    
    
    three.reload.move_to_top
    page.connectors.for_container("foo").should == [three, one, two]    
    
    one.reload.move_to_bottom
    page.connectors.for_container("foo").should == [three, two, one]    
  end

end
