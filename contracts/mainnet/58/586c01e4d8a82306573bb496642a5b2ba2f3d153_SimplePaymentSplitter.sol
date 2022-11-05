/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


contract SimplePaymentSplitter {
    address payable owner1 =
        payable(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);
    address payable owner2 =
        payable(0x69c9F10c96B25fbB6Ad036CF8e5b578000b5565f);
    address payable owner3 =
        payable(0xB9C9a5f66DF622Fa2242e33Bb23d8c7Da964b2Cb);
    address payable owner4 = payable(0x0a17A826E7488daf0bfAF4D43de9E1DEC6a014f9);


    function distribute() public {
        uint256 amount = address(this).balance / 4;

        owner1.transfer(amount);
        owner2.transfer(amount);
        owner3.transfer(amount);
        owner4.transfer(amount);
    }

    // Allows distribution of weth or any erc20 owned by this contract

    function distributeERC20(address erc20ContractAddress) public {

        IERC20 TokenContract = IERC20(erc20ContractAddress);
        uint256 amount = TokenContract.balanceOf(address(this)) / 4;

        TokenContract.transfer(owner1, amount);
        TokenContract.transfer(owner2, amount);
        TokenContract.transfer(owner3, amount);
        TokenContract.transfer(owner4, amount);
    }

    // Receive any ether sent to the contract.
    receive() external payable {}
}