// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IOracle {
  function randomNumber(uint256 max, uint256 seed) external view returns (uint256);
}

interface INFT {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRobotikz is INFT {
  function mintFromMetaRage(address recipient) external returns (bool);
}

interface IToken {
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function mint(address to, uint256 amount) external;
}

error GamePaused();
error CollectionAlreadyExists();
error CollectionNotFound();
error WrongOwner();
error AlreadyClaimed();
error ClaimsDepleted();
error AttackerCollectionNotFound();
error InsufficientBalance();
error OpponentCollectionNotFound();
error RewardsDepleted();

contract MetaRage is Ownable, ReentrancyGuard {
  uint256 public totalFighters = 0;
  uint256 public totalClaims = 0 ether;
  uint256 public totalRewards = 0 ether;

  bool public paused = true;

  mapping(uint256 => bool) public claims;
  mapping(address => Collection) public collections;

  IOracle public oracleContract;
  IRobotikz public robotikzContract;
  IToken public metapondContract;

  struct Config {
    uint256 entryFee;
    uint256 chance;
    uint256 perfectOutcome;
    uint256 perfectReward;
    uint256 executionOutcome;
    uint256 executionReward;
    uint256 victoryOutcome;
    uint256 victoryReward;
    uint256 maxClaims;
    uint256 maxRewards;
  }
  
  Config public config = Config(
    100 ether, 
    100, 
    98, 
    12000 ether,
    80, 
    6000 ether,
    50,
    3000 ether,
    200_000_000 ether,
    300_000_000 ether
  );

  struct Collection {
    bool active;
    string symbol;
    address contractAddress;
    address currency;
    uint256 supply;
    uint256 startIndex;
    uint256 allocation;
  }

  struct Fighter {
    address collection;
    uint256 tokenId;
  }

  event Fight(
    address indexed attacker, 
    address indexed opponent,
    uint256 indexed outcome
  );

  event Claim(
    address indexed wallet,
    uint256 indexed amount
  );

  modifier unlessPaused {
    if (paused) {
      revert GamePaused();
    }
    _;
  }

  constructor(
    address oracleContractAddress,
    address cryptoPolzContractAddress,
    address polzillaContractAddress,
    address eggzillaContractAddress,
    address kongzillaContractAddress,
    address robotikzContractAddress,
    address eggzContractAddress,
    address rageContractAddress,
    address metapondContractAddress
  ) {
    setOracleContract(oracleContractAddress);
    setRobotikzContract(robotikzContractAddress);
    setMetapondContract(metapondContractAddress);
    
    addCollection(true, "CRYPTOPOLZ", cryptoPolzContractAddress, eggzContractAddress, 9696, 5000 ether);
    addCollection(true, "POLZILLA", polzillaContractAddress, eggzContractAddress, 9696, 3000 ether);
    addCollection(true, "EGGZILLA", eggzillaContractAddress, eggzContractAddress, 15555, 1000 ether);
    addCollection(true, "KONGZILLA", kongzillaContractAddress, rageContractAddress, 6969, 10000 ether);
    addCollection(true, "ROBOTIKZ", robotikzContractAddress, metapondContractAddress, 4242, 0 ether);
  }

  function flipPause() external onlyOwner {
    paused = !paused;
  }
  
  function setConfig(
    uint256 entryFee,
    uint256 chance,
    uint256 perfectOutcome,
    uint256 perfectReward,
    uint256 executionOutcome,
    uint256 executionReward,
    uint256 victoryOutcome,
    uint256 victoryReward,
    uint256 maxClaims,
    uint256 maxRewards
  ) public onlyOwner nonReentrant {
    require (chance > 0);
    require (perfectOutcome > executionOutcome);
    require (perfectReward > 0);
    require (executionOutcome > victoryOutcome);
    require (executionReward > 0);
    require (victoryOutcome > 0);
    require (victoryReward > 0);

    config = Config(
      entryFee,
      chance,
      perfectOutcome,
      perfectReward,
      executionOutcome,
      executionReward,
      victoryOutcome,
      victoryReward,
      maxClaims,
      maxRewards
    );
  }

  function addCollection(
    bool active,
    string memory symbol,
    address contractAddress,
    address currency,
    uint256 supply,
    uint256 allocationAmount
  ) public onlyOwner nonReentrant {
    if (collectionExists(contractAddress)) {
      revert CollectionAlreadyExists();
    }

    Collection memory collection = Collection(
      active,
      symbol,
      contractAddress,
      currency,
      supply,
      0,
      allocationAmount
    );

    collection.startIndex = totalFighters;
    collections[collection.contractAddress] = collection;
    totalFighters += collection.supply;
  }

  function deactivateCollection(address contractAddress) public onlyOwner nonReentrant {
    Collection memory collection = collections[contractAddress];
    collection.active = false;
    collections[contractAddress] = collection;
  }

  function collectionExists(address contractAddress) public view returns (bool) {
    return collections[contractAddress].supply > 0;
  }

  function setOracleContract(address contractAddress) public onlyOwner {
    oracleContract = IOracle(contractAddress);
  }

  function setRobotikzContract(address contractAddress) public onlyOwner {
    robotikzContract = IRobotikz(contractAddress);
  }

  function setMetapondContract(address contractAddress) public onlyOwner {
    metapondContract = IToken(contractAddress);
  }

  function getFighterId(address collection, uint256 tokenId) public view returns (uint256) {
    unchecked {
      return collections[collection].startIndex + tokenId;
    }
  }

  function claimable(Fighter[] memory fighters) public view returns (uint256) {
    uint256 f = fighters.length;
    uint256 amount = 0 ether;

    for (uint256 i; i < f; i++) {
      unchecked {
        amount += _claimable(fighters[i]);
      }
    }

    if ((totalClaims + amount) > config.maxClaims) {
      return 0 ether;
    }

    return amount;
  }

  function _claimable(Fighter memory fighter) internal view returns (uint256) {
    if (!collections[fighter.collection].active) {
      return 0 ether;
    }
    
    uint256 fighterId = getFighterId(fighter.collection, fighter.tokenId);

    if (claims[fighterId] == true) {
      return 0 ether;
    }

    return collections[fighter.collection].allocation;
  }

  function claim(Fighter[] memory fighters) public unlessPaused nonReentrant returns (uint256) {
    uint256 f = fighters.length;
    uint256 amount = 0 ether;

    unchecked {
      for (uint256 i; i < f; i++) {
        amount += _claim(fighters[i]);
      }
    }

    uint256 nextTotalClaimed = totalClaims + amount;

    if (nextTotalClaimed > config.maxClaims) {
      revert ClaimsDepleted();
    }

    totalClaims = nextTotalClaimed;

    metapondContract.mint(msg.sender, amount);

    emit Claim(msg.sender, amount);

    return amount;
  }

  function _claim(Fighter memory fighter) internal returns (uint256) {
    if (!collections[fighter.collection].active) {
      return 0 ether;
    }
    
    if (INFT(fighter.collection).ownerOf(fighter.tokenId) != msg.sender) {
      return 0 ether;
    }

    uint256 fighterId = getFighterId(fighter.collection, fighter.tokenId);

    if (claims[fighterId]) {
      return 0 ether;
    }
    
    claims[fighterId] = true;

    return collections[fighter.collection].allocation;
  }

  function fight(Fighter memory attacker, Fighter[] memory opponents) public unlessPaused nonReentrant {
    if (!collections[attacker.collection].active) {
      revert AttackerCollectionNotFound();
    }

    if (INFT(attacker.collection).ownerOf(attacker.tokenId) != msg.sender) {
      revert WrongOwner();
    }
    
    uint256 entryFee = config.entryFee * opponents.length;

    if (entryFee > IToken(collections[attacker.collection].currency).balanceOf(msg.sender)) {
      revert InsufficientBalance();
    }

    uint256 fights = opponents.length;
    uint256 rewards = 0 ether;

    while (fights > 0) {
      unchecked {
        --fights;
      }

      if (!collections[opponents[fights].collection].active) {
        revert OpponentCollectionNotFound();
      }
      
      unchecked {
        rewards += _fight(opponents[fights]);
      }
    }

    unchecked {
      if (rewards > 0) {
        uint256 nextTotalRewards = totalRewards + rewards;

        if (nextTotalRewards > config.maxRewards) {
          revert RewardsDepleted();
        }

        totalRewards = nextTotalRewards;

        metapondContract.mint(msg.sender, rewards);
      }
    }

    IToken(collections[attacker.collection].currency)
      .transferFrom(msg.sender, address(this), entryFee);
  }

  function _fight(Fighter memory opponent) internal returns (uint256) {
    address otherPlayer = INFT(opponent.collection).ownerOf(opponent.tokenId); 
    address winner = msg.sender;
    uint256 reward = 0 ether;
    uint256 outcome = oracleContract.randomNumber(
      config.chance, 
      getFighterId(opponent.collection, opponent.tokenId)
    );
    
    if (outcome >= config.perfectOutcome) {
      robotikzContract.mintFromMetaRage(winner);
      reward = config.perfectReward;
    } else if (outcome >= config.executionOutcome && outcome < config.perfectOutcome) {
      reward = config.executionReward;
    } else if (outcome >= config.victoryOutcome && outcome < config.executionOutcome) {
      reward = config.victoryReward;
    } else {
      winner = otherPlayer;
    }

    emit Fight(msg.sender, otherPlayer, outcome);

    return reward;
  }

  function withdraw(IToken token, address recipient) external onlyOwner nonReentrant {
    token.transfer(recipient, token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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