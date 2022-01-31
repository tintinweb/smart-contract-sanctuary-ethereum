//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "IERC20.sol";

interface ERC20 {
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool); 
}

contract Pool {


	address nitroOperatorAddress = 0x733990D97D7c5237FFE92A98d729b6dfba72D656; // TODO Change this to a permenant address // The address to recieve nitro funds too
	bool public isPaused = false; // -> require(!paused, "the contract is paused");
	uint nitroServiceFee = 10; // How much we charge LPs one profits as percentag

	struct pool {
		bool doesExist; // Check pool exists
		uint[] updatedTime; // A record of the pool transactions over time, this is updated when everything else is
		uint[] poolDepositedLiquidity; // The total liquidity deposited in the pool, before profit or loss
		uint[] poolTotalLiquidity; // The total liquidity in the pool, after profit or loss
		mapping(address => uint) userDepositedLiquidity; // The amount deposited by LP in the pool, before profit or loss
	}

	mapping(address => pool) internal pools; // Token address

	function addLiquidity(address _owner, address _token, uint _amount) public payable {

		ERC20(_token).transferFrom(_owner, address(this), _amount); // transfer the tokens from the sender to this contract

		require(!isPaused, "The contract is paused"); // Require the contract is not paused

		pools[_token].doesExist = true; // Confirm pool exists
		pools[_token].updatedTime.push(block.timestamp); // Push timestamp of update
		pools[_token].poolDepositedLiquidity.push(pools[_token].poolDepositedLiquidity[pools[_token].poolDepositedLiquidity.length] + msg.value); // Update deposited pool
		pools[_token].poolTotalLiquidity.push(pools[_token].poolTotalLiquidity[pools[_token].poolTotalLiquidity.length] + msg.value); // Update total pool
		pools[_token].userDepositedLiquidity[msg.sender] += msg.value; // Updated user deposited

	}

	/*
	function withdrawLiquidity(address _token) public payable {

		uint userTotalLiquidity = calculateLpInterest(_token, msg.sender); // Calculate how much money the liquidity provider is owed
		uint userDepositedLiquidity = pools[_token].userDepositedLiquidity[msg.sender];
		pools[_token].updatedTime.push(block.timestamp); // Push timestamp of update
		pools[_token].poolDepositedLiquidity.push(pools[_token].poolDepositedLiquidity[pools[_token].poolDepositedLiquidity.length] - pools[_token].userDepositedLiquidity[msg.sender]); // Update deposited pool
		pools[_token].poolTotalLiquidity.push(pools[_token].poolTotalLiquidity[pools[_token].poolTotalLiquidity.length] - userTotalLiquidity); // Update total pool
		pools[_token].userDepositedLiquidity[msg.sender] = 0; // Reset user deposit

		if (userTotalLiquidity > userDepositedLiquidity) {

			// Subtract value of nitroServiceFee as percentage
			// IERC20(_token).transfer(msg.sender, userTotalLiquidity);

		}

		IERC20(_token).transfer(msg.sender, userTotalLiquidity);

	}
	*/

	function simulateLoosingTrade(address _owner, address _token, uint _amount) public {

		ERC20(_token).transferFrom(_owner, address(this), _amount); // transfer the tokens from the sender to this contract

		// require(pools[_token].doesExist, "No liquidity pool");

	}

	function calculateLpInterest(address _token, address _userAddress) public view returns (uint userTotalLiquidity) {

		uint poolDepositedLiquidity = pools[_token].poolDepositedLiquidity[pools[_token].poolDepositedLiquidity.length]; // The amount of money deposited in the pool
		uint userDepositedLiquidity = pools[_token].userDepositedLiquidity[_userAddress]; // The amount the LP has deposited
		uint userPoolShare = (userDepositedLiquidity / poolDepositedLiquidity) * 100;
		uint poolTotalLiquidity = pools[_token].poolTotalLiquidity[pools[_token].poolTotalLiquidity.length]; // The actual balance of the liquidity pool
		return (poolTotalLiquidity / 100) * userPoolShare; // Return their share of the pool

	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}