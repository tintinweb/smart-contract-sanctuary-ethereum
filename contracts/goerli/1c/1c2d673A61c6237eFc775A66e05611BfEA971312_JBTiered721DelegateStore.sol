// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { PRBMath } from "@paulrberg/contracts/math/PRBMath.sol";

import { IJBTiered721DelegateStore } from "./interfaces/IJBTiered721DelegateStore.sol";
import { IJB721TokenUriResolver } from "./interfaces/IJB721TokenUriResolver.sol";
import { JBBitmap } from "./libraries/JBBitmap.sol";
import { JBBitmapWord } from "./structs/JBBitmapWord.sol";
import { JB721Tier } from "./structs/JB721Tier.sol";
import { JB721TierParams } from "./structs/JB721TierParams.sol";
import { JBStored721Tier } from "./structs/JBStored721Tier.sol";
import { JBTiered721Flags } from "./structs/JBTiered721Flags.sol";

/// @title JBTiered721DelegateStore
/// @notice This contract stores and manages data for an IJBTiered721Delegate's NFTs.
contract JBTiered721DelegateStore is IJBTiered721DelegateStore {
    using JBBitmap for mapping(uint256 => uint256);
    using JBBitmap for JBBitmapWord;

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error CANT_MINT_MANUALLY();
    error INSUFFICIENT_AMOUNT();
    error INSUFFICIENT_RESERVES();
    error INVALID_CATEGORY_SORT_ORDER();
    error INVALID_QUANTITY();
    error INVALID_TIER();
    error MAX_TIERS_EXCEEDED();
    error NO_QUANTITY();
    error OUT();
    error RESERVED_RATE_NOT_ALLOWED();
    error MANUAL_MINTING_NOT_ALLOWED();
    error TIER_REMOVED();
    error VOTING_UNITS_NOT_ALLOWED();

    //*********************************************************************//
    // -------------------- private constant properties ------------------ //
    //*********************************************************************//

    /// @notice Just a kind reminder to our readers.
    /// @dev Used in token ID generation.
    uint256 private constant _ONE_BILLION = 1_000_000_000;

    //*********************************************************************//
    // --------------------- internal stored properties ------------------ //
    //*********************************************************************//

    /// @notice Returns the tier ID which should come after the provided tier ID when sorting by contribution floor.
    /// @dev If empty, assume the next tier ID should come after.
    /// @custom:param _nft The NFT contract to get ordered tier ID from.
    /// @custom:param _tierId The tier ID to get the following tier for.
    /// @custom:returns The following tier's ID.
    mapping(address => mapping(uint256 => uint256)) internal _tierIdAfter;

    /// @notice Returns optional reserved token beneficiary addresses for the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract to which the reserved token beneficiary belongs.
    /// @custom:param _tierId The ID of the tier.
    /// @custom:returns The address of the reserved token beneficiary.
    mapping(address => mapping(uint256 => address)) internal _reservedTokenBeneficiaryOf;

    /// @notice Returns the tier at the provided contract and tier ID.
    /// @custom:param _nft The NFT contract to which the tiers belong.
    /// @custom:param _tierId The tier ID.
    /// @custom:returns The stored tier.
    mapping(address => mapping(uint256 => JBStored721Tier)) internal _storedTierOf;

    /// @notice Returns flags that influence the behavior of each NFT contract.
    /// @custom:param _nft The NFT contract for which the flags apply.
    /// @custom:returns The flags.
    mapping(address => JBTiered721Flags) internal _flagsOf;

    /// @notice For each tier ID, return a bitmap containing flags indicating whether the tier has been removed.
    /// @custom:param _nft The NFT contract to which the tier belongs.
    /// @custom:param _depth The bitmap row. Each row stores 256 tiers.
    /// @custom:returns _word The bitmap row's content.
    mapping(address => mapping(uint256 => uint256)) internal _isTierRemovedBitmapWord;

    /// @notice For each NFT, return the tier ID that comes last when sorting.
    /// @dev If not set, it is assumed the `maxTierIdOf` is the last sorted.
    /// @custom:param _nft The NFT contract to which the tier belongs.
    mapping(address => uint256) internal _trackedLastSortTierIdOf;

    /// @notice Returns the ID of the first tier in the provided NFT contract and category.
    /// @custom:param _nft The NFT contract to get the tier ID of.
    /// @custom:param _category The category to get the first tier ID of.
    mapping(address => mapping(uint256 => uint256)) internal _startingTierIdOfCategory;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice Returns the largest tier ID used on the provided NFT contract.
    /// @dev This may not include the last tier ID if it has been removed.
    /// @custom:param _nft The NFT contract to get the largest tier ID from.
    mapping(address => uint256) public override maxTierIdOf;

    /// @notice Returns the number of NFTs held by the provided address which belong to the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract to check balances for.
    /// @custom:param _owner The address to get a balance for.
    /// @custom:param _tierId The tier ID to get a balance for.
    mapping(address => mapping(address => mapping(uint256 => uint256))) public override tierBalanceOf;

    /// @notice Returns the number of reserved tokens which have been minted within the provided tier and NFT contract.
    /// @custom:param _nft The NFT contract that the reserved minting data belongs to.
    /// @custom:param _tierId The tier ID to get a reserved token mint count for.
    mapping(address => mapping(uint256 => uint256)) public override numberOfReservesMintedFor;

    /// @notice Returns the number of tokens belonging to the provided tier and NFT contract which have been burned.
    /// @custom:param _nft The NFT contract that the burning data belongs to.
    /// @custom:param _tierId The tier ID of the tier to get a burned token count for.
    mapping(address => mapping(uint256 => uint256)) public override numberOfBurnedFor;

    /// @notice Returns the reserved token beneficiary address used when a tier doesn't specify a beneficiary.
    /// @custom:param _nft The NFT contract to which the reserved token beneficiary applies.
    mapping(address => address) public override defaultReservedTokenBeneficiaryOf;

    /// @notice Returns a custom token URI resolver which supersedes the base URI.
    /// @custom:param _nft The NFT contract to which the token URI resolver applies.
    mapping(address => IJB721TokenUriResolver) public override tokenUriResolverOf;

    /// @notice Returns the encoded IPFS URI for the provided tier and NFT contract.
    /// @dev Token URIs managed by this contract are stored as 32 bytes and based on stripped down IPFS hashes.
    /// @custom:param _nft The NFT contract to which the encoded IPFS URI belongs.
    /// @custom:param _tierId The tier ID to which the encoded IPFS URI belongs.
    /// @custom:returns The encoded IPFS URI.
    mapping(address => mapping(uint256 => bytes32)) public override encodedIPFSUriOf;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//

    /// @notice Gets an array of active tiers.
    /// @param _nft The NFT contract to get tiers for.
    /// @param _categories The categories of the tiers to get. Send empty for all categories.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @param _startingId The starting tier ID of the array of tiers sorted by contribution floor. Send 0 to get all active tiers.
    /// @param _size The number of tiers to include.
    /// @return _tiers An array of active tiers.
    function tiersOf(
        address _nft,
        uint256[] calldata _categories,
        bool _includeResolvedUri,
        uint256 _startingId,
        uint256 _size
    ) external view override returns (JB721Tier[] memory _tiers) {
        // Keep a reference to the last tier ID.
        uint256 _lastTierId = _lastSortedTierIdOf(_nft);

        // Initialize an array with the appropriate length.
        _tiers = new JB721Tier[](_size);

        // Count the number of included tiers.
        uint256 _numberOfIncludedTiers;

        // Keep a reference to the tier being iterated upon.
        JBStored721Tier memory _storedTier;

        // Initialize a BitmapWord to track if a tier has been removed.
        JBBitmapWord memory _bitmapWord;

        // Keep a reference to the iterable variable.
        uint256 _i;

        // Iterate at least once.
        do {
            // Break if the size limit has been reached.
            if (_numberOfIncludedTiers == _size) break;

            // Get a reference to the tier ID being iterated upon, starting with the first tier ID if no starting ID was specified.
            uint256 _currentSortedTierId = _startingId != 0
                ? _startingId
                : _firstSortedTierIdOf(_nft, _categories.length == 0 ? 0 : _categories[_i]);

            // Make the sorted array.
            while (_currentSortedTierId != 0 && _numberOfIncludedTiers < _size) {
                if (!_isTierRemovedWithRefresh(_nft, _currentSortedTierId, _bitmapWord)) {
                    _storedTier = _storedTierOf[_nft][_currentSortedTierId];

                    if (_categories.length != 0 && _storedTier.category > _categories[_i]) {
                        break;
                    }
                    // If a category is specified and matches, add the returned values.
                    else if (_categories.length == 0 || _storedTier.category == _categories[_i]) {
                        // Add the tier to the array being returned.
                        _tiers[_numberOfIncludedTiers++] =
                            _getTierFrom(_nft, _currentSortedTierId, _storedTier, _includeResolvedUri);
                    }
                }
                // Set the next sorted tier ID.
                _currentSortedTierId = _nextSortedTierIdOf(_nft, _currentSortedTierId, _lastTierId);
            }

            unchecked {
                ++_i;
            }
        } while (_i < _categories.length);

        // Resize the array if there are removed tiers.
        if (_numberOfIncludedTiers != _size) {
            assembly ("memory-safe") {
                mstore(_tiers, _numberOfIncludedTiers)
            }
        }
    }

    /// @notice Return the tier for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to get a tier from.
    /// @param _id The tier ID of the tier to get.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @return The tier.
    function tierOf(address _nft, uint256 _id, bool _includeResolvedUri)
        public
        view
        override
        returns (JB721Tier memory)
    {
        return _getTierFrom(_nft, _id, _storedTierOf[_nft][_id], _includeResolvedUri);
    }

    /// @notice Return the tier for the provided token ID and NFT contract.
    /// @param _nft The NFT contract to get a tier from.
    /// @param _tokenId The token ID to return the tier of.
    /// @param _includeResolvedUri If enabled, if there's a token URI resolver, the content will be resolved and included.
    /// @return The tier.
    function tierOfTokenId(address _nft, uint256 _tokenId, bool _includeResolvedUri)
        external
        view
        override
        returns (JB721Tier memory)
    {
        // Get a reference to the tier's ID.
        uint256 _tierId = tierIdOfToken(_tokenId);
        return _getTierFrom(_nft, _tierId, _storedTierOf[_nft][_tierId], _includeResolvedUri);
    }

    /// @notice The total number of NFTs issued from all tiers of the provided NFT contract.
    /// @param _nft The NFT contract to get a total supply of.
    /// @return supply The total number of NFTs issued from all tiers.
    function totalSupplyOf(address _nft) external view override returns (uint256 supply) {
        // Keep a reference to the tier being iterated on.
        JBStored721Tier memory _storedTier;

        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        for (uint256 _i = _maxTierId; _i != 0;) {
            // Set the tier being iterated on.
            _storedTier = _storedTierOf[_nft][_i];

            // Increment the total supply by the number of tokens already minted.
            supply += _storedTier.initialQuantity - _storedTier.remainingQuantity;

            unchecked {
                --_i;
            }
        }
    }

    /// @notice Returns the number of currently mintable reserved tokens for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to check for mintable reserved tokens.
    /// @param _tierId The tier ID to check for mintable reserved tokens.
    /// @return The number of currently outstanding reserved tokens within the tier and contract.
    function numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId)
        external
        view
        override
        returns (uint256)
    {
        return _numberOfReservedTokensOutstandingFor(_nft, _tierId, _storedTierOf[_nft][_tierId]);
    }

    /// @notice Returns the total voting units from all of an addresses' NFTs (across all tiers) for the provided NFT contract. NFTs have a tier-specific number of voting units.
    /// @param _nft The NFT contract to get voting units within.
    /// @param _account The address to get the voting units of.
    /// @return units The total voting units for the address.
    function votingUnitsOf(address _nft, address _account) external view virtual override returns (uint256 units) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Keep a reference to the balance being iterated upon.
        uint256 _balance;

        // Keep a reference to the stored tier.
        JBStored721Tier memory _storedTier;

        // Loop through all tiers.
        for (uint256 _i = _maxTierId; _i != 0;) {
            // Get a reference to the account's balance in this tier.
            _balance = tierBalanceOf[_nft][_account][_i];

            if (_balance != 0) _storedTier = _storedTierOf[_nft][_i];

            (,, bool _useVotingUnits) = _unpackBools(_storedTier.packedBools);

            // Add the tier's voting units.
            // Use either the tier's price or custom set voting units.
            units += _balance * (_useVotingUnits ? _storedTier.votingUnits : _storedTier.price);

            unchecked {
                --_i;
            }
        }
    }

    /// @notice Returns the voting units for an addresses' NFTs in one tier. NFTs have a tier-specific number of voting units.
    /// @param _nft The NFT contract to get voting units within.
    /// @param _account The address to get the voting units of.
    /// @param _tierId The tier ID to get voting units within.
    /// @return The voting units for the address within the tier.
    function tierVotingUnitsOf(address _nft, address _account, uint256 _tierId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        // Get a reference to the account's balance in this tier.
        uint256 _balance = tierBalanceOf[_nft][_account][_tierId];

        if (_balance == 0) return 0;

        // Add the tier's voting units.
        return _balance * _storedTierOf[_nft][_tierId].votingUnits;
    }

    /// @notice Resolves the encoded IPFS URI of the tier for the provided token ID and NFT contract.
    /// @param _nft The NFT contract to which the encoded IPFS URI belongs.
    /// @param _tokenId The token ID to get the encoded IPFS URI of.
    /// @return The encoded IPFS URI.
    function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view override returns (bytes32) {
        return encodedIPFSUriOf[_nft][tierIdOfToken(_tokenId)];
    }

    /// @notice Flags that influence the behavior of each NFT.
    /// @param _nft The NFT contract for which the flags apply.
    /// @return The flags.
    function flagsOf(address _nft) external view override returns (JBTiered721Flags memory) {
        return _flagsOf[_nft];
    }

    /// @notice Check if the provided tier has been removed from the current set of tiers.
    /// @param _nft The NFT contract of the tier to check for removal.
    /// @param _tierId The tier ID to check for removal.
    /// @return True if the tier has been removed.
    function isTierRemoved(address _nft, uint256 _tierId) external view override returns (bool) {
        JBBitmapWord memory _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_tierId);

        return _bitmapWord.isTierIdRemoved(_tierId);
    }

    //*********************************************************************//
    // -------------------------- public views --------------------------- //
    //*********************************************************************//

    /// @notice The total number of tokens owned by the provided address.
    /// @param _nft The NFT contract to check the balance within.
    /// @param _owner The address to check the balance of.
    /// @return balance The number of tokens owned by the owner across all tiers within the NFT contract.
    function balanceOf(address _nft, address _owner) public view override returns (uint256 balance) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Loop through all tiers.
        for (uint256 _i = _maxTierId; _i != 0;) {
            // Get a reference to the account's balance within this tier.
            balance += tierBalanceOf[_nft][_owner][_i];

            unchecked {
                --_i;
            }
        }
    }

    /// @notice The cumulative redemption weight of the given token IDs compared to the `totalRedemptionWeight`.
    /// @param _nft The NFT contract which the redemption weight is being calculated within.
    /// @param _tokenIds The IDs of the tokens to get the cumulative redemption weight of.
    /// @return weight The weight.
    function redemptionWeightOf(address _nft, uint256[] calldata _tokenIds)
        public
        view
        override
        returns (uint256 weight)
    {
        // Get a reference to the total number of tokens.
        uint256 _numberOfTokenIds = _tokenIds.length;

        // Add each token's tier's contribution floor to the weight.
        for (uint256 _i; _i < _numberOfTokenIds;) {
            weight += _storedTierOf[_nft][tierIdOfToken(_tokenIds[_i])].price;

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice The cumulative redemption weight for all token IDs.
    /// @param _nft The NFT contract for which the redemption weight is being calculated.
    /// @return weight The total weight.
    function totalRedemptionWeight(address _nft) public view override returns (uint256 weight) {
        // Keep a reference to the greatest tier ID.
        uint256 _maxTierId = maxTierIdOf[_nft];

        // Keep a reference to the tier being iterated upon.
        JBStored721Tier memory _storedTier;

        // Add each token's tier's contribution floor to the weight.
        for (uint256 _i; _i < _maxTierId;) {
            // Keep a reference to the stored tier.
            unchecked {
                _storedTier = _storedTierOf[_nft][_i + 1];
            }

            // Add the tier's contribution floor multiplied by the quantity minted.
            weight += _storedTier.price
                * (
                    (_storedTier.initialQuantity - _storedTier.remainingQuantity)
                        + _numberOfReservedTokensOutstandingFor(_nft, _i + 1, _storedTier)
                );

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice The tier ID of the provided token ID.
    /// @dev Tiers are 1-indexed from the `tiers` array, meaning the 0th element of the array is tier 1.
    /// @param _tokenId The token ID to get the tier ID of.
    /// @return The tier ID for the provided token ID.
    function tierIdOfToken(uint256 _tokenId) public pure override returns (uint256) {
        return _tokenId / _ONE_BILLION;
    }

    /// @notice The reserved token beneficiary address for the provided tier ID and NFT contract.
    /// @param _nft The NFT contract to check the reserved token beneficiary within.
    /// @param _tierId The tier ID to get the reserved token beneficiary of.
    /// @return The reserved token beneficiary address.
    function reservedTokenBeneficiaryOf(address _nft, uint256 _tierId) public view override returns (address) {
        // Get the stored reserved token beneficiary.
        address _storedReservedTokenBeneficiaryOfTier = _reservedTokenBeneficiaryOf[_nft][_tierId];

        // If the tier has a beneficiary return it.
        if (_storedReservedTokenBeneficiaryOfTier != address(0)) {
            return _storedReservedTokenBeneficiaryOfTier;
        }

        // Return the default.
        return defaultReservedTokenBeneficiaryOf[_nft];
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Adds tiers.
    /// @param _tiersToAdd The tiers to add.
    /// @return tierIds The IDs of the tiers added.
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
        if (_currentMaxTierIdOf + _numberOfNewTiers > type(uint16).max) revert MAX_TIERS_EXCEEDED();

        // Keep a reference to the current last sorted tier ID.
        uint256 _currentLastSortedTierId = _lastSortedTierIdOf(msg.sender);

        // Initialize an array with the appropriate length.
        tierIds = new uint256[](_numberOfNewTiers);

        // Keep a reference to the starting sort ID for sorting new tiers if needed.
        // There's no need for sorting if there are currently no tiers.
        uint256 _startSortedTierId = _currentMaxTierIdOf == 0 ? 0 : _firstSortedTierIdOf(msg.sender, 0);

        // Keep track of the previous tier ID.
        uint256 _previous;

        // Keep a reference to the tier being iterated upon.
        JB721TierParams memory _tierToAdd;

        // Keep a reference to the flags.
        JBTiered721Flags memory _flags = _flagsOf[msg.sender];

        for (uint256 _i; _i < _numberOfNewTiers;) {
            // Set the tier being iterated upon.
            _tierToAdd = _tiersToAdd[_i];

            // Make sure the max is enforced.
            if (_tierToAdd.initialQuantity > _ONE_BILLION - 1) revert INVALID_QUANTITY();

            // Keep a reference to the previous tier.
            JB721TierParams memory _previousTier;

            // Make sure the tier's category is greater than or equal to the previous tier's category.
            if (_i != 0) {
                // Set the reference to the previous tier.
                _previousTier = _tiersToAdd[_i - 1];

                // Check category sort order.
                if (_tierToAdd.category < _previousTier.category) revert INVALID_CATEGORY_SORT_ORDER();
            }

            // Make sure there are no voting units set if they're not allowed.
            if (
                _flags.lockVotingUnitChanges
                    && (
                        (_tierToAdd.useVotingUnits && _tierToAdd.votingUnits != 0)
                            || (!_tierToAdd.useVotingUnits && _tierToAdd.price != 0)
                    )
            ) {
                revert VOTING_UNITS_NOT_ALLOWED();
            }

            // Make sure a reserved rate isn't set if changes should be locked, or if manual minting is allowed.
            if ((_flags.lockReservedTokenChanges || _tierToAdd.allowManualMint) && _tierToAdd.reservedRate != 0) {
                revert RESERVED_RATE_NOT_ALLOWED();
            }

            // Make sure manual minting is not set if not allowed.
            if (_flags.lockManualMintingChanges && _tierToAdd.allowManualMint) {
                revert MANUAL_MINTING_NOT_ALLOWED();
            }

            // Make sure there is some quantity.
            if (_tierToAdd.initialQuantity == 0) revert NO_QUANTITY();

            // Get a reference to the tier ID.
            uint256 _tierId = _currentMaxTierIdOf + _i + 1;

            // Add the tier with the iterative ID.
            _storedTierOf[msg.sender][_tierId] = JBStored721Tier({
                price: uint104(_tierToAdd.price),
                remainingQuantity: uint32(_tierToAdd.initialQuantity),
                initialQuantity: uint32(_tierToAdd.initialQuantity),
                votingUnits: uint40(_tierToAdd.votingUnits),
                reservedRate: uint16(_tierToAdd.reservedRate),
                category: uint24(_tierToAdd.category),
                packedBools: _packBools(_tierToAdd.allowManualMint, _tierToAdd.transfersPausable, _tierToAdd.useVotingUnits)
            });

            // If this is the first tier in a new category, store its ID as such. The `_startingTierIdOfCategory` of the 0 category will always be the same as the `_tierIdAfter` the 0th tier.
            if (_previousTier.category != _tierToAdd.category && _tierToAdd.category != 0) {
                _startingTierIdOfCategory[msg.sender][_tierToAdd.category] = _tierId;
            }

            // Set the reserved token beneficiary if needed.
            if (_tierToAdd.reservedTokenBeneficiary != address(0)) {
                if (_tierToAdd.shouldUseReservedTokenBeneficiaryAsDefault) {
                    if (defaultReservedTokenBeneficiaryOf[msg.sender] != _tierToAdd.reservedTokenBeneficiary) {
                        defaultReservedTokenBeneficiaryOf[msg.sender] = _tierToAdd.reservedTokenBeneficiary;
                    }
                } else {
                    _reservedTokenBeneficiaryOf[msg.sender][_tierId] = _tierToAdd.reservedTokenBeneficiary;
                }
            }

            // Set the encodedIPFSUri if needed.
            if (_tierToAdd.encodedIPFSUri != bytes32(0)) {
                encodedIPFSUriOf[msg.sender][_tierId] = _tierToAdd.encodedIPFSUri;
            }

            if (_startSortedTierId != 0) {
                // Keep track of the sorted tier ID.
                uint256 _currentSortedTierId = _startSortedTierId;

                // Keep a reference to the tier ID to iterate on next.
                uint256 _next;

                while (_currentSortedTierId != 0) {
                    // Set the next tier ID.
                    _next = _nextSortedTierIdOf(msg.sender, _currentSortedTierId, _currentLastSortedTierId);

                    // If the category is less than or equal to the tier being iterated on and the tier being iterated isn't among those being added, store the order.
                    if (
                        _tierToAdd.category <= _storedTierOf[msg.sender][_currentSortedTierId].category
                            && _currentSortedTierId <= _currentMaxTierIdOf
                    ) {
                        // If the tier ID being iterated on isn't the next tier ID, set the tier ID after.
                        if (_currentSortedTierId != _tierId + 1) {
                            _tierIdAfter[msg.sender][_tierId] = _currentSortedTierId;
                        }

                        // If this is the first tier being added, track the current last sorted tier ID if it's not already tracked.
                        if (_trackedLastSortTierIdOf[msg.sender] != _currentLastSortedTierId) {
                            _trackedLastSortTierIdOf[msg.sender] = _currentLastSortedTierId;
                        }

                        // If the previous after tier ID was set to something else, set the previous tier ID after.
                        if (_previous != _tierId - 1 || _tierIdAfter[msg.sender][_previous] != 0) {
                            // Set the tier after the previous one being iterated on as the tier being added, or 0 if the tier ID is incremented.
                            _tierIdAfter[msg.sender][_previous] = _previous == _tierId - 1 ? 0 : _tierId;
                        }

                        // For the next tier being added, start at the tier just placed.
                        _startSortedTierId = _currentSortedTierId;

                        // The tier just added is the previous for the next tier being added.
                        _previous = _tierId;

                        // Set current to zero to break out of the loop.
                        _currentSortedTierId = 0;
                    }
                    // If the tier being iterated on is the last tier, add the tier after it.
                    else if (_next == 0 || _next > _currentMaxTierIdOf) {
                        if (_tierId != _currentSortedTierId + 1) {
                            _tierIdAfter[msg.sender][_currentSortedTierId] = _tierId;
                        }

                        // For the next tier being added, start at this current tier ID.
                        _startSortedTierId = _tierId;

                        // Break out.
                        _currentSortedTierId = 0;

                        // If there's currently a last sorted tier ID tracked, override it.
                        if (_trackedLastSortTierIdOf[msg.sender] != 0) _trackedLastSortTierIdOf[msg.sender] = 0;
                    }
                    // Move on to the next tier ID.
                    else {
                        // Set the previous tier ID to be the current tier ID.
                        _previous = _currentSortedTierId;

                        // Go to the next tier ID.
                        _currentSortedTierId = _next;
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

    /// @notice Record reserved token mints within the provided tier.
    /// @param _tierId The ID of the tier to mint reserved tokens from.
    /// @param _count The number of reserved tokens to mint.
    /// @return tokenIds The IDs of the tokens being minted as reserves.
    function recordMintReservesFor(uint256 _tierId, uint256 _count)
        external
        override
        returns (uint256[] memory tokenIds)
    {
        // Get a reference to the tier.
        JBStored721Tier storage _storedTier = _storedTierOf[msg.sender][_tierId];

        // Get a reference to the number of mintable reserved tokens for the tier.
        uint256 _numberOfReservedTokensOutstanding =
            _numberOfReservedTokensOutstandingFor(msg.sender, _tierId, _storedTier);

        // Can't mint more reserves than expected.
        if (_count > _numberOfReservedTokensOutstanding) revert INSUFFICIENT_RESERVES();

        // Increment the number of reserved tokens minted.
        numberOfReservesMintedFor[msg.sender][_tierId] += _count;

        // Initialize an array with the appropriate length.
        tokenIds = new uint256[](_count);

        // Keep a reference to the number of burned in the tier.
        uint256 _numberOfBurnedFromTier = numberOfBurnedFor[msg.sender][_tierId];

        for (uint256 _i; _i < _count;) {
            // Generate the tokens.
            tokenIds[_i] = _generateTokenId(
                _tierId, _storedTier.initialQuantity - --_storedTier.remainingQuantity + _numberOfBurnedFromTier
            );

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Record a token transfer.
    /// @param _tierId The tier ID of the token being transferred.
    /// @param _from The address the token is being transferred from.
    /// @param _to The address the token is being transferred to.
    function recordTransferForTier(uint256 _tierId, address _from, address _to) external override {
        // If this is not a mint then subtract the tier balance from the original holder.
        if (_from != address(0)) {
            // Decrease the tier balance for the sender.
            --tierBalanceOf[msg.sender][_from][_tierId];
        }

        // If this is a burn the balance is not added.
        if (_to != address(0)) {
            unchecked {
                // Increase the tier balance for the beneficiary.
                ++tierBalanceOf[msg.sender][_to][_tierId];
            }
        }
    }

    /// @notice Record removing the provided tiers.
    /// @param _tierIds The tiers IDs to remove.
    function recordRemoveTierIds(uint256[] calldata _tierIds) external override {
        // Get a reference to the number of tiers being removed.
        uint256 _numTiers = _tierIds.length;

        // Keep a reference to the tier ID being iterated upon.
        uint256 _tierId;

        for (uint256 _i; _i < _numTiers;) {
            // Set the tier being iterated upon (0-indexed).
            _tierId = _tierIds[_i];

            // Set the tier as removed.
            _isTierRemovedBitmapWord[msg.sender].removeTier(_tierId);

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Record token mints in the provided tiers.
    /// @param _amount The amount to base the mints on. All mints' price floors must fit within this amount.
    /// @param _tierIds The tier IDs to mint from.
    /// @param _isManualMint A flag indicating if the mint is being made manually by the NFT contract's owner.
    /// @return tokenIds The IDs of the minted tokens.
    /// @return leftoverAmount The amount left over after the mint.
    function recordMint(uint256 _amount, uint16[] calldata _tierIds, bool _isManualMint)
        external
        override
        returns (uint256[] memory tokenIds, uint256 leftoverAmount)
    {
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
        JBBitmapWord memory _bitmapWord;

        for (uint256 _i; _i < _numberOfTiers;) {
            // Set the tier ID being iterated on.
            _tierId = _tierIds[_i];

            // Make sure the tier hasn't been removed.
            if (_isTierRemovedWithRefresh(msg.sender, _tierId, _bitmapWord)) revert TIER_REMOVED();

            // Keep a reference to the tier being iterated on.
            _storedTier = _storedTierOf[msg.sender][_tierId];

            (bool _allowManualMint,,) = _unpackBools(_storedTier.packedBools);

            // If this is a manual mint, make sure manual minting is allowed.
            if (_isManualMint && !_allowManualMint) revert CANT_MINT_MANUALLY();

            // Make sure the provided tier exists.
            if (_storedTier.initialQuantity == 0) revert INVALID_TIER();

            // Make sure the amount meets the tier's contribution floor.
            if (_storedTier.price > leftoverAmount) revert INSUFFICIENT_AMOUNT();

            // Make sure there are enough units available.
            if (
                _storedTier.remainingQuantity - _numberOfReservedTokensOutstandingFor(msg.sender, _tierId, _storedTier)
                    == 0
            ) revert OUT();

            // Mint the tokens.
            unchecked {
                // Keep a reference to the token ID.
                tokenIds[_i] = _generateTokenId(
                    _tierId,
                    _storedTier.initialQuantity - --_storedTier.remainingQuantity
                        + numberOfBurnedFor[msg.sender][_tierId]
                );
            }

            // Update the leftover amount;
            unchecked {
                leftoverAmount = leftoverAmount - _storedTier.price;
                ++_i;
            }
        }
    }

    /// @notice Records token burns.
    /// @param _tokenIds The IDs of the tokens being burned.
    function recordBurn(uint256[] calldata _tokenIds) external override {
        // Get a reference to the number of token IDs provided.
        uint256 _numberOfTokenIds = _tokenIds.length;

        // Keep a reference to the token ID being iterated on.
        uint256 _tokenId;

        // Iterate through all tokens to increment the burn count.
        for (uint256 _i; _i < _numberOfTokenIds;) {
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

    /// @notice Sets the token URI resolver.
    /// @param _resolver The resolver to set.
    function recordSetTokenUriResolver(IJB721TokenUriResolver _resolver) external override {
        tokenUriResolverOf[msg.sender] = _resolver;
    }

    /// @notice Sets the encoded IPFS URI of a tier.
    /// @param _tierId The tier ID to set the encoded IPFS URI of.
    /// @param _encodedIPFSUri The encoded IPFS URI to set.
    function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external override {
        encodedIPFSUriOf[msg.sender][_tierId] = _encodedIPFSUri;
    }

    /// @notice Sets flags.
    /// @param _flags The flags to set.
    function recordFlags(JBTiered721Flags calldata _flags) external override {
        _flagsOf[msg.sender] = _flags;
    }

    /// @notice Removes an NFT contract's removed tiers from sequencing.
    /// @param _nft The NFT contract to clean tiers for.
    function cleanTiers(address _nft) external override {
        // Keep a reference to the last tier ID.
        uint256 _lastSortedTierId = _lastSortedTierIdOf(_nft);

        // Get a reference to the tier ID being iterated on, starting with the starting tier ID.
        uint256 _currentSortedTierId = _firstSortedTierIdOf(_nft, 0);

        // Keep track of the previous non-removed tier ID.
        uint256 _previous;

        // Initialize a BitmapWord for isRemoved.
        JBBitmapWord memory _bitmapWord;

        // Make the sorted array.
        while (_currentSortedTierId != 0) {
            if (!_isTierRemovedWithRefresh(_nft, _currentSortedTierId, _bitmapWord)) {
                // If the current tier ID being iterated on isn't an increment of the previous, set the correct tier after if needed.
                if (_currentSortedTierId != _previous + 1) {
                    if (_tierIdAfter[_nft][_previous] != _currentSortedTierId) {
                        _tierIdAfter[_nft][_previous] = _currentSortedTierId;
                    }
                    // Otherwise if the current tier ID is an increment of the previous and the tier ID after isn't 0, set it to 0.
                } else if (_tierIdAfter[_nft][_previous] != 0) {
                    _tierIdAfter[_nft][_previous] = 0;
                }

                // Set the previous tier ID to be the current tier ID.
                _previous = _currentSortedTierId;
            }
            // Set the next sorted tier ID.
            _currentSortedTierId = _nextSortedTierIdOf(_nft, _currentSortedTierId, _lastSortedTierId);
        }

        emit CleanTiers(_nft, msg.sender);
    }

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice Returns a tier given a provided stored tier.
    /// @param _nft The NFT contract to get the tier from.
    /// @param _tierId The tier ID of the tier to get.
    /// @param _storedTier The stored tier to base the tier on.
    /// @param _includeResolvedUri If true, if there's a token URI resolver, the content will be resolved and included.
    /// @return tier The tier object.
    function _getTierFrom(address _nft, uint256 _tierId, JBStored721Tier memory _storedTier, bool _includeResolvedUri)
        internal
        view
        returns (JB721Tier memory)
    {
        // Get a reference to the reserved token beneficiary.
        address _reservedTokenBeneficiary = reservedTokenBeneficiaryOf(_nft, _tierId);

        (bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits) = _unpackBools(_storedTier.packedBools);

        return JB721Tier({
            id: _tierId,
            price: _storedTier.price,
            remainingQuantity: _storedTier.remainingQuantity,
            initialQuantity: _storedTier.initialQuantity,
            votingUnits: _useVotingUnits ? _storedTier.votingUnits : _storedTier.price,
            // No reserved rate if no beneficiary set.
            reservedRate: _reservedTokenBeneficiary == address(0) ? 0 : _storedTier.reservedRate,
            reservedTokenBeneficiary: _reservedTokenBeneficiary,
            encodedIPFSUri: encodedIPFSUriOf[_nft][_tierId],
            category: _storedTier.category,
            allowManualMint: _allowManualMint,
            transfersPausable: _transfersPausable,
            resolvedUri: !_includeResolvedUri || tokenUriResolverOf[_nft] == IJB721TokenUriResolver(address(0))
                ? ""
                : tokenUriResolverOf[_nft].tokenUriOf(_nft, _generateTokenId(_tierId, 0))
        });
    }

    /// @notice Check if a tier is removed from the current set of tiers, while reusing a bitmap word.
    /// @param _nft The NFT contract on which to check if the tier is removed.
    /// @param _tierId The tier ID to check for removal.
    /// @param _bitmapWord The bitmap word to reuse.
    /// @return True if the tier has been removed.
    function _isTierRemovedWithRefresh(address _nft, uint256 _tierId, JBBitmapWord memory _bitmapWord)
        internal
        view
        returns (bool)
    {
        // Reset the bitmap if the current tier ID is outside the currently stored word.
        if (_bitmapWord.refreshBitmapNeeded(_tierId) || (_bitmapWord.currentWord == 0 && _bitmapWord.currentDepth == 0))
        {
            _bitmapWord = _isTierRemovedBitmapWord[_nft].readId(_tierId);
        }

        return _bitmapWord.isTierIdRemoved(_tierId);
    }

    /// @notice The number of mintable reserved tokens within the provided tier.
    /// @param _nft The NFT contract to check mintable reserved tokens on.
    /// @param _tierId The tier ID to check the number of mintable reserved tokens for.
    /// @param _storedTier The stored tier to get the number of mintable reserved tokens for.
    /// @return numberReservedTokensOutstanding The number of outstanding mintable reserved tokens within the tier.
    function _numberOfReservedTokensOutstandingFor(address _nft, uint256 _tierId, JBStored721Tier memory _storedTier)
        internal
        view
        returns (uint256)
    {
        // No reserves outstanding if no mints or no reserved rate.
        if (
            _storedTier.reservedRate == 0 || _storedTier.initialQuantity == _storedTier.remainingQuantity
                || reservedTokenBeneficiaryOf(_nft, _tierId) == address(0)
        ) return 0;

        // The number of reserved tokens of the tier already minted.
        uint256 _reserveTokensMinted = numberOfReservesMintedFor[_nft][_tierId];

        // If only the reserved token (from the rounding up) has been minted so far, return 0.
        if (_storedTier.initialQuantity - _reserveTokensMinted == _storedTier.remainingQuantity) {
            return 0;
        }

        // Get a reference to the number of tokens already minted in the tier, not counting reserves or burned tokens.
        uint256 _numberOfNonReservesMinted;
        unchecked {
            _numberOfNonReservesMinted =
                _storedTier.initialQuantity - _storedTier.remainingQuantity - _reserveTokensMinted;
        }

        // Get the number of reserved tokens mintable given the number of non reserved tokens minted. This will round down.
        uint256 _numberReservedTokensMintable = _numberOfNonReservesMinted / _storedTier.reservedRate;

        // Round up.
        if (_numberOfNonReservesMinted % _storedTier.reservedRate > 0) ++_numberReservedTokensMintable;

        // Make sure there are more mintable than have been minted. This is possible if some tokens have been burned.
        if (_reserveTokensMinted > _numberReservedTokensMintable) return 0;

        // Return the difference between the amount mintable and the amount already minted.
        unchecked {
            return _numberReservedTokensMintable - _reserveTokensMinted;
        }
    }

    /// @notice Finds the token ID given a tier ID and a token number within that tier.
    /// @param _tierId The ID of the tier to generate an ID for.
    /// @param _tokenNumber The number of the token in the tier.
    /// @return The ID of the token.
    function _generateTokenId(uint256 _tierId, uint256 _tokenNumber) internal pure returns (uint256) {
        return (_tierId * _ONE_BILLION) + _tokenNumber;
    }

    /// @notice The next sorted tier ID.
    /// @param _nft The NFT contract for which the sorted tier ID applies.
    /// @param _id The ID relative to which the next sorted ID will be returned.
    /// @param _max The maximum possible ID.
    /// @return The ID.
    function _nextSortedTierIdOf(address _nft, uint256 _id, uint256 _max) internal view returns (uint256) {
        // If this is the last tier, return zero.
        if (_id == _max) return 0;

        // Update the current tier ID to be the one saved to be after, if it exists.
        uint256 _storedNext = _tierIdAfter[_nft][_id];

        if (_storedNext != 0) return _storedNext;

        // Otherwise increment the current.
        return _id + 1;
    }

    /// @notice The first sorted tier ID of an NFT contract.
    /// @param _nft The NFT contract to get the first sorted tier ID of.
    /// @param _category The category to get the first sorted tier ID of. Send 0 for the first overall sorted ID, which might not be of the 0 category if there isn't a tier of the 0 category.
    /// @return id The first sorted tier ID.
    function _firstSortedTierIdOf(address _nft, uint256 _category) internal view returns (uint256 id) {
        id = _category == 0 ? _tierIdAfter[_nft][0] : _startingTierIdOfCategory[_nft][_category];
        // Start at the first tier ID if nothing is specified.
        if (id == 0) id = 1;
    }

    /// @notice The last sorted tier ID of an NFT.
    /// @param _nft The NFT contract to get the last sorted tier ID of.
    /// @return id The last sorted tier ID.
    function _lastSortedTierIdOf(address _nft) internal view returns (uint256 id) {
        id = _trackedLastSortTierIdOf[_nft];
        // Start at the first ID if nothing is specified.
        if (id == 0) id = maxTierIdOf[_nft];
    }

    /// @notice Pack three bools into a single uint8.
    /// @param _allowManualMint Whether or not manual mints are allowed.
    /// @param _transfersPausable Whether or not transfers are pausable.
    /// @param _useVotingUnits A flag indicating whether the voting units override should be used.
    /// @return _packed The packed bools.
    function _packBools(bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits)
        internal
        pure
        returns (uint8 _packed)
    {
        assembly {
            _packed := or(_allowManualMint, _packed)
            _packed := or(shl(0x1, _transfersPausable), _packed)
            _packed := or(shl(0x2, _useVotingUnits), _packed)
        }
    }

    /// @notice Unpack three bools from a single uint8.
    /// @param _packed The packed bools.
    /// @return _allowManualMint Whether or not manual mints are allowed.
    /// @return _transfersPausable Whether or not transfers are pausable.
    /// @return _useVotingUnits A flag indicating whether the voting units override should be used.
    function _unpackBools(uint8 _packed)
        internal
        pure
        returns (bool _allowManualMint, bool _transfersPausable, bool _useVotingUnits)
    {
        assembly {
            _allowManualMint := iszero(iszero(and(0x1, _packed)))
            _transfersPausable := iszero(iszero(and(0x2, _packed)))
            _useVotingUnits := iszero(iszero(and(0x4, _packed)))
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJB721TokenUriResolver } from "./IJB721TokenUriResolver.sol";
import { JB721TierParams } from "./../structs/JB721TierParams.sol";
import { JB721Tier } from "./../structs/JB721Tier.sol";
import { JBTiered721Flags } from "./../structs/JBTiered721Flags.sol";

interface IJBTiered721DelegateStore {
    event CleanTiers(address indexed nft, address caller);

    function totalSupplyOf(address _nft) external view returns (uint256);

    function balanceOf(address _nft, address _owner) external view returns (uint256);

    function maxTierIdOf(address _nft) external view returns (uint256);

    function tiersOf(
        address nft,
        uint256[] calldata categories,
        bool includeResolvedUri,
        uint256 startingSortIndex,
        uint256 size
    ) external view returns (JB721Tier[] memory tiers);

    function tierOf(address nft, uint256 id, bool includeResolvedUri) external view returns (JB721Tier memory tier);

    function tierBalanceOf(address nft, address owner, uint256 tier) external view returns (uint256);

    function tierOfTokenId(address nft, uint256 tokenId, bool includeResolvedUri)
        external
        view
        returns (JB721Tier memory tier);

    function tierIdOfToken(uint256 tokenId) external pure returns (uint256);

    function encodedIPFSUriOf(address nft, uint256 tierId) external view returns (bytes32);

    function redemptionWeightOf(address nft, uint256[] memory tokenIds) external view returns (uint256 weight);

    function totalRedemptionWeight(address nft) external view returns (uint256 weight);

    function numberOfReservedTokensOutstandingFor(address nft, uint256 tierId) external view returns (uint256);

    function numberOfReservesMintedFor(address nft, uint256 tierId) external view returns (uint256);

    function numberOfBurnedFor(address nft, uint256 tierId) external view returns (uint256);

    function isTierRemoved(address nft, uint256 tierId) external view returns (bool);

    function flagsOf(address nft) external view returns (JBTiered721Flags memory);

    function votingUnitsOf(address nft, address account) external view returns (uint256 units);

    function tierVotingUnitsOf(address nft, address account, uint256 tierId) external view returns (uint256 units);

    function defaultReservedTokenBeneficiaryOf(address nft) external view returns (address);

    function reservedTokenBeneficiaryOf(address nft, uint256 tierId) external view returns (address);

    function tokenUriResolverOf(address nft) external view returns (IJB721TokenUriResolver);

    function encodedTierIPFSUriOf(address nft, uint256 tokenId) external view returns (bytes32);

    function recordAddTiers(JB721TierParams[] memory tierData) external returns (uint256[] memory tierIds);

    function recordMintReservesFor(uint256 tierId, uint256 count) external returns (uint256[] memory tokenIds);

    function recordBurn(uint256[] memory tokenIds) external;

    function recordMint(uint256 amount, uint16[] calldata tierIds, bool isManualMint)
        external
        returns (uint256[] memory tokenIds, uint256 leftoverAmount);

    function recordTransferForTier(uint256 tierId, address from, address to) external;

    function recordRemoveTierIds(uint256[] memory tierIds) external;

    function recordSetTokenUriResolver(IJB721TokenUriResolver resolver) external;

    function recordSetEncodedIPFSUriOf(uint256 tierId, bytes32 encodedIPFSUri) external;

    function recordFlags(JBTiered721Flags calldata flag) external;

    function cleanTiers(address nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJB721TokenUriResolver {
    function tokenUriOf(address nft, uint256 tokenId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { JBBitmapWord } from "../structs/JBBitmapWord.sol";

/// @title JBBitmap
/// @notice Utilities to manage bool bitmap storing the inactive tiers.
library JBBitmap {
    /// @notice Initialize a BitmapWord struct, based on the mapping storage pointer and a given index.
    function readId(mapping(uint256 => uint256) storage self, uint256 _index)
        internal
        view
        returns (JBBitmapWord memory)
    {
        uint256 _depth = _retrieveDepth(_index);

        return JBBitmapWord({currentWord: self[_depth], currentDepth: _depth});
    }

    /// @notice Returns the status of a given bit, in the single word stored in a BitmapWord struct.
    function isTierIdRemoved(JBBitmapWord memory self, uint256 _index) internal pure returns (bool) {
        return (self.currentWord >> (_index % 256)) & 1 == 1;
    }

    /// @notice Returns the status of a bit in a given bitmap (index is the index in the reshaped bitmap matrix 1*n).
    function isTierIdRemoved(mapping(uint256 => uint256) storage self, uint256 _index) internal view returns (bool) {
        uint256 _depth = _retrieveDepth(_index);
        return isTierIdRemoved(JBBitmapWord({currentWord: self[_depth], currentDepth: _depth}), _index);
    }

    /// @notice Flip the bit at a given index to true (this is a one-way operation).
    function removeTier(mapping(uint256 => uint256) storage self, uint256 _index) internal {
        uint256 _depth = _retrieveDepth(_index);
        self[_depth] |= uint256(1 << (_index % 256));
    }

    /// @notice Return true if the index is in an another word than the one stored in the BitmapWord struct.
    function refreshBitmapNeeded(JBBitmapWord memory self, uint256 _index) internal pure returns (bool) {
        return _retrieveDepth(_index) != self.currentDepth;
    }

    // Lib internal

    /// @notice Return the lines of the bitmap matrix where an index lies.
    function _retrieveDepth(uint256 _index) internal pure returns (uint256) {
        return _index >> 8; // div by 256
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member The information stored at the index.
 *   @custom:member The index.
 */
struct JBBitmapWord {
    uint256 currentWord;
    uint256 currentDepth;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @custom:member id The tier's ID.
 *   @custom:member price The price that must be paid to qualify for this tier.
 *   @custom:member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
 *   @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
 *   @custom:member votingUnits The amount of voting significance to give this tier compared to others.
 *   @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
 *   @custom:member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
 *   @custom:member encodedIPFSUri The URI to use for each token within the tier.
 *   @custom:member category A category to group NFT tiers by.
 *   @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
 *   @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
 *   @custom:member resolvedTokenUri A resolved token URI if a resolver is included for the NFT to which this tier belongs.
 */
struct JB721Tier {
    uint256 id;
    uint256 price;
    uint256 remainingQuantity;
    uint256 initialQuantity;
    uint256 votingUnits;
    uint256 reservedRate;
    address reservedTokenBeneficiary;
    bytes32 encodedIPFSUri;
    uint256 category;
    bool allowManualMint;
    bool transfersPausable;
    string resolvedUri;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member price The minimum contribution to qualify for this tier.
 *   @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
 *   @custom:member votingUnits The amount of voting significance to give this tier compared to others.
 *   @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
 *   @custom:member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
 *   @custom:member encodedIPFSUri The URI to use for each token within the tier.
 *   @custom:member category A category to group NFT tiers by.
 *   @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
 *   @custom:member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
 *   @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
 *   @custom:member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
 */
struct JB721TierParams {
    uint104 price;
    uint32 initialQuantity;
    uint32 votingUnits;
    uint16 reservedRate;
    address reservedTokenBeneficiary;
    bytes32 encodedIPFSUri;
    uint24 category;
    bool allowManualMint;
    bool shouldUseReservedTokenBeneficiaryAsDefault;
    bool transfersPausable;
    bool useVotingUnits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member price The minimum contribution to qualify for this tier.
 *   @custom:member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
 *   @custom:member initialQuantity The initial `remainingAllowance` value when the tier was set.
 *   @custom:member votingUnits The amount of voting significance to give this tier compared to others.
 *   @custom:member category A category to group NFT tiers by.
 *   @custom:member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
 *   @custom:member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
 *   @custom:member transfersPausable A flag indicating if transfers from this tier can be pausable. 
 *   @custom:member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
 */
struct JBStored721Tier {
    uint104 price;
    uint32 remainingQuantity;
    uint32 initialQuantity;
    uint40 votingUnits;
    uint24 category;
    uint16 reservedRate;
    uint8 packedBools;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
 *   @custom:member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
 *   @custom:member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
 *   @custom:member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted.
 */
struct JBTiered721Flags {
    bool lockReservedTokenChanges;
    bool lockVotingUnitChanges;
    bool lockManualMintingChanges;
    bool preventOverspending;
}

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