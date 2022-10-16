// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../shared/NFTTypes.sol";

import "./mixins/WrapperFactoryShared.sol";
import "./mixins/WrapperFactory1155.sol";
import "./mixins/WrapperFactory721.sol";

/**
 * @title Wrap ERC-721 or ERC-1155 NFTs to enable rentals.
 * @dev Deploys a new wrapper contract for each unique NFT contract, reusing an existing one if it was already created
 * (unless the wrapped NFT implementation was since updated).
 * @author batu-inal & HardlyDifficult
 */
contract StashWrapperFactory is
  NFTTypes,
  Initializable,
  OwnableUpgradeable,
  WrapperFactoryShared,
  WrapperFactory721,
  WrapperFactory1155
{
  /**
   * @notice Assign immutable variables defined in this proxy's implementation.
   * @dev This will disable initializers in the implementation contract to avoid confusion with the proxy itself.
   */
  constructor() {
    // Prevent the implementation contract from being used directly.
    _disableInitializers();
  }

  /**
   * @notice Initialize variables in the proxy contract.
   * @dev This assigns a default owner for the contract.
   */
  function initialize() external initializer {
    // Set owner to the `msg.sender`.
    __Ownable_init();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../WrappedNFTs/interfaces/IERC4907.sol";
import "../WrappedNFTs/interfaces/IERC5006.sol";

import "../shared/SharedTypes.sol";

import "../libraries/SupportsInterfaceUnchecked.sol";

/**
 * @title A mixin for checking supported contract interfaces.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTTypes {
  using SupportsInterfaceUnchecked for address;

  /**
   * @notice Reverts if the contract is not a valid ERC-721 NFT.
   * @param requireLending If true, also revert if the NFT does not support ERC-4907.
   */
  modifier onlyERC721(address nftContract, bool requireLending) {
    require(
      nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId),
      "NFTTypes: NFT must support ERC721"
    );
    if (requireLending) {
      // Check required interfaces to list on Stash Market.
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId),
        "NFTTypes: NFT must support ERC4907"
      );
    }
    _;
  }

  /**
   * @notice Reverts if the contract is not a valid ERC-1155 NFT.
   * @param requireLending If true, also revert if the NFT does not support ERC-5006.
   */
  modifier onlyERC1155(address nftContract, bool requireLending) {
    require(
      nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId),
      "NFTTypes: NFT must support ERC1155"
    );

    if (requireLending) {
      // Check required interfaces to list on Stash Market.
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId),
        "NFTTypes: NFT must support ERC5006"
      );
    }

    _;
  }

  /**
   * @notice Checks which type of NFT the given contract is, reverting if neither ERC-721 nor ERC-1155.
   * @param requireLending If true, also revert if the NFT does not support ERC-4907 (for 721) or ERC-5006 (for 1155).
   */
  function _checkNftType(address nftContract, bool requireLending) internal view returns (NFTType nftType) {
    if (nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId)) {
      if (requireLending) {
        // Check required interfaces to list on Stash Market.
        require(
          nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId),
          "NFTTypes: NFT must support ERC4907"
        );
      }

      nftType = NFTType.ERC721;
    } else {
      require(
        nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId),
        "NFTTypes: NFT must support ERC721 or ERC1155"
      );

      if (requireLending) {
        // Check required interfaces to list on Stash Market.
        require(
          nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId),
          "NFTTypes: NFT must support ERC5006"
        );
      }

      nftType = NFTType.ERC1155;
    }
  }

  /**
   * @notice Checks whether a contract is rentable on the Stash Market.
   * @param nftContract The address of the checked contract.
   * @return isCompatible True if the NFT supports the required NFT & lending interfaces.
   */
  function _isCompatibleForRent(address nftContract) internal view returns (bool isCompatible) {
    isCompatible =
      (nftContract.supportsERC165InterfaceUnchecked(type(IERC721).interfaceId) &&
        nftContract.supportsERC165InterfaceUnchecked(type(IERC4907).interfaceId)) ||
      (nftContract.supportsERC165InterfaceUnchecked(type(IERC1155).interfaceId) &&
        nftContract.supportsERC165InterfaceUnchecked(type(IERC5006).interfaceId));
  }

  // This is a stateless contract, no upgrade-safe gap required.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IStashWrapped1155Factory.sol";

import "./WrapperFactoryShared.sol";

/**
 * @title A mixin for wrapping ERC-1155 NFTs.
 * @author batu-inal & HardlyDifficult
 */
abstract contract WrapperFactory1155 is WrapperFactoryShared {
  /**
   * @notice Wrap a specific ERC-1155 NFT tokenId to enable rentals.
   * @param nftContract The address of the original NFT contract to wrap.
   * @param tokenId The tokenId of the original NFT.
   * @param amount The amount of the original NFT to wrap. This must be set to 1 for ERC-721 NFTs.
   * @dev This will deploy a new wrapper contract for each unique NFT contract, reusing an existing one if it already
   * exists (unless the wrapped NFT implementation was since updated).
   */
  function wrapERC1155Token(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external onlyERC1155(nftContract, false) {
    address wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC1155);
    IStashWrapped1155Factory(wrappedNFTContract).factoryWrap(msg.sender, tokenId, amount);
  }

  /**
   * @notice Wrap a specific ERC-1155 NFT tokenId to enable rentals and grant approval for all on the wrapped contract
   * for the `msg.sender` (NFT owner) and the `operator` provided.
   * @param nftContract The address of the original NFT contract to wrap.
   * @param tokenId The tokenId of the original NFT.
   * @param amount The amount of the original NFT to wrap. This must be set to 1 for ERC-721 NFTs.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This will deploy a new wrapper contract for each unique NFT contract, reusing an existing one if it already
   * exists (unless the wrapped NFT implementation was since updated).
   */
  function wrapERC1155TokenAndSetApprovalForAll(
    address nftContract,
    uint256 tokenId,
    uint256 amount,
    address operator
  ) external onlyERC1155(nftContract, false) {
    address wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC1155);
    IStashWrapped1155Factory(wrappedNFTContract).factoryWrapAndSetApprovalForAll(msg.sender, tokenId, amount, operator);
  }

  /**
   * @notice Wrap an ERC-1155 NFT contract to enable rentals, if it does not already exist for the current
   * implementation version.
   * @param nftContract The address of the original NFT contract to wrap.
   * @return wrappedNFTContract The address of the wrapped NFT contract.
   * @dev This may be used before any individual tokens are wrapped, lowering the cost to do so for the first token
   * wrapped.
   */
  function wrapERC1155Contract(address nftContract)
    external
    onlyERC1155(nftContract, false)
    returns (address wrappedNFTContract)
  {
    wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC1155);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "solady/src/utils/LibClone.sol";

import "../../libraries/SupportsInterfaceUnchecked.sol";

import "../../shared/NFTTypes.sol";

/**
 * @title A mixin with shared functionality for deploying wrapped NFT contracts.
 * @author batu-inal & HardlyDifficult
 */
abstract contract WrapperFactoryShared is NFTTypes, Initializable, OwnableUpgradeable {
  using AddressUpgradeable for address;
  using LibClone for address;
  using SupportsInterfaceUnchecked for address;

  // /**
  //  * @notice The implementation address to use for wrapping ERC-721 NFTs.
  //  */
  // /**
  //  * @notice The current version number for the ERC-721 wrapper implementation.
  //  * @dev This is auto-incremented whenever the implementation is updated.
  //  * This is packed into the same slot as the `wrapped721Implementation` for gas efficiency.
  //  * It's not realistic for the version to overflow 32-bits.
  //  */

  struct WrappedImplementation {
    address implementation;
    uint32 version;
    // This slot has 64-bits of free space remaining.
  }

  mapping(NFTType => WrappedImplementation) private nftTypeToImplementation;

  /**
   * @notice Emitted when the admin upgrades a wrapped NFT implementation to use for future wraps.
   * @param implementation The new implementation address for wrapped NFTs.
   * @param nftType The type of NFTs that the new implementation supports: 0 for ERC-721, 1 for ERC-1155.
   * @param version The auto-incremented version number of the new implementation, specific to this nftType.
   */
  event ImplementationUpdated(address indexed implementation, NFTType indexed nftType, uint256 indexed version);

  /**
   * @notice Emitted when a new wrapped NFT contract is deployed.
   * @param nftContract The address of the original NFT contract.
   * @param nftType The type of this nftContract: 0 for ERC-721, 1 for ERC-1155.
   * @param wrappedNFTContract The address of the newly deployed wrapped NFT contract.
   * @param implementationVersion The implementation version number that was used to deploy this wrapped NFT.
   * @dev This occurs once for each unique NFT contract that is wrapped (unless the wrapped NFT implementation was
   * since updated).
   */
  event Wrapped(
    address indexed nftContract,
    NFTType indexed nftType,
    address indexed wrappedNFTContract,
    uint256 implementationVersion
  );

  /**
   * @notice Allows the factory owner to upgrade the implementation contract to use for wrapping NFTs.
   * @param implementation The new implementation address for either wrapped ERC-721 or ERC-1155 NFTs.
   * @dev This only impacts future wraps, existing wrapped NFTs have immutable implementations and cannot be changed.
   * The nftType is determined with ERC-165 checks on the implementation contract provided.
   */
  function ownerUpdateImplementation(address implementation) external onlyOwner {
    NFTType nftType = _checkNftType(implementation, true);
    WrappedImplementation storage wrappedImplementation = nftTypeToImplementation[nftType];
    require(
      implementation != wrappedImplementation.implementation,
      "StashWrapperFactory: Implementation is already set"
    );

    wrappedImplementation.implementation = implementation;
    uint256 wrappedVersion;
    unchecked {
      // Version will not realistically overflow 32 bits.
      wrappedVersion = ++wrappedImplementation.version;
    }
    emit ImplementationUpdated(implementation, nftType, wrappedVersion);
  }

  /**
   * @notice Wraps an NFT contract, if it does not already exist for the current implementation version.
   */
  function _wrapContract(address nftContract, NFTType nftType) internal returns (address wrappedNFTContract) {
    WrappedImplementation storage wrappedImplementation = nftTypeToImplementation[nftType];
    require(wrappedImplementation.version != 0, "StashWrapperFactory: Wrapped NFT implementation not configured");

    wrappedNFTContract = _getWrappedAddress(wrappedImplementation.implementation, nftContract);

    if (!wrappedNFTContract.isContract()) {
      // Deploy and initialize the wrapped NFT contract.
      // Salt is not required since the unique data is included in the deployed data.
      wrappedImplementation.implementation.cloneDeterministic(abi.encodePacked(nftContract), "");

      emit Wrapped(nftContract, nftType, wrappedNFTContract, wrappedImplementation.version);
    }
  }

  /**
   * @notice Get the implementation to be used for wrapping NFTs of the type provided.
   * @return implementation The implementation contract to be used for wrapping NFTs of this type.
   */
  function getImplementation(NFTType nftType) external view returns (address implementation) {
    implementation = nftTypeToImplementation[nftType].implementation;
  }

  /**
   * @notice Get the version of the implementation to be used for wrapping NFTs of the type provided.
   * @return version The version of the implementation contract to be used for wrapping NFTs of this type.
   */
  function getVersion(NFTType nftType) external view returns (uint256 version) {
    version = nftTypeToImplementation[nftType].version;
  }

  // /**
  //  * @notice Get the NFT type and wrapped contract address for an original NFT contract address.
  //  * @param nftContract The address of the original NFT contract.
  //  * @return wrappedNFTContract The address of the wrapped NFT contract, which may or may not be deployed already.
  //  */
  function predictWrappedContract(address nftContract)
    external
    view
    returns (NFTType nftType, address wrappedNFTContract)
  {
    nftType = _checkNftType(nftContract, false);
    wrappedNFTContract = _getWrappedAddress(nftTypeToImplementation[nftType].implementation, nftContract);
  }

  /**
   * @notice Gets the contract address for the wrapped NFT contract of the original NFT contract provided, which may or
   * may not be deployed already.
   */
  function _getWrappedAddress(address wrappedImplementation, address nftContract)
    internal
    view
    returns (address wrappedNFTContract)
  {
    // Compute the address of the wrapped NFT contract.
    // Salt is not required since the unique data is included in the deployed data.
    wrappedNFTContract = wrappedImplementation.predictDeterministicAddress(
      abi.encodePacked(nftContract),
      "",
      address(this)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IStashWrapped721Factory.sol";

import "./WrapperFactoryShared.sol";

/**
 * @title A mixin for wrapping ERC-721 NFTs.
 * @author batu-inal & HardlyDifficult
 */
abstract contract WrapperFactory721 is WrapperFactoryShared {
  /**
   * @notice Wrap a specific ERC-721 NFT tokenId to enable rentals.
   * @param nftContract The address of the original NFT contract to wrap.
   * @param tokenId The tokenId of the original NFT.
   * @dev This will deploy a new wrapper contract for each unique NFT contract, reusing an existing one if it already
   * exists (unless the wrapped NFT implementation was since updated).
   */
  function wrapERC721Token(address nftContract, uint256 tokenId) external onlyERC721(nftContract, false) {
    address wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC721);
    IStashWrapped721Factory(wrappedNFTContract).factoryWrap(msg.sender, tokenId);
  }

  /**
   * @notice Wrap a specific ERC-721 NFT tokenId to enable rentals and grant approval for all on the wrapped contract
   * for the `msg.sender` (NFT owner) and the `operator` provided.
   * @param nftContract The address of the original NFT contract to wrap.
   * @param tokenId The tokenId of the original NFT.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This will deploy a new wrapper contract for each unique NFT contract, reusing an existing one if it already
   * exists (unless the wrapped NFT implementation was since updated).
   */
  function wrapERC721TokenAndSetApprovalForAll(
    address nftContract,
    uint256 tokenId,
    address operator
  ) external onlyERC721(nftContract, false) {
    address wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC721);
    IStashWrapped721Factory(wrappedNFTContract).factoryWrapAndSetApprovalForAll(msg.sender, tokenId, operator);
  }

  /**
   * @notice Wrap an ERC-721 NFT contract to enable rentals, if it does not already exist for the current implementation
   * version.
   * @param nftContract The address of the original NFT contract to wrap.
   * @return wrappedNFTContract The address of the wrapped NFT contract.
   * @dev This may be used before any individual tokens are wrapped, lowering the cost to do so for the first token
   * wrapped.
   */
  function wrapERC721Contract(address nftContract)
    external
    onlyERC721(nftContract, false)
    returns (address wrappedNFTContract)
  {
    wrappedNFTContract = _wrapContract(nftContract, NFTType.ERC721);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev From github.com/OpenZeppelin/openzeppelin-contracts/blob/dc4869e
 *           /contracts/utils/introspection/ERC165Checker.sol#L107
 * TODO: Remove once OZ releases this function.
 */
library SupportsInterfaceUnchecked {
  /**
   * @notice Query if a contract implements an interface, does not check ERC165 support
   * @param account The address of the contract to query for support of an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @return true if the contract at account indicates support of the interface with
   * identifier interfaceId, false otherwise
   * @dev Assumes that account contains a contract that supports ERC165, otherwise
   * the behavior of this method is undefined. This precondition can be checked
   * with {supportsERC165}.
   * Interface identification is specified in ERC-165.
   */
  function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
    // prepare call
    bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

    // perform static call
    bool success;
    uint256 returnSize;
    uint256 returnValue;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
      returnSize := returndatasize()
      returnValue := mload(0x00)
    }

    return success && returnSize >= 0x20 && returnValue > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @notice Supported NFT types.
 */
enum NFTType {
  ERC721,
  ERC1155
}

/**
 * @notice Potential user roles supported by play rewards.
 */
enum RecipientRole {
  Player,
  Owner,
  Operator
}

/**
 * @notice Stores a recipient and their share owed for payments.
 * @param to The address to which payments should be made.
 * @param share The percent share of the payments owed to the recipient, in basis points.
 * @param role The role of the recipient in terms of why they are receiving a share of payments.
 */
struct Recipient {
  address payable to;
  uint16 shareInBasisPoints;
  RecipientRole role;
}

/**
 * @notice Details about an offer to rent or buy an NFT.
 * @param nftContract The address of the NFT contract.
 * @param tokenId The tokenId of the NFT these terms are for.
 * @param nftType The type of NFT this nftContract represents.
 * @param amount The amount of the asset being offered, if ERC-721 this is always 1 (but 0 in storage).
 * @param expiry The timestamp at which this offer expires.
 * @param pricePerDay The price per day of the offer, in wei.
 * @param lenderRevShareInBasisPoints The percent of revenue the lender should receive from play rewards, in basis
 * points. uint16 so that it cannot be set to an unreasonably high value.
 * @param buyPrice The price to buy the NFT outright, in wei -- if 0 then the NFT is not for sale.
 * @param paymentToken The address of the ERC-20 token to use for payments, or address(0) for ETH.
 * @param lender The address of the lender which set these terms.
 * @param maxRentalDays The maximum number of days this NFT can be rented for.
 * @param erc5006RecordId The ERC-5006 recordId of the NFT, if it is an ERC-1155 NFT and has already been rented.
 */
struct RentalTerms {
  // Slot 1
  address nftContract;
  // Capping pricePerDay to 96-bits to allow slot packing.
  uint96 pricePerDay;
  // 0-bits available

  // Slot 2
  uint256 tokenId;
  // Slot 3
  address paymentToken;
  // Capping pricePerDay to 96-bits to allow slot packing.
  uint96 buyPrice;
  // 0-bits available

  // Slot 4
  address lender;
  uint64 expiry;
  uint16 lenderRevShareInBasisPoints;
  uint16 maxRentalDays;
  // 0-bits available

  // Slot 5
  NFTType nftType;
  // Capping recordId to 184-bits to allow for slot packing.
  uint184 erc5006RecordId;
  // `amount` is limited to uint64 in the ERC-5006 spec.
  uint64 amount;
  // 0-bits available
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

/**
 * @title Rental NFT, ERC-721 User And Expires Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-4907
 * With more elaborate comments added.
 */
interface IERC4907 {
  /**
   * @notice Emitted when the rental terms of an NFT are set or deleted.
   * @param tokenId The NFT which is being rented.
   * @param user The user who is renting the NFT.
   * The zero address for user indicates that there is no longer any active renter of this NFT.
   * @param expiry The time at which the rental expires.
   */
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expiry);

  /**
   * @notice Defines rental terms for an NFT.
   * @param tokenId The NFT which is being rented. Throws if `tokenId` is not valid NFT.
   * @param user The user who is renting the NFT and has access to use it in game.
   * @param expiry The time at which these rental terms expire.
   * @dev Zero for `user` and `expiry` are used to delete the current rental information, which can be done by the
   * operator which set the rental terms.
   */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expiry
  ) external;

  /**
   * @notice Get the expiry time of the current rental terms for an NFT.
   * @param tokenId The NFT to get the expiry of.
   * @return expiry The time at which the rental terms expire.
   * @dev Zero indicates that there is no longer any active renter of this NFT.
   */
  function userExpires(uint256 tokenId) external view returns (uint256 expiry);

  /**
   * @notice Get the rental user of an NFT.
   * @param tokenId The NFT to get the rental user of.
   * @return user The user which is renting the NFT and has access to use it in game.
   * @dev The zero address indicates that there is no longer any active renter of this NFT.
   */
  function userOf(uint256 tokenId) external view returns (address user);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

/**
 * @title Rental NFT, NFT User Extension
 * @dev Source: https://eips.ethereum.org/EIPS/eip-5006
 * With more elaborate comments added.
 */
interface IERC5006 {
  /**
   * @notice Details about a rental.
   * @param tokenId The NFT which is being rented.
   * @param owner The owner of the NFT which was rented out.
   * @param amount The amount of the NFT which was rented to this user.
   * @param user The user who is renting the NFT.
   * @param expiry The time at which the rental expires.
   */
  struct UserRecord {
    uint256 tokenId;
    address owner;
    uint64 amount;
    address user;
    uint64 expiry;
  }

  /**
   * @notice Emitted when the rental terms of an NFT are set.
   * @param recordId A unique identifier for this rental.
   * @param tokenId The NFT which is being rented.
   * @param amount The amount of the NFT which was rented to this user.
   * @param owner The owner of the NFT which was rented out.
   * @param user The user who is renting the NFT.
   * @param expiry The time at which the rental expires.
   * @dev Emitted when permission for `user` to use `amount` of `tokenId` token owned by `owner`
   * until `expiry` are given.
   * Indexed fields are not used in order to remain consistent with the EIP.
   */
  event CreateUserRecord(uint256 recordId, uint256 tokenId, uint256 amount, address owner, address user, uint64 expiry);

  /**
   * @notice Emitted when the rental terms of an NFT are deleted.
   * @param recordId A unique identifier for the rental which was deleted.
   * @dev Indexed fields are not used in order to remain consistent with the EIP.
   * This event is not emitted for expired records.
   */
  event DeleteUserRecord(uint256 recordId);

  /**
   * @notice Creates rental terms by giving permission to `user` to use `amount` of `tokenId` token owned by `owner`
   * until `expiry`.
   * @param owner The owner of the NFT which is being rented out.
   * @param user The user who is being granted rights to use this NFT for a period of time.
   * @param tokenId The NFT which is being rented.
   * @param amount The amount of the NFT which is being rented to this user.
   * @param expiry The time at which the rental expires.
   * @return recordId A unique identifier for this rental.
   * @dev Emits a {CreateUserRecord} event.
   *
   * Requirements:
   *
   * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens
   * via {setApprovalForAll}.
   * - `owner` must have a balance of tokens of type `id` of at least `amount`.
   * - `user` cannot be the zero address.
   * - `amount` must be greater than 0.
   * - `expiry` must after the block timestamp.
   */
  function createUserRecord(
    address owner,
    address user,
    uint256 tokenId,
    uint64 amount,
    uint64 expiry
  ) external returns (uint256 recordId);

  /**
   * @notice Deletes previously assigned rental terms.
   * @param recordId The identifier of the rental terms to delete.
   */
  function deleteUserRecord(uint256 recordId) external;

  /**
   * @notice Return the total amount of a given token that this owner account has rented out.
   * @param account The owner of the NFT which is being rented out.
   * @param tokenId The NFT which is being rented.
   * @return amount The total amount of the NFT which is being rented out.
   * @dev Expired or deleted records are not included in the total.
   */
  function frozenBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount);

  /**
   * @notice Return the total amount of a given token that this user account has rented.
   * @param account The user who is renting the NFT.
   * @param tokenId The NFT which is being rented.
   * @return amount The total amount of the NFT which is being rented to this user.
   * @dev This may include rentals for this user from multiple NFT owners.
   * Expired or deleted records are not included in the total.
   */
  function usableBalanceOf(address account, uint256 tokenId) external view returns (uint256 amount);

  /**
   * @notice Returns the rental terms for a given record identifier.
   * @param recordId The identifier of the rental terms to return.
   * @return record The rental terms for the given record identifier.
   * @dev Expired or deleted records are not returned.
   */
  function userRecordOf(uint256 recordId) external view returns (UserRecord memory record);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.12;

/**
 * @title Factory interface for ERC-1155 wrapped NFTs.
 * @author batu-inal & HardlyDifficult
 */
interface IStashWrapped1155Factory {
  /**
   * @notice Wrap a specific NFT id and amount to enable rentals.
   * @param owner The account that currently owns the original NFT.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrap(
    address owner,
    uint256 id,
    uint256 amount
  ) external;

  /**
   * @notice Wrap a specific NFT id and amount to enable rentals and grant approval for all on this wrapped contract for
   * the NFT owner and the `operator` provided.
   * @param owner The account that currently owns the original NFT.
   * @param id The id of the NFT to wrap.
   * @param amount The amount of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 id,
    uint256 amount,
    address operator
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */

            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(0, 0x0c, 0x35)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(0, 0x0c, 0x35, salt)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the address of the deterministic clone of `implementation`,
    /// with `salt` by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            // prettier-ignore
            mstore(0x00, 0xff0000000000000000000000602c3d8160093d39f33d3d3d3d363d3d37363d73)
            // Compute and store the bytecode hash.
            mstore(0x35, keccak256(0x0c, 0x35))
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a minimal proxy with `implementation`,
    /// using immutable arguments encoded in `data`.
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 108`
            // The `runSize` is `creationSize - 10`.

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: if no calldata, emit event & return w/o `DELEGATECALL` ::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 60 0x2c  | PUSH1 0x2c     | 0x2c cds                 |                                             |
             * 57       | JUMPI          |                          |                                             |
             * 34       | CALLVALUE      | cv                       |                                             |
             * 3d       | RETURNDATASIZE | 0 cv                     |                                             |
             * 52       | MSTORE         |                          | [0..0x20): callvalue                        |
             * 7f sig   | PUSH32 0x9e..  | sig                      | [0..0x20): callvalue                        |
             * 59       | MSIZE          | 0x20 sig                 | [0..0x20): callvalue                        |
             * 3d       | RETURNDATASIZE | 0 0x20 sig               | [0..0x20): callvalue                        |
             * a1       | LOG1           |                          | [0..0x20): callvalue                        |
             * 00       | STOP           |                          | [0..0x20): callvalue                        |
             * 5b       | JUMPDEST       |                          |                                             |
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x62  | PUSH1 0x62     | 0x62 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x62 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x60  | PUSH1 0x60     | 0x60 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(sub(data, 0x21), or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73))
            // `keccak256("ReceiveETH(uint256)")`
            mstore(sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff)
            mstore(sub(data, 0x5a), or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f))
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create(0, sub(data, 0x4c), add(extraLength, 0x6c))

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable arguments encoded in `data`, with `salt`.
    function cloneDeterministic(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(sub(data, 0x21), or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73))
            // `keccak256("ReceiveETH(uint256)")`
            mstore(sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff)
            mstore(sub(data, 0x5a), or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f))
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x4c), add(extraLength, 0x6c), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(sub(data, 0x21), or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73))
            // `keccak256("ReceiveETH(uint256)")`
            mstore(sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff)
            mstore(sub(data, 0x5a), or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f))
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            mstore(0x35, keccak256(sub(data, 0x4c), add(extraLength, 0x6c)))
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Factory interface for ERC-721 wrapped NFTs.
 * @author batu-inal & HardlyDifficult
 */
interface IStashWrapped721Factory {
  /**
   * @notice Wrap a specific NFT tokenId to enable rentals.
   * @param owner The account that currently owns the original NFT.
   * @param tokenId The tokenId of the NFT to wrap.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrap(address owner, uint256 tokenId) external;

  /**
   * @notice Wrap a specific NFT tokenId to enable rentals and grant approval for all on this wrapped contract for the
   * NFT owner and the `operator` provided.
   * @param owner The account that currently owns the original NFT.
   * @param tokenId The tokenId of the NFT to wrap.
   * @param operator The address to grant approval for all for the NFT owner on the wrapped contract.
   * @dev This function is only callable by the contract factory, which is trusted to securely authorize the parameters
   * were provided by the `owner` specified here.
   */
  function factoryWrapAndSetApprovalForAll(
    address owner,
    uint256 tokenId,
    address operator
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/WrappedNFTs/StashWrapperFactory.sol";

contract $StashWrapperFactory is StashWrapperFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_wrapContract_Returned(address arg0);

    constructor() {}

    function $_wrapContract(address nftContract,NFTType nftType) external returns (address) {
        (address ret0) = super._wrapContract(nftContract,nftType);
        emit $_wrapContract_Returned(ret0);
        return (ret0);
    }

    function $_getWrappedAddress(address wrappedImplementation,address nftContract) external view returns (address) {
        return super._getWrappedAddress(wrappedImplementation,nftContract);
    }

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IERC4907.sol";

abstract contract $IERC4907 is IERC4907 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IERC5006.sol";

abstract contract $IERC5006 is IERC5006 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IStashWrapped1155Factory.sol";

abstract contract $IStashWrapped1155Factory is IStashWrapped1155Factory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/interfaces/IStashWrapped721Factory.sol";

abstract contract $IStashWrapped721Factory is IStashWrapped721Factory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/WrapperFactory1155.sol";

contract $WrapperFactory1155 is WrapperFactory1155 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_wrapContract_Returned(address arg0);

    constructor() {}

    function $_wrapContract(address nftContract,NFTType nftType) external returns (address) {
        (address ret0) = super._wrapContract(nftContract,nftType);
        emit $_wrapContract_Returned(ret0);
        return (ret0);
    }

    function $_getWrappedAddress(address wrappedImplementation,address nftContract) external view returns (address) {
        return super._getWrappedAddress(wrappedImplementation,nftContract);
    }

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/WrapperFactory721.sol";

contract $WrapperFactory721 is WrapperFactory721 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_wrapContract_Returned(address arg0);

    constructor() {}

    function $_wrapContract(address nftContract,NFTType nftType) external returns (address) {
        (address ret0) = super._wrapContract(nftContract,nftType);
        emit $_wrapContract_Returned(ret0);
        return (ret0);
    }

    function $_getWrappedAddress(address wrappedImplementation,address nftContract) external view returns (address) {
        return super._getWrappedAddress(wrappedImplementation,nftContract);
    }

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/WrappedNFTs/mixins/WrapperFactoryShared.sol";

contract $WrapperFactoryShared is WrapperFactoryShared {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_wrapContract_Returned(address arg0);

    constructor() {}

    function $_wrapContract(address nftContract,NFTType nftType) external returns (address) {
        (address ret0) = super._wrapContract(nftContract,nftType);
        emit $_wrapContract_Returned(ret0);
        return (ret0);
    }

    function $_getWrappedAddress(address wrappedImplementation,address nftContract) external view returns (address) {
        return super._getWrappedAddress(wrappedImplementation,nftContract);
    }

    function $__Ownable_init() external {
        return super.__Ownable_init();
    }

    function $__Ownable_init_unchained() external {
        return super.__Ownable_init_unchained();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $__Context_init() external {
        return super.__Context_init();
    }

    function $__Context_init_unchained() external {
        return super.__Context_init_unchained();
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/SupportsInterfaceUnchecked.sol";

contract $SupportsInterfaceUnchecked {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $supportsERC165InterfaceUnchecked(address account,bytes4 interfaceId) external view returns (bool) {
        return SupportsInterfaceUnchecked.supportsERC165InterfaceUnchecked(account,interfaceId);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/NFTTypes.sol";

contract $NFTTypes is NFTTypes {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_checkNftType(address nftContract,bool requireLending) external view returns (NFTType) {
        return super._checkNftType(nftContract,requireLending);
    }

    function $_isCompatibleForRent(address nftContract) external view returns (bool) {
        return super._isCompatibleForRent(nftContract);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/shared/SharedTypes.sol";