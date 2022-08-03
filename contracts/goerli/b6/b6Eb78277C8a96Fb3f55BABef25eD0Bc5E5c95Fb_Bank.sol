// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// @title Bank contract
pragma solidity ^0.8.0;

import {IBank} from "./IBank.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bank is IBank {
    IERC20 private immutable token;

    // `balances` maps account/contract addresses to balances
    mapping(address => uint256) private balances;

    constructor(address _token) {
        require(_token != address(0), "Bank: invalid token");
        token = IERC20(_token);
    }

    function getToken() public view override returns (IERC20) {
        return token;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function transferTokens(address _to, uint256 _value) public override {
        // checks
        uint256 balance = balances[msg.sender];
        require(_value <= balance, "Bank: not enough balance");

        // effects
        // Note: this should not underflow because we checked that
        // `_value <= balance` in the `require` above
        unchecked {
            balances[msg.sender] = balance - _value;
        }

        // interactions
        // Note: a well-implemented ERC-20 contract should already
        // require the recipient (in this case, `_to`) to be different
        // than address(0), so we don't need to check it ourselves
        require(token.transfer(_to, _value), "Bank: transfer failed");
        emit Transfer(msg.sender, _to, _value);
    }

    function depositTokens(address _to, uint256 _value) public override {
        // checks
        require(_to != address(0), "Bank: invalid recipient");

        // effects
        // Note: this should not overflow because `IERC20.totalSupply`
        // returns a `uint256` value, so there can't be more than
        // `uint256.max` tokens in an ERC-20 contract.
        balances[_to] += _value;

        // interactions
        // Note: transfers tokens to bank, but emits `Deposit` event
        // with recipient being `_to`
        require(
            token.transferFrom(msg.sender, address(this), _value),
            "Bank: transferFrom failed"
        );
        emit Deposit(msg.sender, _to, _value);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// @title Bank interface
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank {
    /// @notice returns the token used internally
    function getToken() external view returns (IERC20);

    /// @notice get balance of `_owner`
    /// @param _owner account owner
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice transfer `_value` tokens from bank to `_to`
    /// @notice decrease the balance of caller by `_value`
    /// @param _to account that will receive `_value` tokens
    /// @param _value amount of tokens to be transfered
    function transferTokens(address _to, uint256 _value) external;

    /// @notice transfer `_value` tokens from caller to bank
    /// @notice increase the balance of `_to` by `_value`
    /// @dev you may need to call `token.approve(bank, _value)`
    /// @param _to account that will have their balance increased by `_value`
    /// @param _value amount of tokens to be transfered
    function depositTokens(address _to, uint256 _value) external;

    /// @notice `value` tokens were transfered from the bank to `to`
    /// @notice the balance of `from` was decreased by `value`
    /// @dev is triggered on any successful call to `transferTokens`
    /// @param from the account/contract that called `transferTokens` and
    ///              got their balance decreased by `value`
    /// @param to the one that received `value` tokens from the bank
    /// @param value amount of tokens that were transfered
    event Transfer(address indexed from, address to, uint256 value);

    /// @notice `value` tokens were transfered from `from` to bank
    /// @notice the balance of `to` was increased by `value`
    /// @dev is triggered on any successful call to `depositTokens`
    /// @param from the account/contract that called `depositTokens` and
    ///              transfered `value` tokens to the bank
    /// @param to the one that got their balance increased by `value`
    /// @param value amount of tokens that were transfered
    event Deposit(address from, address indexed to, uint256 value);
}