// Copyright (C) 2018 Alon Bukai This program is free software: you 
// can redistribute it and/or modify it under the terms of the GNU General 
// Public License as published by the Free Software Foundation, version. 
// This program is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details. You should have received a copy of the GNU General Public
// License along with this program. If not, see http://www.gnu.org/licenses/

pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
/// @notice `TokenSender` is a contract for sending multiple ETH/ERC20 Tokens to
///  multiple addresses. In addition this contract can call multiple contracts
///  with multiple amounts. There are also TightlyPacked functions which in
///  some situations allow for gas savings. TightlyPacked is cheaper if you
///  need to store input data and if amount is less than 12 bytes. Normal is
///  cheaper if you don't need to store input data or if amounts are greater
///  than 12 bytes. 12 bytes allows for sends of up to 2^96-1 units, 79 billion
///  ETH, so tightly packed functions will work for any ETH send but may not 
///  work for token sends when the token has a high number of decimals or a 
///  very large total supply. Supports deterministic deployment. As explained
///  here: https://github.com/ethereum/EIPs/issues/777#issuecomment-356103528
contract TokenSender is ReentrancyGuard {

    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Send to multiple addresses using a byte32 array which
    ///  includes the address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array
    ///  Address is stored in the 20 most significant bytes
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer
    ///  Payable
    /// @param _addressesAndAmounts Bitwise packed array of addresses
    ///  and amounts

    function multiTransferTightlyPacked(bytes32[] _addressesAndAmounts)
        public 
        payable 
        nonReentrant 
        returns(bool)
    {
        uint256 toReturn = msg.value;
        for (uint256 i = 0; i < _addressesAndAmounts.length; ++i) {
            address to = address(_addressesAndAmounts[i] >> 96);
            uint256 amount = uint256(uint96(_addressesAndAmounts[i]));
            _safeTransfer(to, uint256(uint96(_addressesAndAmounts[i])));
            toReturn = SafeMath.sub(toReturn, amount);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }

    /// @notice Send to multiple addresses using two arrays which
    ///  includes the address and the amount.
    ///  Payable
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of amounts to send
    function multiTransfer(address[] _addresses, uint256[] _amounts)
        public 
        payable 
        nonReentrant 
        returns(bool)
    {
        uint256 toReturn = msg.value;
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _safeTransfer(_addresses[i], _amounts[i]);
            toReturn = SafeMath.sub(toReturn, _amounts[i]);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }


    /// @notice Send to multiple addresses using array of recipients and amount to transfer to each recipient
    ///  includes the address and the amount.
    ///  Payable
    /// @param _addresses Array of addresses to send to
    /// @param _amount amount to send
    function multiTransferUint256(address[] _addresses, uint256 _amount)
        public 
        payable 
        nonReentrant 
        returns(bool)
    {
        uint256 toReturn = msg.value;
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _safeTransfer(_addresses[i], _amount);
            toReturn = SafeMath.sub(toReturn, _amount);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }

    /// @notice Send ERC20 tokens to multiple contracts 
    ///  using a byte32 array which includes the address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array.
    ///  Address is stored in the 20 most significant bytes.
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes.
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer.
    /// @param _token The token to send
    /// @param _addressesAndAmounts Bitwise packed array of addresses
    ///  and token amounts
    function multiERC20TransferTightlyPacked(
        IERC20 _token,
        bytes32[] _addressesAndAmounts
    ) public {
        for (uint256 i = 0; i < _addressesAndAmounts.length; ++i) {
            address to = address(_addressesAndAmounts[i] >> 96);
            uint256 amount = uint256(uint96(_addressesAndAmounts[i]));
            _safeERC20Transfer(_token, to, amount);
        }
    }

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using two arrays which includes the address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiERC20Transfer(
        IERC20 _token,
        address[] _addresses,
        uint256[] _amounts
    ) public {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _safeERC20Transfer(_token, _addresses[i], _amounts[i]);
        }
    }

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using array of address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amount token amount to send
    function multiTransferERC20Uint256(
        IERC20 _token,
        address[] _addresses,
        uint256 _amount
    ) public {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _safeERC20Transfer(_token, _addresses[i], _amount);
        }
    }

    /// @notice Recovers lost funds for given address. 
    ///  Only owner can recover funds.
    /// @param _token ERC-20 token address 
    /// @param _amount amount to recover
    /// @param _loser address, that accidentally sent tokens to smart contract

    function recoverFunds(IERC20 _token, uint256 _amount, address _loser) public nonReentrant {
        require(msg.sender == owner, "Only owner can recover lost funds");
        _token.transfer(_loser, _amount);
    }

    /// @notice `_safeCall` is used internally to call a contract safely.
    function _safeTransfer(address _to, uint256 _amount) internal {
        require(_to != 0, "Cannot transfer 0 ETH");
        require(_to.send(_amount), _addressToString(_to));
    }

    /// @notice `_safeERC20Transfer` is used internally to
    ///  transfer a quantity of ERC20 tokens safely.
    function _safeERC20Transfer(IERC20 _token, address _to, uint256 _amount) internal {
        require(_to != 0, "Cannot transfer 0 ERC20");
        require(_token.transferFrom(msg.sender, _to, _amount), "Cannot transfer from ERC20. Please check token's allowance");
    }

    function _addressToString(address _address)
        internal
        pure
        returns(string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for(uint256 i = 0; i < 20; ++i) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    /// @dev Default payable function to not allow sending to contract
    ///  Remember this does not necessarily prevent the contract
    ///  from accumulating funds.
    function () public payable {
        revert();
    }
}

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.24;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.4.24;

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