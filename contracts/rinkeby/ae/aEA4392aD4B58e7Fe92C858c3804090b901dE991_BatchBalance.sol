pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract BatchBalance {
	function getBalances(address user, IERC20[] memory tokenAddresses) public view returns (uint256[] memory balance) {
		balance = new uint256[](tokenAddresses.length);
		for(uint256 i = 0; i < tokenAddresses.length; i ++) {
			balance[i] = tokenAddresses[i].balanceOf(user);
		}
	}
}