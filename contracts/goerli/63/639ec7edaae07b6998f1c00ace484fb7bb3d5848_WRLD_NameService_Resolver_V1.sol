/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: contracts/IWRLD_Records.sol


pragma solidity ^0.8.4;

interface IWRLD_Records {
  struct StringRecord {
    string value;
    string typeOf;
    uint32 ttl;
  }

  struct AddressRecord {
    address value;
    uint32 ttl;
  }

  struct UintRecord {
    uint256 value;
    uint32 ttl;
  }

  struct IntRecord {
    int256 value;
    uint32 ttl;
  }

}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: contracts/IWRLD_Name_Service_Storage.sol


pragma solidity ^0.8.4;



interface IWRLD_Name_Service_Storage is IERC165, IWRLD_Records {
  event StringRecordUpdated(uint256 indexed tokenId, string record, string value, string typeOf, uint32 ttl);
  event AddressRecordUpdated(uint256 indexed tokenId, string record, address value, uint32 ttl);
  event UintRecordUpdated(uint256 indexed tokenId, string record, uint256 value, uint32 ttl);
  event IntRecordUpdated(uint256 indexed tokenId, string record, int256 value, uint32 ttl);
  event WalletRecordUpdated(uint256 indexed tokenId, uint256 record, string value);

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external;
  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external;
  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external;
  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external;
  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external;
  
  function getStringRecord(uint256 tokenId, string calldata _record) external view returns (StringRecord memory);
  function getAddressRecord(uint256 tokenId, string calldata _record) external view returns (AddressRecord memory);
  function getUintRecord(uint256 tokenId, string calldata _record) external view returns (UintRecord memory);
  function getIntRecord(uint256 tokenId, string calldata _record) external view returns (IntRecord memory);
  function getWalletRecord(uint256 tokenId, uint256 _record) external view returns (string memory);

}
// File: contracts/IWRLD_Name_Service_Bridge.sol


pragma solidity ^0.8.4;


interface IWRLD_Name_Service_Bridge is IERC165 {
  event NameBridged(uint256 indexed tokenId, address registerer, uint96 expiresAt);

  function nameTokenId(string memory name) external pure returns (uint256);
  function registererOf(uint256 tokenId) external view returns (address);
  function controllerOf(uint256 tokenId) external view returns (address);
  function expiryOf(uint256 tokenId) external view returns (uint96);
  function nameOf(uint256 tokenId) external view returns (string memory);
  function isAuthd(uint256 tokenId, address user) external view returns (bool);

}

// File: contracts/IWRLD_Name_Service_Resolver.sol


pragma solidity ^0.8.4;



interface IWRLD_Name_Service_Resolver is IERC165, IWRLD_Records {
  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external;
  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external;
  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external;
  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external;
  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external;
  
  function getStringRecord(uint256 tokenId, string calldata _record) external view returns (StringRecord memory);
  function getAddressRecord(uint256 tokenId, string calldata _record) external view returns (AddressRecord memory);
  function getUintRecord(uint256 tokenId, string calldata _record) external view returns (UintRecord memory);
  function getIntRecord(uint256 tokenId, string calldata _record) external view returns (IntRecord memory);
  function getWalletRecord(uint256 tokenId, uint256 _record) external view returns (string memory);
}

// File: contracts/WRLD_Name_Service_Resolver_V1.sol


pragma solidity ^0.8.4;




// Resolvers can be updated without needing to migrate storage
// Multiple resolvers can be deployed for each storage
contract WRLD_NameService_Resolver_V1 is IWRLD_Name_Service_Resolver {
  IWRLD_Name_Service_Bridge nameServiceBridge;
  IWRLD_Name_Service_Storage nameServiceStorage;


  constructor(address _nameServiceBridge, address _nameServiceStorage) {
    nameServiceBridge = IWRLD_Name_Service_Bridge(_nameServiceBridge);
    nameServiceStorage = IWRLD_Name_Service_Storage(_nameServiceStorage);
  }

  /******************
   * Record Setters *
   ******************/
   // To delete records simply set them to empty
   // Enumeration needs to be implemented off-chain since there's no efficient CRUD implementation for string type

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setStringRecord(tokenId, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setAddressRecord(tokenId, _record, _value, _ttl);
  }

  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setUintRecord(tokenId, _record, _value, _ttl);
  }

  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setIntRecord(tokenId, _record, _value, _ttl);
  }

  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external override onlyAuthd(tokenId) {
    nameServiceStorage.setWalletRecord(tokenId, _record, _value);
  }

  /******************
   * Record Getters *
   ******************/

  function getStringRecord(uint256 tokenId, string calldata _record) external view override returns (StringRecord memory) {
    return nameServiceStorage.getStringRecord(tokenId, _record);
  }

  function getAddressRecord(uint256 tokenId, string calldata _record) external view override returns (AddressRecord memory) {
    return nameServiceStorage.getAddressRecord(tokenId, _record);
  }

  function getUintRecord(uint256 tokenId, string calldata _record) external view override returns (UintRecord memory) {
    return nameServiceStorage.getUintRecord(tokenId, _record);
  }

  function getIntRecord(uint256 tokenId, string calldata _record) external view override returns (IntRecord memory) {
    return nameServiceStorage.getIntRecord(tokenId, _record);
  }

  function getWalletRecord(uint256 tokenId, uint256 _record) external view override returns (string memory) {
    return nameServiceStorage.getWalletRecord(tokenId, _record);
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Resolver).interfaceId;
  }

  /*************
   * Modifiers *
   *************/

  modifier onlyAuthd(uint256 tokenId) {
    require(nameServiceBridge.isAuthd(tokenId, msg.sender), "Sender is not authorized.");
    _;
  }
}