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

data:extend({
    {
        type = "string-setting",
        name = "simplified-tier-based-cost-reduction",
        setting_type = "startup",
        default_value = "moderate",
        allowed_values = {"none", "minor", "decent", "moderate", "serious", "immense"}
    }
})

data:extend({
    {
        type = "string-setting",
        name = "simplified-tier-based-cost-reduction-for-technology",
        setting_type = "startup",
        default_value = "none",
        allowed_values = {"none", "minor", "decent", "moderate", "serious", "immense"}
    }
})

data:extend({
    {
        type = "string-setting",
        name = "simplified-item-count-crop-strategy",
        setting_type = "startup",
        default_value = "none",
        allowed_values = {"none", "onehalf", "onethird", "max4", "max3", "max2", "max1"}
    }
})

