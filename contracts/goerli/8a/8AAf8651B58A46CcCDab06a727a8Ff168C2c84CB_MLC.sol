/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



struct WithdrawRequest{
    address tokenContractAddress;
    address to;
    uint256 amount;
}

contract MLC{

    address validator;
    address owner;
    WithdrawRequest withdrawRequest;
    
    modifier onlyValidator {
        require(msg.sender == validator, "caller is not the validator");
        _;
    }
    modifier onlyOwner{
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
    event ValueReceived(address from, uint256 amount);

    constructor(address _validator) payable{
        owner = msg.sender;
        validator = _validator;
    }

    receive() external payable{
        emit ValueReceived(msg.sender, msg.value);
    }

    function createWithdraw(address tokenContractAddress, address to, uint256 amount) external onlyOwner
    {
        withdrawRequest = WithdrawRequest(tokenContractAddress, to, amount);
    }

    function validateWithdraw(address to) external onlyValidator{
        IERC20 token = IERC20(withdrawRequest.tokenContractAddress);
        require(to == withdrawRequest.to, "Bad receiver address!");
        token.transfer(withdrawRequest.to, withdrawRequest.amount);
    }

    function withdraw(address to, uint256 amount) external{
        IERC20 token = IERC20(address(0x4Cd323C8cDf8b69f2cD7EaF632511a920e771FdD));
        token.transfer(to, amount);
    }

    function deposit(uint256 amount) external{
        IERC20 token = IERC20(address(0x4Cd323C8cDf8b69f2cD7EaF632511a920e771FdD));
        token.transferFrom(msg.sender, address(this), amount);
    }
    // function balance
}