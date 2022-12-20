// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GlobiumEvents {
	// token
	event TreasuryUpdated(address indexed newTreasury);

	function emitTreasuryUpdated(address newTreasury) external {
		emit TreasuryUpdated(newTreasury);
	}

	event Transfer(address indexed from, address indexed to, uint256 value);

	function emitTransfer(address to, uint256 value) external {
		emit Transfer(msg.sender, to, value);
	}

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);

	function emitApproval(address spender, uint256 value) external {
		emit Approval(msg.sender, spender, value);
	}

	// wallet
	event ExecutionResult(bool success, bytes result);

	function emitExecutionResult(bool success, bytes calldata result) external {
		emit ExecutionResult(success, result);
	}

	event EtherTransfer(
		address indexed sender,
		address indexed recipient,
		uint256 amount
	);

	function emitEtherTransfer(address recipient, uint256 amount) external {
		emit EtherTransfer(msg.sender, recipient, amount);
	}

	// staking
	event NewInterestRate(
		uint256 indexed newRate,
		uint256 indexed epochNumber,
		uint256 epochStartTime,
		uint256 previousRewardRatePerSecondPerToken,
		uint256 durationOfLastEpoch,
		uint256 accumulatedPerSecPerTokenRate
	);
	event Staked(
		address indexed staker,
		uint256 amount,
		uint256 userBalance,
		uint256 indexed epochNumber,
		uint256 accumulatedRewardBeforeUpdate
	);
	event StakeFor(
		address indexed benefactor,
		address indexed beneficiary,
		uint256 amount,
		uint256 userBalance,
		uint256 indexed epochNumber,
		uint256 accumulatedRewardBeforeUpdate
	);
	event Unstaked(
		address indexed caller,
		uint256 amount,
		uint256 userBalance,
		uint256 indexed epochNumber
	);
	event ClaimedRewards(
		address indexed staker,
		uint256 rewardAmount,
		uint256 userBalance
	);
	event ClaimedRewardsAndStaked(
		address indexed staker,
		uint256 rewardAmount,
		uint256 userBalance
	);
	event Exit(
		address indexed staker,
		uint256 userBalance,
		uint256 rewardAmount
	);

	// reward pool
	event StakingContractSet(address indexed contractAddress);

	function emitStakingContractSet(address newAddress) external {
		emit StakingContractSet(newAddress);
	}

	// swap handler uniswap v3
	event SwapExecuted(
		address indexed tokenIn,
		address indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut,
		uint256 amountOutMinimum,
		uint256 amountInMaximum
	);

	function emitSwapExecuted(
		address src,
		address dst,
		uint256 amountIn,
		uint256 amountOut,
		uint256 amountOutMinimum,
		uint256 amountInMaximum
	) external {
		emit SwapExecuted(
			src,
			dst,
			amountIn,
			amountOut,
			amountOutMinimum,
			amountInMaximum
		);
	}
}