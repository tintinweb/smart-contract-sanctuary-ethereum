// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IDCNTRegistry.sol";
import "./storage/EditionConfig.sol";
import "./storage/MetadataConfig.sol";
import "./storage/CrescendoConfig.sol";

contract DCNTSDK is Ownable {
  /// ============ Immutable storage ============

  /// ============ Mutable storage ============

  /// @notice implementation addresses for base contracts
  address public DCNT721AImplementation;
  address public DCNT4907AImplementation;
  address public DCNTCrescendoImplementation;
  address public DCNTVaultImplementation;
  address public DCNTStakingImplementation;

  /// @notice address of the metadata renderer
  address public metadataRenderer;

  /// @notice address of the associated registry
  address public contractRegistry;

  /// @notice addresses for splits contract
  address public SplitMain;

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event DeployDCNT721A(address DCNT721A);
  event DeployDCNT4907A(address DCNT4907A);
  event DeployDCNTCrescendo(address DCNTCrescendo);
  event DeployDCNTVault(address DCNTVault);
  event DeployDCNTStaking(address DCNTStaking);

  /// ============ Constructor ============

  /// @notice Creates a new DecentSDK instance
  constructor(
    address _DCNT721AImplementation,
    address _DCNT4907AImplementation,
    address _DCNTCrescendoImplementation,
    address _DCNTVaultImplementation,
    address _DCNTStakingImplementation,
    address _metadataRenderer,
    address _contractRegistry,
    address _SplitMain
  ) {
    DCNT721AImplementation = _DCNT721AImplementation;
    DCNT4907AImplementation = _DCNT4907AImplementation;
    DCNTCrescendoImplementation = _DCNTCrescendoImplementation;
    DCNTVaultImplementation = _DCNTVaultImplementation;
    DCNTStakingImplementation = _DCNTStakingImplementation;
    metadataRenderer = _metadataRenderer;
    contractRegistry = _contractRegistry;
    SplitMain = _SplitMain;
  }

  /// ============ Functions ============

  // deploy and initialize an erc721a clone
  function deployDCNT721A(
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT721AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,uint256,uint256,uint256,uint256),"
          "(string,bytes),"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT721A");
    emit DeployDCNT721A(clone);
  }

  // deploy and initialize an erc4907a clone
  function deployDCNT4907A(
    EditionConfig memory _editionConfig,
    MetadataConfig memory _metadataConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNT4907AImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,uint256,uint256,uint256,uint256),"
          "(string,bytes),"
          "address,"
          "address"
        ")",
        msg.sender,
        _editionConfig,
        _metadataConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNT4907A");
    emit DeployDCNT4907A(clone);
  }

  // deploy and initialize a Crescendo clone
  function deployDCNTCrescendo(
    CrescendoConfig memory _config,
    MetadataConfig memory _metadataConfig
  ) external returns (address clone) {
    clone = Clones.clone(DCNTCrescendoImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize("
          "address,"
          "(string,string,uint256,uint256,uint256,uint256,uint256,uint256,uint256),"
          "(string,bytes),"
          "address,"
          "address"
        ")",
        msg.sender,
        _config,
        _metadataConfig,
        metadataRenderer,
        SplitMain
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(
      msg.sender,
      clone,
      "DCNTCrescendo"
    );
    emit DeployDCNTCrescendo(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone) {
    clone = Clones.clone(DCNTVaultImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _vaultDistributionTokenAddress,
        _nftVaultKeyAddress,
        _nftTotalSupply,
        _unlockDate
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTVault");
    emit DeployDCNTVault(clone);
  }

  // deploy and initialize a vault wrapper clone
  function deployDCNTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone) {
    clone = Clones.clone(DCNTStakingImplementation);
    (bool success, ) = clone.call(
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
        msg.sender,
        _nft,
        _token,
        _vaultDuration,
        _totalSupply
      )
    );
    require(success);
    IDCNTRegistry(contractRegistry).register(msg.sender, clone, "DCNTStaking");
    emit DeployDCNTStaking(clone);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

interface IDCNTRegistry {
  function register(
    address _deployer,
    address _deployment,
    string calldata _key
  ) external;

  function remove(address _deployer, address _deployment) external;

  function query(address _deployer) external returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  uint256 maxTokens;
  uint256 tokenPrice;
  uint256 maxTokenPurchase;
  uint256 royaltyBPS;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct MetadataConfig {
  string metadataURI;
  bytes metadataRendererInit;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct CrescendoConfig {
  string name;
  string symbol;
  uint256 initialPrice;
  uint256 step1;
  uint256 step2;
  uint256 hitch;
  uint256 takeRateBPS;
  uint256 unlockDate;
  uint256 royaltyBPS;
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