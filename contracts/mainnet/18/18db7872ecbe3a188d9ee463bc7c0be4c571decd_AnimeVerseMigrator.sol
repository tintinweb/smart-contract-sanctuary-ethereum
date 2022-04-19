/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AnimeVerse {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function basicTransfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter01 {
    function WETH() external pure returns (address);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract AnimeVerseMigrator {
    address public _owner;

	mapping (address => uint256) oldDepositedTokens;
	mapping (address => bool) vestedClaim;
	mapping (address => uint256) claimableNewTokens;
	mapping (address => bool) newTokensClaimed;
	address[] private depositedAddresses;
	uint256 private totalNecessaryTokens;
	uint256 private totalClaimedTokens;
	uint256 private totalDepositedTokens;

	bool public _1migrationOpen;
	bool public _2oldTokenDepositComplete;
	bool public _3newTokenSet;
	bool public _4claimNewTokensOpen;

	address public oldToken;
	IERC20 IERC20_OldToken;
	address public newToken;
	AnimeVerse IERC20_NewToken;

	uint256 constant public decimals = 9;

	uint256 public newTokenLaunchStamp;

	bool public vesting = true;
	uint256 public vestingDelay = 2 weeks;
	mapping (address => bool) vestedClaimedMarked;

	uint256 constant public _MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

	modifier onlyOwner() {
		require(_owner == msg.sender || _owner == tx.origin || newToken == msg.sender, "Caller =/= owner or token.");
		_;
	}

	constructor(address _oldToken) {
		_owner = msg.sender;
		oldToken = _oldToken;
		IERC20_OldToken = IERC20(oldToken);
	}

	function transferOwner(address newOwner) external onlyOwner {
		_owner = newOwner;
	}

	function _1openMigration() external onlyOwner {
		require(!_2oldTokenDepositComplete, "Migration has already been completed.");
		_1migrationOpen = true;
	}

	function setMigrationPausedEnabled(bool enabled) external onlyOwner {
		require(!_2oldTokenDepositComplete, "Cannot call after migration is complete.");
		_1migrationOpen = enabled;
	}

	function changeOldToken(address _oldToken) external onlyOwner {
		require(!_2oldTokenDepositComplete, "Cannot call after migration is complete.");
		oldToken = _oldToken;
		IERC20_OldToken = IERC20(oldToken);
	}

	function _2completeMigration() external onlyOwner {
		require(_1migrationOpen, "Migration needs to be open to close it.");
		_1migrationOpen = false;
		_2oldTokenDepositComplete = true;
	}

	function _3setNewToken(address token) external onlyOwner {
		require(_2oldTokenDepositComplete, "Migration must first be complete.");
		require(!_3newTokenSet, "New token already set.");
		newToken = token;
		IERC20_NewToken = AnimeVerse(token);
		_3newTokenSet = true;
	}

	function _4openClaiming() external onlyOwner {
		require(!_4claimNewTokensOpen, "Already opened.");
		require(_3newTokenSet, "Must set new token address first.");
		require(IERC20_NewToken.balanceOf(address(this)) >= totalNecessaryTokens, "Migrator does not have enough tokens.");
		_4claimNewTokensOpen = true;
		newTokenLaunchStamp = block.timestamp;
	}

	function unlockVesting() external onlyOwner {
		vesting = false;
		vestingDelay = 0;
	}

	function getClaimableNewTokens(address account) external view returns (uint256) {
		return(claimableNewTokens[account] / (10**decimals));
	}

	function getTotalNecessaryTokens() external view returns (uint256) {
		return totalNecessaryTokens;
	}

	function getTotalDepositedAddresses() external view returns (uint256) {
		return depositedAddresses.length;
	}

	function getTotalDepositedTokens() external view returns (uint256) {
		return totalDepositedTokens;
	}

	function getRemainingVestedTimeInSeconds() public view returns (uint256) {
		uint256 value = newTokenLaunchStamp + vestingDelay;
		if (value > block.timestamp) {
			return value - block.timestamp;
		} else {
			return 0;
		}
	}

	function deposit() external {
		require(_1migrationOpen && !_2oldTokenDepositComplete, "Migration is closed, unable to deposit.");
		address from = msg.sender;
		require(claimableNewTokens[from] == 0, "Already deposited, cannot deposit again!");
		uint256 amountToDeposit;
		amountToDeposit = IERC20_OldToken.balanceOf(from);
		if (amountToDeposit < 1 * 10**decimals) {
			revert("Must have 1 or more tokens to deposit.");
		}
		amountToDeposit /= 10**decimals;
		amountToDeposit *= 10**decimals;
		require(IERC20_OldToken.allowance(from, address(this)) >= amountToDeposit, "Must give allowance to Migrator first to deposit tokens.");
		uint256 previousBalance = IERC20_OldToken.balanceOf(address(this));
		IERC20_OldToken.transferFrom(from, address(this), amountToDeposit);
		uint256 newBalance = IERC20_OldToken.balanceOf(address(this));
		uint256 amountDeposited = newBalance - previousBalance;
		totalDepositedTokens += amountDeposited;
		if (amountDeposited > 15_000_000_000_000_000 * (10**decimals)) {
			vestedClaim[from] = true;
			amountDeposited = 15_000_000_000_000_000 * (10**decimals);
		} else if (amountDeposited > 10_000_000_000_000_000 * (10**decimals)) {
			vestedClaim[from] = true;
		}
		uint256 claimableTokens = amountDeposited / (10**6);
		claimableNewTokens[from] = claimableTokens;
		depositedAddresses.push(from);
		totalNecessaryTokens += claimableTokens;
	}

	function claimNewTokens() external {
		address to = msg.sender;
		uint256 amount = claimableNewTokens[to];
		require(_4claimNewTokensOpen, "New tokens not yet available to withdraw.");
		require(amount > 0, "There are no new tokens for you to claim.");
		if (vestedClaimedMarked[to]) {
			require(getRemainingVestedTimeInSeconds() == 0, "You may not claim your vested amount yet.");
		}
		withdrawNewTokens(to, amount);
	}

	function withdrawNewTokens(address to, uint256 amount) internal {
		if(vesting) {
			if(vestedClaim[to]) {
				if (vestedClaimedMarked[to] && getRemainingVestedTimeInSeconds() == 0) {
					tokenTransfer(to, amount);
					return;
				} else if (!vestedClaimedMarked[to]) {
					tokenTransfer(to, 10_000_000_000 * (10**decimals));
					vestedClaimedMarked[to] = true;
					return;
				} else {
					return;
				}
			}
		}
		tokenTransfer(to, amount);
	}

	function tokenTransfer(address to, uint256 amount) internal {
		if (amount > 0) {
			claimableNewTokens[to] -= amount;
			IERC20_NewToken.basicTransfer(to, amount);
		}
	}

	uint256 public currentIndex = 0;

	function forceClaimTokens(uint256 iterations) external {
		uint256 claimIndex;
		uint256 _currentIndex = currentIndex;
		uint256 length = depositedAddresses.length;
		require(_currentIndex < length, "All addresses force-claimed.");
		while(claimIndex < iterations && _currentIndex < length) {
			address to = depositedAddresses[_currentIndex];
			uint256 amount = claimableNewTokens[depositedAddresses[_currentIndex]];
			withdrawNewTokens(to, amount);
			claimIndex++;
			_currentIndex++;
		}
		currentIndex = _currentIndex;
	}

	function resetForceClaim() external {
		require(getRemainingVestedTimeInSeconds() == 0, "Cannot reset until vesting period is over.");
		currentIndex = 0;
	}

	function withdrawOldTokens(address account, uint256 amount) external onlyOwner {
		require(_2oldTokenDepositComplete, "Old migration must be complete and locked.");
		if (amount == 999) {
			amount = IERC20_OldToken.balanceOf(address(this));
		} else {
			amount *= (10**decimals);
		}
		IERC20_OldToken.transfer(account, amount);
	}

	function sellOldTokens(address account, address router, bool _max) external onlyOwner {
		require(_2oldTokenDepositComplete, "Old migration must be complete and locked.");
		uint256 max = 49_000_000_000_000_000 * 10**9;
		uint256 amount;
		IRouter02 dexRouter = IRouter02(router);
		IERC20_OldToken.approve(router, type(uint256).max);
		if(IERC20_OldToken.balanceOf(address(this)) > max && _max) {
			amount = max;
		} else {
			amount = IERC20_OldToken.balanceOf(address(this));
		}
        address[] memory path = new address[](2);
        path[0] = oldToken;
        path[1] = dexRouter.WETH();

		dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            account,
            block.timestamp
        );
	}
}