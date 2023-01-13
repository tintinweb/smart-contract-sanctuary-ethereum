// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IBNFT.sol";
import "./ILendPoolAddressesProvider.sol";
import "./ILendPoolLoan.sol";
import "./IStakeManager.sol";

import "./IUserFlashclaimRegistryV3.sol";

import "./AirdropFlashLoanReceiverV3.sol";

contract UserFlashclaimRegistryV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable, IUserFlashclaimRegistryV3 {
  using ClonesUpgradeable for address;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  uint256 public constant VERSION = 3;

  address public bnftRegistry;
  mapping(address => address) public userReceiversV3;
  mapping(address => bool) public allReceiversV3;
  address public receiverV3Implemention;
  mapping(address => EnumerableSetUpgradeable.AddressSet) private _airdropContractWhiteList;
  address public addressProvider;
  address public stakeManager;

  event ReceiverV3ImplementionUpdated(address indexed receiverV3Implemention);
  event AirdropContractWhiteListChanged(address indexed nftAsset, address indexed airdropContract, bool flag);
  event ReceiverCreated(address indexed user, address indexed receiver, uint256 version);

  function initialize(
    address bnftRegistry_,
    address addressProvider_,
    address stakeManager_,
    address receiverV3Implemention_
  ) public initializer {
    __Ownable_init();

    bnftRegistry = bnftRegistry_;
    addressProvider = addressProvider_;
    stakeManager = stakeManager_;

    receiverV3Implemention = receiverV3Implemention_;
  }

  function setReceiverV3Implemention(address receiverV3Implemention_) public onlyOwner {
    receiverV3Implemention = receiverV3Implemention_;

    emit ReceiverV3ImplementionUpdated(receiverV3Implemention_);
  }

  function setAirdropContractWhiteList(
    address nftAsset,
    address airdropContract,
    bool flag
  ) public onlyOwner {
    if (flag) {
      _airdropContractWhiteList[nftAsset].add(airdropContract);
    } else {
      _airdropContractWhiteList[nftAsset].remove(airdropContract);
    }

    emit AirdropContractWhiteListChanged(nftAsset, airdropContract, flag);
  }

  /**
   * @dev Allows user create receiver.
   *
   * Requirements:
   *  - Receiver not exist for the `caller`.
   *
   */
  function createReceiver() public override nonReentrant {
    require(userReceiversV3[msg.sender] == address(0), "user already has a receiver");
    _createReceiver();
  }

  /**
   * @dev Allows user receiver to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param nftAsset The address of the underlying asset
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public override nonReentrant {
    address lendPoolLoan = ILendPoolAddressesProvider(addressProvider).getLendPoolLoan();

    (address bnftProxy, ) = IBNFTRegistry(bnftRegistry).getBNFTAddresses(nftAsset);
    require(bnftProxy != address(0), "invalid nft asset");

    address receiverAddress = getUserReceiver(msg.sender);
    require(receiverAddress != address(0), "empty user receiver");

    // check airdrop contract MUST in the whitelist
    _checkValidAirdropContract(nftAsset, params);

    // check owner and set locking flag
    for (uint256 i = 0; i < nftTokenIds.length; i++) {
      require(IERC721Upgradeable(bnftProxy).ownerOf(nftTokenIds[i]) == msg.sender, "invalid token owner");

      address minterAddr = IBNFT(bnftProxy).minterOf(nftTokenIds[i]);
      address[] memory lockers = IBNFT(bnftProxy).getFlashLoanLocked(nftTokenIds[i], minterAddr);
      require(lockers.length > 0, "flash loan not locked");

      if (minterAddr == lendPoolLoan) {
        ILendPoolLoan(lendPoolLoan).setFlashLoanLocking(nftAsset, nftTokenIds[i], true);
      } else if (minterAddr == stakeManager) {
        IStakeManager(stakeManager).setFlashLoanLocking(nftAsset, nftTokenIds[i], true);
      }
    }

    // doing flash loan
    IBNFT(bnftProxy).flashLoan(receiverAddress, nftTokenIds, params);

    // clear locking flag
    for (uint256 i = 0; i < nftTokenIds.length; i++) {
      address minterAddr = IBNFT(bnftProxy).minterOf(nftTokenIds[i]);
      if (minterAddr == lendPoolLoan) {
        ILendPoolLoan(lendPoolLoan).setFlashLoanLocking(nftAsset, nftTokenIds[i], false);
      } else if (minterAddr == stakeManager) {
        IStakeManager(stakeManager).setFlashLoanLocking(nftAsset, nftTokenIds[i], false);
      }
    }
  }

  /**
   * @dev Query user receiver, only compatable with v2.
   */
  function userReceivers(address user) public view returns (address) {
    return getUserReceiver(user);
  }

  /**
   * @dev Query user receiver, current in used.
   */
  function getUserReceiver(address user) public view override returns (address) {
    return userReceiversV3[user];
  }

  /**
   * @dev Query user receiver, latest version.
   */
  function getUserReceiverLatestVersion(address user) public view override returns (uint256, address) {
    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      return (VERSION, receiverV3);
    }

    return (0, address(0));
  }

  /**
   * @dev Query user receiver, all versions.
   */
  function getUserReceiverAllVersions(address user) public view override returns (uint256[] memory, address[] memory) {
    uint256 length;
    uint256[3] memory versions;
    address[3] memory addresses;

    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      versions[length] = VERSION;
      addresses[length] = receiverV3;
      length++;
    }

    uint256[] memory retVersions = new uint256[](length);
    address[] memory retAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      retVersions[i] = versions[i];
      retAddresses[i] = addresses[i];
    }

    return (retVersions, retAddresses);
  }

  function isAirdropContractInWhiteList(address nftAsset, address airdropContract) public view returns (bool) {
    return _airdropContractWhiteList[nftAsset].contains(airdropContract);
  }

  function _createReceiver() internal {
    address payable receiverV3 = payable(receiverV3Implemention.clone());
    AirdropFlashLoanReceiverV3(receiverV3).initialize(msg.sender, bnftRegistry);

    userReceiversV3[msg.sender] = address(receiverV3);
    allReceiversV3[receiverV3] = true;

    emit ReceiverCreated(msg.sender, address(receiverV3), VERSION);
  }

  function _checkValidAirdropContract(address nftAsset, bytes calldata params) internal view {
    // decode parameters
    (, , , address airdropContract, , ) = abi.decode(
      params,
      (uint256[], address[], uint256[], address, bytes, uint256)
    );
    require(isAirdropContractInWhiteList(nftAsset, airdropContract) == true, "invalid airdrop contract");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFT {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset_ The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset_);

  /**
   * @dev Emitted when the ownership is transferred
   * @param oldOwner The address of the old owner
   * @param newOwner The address of the new owner
   **/
  event OwnershipTransferred(address oldOwner, address newOwner);

  /**
   * @dev Emitted when the claim admin is updated
   * @param oldAdmin The address of the old admin
   * @param newAdmin The address of the new admin
   **/
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

  event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

  event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

  event ExecuteAirdrop(address indexed airdropContract);

  event FlashLoanApproval(address indexed minter, address indexed operator, bool approved);

  event FlashLoanLocking(uint256 tokenId, address indexed minter, address indexed operator, bool approved);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset_ The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset_,
    string calldata bNftName,
    string calldata bNftSymbol,
    address owner_,
    address claimAdmin_
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  /**
   * @dev Approve or remove the flash loan `operator` as an operator for the minter.
   * Operators can call {flashLoan} for any token minted by the minter.
   *
   */
  function setFlashLoanApproval(address operator, bool approved) external;

  /**
   * @dev Returns if the `operator` is allowed to call flash loan of the assets of `minter`.
   */
  function isFlashLoanApproved(address minter, address operator) external view returns (bool);

  /**
   * @dev Lock or unlock the flash loan `operator` as an operator for the minter.
   * Operators can call {flashLoan} for any token minted by the minter.
   *
   */
  function setFlashLoanLocking(
    uint256 tokenId,
    address operator,
    bool locked
  ) external;

  /**
   * @dev Returns if the `operator` is allowed to call flash loan of the assets of `minter`.
   */
  function isFlashLoanLocked(
    uint256 tokenId,
    address minter,
    address operator
  ) external view returns (bool);

  function getFlashLoanLocked(uint256 tokenId, address minter) external view returns (address[] memory);

  function claimERC20Airdrop(
    address token,
    address to,
    uint256 amount
  ) external;

  function claimERC721Airdrop(
    address token,
    address to,
    uint256[] calldata ids
  ) external;

  function claimERC1155Airdrop(
    address token,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  function executeAirdrop(address airdropContract, bytes calldata airdropParams) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);

  /**
   * @dev Returns the address of the underlying asset.
   */
  function underlyingAsset() external view returns (address);

  /**
   * @dev Returns the contract-level metadata.
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolAddressesProvider {
  function getLendPoolLoan() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolLoan {
  function setFlashLoanLocking(
    address nftAsset,
    uint256 tokenId,
    bool locked
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IStakeManager {
  function setFlashLoanLocking(
    address nftAsset,
    uint256 tokenId,
    bool locked
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IUserFlashclaimRegistryV3 {
  function createReceiver() external;

  function flashLoan(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  function getUserReceiver(address user) external view returns (address);

  function getUserReceiverLatestVersion(address user) external view returns (uint256, address);

  function getUserReceiverAllVersions(address user) external view returns (uint256[] memory, address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/IBNFT.sol";
import "../interfaces/IBNFTRegistry.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

/**
 * @title Airdrop receiver contract and implement IFlashLoanReceiver interface
 * @author BendDAO
 * @dev implement a flashloan-compatible flashLoanReceiver contract
 **/
contract AirdropFlashLoanReceiverV3 is
  IFlashLoanReceiver,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  address public bnftRegistry;
  mapping(bytes32 => bool) public airdropClaimRecords;
  uint256 public constant VERSION = 3;

  event ApproveERC20(address indexed token, address indexed spender, uint256 amount);
  event ApproveERC721(address indexed token, address indexed operator, uint256 amount);
  event ApproveERC721ForAll(address indexed token, address indexed operator, bool approved);
  event ApproveERC1155ForAll(address indexed token, address indexed operator, bool approved);

  function initialize(address owner_, address bnftRegistry_) public initializer {
    __ReentrancyGuard_init();
    __Ownable_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    require(owner_ != address(0), "zero owner address");
    require(bnftRegistry_ != address(0), "zero registry address");

    bnftRegistry = bnftRegistry_;

    _transferOwnership(owner_);
  }

  struct ExecuteOperationLocalVars {
    uint256[] airdropTokenTypes;
    address[] airdropTokenAddresses;
    uint256[] airdropTokenIds;
    address airdropContract;
    bytes airdropParams;
    uint256 airdropBalance;
    uint256 airdropTokenId;
    bytes32 airdropKeyHash;
    uint256 ethValue;
  }

  /**
   * @dev Implement the flash loan receiver interface of boundNFT
   * @param nftAsset address of original NFT contract
   * @param nftTokenIds id list of original NFT token
   * @param initiator address of original msg sender (caller)
   * @param operator address of bound NFT contract
   * @param params parameters to call third party contract
   */
  function executeOperation(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    address initiator,
    address operator,
    bytes calldata params
  ) external override returns (bool) {
    initiator;

    ExecuteOperationLocalVars memory vars;
    address targetOwner = owner();

    // check caller and owner
    (address bnftProxy, ) = IBNFTRegistry(bnftRegistry).getBNFTAddresses(nftAsset);
    require(bnftProxy == msg.sender, "caller not bnft");

    require(nftTokenIds.length > 0, "empty token list");

    // decode parameters
    (
      vars.airdropTokenTypes,
      vars.airdropTokenAddresses,
      vars.airdropTokenIds,
      vars.airdropContract,
      vars.airdropParams,
      vars.ethValue
    ) = abi.decode(params, (uint256[], address[], uint256[], address, bytes, uint256));

    // airdrop token list can be empty, no need transfer immediately after call method
    // require(vars.airdropTokenTypes.length > 0, "invalid airdrop token type");
    require(vars.airdropTokenAddresses.length == vars.airdropTokenTypes.length, "invalid airdrop token address length");
    require(vars.airdropTokenIds.length == vars.airdropTokenTypes.length, "invalid airdrop token id length");

    require(vars.airdropContract != address(0), "invalid airdrop contract address");
    require(vars.airdropParams.length >= 4, "invalid airdrop parameters");

    // allow operator transfer borrowed nfts back to bnft
    for (uint256 idIdx = 0; idIdx < nftTokenIds.length; idIdx++) {
      IERC721Upgradeable(nftAsset).approve(operator, nftTokenIds[idIdx]);
    }

    // call project aidrop contract
    AddressUpgradeable.functionCallWithValue(
      vars.airdropContract,
      vars.airdropParams,
      vars.ethValue,
      "call airdrop method failed"
    );

    vars.airdropKeyHash = getClaimKeyHash(targetOwner, nftAsset, nftTokenIds, params);
    airdropClaimRecords[vars.airdropKeyHash] = true;

    // transfer airdrop tokens to borrower
    for (uint256 typeIndex = 0; typeIndex < vars.airdropTokenTypes.length; typeIndex++) {
      require(vars.airdropTokenAddresses[typeIndex] != address(0), "invalid airdrop token address");

      if (vars.airdropTokenTypes[typeIndex] == 1) {
        // ERC20
        vars.airdropBalance = IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        if (vars.airdropBalance > 0) {
          IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).transfer(targetOwner, vars.airdropBalance);
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 2) {
        // ERC721 with Enumerate
        vars.airdropBalance = IERC721Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        for (uint256 i = 0; i < vars.airdropBalance; i++) {
          vars.airdropTokenId = IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).tokenOfOwnerByIndex(
            address(this),
            0
          );
          IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
            address(this),
            targetOwner,
            vars.airdropTokenId
          );
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 3) {
        // ERC1155
        vars.airdropBalance = IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(
          address(this),
          vars.airdropTokenIds[typeIndex]
        );
        IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          targetOwner,
          vars.airdropTokenIds[typeIndex],
          vars.airdropBalance,
          new bytes(0)
        );
      } else if (vars.airdropTokenTypes[typeIndex] == 4) {
        // ERC721 without Enumerate but can know the droped token id
        IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          targetOwner,
          vars.airdropTokenIds[typeIndex]
        );
      } else if (vars.airdropTokenTypes[typeIndex] == 5) {
        // ERC721 without Enumerate and can not know the droped token id
      }
    }

    return true;
  }

  /**
   * @dev call third party contract method, etc. staking, claim...
   * @param targetContract address of target contract
   * @param callParams parameters to call target contract
   */
  function callMethod(
    address targetContract,
    bytes calldata callParams,
    uint256 ethValue
  ) external payable nonReentrant onlyOwner {
    require(targetContract != address(0), "invalid contract address");
    require(callParams.length >= 4, "invalid call parameters");

    require(address(this).balance >= ethValue, "insufficient eth");

    // call project claim contract
    AddressUpgradeable.functionCallWithValue(targetContract, callParams, ethValue, "call method failed");
  }

  function approveERC20(
    address token,
    address spender,
    uint256 amount
  ) external nonReentrant onlyOwner {
    IERC20Upgradeable(token).approve(spender, amount);
    emit ApproveERC20(token, spender, amount);
  }

  /**
   * @dev transfer ERC20 token from contract to owner
   * @param token address of ERC20 token
   * @param amount amount to send
   */
  function transferERC20(address token, uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
    IERC20Upgradeable(token).transfer(to, amount);
  }

  function approveERC721(
    address token,
    address operator,
    uint256 tokenId
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).approve(operator, tokenId);
    emit ApproveERC721(token, operator, tokenId);
  }

  function approveERC721ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).setApprovalForAll(operator, approved);
    emit ApproveERC721ForAll(token, operator, approved);
  }

  /**
   * @dev transfer ERC721 token from contract to owner
   * @param token address of ERC721 token
   * @param id token item to send
   */
  function transferERC721(address token, uint256 id) external nonReentrant onlyOwner {
    address to = owner();
    IERC721Upgradeable(token).safeTransferFrom(address(this), to, id);
  }

  function approveERC1155ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC1155Upgradeable(token).setApprovalForAll(operator, approved);
    emit ApproveERC1155ForAll(token, operator, approved);
  }

  /**
   * @dev transfer ERC1155 token from contract to owner
   * @param token address of ERC1155 token
   * @param id token item to send
   * @param amount amount to send
   */
  function transferERC1155(
    address token,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyOwner {
    address to = owner();
    IERC1155Upgradeable(token).safeTransferFrom(address(this), to, id, amount, new bytes(0));
  }

  /**
   * @dev transfer native Ether from contract to owner
   * @param amount amount to send
   */
  function transferEther(uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  /**
   * @dev query claim record
   */
  function getAirdropClaimRecord(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public view returns (bool) {
    bytes32 airdropKeyHash = getClaimKeyHash(initiator, nftAsset, nftTokenIds, params);
    return airdropClaimRecords[airdropKeyHash];
  }

  /**
   * @dev encode flash claim parameters
   */
  function encodeFlashLoanParams(
    uint256[] calldata airdropTokenTypes,
    address[] calldata airdropTokenAddresses,
    uint256[] calldata airdropTokenIds,
    address airdropContract,
    bytes calldata airdropParams,
    uint256 ethValue
  ) public pure returns (bytes memory) {
    return
      abi.encode(airdropTokenTypes, airdropTokenAddresses, airdropTokenIds, airdropContract, airdropParams, ethValue);
  }

  /**
   * @dev query claim key hash
   */
  function getClaimKeyHash(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(initiator, nftAsset, nftTokenIds, params));
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the IFlashLoanReceiver.
 * @author BEND
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address asset,
    uint256[] calldata tokenIds,
    address initiator,
    address operator,
    bytes calldata params
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event BNFTCreated(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event BNFTUpgraded(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event CustomeSymbolsAdded(address[] nftAssets, string[] symbols);
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  function getBNFTAddresses(address nftAsset) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAddressesByIndex(uint16 index) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAssetList() external view returns (address[] memory);

  function allBNFTAssetLength() external view returns (uint256);

  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  function setBNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create bNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   **/
  function createBNFT(address nftAsset) external returns (address bNftProxy);

  /**
   * @dev Create bNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   **/
  function createBNFTWithImpl(address nftAsset, address bNftImpl) external returns (address bNftProxy);

  /**
   * @dev Update bNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeBNFTWithImpl(
    address nftAsset,
    address bNftImpl,
    bytes memory encodedCallData
  ) external;

  function batchUpgradeBNFT(address[] calldata nftAssets) external;

  function batchUpgradeAllBNFT() external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}