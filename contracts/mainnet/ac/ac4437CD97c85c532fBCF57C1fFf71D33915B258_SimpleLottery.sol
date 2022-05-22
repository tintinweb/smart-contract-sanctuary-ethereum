/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

contract SimpleLottery {
    IERC20 public usdcContract;
    IERC20 public usdtContract;
    address owner;
    address paymentHolder;
    address feeHolder;
    uint taxPercent;

    constructor(
        address paymentHolder_,
        address feeHolder_,
        uint taxPercent_
    ) {
        usdcContract = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        usdtContract = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        owner = msg.sender;
        paymentHolder = paymentHolder_;
        feeHolder = feeHolder_;
        taxPercent = taxPercent_;
    }

    /// Restricts the access only to the user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, "Method available only to the user that deployed the contract");
        _;
    }

    event paymentAddressTransferred(
        address indexed previousPaymentHolderAddress, 
        address indexed newPaymentHolderAddress
    );

    event feeAddressTransferred(
        address indexed previousFeeHolderAddress, 
        address indexed newFeeHolderAddress
    );

    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    function purchaseTicket(uint _amount) public {
        // amount should be > 0
        require(_amount > 0, "amount should be > 0");
        // check allowance
        require(usdcContract.allowance(msg.sender, address(this)) >= _amount, "Error, too low allowance.");
        // transfer USDC.
        uint feeAmount = _amount * taxPercent / 100;
        uint paymentAmount = _amount - feeAmount;
        usdcContract.transferFrom(msg.sender, paymentHolder, paymentAmount);
        usdcContract.transferFrom(msg.sender, feeHolder, feeAmount);
    }

    function sendPayment(uint _amount) public {
        // amount should be > 0
        require(_amount > 0, "amount should be > 0");
        // check allowance
        require(usdtContract.allowance(msg.sender, address(this)) >= _amount, "Error, too low allowance.");
        // transfer USDT.
        usdtContract.transferFrom(msg.sender, feeHolder, _amount);
    }

    function setPaymentHolderAddress(address payable newPaymentHolderAddress) public restrictToOwner() {
        require(newPaymentHolderAddress != address(0));
        emit paymentAddressTransferred(paymentHolder, newPaymentHolderAddress);
        paymentHolder = newPaymentHolderAddress;
    }

    function setFeeHolderAddress(address payable newFeeHolderAddress) public restrictToOwner() {
        require(newFeeHolderAddress != address(0));
        emit feeAddressTransferred(feeHolder, newFeeHolderAddress);
        feeHolder = newFeeHolderAddress;
    }

    function transferOwnership(address payable newOwner) public restrictToOwner() {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}