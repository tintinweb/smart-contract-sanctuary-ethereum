// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './interfaces/IJBTiered721DelegateStore.sol';
import './libraries/JBBitmap.sol';
import './structs/JBBitmapWord.sol';
import './structs/JBStored721Tier.sol';

/**
  @title
  JBTiered721DelegateStore

  @notice
  The contract that stores and manages the NFT's data.

  @dev
  Adheres to -
  IJBTiered721DelegateStore: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
contract JBTiered721DelegateStore is IJBTiered721DelegateStore {
  using JBBitmap for mapping(uint256 => uint256);
  using JBBitmap for JBBitmapWord;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error CANT_MINT_MANUALLY();
  error INSUFFICIENT_AMOUNT();
  error INSUFFICIENT_RESERVES();
  error INVALID_PRICE_SORT_ORDER();
  error INVALID_QUANTITY();
  error INVALID_TIER();
  error MAX_TIERS_EXCEEDED();
  error NO_QUANTITY();
  error OUT();
  error RESERVED_RATE_NOT_ALLOWED();
  error MANUAL_MINTING_NOT_ALLOWED();
  error PRICING_RESOLVER_CHANGES_LOCKED();
  error TIER_LOCKED();
  error TIER_REMOVED();
  error VOTING_UNITS_NOT_ALLOWED();

  //*********************************************************************//
  // -------------------- private constant properties ------------------ //
  //*********************************************************************//

  uint256 private constant _ONE_BILLION = 1_000_000_000;

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /** 
    @notice
    The index that should come after the given index when sorting by contribution floor.

    @dev
    If empty, assume the next index should come after. 

    _nft The NFT contract to get tier order index from.
    _index The index to get a tier after relative to.
  */
  mapping(address => mapping(uint256 => uint256)) internal _tierIdAfter;

  /**
    @notice
    An optional beneficiary for the reserved token of a given tier.

    _nft The NFT contract to which the reserved token beneficiary belongs.
    _tierId the ID of the tier.
  */
  mapping(address => mapping(uint256 => address)) internal _reservedTokenBeneficiaryOf;

  /** 
    @notice
    The stored reward tier. 

    _nft The NFT contract to which the tiers belong.
    _tierId The incremental ID of the tier, starting with 1.
  */
  mapping(address => mapping(uint256 => JBStored721Tier)) internal _storedTierOf;

  /**
    @notice
    Flags that influence the behavior of each NFT.

    _nft The NFT for which the flags apply.
  */
  mapping(address => JBTiered721Flags) internal _flagsOf;

  /** 
    @notice
    For each tier ID, a bitmap containing flags indicating if the tier has been removed. 

    _nft The NFT contract to which the tier belong.
    _depth The bitmap row.
    _word The row content bitmap.
  */
  mapping(address => mapping(uint256 => uint256)) internal _isTierRemovedBitmapWord;

  /** 
    @notice
    For each NFT, the tier ID that comes last when sorting. 

    @dev
    If not set, it is assumed the `maxTierIdOf` is the last sorted.

    _nft The NFT contract to which the tier belongs.
  */
  mapping(address => uint256) internal _trackedLastSortTierIdOf;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice
    The biggest tier ID used. 

    @dev
    This may not include the last tier ID if it has been removed.

    _nft The NFT contract to get the number of tiers.
  */
  mapping(address => uint256) public override maxTierIdOf;

  /** 
    @notice
    Each account's balance within a specific tier.

    _nft The NFT contract to which the tier balances belong.
    _owner The address to get a balance for. 
    _tierId The ID of the tier to get a balance within.
  */
  mapping(address => mapping(address => mapping(uint256 => uint256))) public override tierBalanceOf;

  /**
    @notice 
    The number of reserved tokens that have been minted for each tier. 

    _nft The NFT contract to which the reserve data belong.
    _tierId The ID of the tier to get a minted reserved token count for.
   */
  mapping(address => mapping(uint256 => uint256)) public override numberOfReservesMintedFor;

  /**
    @notice 
    The number of tokens that have been burned for each tier. 

    _nft The NFT contract to which the burned data belong.
    _tierId The ID of the tier to get a burned token count for.
   */
  mapping(address => mapping(uint256 => uint256)) public override numberOfBurnedFor;

  /** 
    @notice
    The beneficiary of reserved tokens when the tier doesn't specify a beneficiary.

    _nft The NFT contract to which the reserved token beneficiary applies.
  */
  mapping(address => address) public override defaultReservedTokenBeneficiaryOf;

  /**
    @notice
    The first owner of each token ID, stored on first transfer out.

    _nft The NFT contract to which the token belongs.
    _tokenId The ID of the token to get the stored first owner of.
  */
  mapping(address => mapping(uint256 => address)) public override firstOwnerOf;

  /**
    @notice
    The common base for the tokenUri's

    _nft The NFT for which the base URI applies.
  */
  mapping(address => string) public override baseUriOf;

  /**
    @notice
    Custom token URI resolver, supersedes base URI.

    _nft The NFT for which the token URI resolver applies.
  */
  mapping(address => IJBTokenUriResolver) public override tokenUriResolverOf;

  /**
    @notice
    Contract metadata uri.

    _nft The NFT for which the contract URI resolver applies.
  */
  mapping(address => string) public override contractUriOf;

  /**
    @notice
    When using this contract to manage token uri's, those are stored as 32bytes, based on IPFS hashes stripped down.

    _nft The NFT contract to which the encoded upfs uri belongs.
    _tierId the ID of the tier
  */
  mapping(address => mapping(uint256 => bytes32)) public override encodedIPFSUriOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Gets an array of all the active tiers. 

    @param _nft The NFT contract to get tiers for.
    @param _startingId The start index of the array of tiers sorted by contribution floor. Send 0 to start at the beginning.
    @param _size The number of tiers to include.

    @return _tiers All the tiers.
  */
  function tiers(
    address _nft,
    uint256 _startingId,
    uint256 _size
  ) external view override returns (JB721Tier[] memory _tiers) {
    // Keep a reference to the last tier ID.
    uint256 _lastTierId = _lastSortIndexOf(_nft);

    // Initialize an array with the appropriate length.
    _tiers = new JB721Tier[](_size);

    // Count the number of included tiers.
    uint256 _numberOfIncludedTiers;

    // Get a reference to the index being iterated on, starting with the starting index.
    uint256 _currentSortIndex = _startingId != 0 ? _startingId : _firstSortIndexOf(_nft);

    // Keep a reference to the tier being iterated on.
    JBStored721Tier memory _storedTier;

    // Initialize a BitmapWord for isRemoved
    JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_currentSortIndex);

    // Make the sorted array.
    while (_currentSortIndex != 0 && _numberOfIncludedTiers < _size) {
      // Is the current index outside the currently stored word for isRemoved?
      if (_bitmapWord.refreshBitmapNeeded(_currentSortIndex))
        _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_currentSortIndex);

      if (!_bitmapWord.isTierIdRemoved(_currentSortIndex)) {
        _storedTier = _storedTierOf[_nft][_currentSortIndex];
        // Add the tier to the array being returned.
        _tiers[_numberOfIncludedTiers++] = JB721Tier({
          id: _currentSortIndex,
          contributionFloor: _storedTier.contributionFloor,
          lockedUntil: _storedTier.lockedUntil,
          remainingQuantity: _storedTier.remainingQuantity,
          initialQuantity: _storedTier.initialQuantity,
          votingUnits: _storedTier.votingUnits,
          reservedRate: _storedTier.reservedRate,
          reservedTokenBeneficiary: reservedTokenBeneficiaryOf(_nft, _currentSortIndex),
          encodedIPFSUri: encodedIPFSUriOf[_nft][_currentSortIndex],
          allowManualMint: _storedTier.allowManualMint,
          transfersPausable: _storedTier.transfersPausable
        });
      }

      // Set the next sort index.
      _currentSortIndex = _nextSortIndex(_nft, _currentSortIndex, _lastTierId);
    }

    // Resize the array if there are removed tiers
    if (_numberOfIncludedTiers != _size)
      assembly ("memory-safe"){
        mstore(_tiers, _numberOfIncludedTiers)
      }
  }

  /** 
    @notice
    Return the tier for the specified ID. 

    @param _nft The NFT to get a tier within.
    @param _id The ID of the tier to get. 

    @return The tier.
  */
  function tier(address _nft, uint256 _id) external view override returns (JB721Tier memory) {
    // Get the stored tier.
    JBStored721Tier memory _storedTier = _storedTierOf[_nft][_id];

    return
      JB721Tier({
        id: _id,
        contributionFloor: _storedTier.contributionFloor,
        lockedUntil: _storedTier.lockedUntil,
        remainingQuantity: _storedTier.remainingQuantity,
        initialQuantity: _storedTier.initialQuantity,
        votingUnits: _storedTier.votingUnits,
        reservedRate: _storedTier.reservedRate,
        reservedTokenBeneficiary: reservedTokenBeneficiaryOf(_nft, _id),
        encodedIPFSUri: encodedIPFSUriOf[_nft][_id],
        allowManualMint: _storedTier.allowManualMint,
        transfersPausable: _storedTier.transfersPausable
      });
  }

  /**  
    @notice
    Return the tier for the specified token ID. 

    @param _nft The NFT to get a tier within.
    @param _tokenId The ID of token to return the tier of. 

    @return The tier.
  */
  function tierOfTokenId(address _nft, uint256 _tokenId)
    external
    view
    override
    returns (JB721Tier memory)
  {
    // Get a reference to the tier's ID.
    uint256 _tierId = tierIdOfToken(_tokenId);

    // Get the stored tier.
    JBStored721Tier memory _storedTier = _storedTierOf[_nft][_tierId];

    return
      JB721Tier({
        id: _tierId,
        contributionFloor: _storedTier.contributionFloor,
        lockedUntil: _storedTier.lockedUntil,
        remainingQuantity: _storedTier.remainingQuantity,
        initialQuantity: _storedTier.initialQuantity,
        votingUnits: _storedTier.votingUnits,
        reservedRate: _storedTier.reservedRate,
        reservedTokenBeneficiary: reservedTokenBeneficiaryOf(_nft, _tierId),
        encodedIPFSUri: encodedIPFSUriOf[_nft][_tierId],
        allowManualMint: _storedTier.allowManualMint,
        transfersPausable: _storedTier.transfersPausable
      });
  }

  /** 
    @notice 
    The total supply of issued NFTs from all tiers.

    @param _nft The NFT to get a total supply of.

    @return supply The total number of NFTs between all tiers.
  */
  function totalSupply(address _nft) external view override returns (uint256 supply) {
    // Keep a reference to the tier being iterated on.
    JBStored721Tier storage _storedTier;

    // Keep a reference to the greatest tier ID.
    uint256 _maxTierId = maxTierIdOf[_nft];

    for (uint256 _i = _maxTierId; _i != 0; ) {
      // Set the tier being iterated on.
      _storedTier = _storedTierOf[_nft][_i];

      // Increment the total supply with the amount used already.
      supply += _storedTier.initialQuantity - _storedTier.remainingQuantity;

      unchecked {
        --_i;
      }
    }
  }

  /** 
    @notice
    The number of reserved tokens that can currently be minted within the tier. 

    @param _nft The NFT to get a number of reserved tokens outstanding.
    @param _tierId The ID of the tier to get a number of reserved tokens outstanding.

    @return The outstanding number of reserved tokens within the tier.
  */
  function numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId)
    external
    view
    override
    returns (uint256)
  {
    return _numberOfReservedTokensOutstandingFor(_nft, _tierId, _storedTierOf[_nft][_tierId]);
  }

  /**
    @notice
    The voting units for an account from its NFTs across all tiers. NFTs have a tier-specific preset number of voting units. 

    @param _nft The NFT to get voting units within.
    @param _account The account to get voting units for.

    @return units The voting units for the account.
  */
  function votingUnitsOf(address _nft, address _account)
    external
    view
    virtual
    override
    returns (uint256 units)
  {
    // Keep a reference to the greatest tier ID.
    uint256 _maxTierId = maxTierIdOf[_nft];

    // Keep a reference to the balance being iterated on.
    uint256 _balance;

    // Loop through all tiers.
    for (uint256 _i = _maxTierId; _i != 0; ) {
      // Get a reference to the account's balance in this tier.
      _balance = tierBalanceOf[_nft][_account][_i];

      if (_balance != 0)
        // Add the tier's voting units.
        units += _balance * _storedTierOf[_nft][_i].votingUnits;

      unchecked {
        --_i;
      }
    }
  }

  /**
    @notice
    The voting units for an account from its NFTs across all tiers. NFTs have a tier-specific preset number of voting units. 

    @param _nft The NFT to get voting units within.
    @param _account The account to get voting units for.
    @param _tierId The ID of the tier to get voting units for.

    @return The voting units for the account.
  */
  function tierVotingUnitsOf(
    address _nft,
    address _account,
    uint256 _tierId
  ) external view virtual override returns (uint256) {
    // Get a reference to the account's balance in this tier.
    uint256 _balance = tierBalanceOf[_nft][_account][_tierId];

    if (_balance == 0) return 0;

    // Add the tier's voting units.
    return _balance * _storedTierOf[_nft][_tierId].votingUnits;
  }

  /**
    @notice
    Resolves the encoded tier IPFS URI of the tier for the given token.

    @param _nft The NFT contract to which the encoded IPFS URI belongs.
    @param _tokenId the ID of the token.

    @return The encoded IPFS URI.
  */
  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId)
    external
    view
    override
    returns (bytes32)
  {
    return encodedIPFSUriOf[_nft][tierIdOfToken(_tokenId)];
  }

  /** 
    @notice
    Flags that influence the behavior of each NFT.

    @param _nft The NFT for which the flags apply.

    @return The flags.
  */
  function flagsOf(address _nft) external view override returns (JBTiered721Flags memory) {
    return _flagsOf[_nft];
  }

  /** 
    @notice
    Tier removed from the current tiering

    @param _nft The NFT for which the removed tier is queried
    @param _tierId The tier ID

    @return True if the tier has been removed
  */
  function isTierRemoved(address _nft, uint256 _tierId) external view override returns (bool) {
    JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_tierId);

    return _bitmapWord.isTierIdRemoved(_tierId);
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The total number of tokens owned by the given owner. 

    @param _nft The NFT to get a balance from.
    @param _owner The address to check the balance of.

    @return balance The number of tokens owners by the owner across all tiers.
  */
  function balanceOf(address _nft, address _owner) public view override returns (uint256 balance) {
    // Keep a reference to the greatest tier ID.
    uint256 _maxTierId = maxTierIdOf[_nft];

    // Loop through all tiers.
    for (uint256 _i = _maxTierId; _i != 0; ) {
      // Get a reference to the account's balance in this tier.
      balance += tierBalanceOf[_nft][_owner][_i];

      unchecked {
        --_i;
      }
    }
  }

  /**
    @notice
    The cumulative weight the given token IDs have in redemptions compared to the `totalRedemptionWeight`.

    @param _nft The NFT for which the redemption weight is being calculated.
    @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.

    @return weight The weight.
  */
  function redemptionWeightOf(address _nft, uint256[] calldata _tokenIds)
    public
    view
    override
    returns (uint256 weight)
  {
    // Get a reference to the total number of tokens.
    uint256 _numberOfTokenIds = _tokenIds.length;

    // Add each token's tier's contribution floor to the weight.
    for (uint256 _i; _i < _numberOfTokenIds; ) {
      weight += _storedTierOf[_nft][tierIdOfToken(_tokenIds[_i])].contributionFloor;

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    The cumulative weight that all token IDs have in redemptions.

    @param _nft The NFT for which the redemption weight is being calculated.

    @return weight The total weight.
  */
  function totalRedemptionWeight(address _nft) public view override returns (uint256 weight) {
    // Keep a reference to the greatest tier ID.
    uint256 _maxTierId = maxTierIdOf[_nft];

    // Keep a reference to the tier being iterated on.
    JBStored721Tier memory _storedTier;

    // Add each token's tier's contribution floor to the weight.
    for (uint256 _i; _i < _maxTierId; ) {
      // Keep a reference to the stored tier.
      unchecked {
        _storedTier = _storedTierOf[_nft][_i + 1];
      }

      // Add the tier's contribution floor multiplied by the quantity minted.
      weight +=
        _storedTier.contributionFloor *
        ((_storedTier.initialQuantity - _storedTier.remainingQuantity) +
          _numberOfReservedTokensOutstandingFor(_nft, _i + 1, _storedTier));

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    The tier number of the provided token ID. 

    @dev
    Tier's are 1 indexed from the `tiers` array, meaning the 0th element of the array is tier 1.

    @param _tokenId The ID of the token to get the tier number of. 

    @return The tier number of the specified token ID.
  */
  function tierIdOfToken(uint256 _tokenId) public pure override returns (uint256) {
    return _tokenId / _ONE_BILLION;
  }

  /** 
    @notice
    The reserved token beneficiary for each tier. 

    @param _nft The NFT to get the reserved token beneficiary within.
    @param _tierId The ID of the tier to get a reserved token beneficiary of.

    @return The reserved token beneficiary.
  */
  function reservedTokenBeneficiaryOf(address _nft, uint256 _tierId)
    public
    view
    override
    returns (address)
  {
    // Get the stored reserved token beneficiary.
    address _storedReservedTokenBeneficiaryOfTier = _reservedTokenBeneficiaryOf[_nft][_tierId];

    // If the tier has a beneficiary return it.
    if (_storedReservedTokenBeneficiaryOfTier != address(0))
      return _storedReservedTokenBeneficiaryOfTier;

    // Return the default.
    return defaultReservedTokenBeneficiaryOf[_nft];
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Adds tiers. 

    @param _tiersToAdd The tiers to add.

    @return tierIds The IDs of the tiers added.
  */
  function recordAddTiers(JB721TierParams[] calldata _tiersToAdd)
    external
    override
    returns (uint256[] memory tierIds)
  {
    // Get a reference to the number of new tiers.
    uint256 _numberOfNewTiers = _tiersToAdd.length;

    // Keep a reference to the greatest tier ID.
    uint256 _currentMaxTierIdOf = maxTierIdOf[msg.sender];

    // Make sure the max number of tiers hasn't been reached.
    if(_currentMaxTierIdOf + _numberOfNewTiers > type(uint16).max) revert MAX_TIERS_EXCEEDED();

    // Keep a reference to the current last sorted tier ID.
    uint256 _currentLastSortIndex = _lastSortIndexOf(msg.sender);

    // Initialize an array with the appropriate length.
    tierIds = new uint256[](_numberOfNewTiers);

    // Keep a reference to the starting sort ID for sorting new tiers if needed.
    // There's no need for sorting if there are currently no tiers.
    // If there's no sort index, start with the first index.
    uint256 _startSortIndex = _currentMaxTierIdOf == 0 ? 0 : _firstSortIndexOf(msg.sender);

    // Keep track of the previous index.
    uint256 _previous;

    // Keep a reference to the tier being iterated on.
    JB721TierParams memory _tierToAdd;

    // Keep a reference to the flags.
    JBTiered721Flags memory _flags = _flagsOf[msg.sender];

    for (uint256 _i; _i < _numberOfNewTiers; ) {
      // Set the tier being iterated on.
      _tierToAdd = _tiersToAdd[_i];

      // Make sure the max is enforced.
      if (_tierToAdd.initialQuantity > _ONE_BILLION - 1) revert INVALID_QUANTITY();

      // Make sure the tier's contribution floor is greater than or equal to the previous contribution floor.
      if (_i != 0 && _tierToAdd.contributionFloor < _tiersToAdd[_i - 1].contributionFloor)
        revert INVALID_PRICE_SORT_ORDER();

      // Make sure there are no voting units set if they're not allowed.
      if (_flags.lockVotingUnitChanges && _tierToAdd.votingUnits != 0)
        revert VOTING_UNITS_NOT_ALLOWED();

      // Make sure a reserved rate isn't set if changes should be locked or if manual minting is allowed.
      if (
        (_flags.lockReservedTokenChanges || _tierToAdd.allowManualMint) &&
        _tierToAdd.reservedRate != 0
      ) revert RESERVED_RATE_NOT_ALLOWED();

      // Make sure manual minting is not set if not allowed.
      if (_flags.lockManualMintingChanges && _tierToAdd.allowManualMint)
        revert MANUAL_MINTING_NOT_ALLOWED();

      // Make sure there is some quantity.
      if (_tierToAdd.initialQuantity == 0) revert NO_QUANTITY();

      // Get a reference to the tier ID.
      uint256 _tierId = _currentMaxTierIdOf + _i + 1;

      // Add the tier with the iterative ID.
      _storedTierOf[msg.sender][_tierId] = JBStored721Tier({
        contributionFloor: uint80(_tierToAdd.contributionFloor),
        lockedUntil: uint48(_tierToAdd.lockedUntil),
        remainingQuantity: uint40(_tierToAdd.initialQuantity),
        initialQuantity: uint40(_tierToAdd.initialQuantity),
        votingUnits: uint16(_tierToAdd.votingUnits),
        reservedRate: uint16(_tierToAdd.reservedRate),
        allowManualMint: _tierToAdd.allowManualMint,
        transfersPausable: _tierToAdd.transfersPausable
      });

      // Set the reserved token beneficiary if needed.
      if (_tierToAdd.reservedTokenBeneficiary != address(0))
        if (_tierToAdd.shouldUseBeneficiaryAsDefault)
          defaultReservedTokenBeneficiaryOf[msg.sender] = _tierToAdd.reservedTokenBeneficiary;
        else _reservedTokenBeneficiaryOf[msg.sender][_tierId] = _tierToAdd.reservedTokenBeneficiary;

      // Set the encodedIPFSUri if needed.
      if (_tierToAdd.encodedIPFSUri != bytes32(0))
        encodedIPFSUriOf[msg.sender][_tierId] = _tierToAdd.encodedIPFSUri;

      if (_startSortIndex != 0) {
        // Keep track of the sort index.
        uint256 _currentSortIndex = _startSortIndex;

        // Initialize a BitmapWord for isRemoved
        JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(
          _currentSortIndex
        );

        // Keep a reference to the idex to iterate on next.
        uint256 _next;

        while (_currentSortIndex != 0) {
          // Is the current index outside the currently stored word?
          if (_bitmapWord.refreshBitmapNeeded(_currentSortIndex))
            _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(_currentSortIndex);

          // Set the next index.
          _next = _nextSortIndex(msg.sender, _currentSortIndex, _currentLastSortIndex);

          // If the contribution floor is less than the tier being iterated on, store the order.
          if (
            _tierToAdd.contributionFloor <
            _storedTierOf[msg.sender][_currentSortIndex].contributionFloor
          ) {
            // If the index being iterated on isn't the next index, set the after.
            if (_currentSortIndex != _tierId + 1)
              _tierIdAfter[msg.sender][_tierId] = _currentSortIndex;

            // If this is the last tier being added, track the current last sort index if it's not already tracked.
            if (
              _i == _numberOfNewTiers - 1 &&
              _trackedLastSortTierIdOf[msg.sender] != _currentLastSortIndex
            ) _trackedLastSortTierIdOf[msg.sender] = _currentLastSortIndex;

            // If the previous after index was set to something else, set the previous after.
            if (_previous != _tierId - 1 || _tierIdAfter[msg.sender][_previous] != 0)
              // Set the tier after the previous one being iterated on as the tier being added, or 0 if the index is incremented.
              _tierIdAfter[msg.sender][_previous] = _previous == _tierId - 1 ? 0 : _tierId;

            // For the next tier being added, start at this current index.
            _startSortIndex = _currentSortIndex;

            // The tier just added is the previous for the next tier being added.
            _previous = _tierId;

            // Set current to zero to break out of the loop.
            _currentSortIndex = 0;
          }
          // If the tier being iterated on is the last tier, add the tier after it.
          else if (_next == 0 || _next > _currentMaxTierIdOf) {
            if (_tierId != _currentSortIndex + 1)
              _tierIdAfter[msg.sender][_currentSortIndex] = _tierId;

            // For the next tier being added, start at this current index.
            _startSortIndex = _tierId;

            // Break out.
            _currentSortIndex = 0;

            // If there's currently a last sort index tracked, override it.
            if (_trackedLastSortTierIdOf[msg.sender] != 0) _trackedLastSortTierIdOf[msg.sender] = 0;
          }
          // Move on to the next index.
          else {
            // Set the previous index to be the current index.
            _previous = _currentSortIndex;

            // Go to the next index.
            _currentSortIndex = _next;
          }
        }
      }

      // Set the tier ID in the returned value.
      tierIds[_i] = _tierId;

      unchecked {
        ++_i;
      }
    }

    maxTierIdOf[msg.sender] = _currentMaxTierIdOf + _numberOfNewTiers;
  }

  /** 
    @notice
    Mint a token within the tier for the provided value.

    @dev
    Only a project owner can mint tokens.

    @param _tierId The ID of the tier to mint within.
    @param _count The number of reserved tokens to mint. 

    @return tokenIds The IDs of the tokens being minted as reserves.
  */
  function recordMintReservesFor(uint256 _tierId, uint256 _count)
    external
    override
    returns (uint256[] memory tokenIds)
  {
    // Get a reference to the tier.
    JBStored721Tier storage _storedTier = _storedTierOf[msg.sender][_tierId];

    // Get a reference to the number of reserved tokens mintable for the tier.
    uint256 _numberOfReservedTokensOutstanding = _numberOfReservedTokensOutstandingFor(
      msg.sender,
      _tierId,
      _storedTier
    );

    // Can't mint more reserves than expected.
    if (_count > _numberOfReservedTokensOutstanding) revert INSUFFICIENT_RESERVES();

    // Increment the number of reserved tokens minted.
    numberOfReservesMintedFor[msg.sender][_tierId] += _count;

    // Initialize an array with the appropriate length.
    tokenIds = new uint256[](_count);

    // Keep a reference to the number of burned in the tier.
    uint256 _numberOfBurnedFromTier = numberOfBurnedFor[msg.sender][_tierId];

    for (uint256 _i; _i < _count; ) {
      // Generate the tokens.
      tokenIds[_i] = _generateTokenId(
        _tierId,
        _storedTier.initialQuantity - --_storedTier.remainingQuantity + _numberOfBurnedFromTier
      );

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Sets the reserved token beneficiary.

    @param _beneficiary The reserved token beneficiary.
  */
  function recordSetDefaultReservedTokenBeneficiary(address _beneficiary) external override {
    defaultReservedTokenBeneficiaryOf[msg.sender] = _beneficiary;
  }

  /** 
    @notice
    Record a token transfer.

    @param _tierId The ID the tier being transferred.
    @param _from The sender of the token.
    @param _to The recipient of the token.
  */
  function recordTransferForTier(
    uint256 _tierId,
    address _from,
    address _to
  ) external override {
    // If this is not a mint then subtract the tier balance from the original holder.
    if (_from != address(0))
      // decrease the tier balance for the sender
      --tierBalanceOf[msg.sender][_from][_tierId];

    // if this is a burn the balance is not added
    if (_to != address(0)) {
      unchecked {
        // increase the tier balance for the beneficiary
        ++tierBalanceOf[msg.sender][_to][_tierId];
      }
    }
  }

  /** 
    @notice
    Remove tiers. 

    @param _tierIds The tiers IDs to remove.
  */
  function recordRemoveTierIds(uint256[] calldata _tierIds) external override {
    // Get a reference to the number of tiers being removed.
    uint256 _numTiers = _tierIds.length;

    // Keep a reference to the tier ID being iterated on.
    uint256 _tierId;

    for (uint256 _i; _i < _numTiers; ) {
      // Set the tier being iterated on, 0-indexed
      _tierId = _tierIds[_i];

      // If the tier is locked throw an error.
      if (_storedTierOf[msg.sender][_tierId].lockedUntil >= block.timestamp) revert TIER_LOCKED();

      // Set the tier as removed.
      _isTierRemovedBitmapWord[msg.sender].removeTier(_tierId);

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Mints a token in the best available tier.

    @param _amount The amount to base the mint on.

    @return tokenId The token ID minted.
    @return tierId The ID of the tier minted from.
    @return leftoverAmount The amount leftover after the mint. 
  */
  function recordMintBestAvailableTier(uint256 _amount)
    external
    override
    returns (
      uint256 tokenId,
      uint256 tierId,
      uint256 leftoverAmount
    )
  {
    // If no tiers at all, exit early without token to mint
    if (maxTierIdOf[msg.sender] == 0) return (0, 0, _amount);

    // Keep a reference to the last tier ID.
    uint256 _lastTierId = _lastSortIndexOf(msg.sender);

    // Keep a reference to the tier being iterated on.
    JBStored721Tier memory _storedTier;

    // Keep a reference to the starting sort ID for sorting new tiers if needed.
    // There's no need for sorting if there are currently no tiers.
    // If there's no sort index, start with the first index.
    uint256 _currentSortIndex = _firstSortIndexOf(msg.sender);

    // Keep a reference to the best contribution floor.
    uint256 _bestContributionFloor;

    // Initialize a BitmapWord to read isRemoved
    JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(
      _currentSortIndex
    );

    while (_currentSortIndex != 0) {
      // Set the tier being iterated on. Tier's are 1 indexed.
      _storedTier = _storedTierOf[msg.sender][_currentSortIndex];

      // Is the current index outside the currently stored word?
      if (_bitmapWord.refreshBitmapNeeded(_currentSortIndex))
        _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(_currentSortIndex);

      // If the contribution floor has gone over, break out of the loop.
      if (_storedTier.contributionFloor > _amount) _currentSortIndex = 0;
      else {
        // If the tier is not removed, check to see if it's optimal.
        // Set the tier as the best available so far if there is still a remaining quantity.
        if (
          !_bitmapWord.isTierIdRemoved(_currentSortIndex) &&
          _storedTier.contributionFloor > _bestContributionFloor &&
          (_storedTier.remainingQuantity -
            _numberOfReservedTokensOutstandingFor(msg.sender, _currentSortIndex, _storedTier)) !=
          0
        ) {
          tierId = _currentSortIndex;
          _bestContributionFloor = _storedTier.contributionFloor;
        }

        // Set the next sort index.
        _currentSortIndex = _nextSortIndex(msg.sender, _currentSortIndex, _lastTierId);
      }
    }

    // If there's no best tier, return.
    if (tierId == 0) leftoverAmount = _amount;
    else {
      // Keep a reference to the best tier.
      JBStored721Tier storage _bestStoredTier = _storedTierOf[msg.sender][tierId];

      // Make the token ID.
      unchecked {
        // Keep a reference to the token ID.
        tokenId = _generateTokenId(
          tierId,
          _bestStoredTier.initialQuantity -
            --_bestStoredTier.remainingQuantity +
            numberOfBurnedFor[msg.sender][tierId]
        );
      }

      // Set the leftover amount.
      leftoverAmount = _amount - _bestContributionFloor;
    }
  }

  /** 
    @notice
    Mints a token in all provided tiers.

    @param _amount The amount to base the mints on. All mints' price floors must fit in this amount.
    @param _tierIds The IDs of the tier to mint from.
    @param _isManualMint A flag indicating if the mint is being made manually by the NFT's owner.

    @return tokenIds The IDs of the tokens minted.
    @return leftoverAmount The amount leftover after the mint.
  */
  function recordMint(
    uint256 _amount,
    uint16[] calldata _tierIds,
    bool _isManualMint
  ) external override returns (uint256[] memory tokenIds, uint256 leftoverAmount) {
    // Set the leftover amount as the initial amount.
    leftoverAmount = _amount;

    // Get a reference to the number of tiers.
    uint256 _numberOfTiers = _tierIds.length;

    // Keep a reference to the tier being iterated on.
    JBStored721Tier storage _storedTier;

    // Keep a reference to the tier ID being iterated on.
    uint256 _tierId;

    // Initialize an array with the appropriate length.
    tokenIds = new uint256[](_numberOfTiers);

    // Initialize a BitmapWord for isRemoved.
    JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(_tierIds[0]);

    for (uint256 _i; _i < _numberOfTiers; ) {
      // Set the tier ID being iterated on.
      _tierId = _tierIds[_i];

      // Is the current index outside the currently stored word?
      if (_bitmapWord.refreshBitmapNeeded(_tierId))
        _bitmapWord = _isTierRemovedBitmapWord[msg.sender].readId(_tierId);

      // Make sure the tier hasn't been removed.
      if (_bitmapWord.isTierIdRemoved(_tierId)) revert TIER_REMOVED();

      // Keep a reference to the tier being iterated on.
      _storedTier = _storedTierOf[msg.sender][_tierId];

      // If this is a manual mint, make sure manual minting is allowed.
      if (_isManualMint && !_storedTier.allowManualMint) revert CANT_MINT_MANUALLY();

      // Make sure the provided tier exists.
      if (_storedTier.initialQuantity == 0) revert INVALID_TIER();

      // Make sure the amount meets the tier's contribution floor.
      if (_storedTier.contributionFloor > leftoverAmount) revert INSUFFICIENT_AMOUNT();

      // Make sure there are enough units available.
      if (
        _storedTier.remainingQuantity -
          _numberOfReservedTokensOutstandingFor(msg.sender, _tierId, _storedTier) ==
        0
      ) revert OUT();

      // Mint the tokens.
      unchecked {
        // Keep a reference to the token ID.
        tokenIds[_i] = _generateTokenId(
          _tierId,
          _storedTier.initialQuantity -
            --_storedTier.remainingQuantity +
            numberOfBurnedFor[msg.sender][_tierId]
        );
      }

      // Update the leftover amount;
      leftoverAmount = leftoverAmount - _storedTier.contributionFloor;

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Records burned tokens.

    @param _tokenIds The IDs of the tokens burned.
  */
  function recordBurn(uint256[] calldata _tokenIds) external override {
    // Get a reference to the number of token IDs provided.
    uint256 _numberOfTokenIds = _tokenIds.length;

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    // Iterate through all tokens to increment the burn count.
    for (uint256 _i; _i < _numberOfTokenIds; ) {
      // Set the token's ID.
      _tokenId = _tokenIds[_i];

      uint256 _tierId = tierIdOfToken(_tokenId);

      // Increment the number burned for the tier.
      numberOfBurnedFor[msg.sender][_tierId]++;

      _storedTierOf[msg.sender][_tierId].remainingQuantity++;

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Sets the first owner of a token.

    @param _tokenId The ID of the token having the first owner set.
    @param _owner The owner to set as the first owner.
  */
  function recordSetFirstOwnerOf(uint256 _tokenId, address _owner) external override {
    firstOwnerOf[msg.sender][_tokenId] = _owner;
  }

  /** 
    @notice
    Sets the base URI. 

    @param _uri The base URI to set.
  */
  function recordSetBaseUri(string calldata _uri) external override {
    baseUriOf[msg.sender] = _uri;
  }

  /** 
    @notice
    Sets the contract URI. 

    @param _uri The contract URI to set.
  */
  function recordSetContractUri(string calldata _uri) external override {
    contractUriOf[msg.sender] = _uri;
  }

  /** 
    @notice
    Sets the token URI resolver. 

    @param _resolver The resolver to set.
  */
  function recordSetTokenUriResolver(IJBTokenUriResolver _resolver) external override {
    tokenUriResolverOf[msg.sender] = _resolver;
  }

  /** 
    @notice
    Sets flags. 

    @param _flags The flag to sets.
  */
  function recordFlags(JBTiered721Flags calldata _flags) external override {
    _flagsOf[msg.sender] = _flags;
  }

  /** 
    @notice
    Removes removed tiers from sequencing.

    @param _nft The NFT contract to clean tiers for.
  */
  function cleanTiers(address _nft) external override {
    // Keep a reference to the last tier ID.
    uint256 _lastTierId = _lastSortIndexOf(_nft);

    // Get a reference to the index being iterated on, starting with the starting index.
    uint256 _currentSortIndex = _firstSortIndexOf(_nft);

    // Keep track of the previous non-removed index.
    uint256 _previous;

    // Initialize a BitmapWord for isRemoved.
    JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_currentSortIndex);

    // Make the sorted array.
    while (_currentSortIndex != 0) {
      // Is the current index outside the currently stored word?
      if (_bitmapWord.refreshBitmapNeeded(_currentSortIndex))
        _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_currentSortIndex);

      if (!_bitmapWord.isTierIdRemoved(_currentSortIndex)) {
        // If the current index being iterated on isn't an increment of the previous, set the correct tier after if needed.
        if (_currentSortIndex != _previous + 1) {
          if (_tierIdAfter[_nft][_previous] != _currentSortIndex)
            _tierIdAfter[_nft][_previous] = _currentSortIndex;
          // Otherwise if the current index is an increment of the previous and the after index isn't 0, set it to 0.
        } else if (_tierIdAfter[_nft][_previous] != 0) _tierIdAfter[_nft][_previous] = 0;

        // Set the previous index to be the current index.
        _previous = _currentSortIndex;
      }
      // Set the next sort index.
      _currentSortIndex = _nextSortIndex(_nft, _currentSortIndex, _lastTierId);
    }

    emit CleanTiers(_nft, msg.sender);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice
    The number of reserved tokens that can currently be minted within the tier. 

    @param _nft The NFT to get reserved tokens outstanding.
    @param _tierId The ID of the tier to get a number of reserved tokens outstanding.
    @param _storedTier The tier to get a number of reserved tokens outstanding.

    @return numberReservedTokensOutstanding The outstanding number of reserved tokens within the tier.
  */
  function _numberOfReservedTokensOutstandingFor(
    address _nft,
    uint256 _tierId,
    JBStored721Tier memory _storedTier
  ) internal view returns (uint256) {
    // No reserves outstanding if no mints or no reserved rate.
    if (
      _storedTier.reservedRate == 0 || _storedTier.initialQuantity == _storedTier.remainingQuantity
    ) return 0;

    // The number of reserved tokens of the tier already minted.
    uint256 _reserveTokensMinted = numberOfReservesMintedFor[_nft][_tierId];

    // If only the reserved token (from the rounding up) has been minted so far, return 0.
    if (_storedTier.initialQuantity - _reserveTokensMinted == _storedTier.remainingQuantity)
      return 0;

    // Get a reference to the number of tokens already minted in the tier, not counting reserves or burned tokens.
    uint256 _numberOfNonReservesMinted = _storedTier.initialQuantity -
      _storedTier.remainingQuantity -
      _reserveTokensMinted;

    // Get the number of reserved tokens mintable given the number of non reserved tokens minted. This will round down.
    uint256 _numberReservedTokensMintable = _numberOfNonReservesMinted / _storedTier.reservedRate;

    // Round up.
    if (_numberOfNonReservesMinted % _storedTier.reservedRate > 0) ++_numberReservedTokensMintable;

    // Make sure there are more mintable than have been minted. This is possible if some tokens have been burned.
    if (_reserveTokensMinted > _numberReservedTokensMintable) return 0;

    // Return the difference between the amount mintable and the amount already minted.
    return _numberReservedTokensMintable - _reserveTokensMinted;
  }

  /** 
    @notice
    Finds the token ID and tier given a contribution amount. 

    @param _tierId The ID of the tier to generate an ID for.
    @param _tokenNumber The number of the token in the tier.

    @return The ID of the token.
  */
  function _generateTokenId(uint256 _tierId, uint256 _tokenNumber)
    internal
    pure
    returns (uint256)
  {
    return (_tierId * _ONE_BILLION) + _tokenNumber;
  }

  /** 
    @notice 
    The next sorted index. 

    @param _nft The NFT for which the sort index applies.
    @param _index The index relative to which the next sorted index will be returned.
    @param _max The maximum possible index.

    @return The index.
  */
  function _nextSortIndex(
    address _nft,
    uint256 _index,
    uint256 _max
  ) internal view returns (uint256) {
    // If this is the last tier, set current to zero to break out of the loop.
    if (_index == _max) return 0;
    // Update the current index to be the one saved to be after, if it exists.
    uint256 _storedNext = _tierIdAfter[_nft][_index];
    if (_storedNext != 0) return _storedNext;
    // Otherwise increment the current.
    return _index + 1;
  }

  /** 
    @notice
    The first sorted tier index of an NFT.

    @param _nft The NFT to get the first sorted tier index of.

    @return index The first sorted tier index.
  */
  function _firstSortIndexOf(address _nft) internal view returns (uint256 index) {
    index = _tierIdAfter[_nft][0];
    // Start at the first index if nothing is specified.
    if (index == 0) index = 1;
  }

  /** 
    @notice
    The last sorted tier index of an NFT.

    @param _nft The NFT to get the last sorted tier index of.

    @return index The last sorted tier index.
  */
  function _lastSortIndexOf(address _nft) internal view returns (uint256 index) {
    index = _trackedLastSortTierIdOf[_nft];
    // Start at the first index if nothing is specified.
    if (index == 0) index = maxTierIdOf[_nft];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JB721Tier.sol';
import './../structs/JBTiered721Flags.sol';

interface IJBTiered721DelegateStore {
  event CleanTiers(address indexed nft, address caller);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function maxTierIdOf(address _nft) external view returns (uint256);

  function tiers(
    address _nft,
    uint256 _startingSortIndex,
    uint256 _size
  ) external view returns (JB721Tier[] memory tiers);

  function tier(address _nft, uint256 _id) external view returns (JB721Tier memory tier);

  function tierBalanceOf(
    address _nft,
    address _owner,
    uint256 _tier
  ) external view returns (uint256);

  function tierOfTokenId(address _nft, uint256 _tokenId)
    external
    view
    returns (JB721Tier memory tier);

  function tierIdOfToken(uint256 _tokenId) external pure returns (uint256);

  function encodedIPFSUriOf(address _nft, uint256 _tierId) external view returns (bytes32);

  function firstOwnerOf(address _nft, uint256 _tokenId) external view returns (address);

  function redemptionWeightOf(address _nft, uint256[] memory _tokenIds)
    external
    view
    returns (uint256 weight);

  function totalRedemptionWeight(address _nft) external view returns (uint256 weight);

  function numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId)
    external
    view
    returns (uint256);

  function numberOfReservesMintedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function numberOfBurnedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function isTierRemoved(address _nft, uint256 _tierId) external view returns (bool);

  function flagsOf(address _nft) external view returns (JBTiered721Flags memory);

  function votingUnitsOf(address _nft, address _account) external view returns (uint256 units);

  function tierVotingUnitsOf(
    address _nft,
    address _account,
    uint256 _tierId
  ) external view returns (uint256 units);

  function defaultReservedTokenBeneficiaryOf(address _nft) external view returns (address);

  function reservedTokenBeneficiaryOf(address _nft, uint256 _tierId)
    external
    view
    returns (address);

  function baseUriOf(address _nft) external view returns (string memory);

  function contractUriOf(address _nft) external view returns (string memory);

  function tokenUriResolverOf(address _nft) external view returns (IJBTokenUriResolver);

  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view returns (bytes32);

  function recordAddTiers(JB721TierParams[] memory _tierData)
    external
    returns (uint256[] memory tierIds);

  function recordMintReservesFor(uint256 _tierId, uint256 _count)
    external
    returns (uint256[] memory tokenIds);

  function recordMintBestAvailableTier(uint256 _amount)
    external
    returns (
      uint256 tokenId,
      uint256 tierId,
      uint256 leftoverAmount
    );

  function recordBurn(uint256[] memory _tokenIds) external;

  function recordSetDefaultReservedTokenBeneficiary(address _beneficiary) external;

  function recordMint(
    uint256 _amount,
    uint16[] calldata _tierIds,
    bool _isManualMint
  ) external returns (uint256[] memory tokenIds, uint256 leftoverAmount);

  function recordTransferForTier(
    uint256 _tierId,
    address _from,
    address _to
  ) external;

  function recordRemoveTierIds(uint256[] memory _tierIds) external;

  function recordSetFirstOwnerOf(uint256 _tokenId, address _owner) external;

  function recordSetBaseUri(string memory _uri) external;

  function recordSetContractUri(string memory _uri) external;

  function recordSetTokenUriResolver(IJBTokenUriResolver _resolver) external;

  function recordFlags(JBTiered721Flags calldata _flag) external;

  function cleanTiers(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '../structs/JBBitmapWord.sol';

/**
  @notice
  Utilities to manage bool bitmap storing the inactive tiers.
*/
library JBBitmap {
  /**
    @notice
    Initialize a BitmapWord struct, based on the mapping storage pointer and a given index.
  */
  function readId(mapping(uint256 => uint256) storage self, uint256 _index)
    internal
    view
    returns (JBBitmapWord memory)
  {
    uint256 _depth = _retrieveDepth(_index);

    return JBBitmapWord({currentWord: self[_depth], currentDepth: _depth});
  }

  /**
    @notice
    Returns the status of a given bit, in the single word stored in a BitmapWord struct.
  */
  function isTierIdRemoved(JBBitmapWord memory self, uint256 _index) internal pure returns (bool) {
    return (self.currentWord >> (_index % 256)) & 1 == 1;
  }

  /**
    @notice
    Returns the status of a bit in a given bitmap (index is the index in the reshaped bitmap matrix 1*n).
  */
  function isTierIdRemoved(mapping(uint256 => uint256) storage self, uint256 _index)
    internal
    view
    returns (bool)
  {
    uint256 _depth = _retrieveDepth(_index);
    return isTierIdRemoved(JBBitmapWord({currentWord: self[_depth], currentDepth: _depth}), _index);
  }

  /**
    @notice
    Flip the bit at a given index to true (this is a one-way operation).
  */
  function removeTier(mapping(uint256 => uint256) storage self, uint256 _index) internal {
    uint256 _depth = _retrieveDepth(_index);
    self[_depth] |= uint256(1 << (_index % 256));
  }

  /**
    @notice
    Return true if the index is in an another word than the one stored in the BitmapWord struct.
  */
  function refreshBitmapNeeded(JBBitmapWord memory self, uint256 _index)
    internal
    pure
    returns (bool)
  {
    return _retrieveDepth(_index) != self.currentDepth;
  }

  // Lib internal

  /**
    @notice
    Return the lines of the bitmap matrix where an index lies.
  */
  function _retrieveDepth(uint256 _index) internal pure returns (uint256) {
    return _index >> 8; // div by 256
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  @member id The tier's ID.
  @member contributionFloor The minimum contribution to qualify for this tier.
  @member lockedUntil The time up to which this tier cannot be removed or paused.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
*/
struct JB721Tier {
  uint256 id;
  uint256 contributionFloor;
  uint256 lockedUntil;
  uint256 remainingQuantity;
  uint256 initialQuantity;
  uint256 votingUnits;
  uint256 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  bool allowManualMint;
  bool transfersPausable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member contributionFloor The minimum contribution to qualify for this tier.
  @member lockedUntil The time up to which this tier cannot be removed or paused.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @memver reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member shouldUseBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
*/
struct JB721TierParams {
  uint80 contributionFloor;
  uint48 lockedUntil;
  uint40 initialQuantity;
  uint16 votingUnits;
  uint16 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  bool allowManualMint;
  bool shouldUseBeneficiaryAsDefault;
  bool transfersPausable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member The information stored at the index.
  @member The index.
*/
struct JBBitmapWord {
  uint256 currentWord;
  uint256 currentDepth;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member contributionFloor The minimum contribution to qualify for this tier.
  @member lockedUntil The time up to which this tier cannot be removed or paused.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
*/
struct JBStored721Tier {
  uint80 contributionFloor;
  uint48 lockedUntil;
  uint40 remainingQuantity;
  uint40 initialQuantity;
  uint16 votingUnits;
  uint16 reservedRate;
  bool allowManualMint;
  bool transfersPausable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
  @member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
  @member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
*/
struct JBTiered721Flags {
  bool lockReservedTokenChanges;
  bool lockVotingUnitChanges;
  bool lockManualMintingChanges;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}