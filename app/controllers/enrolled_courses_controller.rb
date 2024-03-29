class EnrolledCoursesController < ApplicationController
  before_action :set_enrolled_course, only: %i[ show edit update destroy ]
  before_action :mark_prams, only: %i[create_marks]
  before_action :semesters

  # GET /enrolled_courses or /enrolled_courses.json
  def index
    @enrolled_courses = EnrolledCourse.where(users_id: current_user.id, semester_id: current_user.semester_id)
  end

  # GET /enrolled_courses/1 or /enrolled_courses/1.json
  def show
  end

  # GET /enrolled_courses/new
  def new
    @enrolled_course = EnrolledCourse.new
  end

  # GET /enrolled_courses/1/edit
  def edit
  end

  # POST /enrolled_courses or /enrolled_courses.json
  def create
    @enrolled_course = EnrolledCourse.new(enrolled_course_params)

    respond_to do |format|
      if @enrolled_course.save
        format.html { redirect_to users_dashboard_path, notice: 'Enrolled course was successfully created.' }
        format.json { render :show, status: :created, location: @enrolled_courses }
      else
        if @enrolled_course.errors[:course_id].include?("has already been enrolled by the user")
          format.html { redirect_to users_dashboard_path, notice: 'You are already enrolled in this course.' }
        else
          format.html { render :new }
        end
        format.json { render json: @enrolled_course.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_marks
    find_user = User.find(params[:id])
    @semesters = Semester.all
    next_semester = nil
    @errors = []

    @semesters.each_with_index do |semester, index|
      if semester.id == find_user.semester_id
        next_semester = @semesters[index + 1] if index + 1 < @semesters.length
        break
      end
    end

    params[:marks].each do |course_id, marks|
      if marks.blank?
        @errors << "Mark is required for course ID #{course_id}."
      elsif marks.to_i > 100
        @errors << "Mark cannot exceed 100 for course ID #{course_id}."
      else
        enrolled_course = find_user.enrolled_courses.find_by(id: course_id)
        unless enrolled_course
          @errors << "Failed to update marks for course with ID #{course}."
          next
        end
        enrolled_course.update(marks: marks)
      end
    end

    if @errors.any?
      flash[:alert] = @errors.join(" ").html_safe
      redirect_to mark_students_path(semester_id: params[:semester_id])
      return
    end

    if params[:semester_id] == find_user.semester_id.to_s && next_semester.present?
      find_user.update(semester_id: next_semester.id)
    else
      flash[:notice] = "You have reached the last semester."
    end

    redirect_to students_list_path, notice: "Marks updated successfully."
  end




  # PATCH/PUT /enrolled_courses/1 or /enrolled_courses/1.json
  def update
    respond_to do |format|
      if @enrolled_course.update(enrolled_course_params)
        format.html { redirect_to enrolled_course_url(@enrolled_course), notice: "Enrolled course was successfully updated." }
        format.json { render :show, status: :ok, location: @enrolled_course }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @enrolled_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /enrolled_courses/1 or /enrolled_courses/1.json
  def destroy
    @enrolled_course.destroy!

    respond_to do |format|
      format.html { redirect_to enrolled_courses_url, notice: "Enrolled course was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_enrolled_course
    @enrolled_course = current_user.enrolled_courses.find_by(id: params[:id])

    unless @enrolled_course
      flash[:alert] = "Enrolled course not found or doesn't belong to the current user."
      redirect_to enrolled_courses_path
    end
  end

  def mark_prams
    params.permit(:semester_id, marks: {})
  end


  # Only allow a list of trusted parameters through.
  def enrolled_course_params
    params.require(:enrolled_course).permit(:course_id, :semester_id, :users_id)
  end

  def semesters
    @semesters = Semester.all
  end
end
