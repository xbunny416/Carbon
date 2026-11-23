--!strict
--[[
	Analytics — failure-safe wrapper over AnalyticsService. Every tracked event in the game goes through here so
	names stay consistent (tutorial steps, purchases, and the game's own events: add a named
	helper per event the bible lists, so call sites cannot drift).
]]
local AnalyticsService = game:GetService("AnalyticsService")

local FIELD_KEYS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

local Analytics = {
	Priority = -100, -- other services may log during their own Init

	-- Enum.AnalyticsEconomyTransactionType names.
	Transaction = {
		IAP = Enum.AnalyticsEconomyTransactionType.IAP.Name,
		Shop = Enum.AnalyticsEconomyTransactionType.Shop.Name,
		Gameplay = Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
		TimedReward = Enum.AnalyticsEconomyTransactionType.TimedReward.Name,
		Onboarding = Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
	},
}

-- Up to three custom field values (e.g. { modeId, mapId }).
local function customFields(values: { string }?): { [string]: string }?
	if values == nil then
		return nil
	end
	local fields: { [string]: string } = {}
	for index, value in values do
		local key = FIELD_KEYS[index]
		if key then
			fields[key] = value
		end
	end
	return fields
end

local function safely(label: string, callback: () -> ())
	xpcall(callback, function(err: unknown)
		warn(`[Analytics] {label} failed: {err}`)
	end)
end

-- Tutorial / onboarding funnel step (1-based, in order).
function Analytics.onboardingStep(player: Player, step: number, stepName: string)
	safely("onboardingStep", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- Generic custom event with an optional value and up to three custom fields.
function Analytics.custom(player: Player, eventName: string, value: number?, fields: { string }?)
	safely(eventName, function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1, customFields(fields))
	end)
end

-- Named events, so call sites cannot drift.
function Analytics.robuxPurchase(player: Player, kind: string, key: string, robux: number)
	Analytics.custom(player, "RobuxPurchase", robux, { kind, key })
end

return Analytics
