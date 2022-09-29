pragma solidity 0.8.17;

import "@thesis/solidity-contracts/contracts/token/IERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RNG.sol";
import "./SortitionTree.sol";
import "./Rewards.sol";
import "./Chaosnet.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is
  SortitionTree,
  Rewards,
  Ownable,
  Chaosnet,
  IReceiveApproval
{
  using Branch for uint256;
  using Leaf for uint256;
  using Position for uint256;

  IERC20WithPermit public immutable rewardToken;

  uint256 public immutable poolWeightDivisor;

  bool public isLocked;

  event IneligibleForRewards(uint32[] ids, uint256 until);

  event RewardEligibilityRestored(address indexed operator, uint32 indexed id);

  /// @notice Reverts if called while pool is locked.
  modifier onlyUnlocked() {
    require(!isLocked, "Sortition pool locked");
    _;
  }

  /// @notice Reverts if called while pool is unlocked.
  modifier onlyLocked() {
    require(isLocked, "Sortition pool unlocked");
    _;
  }

  constructor(IERC20WithPermit _rewardToken, uint256 _poolWeightDivisor) {
    rewardToken = _rewardToken;
    poolWeightDivisor = _poolWeightDivisor;
  }

  function receiveApproval(
    address sender,
    uint256 amount,
    address token,
    bytes calldata
  ) external override {
    require(token == address(rewardToken), "Unsupported token");
    rewardToken.transferFrom(sender, address(this), amount);
    Rewards.addRewards(uint96(amount), uint32(root.sumWeight()));
  }

  /// @notice Withdraws all available rewards for the given operator to the
  ///         given beneficiary.
  /// @dev Can be called only be the owner. Does not validate if the provided
  ///      beneficiary is associated with the provided operator - this needs to
  ///      be done by the owner calling this function.
  /// @return The amount of rewards withdrawn in this call.
  function withdrawRewards(address operator, address beneficiary)
    public
    onlyOwner
    returns (uint96)
  {
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(getPoolWeight(operator)));
    uint96 earned = Rewards.withdrawOperatorRewards(id);
    rewardToken.transfer(beneficiary, uint256(earned));
    return earned;
  }

  /// @notice Withdraws rewards not allocated to operators marked as ineligible
  ///         to the given recipient address.
  /// @dev Can be called only by the owner.
  function withdrawIneligible(address recipient) public onlyOwner {
    uint96 earned = Rewards.withdrawIneligibleRewards();
    rewardToken.transfer(recipient, uint256(earned));
  }

  /// @notice Locks the sortition pool. In locked state, members cannot be
  ///         inserted and removed from the pool. Members statuses cannot
  ///         be updated as well.
  /// @dev Can be called only by the contract owner.
  function lock() public onlyOwner {
    isLocked = true;
  }

  /// @notice Unlocks the sortition pool. Removes all restrictions set by
  ///         the `lock` method.
  /// @dev Can be called only by the contract owner.
  function unlock() public onlyOwner {
    isLocked = false;
  }

  /// @notice Inserts an operator to the pool. Reverts if the operator is
  /// already present. Reverts if the operator is not eligible because of their
  /// authorized stake. Reverts if the chaosnet is active and the operator is
  /// not a beta operator.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the inserted operator.
  /// @param authorizedStake Inserted operator's authorized stake for the application.
  function insertOperator(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);
    require(weight > 0, "Operator not eligible");

    if (isChaosnetActive) {
      require(isBetaOperator[operator], "Not beta operator for chaosnet");
    }

    _insertOperator(operator, weight);
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the updated operator.
  /// @param authorizedStake Operator's authorized stake for the application.
  function updateOperatorStatus(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);

    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));

    if (weight == 0) {
      _removeOperator(operator);
    } else {
      updateOperator(operator, weight);
    }
  }

  /// @notice Set the given operators as ineligible for rewards.
  ///         The operators can restore their eligibility at the given time.
  function setRewardIneligibility(uint32[] calldata operators, uint256 until)
    public
    onlyOwner
  {
    Rewards.setIneligible(operators, until);
    emit IneligibleForRewards(operators, until);
  }

  /// @notice Restores reward eligibility for the operator.
  function restoreRewardEligibility(address operator) public {
    uint32 id = getOperatorID(operator);
    Rewards.restoreEligibility(id);
    emit RewardEligibilityRestored(operator, id);
  }

  /// @notice Returns whether the operator is eligible for rewards or not.
  function isEligibleForRewards(address operator) public view returns (bool) {
    uint32 id = getOperatorID(operator);
    return Rewards.isEligibleForRewards(id);
  }

  /// @notice Returns the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(address operator)
    public
    view
    returns (uint256)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.rewardsEligibilityRestorableAt(id);
  }

  /// @notice Returns whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(address operator)
    public
    view
    returns (bool)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.canRestoreRewardEligibility(id);
  }

  /// @notice Returns the amount of rewards withdrawable for the given operator.
  function getAvailableRewards(address operator) public view returns (uint96) {
    uint32 id = getOperatorID(operator);
    return availableRewards(id);
  }

  /// @notice Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Return whether the operator's weight in the pool
  /// matches their eligible weight.
  function isOperatorUpToDate(address operator, uint256 authorizedStake)
    public
    view
    returns (bool)
  {
    return getWeight(authorizedStake) == getPoolWeight(operator);
  }

  /// @notice Return the weight of the operator in the pool,
  /// which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = getLeafWeight(leafPosition);
      return leafWeight;
    }
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed. At least one operator has to be
  /// registered in the pool, otherwise the function fails reverting the
  /// transaction.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @return selected Members of the selected group
  function selectGroup(uint256 groupSize, bytes32 seed)
    public
    view
    onlyLocked
    returns (uint32[] memory)
  {
    uint256 _root = root;

    bytes32 rngState = seed;
    uint256 rngRange = _root.sumWeight();
    require(rngRange > 0, "Not enough operators in pool");
    uint256 currentIndex;

    uint256 bits = RNG.bitsRequired(rngRange);

    uint32[] memory selected = new uint32[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
      (currentIndex, rngState) = RNG.getIndex(rngRange, rngState, bits);

      uint256 leafPosition = pickWeightedLeaf(currentIndex, _root);

      uint256 leaf = leaves[leafPosition];
      selected[i] = leaf.id();
    }
    return selected;
  }

  function getWeight(uint256 authorization) internal view returns (uint256) {
    return authorization / poolWeightDivisor;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IApproveAndCall.sol";

/// @title  IERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
interface IERC20WithPermit is IERC20, IERC20Metadata, IApproveAndCall {
    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Destroys `amount` tokens from the caller.
    function burn(uint256 amount) external;

    /// @notice Destroys `amount` of tokens from `account`, deducting the amount
    ///         from caller's allowance.
    function burnFrom(address account, uint256 amount) external;

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    function nonce(address owner) external view returns (uint256);

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    /* solhint-disable-next-line func-name-mixedcase */
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by contracts supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IReceiveApproval {
    /// @notice Receives approval to spend tokens. Called as a result of
    ///         `approveAndCall` call on the token.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
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

pragma solidity 0.8.17;

import "./Leaf.sol";
import "./Constants.sol";

library RNG {
  /// @notice Get an index in the range `[0 .. range-1]`
  /// and the new state of the RNG,
  /// using the provided `state` of the RNG.
  ///
  /// @param range The upper bound of the index, exclusive.
  ///
  /// @param state The previous state of the RNG.
  /// The initial state needs to be obtained
  /// from a trusted randomness oracle (the random beacon),
  /// or from a chain of earlier calls to `RNG.getIndex()`
  /// on an originally trusted seed.
  ///
  /// @dev Calculates the number of bits required for the desired range,
  /// takes the least significant bits of `state`
  /// and checks if the obtained index is within the desired range.
  /// The original state is hashed with `keccak256` to get a new state.
  /// If the index is outside the range,
  /// the function retries until it gets a suitable index.
  ///
  /// @return index A random integer between `0` and `range - 1`, inclusive.
  ///
  /// @return newState The new state of the RNG.
  /// When `getIndex()` is called one or more times,
  /// care must be taken to always use the output `state`
  /// of the most recent call as the input `state` of a subsequent call.
  /// At the end of a transaction calling `RNG.getIndex()`,
  /// the previous stored state must be overwritten with the latest output.
  function getIndex(
    uint256 range,
    bytes32 state,
    uint256 bits
  ) internal view returns (uint256, bytes32) {
    bool found = false;
    uint256 index = 0;
    bytes32 newState = state;
    while (!found) {
      index = truncate(bits, uint256(newState));
      newState = keccak256(abi.encodePacked(newState, address(this)));
      if (index < range) {
        found = true;
      }
    }
    return (index, newState);
  }

  /// @notice Calculate how many bits are required
  /// for an index in the range `[0 .. range-1]`.
  ///
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    unchecked {
      if (range == 1) {
        return 0;
      }

      uint256 bits = Constants.WEIGHT_WIDTH - 1;

      // Left shift by `bits`,
      // so we have a 1 in the (bits + 1)th least significant bit
      // and 0 in other bits.
      // If this number is equal or greater than `range`,
      // the range [0, range-1] fits in `bits` bits.
      //
      // Because we loop from high bits to low bits,
      // we find the highest number of bits that doesn't fit the range,
      // and return that number + 1.
      while (1 << bits >= range) {
        bits--;
      }

      return bits + 1;
    }
  }

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint256 bits, uint256 input)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      return input & ((1 << bits) - 1);
    }
  }
}

pragma solidity 0.8.17;

import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";
import "./Constants.sol";

contract SortitionTree {
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 internal root;

  // A 2-index mapping from layer => (index (0-index) => branch). For example,
  // to access the 6th branch in the 2nd layer (right below the root node; the
  // first branch layer), call branches[2][5]. Mappings are used in place of
  // arrays for efficiency. The root is the first layer, the branches occupy
  // layers 2 through 7, and layer 8 is for the leaves. Following this
  // convention, the first index in `branches` is `2`, and the last index is
  // `7`.
  mapping(uint256 => mapping(uint256 => uint256)) internal branches;

  // A 0-index mapping from index => leaf, acting as an array. For example, to
  // access the 42nd leaf, call leaves[41].
  mapping(uint256 => uint256) internal leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) internal flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 internal rightmostLeaf;

  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] internal emptyLeaves;

  // Each operator has an uint32 ID number
  // which is allocated when they first join the pool
  // and remains unchanged even if they leave and rejoin the pool.
  mapping(address => uint32) internal operatorID;

  // The idAddress array records the address corresponding to each ID number.
  // The ID number 0 is initialized with a zero address and is not used.
  address[] internal idAddress;

  constructor() {
    root = 0;
    rightmostLeaf = 0;
    idAddress.push();
  }

  /// @notice Return the ID number of the given operator address. An ID number
  /// of 0 means the operator has not been allocated an ID number yet.
  /// @param operator Address of the operator.
  /// @return the ID number of the given operator address
  function getOperatorID(address operator) public view returns (uint32) {
    return operatorID[operator];
  }

  /// @notice Get the operator address corresponding to the given ID number. A
  /// zero address means the ID number has not been allocated yet.
  /// @param id ID of the operator
  /// @return the address of the operator
  function getIDOperator(uint32 id) public view returns (address) {
    return idAddress.length > id ? idAddress[id] : address(0);
  }

  /// @notice Gets the operator addresses corresponding to the given ID
  /// numbers. A zero address means the ID number has not been allocated yet.
  /// This function works just like getIDOperator except that it allows to fetch
  /// operator addresses for multiple IDs in one call.
  /// @param ids the array of the operator ids
  /// @return an array of the associated operator addresses
  function getIDOperators(uint32[] calldata ids)
    public
    view
    returns (address[] memory)
  {
    uint256 idCount = idAddress.length;

    address[] memory operators = new address[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      uint32 id = ids[i];
      operators[i] = idCount > id ? idAddress[id] : address(0);
    }
    return operators;
  }

  /// @notice Checks if operator is already registered in the pool.
  /// @param operator the address of the operator
  /// @return whether or not the operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Sum the number of operators in each trunk.
  /// @return the number of operators in the pool
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.length;

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  /// @notice Convenience method to return the total weight of the pool
  /// @return the total weight of the pool
  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  /// @notice Give the operator a new ID number.
  /// Does not check if the operator already has an ID number.
  /// @param operator the address of the operator
  /// @return a new ID for that operator
  function allocateOperatorID(address operator) internal returns (uint256) {
    uint256 id = idAddress.length;

    require(id <= type(uint32).max, "Pool capacity exceeded");

    operatorID[operator] = uint32(id);
    idAddress.push(operator);
    return id;
  }

  /// @notice Inserts an operator into the sortition pool
  /// @param operator the address of an operator to insert
  /// @param weight how much weight that operator has in the pool
  function _insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    // Fetch the operator's ID, and if they don't have one, allocate them one.
    uint256 id = getOperatorID(operator);
    if (id == 0) {
      id = allocateOperatorID(operator);
    }

    // Determine which leaf to insert them into
    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, id);

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = setLeaf(position, theLeaf, weight, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  /// @notice Remove an operator (and their weight) from the pool.
  /// @param operator the address of the operator to remove
  function _removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  /// @notice Update an operator's weight in the pool.
  /// @param operator the address of the operator to update
  /// @param weight the new weight
  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = updateLeaf(unflaggedPosition, weight, root);
  }

  /// @notice Helper method to remove a leaf position record for an operator.
  /// @param operator the address of the operator to remove the record for
  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  /// @notice Removes the data and weight from a particular leaf.
  /// @param position the leaf index to remove
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    // Clears out the data in the leaf node, and then propagates the weight
    // changes all the way up to the root.
    uint256 newRoot = setLeaf(position, 0, 0, _root);

    // Infer if need to fall back on emptyLeaves yet
    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.push(position);
    }
    return newRoot;
  }

  /// @notice Updates the tree to give a particular leaf a new weight.
  /// @param position the index of the leaf to update
  /// @param weight the new weight
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateLeaf(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    if (getLeafWeight(position) != weight) {
      return updateTree(position, weight, _root);
    } else {
      return _root;
    }
  }

  /// @notice Places a leaf into a particular position, with a given weight and
  /// propagates that change.
  /// @param position the index to place the leaf in
  /// @param theLeaf the new leaf to place in the position
  /// @param leafWeight the weight of the leaf
  /// @param _root the root containing the new leaf
  /// @return the updated root node
  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 leafWeight,
    uint256 _root
  ) internal returns (uint256) {
    // set leaf
    leaves[position] = theLeaf;

    return (updateTree(position, leafWeight, _root));
  }

  /// @notice Propagates a weight change at a position through the tree,
  /// eventually returning the updated root.
  /// @param position the index of leaf to update
  /// @param weight the new weight of the leaf
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateTree(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = weight;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = Constants.LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  /// @notice Retrieves the next available empty leaf position. Tries to fill
  /// left to right first, ignoring leaf removals, and then fills
  /// most-recent-removals first.
  /// @return the position of the empty leaf
  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < Constants.POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      uint256 emptyLeafCount = emptyLeaves.length;
      require(emptyLeafCount > 0, "Pool is full");
      uint256 emptyLeaf = emptyLeaves[emptyLeafCount - 1];
      emptyLeaves.pop();
      return emptyLeaf;
    }
  }

  /// @notice Gets the flagged leaf position for an operator.
  /// @param operator the address of the operator
  /// @return the leaf position of that operator
  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  /// @notice Gets the weight of a leaf at a particular position.
  /// @param position the index of the leaf
  /// @return the weight of the leaf at that position
  function getLeafWeight(uint256 position) internal view returns (uint256) {
    uint256 slot = position.slot();
    uint256 parent = position.parent();

    // A leaf's weight information is stored a 32-bit slot in the branch layer
    // directly above the leaf layer. To access it, we calculate that slot and
    // parent position, and always know the hard-coded layer index.
    uint256 node = branches[Constants.LEVELS][parent];
    return node.getSlot(slot);
  }

  /// @notice Picks a leaf given a random index.
  /// @param index a number in `[0, _root.totalWeight())` used to decide
  /// between leaves
  /// @param _root the root of the tree
  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= Constants.LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
  }
}

pragma solidity 0.8.17;

/// @title Rewards
/// @notice Rewards are allocated proportionally to operators
/// present in the pool at payout based on their weight in the pool.
///
/// To facilitate this, we use a global accumulator value
/// to track the total rewards one unit of weight would've earned
/// since the creation of the pool.
///
/// Whenever a reward is paid, the accumulator is increased
/// by the size of the reward divided by the total weight
/// of all eligible operators in the pool.
///
/// Each operator has an individual accumulator value,
/// set to equal the global accumulator when the operator joins the pool.
/// This accumulator reflects the amount of rewards
/// that have already been accounted for with that operator.
///
/// Whenever an operator's weight in the pool changes,
/// we can update the amount of rewards the operator has earned
/// by subtracting the operator's accumulator from the global accumulator.
/// This gives us the amount of rewards one unit of weight has earned
/// since the last time the operator's rewards have been updated.
/// Then we multiply that by the operator's previous (pre-change) weight
/// to determine how much rewards in total the operator has earned,
/// and add this to the operator's earned rewards.
/// Finally, we set the operator's accumulator to the global accumulator value.
contract Rewards {
  struct OperatorRewards {
    // The state of the global accumulator
    // when the operator's rewards were last updated
    uint96 accumulated;
    // The amount of rewards collected by the operator after the latest update.
    // The amount the operator could withdraw may equal `available`
    // or it may be greater, if more rewards have been paid in since then.
    // To evaulate the most recent amount including rewards potentially paid
    // since the last update, use `availableRewards` function.
    uint96 available;
    // If nonzero, the operator is ineligible for rewards
    // and may only re-enable rewards after the specified timestamp.
    // XXX: unsigned 32-bit integer unix seconds, will break around 2106
    uint32 ineligibleUntil;
    // Locally cached weight of the operator,
    // used to reduce the cost of setting operators ineligible.
    uint32 weight;
  }

  // The global accumulator of how much rewards
  // a hypothetical operator of weight 1 would have earned
  // since the creation of the pool.
  uint96 internal globalRewardAccumulator;
  // If the amount of reward tokens paid in
  // does not divide cleanly by pool weight,
  // the difference is recorded as rounding dust
  // and added to the next reward.
  uint96 internal rewardRoundingDust;

  // The amount of rewards that would've been earned by ineligible operators
  // had they not been ineligible.
  uint96 public ineligibleEarnedRewards;

  // Ineligibility times are calculated from this offset,
  // set at contract creation.
  uint256 internal immutable ineligibleOffsetStart;

  mapping(uint32 => OperatorRewards) internal operatorRewards;

  constructor() {
    // solhint-disable-next-line not-rely-on-time
    ineligibleOffsetStart = block.timestamp;
  }

  /// @notice Return whether the operator is eligible for rewards or not.
  function isEligibleForRewards(uint32 operator) internal view returns (bool) {
    return operatorRewards[operator].ineligibleUntil == 0;
  }

  /// @notice Return the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(uint32 operator)
    internal
    view
    returns (uint256)
  {
    uint32 until = operatorRewards[operator].ineligibleUntil;
    require(until != 0, "Operator already eligible");
    return (uint256(until) + ineligibleOffsetStart);
  }

  /// @notice Return whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(uint32 operator)
    internal
    view
    returns (bool)
  {
    // solhint-disable-next-line not-rely-on-time
    return rewardsEligibilityRestorableAt(operator) <= block.timestamp;
  }

  /// @notice Internal function for updating the global state of rewards.
  function addRewards(uint96 rewardAmount, uint32 currentPoolWeight) internal {
    require(currentPoolWeight > 0, "No recipients in pool");

    uint96 totalAmount = rewardAmount + rewardRoundingDust;
    uint96 perWeightReward = totalAmount / currentPoolWeight;
    uint96 newRoundingDust = totalAmount % currentPoolWeight;

    globalRewardAccumulator += perWeightReward;
    rewardRoundingDust = newRoundingDust;
  }

  /// @notice Internal function for updating the operator's reward state.
  function updateOperatorRewards(uint32 operator, uint32 newWeight) internal {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, update their earned rewards
      o.available += accruedRewards;
    } else {
      // If ineligible, put the rewards into the ineligible pot
      ineligibleEarnedRewards += accruedRewards;
    }
    // In any case, update their accumulator and weight
    o.accumulated = acc;
    o.weight = newWeight;
    operatorRewards[operator] = o;
  }

  /// @notice Set the amount of withdrawable tokens to zero
  /// and return the previous withdrawable amount.
  /// @dev Does not update the withdrawable amount,
  /// but should usually be accompanied by an update.
  function withdrawOperatorRewards(uint32 operator)
    internal
    returns (uint96 withdrawable)
  {
    OperatorRewards storage o = operatorRewards[operator];
    withdrawable = o.available;
    o.available = 0;
  }

  /// @notice Set the amount of ineligible-earned tokens to zero
  /// and return the previous amount.
  function withdrawIneligibleRewards() internal returns (uint96 withdrawable) {
    withdrawable = ineligibleEarnedRewards;
    ineligibleEarnedRewards = 0;
  }

  /// @notice Set the given operators as ineligible for rewards.
  /// The operators can restore their eligibility at the given time.
  function setIneligible(uint32[] memory operators, uint256 until) internal {
    OperatorRewards memory o = OperatorRewards(0, 0, 0, 0);
    uint96 globalAcc = globalRewardAccumulator;
    uint96 accrued = 0;
    // Record ineligibility as seconds after contract creation
    uint32 _until = uint32(until - ineligibleOffsetStart);

    for (uint256 i = 0; i < operators.length; i++) {
      uint32 operator = operators[i];
      OperatorRewards storage r = operatorRewards[operator];
      o.available = r.available;
      o.accumulated = r.accumulated;
      o.ineligibleUntil = r.ineligibleUntil;
      o.weight = r.weight;

      if (o.ineligibleUntil != 0) {
        // If operator is already ineligible,
        // don't earn rewards or shorten its ineligibility
        if (o.ineligibleUntil < _until) {
          o.ineligibleUntil = _until;
        }
      } else {
        // The operator becomes ineligible -> earn rewards
        o.ineligibleUntil = _until;
        accrued = (globalAcc - o.accumulated) * uint96(o.weight);
        o.available += accrued;
      }
      o.accumulated = globalAcc;

      r.available = o.available;
      r.accumulated = o.accumulated;
      r.ineligibleUntil = o.ineligibleUntil;
      r.weight = o.weight;
    }
  }

  /// @notice Restore the given operator's eligibility for rewards.
  function restoreEligibility(uint32 operator) internal {
    // solhint-disable-next-line not-rely-on-time
    require(canRestoreRewardEligibility(operator), "Operator still ineligible");
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    ineligibleEarnedRewards += accruedRewards;
    o.accumulated = acc;
    o.ineligibleUntil = 0;
    operatorRewards[operator] = o;
  }

  /// @notice Returns the amount of rewards currently available for withdrawal
  ///         for the given operator.
  function availableRewards(uint32 operator) internal view returns (uint96) {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, calculate newly accrued rewards and add
      // them to the available ones, calculated during the last update.
      uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
      return o.available + accruedRewards;
    } else {
      // If ineligible, return only the rewards calculated during the last
      // update.
      return o.available;
    }
  }
}

pragma solidity 0.8.17;

/// @title Chaosnet
/// @notice This is a beta staker program for stakers willing to go the extra
/// mile with monitoring, share their logs with the dev team, and allow to more
/// carefully monitor the bootstrapping network. As the network matures, the
/// beta program will be ended.
contract Chaosnet {
  /// @notice Indicates if the chaosnet is active. The chaosnet is active
  /// after the contract deployment and can be ended with a call to
  /// `deactivateChaosnet()`. Once deactivated chaosnet can not be activated
  /// again.
  bool public isChaosnetActive;

  /// @notice Indicates if the given operator is a beta operator for chaosnet.
  mapping(address => bool) public isBetaOperator;

  /// @notice Address controlling chaosnet status and beta operator addresses.
  address public chaosnetOwner;

  event BetaOperatorsAdded(address[] operators);

  event ChaosnetOwnerRoleTransferred(
    address oldChaosnetOwner,
    address newChaosnetOwner
  );

  event ChaosnetDeactivated();

  constructor() {
    _transferChaosnetOwner(msg.sender);
    isChaosnetActive = true;
  }

  modifier onlyChaosnetOwner() {
    require(msg.sender == chaosnetOwner, "Not the chaosnet owner");
    _;
  }

  modifier onlyOnChaosnet() {
    require(isChaosnetActive, "Chaosnet is not active");
    _;
  }

  /// @notice Adds beta operator to chaosnet. Can be called only by the
  /// chaosnet owner when the chaosnet is active. Once the operator is added
  /// as a beta operator, it can not be removed.
  function addBetaOperators(address[] calldata operators)
    public
    onlyOnChaosnet
    onlyChaosnetOwner
  {
    for (uint256 i = 0; i < operators.length; i++) {
      isBetaOperator[operators[i]] = true;
    }

    emit BetaOperatorsAdded(operators);
  }

  /// @notice Deactivates the chaosnet. Can be called only by the chaosnet
  /// owner. Once deactivated chaosnet can not be activated again.
  function deactivateChaosnet() public onlyOnChaosnet onlyChaosnetOwner {
    isChaosnetActive = false;
    emit ChaosnetDeactivated();
  }

  /// @notice Transfers the chaosnet owner role to another non-zero address.
  function transferChaosnetOwnerRole(address newChaosnetOwner)
    public
    onlyChaosnetOwner
  {
    require(
      newChaosnetOwner != address(0),
      "New chaosnet owner must not be zero address"
    );
    _transferChaosnetOwner(newChaosnetOwner);
  }

  function _transferChaosnetOwner(address newChaosnetOwner) internal {
    address oldChaosnetOwner = chaosnetOwner;
    chaosnetOwner = newChaosnetOwner;
    emit ChaosnetOwnerRoleTransferred(oldChaosnetOwner, newChaosnetOwner);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by tokens supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IApproveAndCall {
    /// @notice Executes `receiveApproval` function on spender as specified in
    ///         `IReceiveApproval` interface. Approves spender to withdraw from
    ///         the caller multiple times, up to the `amount`. If this
    ///         function is called again, it overwrites the current allowance
    ///         with `amount`. Reverts if the approval reverted or if
    ///         `receiveApproval` call on the spender reverted.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external returns (bool);
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

pragma solidity 0.8.17;

import "./Constants.sol";

library Leaf {
  function make(
    address _operator,
    uint256 _creationBlock,
    uint256 _id
  ) internal pure returns (uint256) {
    assert(_creationBlock <= type(uint64).max);
    assert(_id <= type(uint32).max);
    // Converting a bytesX type into a larger type
    // adds zero bytes on the right.
    uint256 op = uint256(bytes32(bytes20(_operator)));
    // Bitwise AND the id to erase
    // all but the 32 least significant bits
    uint256 uid = _id & Constants.ID_MAX;
    // Erase all but the 64 least significant bits,
    // then shift left by 32 bits to make room for the id
    uint256 cb = (_creationBlock & Constants.BLOCKHEIGHT_MAX) <<
      Constants.ID_WIDTH;
    // Bitwise OR them all together to get
    // [address operator || uint64 creationBlock || uint32 id]
    return (op | cb | uid);
  }

  function operator(uint256 leaf) internal pure returns (address) {
    // Converting a bytesX type into a smaller type
    // truncates it on the right.
    return address(bytes20(bytes32(leaf)));
  }

  /// @notice Return the block number the leaf was created in.
  function creationBlock(uint256 leaf) internal pure returns (uint256) {
    return ((leaf >> Constants.ID_WIDTH) & Constants.BLOCKHEIGHT_MAX);
  }

  function id(uint256 leaf) internal pure returns (uint32) {
    // Id is stored in the 32 least significant bits.
    // Bitwise AND ensures that we only get the contents of those bits.
    return uint32(leaf & Constants.ID_MAX);
  }
}

pragma solidity 0.8.17;

library Constants {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant LAST_SLOT = SLOT_COUNT - 1;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 constant POOL_CAPACITY = SLOT_COUNT**LEVELS;

  uint256 constant ID_WIDTH = SLOT_WIDTH;
  uint256 constant ID_MAX = SLOT_MAX;

  uint256 constant BLOCKHEIGHT_WIDTH = 96 - ID_WIDTH;
  uint256 constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

  uint256 constant SLOT_POINTER_MAX = (2**SLOT_BITS) - 1;
  uint256 constant LEAF_FLAG = 1 << 255;

  uint256 constant WEIGHT_WIDTH = 256 / SLOT_COUNT;
  ////////////////////////////////////////////////////////////////////////////
}

pragma solidity 0.8.17;

import "./Constants.sol";

/// @notice The implicit 8-ary trees of the sortition pool
/// rely on packing 8 "slots" of 32-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {
  /// @notice Calculate the right shift required
  /// to make the 32 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint32[8].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint256 position) internal pure returns (uint256) {
    unchecked {
      return position * Constants.SLOT_WIDTH;
    }
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint32[32].
  function getSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Doing a bitwise AND with `SLOT_MAX`
      // clears all but the 32 least significant bits.
      // Because of the right shift by `slotShift(position)` bits,
      // those 32 bits contain the 32 bits in the `position`th slot of `node`.
      return (node >> shiftBits) & Constants.SLOT_MAX;
    }
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Shifting `SLOT_MAX` left by `slotShift(position)` bits
      // gives us a number where all bits of the `position`th slot are set,
      // and all other bits are unset.
      //
      // Using a bitwise NOT on this number,
      // we get a uint256 where all bits are set
      // except for those of the `position`th slot.
      //
      // Bitwise ANDing the original `node` with this number
      // sets the bits of `position`th slot to zero,
      // leaving all other bits unchanged.
      return node & ~(Constants.SLOT_MAX << shiftBits);
    }
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @param weight The weight of of the node.
  /// Safely truncated to a 32-bit number,
  /// but this should never be called with an overflowing weight regardless.
  function setSlot(
    uint256 node,
    uint256 position,
    uint256 weight
  ) internal pure returns (uint256) {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Clear the `position`th slot like in `clearSlot()`.
      uint256 clearedNode = node & ~(Constants.SLOT_MAX << shiftBits);
      // Bitwise AND `weight` with `SLOT_MAX`
      // to clear all but the 32 least significant bits.
      //
      // Shift this left by `slotShift(position)` bits
      // to obtain a uint256 with all bits unset
      // except in the `position`th slot
      // which contains the 32-bit value of `weight`.
      uint256 shiftedWeight = (weight & Constants.SLOT_MAX) << shiftBits;
      // When we bitwise OR these together,
      // all other slots except the `position`th one come from the left argument,
      // and the `position`th gets filled with `weight` from the right argument.
      return clearedNode | shiftedWeight;
    }
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint256 node) internal pure returns (uint256 sum) {
    unchecked {
      sum = node & Constants.SLOT_MAX;
      // Iterate through each slot
      // by shifting `node` right in increments of 32 bits,
      // and adding the 32 least significant bits to the `sum`.
      uint256 newNode = node >> Constants.SLOT_WIDTH;
      while (newNode > 0) {
        sum += (newNode & Constants.SLOT_MAX);
        newNode = newNode >> Constants.SLOT_WIDTH;
      }
      return sum;
    }
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint256 node, uint256 index)
    internal
    pure
    returns (uint256 slot, uint256 newIndex)
  {
    unchecked {
      newIndex = index;
      uint256 newNode = node;
      uint256 currentSlotWeight = newNode & Constants.SLOT_MAX;
      while (newIndex >= currentSlotWeight) {
        newIndex -= currentSlotWeight;
        slot++;
        newNode = newNode >> Constants.SLOT_WIDTH;
        currentSlotWeight = newNode & Constants.SLOT_MAX;
      }
      return (slot, newIndex);
    }
  }
}

pragma solidity 0.8.17;

import "./Constants.sol";

library Position {
  // Return the last 3 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint256 a) internal pure returns (uint256) {
    return a & Constants.SLOT_POINTER_MAX;
  }

  // Return the parent of a position number
  function parent(uint256 a) internal pure returns (uint256) {
    return a >> Constants.SLOT_BITS;
  }

  // Return the location of the child of a at the given slot
  function child(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a << Constants.SLOT_BITS) | (s & Constants.SLOT_POINTER_MAX); // slot(s)
  }

  // Return the uint p as a flagged position uint:
  // the least significant 21 bits contain the position
  // and the 22nd bit is set as a flag
  // to distinguish the position 0x000000 from an empty field.
  function setFlag(uint256 p) internal pure returns (uint256) {
    return p | Constants.LEAF_FLAG;
  }

  // Turn a flagged position into an unflagged position
  // by removing the flag at the 22nd least significant bit.
  //
  // We shouldn't _actually_ need this
  // as all position-manipulating code should ignore non-position bits anyway
  // but it's cheap to call so might as well do it.
  function unsetFlag(uint256 p) internal pure returns (uint256) {
    return p & (~Constants.LEAF_FLAG);
  }
}