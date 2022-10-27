/**
 *Submitted for verification at Etherscan.io on 2020-09-24
 */

/**
 *Submitted for verification at Etherscan.io on 2020-08-06
 */

pragma solidity 0.8.17;

/**
 * @title External Access Controlled Aggregator Proxy
 * @notice A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * Aggregator and AggregatorV3Interface but delegates where it reads from to the owner, who is
 * trusted to update it.
 * @notice Only access enabled addresses are allowed to access getters for
 * aggregated answers and round information.
 */
contract EACAggregatorProxy {
	function latestRoundData()
		public
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		return (
			18446744073709557684,
			154680424830,
			1666886832,
			1666886832,
			18446744073709557684
		);
	}

	function decimals() external view returns (uint8) {
		return 8;
	}
}