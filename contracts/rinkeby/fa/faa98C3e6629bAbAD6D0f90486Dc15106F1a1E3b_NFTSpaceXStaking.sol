// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Pausable.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../token/ERC1155/ERC1155Holder.sol";
import "../token/ERC1155/IERC1155.sol";
import "../token/INFTSpaceXToken.sol";

contract NFTSpaceXStaking is ERC1155Holder, Ownable, ReentrancyGuard, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  string public constant name = "NFTSpaceX Staking";

  enum StakingOption {
    basic,
    premium,
    pro
  }

  struct StakingInfo {
    StakingOption option;
    uint256 tokenId;
    uint256 amount;
    uint256 startTime;
    bool harvest;
  }
  // mapping from user to slot index to info
  mapping(address => mapping(uint256 => StakingInfo)) public userStakings;
  mapping(address => uint256) public numberStaking;
  mapping(address => EnumerableSet.UintSet) slotStaked;
  mapping(address => uint256) public accumulativeTP;

  uint256 constant BASE = 1e18;
  uint256 public limitSlot;
  IERC1155 public nftspacexAssetERC1155;
  INFTSpaceXToken public nftspacexToken;

  uint16[6] public TICKET_POINT = [1, 39, 219, 1099, 5499, 31299];
  uint32[6] public BASIC_STAKING = [500, 2500, 12500, 62500, 312500, 1500000];
  uint32[6] public PREMIUM_STAKING = [1100, 5500, 26000, 132500, 650000, 3250000];
  uint32[6] public PRO_STAKING = [2000, 10000, 50000, 260000, 1125000, 5000000];

  event Stake(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 indexed startTime);
  event Harvest(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 reward);
  event Withdraw(address indexed user, uint256 indexed tokenId, uint256 amount);
  event UpdatedTP(address indexed user, uint256 accumulativeTP);

  constructor(address _nftspacexAssetERC1155, address _nftspacexToken, uint256 _limitSlot) {
    nftspacexAssetERC1155 = IERC1155(_nftspacexAssetERC1155);
    nftspacexToken = INFTSpaceXToken(_nftspacexToken);
    limitSlot = _limitSlot;
  }

  function setLimitSlot(uint256 _limitSlot) public onlyOwner whenPaused {
    limitSlot = _limitSlot;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function refundNFT(address to, uint256 tokenId, uint256 amount) public onlyOwner whenPaused {
    _transferNFT(address(this), to, tokenId, amount);
  }

  function stakedSlot(address user) public view returns (uint256[] memory slots) {
    for (uint256 i = 0; i < slotStaked[user].length(); i++) {
      slots[i] = slotStaked[user].at(i);
    }
  }

  function stake(StakingOption option, uint256 tokenId, uint256 amount) public whenNotPaused {
    require(nftspacexAssetERC1155.balanceOf(_msgSender(), tokenId) >= amount, "NSS: insufficient fund");
    require(slotStaked[_msgSender()].length() < limitSlot, "NSS: full slot staking");

    _transferNFT(_msgSender(), address(this), tokenId, amount);
    uint256 slotIndex = numberStaking[_msgSender()];
    slotStaked[_msgSender()].add(slotIndex);
    numberStaking[_msgSender()]++;
    StakingInfo memory stakingInfo = _setStakingInfo(option, tokenId, amount, block.timestamp, false);
    _updateStakingInfo(_msgSender(), slotIndex, stakingInfo);

    emit Stake(_msgSender(), tokenId, amount, block.timestamp);
  }

  function harvest(uint256 slotIndex) public whenNotPaused {
    require(slotStaked[_msgSender()].contains(slotIndex), "NSS: slot non exists");

    StakingInfo memory stakingInfo = userStakings[_msgSender()][slotIndex];
    require(nftspacexAssetERC1155.balanceOf(address(this), stakingInfo.tokenId) >= stakingInfo.amount, "NSS: not enough amount to withdraw");
    require(_canHarvest(_msgSender(), slotIndex), "NSS: stake finished");

    uint256 reward = _calculateReward(_msgSender(), slotIndex);
    _transferNFT(address(this), _msgSender(), stakingInfo.tokenId, stakingInfo.amount);
    _transferRewardToken(_msgSender(), reward);
    _updateAccumulativeTP(_msgSender(), slotIndex);

    slotStaked[_msgSender()].remove(slotIndex);
    _updateStakingInfo(
      _msgSender(),
      slotIndex,
      StakingInfo({
        option: stakingInfo.option,
        tokenId: stakingInfo.tokenId,
        amount: stakingInfo.amount,
        startTime: stakingInfo.startTime,
        harvest: true
      })
    );

    emit UpdatedTP(_msgSender(), accumulativeTP[_msgSender()]);
    emit Harvest(_msgSender(), stakingInfo.tokenId, stakingInfo.amount, reward);
  }

  function withdraw(uint256 slotIndex) public whenNotPaused {
    require(slotStaked[_msgSender()].contains(slotIndex), "NSS: slot non exists");

    StakingInfo memory stakingInfo = userStakings[_msgSender()][slotIndex];
    require(nftspacexAssetERC1155.balanceOf(address(this), stakingInfo.tokenId) >= stakingInfo.amount, "NSS: not enough amount to withdraw");
    require(!_canHarvest(_msgSender(), slotIndex), "NSS: stake finished");

    _transferNFT(address(this), _msgSender(), stakingInfo.tokenId, stakingInfo.amount);
    slotStaked[_msgSender()].remove(slotIndex);
    _updateStakingInfo(
      _msgSender(),
      slotIndex,
      StakingInfo({
        option: stakingInfo.option,
        tokenId: stakingInfo.tokenId,
        amount: stakingInfo.amount,
        startTime: stakingInfo.startTime,
        harvest: true
      })
    );

    emit Withdraw(_msgSender(), stakingInfo.tokenId, stakingInfo.amount);
  }

  function canHarvest(address user, uint256 slotIndex) public view returns (bool result) {
    result = _canHarvest(user, slotIndex);
  }

  function rewardAfterHarvest(address user, uint256 slotIndex) public view returns (uint256 reward) {
    reward = _calculateReward(user, slotIndex);
  }

  function _transferNFT(address _from, address _to, uint256 _tokenId, uint256 _amount) internal {
    nftspacexAssetERC1155.safeTransferFrom(_from, _to, _tokenId, _amount, "");
  }

  function _transferRewardToken(address _to, uint256 _amount) internal {
    nftspacexToken.transfer(_to, _amount);
  }

  function _updateStakingInfo(address _user, uint256 _slotIndex, StakingInfo memory _stakingInfo) internal {
    userStakings[_user][_slotIndex] = _stakingInfo;
  }

  function _setStakingInfo(
    StakingOption _option,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _startTime,
    bool _harvest
  ) internal pure returns(StakingInfo memory stakingInfo) {
    stakingInfo = StakingInfo({
      option: _option,
      tokenId: _tokenId,
      amount: _amount,
      startTime: _startTime,
      harvest: _harvest
    });
  }
 
  function _canHarvest(address _user, uint256 _slotIndex) internal view returns (bool) {
    StakingInfo memory stakingInfo = userStakings[_user][_slotIndex];
    if (stakingInfo.harvest) {
      return false;
    }

    if (stakingInfo.option == StakingOption.basic) {
      if ((stakingInfo.startTime + (30 * 10)) <= block.timestamp) {
        return true;
      }
    } else if (stakingInfo.option == StakingOption.premium) {
      if ((stakingInfo.startTime + (60 * 10)) <= block.timestamp) {
        return true;
      }
    } else {
      if ((stakingInfo.startTime + (90 * 10)) <= block.timestamp) {
        return true;
      }
    }

    return false;
  }

  function _calculateReward(address _user, uint256 _slotIndex) internal view returns (uint256) {
    StakingInfo memory stakingInfo = userStakings[_user][_slotIndex];
    if (stakingInfo.option == StakingOption.basic) {
      return (BASIC_STAKING[stakingInfo.tokenId] * stakingInfo.amount * BASE);
    } else if (stakingInfo.option == StakingOption.premium) {
      return (PREMIUM_STAKING[stakingInfo.tokenId] * stakingInfo.amount * BASE);
    } else {
      return (PRO_STAKING[stakingInfo.tokenId] * stakingInfo.amount * BASE);
    }
  }

  function _updateAccumulativeTP(address _user, uint256 _slotIndex) internal {
    StakingInfo memory stakingInfo = userStakings[_user][_slotIndex];
    if (stakingInfo.option == StakingOption.basic) {
      if (stakingInfo.tokenId == 0) {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId];
      } else {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId] / 3;
      }
    } else if (stakingInfo.option == StakingOption.premium) {
      if (stakingInfo.tokenId == 0) {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId];
      } else {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId] * 2 / 3;
      }
    } else {
      if (stakingInfo.tokenId == 0) {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId];
      } else {
        accumulativeTP[_user] += stakingInfo.amount * TICKET_POINT[stakingInfo.tokenId];
      }
    }
  }
}

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Pausable is Context {
  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  constructor() {
    _paused = false;
  }

  /**
   * @dev Return true if the contract is paused, and false otherwise
   */
  function paused() public virtual returns (bool) {
    return _paused;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Return to normal state
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
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

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    // event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

import "./ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface INFTSpaceXToken is IERC20 {
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
  
  function maxTotalSupply() external view returns (uint256);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function getVotes(address account) external view returns (uint256);
  function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
  function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
  function delegates(address account) external view returns (address);
  function delegate(address delegatee) external;
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT

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

import "./IERC1155Receiver.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IERC1155Receiver).interfaceId
        || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}