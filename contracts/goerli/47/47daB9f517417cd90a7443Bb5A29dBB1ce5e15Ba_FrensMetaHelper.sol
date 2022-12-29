// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./interfaces/ISSVRegistry.sol";
import "./interfaces/IFrensMetaHelper.sol";
import "./interfaces/IENS.sol";
import "./interfaces/IReverseResolver.sol";
import "./FrensBase.sol";
import './ToColor.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract FrensMetaHelper is IFrensMetaHelper, FrensBase {

  using ToColor for bytes3;
  using Strings for uint256;

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage) {
    //hi fren
  }

  function getColor(address a) public pure returns(string memory){
    bytes32 colorRandomness = keccak256(abi.encodePacked(address(a)));
    bytes3 colorBytes = bytes2(colorRandomness[0]) | ( bytes2(colorRandomness[1]) >> 8 ) | ( bytes3(colorRandomness[2]) >> 16 );
    string memory color = colorBytes.toColor();
    return color;
  }

  function getEthDecimalString(uint amountInWei) public pure returns(string memory){
    string memory leftOfDecimal = (amountInWei / 1 ether).toString();
    uint rightOfDecimal = (amountInWei % 1 ether) / 10**14;
    string memory rod = rightOfDecimal.toString();
    if(rightOfDecimal < 1000) rod = string.concat("0", rod);
    if(rightOfDecimal < 100) rod = string.concat("0", rod);
    if(rightOfDecimal < 10) rod = string.concat("0", rod);
    return string.concat(leftOfDecimal, ".", rod);
  }

  function getOperatorsForPool(address poolAddress) public view returns (uint32[] memory, string memory) {
    bytes memory poolPubKey = getBytes(keccak256(abi.encodePacked("validator.public.key", poolAddress)));
    string memory pubKeyString = _iToHex(poolPubKey);
    ISSVRegistry ssvRegistry = ISSVRegistry(getAddress(keccak256(abi.encodePacked("external.contract.address", "SSVRegistry"))));
    uint32[] memory poolOperators = ssvRegistry.getOperatorsByValidator(poolPubKey);
    return(poolOperators, pubKeyString);
  }

  function _iToHex(bytes memory buffer) internal pure returns (string memory) {
    // Fixed buffer size for hexadecimal convertion
    bytes memory converted = new bytes(buffer.length * 2);
    bytes memory _base = "0123456789abcdef";
    for (uint256 i = 0; i < buffer.length; i++) {
        converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
        converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
    }
    return string(abi.encodePacked("0x", converted));
  }

  function getEns(address addr) public view returns(bool, string memory){
    IENS ens = IENS(getAddress(keccak256(abi.encodePacked("external.contract.address", "ENS"))));
    bytes32 node = _node(addr);
    address revResAddr = ens.resolver(node);
    if(revResAddr == address(0)) return(false,'');
    IReverseResolver reverseResolver = IReverseResolver(revResAddr);
    return(ens.recordExists(node), reverseResolver.name(node));
  }

  function _node(address addr) internal pure returns (bytes32) {
    bytes32 ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
  }

  function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
    addr;
    ret; // Stop warning us about unused variables
    assembly {
      let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

      for { let i := 40 } gt(i, 0) { } {
          i := sub(i, 1)
          mstore8(i, byte(and(addr, 0xf), lookup))
          addr := div(addr, 0x10)
          i := sub(i, 1)
          mstore8(i, byte(and(addr, 0xf), lookup))
          addr := div(addr, 0x10)
      }

      ret := keccak256(0, 40)
    }
  }

}

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        uint32 operatorId;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /** errors */
    error ExceedRegisteredOperatorsByAccountLimit();
    error OperatorDeleted();
    error ValidatorAlreadyExists();
    error ExceedValidatorLimit();
    error OperatorNotFound();
    error InvalidPublicKeyLength();
    error OessDataStructureInvalid();

    /**
     * @dev Initializes the contract
     */
    function initialize() external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint64 fee) external returns (uint32);

    /**
     * @dev removes an operator.
     * @param operatorId Operator id.
     */
    function removeOperator(uint32 operatorId) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param fee New operator fee.
     */
    function updateOperatorFee(
        uint32 operatorId,
        uint64 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param score New score.
     */
    function updateOperatorScore(
        uint32 operatorId,
        uint32 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param sharesEncrypted Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint32[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata sharesEncrypted
    ) external;

    /**
     * @dev removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isLiquidated(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator id.
     */
    function getOperatorById(uint32 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            uint256,
            uint256,
            bool
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint32[] memory);

    /**
     * @dev Gets operator's owner.
     * @param operatorId Operator id.
     */
    function getOperatorOwner(uint32 operatorId) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator id.
     */
    function getOperatorFee(uint32 operatorId)
        external view
        returns (uint64);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint32);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Get validators amount per operator.
     * @param operatorId Operator public key
     */
    function validatorsPerOperatorCount(uint32 operatorId) external view returns (uint32);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensMetaHelper {

  function getColor(address a) external pure returns(string memory);

  function getEthDecimalString(uint amountInWei) external pure returns(string memory);

  function getOperatorsForPool(address poolAddress) external view returns (uint32[] memory, string memory);

  function getEns(address addr) external view returns(bool, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IReverseResolver{

    function name(bytes32 node) external view returns(string memory);

}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFrensStorage.sol";

/// @title Base settings / modifiers for each contract in Frens Pool
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketBase contract all "Rocket" replaced with "Frens"

abstract contract FrensBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IFrensStorage frensStorage;


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Frens Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    //removed  0xWildhare
    /*
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }
    */
    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    //removed  0xWildhare
    /*
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }
    */

    /**
    * @dev Throws if called by any sender that isn't a registered Frens StakingPool
    */
    modifier onlyStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("pool.exists", _stakingPoolAddress))), "Invalid Pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == frensStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }


    





    /*** Methods **********************************************************/

    /// @dev Set the main Frens Storage address
    constructor(IFrensStorage _frensStorage) {
        // Update the contract address
        frensStorage = IFrensStorage(_frensStorage);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Frens Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return frensStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return frensStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return frensStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return frensStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return frensStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return frensStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return frensStorage.getBytes32(_key); }
    function getArray(bytes32 _key) internal view returns (uint[] memory) { return frensStorage.getArray(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { frensStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { frensStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { frensStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { frensStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { frensStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { frensStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { frensStorage.setBytes32(_key, _value); }
    function setArray(bytes32 _key, uint[] memory _value) internal { frensStorage.setArray(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { frensStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { frensStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { frensStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { frensStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { frensStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { frensStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { frensStorage.deleteBytes32(_key); }
    function deleteArray(bytes32 _key) internal { frensStorage.deleteArray(_key); }

    /// @dev Storage arithmetic methods - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) internal { frensStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { frensStorage.subUint(_key, _amount); }
    function pushUint(bytes32 _key, uint256 _amount) internal { frensStorage.pushUint(_key, _amount); }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library ToColor {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) internal pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);
    function getArray(bytes32 _key) external view returns (uint[] memory);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;
    function setArray(bytes32 _key, uint[] calldata _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
    function deleteArray(bytes32 _key) external;

    // Arithmetic (and stuff) - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    function pushUint(bytes32 _key, uint256 _amount) external;

    // Protected storage removed ~ 0xWildhare
    /*
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    */
}