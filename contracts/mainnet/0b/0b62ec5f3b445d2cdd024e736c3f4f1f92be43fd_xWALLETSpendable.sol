pragma solidity ^0.8.7;
import "./xWALLET.sol";

contract xWALLETSpendable {
	function balanceOf(address who) external view returns (uint256 balance) {
		StakingPool xWALLET = StakingPool(0x47Cd7E91C3CBaAF266369fe8518345fc4FC12935);
		return xWALLET.balanceOf(who) - xWALLET.lockedShares(who);
	}
}