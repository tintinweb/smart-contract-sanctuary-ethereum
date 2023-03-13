/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.7;

interface StakingPool {
	function balanceOf(address spender) external view returns (uint);
	function lockedShares(address spender) external view returns (uint);
}

contract adexStakingSpendable {
	function balanceOf(address who) external view returns (uint256 balance) {
		StakingPool adexStaking = StakingPool(0xB6456b57f03352bE48Bf101B46c1752a0813491a);
		uint adexStakingBalance = adexStaking.balanceOf(who);
		uint lockedShares = adexStaking.lockedShares(who);
		if (lockedShares > adexStakingBalance) return 0;
		return adexStakingBalance - lockedShares;
	}
}