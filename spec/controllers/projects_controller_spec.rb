require 'spec_helper'
describe ProjectsController do
  describe 'GET index' do
    before(:each){ get :index, :locale => 'pt' }
    it{ assigns(:title).should == 'A primeira plataforma de financiamento colaborativo de projetos criativos do Brasil' }
    it{ assigns(:home_page).should == [] }
    #@home_page = current_site.present_projects.includes(:user, :category).visible.home_page.limit(6).order('projects_sites."order"').all
    #@recommended = current_site.present_projects.includes(:user, :category).visible.recommended.not_home_page.not_successful.not_unsuccessful.order('created_at DESC').limit(12).all
    #@recent = current_site.present_projects.includes(:user, :category).visible.not_home_page.not_recommended.not_successful.not_unsuccessful.order('created_at DESC').limit(12).all
    #@successful = current_site.present_projects.includes(:user, :category).visible.not_home_page.successful.order('expires_at DESC').limit(12).all
  end
  it "should confirm backer in moip payment" do
    backer = Factory(:backer, :confirmed => false)
    post :moip, {:id_transacao => backer.key, :status_pagamento => '1', :valor => backer.moip_value}
    response.should be_successful
    backer.reload.confirmed.should be_true 
  end
  it "should not confirm in case of error in moip payment" do
    backer = Factory(:backer, :confirmed => false)
    post :moip, {:id_transacao => -1, :status_pagamento => '1', :valor => backer.moip_value}
    response.should_not be_successful
    backer.reload.confirmed.should_not be_true
  end
end
