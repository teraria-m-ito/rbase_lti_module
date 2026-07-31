module LTI
  class LTIGrade
    include ActiveModel::Model
    include ::SelectableAttr::Base

    @score_given = nil
    @score_maximum = nil
    @comment = nil
    @activity_progress = nil
    @grading_progress = nil
    @timestamp = nil
    @user_id = nil
    @submission_review = nil

    selectable_attr :activity_progress do
      entry "Initialized", :initialized, "活動未開始"
      entry "Started", :started, "活動開始"
      entry "InProgress", :in_progress, "活動中"
      entry "Submitted", :submitted, "提出済"
      entry "Completed", :completed, "活動完了"
    end

    selectable_attr :grading_progress do
      entry "FullyGraded", :fully_graded, '最終評定済'
      entry "Pending", :pending, '評定待ち(自動採点)'
      entry "PendingManual", :pending_manual, '評定待ち(手動採点)'
    end

    def self.instance
      ::LTI::LTIGrade.new
    end
      
    def get_score_given
      @score_given
    end
    
    def set_score_given(value)
      @score_given = value
      
      self
    end

    def get_score_maximum
      @score_maximum
    end
    
    def set_score_maximum(value)
      @score_maximum = value
      
      self
    end

    def get_comment
      @comment
    end
    
    def set_comment(value)
      @comment = value
      
      self
    end

    def get_activity_progress
      @activity_progress
    end
    
    def set_activity_progress(value)
      @activity_progress = value
      
      self
    end

    def get_grading_progress
      @grading_progress
    end
    
    def set_grading_progress(value)
      @grading_progress = value
      
      self
    end

    def get_timestamp
      @timestamp
    end
    
    def set_timestamp(value)
      @timestamp = value
      
      self
    end

    def get_user_id
      @user_id
    end
    
    def set_user_id(value)
      @user_id = value
      
      self
    end

    def get_submission_review
      @submission_review
    end
    
    def set_submission_review(value)
      @submission_review = value
      
      self
    end

    def __toString
      return {
        scoreGiven: @score_given.to_f,
        scoreMaximum: @score_maximum.to_f,
        comment: @comment,
        activityProgress: @activity_progress,
        gradingProgress: @grading_progress,
        timestamp: @timestamp,
        userId: @user_id,
        submissionReview: @submission_review
      }
    end
  end
end