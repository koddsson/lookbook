require "rails_helper"

module Lookbook
  module Panels
    RSpec.describe PanelError do
      context ".new" do
        it "is an StandardError instance" do
          expect(PanelError.new).to be_a StandardError
        end
      end
    end
  end
end
