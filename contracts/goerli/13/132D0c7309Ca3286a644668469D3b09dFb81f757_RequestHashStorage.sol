// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './legacy_openzeppelin/contracts/access/roles/WhitelistedRole.sol';

/**
 * @title RequestHashStorage
 * @notice This contract is the entry point to retrieve all the hashes of the request network system.
 */
contract RequestHashStorage is WhitelistedRole {
  // Event to declare a new hash
  event NewHash(string hash, address hashSubmitter, bytes feesParameters);

  /**
   * @notice Declare a new hash
   * @param _hash hash to store
   * @param _feesParameters Parameters use to compute the fees.
                            This is a bytes to stay generic,
                            the structure is on the charge of the hashSubmitter contracts.
   */
  function declareNewHash(string calldata _hash, bytes calldata _feesParameters)
    external
    onlyWhitelisted
  {
    // Emit event for log
    emit NewHash(_hash, msg.sender, _feesParameters);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '../Roles.sol';
import './WhitelistAdminRole.sol';

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
abstract contract WhitelistedRole is Context, WhitelistAdminRole {
  using Roles for Roles.Role;

  event WhitelistedAdded(address indexed account);
  event WhitelistedRemoved(address indexed account);

  Roles.Role private _whitelisteds;

  modifier onlyWhitelisted() {
    require(
      isWhitelisted(_msgSender()),
      'WhitelistedRole: caller does not have the Whitelisted role'
    );
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return _whitelisteds.has(account);
  }

  function addWhitelisted(address account) public onlyWhitelistAdmin {
    _addWhitelisted(account);
  }

  function removeWhitelisted(address account) public onlyWhitelistAdmin {
    _removeWhitelisted(account);
  }

  function renounceWhitelisted() public {
    _removeWhitelisted(_msgSender());
  }

  function _addWhitelisted(address account) internal {
    _whitelisteds.add(account);
    emit WhitelistedAdded(account);
  }

  function _removeWhitelisted(address account) internal {
    _whitelisteds.remove(account);
    emit WhitelistedRemoved(account);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '../Roles.sol';

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is Context {
  using Roles for Roles.Role;

  event WhitelistAdminAdded(address indexed account);
  event WhitelistAdminRemoved(address indexed account);

  Roles.Role private _whitelistAdmins;

  constructor() {
    _addWhitelistAdmin(_msgSender());
  }

  modifier onlyWhitelistAdmin() {
    require(
      isWhitelistAdmin(_msgSender()),
      'WhitelistAdminRole: caller does not have the WhitelistAdmin role'
    );
    _;
  }

  function isWhitelistAdmin(address account) public view returns (bool) {
    return _whitelistAdmins.has(account);
  }

  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    _addWhitelistAdmin(account);
  }

  function renounceWhitelistAdmin() public {
    _removeWhitelistAdmin(_msgSender());
  }

  function _addWhitelistAdmin(address account) internal {
    _whitelistAdmins.add(account);
    emit WhitelistAdminAdded(account);
  }

  function _removeWhitelistAdmin(address account) internal {
    _whitelistAdmins.remove(account);
    emit WhitelistAdminRemoved(account);
  }
}