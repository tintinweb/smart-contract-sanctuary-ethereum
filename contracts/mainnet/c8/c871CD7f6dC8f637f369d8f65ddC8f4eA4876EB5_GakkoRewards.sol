//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IGakkoLoot.sol";
import "./IGakkoRewards.sol";
import "./IStakingProvider.sol";
import "../Common/Delegated.sol";


contract GakkoRewards is Delegated, IGakkoRewards{
  event LootAwarded(uint256 indexed tokenId, uint16 level);
  event LootClaimed(uint256 indexed tokenId, uint16 level);

  error AlreadyClaimed();
  error IncorrectOwner();
  error LengthMistmatch();
  error NonexistentLevel();

  struct LootConfig{
    uint16 maxSupply;
    bool isActive;
  }

  bool public isClaimsEnabled;
  bool public isRewardsEnabled;
  string public name = "Gakko Rewards";
  uint16 public totalSupply;
  uint32[] public rewardTimes;
  IStakingProvider public stakingProvider;
  mapping(uint16 => Token[]) public loot;
  mapping(uint16 => IGakkoLoot) public lootProviders;

  constructor()
    Delegated()
  // solhint-disable-next-line no-empty-blocks
  {}


  //nonpayable - public
  function claimLoot( uint16[] calldata tokenIds, uint16[] calldata levels ) external{
    if(!isClaimsEnabled) return;

    if(tokenIds.length != levels.length) revert LengthMistmatch();

    uint256 length = tokenIds.length;
    address[] memory owners = stakingProvider.ownerOfAll(tokenIds);
    for( uint256 i = 0; i < length; ++i ){
      if(msg.sender != owners[i]) revert IncorrectOwner();

      uint16 level = levels[i];
      uint16 tokenId = tokenIds[i];
      if(level >= loot[tokenId].length) revert NonexistentLevel();

      Token storage token = loot[tokenId][level];
      if(token.isClaimed) revert AlreadyClaimed();

      token.isClaimed = true;
      lootProviders[token.level].handleClaim(msg.sender, token);

      emit LootClaimed(tokenId, level);
    }
  }


  //nonpayable - delegate callbacks
  function handleRewards( StakeSummary[] calldata claims ) external onlyDelegates{
    if( !isRewardsEnabled ) return;


    StakeSummary memory claim;
    for( uint256 i = 0; i < claims.length; ++i ){
      claim = claims[i];

      uint32 check;
      uint16 level = uint16(loot[claim.tokenId].length);
      for(; level < rewardTimes.length; ++level ){
        check = rewardTimes[ level ];
        if( claim.initial < check && check <= claim.total ){
          loot[claim.tokenId].push(Token(
            claim.tokenId,
            level,
            false
          ));

          emit LootAwarded( claim.tokenId, level );
        }
        else
          break;
      }
    }
  }

  // solhint-disable-next-line no-empty-blocks
  function handleStakes( uint16[] calldata tokenIds ) external onlyDelegates{}


  //nonpayable - owner
  function mintTo(uint16[] calldata tokenIds, uint16[] calldata levels ) external onlyDelegates{
    if(tokenIds.length != levels.length) revert LengthMistmatch();

    uint256 length = tokenIds.length;
    for(uint256 t = 0; t < length; ++t ){
      uint16 tokenId = tokenIds[t];
      uint16 level = uint16(loot[ tokenId ].length);
      for(; level < levels[t]; ++level ){
        loot[tokenId].push(Token(
          tokenId,
          level,
          false
        ));
      }
    }
  }

  function setEnabled(bool claimsEnabled, bool rewardsEnabled) external onlyDelegates{
    isClaimsEnabled = claimsEnabled;
    isRewardsEnabled = rewardsEnabled;
  }

  function setLootProvider(uint16 level, IGakkoLoot provider) external onlyDelegates{
    lootProviders[level] = provider;
  }

  //set newTimes first, then increment maxTokenClaims
  function setRewardTimes(uint32[] calldata newTimes) external onlyDelegates{
    require( newTimes.length >= rewardTimes.length, "newTimes must be more than rewardTimes" );

    uint i = 0;
    for( ; i < rewardTimes.length; ++i ){
      rewardTimes[i] = newTimes[i];
    }

    for( ; i < newTimes.length; ++i ){
      rewardTimes.push( newTimes[i] );
    }
  }

  function setStakingProvider( IStakingProvider provider ) external onlyDelegates {
    stakingProvider = provider;
  }


  //view
  function getTokensLoot(uint16[] calldata tokenIds) external view returns(Token[] memory tokensLoot){
    uint256 totalLoot = 0;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      //Token[] memory x = loot[tokenIds[i]];
      totalLoot += loot[tokenIds[i]].length;
    }

    uint256 index = 0;
    Token[] memory loots;
    tokensLoot = new Token[](totalLoot);
    for(uint256 i = 0; i < tokenIds.length; ++i){
      loots = loot[tokenIds[i]];
      for(uint256 j = 0; j < loots.length; ++j){
        tokensLoot[index++] = loots[j];
      }
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct StakeInfo{
  uint16 tokenId;
  uint32 accrued;
  uint32 pending;
  bool isStaked;
}

interface IStakingProvider {
  function baseAward() external view returns(uint32);
  function getRewardHandler() external view returns(address);
  function getStakeInfo(uint16[] calldata tokenIds) external view returns(StakeInfo[] memory infos);
  function isStakeable() external view returns(bool);
  function ownerOfAll(uint16[] calldata tokenIds) external view returns(address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct StakeSummary{
  uint32 initial; //32
  uint32 total;   //64
  uint16 tokenId; //80
}

interface IGakkoRewards{
  function handleRewards(StakeSummary[] calldata claims) external;
  function handleStakes(uint16[] calldata tokenIds) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

  struct Token{
    uint16 parentId;
    uint16 level;
    bool isClaimed;
  }

interface IGakkoLoot{
  function handleClaim(address owner, Token calldata claim) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;

  modifier onlyDelegates {
    require(_delegates[msg.sender], "Invalid delegate" );
    _;
  }

  constructor()
    Ownable(){
    setDelegate(owner(), true);
  }

  //onlyOwner
  function isDelegate(address addr) external view onlyOwner returns(bool) {
    return _delegates[addr];
  }

  function setDelegate(address addr, bool isDelegate_) public onlyOwner {
    _delegates[addr] = isDelegate_;
  }

  function transferOwnership(address newOwner) public virtual override onlyOwner {
    setDelegate(newOwner, true);
    super.transferOwnership(newOwner);
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