class SearchController < ApplicationController

  def show
    if params[:geoloc]
      @geoloc = GeoKit::GeoLoc.new(params[:geoloc])
      @geoloc.success = true
    elsif params[:address].present?
      if BogusAddress.include?(params[:address])
        invalid_address
        return
      end
      params[:address].sub!('#', 'Apt. ')
      @geoloc = GeoKit::Geocoders::GoogleGeocoder.geocode(params[:address])
      
      if @geoloc.all.size > 1
        render :action => :multiple
        return
      end

      unless @geoloc.success
        invalid_address
        return
      end
    else
      invalid_address
      return
    end

    @letter = Letter.new(
      :sender_attributes => {
        :street     => @geoloc.street_address,
        :city       => @geoloc.city,
        :state      => @geoloc.state,
        :zip        => @geoloc.zip
      },
      :campaign_id => params[:campaign_id]
    )

    if @letter.sender.street.blank?
      invalid_address
      return
    end

    @letter.build_recipients(@geoloc)
  end

  private

  def invalid_address
    @address_error = 'Valid home address is required'
    render :template => 'home/index'
  end
end
