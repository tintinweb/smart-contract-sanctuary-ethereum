/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: NONE

pragma solidity >=0.6.0 <0.8.0;
pragma solidity 0.7.0;


// 
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: contracts/CricStoxTreasury.sol
contract CricStoxTreasury {

    address public cricStoxMasterAddress;

    modifier onlyMaster() {
        require(cricStoxMasterAddress == msg.sender, "Callable only by Master");
        _;
    }

    /**
        * @dev Initializes cricStoxMasterAddress.
        * @param cricStoxMasterAddress_ The address of CricStox Master contract.
        */
    function initMaster(address cricStoxMasterAddress_) external {
        require(cricStoxMasterAddress == address(0), "Master already initialized");
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
    }

    /**
        * @dev For users to withdraw their tokens from treasury.
        * @param token_ The address of token to withdraw.
        * @param user_ The address of user.
        * @param amount_ The amount of stox token.
        */
    function userWithdraw(address token_, address user_, uint256 amount_) external onlyMaster {
        IERC20 token = IERC20(token_);
        token.transfer(user_, amount_); //replace with safeERC20
    }

    /**
        * @dev For users to deposit their tokens from treasury.
        * @param token_ The address of token to withdraw.
        * @param user_ The address of user.
        * @param amount_ The amount of stox token.
        */
    function userDeposit(address token_, address user_, uint256 amount_) external onlyMaster {
        IERC20 token = IERC20(token_);
        require(token.allowance(user_, address(this)) >= amount_, "Not enough allowance");
        token.transferFrom(user_, address(this), amount_); //replace with safeERC20
    }
}