/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IProcessor.sol";
import "../interfaces/IRule.sol";
import "../interfaces/IRuleEngine.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/ISeizable.sol";
import "../interfaces/ISuppliable.sol";
import "../interfaces/IRulable.sol";
import "../token/abstract/BridgeERC20.sol";

import "../access/Operator.sol";

/**
 * @title Processor
 * @dev The Processor orchestrate most of the operations on each token
 *
 * Error messages
 * TR01: Token already registered
 * TR02: Empty name
 * TR03: Empty symbol
 * ER01: Cannot send tokens to 0x0
 * ER02: Owner cannot be 0x0
 * ER03: Spender cannot be 0x0
 * RU03: Rule Engine rejected the transfer
 * SE01: Cannot seize from 0x0
 * SE02: Caller does not have the seizer role
 * MT01: Cannot mint to 0x0
 * MT03: Cannot redeem from 0x0
 * SU01: Caller does not have the supplier role
**/


contract Processor is Initializable, IProcessor, Operator {
  using SafeMath for uint256;

  uint256 public constant VERSION = 1;

  uint256 internal constant TRANSFER_INVALID = 0;
  uint256 internal constant TRANSFER_VALID_WITH_NO_HOOK = 1;
  uint256 internal constant TRANSFER_VALID_WITH_BEFORE_HOOK = 2;
  uint256 internal constant TRANSFER_VALID_WITH_AFTER_HOOK = 3;

  struct TokenData {
    string name;
    string symbol;
    uint8 decimals;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 totalSupply;
  }

  mapping(address => TokenData) _tokens;

  IRuleEngine public ruleEngine;

  /**
  * @dev Initializer (replaces constructor when contract is upgradable)
  * @param owner the final owner of the contract
  * @param _ruleEngine the rule engine library used by this processor
  */
  function initialize(address owner, IRuleEngine _ruleEngine) public initializer {
    Operator.initialize(owner);
    ruleEngine = _ruleEngine;
  }

  /**
  * @dev Set the rule engine library used by this processor
  * @param _ruleEngine the rule engine library used by this processor
  */
  function setRuleEngine(
    IRuleEngine _ruleEngine
  ) 
    public onlyOperator
  {
    ruleEngine = _ruleEngine;
  }

  /**
  * @dev Registers a token with this processor
  * @dev Intended to be called by the token contract itself when initialized
  * @dev name, symbol and decimals are immutable
  * @dev Throws TR01 if the token is already registered with this processor
  * @dev Throws TR02 if the token name is empty
  * @dev Throws TR03 if the token symbol is empty
  * @param _name The token's name
  * @param _symbol The token's symbol
  * @param _decimals The token's number of decimals
  */
  function register(string calldata _name, string calldata _symbol, uint8 _decimals) external override {
    require(keccak256(abi.encodePacked(_name)) != keccak256(""), "TR02");
    require(keccak256(abi.encodePacked(_symbol)) != keccak256(""), "TR03");
    require(keccak256(abi.encodePacked(_tokens[_msgSender()].name)) == keccak256(""), "TR01");
    _tokens[_msgSender()].name = _name;
    _tokens[_msgSender()].symbol = _symbol;
    _tokens[_msgSender()].decimals = _decimals;
  }

  /* ERC20 */
  /**
  * @dev Returns the name of the token
  * @dev Intended to be called by the token contract
  * @return name The name of the token
  */
  function name() public override view returns (string memory) {
    return _tokens[_msgSender()].name;
  }

  /**
  * @dev Returns the symbol of the token
  * @dev Intended to be called by the token contract
  * @return symbol The symbol of the token
  */
  function symbol() public override view returns (string memory) {
    return _tokens[_msgSender()].symbol;
  }

  /**
  * @dev Returns the decimals of the token
  * @dev Intended to be called by the token contract
  * @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
  * be displayed to a user as `5,05` (`505 / 10 ** 2`).
  * @return decimals The decimals of the token
  */
  function decimals() public override view returns (uint8) {
    return _tokens[_msgSender()].decimals;
  }

  /**
  * @dev Returns the total supply of the token
  * @dev Intended to be called by the token contract
  * @return totalSupply The total supply of the token
  */
  function totalSupply() public override view returns (uint256) {
    return _tokens[_msgSender()].totalSupply;
  }

  /**
  * @dev Returns the token balance for the address given in parameter
  * @dev Intended to be called by the token contract
  * @param _owner The address for which the balance has to be retrieved
  * @return balance The token balance for the address given in parameter
  */
  function balanceOf(address _owner) public override view returns (uint256) {
    return _tokens[_msgSender()].balances[_owner];
  }

  /**
  * @dev Determines whether a specific amount of tokens can be transfered from an address to another
  * @dev Intended to be called by the token contract
  * @param _from The sender of the tokens
  * @param _to The receiver of the tokens
  * @param _amount The amount of tokens to transfer
  * @return isValid True if the transfer is valid, false otherwise
  * @return ruleId The ruleId that first rejected the transfer
  * @return reason The reason code for the transfer rejection
  */
  function canTransfer(address _from, address _to, uint256 _amount) public override view returns (bool, uint256, uint256) {
    uint256[] memory rulesParams;
    uint256[] memory ruleIds;
    (ruleIds, rulesParams) = IRulable(_msgSender()).rules();
    return ruleEngine.validateTransferWithRules(
      ruleIds, 
      rulesParams, 
      _msgSender(),
      _from, 
      _to, 
      _amount
    );
  }

  /**
  * @dev Transfer a specific amount of tokens from an address to another
  * @dev Intended to be called by the token contract
  * @dev The receiver address and the amount can be updated by the token enforced rules
  * @dev Throws ER01 if receiver address is 0x0
  * @dev Throws RU03 if one of the rule rejects the transfer
  * @param _from The sender of the tokens
  * @param _to The intended receiver of the tokens
  * @param _value The intended amount of tokens to send
  * @return isSuccessful True if the transfer is successful, false otherwise
  * @return updatedTo The real address the tokens were sent to
  * @return updatedValue The real amount of tokens sent
  */
  function transferFrom(address _from, address _to, uint256 _value) 
    public override returns (bool, address updatedTo, uint256 updatedValue) 
  {
    require(_to != address(0), "ER01");
    uint256[] memory rulesParams;
    uint256[] memory ruleIds;
    uint256 i;
    (ruleIds, rulesParams) = IRulable(_msgSender()).rules();
    IRule[] memory rules = ruleEngine.rules(ruleIds);
    uint256[] memory ruleValid = new uint256[](ruleIds.length);
    /* Transfer check */
    for (i = 0; i < rules.length; i++) {
      (ruleValid[i], ) = rules[i].isTransferValid(
        _msgSender(), _from, _to, _value, rulesParams[i]);
      require(ruleValid[i] > TRANSFER_INVALID, "RU03");
    }
    /* Before transfer hook execution if needed */
    for (i = 0; i < rules.length; i++) {
      if (ruleValid[i] == TRANSFER_VALID_WITH_BEFORE_HOOK) {
        (ruleValid[i], _to, _value) = rules[i].beforeTransferHook(
          _msgSender(), _from, _to, _value, rulesParams[i]);
        require(ruleValid[i] > TRANSFER_INVALID, "RU03");
      }
    }
    /* Update */
    _subBalance(_from, _value);
    _addBalance(_to, _value);
    /* After transfer hook execution if needed */
    for (i = 0; i < rules.length; i++) {
      if (ruleValid[i] == TRANSFER_VALID_WITH_AFTER_HOOK) {
        rules[i].afterTransferHook(
          _msgSender(), _from, _to, _value, rulesParams[i]);
      }
    }
    return (true, _to, _value);
  }

  /**
  * @dev Approves a specific amount of tokens to be spent by a spender from an address
  * @dev Intended to be called by the token contract
  * @dev Throws ER02 if owner address is 0x0
  * @dev Throws ER03 if spender address is 0x0
  * @param _owner The owner of the tokens to be allowed for spending
  * @param _spender The spender address to allow
  * @param _value The maximum amount of tokens that can be allowed for spending
  */
  function approve(address _owner, address _spender, uint256 _value) public override {
    require(_owner != address(0), "ER02");
    require(_spender != address(0), "ER03");

    _setAllowance(_owner, _spender, _value);
  }

  /**
  * @dev Returns the amount of tokens that are allowed to be spent by a spender from an address
  * @dev Intended to be called by the token contract
  * @param _owner The owner of the tokens to be spent
  * @param _spender The spender for which we want the allowed amount
  * @return The amount of tokens that can be spent by the spender from the owning address
  */
  function allowance(address _owner, address _spender) public override view returns (uint256) {
    return _tokens[_msgSender()].allowed[_owner][_spender];
  }

  /**
  * @dev Increases the spending approval of tokens to be spent by a spender from an address by a specific amount
  * @dev Intended to be called by the token contract
  * @dev Throws ER02 if owner address is 0x0
  * @dev Throws ER03 if spender address is 0x0
  * @param _owner The owner of the tokens to be allowed for spending
  * @param _spender The spender address to allow
  * @param _addedValue The number of tokens for the approval increase
  */
  function increaseApproval(address _owner, address _spender, uint _addedValue) public override {
    require(_owner != address(0), "ER02");
    require(_spender != address(0), "ER03");
    _setAllowance(_owner, _spender, _tokens[_msgSender()].allowed[_owner][_spender].add(_addedValue));
  }

  /**
  * @dev Decreases the spending approval of tokens to be spent by a spender from an address by a specific amount
  * @dev Intended to be called by the token contract
  * @dev Throws ER02 if owner address is 0x0
  * @dev Throws ER03 if spender address is 0x0
  * @param _owner The owner of the tokens to be allowed for spending
  * @param _spender The spender address to allow
  * @param _subtractedValue The number of tokens for the approval decrease
  */
  function decreaseApproval(address _owner, address _spender, uint _subtractedValue) public override {
    require(_owner != address(0), "ER02");
    require(_spender != address(0), "ER03");
    _setAllowance(_owner, _spender, _tokens[_msgSender()].allowed[_owner][_spender].sub(_subtractedValue));
  }

  /* Seizable */
  /**
  * @dev Seizes a specific amount of tokens from an address and transfers it to the caller address
  * @dev Intended to be called by the token contract
  * @dev Throws SE01 if the address for seize is 0x0
  * @dev Throws SE02 if the caller does not have the `Seizer` role
  * @param _caller The address that wants to seize the tokens
  * @param _account The address from which the tokens will be seized
  * @param _value The amount of tokens to seize
  */
  function seize(address _caller, address _account, uint256 _value) public override {
    require(_account != address(0), "SE01"); 
    require(ISeizable(_msgSender()).isSeizer(_caller), "SE02");
    _subBalance(_account, _value);
    _addBalance(_caller, _value);
  }

  /* Mintable */
  /**
  * @dev Mints a specific amount of tokens to an address
  * @dev Intended to be called by the token contract
  * @dev Throws SU01 if the caller does not have the `Supplier` role
  * @param _caller The address that wants to mint tokens
  * @param _to The address on which the tokens will be minted
  * @param _amount The amount of tokens to mint
  */
  function mint(address _caller, address _to, uint256 _amount) public override {
    require(_to != address(0), "MT01");
    require(ISuppliable(_msgSender()).isSupplier(_caller), "SU01");
    _tokens[_msgSender()].totalSupply = _tokens[_msgSender()].totalSupply.add(_amount);
    _addBalance(_to, _amount);
  }

  /**
  * @dev Burns a specific amount of tokens to an address
  * @dev Intended to be called by the token contract
  * @dev Throws SU01 if the caller does not have the `Supplier` role
  * @param _caller The address that wants to burn tokens
  * @param _from The address from which the tokens will be burnt
  * @param _amount The amount of tokens to burn
  */
  function burn(address _caller, address _from, uint256 _amount) public override {
    require(_from != address(0), "MT03");
    require(ISuppliable(_msgSender()).isSupplier(_caller), "SU01");
    _tokens[_msgSender()].totalSupply = _tokens[_msgSender()].totalSupply.sub(_amount);
    _subBalance(_from, _amount);
  }

  /* Internals */
  /**
  * @dev Adds a specific amount of tokens to an address balance
  * @dev Intended to be called by the token contract
  * @param _owner The address on which the amount will be added
  * @param _value The amount fo tokens to add
  */
  function _addBalance(address _owner, uint256 _value) internal {
    _tokens[_msgSender()].balances[_owner] = _tokens[_msgSender()].balances[_owner].add(_value);
  }

  /**
  * @dev Removes a specific amount of tokens to an address balance
  * @dev Intended to be called by the token contract
  * @param _owner The address from which the amount will be removed
  * @param _value The amount fo tokens to remove
  */
  function _subBalance(address _owner, uint256 _value) internal {
    _tokens[_msgSender()].balances[_owner] = _tokens[_msgSender()].balances[_owner].sub(_value);
  }

  /**
  * @dev Sets the number of tokens that are allowed to be spent by the spender from the owner address
  * @dev Intended to be called by the token contract
  * @param _owner The owner of the tokens to be allowed for spending
  * @param _spender The spender address to allow
  * @param _value The maximum amount of tokens that can be allowed for spending
  */
  function _setAllowance(address _owner, address _spender, uint256 _value) internal {
    _tokens[_msgSender()].allowed[_owner][_spender] = _value;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * block.timestamp has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

import "./IRuleEngine.sol";

/**
 * @title IProcessor
 * @dev IProcessor interface
 **/

 
interface IProcessor {
  
  /* Register */
  function register(string calldata _name, string calldata _symbol, uint8 _decimals) external;
  /* Rulable */
  function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool, uint256, uint256);
  /* ERC20 */
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) 
    external returns (bool, address, uint256);
  function approve(address _owner, address _spender, uint256 _value) external;
  function allowance(address _owner, address _spender) external view returns (uint256);
  function increaseApproval(address _owner, address _spender, uint _addedValue) external;
  function decreaseApproval(address _owner, address _spender, uint _subtractedValue) external;
  /* Seizable */
  function seize(address _caller, address _account, uint256 _value) external;
  /* Mintable */
  function mint(address _caller, address _to, uint256 _amount) external;
  function burn(address _caller, address _from, uint256 _amount) external;
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IRule
 * @dev IRule interface.
 **/

 
interface IRule {
  function isTransferValid(
    address _token, address _from, address _to, uint256 _amount, uint256 _ruleParam)
    external view returns (uint256 isValid, uint256 reason);
  function beforeTransferHook(
    address _token, address _from, address _to, uint256 _amount, uint256 _ruleParam)
    external returns (uint256 isValid, address updatedTo, uint256 updatedAmount);
  function afterTransferHook(
    address _token, address _from, address _to, uint256 _amount, uint256 _ruleParam)
    external returns (bool updateDone);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;


import "./IRule.sol";

/**
 * @title IRuleEngine
 * @dev IRuleEngine interface
 **/


interface IRuleEngine {

  function setRules(IRule[] calldata rules) external;
  function ruleLength() external view returns (uint256);
  function rule(uint256 ruleId) external view returns (IRule);
  function rules(uint256[] calldata _ruleIds) external view returns(IRule[] memory);

  function validateTransferWithRules(
    uint256[] calldata _tokenRules, 
    uint256[] calldata _tokenRulesParam, 
    address _token,
    address _from, 
    address _to, 
    uint256 _amount)
    external view returns (bool, uint256, uint256);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IOwnable
 * @dev IOwnable interface
 **/

 
interface IOwnable {
  function owner() external view returns (address);
  function transferOwnership(address _newOwner) external returns (bool);
  function renounceOwnership() external returns (bool);

  event OwnershipTransferred(address indexed newOwner);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title ISeizable
 * @dev ISeizable interface
 **/


interface ISeizable {
  function isSeizer(address _seizer) external view returns (bool);
  function addSeizer(address _seizer) external;
  function removeSeizer(address _seizer) external;

  event SeizerAdded(address indexed seizer);
  event SeizerRemoved(address indexed seizer);

  function seize(address _account, uint256 _value) external;
  event Seize(address account, uint256 amount);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title ISuppliable
 * @dev ISuppliable interface
 **/


interface ISuppliable {
  function isSupplier(address _supplier) external view returns (bool);
  function addSupplier(address _supplier) external;
  function removeSupplier(address _supplier) external;

  event SupplierAdded(address indexed supplier);
  event SupplierRemoved(address indexed supplier);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IRulable
 * @dev IRulable interface
 **/


interface IRulable {
  function rule(uint256 ruleId) external view returns (uint256, uint256);
  function rules() external view returns (uint256[] memory, uint256[] memory);

  function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool, uint256, uint256);

  function setRules(
    uint256[] calldata _rules, 
    uint256[] calldata _rulesParams
  ) external;
  event RulesChanged(uint256[] newRules, uint256[] newRulesParams);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../access/Roles.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IAdministrable.sol";
import "../../interfaces/IGovernable.sol";
import "../../interfaces/IPriceable.sol";
import "../../interfaces/IProcessor.sol";
import "../../interfaces/IPriceOracle.sol";

/**
 * @title BridgeERC20
 * @dev BridgeERC20 contract
 *
 * Error messages
 * PR01: Processor is not set
 * AD01: Caller is not administrator
 * AL01: Spender is not allowed for this amount
 * PO03: Price Oracle not set
 * KI01: Caller of setRealm has to be owner or administrator of initial token address for realm
**/


contract BridgeERC20 is Initializable, OwnableUpgradeable, IAdministrable, IGovernable, IPriceable, IERC20Detailed {
  using Roles for Roles.Role;
  using SafeMath for uint256;

  event ProcessorChanged(address indexed newProcessor);

  IProcessor internal _processor;
  Roles.Role internal _administrators;
  Roles.Role internal _realmAdministrators;
  address[] internal _trustedIntermediaries;
  address internal _realm;
  IPriceOracle internal _priceOracle;

  /** 
  * @dev Initialization function that replaces constructor in the case of upgradable contracts
  **/
  function initialize(address owner, IProcessor newProcessor) public virtual initializer {
    __Ownable_init();
    transferOwnership(owner);
    _processor = newProcessor;
    _realm = address(this);
    emit ProcessorChanged(address(newProcessor));
    emit RealmChanged(address(this));
  }

  modifier hasProcessor() {
    require(address(_processor) != address(0), "PR01");
    _;
  }

  modifier onlyAdministrator() {
    require(owner() == _msgSender() || isAdministrator(_msgSender()), "AD01");
    _;
  }

  /* Administrable */
  function isAdministrator(address _administrator) public override view returns (bool) {
    return _administrators.has(_administrator);
  }

  function addAdministrator(address _administrator) public override onlyOwner {
    _administrators.add(_administrator);
    emit AdministratorAdded(_administrator);
  }

  function removeAdministrator(address _administrator) public override onlyOwner {
    _administrators.remove(_administrator);
    emit AdministratorRemoved(_administrator);
  }

  /* Governable */
  function realm() public override view returns (address) {
    return _realm;
  }

  function setRealm(address newRealm) public override onlyAdministrator {
    BridgeERC20 king = BridgeERC20(newRealm);
    require(king.owner() == _msgSender() || king.isRealmAdministrator(_msgSender()), "KI01");
    _realm = newRealm;
    emit RealmChanged(newRealm);
  }

  function trustedIntermediaries() public override view returns (address[] memory) {
    return _trustedIntermediaries;
  }

  function setTrustedIntermediaries(address[] calldata newTrustedIntermediaries) external override onlyAdministrator {
    _trustedIntermediaries = newTrustedIntermediaries;
    emit TrustedIntermediariesChanged(newTrustedIntermediaries);
  }

  function isRealmAdministrator(address _administrator) public override view returns (bool) {
    return _realmAdministrators.has(_administrator);
  }

  function addRealmAdministrator(address _administrator) public override onlyAdministrator {
    _realmAdministrators.add(_administrator);
    emit RealmAdministratorAdded(_administrator);
  }

  function removeRealmAdministrator(address _administrator) public override onlyAdministrator {
    _realmAdministrators.remove(_administrator);
    emit RealmAdministratorRemoved(_administrator);
  }

  /* Priceable */
  function priceOracle() public override view returns (IPriceOracle) {
    return _priceOracle;
  }

  function setPriceOracle(IPriceOracle newPriceOracle) public override onlyAdministrator {
    _priceOracle = newPriceOracle;
    emit PriceOracleChanged(address(newPriceOracle));
  }

  function convertTo(
    uint256 _amount, string calldata _currency, uint8 maxDecimals
  ) 
    external override hasProcessor view returns(uint256) 
  {
    require(address(_priceOracle) != address(0), "PO03");
    uint256 amountToConvert = _amount;
    uint256 xrate;
    uint8 xrateDecimals;
    uint8 tokenDecimals = _processor.decimals();
    (xrate, xrateDecimals) = _priceOracle.getPrice(_processor.symbol(), _currency);
    if (xrateDecimals > maxDecimals) {
      xrate = xrate.div(10**uint256(xrateDecimals - maxDecimals));
      xrateDecimals = maxDecimals;
    }
    if (tokenDecimals > maxDecimals) {
      amountToConvert = amountToConvert.div(10**uint256(tokenDecimals - maxDecimals));
      tokenDecimals = maxDecimals;
    }
    /* Multiply amount in token decimals by xrate in xrate decimals */
    return amountToConvert.mul(xrate).mul(10**uint256((2*maxDecimals)-xrateDecimals-tokenDecimals));
  }

  /**
  * @dev Set the token processor
  **/
  function setProcessor(IProcessor newProcessor) public onlyAdministrator {
    _processor = newProcessor;
    emit ProcessorChanged(address(newProcessor));
  }

  /**
  * @return the token processor
  **/
  function processor() public view returns (IProcessor) {
    return _processor;
  }

  /**
  * @return the name of the token.
  */
  function name() public override view hasProcessor returns (string memory) {
    return _processor.name();
  }

  /**
  * @return the symbol of the token.
  */
  function symbol() public override view hasProcessor returns (string memory) {
    return _processor.symbol();
  }

  /**
  * @return the number of decimals of the token.
  */
  function decimals() public override view hasProcessor returns (uint8) {
    return _processor.decimals();
  }

  /**
  * @return total number of tokens in existence
  */
  function totalSupply() public override view hasProcessor returns (uint256) {
    return _processor.totalSupply();
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @return true if transfer is successful, false otherwise
  */
  function transfer(address _to, uint256 _value) public override hasProcessor 
    returns (bool) 
  {
    bool success;
    address updatedTo;
    uint256 updatedAmount;
    (success, updatedTo, updatedAmount) = _transferFrom(
      _msgSender(), 
      _to, 
      _value
    );
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public override view hasProcessor 
    returns (uint256) 
  {
    return _processor.balanceOf(_owner);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @return true if transfer is successful, false otherwise
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    override
    hasProcessor
    returns (bool)
  {
    require(_value <= _processor.allowance(_from, _msgSender()), "AL01"); 
    bool success;
    address updatedTo;
    uint256 updatedAmount;
    (success, updatedTo, updatedAmount) = _transferFrom(
      _from, 
      _to, 
      _value
    );
    _processor.decreaseApproval(_from, _msgSender(), updatedAmount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return true if approval is successful, false otherwise
   */
  function approve(address _spender, uint256 _value) public override hasProcessor returns (bool)
  {
    _approve(_msgSender(), _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    override
    view
    hasProcessor
    returns (uint256)
  {
    return _processor.allowance(_owner, _spender);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    hasProcessor
  {
    _increaseApproval(_msgSender(), _spender, _addedValue);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    hasProcessor
  {
    _decreaseApproval(_msgSender(), _spender, _subtractedValue);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @return _success True if the transfer is successful, false otherwise
   * @return _updatedTo The real address the tokens were sent to
   * @return _updatedAmount The real amount of tokens sent
   */
  function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool _success, address _updatedTo, uint256 _updatedAmount) {
    (_success, _updatedTo, _updatedAmount) = _processor.transferFrom(
      _from, 
      _to, 
      _value
    );
    emit Transfer(_from, _updatedTo, _updatedAmount);
    return (_success, _updatedTo, _updatedAmount);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _owner The owner address of the funds to spend
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function _approve(address _owner, address _spender, uint256 _value) internal {
    _processor.approve(_owner, _spender, _value);
    emit Approval(_owner, _spender, _value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _owner The address which has the funds
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function _increaseApproval(address _owner, address _spender, uint _addedValue) internal {
    _processor.increaseApproval(_owner, _spender, _addedValue);
    uint256 allowed = _processor.allowance(_owner, _spender);
    emit Approval(_owner, _spender, allowed);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _owner The address which has the funds
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function _decreaseApproval(address _owner, address _spender, uint _subtractedValue) internal {
    _processor.decreaseApproval(_owner, _spender, _subtractedValue);
    uint256 allowed = _processor.allowance(_owner, _spender);
    emit Approval(_owner, _spender, allowed);
  }

  /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
  uint256[50] private ______gap;
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Roles.sol";

/**
 * @title Operator
 * @dev The Operator contract contains list of addresses authorized to specific administration operations on contracts
 *
 * Error messages
 * OP01: Message sender must be an operator
 */


contract Operator is OwnableUpgradeable {
  using Roles for Roles.Role;

  Roles.Role private operators;

  event OperatorAdded(address indexed operator);
  event OperatorRemoved(address indexed operator);
  
  /**
  * @dev Initializer (replaces constructor when contract is upgradable)
  * @param owner the final owner of the contract
  */
  function initialize(address owner) public virtual initializer {
    __Ownable_init();
    transferOwnership(owner);
  }

  /**
   * @dev Throws OP01 if called by any account other than the operator
   */
  modifier onlyOperator {
    require(owner() == _msgSender() || operators.has(_msgSender()), "OP01");
    _;
  }

  /**
  * @dev Checks if the address in param _operator is granted the operator right
  * @param _operator the address to check for operator right
  * @return true if the address is granted the operator right, false otherwise
  */
  function isOperator(address _operator) public view returns (bool) {
    return operators.has(_operator);
  }

  /**
  * @dev Grants the operator right to _operator
  * @param _operator the address to grant
  */
  function addOperator(address _operator)
    public onlyOwner
  {
    operators.add(_operator);
    emit OperatorAdded(_operator);
  }

  /**
  * @dev Removes the operator right from the _operator address
  * @param _operator the address of the operator to remove
  */
  function removeOperator(address _operator)
    public onlyOwner
  {
    operators.remove(_operator);
    emit OperatorRemoved(_operator);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/*
    Copyright (c) 2016-2019 zOS Global Limited

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IERC20Detailed
 * @dev IERC20Detailed interface
 **/


interface IERC20Detailed {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IAdministrable
 * @dev IAdministrable interface
 **/
interface IAdministrable {
  function isAdministrator(address _administrator) external view returns (bool);
  function addAdministrator(address _administrator) external;
  function removeAdministrator(address _administrator) external;

  event AdministratorAdded(address indexed administrator);
  event AdministratorRemoved(address indexed administrator);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IGovernable
 * @dev IGovernable interface
 **/
interface IGovernable {
  function realm() external view returns (address);
  function setRealm(address _realm) external;

  function isRealmAdministrator(address _administrator) external view returns (bool);
  function addRealmAdministrator(address _administrator) external;
  function removeRealmAdministrator(address _administrator) external;

  function trustedIntermediaries() external view returns (address[] memory);
  function setTrustedIntermediaries(address[] calldata _trustedIntermediaries) external;

  event TrustedIntermediariesChanged(address[] newTrustedIntermediaries);
  event RealmChanged(address newRealm);
  event RealmAdministratorAdded(address indexed administrator);
  event RealmAdministratorRemoved(address indexed administrator);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

import "./IPriceOracle.sol";

/**
 * @title IPriceable
 * @dev IPriceable interface
 **/


interface IPriceable {
  function priceOracle() external view returns (IPriceOracle);
  function setPriceOracle(IPriceOracle _priceOracle) external;
  function convertTo(
    uint256 _amount, string calldata _currency, uint8 maxDecimals
  ) external view returns(uint256);

  event PriceOracleChanged(address indexed newPriceOracle);
}

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 * @dev IPriceOracle interface
 *
 **/


interface IPriceOracle {

  struct Price {
    uint256 price;
    uint8 decimals;
    uint256 lastUpdated;
  }

  function setPrice(bytes32 _currency1, bytes32 _currency2, uint256 _price, uint8 _decimals) external;
  function setPrices(bytes32[] calldata _currency1, bytes32[] calldata _currency2, uint256[] calldata _price, uint8[] calldata _decimals) external;
  function getPrice(bytes32 _currency1, bytes32 _currency2) external view returns (uint256, uint8);
  function getPrice(string calldata _currency1, string calldata _currency2) external view returns (uint256, uint8);
  function getLastUpdated(bytes32 _currency1, bytes32 _currency2) external view returns (uint256);
  function getDecimals(bytes32 _currency1, bytes32 _currency2) external view returns (uint8);

  event PriceSet(bytes32 indexed currency1, bytes32 indexed currency2, uint256 price, uint8 decimals, uint256 updateDate);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-block.timestamp/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}