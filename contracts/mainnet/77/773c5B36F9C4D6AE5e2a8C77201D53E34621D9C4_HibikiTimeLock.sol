/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

/**
 * Locks specific token address for some time.
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HibikiTimeLock {

	address public owner;
	address public lockedToken;
    uint32 public lockTime = 30 days;
    uint32 public lastLock;

    modifier unlocked {
        require(block.timestamp - lastLock > lockTime, "Tokens are currently locked.");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "No permission.");
        _;
    }

	constructor(address bikky) {
		owner = msg.sender;
		lockedToken = bikky;
	}

	function setHibiki(address b) external unlocked onlyOwner {
		lockedToken = b;
	}

    /**
     * @dev This contract only locks a single token at once, so no need for approval and transferFrom.
     * This is cheaper.
     */
    function lock() external onlyOwner {
        lastLock = uint32(block.timestamp);
    }

	function withdraw() external unlocked onlyOwner {
		IERC20 bikky = IERC20(lockedToken);
		bikky.transfer(msg.sender, bikky.balanceOf(address(this)));
	}

    function recover(address tok) external onlyOwner {
        require(tok != lockedToken, "You cannot recover locked tokens.");
		IERC20 t = IERC20(tok);
		t.transfer(msg.sender, t.balanceOf(address(this)));
	}

    function setLockTime(uint32 t) external unlocked onlyOwner {
        lockTime = t;
    }
}