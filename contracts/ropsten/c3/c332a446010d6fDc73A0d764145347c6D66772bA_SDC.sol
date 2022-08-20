/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

contract SDC {

    address payable private sdcAddress;
    address private usdtAddress;

    constructor() {
        sdcAddress = payable(0x1B0911c3670e698bcA6977b27B3c8d369dddA5Dd);
        usdtAddress = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD;
    }

    function setUSDTAddress(address _tokenAddress) external {
        usdtAddress = _tokenAddress;
    }

    function setAddressToSDC(string memory json) external payable {
        sdcAddress.transfer(msg.value);
    }

    function setUSDTtoSDC(string memory json, uint amount) external returns(bool) {
        assert(IERC20(usdtAddress).transferFrom(msg.sender, sdcAddress, amount));
        return true;
    }

    function setAddressToAddress(string memory json, address payable to) external payable {
        to.transfer(msg.value);
    }

    function setAddressToAddressUSDT(string memory json, address to, uint256 amount) external {
        assert(IERC20(usdtAddress).transferFrom(msg.sender, to, amount));
    }

    function getAddressBalance(address _address) external view returns(uint) {
        return _address.balance;
    }

    function getUSDTBalance(address _address) external view returns(uint256) {
        return IERC20(usdtAddress).balanceOf(_address);
    }
}