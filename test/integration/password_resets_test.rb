require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
    def setup
        ActionMailer::Base.deliveries.clear
        @user = users(:michael)
    end

    test "password resets" do
        get new_password_reset_path
        assert_template 'password_resets/new'
        # address is not invalid
        post password_resets_path, params:{password_reset:{email:""}}
        assert_not flash.empty?
        assert_template 'password_resets/new'
        # address is invalid
        post password_resets_path, params:{password_reset:{email: @user.email}}
        assert_not_equal @user.reset_digest, @user.reload.reset_digest
        assert_equal 1, ActionMailer::Base.deliveries.size
        assert_not flash.empty?
        assert_redirected_to root_url
        # form for password reset
        user = assigns(:user)
        # address is not invalid
        get edit_password_reset_path(user.reset_token, email:"")
        assert_redirected_to root_url
        # invalid user
        user.toggle!(:activated)
        get edit_password_reset_path(user.reset_token, email:user.email)
        assert_redirected_to root_url
        user.toggle!(:activated)
        # address is invalid and token is no t invalid
        get edit_password_reset_path('wrong token', email: user.email)
        assert_redirected_to root_url
        # address and token are invalid
        get edit_password_reset_path(user.reset_token, email:user.email)
        assert_template 'password_resets/edit'
        assert_select "input[name=email][type=hidden][value=?]", user.email
        # invalid password and confirmation
        patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: "foobaz", password_confirmation: "barqux"}}
        assert_select 'div#error_explanation'
        # password is empty
        patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: "", password_confirmation: ""}}
        assert_select 'div#error_explanation'
        # invalid password and confirmation
        patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: "foobaz", password_confirmation:"foobaz"}}
        assert is_logged_in?
        assert_not flash.empty?
        assert_redirected_to user
    end
end
