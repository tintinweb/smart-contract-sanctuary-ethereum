// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/Checkpoints.sol';
import './interfaces/IJB721TieredGovernance.sol';
import './JBTiered721Delegate.sol';

/**
  @title
  JB721TieredGovernance

  @notice
  A tiered 721 delegate where each NFT can be used for on chain governance, with votes delegatable per tier.

  @dev
  Adheres to -
  IJB721TieredGovernance: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBTiered721Delegate: The tiered 721 delegate.
  Votes: A helper for voting balance snapshots.
*/
contract JB721TieredGovernance is JBTiered721Delegate, IJB721TieredGovernance {
  using Checkpoints for Checkpoints.History;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error BLOCK_NOT_YET_MINED();
  error DELEGATE_ADDRESS_ZERO();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    The delegation status for each address and for each tier.

    _delegator The delegator.
    _tierId The ID of the tier being delegated.
  */
  mapping(address => mapping(uint256 => address)) internal _tierDelegation;

  /**
    @notice
    The delegation checkpoints for each address and for each tier.

    _delegator The delegator.
    _tierId The ID of the tier being delegated.
  */
  mapping(address => mapping(uint256 => Checkpoints.History)) internal _delegateTierCheckpoints;

  /**
    @notice
    The total delegation status for each tier.

    _tierId The ID of the tier being delegated.
  */
  mapping(uint256 => Checkpoints.History) internal _totalTierCheckpoints;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    Returns the delegate of an account for specific tier.

    @param _account The account to check for a delegate of.
    @param _tier the tier to check within.
  */
  function getTierDelegate(address _account, uint256 _tier)
    external
    view
    override
    returns (address)
  {
    return _tierDelegation[_account][_tier];
  }

  /**
    @notice
    Returns the current voting power of an address for a specific tier.

    @param _account The address to check.
    @param _tier The tier to check within.
  */
  function getTierVotes(address _account, uint256 _tier) external view override returns (uint256) {
    return _delegateTierCheckpoints[_account][_tier].latest();
  }

  /**
    @notice
    Returns the past voting power of a specific address for a specific tier.

    @param _account The address to check.
    @param _tier The tier to check within.
    @param _blockNumber the blocknumber to check the voting power at.
  */
  function getPastTierVotes(
    address _account,
    uint256 _tier,
    uint256 _blockNumber
  ) external view override returns (uint256) {
    return _delegateTierCheckpoints[_account][_tier].getAtBlock(_blockNumber);
  }

  /**
    @notice
    Returns the total amount of voting power that exists for a tier.

    @param _tier The tier to check.
  */
  function getTierTotalVotes(uint256 _tier) external view override returns (uint256) {
    return _totalTierCheckpoints[_tier].latest();
  }

  /**
    @notice
    Returns the total amount of voting power that exists for a tier.

    @param _tier The tier to check.
    @param _blockNumber The blocknumber to check the total voting power at.
  */
  function getPastTierTotalVotes(uint256 _tier, uint256 _blockNumber)
    external
    view
    override
    returns (uint256)
  {
    return _totalTierCheckpoints[_tier].getAtBlock(_blockNumber);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice 
    Delegates votes from the sender to `delegatee`.

    @param _setTierDelegatesData An array of tiers to set delegates for.
   */
  function setTierDelegates(JBTiered721SetTierDelegatesData[] memory _setTierDelegatesData)
    external
    virtual
    override
  {
    // Keep a reference to the number of tier delegates.
    uint256 _numberOfTierDelegates = _setTierDelegatesData.length;

    // Keep a reference to the data being iterated on.
    JBTiered721SetTierDelegatesData memory _data;

    for (uint256 _i; _i < _numberOfTierDelegates; ) {
      // Reference the data being iterated on.
      _data = _setTierDelegatesData[_i];

      // No active delegation to the address 0
      if (_data.delegatee == address(0)) revert DELEGATE_ADDRESS_ZERO();

      _delegateTier(msg.sender, _data.delegatee, _data.tierId);

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice 
    Delegates votes from the sender to `delegatee`.

    @param _delegatee The account to delegate tier voting units to.
    @param _tierId The ID of the tier to delegate voting units for.
   */
  function setTierDelegate(address _delegatee, uint256 _tierId) public virtual override {
    _delegateTier(msg.sender, _delegatee, _tierId);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice 
    Gets the amount of voting units an address has for a particular tier.

    @param _account The account to get voting units for.
    @param _tierId The ID of the tier to get voting units for.

    @return The voting units.
  */
  function _getTierVotingUnits(address _account, uint256 _tierId)
    internal
    view
    virtual
    returns (uint256)
  {
    return store.tierVotingUnitsOf(address(this), _account, _tierId);
  }

  /**
    @notice 
    Delegate all of `account`'s voting units for the specified tier to `delegatee`.

    @param _account The account delegating tier voting units.
    @param _delegatee The account to delegate tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
  */
  function _delegateTier(
    address _account,
    address _delegatee,
    uint256 _tierId
  ) internal virtual {
    // Get the current delegatee
    address _oldDelegate = _tierDelegation[_account][_tierId];

    // Store the new delegatee
    _tierDelegation[_account][_tierId] = _delegatee;

    emit DelegateChanged(_account, _oldDelegate, _delegatee);

    // Move the votes.
    _moveTierDelegateVotes(
      _oldDelegate,
      _delegatee,
      _tierId,
      _getTierVotingUnits(_account, _tierId)
    );
  }

  /**
    @notice 
    Transfers, mints, or burns tier voting units. To register a mint, `from` should be zero. To register a burn, `to` should be zero. Total supply of voting units will be adjusted with mints and burns.

    @param _from The account to transfer tier voting units from.
    @param _to The account to transfer tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
    @param _amount The amount of voting units to delegate.
   */
  function _transferTierVotingUnits(
    address _from,
    address _to,
    uint256 _tierId,
    uint256 _amount
  ) internal virtual {
    // If minting, add to the total tier checkpoints.
    if (_from == address(0)) _totalTierCheckpoints[_tierId].push(_add, _amount);

    // If burning, subtract from the total tier checkpoints.
    if (_to == address(0)) _totalTierCheckpoints[_tierId].push(_subtract, _amount);

    // Move delegated votes.
    _moveTierDelegateVotes(
      _tierDelegation[_from][_tierId],
      _tierDelegation[_to][_tierId],
      _tierId,
      _amount
    );
  }

  /**
    @notice 
    Moves delegated tier votes from one delegate to another.

    @param _from The account to transfer tier voting units from.
    @param _to The account to transfer tier voting units to.
    @param _tierId The ID of the tier for which voting units are being transferred.
    @param _amount The amount of voting units to delegate.
  */
  function _moveTierDelegateVotes(
    address _from,
    address _to,
    uint256 _tierId,
    uint256 _amount
  ) internal {
    // Nothing to do if moving to the same account, or no amount is being moved.
    if (_from == _to || _amount == 0) return;

    // If not moving from the zero address, update the checkpoints to subtract the amount.
    if (_from != address(0)) {
      (uint256 _oldValue, uint256 _newValue) = _delegateTierCheckpoints[_from][_tierId].push(
        _subtract,
        _amount
      );
      emit TierDelegateVotesChanged(_from, _tierId, _oldValue, _newValue, msg.sender);
    }

    // If not moving to the zero address, update the checkpoints to add the amount.
    if (_to != address(0)) {
      (uint256 _oldValue, uint256 _newValue) = _delegateTierCheckpoints[_to][_tierId].push(
        _add,
        _amount
      );
      emit TierDelegateVotesChanged(_to, _tierId, _oldValue, _newValue, msg.sender);
    }
  }

  /**
   @notice
   handles the tier voting accounting

    @param _from The account to transfer voting units from.
    @param _to The account to transfer voting units to.
    @param _tokenId The ID of the token for which voting units are being transferred.
    @param _tier The tier the token ID is part of.
   */
  function _afterTokenTransferAccounting(
    address _from,
    address _to,
    uint256 _tokenId,
    JB721Tier memory _tier
  ) internal virtual override {
    _tokenId; // Prevents unused var compiler and natspec complaints.
    if (_tier.votingUnits != 0)
      // Transfer the voting units.
      _transferTierVotingUnits(_from, _to, _tier.id, _tier.votingUnits);
  }

  // Utils from the Votes extension that is being reused for tier delegation.
  function _add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBFundingCycleMetadataResolver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './abstract/JB721Delegate.sol';
import './interfaces/IJBTiered721Delegate.sol';
import './libraries/JBIpfsDecoder.sol';
import './libraries/JBTiered721FundingCycleMetadataResolver.sol';
import './structs/JBTiered721Flags.sol';

/**
  @title
  JBTiered721Delegate

  @notice
  Delegate that offers project contributors NFTs with tiered price floors upon payment and the ability to redeem NFTs for treasury assets based based on price floor.

  @dev
  Adheres to -
  IJBTiered721Delegate: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  IERC2981: Royalty standard.

  @dev
  Inherits from -
  JB721Delegate: A generic NFT delegate.
  Votes: A helper for voting balance snapshots.
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
contract JBTiered721Delegate is JB721Delegate, Ownable, IJBTiered721Delegate, IERC2981 {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error NOT_AVAILABLE();
  error OVERSPENDING();
  error PRICING_RESOLVER_CHANGES_PAUSED();
  error RESERVED_TOKEN_MINTING_PAUSED();
  error TRANSFERS_PAUSED();

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    The address of the origin 'JBTiered721Delegate', used to check in the init if the contract is the original or not
  */
  address public override codeOrigin;

  /**
    @notice
    The contract that stores and manages the NFT's data.
  */
  IJBTiered721DelegateStore public override store;

  /**
    @notice
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public override fundingCycleStore;

  /**
    @notice
    The contract that exposes price feeds.
  */
  IJBPrices public override prices;

  /** 
    @notice
    The currency that is accepted when minting tier NFTs. 
  */
  uint256 public override pricingCurrency;

  /** 
    @notice
    The currency that is accepted when minting tier NFTs. 
  */
  uint256 public override pricingDecimals;

  /** 
    @notice
    The amount that each address has paid that has not yet contribute to the minting of an NFT. 

    _address The address to which the credits belong.
  */
  mapping(address => uint256) public override creditsOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    The first owner of each token ID, which corresponds to the address that originally contributed to the project to receive the NFT.

    @param _tokenId The ID of the token to get the first owner of.

    @return The first owner of the token.
  */
  function firstOwnerOf(uint256 _tokenId) external view override returns (address) {
    // Get a reference to the first owner.
    address _storedFirstOwner = store.firstOwnerOf(address(this), _tokenId);

    // If the stored first owner is set, return it.
    if (_storedFirstOwner != address(0)) return _storedFirstOwner;

    // Otherwise, the first owner must be the current owner.
    return _owners[_tokenId];
  }

  /**
    @notice 
    Royalty info conforming to EIP-2981.

    @param _tokenId The ID of the token that the royalty is for.
    @param _salePrice The price being paid for the token.

    @return The address of the royalty's receiver.
    @return The amount of the royalty.
  */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override
    returns (address, uint256)
  {
    return store.royaltyInfo(address(this), _tokenId, _salePrice);
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The total number of tokens owned by the given owner across all tiers. 

    @param _owner The address to check the balance of.

    @return balance The number of tokens owners by the owner across all tiers.
  */
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return store.balanceOf(address(this), _owner);
  }

  /** 
    @notice
    The metadata URI of the provided token ID.

    @dev
    Defer to the tokenUriResolver if set, otherwise, use the tokenUri set with the token's tier.

    @param _tokenId The ID of the token to get the tier URI for. 

    @return The token URI corresponding with the tier or the tokenUriResolver URI.
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    // Get a reference to the URI resolver.
    IJBTokenUriResolver _resolver = store.tokenUriResolverOf(address(this));

    // If a token URI resolver is provided, use it to resolve the token URI.
    if (address(_resolver) != address(0)) return _resolver.getUri(_tokenId);

    // Return the token URI for the token's tier.
    return
      JBIpfsDecoder.decode(
        store.baseUriOf(address(this)),
        store.encodedTierIPFSUriOf(address(this), _tokenId)
      );
  }

  /** 
    @notice
    Returns the URI where contract metadata can be found. 

    @return The contract's metadata URI.
  */
  function contractURI() external view virtual override returns (string memory) {
    return store.contractUriOf(address(this));
  }

  /** 
    @notice
    The cumulative weight the given token IDs have in redemptions compared to the `_totalRedemptionWeight`. 

    @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.

    @return The weight.
  */
  function redemptionWeightOf(uint256[] memory _tokenIds, JBRedeemParamsData calldata)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return store.redemptionWeightOf(address(this), _tokenIds);
  }

  /** 
    @notice
    The cumulative weight that all token IDs have in redemptions. 

    @return The total weight.
  */
  function totalRedemptionWeight(JBRedeemParamsData calldata)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return store.totalRedemptionWeight(address(this));
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherence to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(JB721Delegate, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBTiered721Delegate).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  constructor() {
    codeOrigin = address(this);
  }

  /**
    @param _projectId The ID of the project this contract's functionality applies to.
    @param _directory The directory of terminals and controllers for projects.
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
    @param _baseUri A URI to use as a base for full token URIs.
    @param _tokenUriResolver A contract responsible for resolving the token URI for each token ID.
    @param _contractUri A URI where contract metadata can be found. 
    @param _pricing The tier pricing according to which token distribution will be made. Must be passed in order of contribution floor, with implied increasing value.
    @param _store A contract that stores the NFT's data.
    @param _flags A set of flags that help define how this contract works.
  */
  function initialize(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol,
    IJBFundingCycleStore _fundingCycleStore,
    string memory _baseUri,
    IJBTokenUriResolver _tokenUriResolver,
    string memory _contractUri,
    JB721PricingParams memory _pricing,
    IJBTiered721DelegateStore _store,
    JBTiered721Flags memory _flags
  ) public override {
    // Make the original un-initializable.
    if (address(this) == codeOrigin) revert();

    // Stop re-initialization.
    if (address(store) != address(0)) revert();

    // Initialize the superclass.
    JB721Delegate._initialize(_projectId, _directory, _name, _symbol);

    fundingCycleStore = _fundingCycleStore;
    store = _store;
    pricingCurrency = _pricing.currency;
    pricingDecimals = _pricing.decimals;
    prices = _pricing.prices;

    // Store the base URI if provided.
    if (bytes(_baseUri).length != 0) _store.recordSetBaseUri(_baseUri);

    // Set the contract URI if provided.
    if (bytes(_contractUri).length != 0) _store.recordSetContractUri(_contractUri);

    // Set the token URI resolver if provided.
    if (_tokenUriResolver != IJBTokenUriResolver(address(0)))
      _store.recordSetTokenUriResolver(_tokenUriResolver);

    // Record adding the provided tiers.
    if (_pricing.tiers.length > 0) _store.recordAddTiers(_pricing.tiers);

    // Set the flags if needed.
    if (
      _flags.lockReservedTokenChanges ||
      _flags.lockVotingUnitChanges ||
      _flags.lockManualMintingChanges ||
      _flags.preventOverspending
    ) _store.recordFlags(_flags);

    // Transfer ownership to the initializer.
    _transferOwnership(msg.sender);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Mint reserved tokens within the tier for the provided value.

    @param _mintReservesForTiersData Contains information about how many reserved tokens to mint for each tier.
  */
  function mintReservesFor(JBTiered721MintReservesForTiersData[] calldata _mintReservesForTiersData)
    external
    override
  {
    // Keep a reference to the number of tiers there are to mint reserves for.
    uint256 _numberOfTiers = _mintReservesForTiersData.length;

    for (uint256 _i; _i < _numberOfTiers; ) {
      // Get a reference to the data being iterated on.
      JBTiered721MintReservesForTiersData memory _data = _mintReservesForTiersData[_i];

      // Mint for the tier.
      mintReservesFor(_data.tierId, _data.count);

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Mint tokens within the tier for the provided beneficiaries.

    @param _mintForTiersData Contains information about how who to mint tokens for from each tier.
  */
  function mintFor(JBTiered721MintForTiersData[] calldata _mintForTiersData)
    external
    override
    onlyOwner
  {
    // Keep a reference to the number of beneficiaries there are to mint for.
    uint256 _numberOfBeneficiaries = _mintForTiersData.length;

    for (uint256 _i; _i < _numberOfBeneficiaries; ) {
      // Get a reference to the data being iterated on.
      JBTiered721MintForTiersData calldata _data = _mintForTiersData[_i];

      // Mint for the tier.
      mintFor(_data.tierIds, _data.beneficiary);

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Adjust the tiers mintable through this contract, adhering to any locked tier constraints. 

    @dev
    Only the contract's owner can adjust the tiers.

    @param _tiersToAdd An array of tier data to add.
    @param _tierIdsToRemove An array of tier IDs to remove.
  */
  function adjustTiers(JB721TierParams[] calldata _tiersToAdd, uint256[] calldata _tierIdsToRemove)
    external
    override
    onlyOwner
  {
    // Get a reference to the number of tiers being added.
    uint256 _numberOfTiersToAdd = _tiersToAdd.length;

    // Get a reference to the number of tiers being removed.
    uint256 _numberOfTiersToRemove = _tierIdsToRemove.length;

    // Remove the tiers.
    if (_numberOfTiersToRemove != 0) {
      // Record the removed tiers.
      store.recordRemoveTierIds(_tierIdsToRemove);

      // Emit events for each removed tier.
      for (uint256 _i; _i < _numberOfTiersToRemove; ) {
        emit RemoveTier(_tierIdsToRemove[_i], msg.sender);
        unchecked {
          ++_i;
        }
      }
    }

    // Add the tiers.
    if (_numberOfTiersToAdd != 0) {
      // Record the added tiers in the store.
      uint256[] memory _tierIdsAdded = store.recordAddTiers(_tiersToAdd);

      // Emit events for each added tier.
      for (uint256 _i; _i < _numberOfTiersToAdd; ) {
        emit AddTier(_tierIdsAdded[_i], _tiersToAdd[_i], msg.sender);
        unchecked {
          ++_i;
        }
      }
    }
  }

  /** 
    @notice
    Sets the beneficiary of the reserved tokens for tiers where a specific beneficiary isn't set. 

    @dev
    Only the contract's owner can set the default reserved token beneficiary.

    @param _beneficiary The default beneficiary of the reserved tokens.
  */
  function setDefaultReservedTokenBeneficiary(address _beneficiary) external override onlyOwner {
    // Set the beneficiary.
    store.recordSetDefaultReservedTokenBeneficiary(_beneficiary);

    emit SetDefaultReservedTokenBeneficiary(_beneficiary, msg.sender);
  }

  /**
    @notice
    Set a base token URI.

    @dev
    Only the contract's owner can set the base URI.

    @param _baseUri The new base URI.
  */
  function setBaseUri(string calldata _baseUri) external override onlyOwner {
    // Store the new value.
    store.recordSetBaseUri(_baseUri);

    emit SetBaseUri(_baseUri, msg.sender);
  }

  /**
    @notice
    Set a contract metadata URI to contain opensea-style metadata.

    @dev
    Only the contract's owner can set the contract URI.

    @param _contractUri The new contract URI.
  */
  function setContractUri(string calldata _contractUri) external override onlyOwner {
    // Store the new value.
    store.recordSetContractUri(_contractUri);

    emit SetContractUri(_contractUri, msg.sender);
  }

  /**
    @notice
    Set a token URI resolver.

    @dev
    Only the contract's owner can set the token URI resolver.

    @param _tokenUriResolver The new URI resolver.
  */
  function setTokenUriResolver(IJBTokenUriResolver _tokenUriResolver) external override onlyOwner {
    // Store the new value.
    store.recordSetTokenUriResolver(_tokenUriResolver);

    emit SetTokenUriResolver(_tokenUriResolver, msg.sender);
  }

  /**
    @notice
    Set an encoded IPFS uri of a tier.

    @dev
    Only the contract's owner can set the encoded IPFS uri.

    @param _tierId The ID of the tier to set the encoded IPFS uri of.
    @param _encodedIPFSUri The encoded IPFS uri to set.
  */
  function setEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri)
    external
    override
    onlyOwner
  {
    // Store the new value.
    store.recordSetEncodedIPFSUriOf(_tierId, _encodedIPFSUri);

    emit SetEncodedIPFSUri(_tierId, _encodedIPFSUri, msg.sender);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /** 
    @notice
    Mint reserved tokens within the tier for the provided value.

    @param _tierId The ID of the tier to mint within.
    @param _count The number of reserved tokens to mint. 
  */
  function mintReservesFor(uint256 _tierId, uint256 _count) public override {
    // Get a reference to the project's current funding cycle.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(projectId);

    // Minting reserves must not be paused.
    if (
      JBTiered721FundingCycleMetadataResolver.mintingReservesPaused(
        (JBFundingCycleMetadataResolver.metadata(_fundingCycle))
      )
    ) revert RESERVED_TOKEN_MINTING_PAUSED();

    // Record the minted reserves for the tier.
    uint256[] memory _tokenIds = store.recordMintReservesFor(_tierId, _count);

    // Keep a reference to the reserved token beneficiary.
    address _reservedTokenBeneficiary = store.reservedTokenBeneficiaryOf(address(this), _tierId);

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    for (uint256 _i; _i < _count; ) {
      // Set the token ID.
      _tokenId = _tokenIds[_i];

      // Mint the token.
      _mint(_reservedTokenBeneficiary, _tokenId);

      emit MintReservedToken(_tokenId, _tierId, _reservedTokenBeneficiary, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice
    Manually mint NFTs from tiers.

    @param _tierIds The IDs of the tiers to mint from.
    @param _beneficiary The address to mint to. 

    @return tokenIds The IDs of the newly minted tokens.
  */
  function mintFor(uint16[] calldata _tierIds, address _beneficiary)
    public
    override
    onlyOwner
    returns (uint256[] memory tokenIds)
  {
    // Record the mint. The returned token IDs correspond to the tiers passed in.
    (tokenIds, ) = store.recordMint(
      type(uint256).max, // force the mint.
      _tierIds,
      true // manual mint
    );

    // Keep a reference to the number of tokens being minted.
    uint256 _numberOfTokens = _tierIds.length;

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    for (uint256 _i; _i < _numberOfTokens; ) {
      // Set the token ID.
      _tokenId = tokenIds[_i];

      // Mint the token.
      _mint(_beneficiary, _tokenId);

      emit Mint(_tokenId, _tierIds[_i], _beneficiary, 0, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Mints for a given contribution to the beneficiary.

    @param _data The Juicebox standard project contribution data.
  */
  function _processPayment(JBDidPayData calldata _data) internal override {
    // Normalize the currency.
    uint256 _value;
    if (_data.amount.currency == pricingCurrency) _value = _data.amount.value;
    else if (prices != IJBPrices(address(0)))
      _value = PRBMath.mulDiv(
        _data.amount.value,
        10**pricingDecimals,
        prices.priceFor(_data.amount.currency, pricingCurrency, _data.amount.decimals)
      );
    else return;

    // Keep a reference to the amount of credits the beneficiary already has.
    uint256 _credits = creditsOf[_data.beneficiary];

    // Set the leftover amount as the initial value, including any credits the beneficiary might already have.
    uint256 _leftoverAmount = _value;

    // If the payer is the beneficiary, combine the credits with the paid amount
    // if not, then we keep track of the credits that were unused
    uint256 _stashedCredits;
    if (_data.payer == _data.beneficiary) {
      unchecked {
        _leftoverAmount += _credits;
      }
    } else _stashedCredits = _credits;

    // Keep a reference to the flag indicating if the transaction should not revert if all provided funds aren't spent. Defaults to false, meaning only a minimum payment is enforced.
    bool _allowOverspending;

    // Skip the first 32 bytes which are used by the JB protocol to pass the paying project's ID when paying from a JBSplit.
    // Skip another 32 bytes reserved for generic extension parameters.
    // Check the 4 bytes interfaceId to verify the metadata is intended for this contract.
    if (
      _data.metadata.length > 68 &&
      bytes4(_data.metadata[64:68]) == type(IJB721Delegate).interfaceId
    ) {
      // Keep a reference to the the specific tier IDs to mint.
      uint16[] memory _tierIdsToMint;

      // Decode the metadata.
      (, , , _allowOverspending, _tierIdsToMint) = abi.decode(
        _data.metadata,
        (bytes32, bytes32, bytes4, bool, uint16[])
      );

      // Make sure overspending is allowed if requested.
      if (_allowOverspending && store.flagsOf(address(this)).preventOverspending)
        _allowOverspending = false;

      // Mint tiers if they were specified.
      if (_tierIdsToMint.length != 0)
        _leftoverAmount = _mintAll(_leftoverAmount, _tierIdsToMint, _data.beneficiary);
    }

    // If there are allowed funds leftover, add to credits.
    if (_leftoverAmount != 0) {
      // Make sure there are no leftover funds after minting if not expected.
      if (!_allowOverspending) revert OVERSPENDING();

      // Increment the leftover amount.
      unchecked {
        // Keep a reference to the amount of new credits.
        uint256 _newCredits = _leftoverAmount + _stashedCredits;

        // Emit the change in credits.
        if (_newCredits > _credits)
          emit AddCredits(_newCredits - _credits, _newCredits, _data.beneficiary, msg.sender);
        else if (_credits > _newCredits)
          emit UseCredits(_credits - _newCredits, _newCredits, _data.beneficiary, msg.sender);

        // Store the new credits.
        creditsOf[_data.beneficiary] = _newCredits;
      }
      // Else reset the credits.
    } else if (_credits != _stashedCredits) {
      // Emit the change in credits.
      emit UseCredits(_credits - _stashedCredits, _stashedCredits, _data.beneficiary, msg.sender);

      // Store the new credits.
      creditsOf[_data.beneficiary] = _stashedCredits;
    }
  }

  /** 
    @notice
    A function that will run when tokens are burned via redemption.

    @param _tokenIds The IDs of the tokens that were burned.
  */
  function _didBurn(uint256[] memory _tokenIds) internal virtual override {
    // Add to burned counter.
    store.recordBurn(_tokenIds);
  }

  /** 
    @notice
    Mints a token in all provided tiers.

    @param _amount The amount to base the mints on. All mints' price floors must fit in this amount.
    @param _mintTierIds An array of tier IDs that are intended to be minted.
    @param _beneficiary The address to mint for.

    @return leftoverAmount The amount leftover after the mint.
  */
  function _mintAll(
    uint256 _amount,
    uint16[] memory _mintTierIds,
    address _beneficiary
  ) internal returns (uint256 leftoverAmount) {
    // Keep a reference to the token ID.
    uint256[] memory _tokenIds;

    // Record the mint. The returned token IDs correspond to the tiers passed in.
    (_tokenIds, leftoverAmount) = store.recordMint(
      _amount,
      _mintTierIds,
      false // Not a manual mint
    );

    // Get a reference to the number of mints.
    uint256 _mintsLength = _tokenIds.length;

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    // Loop through each token ID and mint.
    for (uint256 _i; _i < _mintsLength; ) {
      // Get a reference to the tier being iterated on.
      _tokenId = _tokenIds[_i];

      // Mint the tokens.
      _mint(_beneficiary, _tokenId);

      emit Mint(_tokenId, _mintTierIds[_i], _beneficiary, _amount, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    User the hook to register the first owner if it's not yet registered.

    @param _from The address where the transfer is originating.
    @param _to The address to which the transfer is being made.
    @param _tokenId The ID of the token being transferred.
  */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    // Transferred must not be paused when not minting or burning.
    if (_from != address(0)) {
      // Get a reference to the tier.
      JB721Tier memory _tier = store.tierOfTokenId(address(this), _tokenId);

      // Transfers from the tier must be pausable.
      if (_tier.transfersPausable) {
        // Get a reference to the project's current funding cycle.
        JBFundingCycle memory _fundingCycle = fundingCycleStore.currentOf(projectId);

        if (
          _to != address(0) &&
          JBTiered721FundingCycleMetadataResolver.transfersPaused(
            (JBFundingCycleMetadataResolver.metadata(_fundingCycle))
          )
        ) revert TRANSFERS_PAUSED();
      }

      // If there's no stored first owner, and the transfer isn't originating from the zero address as expected for mints, store the first owner.
      if (store.firstOwnerOf(address(this), _tokenId) == address(0))
        store.recordSetFirstOwnerOf(_tokenId, _from);
    }

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  /**
    @notice
    Transfer voting units after the transfer of a token.

    @param _from The address where the transfer is originating.
    @param _to The address to which the transfer is being made.
    @param _tokenId The ID of the token being transferred.
   */
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    // Get a reference to the tier.
    JB721Tier memory _tier = store.tierOfTokenId(address(this), _tokenId);

    // Record the transfer.
    store.recordTransferForTier(_tier.id, _from, _to);

    // Handle any other accounting (ex. account for governance voting units)
    _afterTokenTransferAccounting(_from, _to, _tokenId, _tier);

    super._afterTokenTransfer(_from, _to, _tokenId);
  }

  /**
    @notice 
    Custom hook to handle token/tier accounting, this way we can reuse the '_tier' instead of fetching it again.

    @param _from The account to transfer voting units from.
    @param _to The account to transfer voting units to.
    @param _tokenId The ID of the token for which voting units are being transferred.
    @param _tier The tier the token ID is part of.
  */
  function _afterTokenTransferAccounting(
    address _from,
    address _to,
    uint256 _tokenId,
    JB721Tier memory _tier
  ) internal virtual {
    _from; // Prevents unused var compiler and natspec complaints.
    _to;
    _tokenId;
    _tier;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Doesn't track balances.
 *
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  error ALEADY_MINTED();
  error APPROVE_TO_CALLER();
  error APPROVAL_TO_CURRENT_OWNER();
  error CALLER_NOT_OWNER_OR_APPROVED();
  error INVALID_TOKEN_ID();
  error INCORRECT_OWNER();
  error MINT_TO_ZERO();
  error TRANSFER_TO_NON_IMPLEMENTER();
  error TRANSFER_TO_ZERO_ADDRESS();

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function _initialize(string memory name_, string memory symbol_) internal {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
    @dev Balance tracking to be overriden by childs
  */
  function balanceOf(address owner) external view virtual override returns (uint256 balance) {
    owner;
    return 0;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    if (owner == address(0)) revert INVALID_TOKEN_ID();
    return owner;
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
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);

    if (to == owner) revert APPROVAL_TO_CURRENT_OWNER();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
      revert CALLER_NOT_OWNER_OR_APPROVED();

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
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
    //solhint-disable-next-line max-line-length
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert CALLER_NOT_OWNER_OR_APPROVED();

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
    bytes memory data
  ) public virtual override {
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert CALLER_NOT_OWNER_OR_APPROVED();
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    if (!_checkOnERC721Received(from, to, tokenId, data)) revert TRANSFER_TO_NON_IMPLEMENTER();
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    if (to == address(0)) revert MINT_TO_ZERO();
    if (_exists(tokenId)) revert ALEADY_MINTED();

    _beforeTokenTransfer(address(0), to, tokenId);

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
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
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
  ) internal virtual {
    if (ERC721.ownerOf(tokenId) != from) revert INCORRECT_OWNER();
    if (to == address(0)) revert TRANSFER_TO_ZERO_ADDRESS();

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) revert APPROVE_TO_CALLER();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    if (!_exists(tokenId)) revert INVALID_TOKEN_ID();
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (
        bytes4 retval
      ) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert TRANSFER_TO_NON_IMPLEMENTER();
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBConstants.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayParamsData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayDelegateAllocation.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import '../interfaces/IJB721Delegate.sol';
import './ERC721.sol';

/**
  @title 
  JB721Delegate

  @notice 
  Delegate that offers project contributors NFTs upon payment and the ability to redeem NFTs for treasury assets.

  @dev
  Adheres to -
  IJB721Delegate: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
  IJBFundingCycleDataSource: Allows this contract to be attached to a funding cycle to have its methods called during regular protocol operations.
  IJBPayDelegate: Allows this contract to receive callbacks when a project receives a payment.
  IJBRedemptionDelegate: Allows this contract to receive callbacks when a token holder redeems.

  @dev
  Inherits from -
  ERC721: A standard definition for non-fungible tokens (NFTs).
*/
abstract contract JB721Delegate is
  IJB721Delegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate,
  ERC721
{
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_PAYMENT_EVENT();
  error INVALID_REDEMPTION_EVENT();
  error UNAUTHORIZED();
  error UNEXPECTED_TOKEN_REDEEMED();
  error INVALID_REDEMPTION_METADATA();

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
    @notice
    The ID of the project this contract's functionality applies to.
  */
  uint256 public override projectId;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public override directory;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when the project receives a payment. It will set itself as the delegate to get a callback from the terminal.

    @param _data The Juicebox standard project payment data.

    @return weight The weight that tokens should get minted in accordance with.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(JBPayParamsData calldata _data)
    public
    view
    virtual
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    // Forward the received weight and memo, and use this contract as a pay delegate.
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation(this, 0);
  }

  /**
    @notice 
    Part of IJBFundingCycleDataSource, this function gets called when a project's token holders redeem.

    @param _data The Juicebox standard project redemption data.

    @return reclaimAmount The amount that should be reclaimed from the treasury.
    @return memo The memo that should be forwarded to the event.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    public
    view
    virtual
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    // Make sure fungible project tokens aren't being redeemed too.
    if (_data.tokenCount > 0) revert UNEXPECTED_TOKEN_REDEEMED();

    // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract
    // Skip 32 bytes reserved for generic extension parameters.
    if (
      _data.metadata.length < 36 ||
      bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId
    ) {
      revert INVALID_REDEMPTION_METADATA();
    }

    // Set the only delegate allocation to be a callback to this contract.
    delegateAllocations = new JBRedemptionDelegateAllocation[](1);
    delegateAllocations[0] = JBRedemptionDelegateAllocation(this, 0);

    // Decode the metadata
    (, , uint256[] memory _decodedTokenIds) = abi.decode(
      _data.metadata,
      (bytes32, bytes4, uint256[])
    );

    // Get a reference to the redemption rate of the provided tokens.
    uint256 _redemptionWeight = redemptionWeightOf(_decodedTokenIds, _data);

    // Get a reference to the total redemption weight.
    uint256 _total = totalRedemptionWeight(_data);

    // Get a reference to the linear proportion.
    uint256 _base = PRBMath.mulDiv(_data.overflow, _redemptionWeight, _total);

    // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
    if (_data.redemptionRate == JBConstants.MAX_REDEMPTION_RATE)
      return (_base, _data.memo, delegateAllocations);

    // Return the weighted overflow, and this contract as the delegate so that tokens can be deleted.
    return (
      PRBMath.mulDiv(
        _base,
        _data.redemptionRate +
          PRBMath.mulDiv(
            _redemptionWeight,
            JBConstants.MAX_REDEMPTION_RATE - _data.redemptionRate,
            _total
          ),
        JBConstants.MAX_REDEMPTION_RATE
      ),
      _data.memo,
      delegateAllocations
    );
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The cumulative weight the given token IDs have in redemptions compared to the `totalRedemptionWeight`. 

    @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.
    @param _data The Juicebox standard project redemption data.

    @return The weight.
  */
  function redemptionWeightOf(uint256[] memory _tokenIds, JBRedeemParamsData calldata _data)
    public
    view
    virtual
    returns (uint256)
  {
    _tokenIds; // Prevents unused var compiler and natspec complaints.
    _data; // Prevents unused var compiler and natspec complaints.
    return 0;
  }

  /** 
    @notice
    The cumulative weight that all token IDs have in redemptions. 

    @param _data The Juicebox standard project redemption data.

    @return The total weight.
  */
  function totalRedemptionWeight(JBRedeemParamsData calldata _data)
    public
    view
    virtual
    returns (uint256)
  {
    _data; // Prevents unused var compiler and natspec complaints.
    return 0;
  }

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherence to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJB721Delegate).interfaceId ||
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project this contract's functionality applies to.
    @param _directory The directory of terminals and controllers for projects.
    @param _name The name of the token.
    @param _symbol The symbol that the token should be represented by.
  */
  function _initialize(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol
  ) internal {
    ERC721._initialize(_name, _symbol);

    projectId = _projectId;
    directory = _directory;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Part of IJBPayDelegate, this function gets called when the project receives a payment. It will mint an NFT to the contributor (_data.beneficiary) if conditions are met.

    @dev 
    This function will revert if the contract calling is not one of the project's terminals. 

    @param _data The Juicebox standard project payment data.
  */
  function didPay(JBDidPayData calldata _data) external payable virtual override {
    uint256 _projectId = projectId;

    // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
    if (
      msg.value != 0 ||
      !directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != _projectId
    ) revert INVALID_PAYMENT_EVENT();

    // Process the payment.
    _processPayment(_data);
  }

  /**
    @notice
    Part of IJBRedeemDelegate, this function gets called when the token holder redeems. It will burn the specified NFTs to reclaim from the treasury to the _data.beneficiary.

    @dev
    This function will revert if the contract calling is not one of the project's terminals.

    @param _data The Juicebox standard project redemption data.
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable virtual override {
    // Make sure the caller is a terminal of the project, and the call is being made on behalf of an interaction with the correct project.
    if (
      msg.value != 0 ||
      !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != projectId
    ) revert INVALID_REDEMPTION_EVENT();

    // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract
    // Skip 32 bytes reserved for generic extension parameters.
    if (
      _data.metadata.length < 36 ||
      bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId
    ) revert INVALID_REDEMPTION_METADATA();

    // Decode the metadata.
    (, , uint256[] memory _decodedTokenIds) = abi.decode(
      _data.metadata,
      (bytes32, bytes4, uint256[])
    );

    // Get a reference to the number of token IDs being checked.
    uint256 _numberOfTokenIds = _decodedTokenIds.length;

    // Keep a reference to the token ID being iterated on.
    uint256 _tokenId;

    // Iterate through all tokens, burning them if the owner is correct.
    for (uint256 _i; _i < _numberOfTokenIds; ) {
      // Set the token's ID.
      _tokenId = _decodedTokenIds[_i];

      // Make sure the token's owner is correct.
      if (_owners[_tokenId] != _data.holder) revert UNAUTHORIZED();

      // Burn the token.
      _burn(_tokenId);

      unchecked {
        ++_i;
      }
    }

    // Call the hook.
    _didBurn(_decodedTokenIds);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Process a received payment.

    @param _data The Juicebox standard project payment data.
  */
  function _processPayment(JBDidPayData calldata _data) internal virtual {
    _data; // Prevents unused var compiler and natspec complaints.
  }

  /** 
    @notice
    A function that will run when tokens are burned via redemption.

    @param _tokenIds The IDs of the tokens that were burned.
  */
  function _didBurn(uint256[] memory _tokenIds) internal virtual {
    _tokenIds;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';

interface IJB721Delegate {
  event SetBaseUri(string indexed baseUri, address caller);

  event SetContractUri(string indexed contractUri, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed newResolver, address caller);

  function projectId() external view returns (uint256);

  function directory() external view returns (IJBDirectory);

  function setBaseUri(string memory _baseUri) external;

  function setContractUri(string calldata _contractMetadataUri) external;

  function setTokenUriResolver(IJBTokenUriResolver _tokenUriResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBTiered721SetTierDelegatesData.sol';
import './IJBTiered721Delegate.sol';

interface IJB721TieredGovernance is IJBTiered721Delegate {
  event TierDelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate,
    uint256 tierId,
    address caller
  );

  event TierDelegateVotesChanged(
    address indexed delegate,
    uint256 indexed tierId,
    uint256 previousBalance,
    uint256 newBalance,
    address caller
  );

  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  function getTierDelegate(address _account, uint256 _tier) external view returns (address);

  function getTierVotes(address _account, uint256 _tier) external view returns (uint256);

  function getPastTierVotes(
    address _account,
    uint256 _tier,
    uint256 _blockNumber
  ) external view returns (uint256);

  function getTierTotalVotes(uint256 _tier) external view returns (uint256);

  function getPastTierTotalVotes(uint256 _tier, uint256 _blockNumber)
    external
    view
    returns (uint256);

  function setTierDelegate(address _delegatee, uint256 _tierId) external;

  function setTierDelegates(JBTiered721SetTierDelegatesData[] memory _setTierDelegatesData)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol';
import './../structs/JB721PricingParams.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JBTiered721MintReservesForTiersData.sol';
import './../structs/JBTiered721MintForTiersData.sol';
import './IJB721Delegate.sol';
import './IJBTiered721DelegateStore.sol';

interface IJBTiered721Delegate is IJB721Delegate {
  event Mint(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    uint256 totalAmountContributed,
    address caller
  );

  event MintReservedToken(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    address caller
  );

  event AddTier(uint256 indexed tierId, JB721TierParams data, address caller);

  event RemoveTier(uint256 indexed tierId, address caller);

  event SetDefaultReservedTokenBeneficiary(address indexed beneficiary, address caller);

  event SetEncodedIPFSUri(uint256 indexed tierId, bytes32 encodedIPFSUri, address caller);

  event AddCredits(
    uint256 indexed changeAmount,
    uint256 indexed newTotalCredits,
    address indexed account,
    address caller
  );

  event UseCredits(
    uint256 indexed changeAmount,
    uint256 indexed newTotalCredits,
    address indexed account,
    address caller
  );

  function codeOrigin() external view returns (address);

  function store() external view returns (IJBTiered721DelegateStore);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function prices() external view returns (IJBPrices);

  function pricingCurrency() external view returns (uint256);

  function pricingDecimals() external view returns (uint256);

  function contractURI() external view returns (string memory);

  function creditsOf(address _address) external view returns (uint256);

  function firstOwnerOf(uint256 _tokenId) external view returns (address);

  function adjustTiers(JB721TierParams[] memory _tierDataToAdd, uint256[] memory _tierIdsToRemove)
    external;

  function mintReservesFor(JBTiered721MintReservesForTiersData[] memory _mintReservesForTiersData)
    external;

  function mintReservesFor(uint256 _tierId, uint256 _count) external;

  function mintFor(JBTiered721MintForTiersData[] memory _mintForTiersData) external;

  function mintFor(uint16[] calldata _tierIds, address _beneficiary)
    external
    returns (uint256[] memory tokenIds);

  function setDefaultReservedTokenBeneficiary(address _beneficiary) external;

  function setEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external;

  function initialize(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol,
    IJBFundingCycleStore _fundingCycleStore,
    string memory _baseUri,
    IJBTokenUriResolver _tokenUriResolver,
    string memory _contractUri,
    JB721PricingParams memory _pricing,
    IJBTiered721DelegateStore _store,
    JBTiered721Flags memory _flags
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JB721Tier.sol';
import './../structs/JBTiered721Flags.sol';

interface IJBTiered721DelegateStore {
  event CleanTiers(address indexed nft, address caller);

  function MAX_ROYALTY_RATE() external view returns (uint256);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function maxTierIdOf(address _nft) external view returns (uint256);

  function tiers(
    address _nft,
    uint256 _category,
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

  function defaultRoyaltyBeneficiaryOf(address _nft) external view returns (address);

  function reservedTokenBeneficiaryOf(address _nft, uint256 _tierId)
    external
    view
    returns (address);

  function baseUriOf(address _nft) external view returns (string memory);

  function contractUriOf(address _nft) external view returns (string memory);

  function tokenUriResolverOf(address _nft) external view returns (IJBTokenUriResolver);

  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view returns (bytes32);

  function royaltyInfo(
    address _nft,
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);

  function recordAddTiers(JB721TierParams[] memory _tierData)
    external
    returns (uint256[] memory tierIds);

  function recordMintReservesFor(uint256 _tierId, uint256 _count)
    external
    returns (uint256[] memory tokenIds);

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

  function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external;

  function recordFlags(JBTiered721Flags calldata _flag) external;

  function cleanTiers(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  
  @notice
  Utilities to decode an IPFS hash.

  @dev
  This is fairly gas intensive, due to multiple nested loops, onchain 
  IPFS hash decoding is therefore not advised (storing them as a string,
  in that use-case, *might* be more efficient).

*/
library JBIpfsDecoder {
  //*********************************************************************//
  // ------------------- internal constant properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Just a kind reminder to our readers

    @dev
    Used in base58ToString
  */
  bytes internal constant _ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  function decode(string memory _baseUri, bytes32 _hexString)
    internal
    pure
    returns (string memory)
  {
    // Concatenate the hex string with the fixed IPFS hash part (0x12 and 0x20)
    bytes memory completeHexString = abi.encodePacked(bytes2(0x1220), _hexString);

    // Convert the hex string to a hash
    string memory ipfsHash = _toBase58(completeHexString);

    // Concatenate with the base URI
    return string(abi.encodePacked(_baseUri, ipfsHash));
  }

  /**
    @notice
    Convert a hex string to base58

    @notice 
    Written by Martin Ludfall - Licence: MIT
  */
  function _toBase58(bytes memory _source) private pure returns (string memory) {
    if (_source.length == 0) return new string(0);

    uint8[] memory digits = new uint8[](46); // hash size with the prefix

    digits[0] = 0;

    uint8 digitlength = 1;
    uint256 _sourceLength = _source.length;

    for (uint256 i; i < _sourceLength; ) {
      uint256 carry = uint8(_source[i]);

      for (uint256 j; j < digitlength; ) {
        carry += uint256(digits[j]) << 8; // mul 256
        digits[j] = uint8(carry % 58);
        carry = carry / 58;

        unchecked {
          ++j;
        }
      }

      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        unchecked {
          ++digitlength;
        }
        carry = carry / 58;
      }

      unchecked {
        ++i;
      }
    }
    return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
  }

  function _truncate(uint8[] memory _array, uint8 _length) private pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](_length);
    for (uint256 i; i < _length; ) {
      output[i] = _array[i];

      unchecked {
        ++i;
      }
    }
    return output;
  }

  function _reverse(uint8[] memory _input) private pure returns (uint8[] memory) {
    uint256 _inputLength = _input.length;
    uint8[] memory output = new uint8[](_inputLength);
    for (uint256 i; i < _inputLength; ) {
      unchecked {
        output[i] = _input[_input.length - 1 - i];
        ++i;
      }
    }
    return output;
  }

  function _toAlphabet(uint8[] memory _indices) private pure returns (bytes memory) {
    uint256 _indicesLength = _indices.length;
    bytes memory output = new bytes(_indicesLength);
    for (uint256 i; i < _indicesLength; ) {
      output[i] = _ALPHABET[_indices[i]];

      unchecked {
        ++i;
      }
    }
    return output;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBTiered721FundingCycleMetadata.sol';

library JBTiered721FundingCycleMetadataResolver {
  function transfersPaused(uint256 _data) internal pure returns (bool) {
    return (_data & 1) == 1;
  }

  function mintingReservesPaused(uint256 _data) internal pure returns (bool) {
    return ((_data >> 1) & 1) == 1;
  }

  /**
    @notice
    Pack the tiered 721 funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all tiered 721 metadata params.
  */
  function packFundingCycleGlobalMetadata(JBTiered721FundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // pause transfers in bit 0.
    if (_metadata.pauseTransfers) packed |= 1;
    // pause mint reserves in bit 2.
    if (_metadata.pauseMintingReserves) packed |= 1 << 1;
  }

  /**
    @notice
    Expand the tiered 721 funding cycle metadata.

    @param _packedMetadata The packed metadata to expand.

    @return metadata The tiered 721 metadata object.
  */
  function expandMetadata(uint8 _packedMetadata)
    internal
    pure
    returns (JBTiered721FundingCycleMetadata memory metadata)
  {
    return
      JBTiered721FundingCycleMetadata(
        transfersPaused(_packedMetadata),
        mintingReservesPaused(_packedMetadata)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol';
import './JB721TierParams.sol';

/**
  @member tiers The tiers to set.
  @member currency The currency that the tier contribution floors are denoted in.
  @member decimals The number of decimals included in the tier contribution floor fixed point numbers.
  @member prices A contract that exposes price feeds that can be used to resolved the value of a contributions that are sent in different currencies. Set to the zero address if payments must be made in `currency`.
*/
struct JB721PricingParams {
  JB721TierParams[] tiers;
  uint256 currency;
  uint256 decimals;
  IJBPrices prices;
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
  @member royaltyRate The percentage of each of the NFT sales that should be routed to the royalty beneficiary. Out of MAX_ROYALTY_RATE.
  @member royaltyBeneficiary The beneificary of the royalty.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
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
  uint256 royaltyRate;
  address royaltyBeneficiary;
  bytes32 encodedIPFSUri;
  uint256 category;
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
  @member royaltyRate The percentage of each of the NFT sales that should be routed to the royalty beneficiary. Out of MAX_ROYALTY_RATE.
  @member royaltyBeneficiary The beneificary of the royalty.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
  @member shouldUseRoyaltyBeneficiaryAsDefault A flag indicating if the `royaltyBeneficiary` should be stored as the default beneficiary for all tiers.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
*/
struct JB721TierParams {
  uint80 contributionFloor;
  uint48 lockedUntil;
  uint40 initialQuantity;
  uint16 votingUnits;
  uint16 reservedRate;
  address reservedTokenBeneficiary;
  uint8 royaltyRate;
  address royaltyBeneficiary;
  bytes32 encodedIPFSUri;
  uint8 category;
  bool allowManualMint;
  bool shouldUseReservedTokenBeneficiaryAsDefault;
  bool shouldUseRoyaltyBeneficiaryAsDefault;
  bool transfersPausable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
  @member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
  @member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
  @member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted. 
*/
struct JBTiered721Flags {
  bool lockReservedTokenChanges;
  bool lockVotingUnitChanges;
  bool lockManualMintingChanges;
  bool preventOverspending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member pauseTransfers A flag indicating if the token transfer functionality should be paused during the funding cycle.
  @member pauseMintingReserves A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
*/
struct JBTiered721FundingCycleMetadata {
  bool pauseTransfers;
  bool pauseMintingReserves;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierIds The IDs of the tier to mint within.
  @member beneficiary The beneficiary to mint for. 
*/
struct JBTiered721MintForTiersData {
  uint16[] tierIds;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierId The ID of the tier to mint within.
  @member count The number of reserved tokens to mint. 
*/
struct JBTiered721MintReservesForTiersData {
  uint256 tierId;
  uint256 count;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member delegatee The account to delegate tier voting units to.
  @member tierId The ID of the tier to delegate voting units for.
*/
struct JBTiered721SetTierDelegatesData {
  address delegatee;
  uint256 tierId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';
import './../structs/JBRedemptionDelegateAllocation.sol';

/**
  @title
  Datasource

  @notice
  The datasource is called by JBPaymentTerminal on pay and redemption, and provide an extra layer of logic to use 
  a custom weight, a custom memo and/or a pay/redeem delegate

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBFundingCycleDataSource is IERC165 {
  /**
    @notice
    The datasource implementation for JBPaymentTerminal.pay(..)

    @param _data the data passed to the data source in terminal.pay(..), as a JBPayParamsData struct:
                  IJBPaymentTerminal terminal;
                  address payer;
                  JBTokenAmount amount;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  address beneficiary;
                  uint256 weight;
                  uint256 reservedRate;
                  string memo;
                  bytes metadata;

    @return weight the weight to use to override the funding cycle weight
    @return memo the memo to override the pay(..) memo
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(JBPayParamsData calldata _data)
    external
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    );

  /**
    @notice
    The datasource implementation for JBPaymentTerminal.redeemTokensOf(..)

    @param _data the data passed to the data source in terminal.redeemTokensOf(..), as a JBRedeemParamsData struct:
                    IJBPaymentTerminal terminal;
                    address holder;
                    uint256 projectId;
                    uint256 currentFundingCycleConfiguration;
                    uint256 tokenCount;
                    uint256 totalSupply;
                    uint256 overflow;
                    JBTokenAmount reclaimAmount;
                    bool useTotalOverflow;
                    uint256 redemptionRate;
                    uint256 ballotRedemptionRate;
                    string memo;
                    bytes metadata;

    @return reclaimAmount The amount to claim, overriding the terminal logic.
    @return memo The memo to override the redeemTokensOf(..) memo.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

/**
  @title
  Pay delegate

  @notice
  Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBPayDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.pay(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidPayData struct:
                  address payer;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  JBTokenAmount amount;
                  JBTokenAmount forwardedAmount;
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

/**
  @title
  Redemption delegate

  @notice
  Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBRedemptionDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidRedeemData struct:
                address holder;
                uint256 projectId;
                uint256 currentFundingCycleConfiguration;
                uint256 projectTokenCount;
                JBTokenAmount reclaimedAmount;
                JBTokenAmount forwardedAmount;
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10_000;
  uint256 public constant MAX_REDEMPTION_RATE = 10_000;
  uint256 public constant MAX_DISCOUNT_RATE = 1_000_000_000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1_000_000_000;
  uint256 public constant MAX_FEE = 1_000_000_000;
  uint256 public constant MAX_FEE_DISCOUNT = 1_000_000_000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGlobalFundingCycleMetadata.sol';
import './JBConstants.sol';
import './JBGlobalFundingCycleMetadataResolver.sol';

library JBFundingCycleMetadataResolver {
  function global(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory)
  {
    return JBGlobalFundingCycleMetadataResolver.expandMetadata(uint8(_fundingCycle.metadata >> 8));
  }

  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 40));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 56));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 72) & 1) == 1;
  }

  function distributionsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 73) & 1) == 1;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 74) & 1) == 1;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 75) & 1) == 1;
  }

  function mintingAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 76) & 1) == 1;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 77) & 1) == 1;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 78) & 1) == 1;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 79) & 1) == 1;
  }

  function preferClaimedTokenOverride(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 80) & 1) == 1;
  }

  function useTotalOverflowForRedemptions(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 81) & 1) == 1;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 82) & 1 == 1;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 83) & 1 == 1;
  }

  function dataSource(JBFundingCycle memory _fundingCycle) internal pure returns (address) {
    return address(uint160(_fundingCycle.metadata >> 84));
  }

  function metadata(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint8(_fundingCycle.metadata >> 244));
  }

  /**
    @notice
    Pack the funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleMetadata(JBFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // version 1 in the bits 0-7 (8 bits).
    packed = 1;
    // global metadta in bits 8-23 (16 bits).
    packed |=
      JBGlobalFundingCycleMetadataResolver.packFundingCycleGlobalMetadata(_metadata.global) <<
      8;
    // reserved rate in bits 24-39 (16 bits).
    packed |= _metadata.reservedRate << 24;
    // redemption rate in bits 40-55 (16 bits).
    // redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.redemptionRate) << 40;
    // ballot redemption rate rate in bits 56-71 (16 bits).
    // ballot redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.ballotRedemptionRate) << 56;
    // pause pay in bit 72.
    if (_metadata.pausePay) packed |= 1 << 72;
    // pause tap in bit 73.
    if (_metadata.pauseDistributions) packed |= 1 << 73;
    // pause redeem in bit 74.
    if (_metadata.pauseRedeem) packed |= 1 << 74;
    // pause burn in bit 75.
    if (_metadata.pauseBurn) packed |= 1 << 75;
    // allow minting in bit 76.
    if (_metadata.allowMinting) packed |= 1 << 76;
    // allow terminal migration in bit 77.
    if (_metadata.allowTerminalMigration) packed |= 1 << 77;
    // allow controller migration in bit 78.
    if (_metadata.allowControllerMigration) packed |= 1 << 78;
    // hold fees in bit 79.
    if (_metadata.holdFees) packed |= 1 << 79;
    // prefer claimed token override in bit 80.
    if (_metadata.preferClaimedTokenOverride) packed |= 1 << 80;
    // useTotalOverflowForRedemptions in bit 81.
    if (_metadata.useTotalOverflowForRedemptions) packed |= 1 << 81;
    // use pay data source in bit 82.
    if (_metadata.useDataSourceForPay) packed |= 1 << 82;
    // use redeem data source in bit 83.
    if (_metadata.useDataSourceForRedeem) packed |= 1 << 83;
    // data source address in bits 84-243.
    packed |= uint256(uint160(address(_metadata.dataSource))) << 84;
    // metadata in bits 244-252 (8 bits).
    packed |= _metadata.metadata << 244;
  }

  /**
    @notice
    Expand the funding cycle metadata.

    @param _fundingCycle The funding cycle having its metadata expanded.

    @return metadata The metadata object.
  */
  function expandMetadata(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBFundingCycleMetadata memory)
  {
    return
      JBFundingCycleMetadata(
        global(_fundingCycle),
        reservedRate(_fundingCycle),
        redemptionRate(_fundingCycle),
        ballotRedemptionRate(_fundingCycle),
        payPaused(_fundingCycle),
        distributionsPaused(_fundingCycle),
        redeemPaused(_fundingCycle),
        burnPaused(_fundingCycle),
        mintingAllowed(_fundingCycle),
        terminalMigrationAllowed(_fundingCycle),
        controllerMigrationAllowed(_fundingCycle),
        shouldHoldFees(_fundingCycle),
        preferClaimedTokenOverride(_fundingCycle),
        useTotalOverflowForRedemptions(_fundingCycle),
        useDataSourceForPay(_fundingCycle),
        useDataSourceForRedeem(_fundingCycle),
        dataSource(_fundingCycle),
        metadata(_fundingCycle)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycleMetadata.sol';

library JBGlobalFundingCycleMetadataResolver {
  function setTerminalsAllowed(uint8 _data) internal pure returns (bool) {
    return (_data & 1) == 1;
  }

  function setControllerAllowed(uint8 _data) internal pure returns (bool) {
    return ((_data >> 1) & 1) == 1;
  }

  function transfersPaused(uint8 _data) internal pure returns (bool) {
    return ((_data >> 2) & 1) == 1;
  }

  /**
    @notice
    Pack the global funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all global metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleGlobalMetadata(JBGlobalFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // allow set terminals in bit 0.
    if (_metadata.allowSetTerminals) packed |= 1;
    // allow set controller in bit 1.
    if (_metadata.allowSetController) packed |= 1 << 1;
    // pause transfers in bit 2.
    if (_metadata.pauseTransfers) packed |= 1 << 2;
  }

  /**
    @notice
    Expand the global funding cycle metadata.

    @param _packedMetadata The packed metadata to expand.

    @return metadata The global metadata object.
  */
  function expandMetadata(uint8 _packedMetadata)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory metadata)
  {
    return
      JBGlobalFundingCycleMetadata(
        setTerminalsAllowed(_packedMetadata),
        setControllerAllowed(_packedMetadata),
        transfersPaused(_packedMetadata)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  JBTokenAmount forwardedAmount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  JBTokenAmount forwardedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBPayDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBPayDelegateAllocation {
  IJBPayDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the payment.
  @member payer The address from which the payment originated.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectId The ID of the project being paid.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member beneficiary The specified address that should be the beneficiary of anything that results from the payment.
  @member weight The weight of the funding cycle during which the payment is being made.
  @member reservedRate The reserved rate of the funding cycle during which the payment is being made.
  @member memo The memo that was sent alongside the payment.
  @member metadata Extra data provided by the payer.
*/
struct JBPayParamsData {
  IJBPaymentTerminal terminal;
  address payer;
  JBTokenAmount amount;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  address beneficiary;
  uint256 weight;
  uint256 reservedRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the redemption.
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project whos tokens are being redeemed.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member tokenCount The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  @member totalSupply The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  @member overflow The amount of overflow used in the reclaim amount calculation.
  @member reclaimAmount The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula. Includes the token being reclaimed, the reclaim value, the number of decimals included, and the currency of the reclaim amount.
  @member useTotalOverflow If overflow across all of a project's terminals is being used when making redemptions.
  @member redemptionRate The redemption rate of the funding cycle during which the redemption is being made.
  @member memo The proposed memo that is being emitted alongside the redemption.
  @member metadata Extra data provided by the redeemer.
*/
struct JBRedeemParamsData {
  IJBPaymentTerminal terminal;
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 tokenCount;
  uint256 totalSupply;
  uint256 overflow;
  JBTokenAmount reclaimAmount;
  bool useTotalOverflow;
  uint256 redemptionRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBRedemptionDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBRedemptionDelegateAllocation {
  IJBRedemptionDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
     * block, the requested block number must be in the past, excluding the current block.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._blockNumber <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}