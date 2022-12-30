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

import "../interfaces/IPriceOracle.sol";
import "../access/Operator.sol";

/**
 * @title PriceOracle
 * @dev The Price Oracle stores price related data for currency/token price conversion
 *
 * Error messages
 * PO01: Currency1 length does not match price length 
 * PO02: Currency1 length does not match decimals length 
 * PO03: Currency1 length does not match currency2 length
*/


contract PriceOracle is Initializable, IPriceOracle, Operator {

  uint256 public constant VERSION = 1;

  mapping(bytes32 => mapping(bytes32 => Price)) _prices;

  /**
  * @dev Initializer (replaces constructor when contract is upgradable)
  * @param owner the final owner of the contract
  */
  function initialize(address owner) public override initializer {
    Operator.initialize(owner);
  }

  /**
  * @dev Set prices for multiple pairs at the same time
  * @param _currency1 array of source tokens/currencies to update prices for
  * @param _currency2 array of destination tokens/currencies to update prices for
  * @param _price array of prices
  * @param _decimals array of decimals of the price to be set
  */
  function setPrices(
    bytes32[] calldata _currency1,
    bytes32[] calldata _currency2,
    uint256[] calldata _price, 
    uint8[] calldata _decimals
  ) 
    external override onlyOperator 
  {
    require(_currency1.length == _price.length, "PO01");
    require(_currency1.length == _decimals.length, "PO02");
    require(_currency1.length == _currency2.length, "PO03");
    for (uint256 i = 0; i < _currency1.length; i++) {
      // solium-disable-next-line security/no-block-members
      _prices[_currency1[i]][_currency2[i]] = Price(_price[i], _decimals[i], now);
      // solium-disable-next-line security/no-block-members
      emit PriceSet(_currency1[i], _currency2[i], _price[i], _decimals[i], now);
    }
  }
  
  /**
  * @dev Set prices for multiple pairs at the same time
  * @param _currency1 source token/currency to update the price for
  * @param _currency2 destination token/currency to update the price for
  * @param _price new price
  * @param _decimals decimals of the price to be set
  */
  function setPrice(bytes32 _currency1, bytes32 _currency2, uint256 _price, uint8 _decimals) public override onlyOperator {
    // solium-disable-next-line security/no-block-members
    _prices[_currency1][_currency2] = Price(_price, _decimals, now);
    // solium-disable-next-line security/no-block-members
    emit PriceSet(_currency1, _currency2, _price, _decimals, now);
  }

  /**
  * @dev Get the price information for a specific pair of tokens/currencies
  * @param _currency1 source token/currency to retrieve the price for
  * @param _currency2 destination token/currency to retrieve the price for
  * @return price price in decimals for the wanted pair
  * @return decimals number of decimals for the returns pair price
  */
  function getPrice(bytes32 _currency1, bytes32 _currency2) public override view returns (uint256, uint8) {
    return (_prices[_currency1][_currency2].price, _prices[_currency1][_currency2].decimals);
  }

  /**
  * @dev Get the price information for a specific pair of tokens/currencies
  * @param _currency1 First token/currency symbol string
  * @param _currency2 Second token/currency symbol string
  * @return price price in decimals for the wanted pair
  * @return decimals number of decimals for the returns pair price
  */
  function getPrice(string calldata _currency1, string calldata _currency2) external override view returns (uint256, uint8) {
    return getPrice(_asBytes32(_currency1), _asBytes32(_currency2));
  }

  /**
  * @dev Get the last update date for a specific pair of tokens/currencies
  * @param _currency1 source token/currency to retrieve the last update date for
  * @param _currency2 destination token/currency to retrieve the last update date for
  * @return lastUpdateDate last update date for the required pair
  */
  function getLastUpdated(bytes32 _currency1, bytes32 _currency2) public override view returns (uint256) {
    return _prices[_currency1][_currency2].lastUpdated;
  }

  /**
  * @dev Get the decimals for a specific pair of tokens/currencies
  * @param _currency1 source token/currency to retrieve the decimals for
  * @param _currency2 destination token/currency to retrieve the decimals for
  * @return decimals last update date for the required pair
  */
  function getDecimals(bytes32 _currency1, bytes32 _currency2) public override view returns (uint8) {
    return _prices[_currency1][_currency2].decimals;
  }

  /**
  * @dev Get the bytes32 representation of a token/currency symbol string
  * @param _currency token/currency symbol string
  * @return result the bytes32 representation of the token/currency symbol string as bytes32
  */
  function _asBytes32(string memory _currency) internal pure returns (bytes32 result) {
    bytes memory _currencyAsBytes = bytes(_currency);

    /* Returns 32 first bytes _currencyAsBytes */
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(_currencyAsBytes, 32))
    }
  }
}