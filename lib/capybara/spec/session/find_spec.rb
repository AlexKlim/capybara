shared_examples_for "find" do
  describe '#find' do
    before do
      @session.visit('/with_html')
    end

    after do
      Capybara::Selector.remove(:monkey)
    end

    it "should find the first element using the given locator" do
      @session.find('//h1').text.should == 'This is a test'
      @session.find("//input[@id='test_field']")[:value].should == 'monkey'
    end

    it "preserve object identity", :focus => true do
      (@session.find('//h1') == @session.find('//h1')).should be_true
      (@session.find('//h1') === @session.find('//h1')).should be_true
      (@session.find('//h1').eql? @session.find('//h1')).should be_false
    end

    it "should find the first element using the given locator and options" do
      @session.find('//a', :text => 'Redirect')[:id].should == 'red'
      @session.find(:css, 'a', :text => 'A link came first')[:title].should == 'twas a fine link'
    end

    it "should raise an error if there are multiple matches" do
      expect { @session.find('//a') }.to raise_error(Capybara::Ambiguous)
    end

    describe 'the returned node' do
      it "should act like a session object" do
        @session.visit('/form')
        @form = @session.find(:css, '#get-form')
        @form.should have_field('Middle Name')
        @form.should have_no_field('Languages')
        @form.fill_in('Middle Name', :with => 'Monkey')
        @form.click_button('med')
        extract_results(@session)['middle_name'].should == 'Monkey'
      end

      it "should scope CSS selectors" do
        @session.find(:css, '#second').should have_no_css('h1')
      end

      it "should have a reference to its parent if there is one" do
        @node = @session.find(:css, '#first')
        @node.parent.should == @node.session.document
        @node.find(:css, '#foo').parent.should == @node
      end
    end

    context "with css selectors" do
      it "should find the first element using the given locator" do
        @session.find(:css, 'h1').text.should == 'This is a test'
        @session.find(:css, "input[id='test_field']")[:value].should == 'monkey'
      end
    end

    context "with id selectors" do
      it "should find the first element using the given locator" do
        @session.find(:id, 'john_monkey').text.should == 'Monkey John'
        @session.find(:id, 'red').text.should == 'Redirect'
        @session.find(:red).text.should == 'Redirect'
      end
    end

    context "with xpath selectors" do
      it "should find the first element using the given locator" do
        @session.find(:xpath, '//h1').text.should == 'This is a test'
        @session.find(:xpath, "//input[@id='test_field']")[:value].should == 'monkey'
      end
    end

    context "with custom selector" do
      it "should use the custom selector" do
        Capybara.add_selector(:monkey) do
          xpath { |name| ".//*[@id='#{name}_monkey']" }
        end
        @session.find(:monkey, 'john').text.should == 'Monkey John'
        @session.find(:monkey, 'paul').text.should == 'Monkey Paul'
      end
    end

    context "with custom selector with :for option" do
      it "should use the selector when it matches the :for option" do
        Capybara.add_selector(:monkey) do
          xpath { |num| ".//*[contains(@id, 'monkey')][#{num}]" }
          match { |value| value.is_a?(Fixnum) }
        end
        @session.find(:monkey, '2').text.should == 'Monkey Paul'
        @session.find(1).text.should == 'Monkey John'
        @session.find(2).text.should == 'Monkey Paul'
        @session.find('//h1').text.should == 'This is a test'
      end
    end

    context "with custom selector with custom filter" do
      before do
        Capybara.add_selector(:monkey) do
          xpath { |num| ".//*[contains(@id, 'monkey')][#{num}]" }
          filter(:name) { |node, name| node.text == name }
        end
      end

      it "should find elements that match the filter" do
        @session.find(:monkey, '1', :name => 'Monkey John').text.should == 'Monkey John'
        @session.find(:monkey, '2', :name => 'Monkey Paul').text.should == 'Monkey Paul'
      end

      it "should not find elements that don't match the filter" do
        expect { @session.find(:monkey, '2', :name => 'Monkey John') }.to raise_error(Capybara::ElementNotFound)
        expect { @session.find(:monkey, '1', :name => 'Monkey Paul') }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context "with css as default selector" do
      before { Capybara.default_selector = :css }
      it "should find the first element using the given locator" do
        @session.find('h1').text.should == 'This is a test'
        @session.find("input[id='test_field']")[:value].should == 'monkey'
      end
      after { Capybara.default_selector = :xpath }
    end

    it "should raise ElementNotFound with a useful default message if nothing was found" do
      running do
        @session.find(:xpath, '//div[@id="nosuchthing"]').should be_nil
      end.should raise_error(Capybara::ElementNotFound, "Unable to find xpath \"//div[@id=\\\"nosuchthing\\\"]\"")
    end

    it "should accept an XPath instance" do
      @session.visit('/form')
      @xpath = XPath::HTML.fillable_field('First Name')
      @session.find(@xpath).value.should == 'John'
    end

    context "within a scope" do
      before do
        @session.visit('/with_scope')
      end

      it "should find the an element using the given locator" do
        @session.within(:xpath, "//div[@id='for_bar']") do
          @session.find('.//li[1]').text.should =~ /With Simple HTML/
        end
      end
    end
  end
end
