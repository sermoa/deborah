require File.dirname(__FILE__) + '/../spec_helper'

describe Contact do

  describe 'creating a new contact' do
    context 'name' do
      it 'populates the name when one is provided' do
        contact_name = 'CONTACT NAME'
        contact = Contact.new('title' => contact_name)
        contact.name.should == contact_name
      end

      it 'does not populate the name unless it is a string' do
        contact = Contact.new('title' => {'type' => 'text'})
        contact.name.should be_nil
      end
    end

    context 'email' do
      it 'populates the email address' do
        email = mock(:email)
        contact = Contact.new('gd:email' => {'primary' => 'true', 'address' => email})
        contact.email.should == email
      end

      it 'does not populate the email address if one does not exist' do
        contact = Contact.new()
        contact.email.should be_nil
      end

      it 'populates the primary email address if there is more than one' do
        primary_email = mock(:email)
        contact = Contact.new('gd:email' => [{'primary' => 'true', 'address' => primary_email}, {'address' => 'other email'}])
        contact.email.should == primary_email
      end
    end

    context 'addresses' do
      it 'populates the addresses if there are any' do
        address_string = 'ADDRESS'
        address = mock(:address)
        Address.should_receive(:new).with(address_string).and_return(address)
        contact = Contact.new('gd:postalAddress' => address_string)
        contact.addresses.should == [address]
      end

      it 'does not populate the addresses if none are given' do
        contact = Contact.new()
        contact.addresses.should == []
      end

      it 'deals with multiple addresses' do
        address1 = mock(:address)
        address2 = mock(:address)
        address_string_1 = 'ADDRESS1'
        address_string_2 = 'ADDRESS2'
        Address.stub!(:new).with(address_string_1).and_return(address1)
        Address.stub!(:new).with(address_string_2).and_return(address2)
        contact = Contact.new('gd:postalAddress' => [address_string_1, address_string_2])
        contact.addresses.should == [address1, address2]
      end
    end
  end

  describe 'contact title' do
    it 'uses the name if it has one' do
      contact_name = 'CONTACT NAME'
      contact = Contact.new('title' => contact_name)
      contact.title.should == contact_name
    end

    it 'uses the email if there is no name' do
      email = mock(:email)
      contact = Contact.new('gd:email' => {'primary' => 'true', 'address' => email})
      contact.title.should == email
    end
  end

  describe 'fetching contacts from Google' do
    before do
      @result = ''
      Connector.stub!(:get_request => @result)
      Crack::XML.stub!(:parse => {'feed' => {'entry' => []}})
    end

    it 'makes the request to Google Contacts' do
      Connector.should_receive(:get_request).with('https://www.google.com/m8/feeds/contacts/default/thin', anything, anything)
      Contact.all({})
    end

    it 'asks for a high number of contacts to avoid pagination' do
      params = hash_including('max-results' => 1000)
      Connector.should_receive(:get_request).with(anything, params, anything)
      Contact.all({})
    end

    it 'parses the results' do
      Crack::XML.should_receive(:parse).with(@result)
      Contact.all({})
    end

    it 'creates contacts from the results' do
      entry1 = mock(:entry)
      entry2 = mock(:entry)
      Crack::XML.stub!(:parse => {'feed' => {'entry' => [entry1, entry2]}})
      Contact.should_receive(:new).with(entry1)
      Contact.should_receive(:new).with(entry2)
      Contact.all({})
    end

    it 'provides an array of contacts' do
      contact = mock(:contact)
      Crack::XML.stub!(:parse => {'feed' => {'entry' => [mock]}})
      Contact.stub!(:new => contact)
      Contact.all({}).should == [contact]
    end
  end
end
