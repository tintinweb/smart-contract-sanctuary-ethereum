// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/VoviLibrary.sol";
import "../libraries/LibVoviStorage.sol";
import "../libraries/LibReentrancyGuard.sol";
import "../libraries/LibPausable.sol";

contract VoviTokenStakerV1 {
  using EnumerableSet for EnumerableSet.UintSet;
  using VoviLibrary for *;
  using LibVoviStorage for *;
  using LibReentrancyGuard for *;
  using LibPausable for *;

  modifier whenNotPaused() {
    LibPausable.enforceNotPaused();
    _;
  }

  modifier nonReentrant() {
    LibReentrancyGuard.nonReentrant();
    _;
    LibReentrancyGuard.completeNonReentrant();
  }

  modifier includedWallet(IVoviWallets.Link[] memory links) {
    bool found = false;
    for (uint256 i = 0; i < links.length; i++) {
      if (links[i].signer == msg.sender) {
        found = true;
        break;
      }
    }
    require(found, "Wallet links do not include sender");
    _;
  }

  /// @dev check that the coupon sent was signed by the admin signer
  function _isVerifiedCoupon(bytes32 digest, LibVoviStorage.Coupon memory coupon, address _adminSigner)
    internal
    pure
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), 'ECDSA: invalid signature');
    return signer == _adminSigner;
  }

  function stakeAvatar(IVoviWallets.Link[] memory links, uint256 property, uint256 avatar, uint256 lastTxDate, uint256 listed, LibVoviStorage.Coupon memory coupon)
    internal whenNotPaused includedWallet(links) {
      LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
      bool isOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), avatar);
      require(isOwner, 'Incorrect owner for avatar');
      require(vs.stakedAvatars[property] == 0, 'Property already has an avatar in it!');
      require(vs.stakedAvatarsReverse[avatar] == 0, 'Avatar is already staked');
      bytes32 digest = keccak256(
        abi.encode(avatar, listed, lastTxDate)
      );
      require(_isVerifiedCoupon(digest, coupon, vs.adminSigner), 'Cannot confirm last Tx Date for avatar');
      vs.lastAvatarTxDates[avatar] = lastTxDate;
      vs.stakedAvatars[property] = avatar;
      vs.stakedAvatarsReverse[avatar] = property;
  }

  //@dev force unstaking an avatar without claiming rewards will lose the multiplier for the entire time
  function unstakeAvatar(IVoviWallets.Link[] memory links, uint256 avatar)
    public whenNotPaused nonReentrant includedWallet(links) {
      LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
      require(vs.stakedAvatarsReverse[avatar] != 0, 'Avatar is not staked');
      bool avatarOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), avatar);
      uint256 property = vs.stakedAvatarsReverse[avatar];
      bool propertyOwner = vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), property);
      
      require(avatarOwner || propertyOwner, 'Caller is not an owner of either the property or the avatar');
      delete vs.stakedAvatars[property];
      delete vs.stakedAvatars[avatar];
  }



  function stakePlots(
    IVoviWallets.Link[] memory links,
    LibVoviStorage.StakeRequest[] calldata requests
  ) external whenNotPaused nonReentrant includedWallet(links) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(requests.length <= 40 && requests.length > 0, "Stake: amount prohibited");

    for (uint256 i; i < requests.length; i++) {
      require(requests[i].tokenId <= vs.ranges[vs.ranges.length - 1].to, 'This property cannot be staked yet');
      require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleContract), requests[i].tokenId), "Stake: sender not owner");
      require(requests[i].listed == 0, 'Stake: Cannot stake listed property');
      bytes32 digest = keccak256(
        abi.encode(requests[i].tokenId, requests[i].listed, requests[i].lastTxDate)
      );
      require(_isVerifiedCoupon(digest, requests[i].coupon, vs.adminSigner), 'Last TX date for token could not be confirmed');
      vs.lastTxDates[requests[i].tokenId] = requests[i].lastTxDate;
      address realOwner = vs.voxelVilleContract.ownerOf(requests[i].tokenId);
      vs.lastClaimedBlockForToken[requests[i].tokenId] = uint128(block.number);
      vs.stakedTokens[realOwner].add(requests[i].tokenId);
      if(requests[i].avatar != 0) {
        require(vs.voviWalletsContract.isOwnerOf(links, address(vs.voxelVilleAvatarsContract), requests[i].avatar), "Stake: sender doesn't own avatar");
        require(requests[i].listedAvatar == 0, 'Stake: Cannot stake listed avatar');
        require(vs.stakedAvatarsReverse[requests[i].avatar] == 0, 'Avatar is already staked');
        require(vs.stakedAvatars[requests[i].tokenId] == 0, 'Property already has an avatar staked');
        digest = keccak256(
          abi.encode(requests[i].avatar, requests[i].listedAvatar, requests[i].avatarTxDate)
        );
        require(_isVerifiedCoupon(digest, requests[i].avatarCoupon, vs.adminSigner), 'Cannot verify last Avatar TX date');
        vs.stakedAvatars[requests[i].tokenId] = requests[i].avatar;
        vs.stakedAvatarsReverse[requests[i].avatar] = requests[i].tokenId;
        vs.lastAvatarTxDates[requests[i].avatar] = requests[i].avatarTxDate;
      }
    }

    emit VoviLibrary.Staked(msg.sender, requests);
  }



  function getStakedAvatarFor(uint256 tokenId) external view returns (uint256) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    return vs.stakedAvatars[tokenId];
  } 

  function stakedPlotsOf(IVoviWallets.Link[] memory links) external view returns (uint256[] memory) {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    uint256 stakedCount;
    for(uint i; i < links.length; i++) {
      stakedCount += vs.stakedTokens[links[i].signer].length();
    }
    uint256[] memory tokenIds = new uint256[](stakedCount);
    uint256 index;
    for (uint256 i; i < links.length; i++) {
      for (uint256 j; j < vs.stakedTokens[links[i].signer].length(); j++) {
        tokenIds[index++] = vs.stakedTokens[links[i].signer].at(j);
      }
    }

    return tokenIds;
  }    


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library LibPausable {
  using LibVoviStorage for *;
  
  event Paused(address account);
  event Unpaused(address account);

  function pause() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.paused, "Pausable: Already paused");
    vs.paused = true;
    emit Paused(msg.sender);
  }

  function unpause() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.paused, "Pausable: Already unpaused");
    vs.paused = false;
    emit Unpaused(msg.sender);
  }

  function enforceNotPaused() internal view {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(!vs.paused, "Pausable: Contract functionality paused");
  }

  function enforcePaused() internal view {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.paused, "Pausable: Contract functionality is not paused");
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library LibReentrancyGuard {
  using LibVoviStorage for *;

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  function nonReentrant() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    require(vs.reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
    vs.reentrancyStatus = _ENTERED;
  }

  function completeNonReentrant() internal {
    LibVoviStorage.VoviStorage storage vs = LibVoviStorage.voviStorage();
    vs.reentrancyStatus = _NOT_ENTERED;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IVoviWallets.sol";

library LibVoviStorage {

  bytes32 constant VOVI_STORAGE_POSITION = keccak256("com.voxelville.vovi.storage");

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct StakingRange {
    uint256 from;
    uint256 to;
    uint256 baseReward;
  }

  struct Reward {
    uint256 tokenId;
    uint256 tokens;
    Coupon coupon;
  }

  struct StakeRequest {
    uint256 tokenId;
    uint256 lastTxDate;
    uint256 listed;
    Coupon coupon;
    uint256 avatar;
    uint256 avatarTxDate;
    uint256 listedAvatar;
    Coupon avatarCoupon;
  }

  struct ClaimRequest {
    uint256 tokenId;
    uint256 lastTxDate;
    uint256 listed;
    Reward multReward;
    Coupon coupon;
    uint256 avatarTxDate;
    uint256 listedAvatar;
    Coupon avatarCoupon;
  }
  
  struct VoviStorage {

    mapping(uint256 => uint256)  lastTxDates;
    mapping(uint256 => uint256)  lastAvatarTxDates;

    StakingRange[]  ranges;

    IERC721  voxelVilleContract;
    IERC721  voxelVilleAvatarsContract;
    IVoviWallets  voviWalletsContract;
    address  adminSigner;
    mapping(uint256 => uint256)  stakedAvatars;
    mapping(uint256 => uint256)  stakedAvatarsReverse;
    

    uint256 rewardsEnd;
    bool finalizedRewardsEnd;


    mapping(uint256 => uint256) lastClaimedBlockForToken;
    mapping(address => EnumerableSet.UintSet) stakedTokens;

    mapping(uint256 => bool) claimedHolderRewards;

    uint256 reentrancyStatus;

    bool paused;

    mapping(uint256 => bool) bulkRewardClaimed;

    uint256 dailyBlockAverage;
    uint256 bulkRewardDays;
  }
  


  function voviStorage() internal pure returns (VoviStorage storage vs) {
    bytes32 position = VOVI_STORAGE_POSITION;
    assembly {
      vs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library VoviLibrary {
  using LibVoviStorage for *;


  function arrayContains(address[] memory array, address target) internal pure returns (bool) {
    for (uint256 i; i < array.length; i++) {
      if (array[i] == target) return true;
    }
    return false;
  }

  function isValidReward(LibVoviStorage.Reward memory reward, address adminSigner) internal pure returns (bool) {
    bytes32 digest = keccak256(
      abi.encode(reward.tokenId, reward.tokens)
    );
    return _isVerifiedCoupon(digest, reward.coupon, adminSigner);
  }
  
  /// @dev check that the coupon sent was signed by the admin signer
  function _isVerifiedCoupon(bytes32 digest, LibVoviStorage.Coupon memory coupon, address _adminSigner)
    internal
    pure
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), 'ECDSA: invalid signature');
    return signer == _adminSigner;
  }

  function inRange(uint256 target, uint256 lower, uint256 upper) internal pure returns (bool) {
    return target >= lower && target <= upper;
  }

  event Staked(address indexed account, LibVoviStorage.StakeRequest[] requests);
  event Unstaked(address indexed account, LibVoviStorage.ClaimRequest[] requests, uint256[] avatars);
  event RewardsClaimed(address indexed account, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoviWallets {
  struct Link {
    address signer;
    bytes signature;
  }  
  function isOwnerOf(Link[] calldata links, address token, uint256 tokenId) external view returns (bool);
  function balanceOf(Link[] calldata links, address token) external view returns (uint256);
  function confirmLinks(Link[] calldata links) external pure returns (bool);
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