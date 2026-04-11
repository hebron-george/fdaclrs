module ApplicationHelper
  # Tailwind color palette for center badges.
  # Colors are chosen to be visually distinct and readable on white backgrounds.
  BADGE_PALETTE = [
    "bg-blue-100 text-blue-800",
    "bg-purple-100 text-purple-800",
    "bg-teal-100 text-teal-800",
    "bg-green-100 text-green-800",
    "bg-orange-100 text-orange-800",
    "bg-pink-100 text-pink-800",
    "bg-yellow-100 text-yellow-800",
    "bg-cyan-100 text-cyan-800",
    "bg-rose-100 text-rose-800",
    "bg-indigo-100 text-indigo-800",
    "bg-lime-100 text-lime-800",
    "bg-amber-100 text-amber-800",
  ].freeze

  # Returns a deterministic Tailwind color class string for a given center name.
  # The same string always maps to the same color, across requests and deployments.
  def badge_classes_for(center_name)
    index = center_name.bytes.sum % BADGE_PALETTE.size
    BADGE_PALETTE[index]
  end

  # Renders a single colored pill badge for a center string.
  def center_badge(center_name)
    return "".html_safe if center_name.blank?

    content_tag(:span, center_name,
      class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{badge_classes_for(center_name)}"
    )
  end

  # Renders a row of pill badges for an array of center strings.
  def center_badges(centers)
    return "".html_safe if centers.blank?

    safe_join(centers.map { |c| center_badge(c) }, " ".html_safe)
  end
end
