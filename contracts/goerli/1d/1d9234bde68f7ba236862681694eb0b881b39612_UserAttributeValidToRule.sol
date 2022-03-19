/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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


// File contracts/bridge-token/interfaces/IRule.sol

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


// File contracts/bridge-token/rules/abstract/AbstractRule.sol

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
 * @title AbstractRule
 * @dev YesNoRule validates transfer if param _yesNo is more than 0
 * @dev Useful for testing implementation
 *
 * Error messages
 * RU02: Function cannot be called
 *
 */

contract AbstractRule is IRule {

  uint256 internal constant TRANSFER_INVALID = 0;
  uint256 internal constant TRANSFER_VALID_WITH_NO_HOOK = 1;
  uint256 internal constant TRANSFER_VALID_WITH_BEFORE_HOOK = 2;
  uint256 internal constant TRANSFER_VALID_WITH_AFTER_HOOK = 3;

  uint256 internal constant REASON_OK = 0;
  uint256 internal constant REASON_ABSTRACT_RULE = 1;

  /**
  * @dev Validates a transfer
  * @return transferStatus Invalid transfer
  * @return statusCode The reason of the transfer rejection
  */
  function isTransferValid(
    address /* _token */,
    address /* _from */,
    address /* _to */,
    uint256 /* _amount */,
    uint256 /* _param */ )
    public virtual override view returns (uint256, uint256)
  {
    return (TRANSFER_INVALID, REASON_ABSTRACT_RULE);
  }

  /**
  * @dev Dummy before transfer hook
  * @dev Not intended to be called
  * Throws RU02 because this function is not intended to be called
  */
  function beforeTransferHook(
    address /* _token */, address /* _from */, address /* _to */, uint256 /* _amount */, uint256 /* _param */)
    external virtual override returns (uint256, address, uint256)
  {
    revert("RU02");
  }

  /**
  * @dev Dummy after transfer hook
  * @dev Not intended to be called
  * Throws RU02 because this function is not intended to be called
  */
  function afterTransferHook(
    address /* _token */, address /* _from */, address /* _to */, uint256 /* _amount */, uint256 /* _param */)
    external virtual override returns (bool)
  {
    revert("RU02");
  }
}


// File contracts/bridge-token/interfaces/IComplianceRegistry.sol

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
 * @title IComplianceRegistry
 * @dev IComplianceRegistry interface
 **/
interface IComplianceRegistry {

  event AddressAttached(address indexed trustedIntermediary, uint256 indexed userId, address indexed address_);
  event AddressDetached(address indexed trustedIntermediary, uint256 indexed userId, address indexed address_);

  function userId(address[] calldata _trustedIntermediaries, address _address) 
    external view returns (uint256, address);
  function validUntil(address _trustedIntermediary, uint256 _userId) 
    external view returns (uint256);
  function attribute(address _trustedIntermediary, uint256 _userId, uint256 _key)
    external view returns (uint256);
  function attributes(address _trustedIntermediary, uint256 _userId, uint256[] calldata _keys) 
    external view returns (uint256[] memory);

  function isAddressValid(address[] calldata _trustedIntermediaries, address _address) external view returns (bool);
  function isValid(address _trustedIntermediary, uint256 _userId) external view returns (bool);

  function registerUser(
    address _address, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) external;
  function registerUsers(
    address[] calldata _addresses, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) external;

  function attachAddress(uint256 _userId, address _address) external;
  function attachAddresses(uint256[] calldata _userIds, address[] calldata _addresses) external;

  function detachAddress(address _address) external;
  function detachAddresses(address[] calldata _addresses) external;

  function updateUserAttributes(
    uint256 _userId, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) external;
  function updateUsersAttributes(
    uint256[] calldata _userIds, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) external;

  function updateTransfers(
    address _realm, 
    address _from, 
    address _to, 
    uint256 _value
  ) external;
  function monthlyTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);
  function yearlyTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);
  function monthlyInTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);
  function yearlyInTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);
  function monthlyOutTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);
  function yearlyOutTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function addOnHoldTransfer(
    address trustedIntermediary,
    address token,
    address from, 
    address to, 
    uint256 amount
  ) external;

  function getOnHoldTransfers(address trustedIntermediary)
    external view returns (
      uint256 length, 
      uint256[] memory id,
      address[] memory token, 
      address[] memory from, 
      address[] memory to, 
      uint256[] memory amount
    );

  function processOnHoldTransfers(uint256[] calldata transfers, uint8[] calldata transferDecisions, bool skipMinBoundaryUpdate) external;
  function updateOnHoldMinBoundary(uint256 maxIterations) external;

  event TransferOnHold(
    address indexed trustedIntermediary,
    address indexed token, 
    address indexed from, 
    address to, 
    uint256 amount
  );
  event TransferApproved(
    address indexed trustedIntermediary,
    address indexed token, 
    address indexed from, 
    address to, 
    uint256 amount
  );
  event TransferRejected(
    address indexed trustedIntermediary,
    address indexed token, 
    address indexed from, 
    address to, 
    uint256 amount
  );
  event TransferCancelled(
    address indexed trustedIntermediary,
    address indexed token, 
    address indexed from, 
    address to, 
    uint256 amount
  );
}


// File contracts/bridge-token/interfaces/IGovernable.sol

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


// File contracts/bridge-token/rules/UserAttributeValidToRule.sol

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
 * @title UserAttributeValidToRule
 * @dev UserAttributeValidToRule checks if receiver attribute value of a transfer is above a specific threshold 
 * and rejects the transfer if not
 *
 * Error messages
 * RU02: Function cannot be called
 *
 * Errors
 * 1: address not found in User Registry
 * 2: User attribute is less than threshold
 */

 
contract UserAttributeValidToRule is Initializable, AbstractRule {

  uint256 public constant VERSION = 2;
  IComplianceRegistry public complianceRegistry;

  uint256 constant internal USER_ATTRIBUTE_THRESHOLD = 1;
  uint256 constant internal WHITELISTED_KEY = 130;

  uint256 internal constant REASON_ADDRESS_NOT_REGISTERED = 1;
  uint256 internal constant REASON_ATTRIBUTE_LESS_THAN_THRESHOLD = 2;

  /**
  * @dev Initializer (replaces constructor when contract is upgradable)
  * @param _complianceRegistry The Compliance Registry address that will be used by this rule for compliance checks
  */
  function initialize(IComplianceRegistry _complianceRegistry) public initializer {
    complianceRegistry = _complianceRegistry;
  }

  /**
  * @dev Validates a transfer if the to address attribute value is greater or equal the defined threshold
  * @param _token Address of the contract that represent the token to be transfered
  * @param _to Receiver address
  * @param _attributeKey The attribute key defined at the token rule level
  * @return transferStatus Invalid transfer if attribute value is below the threshold, valid transfer without further action otherwise
  * @return statusCode The reason of the transfer rejection
  */
  function isTransferValid(
    address _token, address /* _from */, address _to, uint256 /* _amount */, uint256 _attributeKey)
    public override view returns (uint256, uint256)
  {
    address[] memory trustedIntermediaries = IGovernable(_token).trustedIntermediaries();
    uint256 userId;
    address trustedIntermediary;
    (userId, trustedIntermediary) = complianceRegistry.userId(trustedIntermediaries, _to);
    if (userId == 0) {
      return (TRANSFER_INVALID, REASON_ADDRESS_NOT_REGISTERED);
    }
    if (complianceRegistry.attribute(trustedIntermediary, userId, WHITELISTED_KEY) < USER_ATTRIBUTE_THRESHOLD && complianceRegistry.attribute(trustedIntermediary, userId, _attributeKey) < USER_ATTRIBUTE_THRESHOLD) {
      return (TRANSFER_INVALID, REASON_ATTRIBUTE_LESS_THAN_THRESHOLD);
    }
    return (TRANSFER_VALID_WITH_NO_HOOK, 0);
  }
}