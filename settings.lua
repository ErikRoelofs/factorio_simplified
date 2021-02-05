require "functions/settings"

data:extend({
    {
        type = "string-setting",
        name = "simplified-max-intermediate-tier",
        setting_type = "startup",
        default_value = "tier-1",
        allowed_values = {"tier-0", "tier-1", "tier-2", "tier-3", "tier-4", "tier-5", "tier-6", "tier-7",
          "tier-8", "tier-9", "tier-10", "tier-11", "tier-12", "tier-13", "tier-14"}
    }
})