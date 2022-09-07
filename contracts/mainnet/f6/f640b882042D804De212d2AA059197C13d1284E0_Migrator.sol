/**
 *Submitted for verification at Etherscan.io on 2022-09-07
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

contract Migrator {
    address public _owner;

	mapping (address => uint256) oldDepositedTokens;
	mapping (address => bool) vestedClaim;
	mapping (address => uint256) claimableNewTokens;
	mapping (address => bool) newTokensClaimed;
	address[] private depositedAddresses;
	uint256 private totalNecessaryTokens;
	uint256 private totalClaimedTokens;
	uint256 private totalDepositedTokens;

	bool public migrationOpen;
	bool public claimingStatus;

	address public oldToken;
	IERC20 IERC20_OldToken;
	uint256 public oldTokenDecimals;
	address public newToken;
	IERC20 IERC20_NewToken;
	uint256 public newTokenDecimals;

	uint256 constant public _MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

	modifier onlyOwner() {
		require(_owner == msg.sender || _owner == tx.origin || newToken == msg.sender, "Caller =/= owner or token.");
		_;
	}

	constructor(address _oldToken) {
		_owner = msg.sender;
		oldToken = _oldToken;
		IERC20_OldToken = IERC20(oldToken);
		oldTokenDecimals = IERC20_OldToken.decimals();
	}

	function transferOwner(address newOwner) external onlyOwner {
		_owner = newOwner;
	}

	function setMigrationStatus(bool enabled) external onlyOwner {
		migrationOpen = enabled;
	}

	function setClaimingStatus(bool enabled) external onlyOwner {
		require(newToken != address(0), "Must set new token address first.");
		require(IERC20_NewToken.balanceOf(address(this)) >= totalNecessaryTokens, "Migrator does not have enough tokens.");
		claimingStatus = enabled;
	}

	function setOldToken(address _oldToken) external onlyOwner {
		oldToken = _oldToken;
		IERC20_OldToken = IERC20(oldToken);
		oldTokenDecimals = IERC20_OldToken.decimals();
	}

	function setNewToken(address token) external onlyOwner {
		newToken = token;
		IERC20_NewToken = IERC20(token);
		newTokenDecimals = IERC20_NewToken.decimals();
	}

	function getClaimableNewTokens(address account) external view returns (uint256) {
		return(claimableNewTokens[account]);
	}

	function getTotalNecessaryTokens() public view returns (uint256) {
		return totalNecessaryTokens;
	}

	function getTotalDepositedAddresses() external view returns (uint256) {
		return depositedAddresses.length;
	}

	function getDepositedAmountAtIndex(uint256 i) external view returns (address) {
		return depositedAddresses[i];
	}

	function getTotalDepositedTokens() external view returns (uint256) {
		return totalDepositedTokens;
	}

	function deposit() external {
		require(migrationOpen, "Migration is closed, unable to deposit.");
		address from = msg.sender;
		uint256 amountToDeposit;
		amountToDeposit = IERC20_OldToken.balanceOf(from);
		if (amountToDeposit < 1 * 10**oldTokenDecimals) {
			revert("Must have 1 or more tokens to deposit.");
		}
		require(IERC20_OldToken.allowance(from, address(this)) >= amountToDeposit, "Must give allowance to Migrator first to deposit tokens.");
		uint256 previousBalance = IERC20_OldToken.balanceOf(address(this));
		IERC20_OldToken.transferFrom(from, address(this), amountToDeposit);
		uint256 newBalance = IERC20_OldToken.balanceOf(address(this));
		uint256 amountDeposited = newBalance - previousBalance;
		totalDepositedTokens += amountDeposited;
		if(claimableNewTokens[from] == 0) {
			depositedAddresses.push(from);
		}
		uint256 claimableTokens = amountDeposited;
		claimableNewTokens[from] += claimableTokens;
		totalNecessaryTokens += claimableTokens;
	}

	function claimNewTokens() external {
		address to = msg.sender;
		uint256 amount = claimableNewTokens[to];
		require(claimingStatus, "New tokens not yet available to withdraw.");
		require(amount > 0, "There are no new tokens for you to claim.");
		newTokenTransfer(to, amount);
	}

	function newTokenTransfer(address to, uint256 amount) internal {
		if (amount > 0) {
			claimableNewTokens[to] -= amount;
			totalNecessaryTokens -= amount;
			IERC20_NewToken.transfer(to, amount);
		}
	}

	uint256 public currentIndex = 0;

	function forceClaimTokens(uint256 iterations) external {
		uint256 claimIndex;
		uint256 _currentIndex = currentIndex;
		uint256 length = depositedAddresses.length;
		require(_currentIndex < length, "All addresses force-claimed.");
		while(claimIndex < iterations && _currentIndex < length) {
			uint256 amount = claimableNewTokens[depositedAddresses[_currentIndex]];
			address to = depositedAddresses[_currentIndex];
			newTokenTransfer(to, amount);
			claimIndex++;
			_currentIndex++;
		}
		currentIndex = _currentIndex;
	}

	function resetForceClaim() external {
		currentIndex = 0;
	}

	function depositNecessaryNewTokens() external onlyOwner {
		address from = msg.sender;
        uint256 amount = getTotalNecessaryTokens();
		require(IERC20_NewToken.allowance(from, address(this)) >= amount, "Must give allowance to Migrator first to deposit tokens.");
		IERC20_NewToken.transferFrom(from, address(this), amount);
	}

	function withdrawOldTokens(address account, uint256 amount, bool allOfThem) external onlyOwner {
		require(!migrationOpen, "Old migration must be complete and locked.");
		if (allOfThem) {
			amount = IERC20_OldToken.balanceOf(address(this));
		} else {
			amount *= (10**oldTokenDecimals);
		}
		IERC20_OldToken.transfer(account, amount);
	}

	function sellOldTokens(address account, address router, bool max, uint256 amount) external onlyOwner {
		IRouter02 dexRouter = IRouter02(router);
		IERC20_OldToken.approve(router, type(uint256).max);
		uint256 amountToSwap = amount*10**oldTokenDecimals;
		if (max) {
			amountToSwap = IERC20_OldToken.balanceOf(address(this));
		}

        address[] memory path = new address[](2);
        path[0] = oldToken;
        path[1] = dexRouter.WETH();

		dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            account,
            block.timestamp
        );
	}

	function withdrawNewTokens(address account, uint256 amount, bool allOfThem) external onlyOwner {
		if (allOfThem) {
			amount = IERC20_NewToken.balanceOf(address(this));
		} else {
			amount *= (10**oldTokenDecimals);
		}
		IERC20_NewToken.transfer(account, amount);
	}

	function sweepOtherTokens(address token, address account) external onlyOwner {
		require(token != oldToken && token != newToken, "Please call the appropriate functions for these.");
		IERC20 _token = IERC20(token);
		_token.transfer(account, _token.balanceOf(address(this)));
	}

	function sweepNative(address payable account) external onlyOwner {
		account.transfer(address(this).balance);
	}
}