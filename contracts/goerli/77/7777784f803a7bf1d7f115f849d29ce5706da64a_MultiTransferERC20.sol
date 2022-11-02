/**
 *Submitted for verification at Etherscan.io on 2022-11-02
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

/**
 * @dev This contract is part of GLM payment system. Visit https://golem.network for details.
 * Be careful when interacting with this contract, because it has no exit mechanism. Any assets sent directly to this contract will be lost.
 */
contract MultiTransferERC20 {
    IERC20 public GLM;

    /**
     * @dev Contract works only on currency specified during contract deployment
     */
    constructor(IERC20 _GLM) {
        GLM = _GLM;
    }

    /**
     * @dev `recipients` is the list of addresses that will receive `amounts` of GLMs from the caller's account
     *
     * Both `recipients` and `amounts` have to be the same length. 
     *
     * Use this function on Polygon chain to avoid excessive approval events. It saves gas on Polygon compared to batchTransferDirect.
     * 
     * Note that this function emits one extra transfer event, which needs to be taken into account when parsing events.
     * GLM flow: Sender -> Contract -> Recipients
     */
    function golemTransferIndirect(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "recipients.length == amounts.length");

        uint256 totalAmount = 0;
        for (uint i = 0; i < recipients.length; ++i) {
            totalAmount += amounts[i];
        }
        require(GLM.transferFrom(msg.sender, address(this), totalAmount), "transferFrom failed");
        
        for (uint i = 0; i < recipients.length; ++i) {
            require(GLM.transfer(recipients[i], amounts[i]), "transfer failed");
        }
    }
    
    /**
     * @dev `recipients` is the list of addresses that will receive `amounts` of GLMs from the caller's account
     *
     * Both `recipients` and `amounts` have to be the same length. 
     *
     * Sometimes this function is cheaper than batchTransferIndirect.
     * GLM flow: Sender -> Recipients
     */
    function golemTransferDirect(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "recipients.length == amounts.length");

        for (uint i = 0; i < recipients.length; ++i) {
            require(GLM.transferFrom(msg.sender, recipients[i], amounts[i]), "transferFrom failed");
        }
    }

    /**
     * @dev Packed version of batchTransferDirect to save some gas on arguments
     *
     * `payments` is an array which consists of packed data as follows:
     * target address (20 bytes), amount (12 bytes)
     */
    function golemTransferDirectPacked(bytes32[] calldata payments) external {
        for (uint i = 0; i < payments.length; ++i) {
            // A payment contains compressed data:
            // first 160 bits (20 bytes) is an address.
            // following 96 bits (12 bytes) is a value,
            bytes32 payment = payments[i];
            address addr = address(bytes20(payment));
            uint amount = uint(payment) % 2**96;
            require(GLM.transferFrom(msg.sender, addr, amount), "transferFrom failed");
        }
    }


    /**
     * @dev Packed version of batchTransferIndirect to save some gas on arguments. 
     * `totalTransferred` - sum of GLM transferred
     * `payments` is an array which consists of packed data as follows:
     * target address (20 bytes), amount (12 bytes)
     */
    function golemTransferIndirectPacked(bytes32[] calldata payments, uint256 totalTransferred) external {
        uint256 totalAmount = 0;
        require(GLM.transferFrom(msg.sender, address(this), totalTransferred), "transferFrom failed");
        for (uint i = 0; i < payments.length; ++i) {
            // A payment contains compressed data:
            // first 160 bits (20 bytes) is an address.
            // following 96 bits (12 bytes) is a value,
            bytes32 payment = payments[i];
            address addr = address(bytes20(payment));
            uint amount = uint(payment) % 2**96;
            totalAmount += amount;
            require(GLM.transfer(addr, amount), "transfer failed");
        }
        require(totalAmount == totalTransferred, "Amount sum not equal totalTransferred");
    }
    
}