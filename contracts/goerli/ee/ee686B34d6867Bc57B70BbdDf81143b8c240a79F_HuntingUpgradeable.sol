// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFnG, IFBX} from "./interfaces/Interfaces.sol";

contract HuntingUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using EnumerableSet for EnumerableSet.UintSet;

  /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

  struct StakeFreak {
    uint256 tokenId;
    uint256 lastClaimTime;
    address owner;
    uint256 species;
    uint256 ffIndex;
  }

  struct StakeCelestial {
    uint256 tokenId;
    address owner;
    uint256 value;
  }

  struct Epoch {
    uint256 favoredFreak;
    uint256 epochStartTime;
  }

  struct PoolConfig {
    uint256 guildSize;
    uint256 rate;
    uint256 minToExit;
  }


/*///////////////////////////////////////////////////////////////
                    Global STATE
   //////////////////////////////////////////////////////////////*/

  // reference to the FnG NFT contract
  IFnG public fngNFT;
  // reference to the $FBX contract for minting $FBX earnings
  IFBX public fbx;
  // maps tokenId to stake observatory
  mapping(uint256 => StakeCelestial) private observatory;
  // maps pool id to mapping of address to deposits
  mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _deposits;
  // maps pool id to mapping of token id to staked freak struct
  mapping(uint256 => mapping(uint256 => StakeFreak)) private stakingPools;
  // maps pool id to pool config
  mapping(uint256 => PoolConfig) public _poolConfig;
  // maps pool id to amount of freaks staked
  mapping(uint256 => uint256) private freaksStaked;
  // maps pool id to epoch struct
  mapping(uint256 => Epoch[]) private favors;
  // any rewards distributed when no celestials are staked
  uint256 private unaccountedRewards;
  // amount of $FBX earned so far
  uint256 public totalFBXEarned;
  // timestamp of last epcoh change
  uint256 private lastEpoch;
  // number of celestials staked at a give time
  uint256 public cCounter;
  // unclaimed FBX pool for hunting observatory
  uint256 public fbxPerCelestial;
  // emergency rescue to allow unstaking without any checks but without $FBX
  bool public rescueEnabled;


  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier changeFFEpoch() {
    if (block.timestamp - lastEpoch >= 72 hours) {
      uint256 rand = _rand(msg.sender);
      for (uint256 i = 0; i < 3; i++) {
        uint256 favoredFreak = (rand % 3) + 1;
        Epoch memory epoch = Epoch(favoredFreak, block.timestamp);
        favors[i].push(epoch);
        rand = uint256(keccak256(abi.encodePacked(msg.sender, rand)));
      }
      lastEpoch = block.timestamp;
    }
    _;
  }


  /*///////////////////////////////////////////////////////////////
                    INITIALIZER 
    //////////////////////////////////////////////////////////////*/


  function initialize(address _fng, address _fbx) public initializer {
    fngNFT = IFnG(_fng);
    fbx = IFBX(_fbx);
    // backupEpochSet();
    _pause();
    cCounter = 0;
    _poolConfig[0] = PoolConfig(1, 200 ether, 200 ether);
    _poolConfig[1] = PoolConfig(3, 300 ether, 1800 ether);
    _poolConfig[2] = PoolConfig(5, 400 ether, 6000 ether);
    freaksStaked[0] = 0;
    freaksStaked[1] = 0;
    freaksStaked[2] = 0;
    rescueEnabled = false;
    unaccountedRewards = 0;
  }


  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // returns config for specific pool
  function getPoolConfig(uint256 pool) external view returns (PoolConfig memory) {
    require(pool < 3, "pool not found");
    return _poolConfig[pool];
  }

  // returns total freaks staked in specific pool
  function getStakedFreaks(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return freaksStaked[pool];
  }

  // returns deposited tokens of an address for each hunting ground and observatory
  function depositsOf(address account)
    external
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    return (
      _deposits[0][account].values(),
      _deposits[1][account].values(),
      _deposits[2][account].values(),
      _deposits[3][account].values()
    );
  }

  // returns rewards for freaks currently staked in specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function calculateFBXRewards(uint256[] memory tokenIds, uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
    }
    return rewards;
  }

  // returns rewards for celestials currently staked in hunting observatory
  function calculateCelestialsRewards(uint256[] calldata tokenIds) external view returns (uint256 rewards) {
    rewards = 0;
    for (uint256 i; i < tokenIds.length; i++) {
      rewards += _calculateCelestialRewards(tokenIds[i]);
    }
    return rewards;
  }

  // returns current favored freak for specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function getFavoredFreak(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return favors[pool][favors[pool].length - 1].favoredFreak;
  }

  // returns list of all favored freaks of a specific pool since genesis
  function getFavoredFreaks(uint256 pool) external view returns (Epoch[] memory) {
    require(pool < 3, "pool not found");
    return favors[pool];
  }

  // emergency rescue function to transfer tokens from contract to owner based on specific pool
  function rescue(uint256[] calldata tokenIds, uint256 pool) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    require(pool <= 3, "Pool doesn't exist");
    if (pool == 3) {
      //observatory
      for (uint256 i = 0; i < tokenIds.length; i++) {
        require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
        delete observatory[tokenIds[i]];
        _deposits[pool][msg.sender].remove(tokenIds[i]);
        cCounter -= 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      }
    } else {
      uint256 newTotal = 0;
      for (uint256 l = 0; l < tokenIds.length; l++) {
        require(stakingPools[pool][tokenIds[l]].owner == msg.sender, "You don't own this token ser");
        delete stakingPools[pool][tokenIds[l]];
        _deposits[pool][msg.sender].remove(tokenIds[l]);
        newTotal += 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[l]);
      }
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
  }

  /*///////////////////////////////////////////////////////////////
                    STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function observe(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(!fngNFT.isFreak(tokenIds[i]), "CELESTIALS ONLY!!! You are not worthy FREAK!");
      observatory[tokenIds[i]] = StakeCelestial({tokenId: tokenIds[i], owner: msg.sender, value: fbxPerCelestial});
      _deposits[3][msg.sender].add(tokenIds[i]);
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      cCounter += 1;
    }
  }

  function hunt(uint256[] calldata tokenIds, uint256 pool) external changeFFEpoch nonReentrant whenNotPaused {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length % _poolConfig[pool].guildSize == 0, "incorrect amount of freaks");
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(fngNFT.isFreak(tokenIds[i]), "Can't get freaky without any freaks ser");
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
      _deposits[pool][msg.sender].add(tokenIds[i]);
      newTotal += 1;
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
    freaksStaked[pool] = freaksStaked[pool] + newTotal;
  }

  /*///////////////////////////////////////////////////////////////
                    CLAIM/UNSTAKE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // unstake or claim from multiple freaks in a specific pool
  function claimUnstake(
    uint256[] calldata tokenIds,
    uint256 pool,
    bool collectTax
  ) external changeFFEpoch nonReentrant {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length != 0, "can't claim no tokens");
    uint256 rewards = 0;
    require(tokenIds.length % _poolConfig[pool].guildSize == 0);
    if (collectTax == true) {
      rewards = _calculateManyFreakRewards(tokenIds, pool, false);
      _claimWithTax(rewards, pool, tokenIds);
    } else {
      rewards = _calculateManyFreakRewards(tokenIds, pool, true);
      _claimEvadeTax(rewards, pool, tokenIds);
    }
    require(rewards >= _poolConfig[pool].minToExit, "Not enough $FBX earned");
  }

  function unobserve(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant {
    uint256 newCounter = 0;
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      if (fbxPerCelestial != 0) {
        rewards += fbxPerCelestial - observatory[tokenIds[i]].value;
      } else {
        rewards += 0;
      }
      delete observatory[tokenIds[i]];
      _deposits[3][msg.sender].remove(tokenIds[i]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      newCounter += 1;
    }
    fbx.mint(msg.sender, rewards);
    totalFBXEarned += rewards;
    cCounter = cCounter - newCounter;
  }

  /*///////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _calculateManyFreakRewards(uint256[] memory tokenIds, uint256 pool, bool unstake) internal returns (uint256 owed) {
    uint256 rewards = 0;
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(stakingPools[pool][tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
      newTotal += 1;
    }
    if (unstake == true) {
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
    return rewards;
  }

  function _calculateCelestialRewards(uint256 tokenId) internal view returns (uint256 reward) {
    if (fbxPerCelestial != 0) {
      reward = fbxPerCelestial - observatory[tokenId].value;
    }
    if (fbxPerCelestial == 0) {
      reward = 0;
    }
    return reward;
  }

  function _calculateSingleFreakRewards(
    uint256 tokenId,
    uint256 pool,
    uint256 rate
  ) internal view returns (uint256 owed) {
    uint256 timestamp = stakingPools[pool][tokenId].lastClaimTime;
    if (timestamp == 0) {
      return 0;
    }
    uint256 species = stakingPools[pool][tokenId].species;
    uint256 duration = block.timestamp - timestamp;
    uint256 favoredDuration = 0;
    for (uint256 j = stakingPools[pool][tokenId].ffIndex; j < favors[pool].length; j++) {
      uint256 startTime;
      if (j == stakingPools[pool][tokenId].ffIndex) {
        startTime = stakingPools[pool][tokenId].lastClaimTime;
      } else {
        startTime = favors[pool][j].epochStartTime;
      }
      if (favors[pool][j].favoredFreak == species) {
        uint256 epochEndTime;
        if (favors[pool].length == j + 1) {
          epochEndTime = block.timestamp;
        } else {
          epochEndTime = favors[pool][j + 1].epochStartTime;
        }
        favoredDuration += epochEndTime - startTime;
      }
    }
    uint256 ffOwed = ((favoredDuration * (rate + 20 ether)) / 1 days);
    uint256 baseOwed = 0;
    if (duration - favoredDuration != 0) {
      baseOwed = (((duration - favoredDuration) * rate) / 1 days);
    }
    owed = ffOwed + baseOwed;
    return owed;
  }

  function _claimWithTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 celestialRewards;
    celestialRewards = rewards / 5;
    if (cCounter == 0) {
      unaccountedRewards += (celestialRewards);
      rewards = rewards - celestialRewards;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    } else {
      fbxPerCelestial += (unaccountedRewards + celestialRewards) / cCounter;
      rewards = rewards - celestialRewards;
      unaccountedRewards = 0;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 i; i < tokenIds.length; i++) {
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
    }
  }

  function _claimEvadeTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 rNum = _rand(msg.sender) % 100;
    if (rNum < 33) {
      if (cCounter == 0) {
        unaccountedRewards += rewards;
      } else {
        fbxPerCelestial += (unaccountedRewards + rewards) / cCounter;
        unaccountedRewards = 0;
      }
    } else {
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 j; j < tokenIds.length; j++) {
      _deposits[pool][msg.sender].remove(tokenIds[j]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[j]);
      delete stakingPools[pool][tokenIds[j]]; 
    }
  }

  function _rand(address acc) internal view returns (uint256) {
    bytes32 _entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, _entropySauce)));
  }

  /*///////////////////////////////////////////////////////////////
                   ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function setContracts(address _fngNFT, address _fbx) external onlyOwner {
    fngNFT = IFnG(_fngNFT);
    fbx = IFBX(_fbx);
  }

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * backup favored freak epoch changing function
   * in case it isn't triggered by claim/unstake function (unlikely)
   */
  function backupEpochSet() public changeFFEpoch onlyOwner {}

  /**
   * manually set rates for each pool
   */
  function setRates(
    uint256 _enclaveRate,
    uint256 _summitRate,
    uint256 _anoRate
  ) external onlyOwner {
    _poolConfig[0].rate = _enclaveRate;
    _poolConfig[1].rate = _summitRate;
    _poolConfig[2].rate = _anoRate;
  }

  /**
   * manually set minimum FBX required to exit each pool
   */
  function setMinExits(
    uint256 _minExitEnclave,
    uint256 _minExitSummit,
    uint256 _minExitAno
  ) external onlyOwner {
    _poolConfig[0].minToExit = _minExitEnclave;
    _poolConfig[1].minToExit = _minExitSummit;
    _poolConfig[2].minToExit = _minExitAno;
  }


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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Structs.sol";

interface MetadataHandlerLike {
  function getCelestialTokenURI(uint256 id, Celestial memory character) external view returns (string memory);

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory);
}

interface InventoryCelestialsLike {
  function getAttributes(Celestial memory character, uint256 id) external pure returns (bytes memory);

  function getImage(uint256 id) external view returns (bytes memory);
}

interface InventoryFreaksLike {
  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory);

  function getImage(Freak memory character) external view returns (bytes memory);
}

interface IFnG {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory);

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external;

  function burn(uint tokenId) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface ICKEY {
  function ownerOf(uint256 tokenId) external returns (address);
}

interface IVAULT {
  function depositsOf(address account) external view returns (uint256[] memory);
  function _depositedBlocks(address account, uint256 tokenId) external returns(uint256);
}

interface ERC20Like {
  function balanceOf(address from) external view returns (uint256 balance);

  function burn(address from, uint256 amount) external;

  function mint(address from, uint256 amount) external;

  function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) external;

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}

interface ERC721Like {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function transfer(address to, uint256 id) external;

  function ownerOf(uint256 id) external returns (address owner);

  function mint(address to, uint256 tokenid) external;
}

interface PortalLike {
  function sendMessage(bytes calldata) external;
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
pragma solidity 0.8.11;

struct Freak {
  uint8 species;
  uint8 body;
  uint8 armor;
  uint8 mainHand;
  uint8 offHand;
  uint8 power;
  uint8 health;
  uint8 criticalStrikeMod;

}
struct Celestial {
  uint8 healthMod;
  uint8 powMod;
  uint8 cPP;
  uint8 cLevel;
}

struct Layer {
  string name;
  string data;
}

struct LayerInput {
  string name;
  string data;
  uint8 layerIndex;
  uint8 itemIndex;
}