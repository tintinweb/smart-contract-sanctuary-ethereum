/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/internal/INFTDropCollectionInitializer.sol";
import "./interfaces/internal/INFTCollectionInitializer.sol";
import "./interfaces/internal/roles/IHasRolesContract.sol";
import "./interfaces/internal/roles/IRoles.sol";

import "./libraries/AddressLibrary.sol";
import "./mixins/shared/Gap10000.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create NFT collections.
 * @dev This creates and initializes an ERC-1167 minimal proxy pointing to an NFT collection contract implementation.
 * @author batu-inal & HardlyDifficult
 */
contract NFTCollectionFactory is IHasRolesContract, Initializable, Gap10000 {
  using AddressUpgradeable for address;
  using Clones for address;
  using Strings for uint32;

  /****** Slot 0 (after inheritance) ******/
  /**
   * @notice The address of the implementation all new NFTCollections will leverage.
   * @dev When this is changed, `versionNFTCollection` is incremented.
   * @return The implementation address for NFTCollection.
   */
  address public implementationNFTCollection;

  /**
   * @notice The implementation version of new NFTCollections.
   * @dev This is auto-incremented each time `implementationNFTCollection` is changed.
   * @return The current NFTCollection implementation version.
   */
  uint32 public versionNFTCollection;

  /****** Slot 1 ******/
  /**
   * @notice The address of the implementation all new NFTDropCollections will leverage.
   * @dev When this is changed, `versionNFTDropCollection` is incremented.
   * @return The implementation address for NFTDropCollection.
   */
  address public implementationNFTDropCollection;

  /**
   * @notice The implementation version of new NFTDropCollections.
   * @dev This is auto-incremented each time `implementationNFTDropCollection` is changed.
   * @return The current NFTDropCollection implementation version.
   */
  uint32 public versionNFTDropCollection;

  /****** End of storage ******/

  /**
   * @notice The contract address which manages common roles.
   * @dev Defines a centralized admin role definition for permissioned functions below.
   * @return The contract address with role definitions.
   */
  IRoles public immutable rolesManager;

  /**
   * @notice Emitted when the implementation of NFTCollection used by new collections is updated.
   * @param implementation The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationNFTCollectionUpdated(address indexed implementation, uint256 indexed version);

  /**
   * @notice Emitted when the implementation of NFTDropCollection used by new collections is updated.
   * @param implementationNFTDropCollection The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationNFTDropCollectionUpdated(
    address indexed implementationNFTDropCollection,
    uint256 indexed version
  );

  /**
   * @notice Emitted when a new NFTCollection is created from this factory.
   * @param collection The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event NFTCollectionCreated(
    address indexed collection,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );

  /**
   * @notice Emitted when a new NFTDropCollection is created from this factory.
   * @param collection The address of the new NFT drop collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max `tokenID` for this collection.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @param version The implementation version used by the new NFTDropCollection collection.
   * @param nonce The nonce used by the creator to create this collection.
   */
  event NFTDropCollectionCreated(
    address indexed collection,
    address indexed creator,
    address indexed approvedMinter,
    string name,
    string symbol,
    string baseURI,
    bool isRevealed,
    uint256 maxTokenId,
    address paymentAddress,
    uint256 version,
    uint256 nonce
  );

  modifier onlyAdmin() {
    require(rolesManager.isAdmin(msg.sender), "NFTCollectionFactory: Caller does not have the Admin role");
    _;
  }

  modifier onlyContract(address _implementation) {
    require(_implementation.isContract(), "NFTCollectionFactory: Implementation is not a contract");
    _;
  }

  /**
   * @notice Defines requirements for the collection drop factory at deployment time.
   * @param _rolesManager The address of the contract defining roles for collections to use.
   */
  constructor(address _rolesManager) initializer {
    require(_rolesManager.isContract(), "NFTCollectionFactory: RolesContract is not a contract");

    rolesManager = IRoles(_rolesManager);
  }

  /**
   * @notice Initializer called after contract creation.
   * @dev This is used so that this factory will resume versions from where our original factory had left off.
   * @param _versionNFTCollection The current implementation version for NFTCollections.
   */
  function initialize(uint32 _versionNFTCollection) external initializer {
    versionNFTCollection = _versionNFTCollection;
  }

  /**
   * @notice Allows Foundation to change the NFTCollection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new NFTCollection collection implementation address.
   */
  function adminUpdateNFTCollectionImplementation(address _implementation)
    external
    onlyAdmin
    onlyContract(_implementation)
  {
    implementationNFTCollection = _implementation;
    // Version will not realistically overflow 32 bits.
    ++versionNFTCollection;

    // The implementation is initialized when assigned so that others may not claim it as their own.
    INFTCollectionInitializer(_implementation).initialize(
      payable(address(rolesManager)),
      string.concat("NFT Collection Implementation v", versionNFTCollection.toString()),
      string.concat("NFTv", versionNFTCollection.toString())
    );

    emit ImplementationNFTCollectionUpdated(_implementation, versionNFTCollection);
  }

  /**
   * @notice Allows Foundation to change the NFTDropCollection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new NFTDropCollection collection implementation address.
   */
  function adminUpdateNFTDropCollectionImplementation(address _implementation)
    external
    onlyAdmin
    onlyContract(_implementation)
  {
    implementationNFTDropCollection = _implementation;
    // Version will not realistically overflow 32 bits.
    ++versionNFTDropCollection;

    // The implementation is initialized when assigned so that others may not claim it as their own.
    INFTDropCollectionInitializer(_implementation).initialize(
      payable(address(this)),
      string.concat("NFT Drop Collection Implementation v", versionNFTDropCollection.toString()),
      string.concat("NFTDropV", versionNFTDropCollection.toString()),
      "ipfs://QmUtCsULTpfUYWBfcUS1y25rqBZ6E5CfKzZg6j9P3gFScK/",
      true,
      1,
      address(0),
      payable(0)
    );

    emit ImplementationNFTDropCollectionUpdated(_implementation, versionNFTDropCollection);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTCollection(
    string calldata name,
    string calldata symbol,
    uint96 nonce
  ) external returns (address collection) {
    require(bytes(symbol).length != 0, "NFTCollectionFactory: Symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collection = implementationNFTCollection.cloneDeterministic(_getSalt(msg.sender, nonce));

    INFTCollectionInitializer(collection).initialize(payable(msg.sender), name, symbol);

    emit NFTCollectionCreated(collection, msg.sender, versionNFTCollection, name, symbol, nonce);
  }

  /**
   * @notice Create a new drop collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollection(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      name,
      symbol,
      baseURI,
      isRevealed,
      maxTokenId,
      approvedMinter,
      payable(0),
      nonce
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address.
   * @dev All params other than `paymentAddress` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentAddress(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    address payable paymentAddress
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      name,
      symbol,
      baseURI,
      isRevealed,
      maxTokenId,
      approvedMinter,
      paymentAddress != msg.sender ? paymentAddress : payable(0),
      nonce
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address derived from the factory.
   * @dev All params other than `paymentAddressFactoryCall` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      name,
      symbol,
      baseURI,
      isRevealed,
      maxTokenId,
      approvedMinter,
      AddressLibrary.callAndReturnContractAddress(paymentAddressFactoryCall),
      nonce
    );
  }

  function _createNFTDropCollection(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    address payable paymentAddress,
    uint96 nonce
  ) private returns (address collection) {
    require(bytes(symbol).length > 0, "NFTCollectionFactory: Symbol is required");
    require(maxTokenId > 0, "NFTCollectionFactory: maxTokenId is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collection = implementationNFTDropCollection.cloneDeterministic(_getSalt(msg.sender, nonce));

    INFTDropCollectionInitializer(collection).initialize(
      payable(msg.sender),
      name,
      symbol,
      baseURI,
      isRevealed,
      maxTokenId,
      approvedMinter,
      paymentAddress
    );

    emit NFTDropCollectionCreated(
      collection,
      msg.sender,
      approvedMinter,
      name,
      symbol,
      baseURI,
      isRevealed,
      maxTokenId,
      paymentAddress,
      versionNFTDropCollection,
      nonce
    );
  }

  /**
   * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   */
  function predictNFTCollectionAddress(address creator, uint96 nonce) external view returns (address collection) {
    collection = implementationNFTCollection.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  /**
   * @notice Returns the address of an NFTDropCollection collection given the current
   * implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   */
  function predictNFTDropCollectionAddress(address creator, uint96 nonce) external view returns (address collection) {
    collection = implementationNFTDropCollection.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  /**
   * @dev Salt is address + nonce packed.
   */
  function _getSalt(address creator, uint96 nonce) private pure returns (bytes32) {
    return bytes32((uint256(uint160(creator)) << 96) | uint256(nonce));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

struct CallWithoutValue {
  address target;
  bytes callData;
}

/**
 * @title A library for address helpers not already covered by the OZ library.
 * @author batu-inal & HardlyDifficult
 */
library AddressLibrary {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Calls an external contract with arbitrary data and parse the return value into an address.
   * @param externalContract The address of the contract to call.
   * @param callData The data to send to the contract.
   * @return contractAddress The address of the contract returned by the call.
   */
  function callAndReturnContractAddress(address externalContract, bytes calldata callData)
    internal
    returns (address payable contractAddress)
  {
    bytes memory returnData = externalContract.functionCall(callData);
    contractAddress = abi.decode(returnData, (address));
    require(contractAddress.isContract(), "InternalProxyCall: did not return a contract");
  }

  function callAndReturnContractAddress(CallWithoutValue calldata call)
    internal
    returns (address payable contractAddress)
  {
    contractAddress = callAndReturnContractAddress(call.target, call.callData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @author batu-inal & HardlyDifficult
 */
interface INFTDropCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata _baseURI,
    bool isRevealed,
    uint32 _maxTokenId,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @author batu-inal & HardlyDifficult
 */
interface INFTCollectionInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract leaving room for new mixins to be added to the future.
 * @author batu-inal & HardlyDifficult
 */
abstract contract Gap10000 {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[10_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./IRoles.sol";

/**
 * @author batu-inal & HardlyDifficult
 */
interface IHasRolesContract {
  function rolesManager() external returns (IRoles);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for a contract which implements admin roles.
 * @author batu-inal & HardlyDifficult
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/NFTCollectionFactory.sol";

contract $NFTCollectionFactory is NFTCollectionFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _rolesManager) NFTCollectionFactory(_rolesManager) {}

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/internal/INFTCollectionInitializer.sol";

abstract contract $INFTCollectionInitializer is INFTCollectionInitializer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/internal/INFTDropCollectionInitializer.sol";

abstract contract $INFTDropCollectionInitializer is INFTDropCollectionInitializer {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/roles/IHasRolesContract.sol";

abstract contract $IHasRolesContract is IHasRolesContract {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/internal/roles/IRoles.sol";

abstract contract $IRoles is IRoles {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/AddressLibrary.sol";

contract $AddressLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $callAndReturnContractAddress_address_bytes_Returned(address payable arg0);

    event $callAndReturnContractAddress_CallWithoutValue_Returned(address payable arg0);

    constructor() {}

    function $callAndReturnContractAddress(address externalContract,bytes calldata callData) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(externalContract,callData);
        emit $callAndReturnContractAddress_address_bytes_Returned(ret0);
        return (ret0);
    }

    function $callAndReturnContractAddress(CallWithoutValue calldata call) external payable returns (address payable) {
        (address payable ret0) = AddressLibrary.callAndReturnContractAddress(call);
        emit $callAndReturnContractAddress_CallWithoutValue_Returned(ret0);
        return (ret0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/mixins/shared/Gap10000.sol";

contract $Gap10000 is Gap10000 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}