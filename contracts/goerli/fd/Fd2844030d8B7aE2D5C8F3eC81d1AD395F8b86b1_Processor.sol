pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./Roles.sol";

/**
 * @title Operator
 * @dev The Operator contract contains list of addresses authorized to specific administration operations on contracts
 *
 * Error messages
 * OP01: Message sender must be an operator
 */


contract Operator is OwnableUpgradeSafe {
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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;


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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

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

pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../interfaces/IProcessor.sol";
import "../interfaces/IRule.sol";
import "../interfaces/IRuleEngine.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/ISeizable.sol";
import "../interfaces/ISuppliable.sol";
import "../interfaces/IRulable.sol";

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
    /* Update */
    _subBalance(_from, _value);
    _addBalance(_to, _value);
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