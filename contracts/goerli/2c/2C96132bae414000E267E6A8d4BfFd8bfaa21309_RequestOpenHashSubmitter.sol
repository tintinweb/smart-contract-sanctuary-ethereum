// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './StorageFeeCollector.sol';
import './RequestHashStorage.sol';
import './Bytes.sol';

/**
 * @title RequestOpenHashSubmitter
 * @notice Contract declares data hashes and collects the fees.
 * @notice The hash is declared to the whole request network system through the RequestHashStorage contract.
 * @notice Anyone can submit hashes.
 */
contract RequestOpenHashSubmitter is StorageFeeCollector {
  RequestHashStorage public requestHashStorage;

  /**
   * @param _addressRequestHashStorage contract address which manages the hashes declarations
   * @param _addressBurner Burner address
   */
  constructor(address _addressRequestHashStorage, address payable _addressBurner)
    StorageFeeCollector(_addressBurner)
  {
    requestHashStorage = RequestHashStorage(_addressRequestHashStorage);
  }

  // Fallback function returns funds to the sender
  receive() external payable {
    revert('not payable receive');
  }

  /**
   * @notice Submit a new hash to the blockchain.
   *
   * @param _hash Hash of the request to be stored
   * @param _feesParameters fees parameters used to compute the fees. Here, it is the content size in an uint256
   */
  function submitHash(string calldata _hash, bytes calldata _feesParameters) external payable {
    // extract the contentSize from the _feesParameters
    uint256 contentSize = uint256(Bytes.extractBytes32(_feesParameters, 0));

    // Check fees are paid
    require(getFeesAmount(contentSize) == msg.value, 'msg.value does not match the fees');

    // Send fees to burner, throws on failure
    collectForREQBurning(msg.value);

    // declare the hash to the whole system through to RequestHashStorage
    requestHashStorage.declareNewHash(_hash, _feesParameters);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './legacy_openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';

/**
 * @title StorageFeeCollector
 *
 * @notice StorageFeeCollector is a contract managing the fees
 */
contract StorageFeeCollector is WhitelistAdminRole {
  /**
   * Fee computation for storage are based on four parameters:
   * minimumFee (wei) fee that will be applied for any size of storage
   * rateFeesNumerator (wei) and rateFeesDenominator (byte) define the variable fee,
   * for each <rateFeesDenominator> bytes above threshold, <rateFeesNumerator> wei will be charged
   *
   * Example:
   * If the size to store is 50 bytes, the threshold is 100 bytes and the minimum fee is 300 wei,
   * then 300 will be charged
   *
   * If rateFeesNumerator is 2 and rateFeesDenominator is 1 then 2 wei will be charged for every bytes above threshold,
   * if the size to store is 150 bytes then the fee will be 300 + (150-100)*2 = 400 wei
   */
  uint256 public minimumFee;
  uint256 public rateFeesNumerator;
  uint256 public rateFeesDenominator;

  // address of the contract that will burn req token
  address payable public requestBurnerContract;

  event UpdatedFeeParameters(
    uint256 minimumFee,
    uint256 rateFeesNumerator,
    uint256 rateFeesDenominator
  );
  event UpdatedMinimumFeeThreshold(uint256 threshold);
  event UpdatedBurnerContract(address burnerAddress);

  /**
   * @param _requestBurnerContract Address of the contract where to send the ether.
   * This burner contract will have a function that can be called by anyone
   * and will exchange ether to req via Kyber and burn the REQ
   */
  constructor(address payable _requestBurnerContract) {
    requestBurnerContract = _requestBurnerContract;
  }

  /**
    * @notice Sets the fees rate and minimum fee.
    * @dev if the _rateFeesDenominator is 0, it will be treated as 1.
            (in other words, the computation of the fees will not use it)
    * @param _minimumFee minimum fixed fee
    * @param _rateFeesNumerator numerator rate
    * @param _rateFeesDenominator denominator rate
    */
  function setFeeParameters(
    uint256 _minimumFee,
    uint256 _rateFeesNumerator,
    uint256 _rateFeesDenominator
  ) external onlyWhitelistAdmin {
    minimumFee = _minimumFee;
    rateFeesNumerator = _rateFeesNumerator;
    rateFeesDenominator = _rateFeesDenominator;
    emit UpdatedFeeParameters(minimumFee, rateFeesNumerator, rateFeesDenominator);
  }

  /**
   * @notice Set the request burner address.
   * @param _requestBurnerContract address of the contract that will burn req token (probably through Kyber)
   */
  function setRequestBurnerContract(address payable _requestBurnerContract)
    external
    onlyWhitelistAdmin
  {
    requestBurnerContract = _requestBurnerContract;
    emit UpdatedBurnerContract(requestBurnerContract);
  }

  /**
   * @notice Computes the fees.
   * @param _contentSize Size of the content of the block to be stored
   * @return the expected amount of fees in wei
   */
  function getFeesAmount(uint256 _contentSize) public view returns (uint256) {
    // Transactions fee
    uint256 computedAllFee = _contentSize * rateFeesNumerator;

    if (rateFeesDenominator != 0) {
      computedAllFee = computedAllFee / rateFeesDenominator;
    }

    if (computedAllFee <= minimumFee) {
      return minimumFee;
    } else {
      return computedAllFee;
    }
  }

  /**
   * @notice Sends fees to the request burning address.
   * @param _amount amount to send to the burning address
   */
  function collectForREQBurning(uint256 _amount) internal {
    // .transfer throws on failure
    requestBurnerContract.transfer(_amount);
  }
}

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

/**
 * @title Bytes util library.
 * @notice Collection of utility functions to manipulate bytes for Request.
 */
library Bytes {
  /**
   * @notice Extract a bytes32 from a bytes.
   * @param data bytes from where the bytes32 will be extract
   * @param offset position of the first byte of the bytes32
   * @return result the 32 bytes extracted
   */
  function extractBytes32(bytes memory data, uint256 offset)
    internal
    pure
    returns (bytes32 result)
  {
    require(
      offset >= 0 && offset + 32 <= data.length,
      'offset value should be in the correct range'
    );

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(data, add(32, offset)))
    }
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