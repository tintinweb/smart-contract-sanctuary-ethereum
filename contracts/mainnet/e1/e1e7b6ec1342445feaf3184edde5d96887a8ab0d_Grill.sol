//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Interfaces SuperFarm's Super1155 contract
 * See example contracts: https://etherscan.io/address/0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af#code,
 * https://etherscan.io/address/0xc7b9D8483FD01C379a4141B2Ee7c39442172b259#code
 *
 * @notice To stake tokens an account must setApprovalForAll() using the address of this contract in the above contracts
 */
interface Super1155 {
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool);
}

/**
 * @title A staking contract for Super1155 tokens.
 * @author DegenDeveloper.eth
 *
 * April 25, 2022
 *
 * This contract allows users to stake their tokens to earn emission tokens.
 *
 * This contract is only capable of transferring tokens to their original stakers.
 *
 * Accounts always have the ability to unstake their tokens no matter the contract state.
 *
 * The contract owner has the following permissions:
 *
 * - Open/close staking; enabling/disabling the addition of new stakes
 * - Blacklist an account; disabling the addition of new stakes for a specific address
 * - Pause emissions; stops the counting of emission tokens
 * - Set new emission rates; sets a new rate for earning emission tokens
 *    - if emissions are paused this unpauses them
 *    - historic emission rates (emRates) are stored in the contract to accurately calculate emissions
 *
 * --------( In case of security breach )---------
 *
 * Accounts will always have the ability to unstake their tokens, no matter the state of the contract; however,
 *
 * If there is a security breach or the team wishes to terminate the grill, they have the ability to permanently close staking,
 * sending back all tokens to their original stakers.
 *
 * The contract owner must call toggleBailout() before they force unstake any tokens.
 *
 * ToggleBailout() is only callable once
 *
 * Once toggleBailout() has been called, bailoutAllStakes() becomes callable. This function will unstake all tokens and send them back to their original stakers.
 * If there are gas limits sending back all tokens in a single transaction, the function bailoutSingleStake(_tokenId) also becomes callable,
 * allowing each tokenId to be unstaked manually
 */
contract Grill is Ownable, ERC1155Holder {
  /// used for variables that start at 0 and only increment/decrement by 1 at a time
  using Counters for Counters.Counter;

  /// the contract instance for the tokens being staked
  Super1155 private immutable Parent;

  bool private STAKING_ACTIVE;
  bool private BAILED_OUT;

  /// the max number of tokens to stake/unstake in a single txn
  uint256 private constant MAX_TXN = 20;

  /// the max number of seconds possible, used for pausing emissions
  uint256 private constant MAX_INT = 2**256 - 1;

  /// a mapping from each tokenId to its stake details
  mapping(uint256 => Stake) private stakes;

  /// a mapping from each address to an indexed mapping of the tokenIds they have staked
  mapping(address => mapping(uint256 => uint256)) private addrStakesIds;

  /// a mapping from each address to a counter for tokens currently staked
  mapping(address => Counters.Counter) private addrStakesCount;

  /// a mapping from each address to their ability to add new stakes
  mapping(address => bool) private blacklist;

  /// a counter for the number of times the emission rate changes
  Counters.Counter private emChanges;

  /// a mapping from each emChange to its associated emission details
  mapping(uint256 => Emission) private emissions;

  /// a mapping from each address to their emission claims earned from their removed stakes
  mapping(address => uint256) private unstakedClaims;

  /// a counter for the number of active stakes
  Counters.Counter private allStakesCount;

  /// an indexed mapping for all tokenIds staked currently
  mapping(uint256 => uint256) private allStakes;

  /**
   * This struct stores information about staked tokens. They are stored
   * in the `stakes` mapping by tokenId
   * @param status If tokenId is staked or not
   * @param staker The staker of tokenId
   * @param timestamp The time tokenId was staked
   */
  struct Stake {
    bool status;
    address staker;
    uint256 timestamp;
  }

  /**
   * This struct stores information about emissions. They are stored in
   * the 'emissions' mapping by emChange
   * @param rate The number of seconds to earn 1 token
   * @param timestamp The time the emission rate was set
   */
  struct Emission {
    uint256 rate;
    uint256 timestamp;
  }

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Initializes the parent contract instance, the initial emission rate, and timestamps the deploy
   * @param _parentAddr The contract address to allow staking from
   */
  constructor(address _parentAddr) {
    Parent = Super1155(_parentAddr);
    STAKING_ACTIVE = true;
    BAILED_OUT = false;
    uint256 secondsIn45Days = 3600 * 24 * 45;
    emissions[emChanges.current()] = Emission(secondsIn45Days, block.timestamp);
  }

  /// ============ OWNER FUNCTIONS ============ ///

  /**
   * For allowing/unallowing the addition of new stakes
   * @notice This function is disabled once toggleBailout() is called
   */
  function toggleStaking() external onlyOwner {
    require(!BAILED_OUT, "GRILL: contract has been terminated");
    STAKING_ACTIVE = !STAKING_ACTIVE;
  }

  /**
   * For allowing/unallowing an address to add new stakes
   * @notice A staker is always able to remove their stakes regardless of contract state
   * @param _addr The address to set blacklist status for
   * @param _status The status to set for _addr
   */
  function blacklistAddr(address _addr, bool _status) external onlyOwner {
    blacklist[_addr] = _status;
  }

  /**
   * Stops the counting of emission tokens
   * @notice No tokens can be earned with an emission rate this long
   * @notice To continue emissions counting, the owner must set a new emission rate
   */
  function pauseEmissions() external onlyOwner {
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sets new emission rate
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   */
  function setEmissionRate(uint256 _seconds) external onlyOwner {
    require(!BAILED_OUT, "GRILL: cannot change emission rate after bailout");
    _setEmissionRate(_seconds);
  }

  /**
   * Pauses staking/emissions counting permanently
   * @notice This function is only callable once and all state changes are final
   * @notice It must be called before bailoutAllStakes() or bailoutSingleStake()
   */
  function toggleBailout() external onlyOwner {
    require(!BAILED_OUT, "GRILL: bailout already called");
    STAKING_ACTIVE = false;
    BAILED_OUT = true;
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sends back all tokens to their original stakers
   * @notice toggleBailout() must be called
   */
  function bailoutAllStakes() external onlyOwner {
    require(BAILED_OUT, "GRILL: toggleBailout() must be called first");

    /// @dev copies current number of stakes before bailout ///
    uint256 _totalCount = allStakesCount.current();
    for (uint256 i = 1; i <= _totalCount; ++i) {
      /// @dev gets token and staker for last token staked ///
      uint256 _lastTokenId = allStakes[allStakesCount.current()];
      address _staker = stakes[_lastTokenId].staker;

      /// @dev transferrs _lastTokenId from the contract to associated _staker ///
      Parent.safeTransferFrom(address(this), _staker, _lastTokenId, 1, "0x0");

      /// @dev sets state changes ///
      uint256[] memory _singleArray = _makeOnesArray(1);
      _singleArray[0] = _lastTokenId; // _removeStakes() requires an array of tokenIds
      _removeStakes(_staker, _singleArray);
    }
  }

  /**
   * Sends back _tokenId to its original staker
   * @notice toggleBailout() must be called
   * @notice This function is here in case bailoutAllStakes() has gas limitations
   */
  function bailoutSingleStake(uint256 _tokenId) external onlyOwner {
    require(BAILED_OUT, "GRILL: toggleBailout() must be called first");

    Parent.safeTransferFrom(
      address(this),
      stakes[_tokenId].staker,
      _tokenId,
      1,
      "0x0"
    );

    /// @dev sets state changes ///
    uint256[] memory _singleArray = _makeOnesArray(1);
    _singleArray[0] = _tokenId;
    _removeStakes(stakes[_tokenId].staker, _singleArray);
  }

  /// ============ PUBLIC FUNCTIONS ============ ///

  /**
   * Transfer tokens from caller to contract and begins emissions counting
   * @param _tokenIds The tokenIds to stake
   * @param _amounts The amount of each tokenId to stake
   * @notice _amounts must have a value of 1 at each index
   */
  function addStakes(uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
  {
    require(STAKING_ACTIVE, "GRILL: staking is not active");
    require(!blacklist[msg.sender], "GRILL: caller is blacklisted");
    require(_tokenIds.length > 0, "GRILL: must stake more than 0 tokens");
    require(
      _tokenIds.length <= MAX_TXN,
      "GRILL: must stake less than MAX_TXN tokens per txn"
    );
    require(
      _isOwnerOfBatch(msg.sender, _tokenIds, _amounts),
      "GRILL: caller does not own these tokens"
    );
    require(
      Parent.isApprovedForAll(msg.sender, address(this)),
      "GRILL: contract is not an approved operator for caller's tokens"
    );

    /// @dev transfers token batch from caller to contract
    Parent.safeBatchTransferFrom(
      msg.sender,
      address(this),
      _tokenIds,
      _amounts,
      "0x0"
    );

    /// @dev sets contract state
    _addStakes(msg.sender, _tokenIds);
  }

  /**
   * Transfer tokens from contract to caller and records emissions in unStakedClaims
   * @param _tokenIds The tokenIds to unstake
   * @param _amounts The amount of each tokenId to unstake
   * @notice _amounts must have a value of 1 at each index
   */
  function removeStakes(uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
  {
    require(_tokenIds.length > 0, "GRILL: must unstake more than 0 tokens");
    require(
      _tokenIds.length <= MAX_TXN,
      "GRILL: cannot stake more than MAX_TXN tokens in a single txn"
    );
    require(_tokenIds.length == _amounts.length, "GRILL: arrays mismatch");
    require(
      _isStakerOfBatch(msg.sender, _tokenIds, _amounts),
      "GRILL: caller was not the staker of these tokens"
    );
    require(
      _tokenIds.length <= addrStakesCount[msg.sender].current(),
      "GRILL: caller is unstaking too many tokens"
    );

    /// @dev transfers token batch from contract to caller ///
    Parent.safeBatchTransferFrom(
      address(this),
      msg.sender,
      _tokenIds,
      _amounts,
      "0x0"
    );

    /// @dev sets contract state ///
    _removeStakes(msg.sender, _tokenIds);
  }

  /// ============ PRIVATE/HELPER FUNCTIONS ============ ///

  /**
   * Verifies if an address can stake a batch of tokens
   * @param _operator The address trying to stake
   * @param _tokenIds The tokenIds _operator is trying to stake
   * @param _amounts The amount of each tokenId caller is trying to stake
   * @notice Each element in _amounts must be 1
   * @return _b If _operator can unstake _tokenIds
   */
  function _isOwnerOfBatch(
    address _operator,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) private view returns (bool _b) {
    _b = true;
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      if (parentBalance(_operator, _tokenIds[i]) == 0 || _amounts[i] != 1) {
        _b = false;
        break;
      }
    }
  }

  /**
   * Verifies if an address can unstake a batch of tokens
   * @param _operator The address trying to unstake
   * @param _tokenIds The tokenIds _operator is trying to unstake
   * @param _amounts The amount of each tokenId caller is trying to unstake
   * @notice Each element in _amounts must be 1
   * @return _b If _operator can unstake _tokenIds
   */
  function _isStakerOfBatch(
    address _operator,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) private view returns (bool _b) {
    _b = true;
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      if (stakes[_tokenIds[i]].staker != _operator || _amounts[i] != 1) {
        _b = false;
        break;
      }
    }
  }

  /**
   * Helper function for setting contract state when tokens are staked
   * @param _staker The address staking tokens
   * @param _tokenIds The tokenIds being staked
   */
  function _addStakes(address _staker, uint256[] memory _tokenIds) private {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      require(!stakes[_tokenIds[i]].status, "GRILL: token already staked");

      /// increment counters
      addrStakesCount[_staker].increment();
      allStakesCount.increment();

      /// set mappings
      addrStakesIds[_staker][addrStakesCount[_staker].current()] = _tokenIds[i];
      allStakes[allStakesCount.current()] = _tokenIds[i];
      stakes[_tokenIds[i]] = Stake(true, _staker, block.timestamp);
    }
  }

  /**
   * Helper function for setting contract state when tokens are unstaked
   * @param _staker The address unstaking tokens
   * @param _tokenIds The tokenIds being unstaked
   */
  function _removeStakes(address _staker, uint256[] memory _tokenIds) private {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      require(
        stakes[_tokenIds[i]].status,
        "GRILL: token is not currently staked"
      );

      /// count rewards earned
      uint256 _tokenId = _tokenIds[i];
      unstakedClaims[_staker] += _countEmissions(_tokenId);

      /// @dev resets Stake object in `stakes` mapping ///
      delete stakes[_tokenId];

      /// last index of mappings
      uint256 _t = addrStakesCount[_staker].current();
      uint256 _t1 = allStakesCount.current();

      /// @dev finds _tokenId in mappings, swaps it with last index ///
      for (uint256 j = 1; j < _t; ++j) {
        if (addrStakesIds[_staker][j] == _tokenId) {
          addrStakesIds[_staker][j] = addrStakesIds[_staker][_t];
        }
      }
      for (uint256 k = 1; k < _t1; ++k) {
        if (allStakes[k] == _tokenId) {
          allStakes[k] = allStakes[_t1];
        }
      }

      /// @dev resets last item in mappings
      delete addrStakesIds[_staker][_t];
      delete allStakes[_t1];

      /// decrement counters, avoiding decrement overflow
      if (_t != 0) {
        addrStakesCount[_staker].decrement();
      }
      if (_t1 != 0) {
        allStakesCount.decrement();
      }
    }
  }

  /**
   * Helper function for setting contract state when emission changes occur
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   * @notice The emission rate cannot be 0 seconds
   */
  function _setEmissionRate(uint256 _seconds) private {
    require(_seconds > 0, "GRILL: emission rate cannot be 0");
    emChanges.increment();
    emissions[emChanges.current()] = Emission(_seconds, block.timestamp);
  }

  /**
   * Helper function to count number of emission tokens _tokenId has earned
   * @param _tokenId The tokenId to check
   * @notice A token must be staked to count emissions
   */
  function _countEmissions(uint256 _tokenId) private view returns (uint256 _c) {
    require(stakes[_tokenId].status, "GRILL: token is not currently staked");

    /// @dev finds the first emission rate _tokenId was staked for ///
    uint256 minT;
    uint256 timeStake = stakes[_tokenId].timestamp;
    for (uint256 i = 1; i <= emChanges.current(); ++i) {
      if (emissions[i].timestamp < timeStake) {
        minT += 1;
      }
    }
    /// @dev counts all emissions earned starting from minT -> now
    for (uint256 i = minT; i <= emChanges.current(); ++i) {
      uint256 tSmall = emissions[i].timestamp;
      uint256 tBig = emissions[i + 1].timestamp;
      if (i == minT) {
        tSmall = timeStake;
      }
      if (i == emChanges.current()) {
        tBig = block.timestamp;
      }
      _c += (tBig - tSmall) / emissions[i].rate;
    }
  }

  /**
   * Helper function for creating an array of all 1's
   * @param _n The size of the array
   * @return _ones An array of size _n with a value of 1 at each index
   */
  function _makeOnesArray(uint256 _n)
    private
    pure
    returns (uint256[] memory _ones)
  {
    _ones = new uint256[](_n);
    for (uint256 i = 0; i < _n; i++) {
      _ones[i] = 1;
    }
    return _ones;
  }

  /// ============ READ-ONLY FUNCTIONS ============ ///

  /**
   * Get the balance for a specifc tokenId in parent contract
   * @param _operator The address to lookup
   * @param _tokenId The token id to check balance of
   * @return _c The _tokenId balance of _operator
   */
  function parentBalance(address _operator, uint256 _tokenId)
    public
    view
    returns (uint256 _c)
  {
    _c = Parent.balanceOf(_operator, _tokenId);
  }

  /**
   * @return _b If the contract is allowing new stakes to be added
   */
  function isStakingActive() external view returns (bool _b) {
    _b = STAKING_ACTIVE;
  }

  /**
   * @return _b If the contract has been bailed out
   */
  function isBailedOut() external view returns (bool _b) {
    _b = BAILED_OUT;
  }

  /**
   * @param _addr The address to lookup
   * @return _b Blacklist status
   */
  function isBlacklisted(address _addr) external view returns (bool _b) {
    _b = blacklist[_addr];
  }

  /**
   * @return _changes The current number of emission changes to date
   */
  function getEmissionChanges() external view returns (uint256 _changes) {
    _changes = emChanges.current();
  }

  /**
   * Get details for an emission change
   * @param _change The change number to lookup
   * @return _emission The emission object for emChange _change
   * @notice A _change must have occured to view it
   */
  function getEmission(uint256 _change)
    external
    view
    returns (Emission memory _emission)
  {
    require(_change <= emChanges.current(), "GRILL: invalid index to lookup");
    _emission = emissions[_change];
  }

  /**
   * @return _allStakingIds Array of tokenIds currently being staked
   */
  function getAllStakedIds()
    external
    view
    returns (uint256[] memory _allStakingIds)
  {
    _allStakingIds = new uint256[](allStakesCount.current());
    for (uint256 i = 0; i < _allStakingIds.length; ++i) {
      _allStakingIds[i] = allStakes[i + 1];
    }
  }

  /**
   * Get details for a staked token
   * @param _tokenId The tokenId to lookup
   * @return _stake The stake of _tokenId
   * @notice A _tokenId must currently be staked to view it
   */
  function getStake(uint256 _tokenId)
    external
    view
    returns (Stake memory _stake)
  {
    require(stakes[_tokenId].status, "GRILL: tokenId is not staked");
    _stake = stakes[_tokenId];
  }

  /**
   * @param _operator The address to lookup
   * @return _addrStakes Array of tokenIds currently staked by _operator
   */
  function getIdsOfAddr(address _operator)
    external
    view
    returns (uint256[] memory _addrStakes)
  {
    _addrStakes = new uint256[](addrStakesCount[_operator].current());
    for (uint256 i = 0; i < _addrStakes.length; ++i) {
      _addrStakes[i] = addrStakesIds[_operator][i + 1];
    }
  }

  /**
   * @param _operator The address to lookup
   * @return _claims The number of claims _operator has earned from their unstaked bulls
   */
  function getUnstakedClaims(address _operator) public view returns (uint256) {
    return unstakedClaims[_operator];
  }

  /**
   * @param _operator The address to lookup
   * @return _total The number of claims an address has earned from their current stakes
   */
  function getStakedClaims(address _operator)
    public
    view
    returns (uint256 _total)
  {
    for (uint256 i = 1; i <= addrStakesCount[_operator].current(); i++) {
      _total += _countEmissions(addrStakesIds[_operator][i]);
    }
  }

  /**
   * @param _operator The address to lookup
   * @return _total The number of emissions _operator has earned from all past and current stakes
   */
  function getTotalClaims(address _operator)
    external
    view
    returns (uint256 _total)
  {
    _total = unstakedClaims[_operator];
    _total += getStakedClaims(_operator);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Interfaces Grill contracts
 */
interface GrillC {
  function getTotalClaims(address _operator) external view returns (uint256);
}

/**
 * @title An erc-1155 nft contract.
 * @author DegenDeveloper.eth
 *
 * March 29th, 2022
 *
 * This contract allows addresses to mint tokens earned from AstroGrill
 * and/or RickstroGrill staking.
 *
 * The contract owner has the following permissions:
 * - toggle minting.
 * - toggle burning.
 * - update the URI for tokens.
 * - mint tokens for marketing/giveaways without restriction
 */
contract Burger is ERC1155, Ownable {
  using Counters for Counters.Counter;

  /// contract instances
  GrillC public immutable AstroGrill;
  GrillC public immutable RickstroGrill;

  Counters.Counter private totalMinted;
  Counters.Counter private totalBurned;

  bool private CAN_MINT = false;
  bool private CAN_BURN = false;

  /// lookup identifiers
  bytes32 constant MINTS = keccak256("CLAIMS");
  bytes32 constant BURNS = keccak256("BURNS");

  /// mapping for the number of mints/burns of each address
  mapping(bytes32 => mapping(address => Counters.Counter)) private stats;

  /**
   * @param _aGrillAddr The address of the astro grill
   * @param _rGrillAddr The address of the rickstro grill
   */
  constructor(address _aGrillAddr, address _rGrillAddr)
    ERC1155("burger.io/{}.json")
  {
    AstroGrill = GrillC(_aGrillAddr);
    RickstroGrill = GrillC(_rGrillAddr);
  }

  /// ============ OWNER FUNCTIONS ============ ///

  /**
   * Sets the URI for the collection
   * @param _URI The new URI
   */
  function setURI(string memory _URI) public onlyOwner {
    _setURI(_URI);
  }

  function toggleMinting() external onlyOwner {
    CAN_MINT = !CAN_MINT;
  }

  function toggleBurning() external onlyOwner {
    CAN_BURN = !CAN_BURN;
  }

  /**
   * Allows contract owner to mint tokens for giveaways/etc.
   * @param _amount The number of tokens to mint
   * @param _addr The address to mint the tokens to
   */
  function ownerMint(uint256 _amount, address _addr) external onlyOwner {
    uint256[] memory _ids = new uint256[](_amount);
    uint256[] memory _amounts = new uint256[](_amount);

    for (uint256 i = 0; i < _amount; i++) {
      totalMinted.increment();
      _ids[i] = totalMinted.current();
      _amounts[i] = 1;
    }

    _mintBatch(_addr, _ids, _amounts, "0x0");
  }

  /// ============ PUBLIC FUNCTIONS ============ ///

  /**
   * Mint tokens to caller
   * @param _amount The number of tokens to mint
   */
  function mintPublic(uint256 _amount) external {
    require(CAN_MINT, "BURGER: minting is not active");
    require(_amount > 0, "BURGER: must claim more than 0 tokens");
    require(
      stats[MINTS][msg.sender].current() + _amount <=
        AstroGrill.getTotalClaims(msg.sender) +
          RickstroGrill.getTotalClaims(msg.sender),
      "BURGER: caller cannot claim this many tokens"
    );

    uint256[] memory _ids = new uint256[](_amount);
    uint256[] memory _amounts = new uint256[](_amount);

    for (uint256 i = 0; i < _amount; i++) {
      stats[MINTS][msg.sender].increment();
      totalMinted.increment();
      _ids[i] = totalMinted.current();
      _amounts[i] = 1;
    }

    _mintBatch(msg.sender, _ids, _amounts, "0x0");
  }

  /**
   * Burns callers tokens and records amount burned
   * @param _ids Array of token ids caller is trying to burn
   */
  function burnPublic(uint256[] memory _ids) external {
    require(CAN_BURN, "BURGER: burning is not active");
    require(_ids.length > 0, "BURGER: must burn more than 0 tokens");

    uint256[] memory _amounts = new uint256[](_ids.length);

    for (uint256 i = 0; i < _ids.length; i++) {
      require(
        balanceOf(msg.sender, _ids[i]) > 0,
        "BURGER: caller is not token owner"
      );
      _amounts[i] = 1;
      stats[BURNS][msg.sender].increment();
      totalBurned.increment();
    }
    _burnBatch(msg.sender, _ids, _amounts);
  }

  /// ============ READ-ONLY FUNCTIONS ============ ///

  /**
   * @return _b If minting tokens is currently allowed
   */
  function isMinting() external view returns (bool _b) {
    return CAN_MINT;
  }

  /**
   * @return _b If burning tokens is currently allowed
   */
  function isBurning() external view returns (bool _b) {
    return CAN_BURN;
  }

  /**
   * @return _supply The number of tokens in circulation
   */
  function totalSupply() external view returns (uint256 _supply) {
    _supply = totalMinted.current() - totalBurned.current();
  }

  /**
   * @return _mints The number of tokens minted
   */
  function totalMints() external view returns (uint256 _mints) {
    _mints = totalMinted.current();
  }

  /**
   * @return _burns The number of tokens burned
   */
  function totalBurns() external view returns (uint256 _burns) {
    _burns = totalBurned.current();
  }

  /**
   * @param _operator The address to lookup
   * @return _remaining The number of tokens _operator can mint
   */
  function tokenMintsLeft(address _operator)
    external
    view
    returns (uint256 _remaining)
  {
    _remaining =
      AstroGrill.getTotalClaims(_operator) +
      RickstroGrill.getTotalClaims(_operator) -
      stats[MINTS][_operator].current();
  }

  /**
   * @param _operator The address to lookup
   * @return _mints The number of tokens _operator has minted
   */
  function tokenMints(address _operator)
    external
    view
    returns (uint256 _mints)
  {
    _mints = stats[MINTS][_operator].current();
  }

  /**
   * @return _burns The number of tokens _operator has burned
   */
  function tokenBurns(address _operator)
    external
    view
    returns (uint256 _burns)
  {
    _burns = stats[BURNS][_operator].current();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
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