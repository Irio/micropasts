# coding: utf-8
require 'spec_helper'

describe Project do
  let(:project){ build(:project, goal: 3000) }
  let(:user){ create(:user) }
  let(:channel){ create(:channel, user: user) }
  let(:channel_project){ create(:project, channels: [ channel ]) }

  describe "associations" do
    it{ should belong_to :user }
    it{ should belong_to :category }
    it{ should have_many :contributions }
    it{ should have_many :rewards }
    it{ should have_many :updates }
    it{ should have_many :notifications }
    it{ should have_many :project_faqs }
    it{ should have_many :project_documents }
    it{ should have_and_belong_to_many :channels }
    it{ should have_many :unsubscribes }
    it{ should have_one  :project_total }
  end

  describe "validations" do
    %w[name user category about headline goal permalink].each do |field|
      it{ should validate_presence_of field }
    end
    it{ should ensure_length_of(:headline).is_at_most(140) }
    it{ should allow_value('http://vimeo.com/12111').for(:video_url) }
    it{ should allow_value('vimeo.com/12111').for(:video_url) }
    it{ should allow_value('https://vimeo.com/12111').for(:video_url) }
    it{ should allow_value('http://youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ should allow_value('youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ should allow_value('https://youtube.com/watch?v=UyU-xI').for(:video_url) }
    it{ should_not allow_value('http://www.foo.bar').for(:video_url) }
    it{ should allow_value('testproject').for(:permalink) }
    it{ should_not allow_value('users').for(:permalink) }
  end

  describe ".with_contributions_confirmed_today" do
    let(:project_01) { create(:project, state: 'online') }
    let(:project_02) { create(:project, state: 'online') }
    let(:project_03) { create(:project, state: 'online') }

    subject { Project.with_contributions_confirmed_today }

    before do
      project_01
      project_02
      project_03
    end

    pending "when have confirmed contributions today" do
      before do

        #TODO: need to investigate this timestamp issue when
        # use DateTime.now or Time.now
        create(:contribution, state: 'confirmed', project: project_01, confirmed_at: 3.hours.from_now )
        create(:contribution, state: 'confirmed', project: project_02, confirmed_at: 2.days.ago )
        create(:contribution, state: 'confirmed', project: project_03, confirmed_at: 3.hours.from_now )
      end

      it { should have(2).items }
      it { subject.include?(project_02).should be_false }
    end

    context "when does not have any confirmed contribution today" do
      before do
        create(:contribution, state: 'confirmed', project: project_01, confirmed_at: 1.days.ago )
        create(:contribution, state: 'confirmed', project: project_02, confirmed_at: 2.days.ago )
        create(:contribution, state: 'confirmed', project: project_03, confirmed_at: 5.days.ago )
      end

      it { should have(0).items }
    end
  end

  describe ".visible" do
    before do
      [:draft, :rejected, :deleted].each do |state|
        create(:project, state: state)
      end
      @project = create(:project, state: :online)
    end
    subject{ Project.visible }
    it{ should == [@project] }
  end

  describe '.state_names' do
    let(:states) { [:draft, :soon, :rejected, :online, :successful, :waiting_funds, :failed] }

    subject { Project.state_names }

    it { should == states }
  end

  describe '.locations' do
    before do
      create(:project, location: 'San Francisco, CA')
      create(:project, location: 'Kansas City, MO')
      create(:project, location: 'Kansas City, MO')
      create(:project, location: 'Kansas City, KS', state: 'draft')
    end
    subject { Project.locations }
    it { should have(2).items }
  end

  describe ".find_by_permalink!" do
    context "when project is deleted" do
      before do
        @p = create(:project, permalink: 'foo', state: 'deleted')
        create(:project, permalink: 'bar')
      end
      it{ expect {Project.find_by_permalink!('foo')}.to raise_error(ActiveRecord::RecordNotFound) }
    end
    context "when project is not deleted" do
      before do
        @p = create(:project, permalink: 'foo')
        create(:project, permalink: 'bar')
      end
      subject{ Project.find_by_permalink!('foo') }
      it{ should == @p }
    end
  end

  describe '.order_by' do
    subject { Project.last.name }

    before do
      create(:project, name: 'lorem')
      #testing for sql injection
      Project.order_by("goal asc;update projects set name ='test';select * from projects ").first #use first so the sql is actually executed
    end

    it { should == 'lorem' }
  end

  describe '.between_created_at' do
    let(:start_at) { '17/01/2013' }
    let(:ends_at) { '20/01/2013' }
    subject { Project.between_created_at(start_at, ends_at) }

    before do
      @project_01 = create(:project, created_at: '19/01/2013')
      @project_02 = create(:project, created_at: '23/01/2013')
      @project_03 = create(:project, created_at: '26/01/2013')
    end

    it { should == [@project_01] }
  end

  describe '.to_finish' do
    before do
      Project.should_receive(:expired).and_call_original
      Project.should_receive(:with_states).with(['online', 'waiting_funds']).and_call_original
    end
    it "should call scope expired and filter states that can be finished" do
      Project.to_finish
    end
  end

  describe ".contributed_by" do
    before do
      contribution = create(:contribution, state: 'confirmed')
      @user = contribution.user
      @project = contribution.project
      # Another contribution with same project and user should not create duplicate results
      create(:contribution, user: @user, project: @project, state: 'confirmed')
      # Another contribution with other project and user should not be in result
      create(:contribution, state: 'confirmed')
      # Another contribution with different project and same user but not confirmed should not be in result
      create(:contribution, user: @user, state: 'pending')
    end
    subject{ Project.contributed_by(@user.id) }
    it{ should == [@project] }
  end

  describe ".expired" do
    before do
      @p = create(:project, online_days: -1)
      create(:project, online_days: 1)
    end
    subject{ Project.expired}
    it{ should == [@p] }
  end

  describe ".not_expired" do
    before do
      @p = create(:project, online_days: 1)
      create(:project, online_days: -1)
    end
    subject{ Project.not_expired }
    it{ should == [@p] }
  end

  describe ".expiring" do
    before do
      @p = create(:project, online_date: Time.now, online_days: 13)
      create(:project, online_date: Time.now, online_days: -1)
    end
    subject{ Project.expiring }
    it{ should == [@p] }
  end

  describe ".not_expiring" do
    before do
      @p = create(:project, online_days: 15)
      create(:project, online_days: -1)
    end
    subject{ Project.not_expiring }
    it{ should == [@p] }
  end

  describe ".recent" do
    before do
      @p = create(:project, online_date: (Time.now - 4.days))
      create(:project, online_date: (Time.now - 15.days))
    end
    subject{ Project.recent }
    it{ should == [@p] }
  end

  describe ".not_soon" do
    before do
      @p = create(:project, state: 'online')
      create(:project, state: 'soon')
    end
    subject{ Project.not_soon}
  end

  describe '#reached_goal?' do
    let(:project) { create(:project, goal: 3000) }
    subject { project.reached_goal? }

    context 'when sum of all contributions hit the goal' do
      before do
        create(:contribution, value: 4000, project: project)
      end
      it { should be_true }
    end

    context "when sum of all contributions don't hit the goal" do
      it { should be_false }
    end
  end

  describe '#in_time_to_wait?' do
    let(:contribution) { create(:contribution, state: 'waiting_confirmation') }
    subject { contribution.project.in_time_to_wait? }

    context 'when project expiration is in time to wait' do
      it { should be_true }
    end

    context 'when project expiration time is not more on time to wait' do
      let(:contribution) { create(:contribution, created_at: 1.week.ago) }
      it {should be_false}
    end
  end


  describe "#pg_search" do
    before { @p = create(:project, name: 'foo') }
    context "when project exists" do
      subject{ [Project.pg_search('foo'), Project.pg_search('fóõ')] }
      it{ should == [[@p],[@p]] }
    end
    context "when project is not found" do
      subject{ Project.pg_search('lorem') }
      it{ should == [] }
    end
  end

  describe "#progress" do
    subject{ project.progress }
    let(:pledged){ 0.0 }
    let(:goal){ 0.0 }
    before do
        project.stub(:pledged).and_return(pledged)
        project.stub(:goal).and_return(goal)
    end

    context "when goal == pledged > 0" do
      let(:goal){ 10.0 }
      let(:pledged){ 10.0 }
      it{ should == 100 }
    end

    context "when goal is > 0 and pledged is 0.0" do
      let(:goal){ 10.0 }
      it{ should == 0 }
    end

    context "when goal is 0.0 and pledged > 0.0" do
      let(:pledged){ 10.0 }
      it{ should == 0 }
    end

    context "when goal is 0.0 and pledged is 0.0" do
      it{ should == 0 }
    end
  end

  describe "#pledged_and_waiting" do
    subject{ project.pledged_and_waiting }
    before do
      @confirmed = create(:contribution, value: 10, state: 'confirmed', project: project)
      @waiting = create(:contribution, value: 10, state: 'waiting_confirmation', project: project)
      create(:contribution, value: 100, state: 'refunded', project: project)
      create(:contribution, value: 1000, state: 'pending', project: project)
    end
    it{ should == @confirmed.value + @waiting.value }
  end

  describe "#pledged" do
    subject{ project.pledged }
    context "when project_total is nil" do
      before do
        project.stub(:project_total).and_return(nil)
      end
      it{ should == 0 }
    end
    context "when project_total exists" do
      before do
        project_total = mock()
        project_total.stub(:pledged).and_return(10.0)
        project.stub(:project_total).and_return(project_total)
      end
      it{ should == 10.0 }
    end
  end

  describe "#total_payment_service_fee" do
    subject { project.total_payment_service_fee }

    context "when project_total is nil" do
      before { project.stub(:project_total).and_return(nil) }
      it { should == 0 }
    end

    context "when project_total exists" do
      before do
        project_total = mock()
        project_total.stub(:total_payment_service_fee).and_return(4.0)
        project.stub(:project_total).and_return(project_total)
      end

      it { should == 4.0 }
    end
  end

  describe "#total_contributions" do
    subject{ project.total_contributions }
    context "when project_total is nil" do
      before do
        project.stub(:project_total).and_return(nil)
      end
      it{ should == 0 }
    end
    context "when project_total exists" do
      before do
        project_total = mock()
        project_total.stub(:total_contributions).and_return(1)
        project.stub(:project_total).and_return(project_total)
      end
      it{ should == 1 }
    end
  end

  describe "#expired?" do
    subject{ project.expired? }

    context "when online_date is nil" do
      let(:project){ Project.new online_date: nil, online_days: 0 }
      it{ should be_false }
    end

    context "when expires_at is in the future" do
      let(:project){ Project.new online_date: 2.days.from_now, online_days: 0 }
      it{ should be_false }
    end

    context "when expires_at is in the past" do
      let(:project){ Project.new online_date: 2.days.ago, online_days: 0 }
      it{ should be_true }
    end
  end

  describe "#expires_at" do
    subject{ project.expires_at }
    context "when we do not have an online_date" do
      let(:project){ build(:project, online_date: nil, online_days: 0) }
      it{ should be_nil }
    end
    context "when we have an online_date" do
      let(:project){ build(:project, online_date: Time.now, online_days: 0) }
      it{ should == Time.zone.now.end_of_day }
    end
  end

  describe '#selected_rewards' do
    let(:project){ create(:project) }
    let(:reward_01) { create(:reward, project: project) }
    let(:reward_02) { create(:reward, project: project) }
    let(:reward_03) { create(:reward, project: project) }

    before do
      create(:contribution, state: 'confirmed', project: project, reward: reward_01)
      create(:contribution, state: 'confirmed', project: project, reward: reward_03)
    end

    subject { project.selected_rewards }
    it { should == [reward_01, reward_03] }
  end

  describe "#last_channel" do
    let(:channel){ create(:channel) }
    let(:project){ create(:project, channels: [ create(:channel), channel ]) }
    subject{ project.last_channel }
    it{ should == channel }
  end

  describe '#pending_contributions_reached_the_goal?' do
    let(:project) { create(:project, goal: 200) }

    before { project.stub(:pleged) { 100 } }

    subject { project.pending_contributions_reached_the_goal? }

    context 'when reached the goal with pending contributions' do
      before { 2.times { create(:contribution, project: project, value: 120, state: 'waiting_confirmation') } }

      it { should be_true }
    end

    context 'when dont reached the goal with pending contributions' do
      before { 2.times { create(:contribution, project: project, value: 30, state: 'waiting_confirmation') } }

      it { should be_false }
    end
  end

  describe "#new_draft_recipient" do
    subject { project.new_draft_recipient }
    context "when project does not belong to any channel" do
      before do
        Configuration[:email_projects] = 'admin_projects@foor.bar'
        @user = create(:user, email: Configuration[:email_projects])
      end
      it{ should == @user }
    end

    context "when project belongs to a channel" do
      let(:project) { channel_project }
      it{ should == user }
    end
  end

  describe "#notification_type" do
    subject { project.notification_type(:foo) }
    context "when project does not belong to any channel" do
      it { should eq(:foo) }
    end

    context "when project does belong to a channel" do
      let(:project) { channel_project }
      it{ should eq(:foo_channel) }
    end
  end

  describe 'Taggable' do
    describe 'associations' do
      it{ should have_many(:tags).through(:taggings) }
      it{ should have_many :taggings }
    end

    describe 'TagList' do
      context 'should split the list' do
        subject { Taggable::TagList.new 'Tag 1, Tag 2, Tag 3' }

        context '#initializer' do
          it { should == ['tag 1', 'tag 2', 'tag 3'] }
        end

        context '#to_s' do
          it { expect(subject.to_s).to eq 'tag 1, tag 2, tag 3' }
        end
      end
    end

    describe '#tag_list' do
      before do
        project.tags = ['Tag 1', 'Tag 2', 'Tag 3'].map {|tag_name| Tag.find_or_create_by(name: tag_name.downcase) }
      end

      it { expect(project.tag_list).to have(3).tags }
    end

    describe '#tag_list=' do
      context 'as method' do
        before do
          project.tag_list = 'Tag 1, Tag 2, Tag 3, Tag 4'
          project.save
        end

        it { expect(project.tags).to have(4).tags }
      end

      context 'as attribute' do
        let(:project_with_tags) { create(:project, tag_list: 'Tag 1, Tag 2') }

        it { expect(project_with_tags.tags).to have(2).tags }
      end

      context 'unassign tags' do
        before do
          project.tag_list = 'Tag 1, Tag 2, Tag 3, Tag 4'
          project.save

          project.tag_list = 'Tag 1, Tag 2, Tag 3'
          project.save
          project.reload
        end

        it { expect(project.tags).to have(3).tags }
      end
    end
  end

  describe "campaign types" do
    let(:project) { create(:project, campaign_type: 'all_or_none') }

    describe "#all_or_none?" do
      subject { project.all_or_none? }

      context "when project is new" do
        it { should be_true }
      end
    end

    describe "#flexible?" do
      let(:project) { create(:project, campaign_type: 'flexible') }

      subject { project.flexible? }

      context "when change campaign type to flexible" do
        it { should be_true }
      end
    end
  end

  describe 'paid?' do
    subject { create(:project, state: 'online') }
    before { Configuration[:platform_fee] = 0.1 }

    it 'returns false when no payouts are recorded for the contributions' do
      create(:contribution, project: subject, payment_method: 'paypal')
      expect(subject).to_not be_paid
    end

    it 'returns false when amount already paid to project owner doesnt match the net amount of contributions' do
      create(:contribution, project: subject, payment_method: 'paypal',       value: 100)
      create(:contribution, project: subject, payment_method: 'authorizenet', value: 200)
      create(:payout, value: 90, project: subject)
      expect(subject).to_not be_paid
    end

    it 'returns true when payout amount matches the net amount of contributions' do
      create(:contribution, project: subject, payment_method: 'paypal', value: 100)
      create(:payout, value: 90, project: subject)
      expect(subject).to be_paid
    end
  end
end
