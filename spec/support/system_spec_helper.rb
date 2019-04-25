# frozen_string_literal: true

module SystemSpecHelper
  def signup(email, password)
    visit new_user_registration_path
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    fill_in 'Password confirmation', with: password
    click_button 'Sign up'
    expect(page).to have_text 'Welcome! You have signed up successfully.'
  end

  def logout
    visit destroy_user_session_path
  end

  def login(email, password)
    visit new_user_session_path
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    click_button 'Log in'
    expect(page).not_to have_text 'Invalid email or password.'
  end

  def deposit_permission_template_for(email)
    template = create(:permission_template, with_admin_set: true, with_workflows: true)
    create(:permission_template_access,
           :deposit,
           permission_template: template,
           agent_type: 'user',
           agent_id: email)
  end
end
