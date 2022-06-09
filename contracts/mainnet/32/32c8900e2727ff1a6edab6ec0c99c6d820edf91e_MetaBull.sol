//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error CallerBlacklisted();
error CallerNotTokenOwner();
error CallerNotTokenStaker();
error StakingNotActive();
error ZeroEmissionRate();

/**
 * Interfaces astrobull contract
 */
interface ISUPER1155 {
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function groupBalances(uint256 groupId, address from)
    external
    view
    returns (uint256);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;
}

/**
 * Interfaces old grill contract
 */
interface IGRILL {
  struct Stake {
    bool status;
    address staker;
    uint256 timestamp;
  }

  function getStake(uint256 _tokenId)
    external
    view
    returns (Stake memory _stake);

  function getIdsOfAddr(address _operator)
    external
    view
    returns (uint256[] memory _addrStakes);
}

/**
 * @title Grill2.0
 * @author Matt Carter, degendeveloper.eth
 * 6 June, 2022
 *
 * The purpose of this contract is to optimize gas consumption when adding new stakes and
 * removing previous stakes from the initial grill contract @ 0xE11AF478aF241FAb926f4c111d50139Ae003F7fd.
 *
 * Users will use this new grill contract when adding and removing stakes. This new contract
 * is also responsible for counting emission tokens and setting new emission rates.
 *
 * This contract is whitelisted to move the first grill's tokens via proxy registry in the super1155 contract.
 *
 * This contract should be set as the `proxyRegistryAddress` in the parent contract. This
 * allows the new grill to move tokens on behalf of the old grill.
 */
contract Grill2 is Ownable, ERC1155Holder {
  using Counters for Counters.Counter;
  uint256 internal constant MAX_INT = 2**256 - 1;
  /// contract instances ///
  ISUPER1155 public constant Parent =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  IGRILL public immutable OldGrill;
  /// the number of times the emission rate changes ///
  Counters.Counter internal emChanges;
  /// is adding stakes allowed ///
  bool public isStaking = true;
  /// the number of stakes added & removed by each account (this contract) ///
  mapping(address => Counters.Counter) internal stakesAddedPerAccount;
  mapping(address => Counters.Counter) internal stakesRemovedPerAccount;
  /// each Stake by tokenId (this contract) ///
  mapping(uint256 => Stake) public stakeStorage;
  /// each tokenId by index for an account (this contract) ///
  mapping(address => mapping(uint256 => uint256)) public accountStakes;
  /// each Emission by index (this contract) ///
  mapping(uint256 => Emission) public emissionStorage;
  /// the number of emission tokens earned be each account from removed stakes ///
  mapping(address => uint256) public unstakedClaims;
  /// accounts that can not add new stakes ///
  mapping(address => bool) public blacklist;
  /// list of new proxies for Parent tokens ///
  mapping(address => address) public proxies;

  /**
   * Stores information for an emission change
   * @param rate The number of seconds to earn 1 emission token
   * @param timestamp The block.timestamp this emission rate is set
   */
  struct Emission {
    uint256 rate;
    uint256 timestamp;
  }

  /**
   * Stores information for a stake
   * @param staker The address who creates this stake
   * @param timestamp The block.timestamp this stake is created
   * @param accountSlot The index for this stake in `accountStakes`
   */
  struct Stake {
    address staker;
    uint256 timestamp;
    uint256 accountSlot;
  }

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Initializes contract instances and sets the initial emission rate
   * @param _grillAddr The address for the first grill contract
   * @notice `1652054400` is Mon, 09 May 2022 00:00:00 GMT
   * @notice '3600 * 24 * 45' is the number of seconds in 45 days
   */
  constructor(address _grillAddr) {
    OldGrill = IGRILL(_grillAddr);
    emissionStorage[emChanges.current()] = Emission(3600 * 24 * 45, 1652054400);
  }

  /// ============ OWNER ============ ///

  /**
   * Sets a proxy transferer for `account`s tokens
   * @param account The address whose tokens to move
   * @param operator The address being proxied as an approved operator for `account`
   * @notice The team will use this contract as a proxy for old grill tokens
   */
  function setProxyForAccount(address account, address operator)
    public
    onlyOwner
  {
    proxies[account] = operator;
  }

  /**
   * Removes a proxy transferer for `account`s tokens
   * @param account The address losing its proxy transferer
   */
  function removeProxyForAccount(address account) public onlyOwner {
    delete proxies[account];
  }

  /**
   * Allows/unallows the addition of new stakes
   */
  function toggleStaking() public onlyOwner {
    isStaking = !isStaking;
  }

  /**
   * Allows/unallows an account to add new stakes
   * @param account The address to set status for
   * @param status The status being set
   * @notice A staker is always able to remove their stakes regardless of blacklist status
   */
  function blacklistAccount(address account, bool status) public onlyOwner {
    blacklist[account] = status;
  }

  /**
   * Stops emission token counting by setting an emission rate of the max-int number of seconds
   * @notice No tokens can be earned with an emission rate this long
   * @notice To continue emissions counting, the owner must set a new emission rate
   */
  function pauseEmissions() public onlyOwner {
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sets a new rate for earning emission tokens
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   */
  function setEmissionRate(uint256 _seconds) public onlyOwner {
    _setEmissionRate(_seconds);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Stakes an array of tokenIds with this contract to earn emission tokens
   * @param tokenIds An array of tokenIds to stake
   * @param amounts An array of amounts of each tokenId to stake
   * @notice Caller must `setApprovalForAll()` to true in the parent contract using this contract's address
   * before it can move their tokens
   */
  function addStakes(uint256[] memory tokenIds, uint256[] memory amounts)
    public
  {
    if (!isStaking) {
      revert StakingNotActive();
    }
    if (blacklist[msg.sender]) {
      revert CallerBlacklisted();
    }
    /// @dev verifies caller owns each token ///
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 _tokenId = tokenIds[i];
      if (Parent.balanceOf(msg.sender, _tokenId) == 0) {
        revert CallerNotTokenOwner();
      }
      /// @dev sets contract state ///
      _addStake(msg.sender, _tokenId);
    }
    /// @dev transfers tokens from caller to this contract ///
    Parent.safeBatchTransferFrom(
      msg.sender,
      address(this),
      tokenIds,
      amounts,
      "0x00"
    );
  }

  /**
   * Removes an array of tokenIds staked in this contract and/or the old one
   * @param oldTokenIds The tokenIds being unstaked from the old contract
   * @param oldAmounts The number of each token being unstaked
   * @param newTokenIds The tokenIds being unstaked from this contract
   * @param newAmounts The number of each token being unstaked
   */
  function removeStakes(
    uint256[] memory oldTokenIds,
    uint256[] memory oldAmounts,
    uint256[] memory newTokenIds,
    uint256[] memory newAmounts
  ) public {
    if (oldTokenIds.length > 0) {
      /// @dev verifies caller staked each token ///
      for (uint256 i = 0; i < oldTokenIds.length; ++i) {
        uint256 _tokenId = oldTokenIds[i];
        IGRILL.Stake memory _thisStake = OldGrill.getStake(_tokenId);
        if (_thisStake.staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        /// @dev increments emissions earned for caller ///
        unstakedClaims[msg.sender] += countEmissions(_thisStake.timestamp);
      }
      /// @dev transfers tokens from old contract to caller ///
      Parent.safeBatchTransferFrom(
        address(OldGrill),
        msg.sender,
        oldTokenIds,
        oldAmounts,
        "0x00"
      );
    }
    if (newTokenIds.length > 0) {
      /// @dev verifies caller staked each token ///
      for (uint256 i = 0; i < newTokenIds.length; ++i) {
        uint256 _tokenId = newTokenIds[i];
        if (stakeStorage[_tokenId].staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        /// @dev sets contract state ///
        _removeStake(_tokenId);
      }
      /// @dev transfers tokens from this contract to caller ///
      Parent.safeBatchTransferFrom(
        address(this),
        msg.sender,
        newTokenIds,
        newAmounts,
        "0x00"
      );
    }
  }

  /**
   * Counts the number of emission tokens a timestamp has earned
   * @param _timestamp The timestamp a token was staked
   * @return _c The number of emission tokens a stake has earned since `_timestamp`
   */
  function countEmissions(uint256 _timestamp) public view returns (uint256 _c) {
    /// @dev if timestamp is before contract creation or later than now return 0 ///
    if (
      _timestamp < emissionStorage[0].timestamp || _timestamp > block.timestamp
    ) {
      _c = 0;
    } else {
      /**
       * @dev finds the most recent emission rate _timestamp comes after
       * Example:
       *  emChanges: *0...........1............2.....................3...........*
       *  timeline:  *(deploy)....x............x.....(timestamp).....x......(now)*
       */
      uint256 minT;
      for (uint256 i = 1; i <= emChanges.current(); ++i) {
        if (emissionStorage[i].timestamp < _timestamp) {
          minT += 1;
        }
      }
      /// @dev counts all emissions earned starting from minT -> now  ///
      for (uint256 i = minT; i <= emChanges.current(); ++i) {
        uint256 tSmall = emissionStorage[i].timestamp;
        uint256 tBig = emissionStorage[i + 1].timestamp; // 0 if not set yet
        if (i == minT) {
          tSmall = _timestamp;
        }
        if (i == emChanges.current()) {
          tBig = block.timestamp;
        }
        _c += (tBig - tSmall) / emissionStorage[i].rate;
      }
    }
  }

  /// ============ INTERNAL ============ ///

  /**
   * Helper function that sets contract state when adding a stake to this contract
   * @param staker The address to make the stake for
   * @param tokenId The tokenId being staked
   */
  function _addStake(address staker, uint256 tokenId) internal {
    /// @dev increments slots filled by staker ///
    stakesAddedPerAccount[staker].increment();
    /// @dev fills new slot (account => index => tokenId) ///
    accountStakes[staker][stakesAddedPerAccount[staker].current()] = tokenId;
    /// @dev add new stake to storage ///
    stakeStorage[tokenId] = Stake(
      staker,
      block.timestamp,
      stakesAddedPerAccount[staker].current()
    );
  }

  /**
   * Helper function that sets contract state when removing a stake from this contract
   * @param tokenId The tokenId being un-staked
   * @notice This function is not called when removing stakes from the old contract
   */
  function _removeStake(uint256 tokenId) internal {
    /// @dev copies the stake being removed ///
    Stake memory _thisStake = stakeStorage[tokenId];
    /// @dev increments slots emptied by staker ///
    stakesRemovedPerAccount[_thisStake.staker].increment();
    /// @dev increments emissions earned for removing this stake ///
    unstakedClaims[_thisStake.staker] += countEmissions(_thisStake.timestamp);
    /// @dev empty staker's slot (account => index => 0) ///
    delete accountStakes[_thisStake.staker][_thisStake.accountSlot];
    /// @dev removes stake from storage ///
    delete stakeStorage[tokenId];
  }

  /**
   * Helper function that sets contract state when emission changes occur
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   * @notice The emission rate cannot be 0 seconds
   */
  function _setEmissionRate(uint256 _seconds) private {
    if (_seconds == 0) {
      revert ZeroEmissionRate();
    }
    emChanges.increment();
    emissionStorage[emChanges.current()] = Emission(_seconds, block.timestamp);
  }

  /**
   * Helper function that gets the number of stakes an account has active with this contract
   * @param account The address to lookup
   * @return _active The number stakes
   */
  function _activeStakesCountPerAccount(address account)
    internal
    view
    returns (uint256 _active)
  {
    _active =
      stakesAddedPerAccount[account].current() -
      stakesRemovedPerAccount[account].current();
  }

  /**
   * Helper function that gets the number of stakes an account has active with the old contract
   * @param account The address to lookup
   * @return _active The number of stakes not yet removed from the old contract
   */
  function _activeStakesCountPerAccountOld(address account)
    internal
    view
    returns (uint256 _active)
  {
    uint256[] memory oldStakes = OldGrill.getIdsOfAddr(account);
    for (uint256 i = 0; i < oldStakes.length; ++i) {
      if (Parent.balanceOf(address(OldGrill), oldStakes[i]) == 1) {
        _active += 1;
      }
    }
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets tokenIds for `account`s active stakes in this contract
   * @param account The address to lookup
   * @return _ids Array of tokenIds
   */
  function stakedIdsPerAccount(address account)
    public
    view
    returns (uint256[] memory _ids)
  {
    _ids = new uint256[](_activeStakesCountPerAccount(account));
    /// @dev finds all slots still filled ///
    uint256 found;
    for (uint256 i = 1; i <= stakesAddedPerAccount[account].current(); ++i) {
      if (accountStakes[account][i] != 0) {
        _ids[found++] = accountStakes[account][i];
      }
    }
  }

  /**
   * Gets tokenIds for `account`s active stakes in the old contract
   * @param account The address to lookup
   * @return _ids Array of tokenIds
   */
  function stakedIdsPerAccountOld(address account)
    public
    view
    returns (uint256[] memory _ids)
  {
    /// @dev gets all tokenIds account had staked ///
    uint256[] memory oldStakes = OldGrill.getIdsOfAddr(account);
    /// @dev finds all tokenIds still active in old contract ///
    _ids = new uint256[](_activeStakesCountPerAccountOld(account));
    uint256 found;
    for (uint256 i = 0; i < oldStakes.length; ++i) {
      if (Parent.balanceOf(address(OldGrill), oldStakes[i]) == 1) {
        _ids[found++] = oldStakes[i];
      }
    }
  }

  /**
   * Gets the total number of emission changes to date
   * @return _changes The current number of changes to emission rates
   */
  function emissionChanges() external view returns (uint256 _changes) {
    _changes = emChanges.current();
  }

  /**
   * Gets the number of emission tokens `account` has earned from their active stakes
   * @param account The address to lookup
   * @return _earned The number of claims
   * @notice Uses stakes from new and old contract
   */
  function stakedClaims(address account) public view returns (uint256 _earned) {
    /// @dev counts emissions for each active stake in this contract ///
    uint256[] memory ownedIds = stakedIdsPerAccount(account);
    for (uint256 i; i < ownedIds.length; ++i) {
      _earned += countEmissions(stakeStorage[ownedIds[i]].timestamp);
    }
    /// @dev counts emissions for each active stake in old contract ///
    uint256[] memory ownedIdsOld = stakedIdsPerAccountOld(account);
    for (uint256 i; i < ownedIdsOld.length; ++i) {
      _earned += countEmissions(OldGrill.getStake(ownedIdsOld[i]).timestamp);
    }
  }

  /**
   * Gets the number of emission tokens `account` has earned from their active and removed stakes
   * @param account The address to lookup
   * @return _earned The number of emissions _operator has earned from all past and current stakes
   * @notice Uses stakes from new and old contract
   */
  function totalClaims(address account)
    external
    view
    returns (uint256 _earned)
  {
    _earned = unstakedClaims[account] + stakedClaims(account);
  }

  /**
   * Gets the Stake object from this grill contract
   * @param tokenId The tokenId to get stake for
   * @return _s The Stake object
   */
  function stakeStorageGetter(uint256 tokenId)
    public
    view
    returns (Stake memory _s)
  {
    _s = stakeStorage[tokenId];
  }

  /**
   * Gets the Stake object from the old grill contract
   * @param tokenId The tokenId to get stake for
   * @return _og The old Stake object
   */
  function stakeStorageOld(uint256 tokenId)
    public
    view
    returns (IGRILL.Stake memory _og)
  {
    _og = OldGrill.getStake(tokenId);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Grill2.sol";

error BurningNotActive();
error ClaimingNotActive();
error CallerIsNotABurner();
error InsufficientClaimsRemaining();

/**
 * @title Burgers
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract is for accounts to claim emission tokens (burgers) from their grill stakes.
 * Burgers have a `tokenId` of 1 and are burnable by owner-set `burner` addresses.
 */
contract Burger is ERC1155, Ownable {
  using Strings for uint256;
  /// contract instances ///
  Grill2 public immutable TheGrill;
  Grill2 public SpecialGrill;
  /// is claiming/burning/special grill active ///
  bool public isClaiming = false;
  bool public isBurning = false;
  bool public isSpecial = false;
  /// the number of burgers minted/burned ///
  uint256 public totalMints;
  uint256 public totalBurns;
  /// addresses allowed to burn burgers ///
  mapping(address => bool) public burners;
  /// the number of claims used by each account ///
  mapping(address => uint256) public claimsUsed;
  /// the number of burgers burned by each account ///
  mapping(address => uint256) public accountBurns;
  /// the number of burgers burned by each burner ///
  mapping(address => uint256) public burnerBurns;

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Sets the initial base URI and address for the grill
   * @param _URI The baseURI for each token
   * @param aGrill The address of the astro grill contract
   */
  constructor(string memory _URI, address aGrill) ERC1155(_URI) {
    TheGrill = Grill2(aGrill);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Gets the total number of burgers `account` has earned from the grill(s)
   * @param account The address to lookup
   * @return quantity The number of claims
   */
  function _totalClaimsEarned(address account)
    internal
    view
    returns (uint256 quantity)
  {
    quantity += TheGrill.totalClaims(account);
    /// @dev additionally counts special grill stakes ///
    if (isSpecial) {
      quantity += SpecialGrill.totalClaims(account);
    }
  }

  /// ============ OWNER ============ ///

  /**
   * Sets the new base URI for tokens
   * @param _URI The new base URI
   * @notice Uses the format: baselink.com/{}.json
   */
  function setURI(string memory _URI) public onlyOwner {
    _setURI(_URI);
  }

  /**
   * Toggles if claiming tokens is allowed
   */
  function toggleClaiming() public onlyOwner {
    isClaiming = !isClaiming;
  }

  /**
   * Toggles if burning tokens is allowed
   */
  function toggleBurning() public onlyOwner {
    isBurning = !isBurning;
  }

  /**
   * Approve an address to burn burgers
   * @param account The burner address
   * @param status The status of the approval
   * @notice A burner should be a contract address that correctly handles the burning of an operators tokens
   */
  function setBurner(address account, bool status) public onlyOwner {
    burners[account] = status;
  }

  /**
   * Mints `quantity` burgers to `account` without restrictions
   * @param quantity The number of tokens to mint
   * @param account The address to mint the tokens to
   */
  function ownerMint(uint256 quantity, address account) public onlyOwner {
    _mint(account, 1, quantity, "0x00");
    totalMints += quantity;
  }

  /**
   * Toggles if the special grill is running
   */
  function toggleSpecial() public onlyOwner {
    isSpecial = !isSpecial;
  }

  /**
   * Sets the special grill interface
   * @param aGrill The address of the special grill
   */
  function setSpecial(address aGrill) public onlyOwner {
    SpecialGrill = Grill2(aGrill);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Mints `quantity` burgers to caller
   * @param quantity The number of burgers caller is trying to mint
   */
  function claimBurgers(uint256 quantity) public {
    if (!isClaiming) {
      revert ClaimingNotActive();
    }
    if (claimsUsed[msg.sender] + quantity > _totalClaimsEarned(msg.sender)) {
      revert InsufficientClaimsRemaining();
    }
    /// @dev mints `quantity` tokens with `tokenId` 1 to caller ///
    _mint(msg.sender, 1, quantity, "0x00");
    /// @dev sets contract state ///
    claimsUsed[msg.sender] += quantity;
    totalMints += quantity;
  }

  /**
   * Burns burgers on behalf of `account`
   * @param account The address having it's burgers burned
   * @param quantity The number of burgers to burn
   * @notice Only burners may call this function
   */
  function burnBurger(address account, uint256 quantity) public {
    if (!isBurning) {
      revert BurningNotActive();
    }
    if (!burners[msg.sender]) {
      revert CallerIsNotABurner();
    }
    /// @dev burns `quantity` tokens of `tokenId` 1 for `account` ///
    _burn(account, 1, quantity);
    /// @dev sets contract state ///
    totalBurns += quantity;
    accountBurns[account] += quantity;
    burnerBurns[msg.sender] += quantity;
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets the balance of burgers for `account`
   * @param account The address to lookup
   * @return _balance The number of burgers
   * @notice burgers have a `tokenId` of 1
   */
  function balanceOf(address account) public view returns (uint256 _balance) {
    _balance = balanceOf(account, 1);
  }

  /**
   * Gets the total number of burgers in circulation
   * @return _totalSupply The number of burgers
   */
  function totalSupply() public view returns (uint256 _totalSupply) {
    _totalSupply = totalMints - totalBurns;
  }

  /**
   * Gets the number of claims `account` has remaining
   * @param account The address to lookup
   * @return _remaining The number of claims
   */
  function tokenClaimsLeft(address account)
    public
    view
    returns (uint256 _remaining)
  {
    _remaining = _totalClaimsEarned(account) - claimsUsed[account];
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Burger.sol";

error MintingNotActive();
error AstrobullAlreadyClaimed();

/**
 * @title Metabulls
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract is an implementation of chiru lab's erc721a contract and is used for minting
 * 3d metaverse bulls. To mint a metabull, an account will input tokenIds of astrobulls
 * they are using to claim; meaning the account must own each astrobull or be the staker of it,
 * and each astrobull can only be used once. The contract will store which astrobull traits to
 * give each metabull. Users will burn burgers for each metabull they mint.
 */
contract MetaBull is ERC721A, Ownable {
  using Strings for uint256;
  /// contract instances ///
  Burger public immutable BurgerContract;
  Grill2 public immutable GrillContract;
  ISUPER1155 public constant Astro =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  address public constant OldGrill = 0xE11AF478aF241FAb926f4c111d50139Ae003F7fd;
  /// if minting is active ///
  bool public isMinting;
  /// if tokens are revealed ///
  bool public isRevealed;
  /// the number of burgers to burn each mint ///
  uint256 public burnScalar = 2;
  /// the number of burgers burned by this contract ///
  uint256 public totalBurns;
  /// the base uri for all tokens ///
  string public URI;
  /// if an astrobull has been claimed for yet ///
  mapping(uint256 => bool) public portedIds;
  /// which astrobull traits to give each metabull ///
  mapping(uint256 => uint256) public portingMeta;
  /// the number of burgers each account has burned ///
  mapping(address => uint256) public accountBurns;

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Sets the initial base uri and address for the burger contract
   * @param _URI The baseURI for each token
   * @param burgerAddr The address of the burger contract
   * @param grillAddr The address of the grill contract
   */
  constructor(
    string memory _URI,
    address burgerAddr,
    address grillAddr
  ) ERC721A("METABULLS", "MBULL") {
    URI = _URI;
    BurgerContract = Burger(burgerAddr);
    GrillContract = Grill2(grillAddr);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Overrides tokens to start at index 1 instead of 0
   * @return _id The tokenId of the first token
   */
  function _startTokenId() internal pure override returns (uint256 _id) {
    _id = 1;
  }

  /// ============ OWNER ============ ///

  /**
   * Sets a new base URI for tokens
   * @param _URI The new baseURI for each token
   */
  function setURI(string memory _URI) public onlyOwner {
    URI = _URI;
  }

  /**
   * Toggles if minting is allowed.
   */
  function toggleMinting() public onlyOwner {
    isMinting = !isMinting;
  }

  /**
   * Toggles if tokens are revealed.
   */
  function toggleReveal() public onlyOwner {
    isRevealed = !isRevealed;
  }

  /**
   * Sets the quantity of burgers an account must burn to mint each metabull
   * @param _burnScalar The number of burgers to burn
   */
  function setBurnScalar(uint256 _burnScalar) public onlyOwner {
    burnScalar = _burnScalar;
  }

  /**
   * Mints `quantity` tokens to `account`
   * @param quantity The number of tokens to mint
   * @param account The address to mint the tokens to
   * @notice Each token an owner mints will point to a 0 in the portingMeta mapping
   * since it does not share traits with a minted astrobull
   */
  function ownerMint(uint256 quantity, address account) public onlyOwner {
    _safeMint(account, quantity);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Mints a metabull for each astrobull input
   * @param astrobullIds An array of astrobull IDs caller is claiming metabulls for
   * @notice The caller must own each astrobull ID they are claiming for; meaning it must
   * be removed from the grill before use
   */
  function claimBull(uint256[] memory astrobullIds) public {
    if (!isMinting) {
      revert MintingNotActive();
    }
    /// @dev gets the first tokenId being minted ///
    uint256 currentIndex = _currentIndex;
    for (uint256 i = 0; i < astrobullIds.length; ++i) {
      if (!_checkOwnerShip(msg.sender, astrobullIds[i])) {
        revert CallerNotTokenOwner();
      }
      if (portedIds[astrobullIds[i]]) {
        revert AstrobullAlreadyClaimed();
      }
      /// @dev sets the astrobull traits to give each metabull being minted ///
      portingMeta[currentIndex] = astrobullIds[i];
      /// @dev sets contract state ///
      portedIds[astrobullIds[i]] = true;
      /// @dev sets the next tokenId being minted ///
      currentIndex += 1;
    }
    /// burn caller's burgers ///
    uint256 toBurn = burnScalar * astrobullIds.length;
    BurgerContract.burnBurger(msg.sender, toBurn);
    /// sets contract state ///
    totalBurns += toBurn;
    accountBurns[msg.sender] += toBurn;
    /// mint metabulls to caller ///
    _safeMint(msg.sender, astrobullIds.length);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Checks if `account` is the owner or staker of `tokenId`
   * @param account The address to check ownership for
   * @param tokenId The tokenId to check ownership of
   * @return _b If `account` is the owner or staker of `tokenId`
   */
  function _checkOwnerShip(address account, uint256 tokenId)
    internal
    view
    returns (bool _b)
  {
    _b = false;
    /// @dev first checks if account owns token ///
    if (Astro.balanceOf(account, tokenId) == 1) {
      _b = true;
    }
    /// @dev next, checks if token is staked in the old grill and caller is staker ///
    else if (Astro.balanceOf(address(OldGrill), tokenId) == 1) {
      if (GrillContract.stakeStorageOld(tokenId).staker == account) {
        _b = true;
      }
    }
    /// @dev last, checks if token is staked in current grill and caller is staker ///
    else if (GrillContract.stakeStorageGetter(tokenId).staker == account) {
      _b = true;
    }
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets a token's URI
   * @param _tokenId The tokenId to lookup
   * @return _URI The token's uri
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory _URI)
  {
    if (isRevealed) {
      _URI = string(abi.encodePacked(URI, _tokenId.toString(), ".json"));
    } else {
      _URI = URI;
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Burger.sol";

error ExceedsMaxClaims();
error InvalidTokenAmount();
error CallerIsNotTokenOwner();
error CallerNotInCommunity();

/**
 * @title Physical Bulls
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract handles the payment and verification for pre-ordering physical bulls. Users
 * will pre-order physical bulls by exchanging erc20 tokens and burning burgers.
 */
contract PhysicalBull is Ownable {
  using Strings for uint256;
  using SafeERC20 for IERC20;
  /// contract instances ///
  IERC20 public erc20;
  Burger public immutable BurgerContract;
  Grill2 public immutable GrillContract;
  ISUPER1155 public constant Astro =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  /// if claiming is active ///
  bool public isClaiming = false;
  /// the current erc20 payment receiver ///
  address public vault;
  /// the number of physical bulls claimed ///
  uint256 public totalClaims;
  /// the max number of claims an account can make ///
  uint256 public maxClaims = 3;
  /// the number of burgers burned by this contract ///
  uint256 public totalBurns;
  /// the number of burgers to burn for 1 physical bull ///
  uint256 public burnScalar = 1;
  /// the amount of erc20 tokens to claim 1 physical bull ///
  uint256 public erc20Cost = 100000000; // 100.000000 $USDC
  /// the number of burgers each account has burned ///
  mapping(address => uint256) public accountBurns;
  /// the number of physcal bulls each account has claimed ///
  mapping(address => uint256) public accountClaims;

  /**
   * @param _vault The address to receive erc20 tokens
   * @param _erc20 The contract address of the erc20 contract to use for payments
   * @param _burger The address of the burger contract
   * @param _grill The address of the new grill contract
   */
  constructor(
    address _vault,
    address _erc20,
    address _burger,
    address _grill
  ) {
    vault = _vault;
    erc20 = IERC20(_erc20);
    BurgerContract = Burger(_burger);
    GrillContract = Grill2(_grill);
  }

  /// ============ OWNER ============ ///

  /**
   * Toggles if claiming is active
   */
  function toggleClaiming() public onlyOwner {
    isClaiming = !isClaiming;
  }

  /**
   * Sets the cost for each bull claim
   * @param _erc20Cost The number of erc20 tokens to transfer
   */
  function setERC20Cost(uint256 _erc20Cost) public onlyOwner {
    erc20Cost = _erc20Cost;
  }

  /**
   * Sets the erc20 contract address to use for payments
   * @param _erc20 The erc20 contract address
   */
  function setERC20Address(address _erc20) public onlyOwner {
    erc20 = IERC20(_erc20);
  }

  /**
   * Sets the number of burgers to burn for each bull claim
   * @param _burnScalar The number of burgers to burn
   */
  function setBurnScalar(uint256 _burnScalar) public onlyOwner {
    burnScalar = _burnScalar;
  }

  /**
   * Sets the limit for the max number of claims per account
   * @param _maxClaims The max number of claims per account
   */
  function setMaxClaims(uint256 _maxClaims) public onlyOwner {
    maxClaims = _maxClaims;
  }

  /**
   * Sets the address for receiving erc20 payments
   * @param _vault The address to receive payments
   */
  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  /// ============ INTERNAL ============ ///

  /**
   * Checks if `account` owns any astrobulls or has any active stakes
   * @param account The address to lookup
   * @return _b If `account` owns or is the staker of > 0 astrobulls
   * @notice Checks both old and new grill contracts for active stakes
   */
  function _checkCommunityStatus(address account)
    internal
    view
    returns (bool _b)
  {
    _b = false;
    /// @dev first check if caller owns > 0 astrobulls ///
    if (Astro.groupBalances(1, account) > 0) {
      _b = true;
    }
    /// @dev next, check if caller has any active stakes in the old grill ///
    else if (GrillContract.stakedIdsPerAccountOld(account).length > 0) {
      _b = true;
    }
    /// @dev lastly, check if caller has any active stakes in the new grill ///
    else if (GrillContract.stakedIdsPerAccount(account).length > 0) {
      _b = true;
    }
  }

  /// ============ PUBLIC ============ ///

  /**
   * Claims `quantity` number of physical bulls if caller owns > 0 astrobulls
   * @param quantity The number of bulls to claim
   * @notice Caller will send `erc20Cost` * `quantity` tokens to `vault`
   * @notice Caller must give this contract a sufficient allowance to send their erc20 tokens
   */
  function claimBulls(uint256 quantity) public {
    if (!isClaiming) {
      revert ClaimingNotActive();
    }
    if (!_checkCommunityStatus(msg.sender)) {
      revert CallerNotInCommunity();
    }
    if (accountClaims[msg.sender] + quantity > maxClaims) {
      revert ExceedsMaxClaims();
    }
    if (quantity == 0) {
      revert InvalidTokenAmount();
    }
    /// @dev sends erc20 tokens from caller to vault ///
    erc20.safeTransferFrom(msg.sender, vault, quantity * erc20Cost);
    /// @dev burns caller's burgers ///
    uint256 toBurn = burnScalar * quantity;
    BurgerContract.burnBurger(msg.sender, burnScalar * quantity);
    /// @dev sets contract state ///
    totalBurns += toBurn;
    accountBurns[msg.sender] += toBurn;
    totalClaims += quantity;
    accountClaims[msg.sender] += quantity;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}