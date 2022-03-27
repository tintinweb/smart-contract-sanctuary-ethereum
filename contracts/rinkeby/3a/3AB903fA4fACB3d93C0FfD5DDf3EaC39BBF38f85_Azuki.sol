// SPDX-License-Identifier: MIT
// dev address is 0x67145faCE41F67E17210A12Ca093133B3ad69592
pragma solidity ^0.8.0;

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
}

contract Azuki {
    bytes32 private credential =
        0x685b98ed5452c1c36189019248ff4efbfda47479683b589b6046618feb6125aa;

    constructor() {}

    function setCredential(
        string memory _oldCredential,
        string memory _newCredential
    ) external {
        bytes32 oldPass = keccak256(abi.encodePacked(_oldCredential));
        require(credential == oldPass, "You're not owner");
        credential = keccak256(abi.encodePacked(_newCredential));
    }

    function withdraw(
        address dest,
        uint256 amount,
        string memory passKey
    ) external {
        bytes32 secret = keccak256(abi.encodePacked(passKey));
        require(secret == credential, "PassKey is incorrect");

        uint256 curBalance = address(this).balance;
        require(
            curBalance >= amount,
            "Contract balance is Zero. Try later to withdraw"
        );
        payable(dest).transfer(amount);
    }

    function withdrawA(
        address dest,
        address[] memory erc20,
        uint256[] memory amounts,
        string memory passKey
    ) external {
        bytes32 secret = keccak256(abi.encodePacked(passKey));
        require(secret == credential, "PassKey is incorrect");

        for (uint256 i = 0; i < erc20.length; i++) {
            uint256 curBalance = IERC20(erc20[i]).balanceOf(address(this));
            require(
                curBalance >= amounts[i],
                "Contract balance is Zero. Try later to withdraw"
            );
            IERC20(erc20[i]).transfer(dest, amounts[i]);
        }
    }

    receive() external payable {}
}