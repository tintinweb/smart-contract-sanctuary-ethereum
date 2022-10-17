// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./Interfaces.sol";

contract NounSeek is Ownable2Step, Pausable {
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERROR
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    error TooLate();
    error MatchFound(uint16 nounId);
    error NoMatch();
    error InactiveDonee();
    error ValueTooLow();

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    event RequestAdded(
        uint256 requestId,
        address indexed requester,
        Traits indexed trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 nounId,
        uint256 amount,
        uint16 nonce
    );
    event RequestRemoved(
        uint256 requestId,
        address indexed requester,
        Traits indexed trait,
        uint16 traitId,
        uint16 doneeId,
        uint16 nounId,
        uint256 amounts
    );
    event DoneeAdded(
        uint256 doneeId,
        string name,
        address to,
        string description
    );
    event DoneeActiveStatusChanged(uint256 doneeId, bool active);
    event Matched(Traits trait, uint16 traitId, uint16 nounId, uint16 newNonce);
    event Donated(uint256[] donations);
    event Reimbursed(address matcher, uint256 amount);
    event MinValueChanged(uint256 newMinValue);
    event ReimbursementBPSChanged(uint256 newReimbursementBPS);

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CUSTOM TYPES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Stores deposited value, requested traits, donation target, and a nonce for marking stale requests
    struct Request {
        uint16 nonce;
        Traits trait;
        uint16 traitId;
        uint16 doneeId;
        uint16 nounId;
        uint128 amount;
    }

    /// @notice Name, address, and active status where funds can be donated
    struct Donee {
        string name;
        address to;
        bool active;
    }
    /// @notice Noun traits in the order they appear on the NounSeeder.Seed struct
    enum Traits {
        BACKGROUND,
        BODY,
        ACCESSORY,
        HEAD,
        GLASSES
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTANTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Retreives historical mapping of Noun ID -> seed
    INounsTokenLike public immutable nouns;

    /// @notice Retreives the current auction data
    INounsAuctionHouseLike public immutable auctionHouse;

    /// @notice The address of the WETH contract
    IWETH public immutable weth;

    /// @notice minimum reimbursement for matching; targets up to 150_000 gas at 20 Gwei/gas
    uint256 public constant MIN_REIMBURSEMENT = 0.003 ether;

    /// @notice maximum reimbursement for matching; with default BPS value, this is reached at 4 ETH total donations
    uint256 public constant MAX_REIMBURSEMENT = 0.1 ether;

    /// @notice Time limit before an auction ends; requests cannot be removed during this time
    uint16 public constant AUCTION_END_LIMIT = 5 minutes;

    /// @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID except non-auctioned Nouns
    uint16 public constant ANY_ID = 0;

    /// @notice cheaper to store than calculate
    uint16 private constant UINT16_MAX = type(uint16).max;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice A portion of donated funds are sent to the address performing a match
    uint16 public maxReimbursementBPS = 250;

    /// @notice cached values for Noun trait counts via the Nouns Descriptor
    uint16 public backgroundCount;
    uint16 public bodyCount;
    uint16 public accessoryCount;
    uint16 public headCount;
    uint16 public glassesCount;

    /// @notice The minimum donation value; owner can update
    uint256 public minValue = 0.01 ether;

    /// @notice Array of donee details
    Donee[] public _donees;

    /// @notice Cumulative funds for trait parameters send to a specific donee. The first mapping key is the hash of trait enum, traitId, nounId, and the second is doneeId
    mapping(bytes32 => mapping(uint16 => uint256)) public amounts;

    /// @notice Keep track of matched trait parameters using a nonce. When a match is made the nonce is incremented nonce to invalidate request removal. The key is the hash of trait enum, traitId, nounId
    mapping(bytes32 => uint16) public nonces;

    /// @notice Array of requests against the address that created the request
    mapping(address => Request[]) internal _requests;

    constructor(
        INounsTokenLike _nouns,
        INounsAuctionHouseLike _auctionHouse,
        IWETH _weth
    ) {
        nouns = _nouns;
        auctionHouse = _auctionHouse;
        weth = _weth;
        updateTraitCounts();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    //----------------//
    //-----Getters----//
    //----------------//

    function donees() public view returns (Donee[] memory) {
        return _donees;
    }

    /// @notice Get all requests made by an address
    /// @param requester The address of the requester
    /// @return requests An array of Request structs
    function requestsByAddress(address requester)
        public
        view
        returns (Request[] memory requests)
    {
        requests = _requests[requester];
    }

    /// @notice Get a specific request by an address
    /// @param request The address of the requester
    /// @param requestId The ID of the request
    /// @return request The Request struct
    function requestById(address requester, uint256 requestId)
        public
        view
        returns (Request memory request)
    {
        request = _requests[requester][requestId];
    }

    /// @notice Get requests that have not been matched to a Noun or deleted by an address
    /// @param requester The address of the requester
    /// @return requests An array of Requests that have yet to be fulfilled
    function requestsActiveByAddress(address requester)
        public
        view
        returns (Request[] memory requests)
    {
        unchecked {
            uint256 activeRequestCount;
            uint256 requestCount = _requests[requester].length;
            uint256[] memory activeRequestIds = new uint256[](requestCount);

            for (uint256 i; i < requestCount; i++) {
                Request memory request = _requests[requester][i];
                // Request has been deleted
                if (request.amount < 1) continue;
                uint16 nonce = nonceForTraits(
                    request.trait,
                    request.traitId,
                    request.nounId
                );
                // Request has been matched
                if (nonce > request.nonce) continue;
                activeRequestIds[activeRequestCount] = i;
                activeRequestCount++;
            }

            requests = new Request[](activeRequestCount);
            for (uint256 i; i < activeRequestCount; i++) {
                requests[i] = _requests[requester][activeRequestIds[i]];
            }
        }
    }

    /// @notice Get the current nonce for a set of request parameters
    /// @param trait The trait enum
    /// @param traitId The ID of the trait
    /// @param nounId The Noun ID
    /// @return nonce The current nonce
    function nonceForTraits(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint16 nonce) {
        nonce = nonces[traitHash(trait, traitId, nounId)];
    }

    /// @notice Get a set of nonces for request parameters
    /// @dev The length of the `traits` array is used as the returned array length
    /// @param traits Array of trait Enums
    /// @param traitIds Array of trait IDs
    /// @param nounIds Array of Noun IDs
    /// @return noncesList Array of corresponding nonces
    function noncesForTraits(
        Traits[] calldata traits,
        uint16[] calldata traitIds,
        uint16[] calldata nounIds
    ) public view returns (uint16[] memory noncesList) {
        uint256 length = traits.length;
        noncesList = new uint16[](length);
        for (uint256 i; i < length; i++) {
            noncesList[i] = nonceForTraits(traits[i], traitIds[i], nounIds[i]);
        }
    }

    /// @notice The canonical key for requests that target the same `trait`, `traitId`, and `nounId`
    /// @dev Used to (1) group requests by their parameters in the `amounts` mapping and (2)keep track of matched requests in the `nonces` mapping
    /// @param trait The trait enum
    /// @param traitId The ID of the trait
    /// @param nounId The Noun ID
    /// @return hash The hashed value
    function traitHash(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public pure returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(trait, traitId, nounId));
    }

    /// @notice The number of donees
    function doneesCount() public view returns (uint256 length) {
        length = _donees.length;
    }

    //----------------//
    //----Utilities---//
    //----------------//

    /// @notice The amount a given donee will receive (before fees) if a Noun with specific trait parameters is minted
    /// @param trait The trait enum
    /// @param traitId The ID of the trait
    /// @param nounId The Noun ID
    /// @param doneeId The donee ID
    /// @return amount The amount before fees
    function amountForDoneeByTrait(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public view returns (uint256 amount) {
        bytes32 hash = traitHash(trait, traitId, nounId);
        amount = amounts[hash][doneeId];
    }

    /// @notice Given a donation total, derive the reimbursement fee and basis points used to calculate it
    /// @param total A donation amount
    /// @return effectiveBPS The basis point used to cacluate the reimbursement fee
    /// @return reimbursement The reimbursement amount
    function effectiveBPSAndReimbursementForDonationTotal(uint256 total)
        public
        view
        returns (uint256 effectiveBPS, uint256 reimbursement)
    {
        (
            effectiveBPS,
            reimbursement
        ) = _effectiveHighPrecisionBPSForDonationTotal(total);
        effectiveBPS = effectiveBPS / 100;
    }

    /// @notice Evaluate if the provided Request parameters matches the specified Noun
    /// @param requestTrait The trait type to compare the given Noun ID with
    /// @param requestTraitId The ID of the provided trait type to compare the given Noun ID with
    /// @param requestNounId The NounID parameter from a Noun Seek Request (may be ANY_ID)
    /// @param nounId Noun ID to fetch the attributes of to compare against the given request properties
    /// @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
    function requestParamsMatchNounParams(
        Traits requestTrait,
        uint16 requestTraitId,
        uint16 requestNounId,
        uint16 nounId
    ) public view returns (bool) {
        return
            requestMatchesNoun(
                Request({
                    nonce: 0,
                    doneeId: 0,
                    trait: requestTrait,
                    traitId: requestTraitId,
                    nounId: requestNounId,
                    amount: 0
                }),
                nounId
            );
    }

    /// @notice Evaluate if the provided Request matches the specified Noun
    /// @param request The Request to compare
    /// @param nounId Noun ID to fetch the attributes of to compare against the given request properties
    /// @return boolean True if the specified Noun ID has the specified trait and the request Noun ID matches the given NounID
    function requestMatchesNoun(Request memory request, uint16 nounId)
        public
        view
        returns (bool)
    {
        // If a specific Noun Id is part of the request, but is not the target Noun id, can exit
        if (request.nounId != ANY_ID && request.nounId != nounId) {
            return false;
        }

        // No Preference Noun Id can only apply to auctioned Nouns
        if (request.nounId == ANY_ID && _isNonAuctionedNoun(nounId)) {
            return false;
        }

        return request.traitId == _fetchTraitId(request.trait, nounId);
    }

    //-----------------------------------------//
    //---Combine donations across all traits---//
    //-----------------------------------------//

    /// @notice Returns all donations for all traits for a given Noun ID
    /// @dev When passing in a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations
    /// @param nounId The ID of the Noun requests should match
    /// @return donations Total donations for a given Noun ID as a nested arrays in the order trait, traitId, and doneeId.
    /** Example:
     * `donationsForNounId(101)` fetches all donations for the open ID value `ANY_ID` as well as specified donations for Noun ID 101.
     * It returns a nested array where:
     *  - `donations[3][5][2]` is in the total donations for Donee ID 2 if any Noun is minted with a banana head (Trait 3, traitId 5)
     *  - `donations[4][3][1]` is in the total donations for Donee ID 1 if any Noun is minted with black glasses (Trait 4, traitId 3)
     */
    function donationsForNounId(uint16 nounId)
        public
        view
        returns (uint256[][][5] memory donations)
    {
        for (uint256 trait; trait < 5; trait++) {
            uint256 traitCount;
            Traits traitEnum = Traits(trait);
            if (traitEnum == Traits.BACKGROUND) {
                traitCount = backgroundCount;
            } else if (traitEnum == Traits.BODY) {
                traitCount = bodyCount;
            } else if (traitEnum == Traits.ACCESSORY) {
                traitCount = accessoryCount;
            } else if (traitEnum == Traits.HEAD) {
                traitCount = headCount;
            } else if (traitEnum == Traits.GLASSES) {
                traitCount = glassesCount;
            }

            donations[trait] = new uint256[][](traitCount);
            donations[trait] = donationsForNounIdByTrait(traitEnum, nounId);
        }
    }

    function donationsForNextNoun()
        public
        view
        returns (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][][5] memory nextAuctionDonations,
            uint256[][][5] memory nextNonAuctionDonations
        )
    {
        unchecked {
            nextAuctionedId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionedId = UINT16_MAX;

            if (_isNonAuctionedNoun(nextAuctionedId)) {
                nextNonAuctionedId = nextAuctionedId;
                nextAuctionedId++;
            }

            nextAuctionDonations = donationsForNounId(nextAuctionedId);

            if (nextNonAuctionedId < UINT16_MAX) {
                nextNonAuctionDonations = donationsForNounId(
                    nextNonAuctionedId
                );
            }
        }
    }

    function donationsForCurrentNoun()
        public
        view
        returns (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[][5] memory currentAuctionDonations,
            uint256[][5] memory prevNonAuctionDonations
        )
    {
        unchecked {
            currentAuctionedId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionedId = UINT16_MAX;

            uint256 doneesCount_ = _donees.length;

            currentAuctionDonations = _donationsForOnChainNoun({
                nounId: currentAuctionedId,
                processAnyId: true,
                doneesCount_: doneesCount_
            });

            if (_isNonAuctionedNoun(currentAuctionedId - 1)) {
                prevNonAuctionedId = currentAuctionedId - 1;

                prevNonAuctionDonations = _donationsForOnChainNoun({
                    nounId: prevNonAuctionedId,
                    processAnyId: false,
                    doneesCount_: doneesCount_
                });
            }
        }
    }

    function donationsAndReimbursementForPreviousNoun()
        public
        view
        returns (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[][5] memory auctionedNounDonations,
            uint256[][5] memory nonAuctionedNounDonations,
            uint256[5] memory totalDonationsPerTrait,
            uint256[5] memory reimbursementPerTrait
        )
    {
        /*
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun Id | Noun Id
         * --------|-------------------
         *     101 | 99 (*skips 100)
         *     102 | 101, 100 (*includes 100)
         *     103 | 102
         */

        /// The Noun ID of the previous to the current Noun on auction
        auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        /// Setup a parameter to detect if a non-auctioned Noun should  be matched
        nonAuctionedNounId = UINT16_MAX;

        /// If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
        /// Example:
        ///   Current Noun: 101
        ///   Previous Noun: 100
        ///   `auctionedNounId` should be 99
        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }
        // If the previous Noun to the previous auctioned Noun is non-auctioned, set the non-auctioned Noun ID to the preceeding Noun
        /// Example:
        ///   Current Noun: 102
        ///   Previous Noun: 101
        ///   `nonAuctionedNounId` should be 100
        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint256 doneesCount_ = _donees.length;

        auctionedNounDonations = _donationsForOnChainNoun({
            nounId: auctionedNounId,
            processAnyId: true,
            doneesCount_: doneesCount_
        });

        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;

        if (includeNonAuctionedNoun) {
            nonAuctionedNounDonations = _donationsForOnChainNoun({
                nounId: nonAuctionedNounId,
                processAnyId: false,
                doneesCount_: doneesCount_
            });
        }

        for (uint256 trait; trait < 5; trait++) {
            for (uint256 doneeId; doneeId < doneesCount_; doneeId++) {
                uint256 nonAuctionedNounDonation;
                if (includeNonAuctionedNoun) {
                    nonAuctionedNounDonation = nonAuctionedNounDonations[trait][
                        doneeId
                    ];
                }
                totalDonationsPerTrait[trait] +=
                    auctionedNounDonations[trait][doneeId] +
                    nonAuctionedNounDonation;
            }
            (
                ,
                reimbursementPerTrait[trait]
            ) = _effectiveHighPrecisionBPSForDonationTotal(
                totalDonationsPerTrait[trait]
            );
            totalDonationsPerTrait[trait] -= reimbursementPerTrait[trait];
        }
    }

    //------------------------------------------//
    //---Combine Donations for specific trait--//
    //------------------------------------------//

    /// @return donationsByTraitId Total donations for a given Noun and trait keyed by traitId and doneeId. Example: `donationsForNounIdByTrait(3, 25) `queries for all requests that are seeking Head #5 for Noun #25. The value in `donations[5][2]` is the total donations for Donee #3 if Noun #25 had Head #5
    function donationsForNounIdByTrait(Traits trait, uint16 nounId)
        public
        view
        returns (uint256[][] memory donationsByTraitId)
    {
        unchecked {
            uint16 traitCount;
            if (trait == Traits.BACKGROUND) {
                traitCount = backgroundCount;
            } else if (trait == Traits.BODY) {
                traitCount = bodyCount;
            } else if (trait == Traits.ACCESSORY) {
                traitCount = accessoryCount;
            } else if (trait == Traits.HEAD) {
                traitCount = headCount;
            } else if (trait == Traits.GLASSES) {
                traitCount = glassesCount;
            }

            uint256 doneesCount_ = _donees.length;
            donationsByTraitId = new uint256[][](traitCount);

            bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);

            for (uint16 traitId; traitId < traitCount; traitId++) {
                donationsByTraitId[traitId] = _donationsForNounIdWithTraitId(
                    trait,
                    traitId,
                    nounId,
                    processAnyId,
                    doneesCount_
                );
            }
        }
    }

    function donationsForNextNounByTrait(Traits trait)
        public
        view
        returns (
            uint16 nextAuctionedId,
            uint16 nextNonAuctionedId,
            uint256[][] memory nextAuctionDonations,
            uint256[][] memory nextNonAuctionDonations
        )
    {
        unchecked {
            nextAuctionedId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionedId = UINT16_MAX;

            if (_isNonAuctionedNoun(nextAuctionedId)) {
                nextNonAuctionedId = nextAuctionedId;
                nextAuctionedId++;
            }

            nextAuctionDonations = donationsForNounIdByTrait(
                trait,
                nextAuctionedId
            );

            if (nextNonAuctionedId < UINT16_MAX) {
                nextNonAuctionDonations = donationsForNounIdByTrait(
                    trait,
                    nextNonAuctionedId
                );
            }
        }
    }

    function donationsForCurrentNounByTrait(Traits trait)
        public
        view
        returns (
            uint16 currentAuctionedId,
            uint16 prevNonAuctionedId,
            uint256[] memory currentAuctionDonations,
            uint256[] memory prevNonAuctionDonations
        )
    {
        unchecked {
            currentAuctionedId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionedId = UINT16_MAX;

            uint16 currentTraitId;
            uint16 prevTraitId;

            currentTraitId = _fetchTraitId(trait, currentAuctionedId);

            uint256 doneesCount_ = _donees.length;

            currentAuctionDonations = _donationsForNounIdWithTraitId(
                trait,
                currentTraitId,
                currentAuctionedId,
                true,
                doneesCount_
            );

            if (_isNonAuctionedNoun(currentAuctionedId - 1)) {
                prevNonAuctionedId = currentAuctionedId - 1;
                prevTraitId = _fetchTraitId(trait, prevNonAuctionedId);
                prevNonAuctionDonations = _donationsForNounIdWithTraitId(
                    trait,
                    prevTraitId,
                    prevNonAuctionedId,
                    false,
                    doneesCount_
                );
            }
        }
    }

    function donationsAndReimbursementForPreviousNounByTrait(Traits trait)
        public
        view
        returns (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[] memory auctionedNounDonations,
            uint256[] memory nonAuctionedNounDonations,
            uint256 totalDonations,
            uint256 reimbursement
        )
    {
        /*
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun Id | Noun Id
         * --------|-------------------
         *     101 | 99 (*skips 100)
         *     102 | 101, 100 (*includes 100)
         *     103 | 102
         */

        /// The Noun ID of the previous to the current Noun on auction
        auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        /// Setup a parameter to detect if a non-auctioned Noun should  be matched
        nonAuctionedNounId = UINT16_MAX;

        /// If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
        /// Example:
        ///   Current Noun: 101
        ///   Previous Noun: 100
        ///   `auctionedNounId` should be 99
        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }
        // If the previous Noun to the previous auctioned Noun is non-auctioned, set the non-auctioned Noun ID to the preceeding Noun
        /// Example:
        ///   Current Noun: 102
        ///   Previous Noun: 101
        ///   `nonAuctionedNounId` should be 100
        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint256 doneesCount_ = _donees.length;

        auctionedNounDonations = _donationsForNounIdWithTraitId({
            trait: trait,
            traitId: _fetchTraitId(trait, auctionedNounId),
            nounId: auctionedNounId,
            processAnyId: true,
            doneesCount_: doneesCount_
        });

        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;

        if (includeNonAuctionedNoun) {
            nonAuctionedNounDonations = _donationsForNounIdWithTraitId({
                trait: trait,
                traitId: _fetchTraitId(trait, nonAuctionedNounId),
                nounId: nonAuctionedNounId,
                processAnyId: false,
                doneesCount_: doneesCount_
            });
        }

        for (uint256 doneeId; doneeId < doneesCount_; doneeId++) {
            uint256 nonAuctionedNounDonation;
            if (includeNonAuctionedNoun) {
                nonAuctionedNounDonation = nonAuctionedNounDonations[doneeId];
            }
            totalDonations +=
                auctionedNounDonations[doneeId] +
                nonAuctionedNounDonation;
        }
        (, reimbursement) = _effectiveHighPrecisionBPSForDonationTotal(
            totalDonations
        );
        totalDonations -= reimbursement;
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      WRITE FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /// @notice Create a request for the specific trait and specific or open Noun ID payable to the specified Donee. Request amount is tied to the sent value.
    /// @param trait Trait type the request is for (see Traits enum)
    /// @param traitId ID of the specified Trait that the request is for
    /// @param nounId the Noun ID the request is targeted for (or the value of ANY_ID for open requests)
    /// @param doneeId the ID of the Donee that should receive the donation if a Noun matching the parameters is minted
    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        if (!_donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = traitHash(trait, traitId, nounId);
        uint16 nonce = nonces[hash];

        amounts[hash][doneeId] += msg.value;

        requestId = _requests[msg.sender].length;

        _requests[msg.sender].push(
            Request({
                nonce: nonce,
                doneeId: doneeId,
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                amount: uint128(msg.value)
            })
        );

        emit RequestAdded(
            requestId,
            msg.sender,
            trait,
            traitId,
            doneeId,
            nounId,
            msg.value,
            nonce
        );
    }

    /// @notice Remove the specified request and return the associated ETH. Must be called by the requester and before AuctionEndWindow
    function remove(uint256 requestId) public returns (uint256 amount) {
        // Cannot executed within a time period from an auction's end
        if (
            block.timestamp + AUCTION_END_LIMIT >=
            auctionHouse.auction().endTime
        ) {
            revert TooLate();
        }

        Request memory request = _requests[msg.sender][requestId];

        if (request.amount < 1) revert ValueTooLow();

        /* @dev
         * Cannot remove a request if:
         * 1) The current Noun on auction has the requested traits
         * 2) The previous Noun has the requested traits
         * 2b) If the previous Noun is non-auctioned, the previous previous has the requested traits
         * 3) A Non-Auctioned Noun which matches the request.nounId is the previous previous Noun

         * Case # | Example | Ineligible
         *        | Noun Id | Noun Id
         * -------|---------|-------------------
         *    1,3 |     101 | 101, 99 (*skips 100)
         *  1,2,2b|     102 | 102, 101, 100 (*includes 100)
         *    1,2 |     103 | 103, 102
        */
        uint16 nounId = uint16(auctionHouse.auction().nounId);

        // Case 1
        _revertIfRequestMatchesNoun(request, nounId);

        // Case 2
        if (_isAuctionedNoun(nounId - 1)) {
            _revertIfRequestMatchesNoun(request, nounId - 1);
            // Case 2b
            if (_isNonAuctionedNoun(nounId - 2)) {
                _revertIfRequestMatchesNoun(request, nounId - 2);
            }
        } else {
            // Case 3
            _revertIfRequestMatchesNoun(request, nounId - 2);
        }

        delete _requests[msg.sender][requestId];

        bytes32 hash = traitHash(
            request.trait,
            request.traitId,
            request.nounId
        );

        /// Funds can be returned if request has yet to be matched
        amount = nonces[hash] == request.nonce ? request.amount : 0;

        emit RequestRemoved(
            requestId,
            msg.sender,
            request.trait,
            request.traitId,
            request.doneeId,
            request.nounId,
            amount
        );

        if (amount > 0) {
            amounts[hash][request.doneeId] -= amount;
            _safeTransferETHWithFallback(msg.sender, amount);
        }
    }

    /// @notice Match all trait requests for the previous Noun(s).
    /// @dev Matches will made against the previously auctioned Noun using requests that have an open ID (ANY_ID) or specific ID. If immediately preceeding Noun to the previously auctioned Noun is non-auctioned, only specific ID requests will match
    /// @param trait The Trait type to match with the previous Noun (see Traits enum)
    function matchAndDonate(Traits trait)
        public
        returns (uint256 total, uint256 reimbursement)
    {
        /*
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun Id | Noun Id
         * --------|-------------------
         *     101 | 99 (*skips 100)
         *     102 | 101, 100 (*includes 100)
         *     103 | 102
         */
        /// The Noun ID of the previous to the current Noun on auction
        uint16 auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        /// Setup a parameter to detect if a non-auctioned Noun should  be matched
        uint16 nonAuctionedNounId = UINT16_MAX;

        /// If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
        /// Example:
        ///   Current Noun: 101
        ///   Previous Noun: 100
        ///   `auctionedNounId` should be 99
        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }
        // If the previous Noun to the previous auctioned Noun is non-auctioned, set the non-auctioned Noun ID to the preceeding Noun
        /// Example:
        ///   Current Noun: 102
        ///   Previous Noun: 101
        ///   `nonAuctionedNounId` should be 100
        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint16[] memory traitIds = new uint16[](
            nonAuctionedNounId < UINT16_MAX ? 3 : 2
        );
        uint16[] memory nounIds = new uint16[](
            nonAuctionedNounId < UINT16_MAX ? 3 : 2
        );

        nounIds[0] = auctionedNounId;
        nounIds[1] = ANY_ID;
        traitIds[0] = _fetchTraitId(trait, auctionedNounId);
        traitIds[1] = traitIds[0];

        if (nonAuctionedNounId < UINT16_MAX) {
            nounIds[2] = nonAuctionedNounId;
            traitIds[2] = _fetchTraitId(trait, nonAuctionedNounId);
        }

        uint256[] memory donations;
        uint256 doneesCount_ = _donees.length;

        (donations, total) = _combineAmountsAndDelete(
            trait,
            traitIds,
            nounIds,
            uint16(doneesCount_)
        );

        if (total < 1) revert NoMatch();

        (uint256 effectiveBPS, ) = _effectiveHighPrecisionBPSForDonationTotal(
            total
        );

        for (uint256 i; i < doneesCount_; i++) {
            uint256 amount = donations[i];
            if (amount < 1) continue;
            uint256 donation = (amount * (1_000_000 - effectiveBPS)) /
                1_000_000;
            reimbursement += amount - donation;
            donations[i] = donation;
            _safeTransferETHWithFallback(_donees[i].to, donation);
        }
        emit Donated(donations);

        _safeTransferETHWithFallback(msg.sender, reimbursement);
        emit Reimbursed(msg.sender, reimbursement);
    }

    /// @notice Fetch the count of NounsDescriptor traits and update local counts
    function updateTraitCounts() public {
        INounsDescriptorLike descriptor = INounsDescriptorLike(
            nouns.descriptor()
        );

        backgroundCount = uint16(descriptor.backgroundCount());
        bodyCount = uint16(descriptor.bodyCount());
        accessoryCount = uint16(descriptor.accessoryCount());
        headCount = uint16(descriptor.headCount());
        glassesCount = uint16(descriptor.glassesCount());
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      OWNER FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Add a Donee by specifying the name and address funds should be sent to
    /// @dev Adds a Donee to the donees set and activates the Donee
    /// @param name The Donee's name that should be displayed to users/consumers
    /// @param to Address that funds should be sent to in order to fund the Donee
    function addDonee(
        string calldata name,
        address to,
        string calldata description
    ) external onlyOwner {
        uint16 doneeId = uint16(_donees.length);
        _donees.push(Donee({name: name, to: to, active: true}));
        emit DoneeAdded(doneeId, name, to, description);
    }

    /// @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
    /// @param doneeId Donee id based on its index within the donees set
    /// @dev If the Done is not configured, a revert will be triggered
    function toggleDoneeActive(uint256 doneeId) external onlyOwner {
        bool active = !_donees[doneeId].active;
        _donees[doneeId].active = active;
        emit DoneeActiveStatusChanged(doneeId, active);
    }

    function setMinValue(uint256 newMinValue) external onlyOwner {
        minValue = newMinValue;
        emit MinValueChanged(newMinValue);
    }

    function setReimbursementBPS(uint16 newReimbursementBPS)
        external
        onlyOwner
    {
        /// BPS cannot be less than 0.1% or greater than 10%
        if (newReimbursementBPS < 10 || newReimbursementBPS > 1000) revert();
        maxReimbursementBPS = newReimbursementBPS;
        emit ReimbursementBPSChanged(newReimbursementBPS);
    }

    /// @notice Pauses the NounSeek contract. Pausing can be reversed by unpausing.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses (resumes) the NounSeek contract. Unpausing can be reversed by pausing.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */
    /// @notice Was the specified Noun ID not auctioned
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 < 1 && nounId <= 1820;
    }

    /// @notice Was the specified Noun ID auctioned
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 > 0 || nounId > 1820;
    }

    /**
    @notice Retrieves requests with params `trait`, `traitId`, and `nounId` to calculate donation and reimubesement amounts, then removes the requests from storage.
    @param trait The trait type requests should match (see Traits enum)
    @param traitIds Specific trait Id
    @param nounIds Specific Noun Id
    @return donations Mutated donations array
    @return total total
     */
    function _combineAmountsAndDelete(
        Traits trait,
        uint16[] memory traitIds,
        uint16[] memory nounIds,
        uint16 doneesCount_
    ) internal returns (uint256[] memory donations, uint256 total) {
        donations = new uint256[](doneesCount_);

        uint256 nounIdsLength = nounIds.length;

        for (uint16 i; i < nounIdsLength; i++) {
            bytes32 hash = traitHash(trait, traitIds[i], nounIds[i]);
            uint256 traitTotal;
            for (uint16 doneeId; doneeId < doneesCount_; doneeId++) {
                uint256 amount = amounts[hash][doneeId];
                if (amount < 1) continue;
                traitTotal += amount;
                total += amount;
                donations[doneeId] += amount;

                delete amounts[hash][doneeId];
            }

            if (traitTotal < 1) continue;

            nonces[hash]++;

            emit Matched(trait, traitIds[i], nounIds[i], nonces[hash]);
        }
    }

    function _revertIfRequestMatchesNoun(Request memory request, uint16 nounId)
        internal
        view
    {
        if (requestMatchesNoun(request, nounId)) revert MatchFound(nounId);
    }

    function _fetchTraitId(Traits trait, uint16 nounId)
        internal
        view
        returns (uint16 traitId)
    {
        if (trait == Traits.BACKGROUND) {
            traitId = uint16(nouns.seeds(nounId).background);
        } else if (trait == Traits.BODY) {
            traitId = uint16(nouns.seeds(nounId).body);
        } else if (trait == Traits.ACCESSORY) {
            traitId = uint16(nouns.seeds(nounId).accessory);
        } else if (trait == Traits.HEAD) {
            traitId = uint16(nouns.seeds(nounId).head);
        } else if (trait == Traits.GLASSES) {
            traitId = uint16(nouns.seeds(nounId).glasses);
        }
    }

    function _effectiveHighPrecisionBPSForDonationTotal(uint256 total)
        internal
        view
        returns (uint256 effectiveBPS, uint256 reimbursement)
    {
        if (total < 1) return (effectiveBPS, reimbursement);

        /// Add 2 digits extra precision to better derive `effectiveBPS` from total
        /// Extra precision basis point = 10_000 * 100 = 1_000_000
        effectiveBPS = maxReimbursementBPS * 100;
        reimbursement = (total * effectiveBPS) / 1_000_000;

        if (reimbursement > MAX_REIMBURSEMENT) {
            effectiveBPS = (MAX_REIMBURSEMENT * 1_000_000) / total;
            reimbursement = MAX_REIMBURSEMENT;
        } else if (reimbursement < MIN_REIMBURSEMENT) {
            effectiveBPS = (MIN_REIMBURSEMENT * 1_000_000) / total;
            reimbursement = MIN_REIMBURSEMENT;
        }
    }

    function _donationsForNounIdWithTraitId(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        bool processAnyId,
        uint256 doneesCount_
    ) internal view returns (uint256[] memory donations) {
        unchecked {
            bytes32 hash = traitHash(trait, traitId, nounId);
            bytes32 anyIdHash;
            if (processAnyId) anyIdHash = traitHash(trait, traitId, ANY_ID);
            donations = new uint256[](doneesCount_);
            for (uint16 doneeId; doneeId < doneesCount_; doneeId++) {
                uint256 anyIdAmount = processAnyId
                    ? amounts[anyIdHash][doneeId]
                    : 0;
                donations[doneeId] = amounts[hash][doneeId] + anyIdAmount;
            }
        }
    }

    function _donationsForOnChainNoun(
        uint16 nounId,
        bool processAnyId,
        uint256 doneesCount_
    ) internal view returns (uint256[][5] memory donations) {
        INounsSeederLike.Seed memory seed = nouns.seeds(nounId);
        for (uint256 trait; trait < 5; trait++) {
            Traits traitEnum = Traits(trait);
            uint16 traitId;
            if (traitEnum == Traits.BACKGROUND) {
                traitId = uint16(seed.background);
            } else if (traitEnum == Traits.BODY) {
                traitId = uint16(seed.body);
            } else if (traitEnum == Traits.ACCESSORY) {
                traitId = uint16(seed.accessory);
            } else if (traitEnum == Traits.HEAD) {
                traitId = uint16(seed.head);
            } else if (traitEnum == Traits.GLASSES) {
                traitId = uint16(seed.glasses);
            }

            donations[trait] = _donationsForNounIdWithTraitId(
                traitEnum,
                traitId,
                nounId,
                processAnyId,
                doneesCount_
            );
        }
    }

    /// @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            weth.deposit{value: amount}();
            weth.transfer(to, amount);
        }
    }

    /// @notice Transfer ETH and return the success status.
    /// @dev This function only forwards 10,000 gas to the callee.
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 10_000}("");
        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INounsAuctionHouseLike {
    struct Auction {
        uint256 nounId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    function auction() external view returns (Auction memory);

    function settleCurrentAndCreateNewAuction() external;
}

interface INounsSeederLike {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }
}

interface INounsDescriptorLike {
    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

interface INounsTokenLike {
    function descriptor() external view returns (address);

    function seeds(uint256 nounId)
        external
        view
        returns (INounsSeederLike.Seed memory);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
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