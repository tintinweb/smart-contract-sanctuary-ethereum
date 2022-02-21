// SPDX-License-Identifier: MIT

// HOLD SOLID & EARN FREE SOLIDREWARDS
// MADE BY PRiNcE..

pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./SolidRewards.sol";

contract SolidRewardsOwnership is Ownable {

    SolidRewardCAKEDividendTracker public dividendTracker;

    constructor() public{

    	dividendTracker = new SolidRewardCAKEDividendTracker();

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
    }

    receive() external payable {

  	}
    function updateCAKE(address _CAKE) external onlyOwner{
        dividendTracker.updateCAKE(_CAKE);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function transferOwnershipOfDividendTracker(address newOwner) external onlyOwner{
        dividendTracker.transferOwnership(newOwner);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function updateWhitelist(address _whitelistAddress, bool status) external onlyOwner{
        dividendTracker.updateWhitelist(_whitelistAddress, status);
    }
}