--!strict
-- Game passes and developer products. Ids are 0 until created on the Creator Dashboard (Monetization); an item with
-- id 0 must show as "Coming soon". Robux prices here are for reference only: the live price comes from
-- MarketplaceService. Nothing sold for Robux may give a gameplay advantage over free players.
type MonetizationConfig = {
	GamePasses: { [string]: { Id: number, PriceRobux: number } },
	Products: { [string]: { Id: number, PriceRobux: number } },
	-- Web calls (pass ownership, policy) are retried this many times, Delay seconds apart.
	WebRetries: { Attempts: number, Delay: number },
}

local Monetization: MonetizationConfig = {
	GamePasses = {},
	Products = {},
	WebRetries = { Attempts = 3, Delay = 2 },
}

return Monetization
