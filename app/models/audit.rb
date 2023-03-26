# frozen_string_literal: true

class Audit < ApplicationRecord
  def as_json
    {
      edited_by: editor.name,
      created_at:,
      action:,
      record: "#{auditable_type}(#{auditable_id})",
      changes: audited_changes,
      comment:
    }
  end

  def editor
    Editor.build(self)
  end
end
