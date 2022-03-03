// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

// TransferKEYS Contract
// Developed by Daniel Kantor

// This contract will allow you to transfer KEYS to any address with NO 3% transfer tax.

// In order to use this contract, make sure you approve the amount of KEYS you would like to transfer
// with the approve() function on the KEYS contract located here: 
// https://etherscan.io/token/0xe0a189C975e4928222978A74517442239a0b86ff#writeContract
// After you approve the amount of KEYS you'd like to send, 
// you can call transferKEYS or transferKEYSWholeTokenAmounts

contract TransferKEYS {
    // KEYS Contract Address
    address constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    function transferKEYS(address toAddress, uint256 amount) public {
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount);
        require(s, "Failure to transfer from sender to contract");

        // Transfer KEYS Tokens To User
        bool s1 = IERC20(KEYS).transfer(toAddress, amount);
        require(s1, "Failure to transfer from contract to receiver");
    }

    function transferKEYSWholeTokenAmounts(address toAddress, uint256 amount) public {
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount * 10**9);
        require(s, "Failure to transfer from sender to contract");

        // Transfer KEYS Tokens To User
        bool s1 = IERC20(KEYS).transfer(toAddress, amount * 10**9);
        require(s1, "Failure to transfer from contract to receiver");
    }
}

//SPDX-License-Identifier: MIT
    pragma solidity 0.8.4;

    interface IERC20 {
        function totalSupply() external view returns (uint256);

        function symbol() external view returns (string memory);

        function name() external view returns (string memory);

        /**
        * @dev Returns the amount of tokens owned by `account`.
        */
        function balanceOf(address account) external view returns (uint256);

        /**
        * @dev Returns the number of decimal places
        */
        function decimals() external view returns (uint8);

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
        function transferFrom(
            address sender,
            address recipient,
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
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }