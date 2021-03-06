require 'rails_helper'

RSpec.describe Story, type: :model do
  # Association test
  it { should have_many(:tasks).dependent(:destroy) }
  it { should belong_to(:project) }
  # Validation tests
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:project_id) }

  it "should get a default status on save" do
    course = create(:course)
    project = create(:project, course_id: course.id)
    subject = create(:story, project_id: project.id)
    subject.status = nil
    expect(subject).to be_valid
    subject.save
    expect(subject.status).to be(Story.statuses[:open])
  end

  it "should get a default project_position on save" do
    course = create(:course)
    project = create(:project, course_id: course.id)
    subject = create(:story, project_id: project.id)
    expect(subject).to be_valid
    subject.save
    project_pos_record = ProjectPosition.find_by(story_id: subject.id, project_id: project.id)
    expect(project_pos_record).not_to be_nil
    expect(project_pos_record.position).to be_an_instance_of(Integer)
  end

  it "should get a default sprint_position if sprint was defined on save" do
    course = create(:course)
    project = create(:project, course_id: course.id)
    sprint = create(
        :sprint,
        course_id: course.id,
        start_date: Date.yesterday,
        end_date: Date.tomorrow
    )
    subject = create(:story, project_id: project.id, sprint_id: sprint.id)
    expect(subject).to be_valid
    subject.save
    sprint_pos_record = SprintPosition.find_by(story_id: subject.id, sprint_id: sprint.id)
    expect(sprint_pos_record).not_to be_nil
    expect(sprint_pos_record.position).to be_an_instance_of(Integer)
  end

  it "should get an identifier in the scope of the project on save" do
    course = create(:course)
    project = create(:project, course_id: course.id)
    first_subject = project.stories.new(title: 'Title')
    second_subject = project.stories.new(title: 'another Title')
    expect(first_subject.identifier).to be_nil
    expect(second_subject.identifier).to be_nil
    first_subject.save
    second_subject.save
    expect(first_subject.identifier).to eq('S-1')
    expect(second_subject.identifier).to eq('S-2')
  end

end