// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Registry.sol";

contract WRLD_NameService_Resolver_V1 is IWRLD_Name_Service_Resolver {
  IWRLD_Name_Service_Registry immutable nameServiceRegistry;

  mapping(uint256 => mapping(string => StringRecord)) private wrldNameStringRecords;
  mapping(uint256 => string[]) private wrldNameStringRecordsList;

  mapping(uint256 => mapping(string => AddressRecord)) private wrldNameAddressRecords;
  mapping(uint256 => string[]) private wrldNameAddressRecordsList;

  mapping(uint256 => mapping(string => UintRecord)) private wrldNameUintRecords;
  mapping(uint256 => string[]) private wrldNameUintRecordsList;

  mapping(uint256 => mapping(string => IntRecord)) private wrldNameIntRecords;
  mapping(uint256 => string[]) private wrldNameIntRecordsList;

  mapping(bytes32 => string) private wrldNameStringEntries;
  mapping(bytes32 => address) private wrldNameAddressEntries;
  mapping(bytes32 => uint) private wrldNameUintEntries;
  mapping(bytes32 => int) private wrldNameIntEntries;

  constructor(address _nameServiceRegistry) {
    nameServiceRegistry = IWRLD_Name_Service_Registry(_nameServiceRegistry);
  }

  /******************
   * Record Setters *
   ******************/

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameStringRecords[_getNameTokenId(_name)][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    wrldNameStringRecordsList[_getNameTokenId(_name)].push(_record);

    emit StringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameAddressRecords[_getNameTokenId(_name)][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameAddressRecordsList[_getNameTokenId(_name)].push(_record);

    emit AddressRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameUintRecords[_getNameTokenId(_name)][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameUintRecordsList[_getNameTokenId(_name)].push(_record);

    emit UintRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameIntRecords[_getNameTokenId(_name)][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameIntRecordsList[_getNameTokenId(_name)].push(_record);

    emit IntRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  /******************
   * Record Getters *
   ******************/

  function getNameStringRecord(string calldata _name, string calldata _record) external view override returns (StringRecord memory) {
    return wrldNameStringRecords[_getNameTokenId(_name)][_record];
  }

  function getNameStringRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameStringRecordsList[_getNameTokenId(_name)];
  }

  function getNameStringRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view override returns (string[] memory) {
    string[] storage allRecords = wrldNameStringRecordsList[_getNameTokenId(_name)];
    string[] memory paginatedRecords = new string[](_limit);

    for (uint256 i = 0; i < _limit; i++) {
      paginatedRecords[i] = allRecords[_offset + i];
    }

    return paginatedRecords;
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external view override returns (AddressRecord memory) {
    return wrldNameAddressRecords[_getNameTokenId(_name)][_record];
  }

  function getNameAddressRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameAddressRecordsList[_getNameTokenId(_name)];
  }

  function getNameAddressRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view override returns (string[] memory) {
    string[] storage allRecords = wrldNameAddressRecordsList[_getNameTokenId(_name)];
    string[] memory paginatedRecords = new string[](_limit);

    for (uint256 i = 0; i < _limit; i++) {
      paginatedRecords[i] = allRecords[_offset + i];
    }

    return paginatedRecords;
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external view override returns (UintRecord memory) {
    return wrldNameUintRecords[_getNameTokenId(_name)][_record];
  }

  function getNameUintRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameUintRecordsList[_getNameTokenId(_name)];
  }

  function getNameUintRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view override returns (string[] memory) {
    string[] storage allRecords = wrldNameUintRecordsList[_getNameTokenId(_name)];
    string[] memory paginatedRecords = new string[](_limit);

    for (uint256 i = 0; i < _limit; i++) {
      paginatedRecords[i] = allRecords[_offset + i];
    }

    return paginatedRecords;
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external view override returns (IntRecord memory) {
    return wrldNameIntRecords[_getNameTokenId(_name)][_record];
  }

  function getNameIntRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameIntRecordsList[_getNameTokenId(_name)];
  }

  function getNameIntRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view override returns (string[] memory) {
    string[] storage allRecords = wrldNameIntRecordsList[_getNameTokenId(_name)];
    string[] memory paginatedRecords = new string[](_limit);

    for (uint256 i = 0; i < _limit; i++) {
      paginatedRecords[i] = allRecords[_offset + i];
    }

    return paginatedRecords;
  }

  /*****************
   * Entry Setters *
   *****************/

  function setStringEntry(address _setter, string calldata _name, string calldata _entry, string calldata _value) external override onlyNameServiceRegistry {
    wrldNameStringEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setAddressEntry(address _setter, string calldata _name, string calldata _entry, address _value) external override onlyNameServiceRegistry {
    wrldNameAddressEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setUintEntry(address _setter, string calldata _name, string calldata _entry, uint256 _value) external override onlyNameServiceRegistry {
    wrldNameUintEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setIntEntry(address _setter, string calldata _name, string calldata _entry, int256 _value) external override onlyNameServiceRegistry {
    wrldNameIntEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  /*****************
   * Entry Getters *
   *****************/

  function getStringEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (string memory) {
    return wrldNameStringEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getAddressEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (address) {
    return wrldNameAddressEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getUintEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (uint256) {
    return wrldNameUintEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getIntEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (int256) {
    return wrldNameIntEntries[_getEntryHash(_setter, _name, _entry)];
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Resolver).interfaceId;
  }

  /***********
   * Helpers *
   ***********/

  function _getNameTokenId(string memory _name) private view returns (uint256) {
    return nameServiceRegistry.getNameTokenId(_name);
  }

  function _getEntryHash(address _setter, string memory _name, string memory _entry) private pure returns (bytes32) {
    return keccak256(abi.encode(_setter, _name, _entry));
  }

  /*************
   * Modifiers *
   *************/

  modifier onlyNameServiceRegistry() {
    require(msg.sender == address(nameServiceRegistry), "Sender is not name service.");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IWRLD_Records.sol";

interface IWRLD_Name_Service_Resolver is IERC165, IWRLD_Records {
  /***********
   * Records *
   ***********/

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external;
  function getNameStringRecord(string calldata _name, string calldata _record) external view returns (StringRecord memory);
  function getNameStringRecordsList(string calldata _name) external view returns (string[] memory);
  function getNameStringRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory);

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external;
  function getNameAddressRecord(string calldata _name, string calldata _record) external view returns (AddressRecord memory);
  function getNameAddressRecordsList(string calldata _name) external view returns (string[] memory);
  function getNameAddressRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory);

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external;
  function getNameUintRecord(string calldata _name, string calldata _record) external view returns (UintRecord memory);
  function getNameUintRecordsList(string calldata _name) external view returns (string[] memory);
  function getNameUintRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory);

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external;
  function getNameIntRecord(string calldata _name, string calldata _record) external view returns (IntRecord memory);
  function getNameIntRecordsList(string calldata _name) external view returns (string[] memory);
  function getNameIntRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory);

  /***********
   * Entries *
   ***********/

  function setStringEntry(address _setter, string calldata _name, string calldata _entry, string calldata _value) external;
  function getStringEntry(address _setter, string calldata _name, string calldata _entry) external view returns (string memory);

  function setAddressEntry(address _setter, string calldata _name, string calldata _entry, address _value) external;
  function getAddressEntry(address _setter, string calldata _name, string calldata _entry) external view returns (address);

  function setUintEntry(address _setter, string calldata _name, string calldata _entry, uint256 _value) external;
  function getUintEntry(address _setter, string calldata _name, string calldata _entry) external view returns (uint256);

  function setIntEntry(address _setter, string calldata _name, string calldata _entry, int256 _value) external;
  function getIntEntry(address _setter, string calldata _name, string calldata _entry) external view returns (int256);

  /**********
   * Events *
   **********/

  event StringRecordUpdated(string indexed idxName, string name, string record, string value, string typeOf, uint256 ttl);
  event AddressRecordUpdated(string indexed idxName, string name, string record, address value, uint256 ttl);
  event UintRecordUpdated(string indexed idxName, string name, string record, uint256 value, uint256 ttl);
  event IntRecordUpdated(string indexed idxName, string name, string record, int256 value, uint256 ttl);

  event StringEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, string value);
  event AddressEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, address value);
  event UintEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, uint256 value);
  event IntEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, int256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Registry is IERC165 {
  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external;
  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external;

  function getNameTokenId(string calldata _name) external view returns (uint256);

  event NameRegistered(string indexed idxName, string name, uint16 registrationYears);
  event NameRegistrationExtended(string indexed idxName, string name, uint16 additionalYears);
  event NameControllerUpdated(string indexed idxName, string name, address controller);

  event ResolverStringRecordUpdated(string indexed idxName, string name, string record, string value, string typeOf, uint256 ttl, address resolver);
  event ResolverAddressRecordUpdated(string indexed idxName, string name, string record, address value, uint256 ttl, address resolver);
  event ResolverUintRecordUpdated(string indexed idxName, string name, string record, uint256 value, uint256 ttl, address resolver);
  event ResolverIntRecordUpdated(string indexed idxName, string name, string record, int256 value, uint256 ttl, address resolver);

  event ResolverStringEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, string value);
  event ResolverAddressEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, address value);
  event ResolverUintEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, uint256 value);
  event ResolverIntEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, int256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWRLD_Records {
  struct StringRecord {
    string value;
    string typeOf;
    uint256 ttl;
  }

  struct AddressRecord {
    address value;
    uint256 ttl;
  }

  struct UintRecord {
    uint256 value;
    uint256 ttl;
  }

  struct IntRecord {
    int256 value;
    uint256 ttl;
  }
}