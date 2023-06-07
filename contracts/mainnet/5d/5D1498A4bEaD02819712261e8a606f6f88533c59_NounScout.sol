// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Interfaces.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract NounScout is Ownable2Step, Pausable {
    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * ERRORS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Thrown when an attempting to remove a Request within `AUCTION_END_LIMIT` (5 minutes) of auction end.
     */
    error AuctionEndingSoon();

    /**
     * @notice Thrown when an attempting to remove a Request that matches the current or previous Noun
     */
    error MatchFound(uint16 nounId);

    /**
     * @notice Thrown when an attempting to remove a Request that was previously matched (donation was sent)
     */
    error PledgeSent();

    /**
     * @notice Thrown when attempting to remove a Request that was previously removed.
     */
    error AlreadyRemoved();

    /**
     * @notice Thrown when attempting to settle the eligible Noun that has no matching Requests for the specified Trait Type and Trait ID
     */
    error NoMatch();

    /**
     * @notice Thrown when attempting to match an eligible Noun. Can only match a Noun previous to the current on auction
     */
    error IneligibleNounId();
    /**
     * @notice Thrown when an attempting to add a Request that pledges an amount to an inactive Recipient
     */
    error InactiveRecipient();

    /**
     * @notice Thrown when an attempting to add a Request with value below `minValue`
     */
    error ValueTooLow();

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * EVENTS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Emitted when a Request is added
     */
    event RequestAdded(
        uint256 requestId,
        address indexed requester,
        Traits trait,
        uint16 traitId,
        uint16 recipientId,
        uint16 indexed nounId,
        uint16 pledgeGroupId,
        bytes32 indexed traitsHash,
        uint256 amount,
        string message
    );

    /**
     * @notice Emitted when a Request is removed
     */
    event RequestRemoved(
        uint256 requestId,
        address indexed requester,
        Traits trait,
        uint16 traitId,
        uint16 indexed nounId,
        uint16 pledgeGroupId,
        uint16 recipientId,
        bytes32 indexed traitsHash,
        uint256 amount
    );

    /**
     * @notice Emitted when a Recipient is added
     */
    event RecipientAdded(
        uint256 recipientId,
        string name,
        address to,
        string description
    );

    /**
     * @notice Emitted when a Recipient status has changed
     */
    event RecipientActiveStatusChanged(uint256 recipientId, bool active);

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @dev Used to update and/or invalidate Requests stored off-chain for these parameters
     * @param trait Trait Type that matched
     * @param traitId Trait ID that matched
     * @param nounId Noun Id that matched
     * @param traitsHash Hash of trait, traitId, nounId
     */
    event Matched(
        Traits indexed trait,
        uint16 traitId,
        uint16 indexed nounId,
        bytes32 indexed traitsHash
    );

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @param donations The array of amounts indexed by Recipient ID sent to recipients
     */
    event Donated(uint256[] donations);

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @param settler The addressed that performed the settling function
     * @param amount The reimbursement amount
     */
    event Reimbursed(address indexed settler, uint256 amount);

    /**
     * @notice Emitted when the minValue changes
     */
    event MinValueChanged(uint256 newMinValue);

    /**
     * @notice Emitted when the messageValue changes
     */
    event MessageValueChanged(uint256 newMessageValue);

    /**
     * @notice Emitted when the baseReimbursementBPS changes
     */
    event ReimbursementBPSChanged(uint256 newReimbursementBPS);

    /**
     * @notice Emitted when the minReimbursement changes
     */
    event MinReimbursementChanged(uint256 newMinReimbursement);

    /**
     * @notice Emitted when the maxReimbursement changes
     */
    event MaxReimbursementChanged(uint256 newMaxReimbursement);

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * CUSTOM TYPES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Stores pledged value, requested traits, pledge target
     */
    struct Request {
        Traits trait;
        uint16 traitId;
        uint16 recipientId;
        uint16 nounId;
        uint16 pledgeGroupId;
        uint128 amount;
    }

    /**
     * @notice Request with additional `id` and `status` parameters; Returned by `requestsByAddress()`
     */
    struct RequestWithStatus {
        uint256 id;
        Traits trait;
        uint16 traitId;
        uint16 recipientId;
        uint16 nounId;
        uint128 amount;
        RequestStatus status;
    }

    /**
     * @notice Used to track cumlitive amounts for a recipient . `id` is incremented when pledged amounts are sent; See `pledgeGroups` variable and `_combineAmountsAndDelete` function
     */
    struct PledgeGroup {
        uint240 amount;
        uint16 id;
    }

    /**
     * @notice Name, address, and active status where funds can be donated
     */
    struct Recipient {
        string name;
        address to;
        bool active;
    }

    /**
     * @notice Noun traits in the order they appear on the NounSeeder.Seed struct
     */
    enum Traits {
        BACKGROUND,
        BODY,
        ACCESSORY,
        HEAD,
        GLASSES
    }

    /**
     * @notice Removal status types for a Request
     * @dev See { _getRequestStatusAndParams } for calculations
     * A Request can only be removed if `status == CAN_REMOVE`
     */
    enum RequestStatus {
        CAN_REMOVE,
        REMOVED,
        PLEDGE_SENT,
        AUCTION_ENDING_SOON,
        MATCH_FOUND
    }

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * CONSTANTS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Retreives historical mapping of Noun ID -> seed
     * @return nouns contract address
     */
    INounsTokenLike public immutable nouns;

    /**
     * @notice Retreives the current auction data
     * @return auctionHouse contract address
     */
    INounsAuctionHouseLike public immutable auctionHouse;

    /**
     * @notice The address of the WETH contract
     * @return WETH contract address
     */
    IWETH public immutable weth;

    /**
     * @notice Time limit before an auction ends; requests cannot be removed during this time
     * @return Set to 5 minutes
     */
    uint16 public constant AUCTION_END_LIMIT = 5 minutes;

    /**
     * @notice The value of "open auctioned Noun ID" which allows trait matches to be performed against any auctioned Noun ID
     * @return Set to zero (0)
     */
    uint16 public constant ANY_AUCTION_ID = 0;

    /**
     * @notice The value of "open non-auctioned Noun ID" which allows trait matches to be performed against any non-auctioned Noun ID
     * @return Set to one (1)
     */
    uint16 public constant ANY_NON_AUCTION_ID = 1;

    /**
     * @notice used as `null` value for Noun ID
     */
    uint16 private constant UINT16_MAX = type(uint16).max;

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * STORAGE VARIABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice A portion of donated funds are sent to the address performing a match
     * @dev Owner can update
     * @return baseReimbursementBPS
     */
    uint16 public baseReimbursementBPS = 250;

    /**
     * @notice minimum reimbursement for settling
     * @dev The default attempts to cover 10 recipient matches each sent the default minimimum value (150_000 gas at 20 Gwei/gas)
     * Owner can update
     * @return minReimbursement
     */
    uint256 public minReimbursement = 0.003 ether;

    /**
     * @notice maximum reimbursement for settling; with default BPS value, this is reached at 4 ETH total pledges
     * @dev Owner can update
     * @return maxReimbursement
     */
    uint256 public maxReimbursement = 0.1 ether;

    /**
     * @notice The minimum pledged value
     * @dev Owner can update
     * @return minValue
     */
    uint256 public minValue = 0.01 ether;

    /**
     * @notice The cost to register a message
     * @dev Owner can update
     * @return messageValue
     */
    uint256 public messageValue = 10 ether;

    /**
     * @notice Array of Recipient details
     */
    Recipient[] internal _recipients;

    /**
     * @notice the total number of background traits
     * @dev Fetched and cached via `updateTraitCounts()`
     * @return backgroundCount
     */
    uint16 public backgroundCount;

    /**
     * @notice the total number of body traits
     * @dev Fetched and cached via `updateTraitCounts()`
     * @return bodyCount
     */
    uint16 public bodyCount;

    /**
     * @notice the total number of accessory traits
     * @dev Fetched and cached via `updateTraitCounts()`
     * @return accessoryCount
     */
    uint16 public accessoryCount;

    /**
     * @notice the total number of head traits,
     * @dev Ftched and cached via `updateTraitCounts()`
     * @return headCount
     */
    uint16 public headCount;

    /**
     * @notice the total number of glasses traits
     * @dev Fetched and cached via `updateTraitCounts()`
     * @return glassesCount
     */
    uint16 public glassesCount;

    /**
     * @notice Cumulative funds to be sent to a specific recipient scoped to trait type, Trait ID, and  Noun ID.
     * @dev The first mapping key is can be generated with the `traitsHash` function
     * and the second is recipientId.
     * `id` tracks which group of pledges have been sent. When a pledge is sent, the ID is incremented. See `_combineAmountsAndDelete()`
     */
    mapping(bytes32 => mapping(uint16 => PledgeGroup)) public pledgeGroups;

    /**
     * @notice Array of requests against the address that created the request
     */
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

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * VIEW FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    //----------------//
    //-----Getters----//
    //----------------//

    /**
     * @notice All recipients as Recipient structs
     */
    function recipients() public view returns (Recipient[] memory) {
        return _recipients;
    }

    /**
     * @notice Get requests, augemented with status, for non-removed Requests
     * @dev Removes Requests marked as REMOVED, and includes Requests that have been previously matched.
     * Do not rely on array index; use `request.id` to specify a Request when calling `remove()`
     * See { _getRequestStatusAndParams } for calculations
     * @param requester The address of the requester
     * @return requests An array of RequestWithStatus Structs
     */
    function requestsByAddress(
        address requester
    ) public view returns (RequestWithStatus[] memory requests) {
        unchecked {
            uint256 activeRequestCount;
            uint256 requestCount = _requests[requester].length;
            uint256[] memory activeRequestIds = new uint256[](requestCount);
            RequestStatus[] memory requestStatuses = new RequestStatus[](
                requestCount
            );

            for (uint256 i; i < requestCount; i++) {
                Request memory request = _requests[requester][i];
                (RequestStatus status, , ) = _getRequestStatusAndParams(
                    request
                );
                // Request has been deleted
                if (status == RequestStatus.REMOVED) {
                    continue;
                }

                activeRequestIds[activeRequestCount] = i;
                requestStatuses[activeRequestCount] = status;
                activeRequestCount++;
            }

            requests = new RequestWithStatus[](activeRequestCount);
            for (uint256 i; i < activeRequestCount; i++) {
                Request memory request = _requests[requester][
                    activeRequestIds[i]
                ];
                requests[i] = RequestWithStatus({
                    id: activeRequestIds[i],
                    trait: request.trait,
                    traitId: request.traitId,
                    recipientId: request.recipientId,
                    nounId: request.nounId,
                    amount: request.amount,
                    status: requestStatuses[i]
                });
            }
        }
    }

    /**
     * @notice The canonical key for requests that target the same `trait`, `traitId`, and `nounId`
     * @dev Used to group requests by their parameters in the `amounts` mapping
     * @param trait The trait enum
     * @param traitId The ID of the trait
     * @param nounId The Noun ID
     * @return hash The hashed value
     */
    function traitHash(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public pure returns (bytes32 hash) {
        hash = keccak256(abi.encode(trait, traitId, nounId));
    }

    //----------------//
    //----Utilities---//
    //----------------//

    /**
     * @notice Given a pledge total, derive the reimbursement fee and basis points used to calculate it
     * @param total A pledge amount
     * @return effectiveBPS The basis point used to cacluate the reimbursement fee
     * @return reimbursement The reimbursement amount
     */
    function effectiveBPSAndReimbursementForPledgeTotal(
        uint256 total
    ) public view returns (uint256 effectiveBPS, uint256 reimbursement) {
        (
            effectiveBPS,
            reimbursement
        ) = _effectiveHighPrecisionBPSForPledgeTotal(total);
        effectiveBPS = effectiveBPS / 100;
    }

    /**
     * @notice Evaluate if the provided Request matches the specified on-chain Noun
     * @param request The Request to compare
     * @param nounId Noun ID to fetch the seed and compare against the given request parameters
     * @return boolean True if the specified Noun has the specified trait and the request Noun ID matches the given Noun ID
     */
    function requestMatchesNoun(
        Request memory request,
        uint16 nounId
    ) public view returns (bool) {
        // open IDs can't be used as Noun Ids
        if (nounId == ANY_AUCTION_ID || nounId == ANY_NON_AUCTION_ID) {
            revert IneligibleNounId();
        }

        // If a specific Noun ID is part of the request, but is not the target Noun ID, can exit
        if (
            request.nounId != ANY_AUCTION_ID &&
            request.nounId != ANY_NON_AUCTION_ID &&
            request.nounId != nounId
        ) {
            return false;
        }

        // `ANY_AUCTION_ID` can only apply to auctioned Nouns
        if (request.nounId == ANY_AUCTION_ID && _isNonAuctionedNoun(nounId)) {
            return false;
        }

        // `ANY_NON_AUCTION_ID` can only apply to non-auctioned Nouns
        if (request.nounId == ANY_NON_AUCTION_ID && _isAuctionedNoun(nounId)) {
            return false;
        }

        return
            request.traitId == _fetchOnChainNounTraitId(request.trait, nounId);
    }

    /**
     * @notice For a given Noun ID, get cumulative pledge amounts for each Recipient scoped by Trait Type and Trait ID.
     * @dev The pledges array is a nested structure of 3 arrays of Trait Type, Trait ID, and Recipient ID.
     * The length of the first array is 5 (five) representing all Trait Types.
     * The length of the second is dependant on the number of traits for that trait type (e.g. 242 for Trait Type 3 aka heads).
     * The length of the third is dependant on the number of recipients added to this contract.
     * ##### For example:
     * 1) `pledges.length` == 5 representing the five unique Noun Trait Types
     * 2) `pledges[0].length` == 2 representing the two traits possible for a background `cool` (Trait ID 0) and `warm` (Trait ID 1)
     * 3) `pledges[0][0].length` == the size of the number of recipients that have been added to this contract. Each value is the amount that has been pledged to a specific recipient, indexed by its ID, if a Noun is minted with a cool background.
     * ##### Practical use-case
     * Calling `pledgesForNounId(101)` returns cumulative matching pledges for each Trait Type, Trait ID and Recipient ID such that:
     * 1) the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)
     * 2) the value at `pledges[0][1][2]` is in the total amount that has been pledged to Recipient ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)
     * 3) looping through `pledges[0][1]` and summing each item represents the total value pledged for a warm background (pledges[0][1][0] + pledges[0][1][1]  + pledges[0][1][2] + .... = n ETH)
     * @param nounId The ID of the Noun requests should match.
     * @param includeAnyId If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`
     * @param excludeSeeds Filters out pledges for any Trait in the array of Noun Seeds.
     * This is useful when fetching pledges that have not been matched by the previously auctioned Nouns (See `pledgesForUpcomingNoun()` for why that is needed).
     * A special case exists to accomediate `pledgesForUpcomingNoun()`: if `nounId` is not an open ID (ANY_AUCTION_ID, ANY_NON_AUCTION_ID) and `includeAnyId` is true, only open ID pledges will be filtered and specific ID pledges for `nounId` will be included.
     * @return pledges Cumulative amounts pledged for each Recipient, indexed by Trait Type, Trait ID and Recipient ID
     */
    function pledgesForNounId(
        uint16 nounId,
        bool includeAnyId,
        INounsSeederLike.Seed[] memory excludeSeeds
    ) public view returns (uint256[][][5] memory pledges) {
        uint256 excludeLength = excludeSeeds.length;
        uint16[] memory excludeTraitIds = new uint16[](excludeLength);

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

            // Find the specific Trait IDs for the current Trait within the array of Seeds
            for (uint256 i; i < excludeLength; i++) {
                if (traitEnum == Traits.BACKGROUND) {
                    excludeTraitIds[i] = uint16(excludeSeeds[i].background);
                } else if (traitEnum == Traits.BODY) {
                    excludeTraitIds[i] = uint16(excludeSeeds[i].body);
                } else if (traitEnum == Traits.ACCESSORY) {
                    excludeTraitIds[i] = uint16(excludeSeeds[i].accessory);
                } else if (traitEnum == Traits.HEAD) {
                    excludeTraitIds[i] = uint16(excludeSeeds[i].head);
                } else if (traitEnum == Traits.GLASSES) {
                    excludeTraitIds[i] = uint16(excludeSeeds[i].glasses);
                }
            }

            pledges[trait] = new uint256[][](traitCount);
            pledges[trait] = pledgesForNounIdByTrait(
                traitEnum,
                nounId,
                includeAnyId,
                excludeTraitIds
            );
        }
    }

    /**
     * @notice Get cumulative pledge amounts scoped to Noun ID and Trait Type.
     * @dev Example: `pledgesForNounIdByTrait(3, 25)` accumulates all pledged pledges amounts for heads and Noun ID 25.
     * The returned value in `pledges[5][2]` is in the total amount that has been pledged to Recipient ID 2 if Noun ID 25 is minted with a head of Trait ID 5
     * @param trait The trait type to scope requests to (See `Traits` Enum)
     * @param nounId The Noun ID to scope requests to
     * @param includeAnyId If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`
     * @param excludeTraitIds The pledges for any Trait ID in the array will not be added to `pledgesByTraitId`.
     * A special case exists: if `nounId` is not an open ID (ANY_AUCTION_ID, ANY_NON_AUCTION_ID) and `includeAnyId` is true, only open ID pledges will be excluded, while the specific Id pledges for `nounId` will not.
     * Example: If there two pledges for HEAD 7, one with `nounId` set to `ANY_AUCTION_ID` and the other set to the specific Noun Id 99, when calling `pledgesForNounIdByTrait(3, 99, true, [7])` (get HEAD pledges for Noun 99 including open Id pledges), only the specific Noun ID pledge will be returned for HEAD 7  (the open ID pledge will be filtered out).
     * @return pledgesByTraitId Cumulative amounts pledged for each Recipient, indexed by Trait ID and Recipient ID
     */
    function pledgesForNounIdByTrait(
        Traits trait,
        uint16 nounId,
        bool includeAnyId,
        uint16[] memory excludeTraitIds
    ) public view returns (uint256[][] memory pledgesByTraitId) {
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

            uint256 recipientsCount = _recipients.length;
            pledgesByTraitId = new uint256[][](traitCount);

            uint256 excludeLength = excludeTraitIds.length;

            for (uint16 traitId; traitId < traitCount; traitId++) {
                bool exclude;
                for (uint256 i; i < excludeLength; i++) {
                    if (traitId == excludeTraitIds[i]) exclude = true;
                }

                // If a Trait ID in the array matches the current Trait ID...
                if (exclude) {
                    bool isSpecificNounId = nounId != ANY_AUCTION_ID &&
                        nounId != ANY_NON_AUCTION_ID;

                    // If the `nounId` is a specific ID and it should be bundled with an open ID...
                    if (isSpecificNounId && includeAnyId) {
                        // Modify the request to only fetch pledges for the specific ID
                        pledgesByTraitId[traitId] = _pledgesForNounIdByTraitId(
                            trait,
                            traitId,
                            nounId,
                            false,
                            recipientsCount
                        );
                        // Otherwise include an empty set of pledges
                    } else {
                        pledgesByTraitId[traitId] = new uint256[](
                            recipientsCount
                        );
                    }
                    // Otherwise the pledges for this Trait ID should be included
                } else {
                    pledgesByTraitId[traitId] = _pledgesForNounIdByTraitId(
                        trait,
                        traitId,
                        nounId,
                        includeAnyId,
                        recipientsCount
                    );
                }
            }
        }
    }

    /**
     * @notice Get cumulative pledge amounts scoped to Noun ID, Trait Type, and Trait ID
     * @dev Example: `pledgesForNounIdByTraitId(0, 1, 25)` accumulates all pledged pledge amounts for background (Trait Type 0) with Trait ID 1 for Noun ID 25. The value in `pledges[2]` is in the total amount that has been pledged to Recipient ID 2
     * @param trait The trait type to scope requests to (See `Traits` Enum)
     * @param traitId The Trait ID  of the trait to scope requests
     * @param nounId The Noun ID to scope requests to
     * @param includeAnyId If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`
     * @return pledges Cumulative amounts pledged for each Recipient, indexed by Recipient ID
     */
    function pledgesForNounIdByTraitId(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        bool includeAnyId
    ) public view returns (uint256[] memory pledges) {
        return
            _pledgesForNounIdByTraitId(
                trait,
                traitId,
                nounId,
                includeAnyId,
                _recipients.length
            );
    }

    /**
     * @notice For an existing on-chain Noun, use its seed to find matching pledges
     * @dev Example: `noun.seeds(1)` returns a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * Calling `pledgesForOnChainNoun(1)` returns cumulative matching pledges for each trait that matches the seed such that:
     * - `pledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 for Noun ID 1. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2
     * @param nounId Noun ID of an existing on-chain Noun
     * @param includeAnyId If `true`, sums pledges for the specified `nounId` with pledges for `ANY_AUCTION_ID` (or `ANY_NON_AUCTION_ID` depending on the nounId). If `false` returns only the pledges for the specified `nounId`
     * @return pledges Cumulative amounts pledged for each Recipient that matches the on-chain Noun seed indexed by Trait Type and Recipient ID
     */
    function pledgesForOnChainNoun(
        uint16 nounId,
        bool includeAnyId
    ) public view returns (uint256[][5] memory pledges) {
        return _pledgesForOnChainNoun(nounId, includeAnyId, _recipients.length);
    }

    /**
     * @notice Use the next auctioned Noun Id (and non-auctioned Noun Id that may be minted in the same block) to get cumulative pledge amounts for each Recipient scoped by possible Trait Type and Trait ID. Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.
     * @dev See { pledgesForNounId } for detailed documentation of the nested array structure
     * @return nextAuctionId The ID of the next Noun that will be auctioned
     * @return nextNonAuctionId If two Nouns are due to be minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return nextAuctionPledges Total pledges for the next auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID
     * @return nextNonAuctionPledges If two Nouns are due to be minted, this will contain the total pledges for the next non-auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Recipient ID
     */
    function pledgesForUpcomingNoun()
        public
        view
        returns (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][][5] memory nextAuctionPledges,
            uint256[][][5] memory nextNonAuctionPledges
        )
    {
        unchecked {
            uint16 currentAuctionNounId = uint16(auctionHouse.auction().nounId);
            uint16 prevAuctionNounId = currentAuctionNounId - 1;
            nextAuctionId = currentAuctionNounId + 1;
            nextNonAuctionId = UINT16_MAX;

            if (_isNonAuctionedNoun(prevAuctionNounId)) {
                prevAuctionNounId = prevAuctionNounId - 1;
            }
            if (_isNonAuctionedNoun(nextAuctionId)) {
                nextNonAuctionId = nextAuctionId;
                nextAuctionId++;
            }

            // Exclude the Noun Seeds for the current Noun on auction and the previously auctioned Noun.
            // Pledges for these Noun traits have already been matched, and so will not be included in the reporting of open (unmatched) pledges for the upcoming Noun.
            // This does not apply to non-auctioned Noun pledges because non-auctioned Nouns are not consecutive and can only be matched with pledges that specify non-auctioned IDs.
            INounsSeederLike.Seed[]
                memory excludeSeeds = new INounsSeederLike.Seed[](2);
            excludeSeeds[0] = nouns.seeds(currentAuctionNounId);
            excludeSeeds[1] = nouns.seeds(prevAuctionNounId);

            nextAuctionPledges = pledgesForNounId(
                nextAuctionId,
                true,
                excludeSeeds
            );

            if (nextNonAuctionId < UINT16_MAX) {
                nextNonAuctionPledges = pledgesForNounId(
                    nextNonAuctionId,
                    true,
                    new INounsSeederLike.Seed[](0)
                );
            }
        }
    }

    /**
     * @notice For the Noun that is currently on auction (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts pledged for each Recipient using requests that match the Noun's seed.  Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.
     * @dev Example: The Noun on auction has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * Calling `pledgesForNounOnAuction()` returns cumulative matching pledges for each trait that matches the seed such that:
     * - `currentAuctionPledges[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2.
     * If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `prevNonAuctionPledges` would be populated
     * @return currentAuctionId The ID of the Noun that is currently being auctioned
     * @return prevNonAuctionId If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return currentAuctionPledges Total pledges for the current auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID
     * @return prevNonAuctionPledges If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays indexed by Trait Type and Recipient ID
     */
    function pledgesForNounOnAuction()
        public
        view
        returns (
            uint16 currentAuctionId,
            uint16 prevNonAuctionId,
            uint256[][5] memory currentAuctionPledges,
            uint256[][5] memory prevNonAuctionPledges
        )
    {
        unchecked {
            currentAuctionId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionId = UINT16_MAX;

            uint256 recipientsCount = _recipients.length;

            currentAuctionPledges = _pledgesForOnChainNoun({
                nounId: currentAuctionId,
                includeAnyId: true,
                recipientsCount: recipientsCount
            });

            if (_isNonAuctionedNoun(currentAuctionId - 1)) {
                prevNonAuctionId = currentAuctionId - 1;

                prevNonAuctionPledges = _pledgesForOnChainNoun({
                    nounId: prevNonAuctionId,
                    includeAnyId: true,
                    recipientsCount: recipientsCount
                });
            }
        }
    }

    /**
     * @notice For the Noun that is eligible to be settled (and the previous non-auctioned Noun if it was minted at the same time), get cumulative pledge amounts for each Recipient using requests that match the Noun's seed. Returned values are the sum of Open ID requests (`ANY_AUCTION_ID` / `ANY_NON_AUCTION_ID`) and specific ID requests.
     * @dev Example:
     - The Noun that is eligible to match has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * - Calling `pledgesForMatchableNoun()` returns cumulative matching pledges for each trait that matches the seed.
     * - `auctionedNounPledges[0]` returns the cumulative donations amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `pledges[0][2]` is in the total amount that has been pledged to Recipient ID 2.
     * - If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `nonAuctionedNounPledges` would be populated
     *
     * - Cases for eligible matched Nouns:
     *
     * - `Current Noun ID | Eligible Noun ID`
     * - `----------------|-------------------`
     * - `            101 | 99 (*skips 100)`
     * - `            102 | 101, 100 (*includes 100)`
     * - `            103 | 102`
     * @return auctionedNounId The ID of the Noun that is was auctioned
     * @return nonAuctionedNounId If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return auctionedNounPledges Total pledges for the eligible auctioned Noun as a nested arrays in the order Trait Type and Recipient ID
     * @return nonAuctionedNounPledges If two Nouns were minted, this will contain the total pledges for the previous non-auctioned Noun as a nested arrays in the order Trait Type and Recipient ID
     * @return auctionNounTotalReimbursement An array of settler's reimbursement that will be sent if a Trait Type is matched to the auctioned Noun, indexed by Trait Type
     * @return nonAuctionNounTotalReimbursement An array of settler's reimbursement that will be sent if a Trait Type is matched to the non-auctioned Noun, indexed by Trait Type
     */
    function pledgesForMatchableNoun()
        public
        view
        returns (
            uint16 auctionedNounId,
            uint16 nonAuctionedNounId,
            uint256[][5] memory auctionedNounPledges,
            uint256[][5] memory nonAuctionedNounPledges,
            uint256[5] memory auctionNounTotalReimbursement,
            uint256[5] memory nonAuctionNounTotalReimbursement
        )
    {
        // The Noun ID of the previous to the current Noun on auction
        auctionedNounId = uint16(auctionHouse.auction().nounId) - 1;
        // Setup a parameter to detect if a non-auctioned Noun should be matched
        nonAuctionedNounId = UINT16_MAX;

        // If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
        // Example:
        //   Current Noun: 101
        //   Previous Noun: 100
        //   `auctionedNounId` should be 99
        if (_isNonAuctionedNoun(auctionedNounId)) {
            auctionedNounId = auctionedNounId - 1;
        }
        // If the previous Noun to the previous auctioned Noun is non-auctioned, set the non-auctioned Noun ID to the preceeding Noun
        // Example:
        //   Current Noun: 102
        //   Previous Noun: 101
        //   `nonAuctionedNounId` should be 100
        if (_isNonAuctionedNoun(auctionedNounId - 1)) {
            nonAuctionedNounId = auctionedNounId - 1;
        }

        uint256 recipientsCount = _recipients.length;

        auctionedNounPledges = _pledgesForOnChainNoun({
            nounId: auctionedNounId,
            includeAnyId: true,
            recipientsCount: recipientsCount
        });

        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;

        if (includeNonAuctionedNoun) {
            nonAuctionedNounPledges = _pledgesForOnChainNoun({
                nounId: nonAuctionedNounId,
                includeAnyId: true,
                recipientsCount: recipientsCount
            });
        }
        uint256[5] memory auctionedNounPledgesTotal;
        uint256[5] memory nonAuctionedNounPledgesTotal;

        for (uint256 trait; trait < 5; trait++) {
            for (
                uint256 recipientId;
                recipientId < recipientsCount;
                recipientId++
            ) {
                auctionedNounPledgesTotal[trait] += auctionedNounPledges[trait][
                    recipientId
                ];
                if (includeNonAuctionedNoun) {
                    nonAuctionedNounPledgesTotal[
                        trait
                    ] += nonAuctionedNounPledges[trait][recipientId];
                }
            }
            (
                ,
                auctionNounTotalReimbursement[trait]
            ) = _effectiveHighPrecisionBPSForPledgeTotal(
                auctionedNounPledgesTotal[trait]
            );
            (
                ,
                nonAuctionNounTotalReimbursement[trait]
            ) = _effectiveHighPrecisionBPSForPledgeTotal(
                nonAuctionedNounPledgesTotal[trait]
            );
        }
    }

    /**
     * @notice Get all raw Requests (without status, includes deleted Requests)
     * @dev Exists for low-level queries. The function { requestsByAddress } is better in most use-cases
     * @param requester The address of the requester
     * @return requests An array of Request structs
     */
    function rawRequestsByAddress(
        address requester
    ) public view returns (Request[] memory requests) {
        requests = _requests[requester];
    }

    /**
     * @notice Get a specific raw Request (without status, includes deleted Requests)
     * @dev Exists for low-level queries. The function { requestsByAddress } is better in most use-cases
     * @param request The address of the requester
     * @param requestId The ID of the request
     * @return request The Request struct
     */
    function rawRequestById(
        address requester,
        uint256 requestId
    ) public view returns (Request memory request) {
        request = _requests[requester][requestId];
    }

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * WRITE FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Create a request for the specific trait and specific or open Noun ID payable to the specified Recipient.
     * @dev `msg.value` is used as the pledged Request amount
     * @param trait Trait Type the request is for (see `Traits` Enum)
     * @param traitId ID of the specified Trait that the request is for
     * @param nounId the Noun ID the request is targeted for. Can be (1) any specific Noun ID, (2) the value of `ANY_AUCTION_ID` if the pledge can target any auctioned Noun, or (3) the value of `ANY_NON_AUCTION_ID` if the pledge can target any non-auctioned Noun
     * @param recipientId the ID of the Recipient that should receive the pledged amount if a Noun matching the parameters is minted
     * @return requestId The ID of this requests for msg.sender's address
     */
    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 recipientId
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        requestId = _add(trait, traitId, nounId, recipientId, msg.value, "");
    }

    /**
     * @notice Create a request with a logged message for the specific trait and specific or open Noun ID payable to the specified Recipient. `messageValue` is sent immediately to the recipient and cannot be refunded.
     * @dev The message cost is subtracted from `msg.value` and transfered immediately to the specified Recipient.
     * The remaining value is stored as the pledged Request amount.
     * @param trait Trait Type the request is for (see `Traits` Enum)
     * @param traitId ID of the specified Trait that the request is for
     * @param nounId the Noun ID the request is targeted for. Can be (1) any specific Noun ID, (2) the value of `ANY_AUCTION_ID` if the pledge can target any auctioned Noun, or (3) the value of `ANY_NON_AUCTION_ID` if the pledge can target any non-auctioned Noun
     * @param recipientId the ID of the Recipient that should receive the pledge if a Noun matching the parameters is minted
     * @param message The message to log
     * @return requestId The ID of this requests for msg.sender's address
     */
    function addWithMessage(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 recipientId,
        string memory message
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue + messageValue) {
            revert ValueTooLow();
        }

        requestId = _add(
            trait,
            traitId,
            nounId,
            recipientId,
            msg.value - messageValue, // Registered pledged amount that does not include `messageValue`
            message
        );

        // Immediately send `messageValue` to recipient
        _safeTransferETHWithFallback(_recipients[recipientId].to, messageValue);
    }

    /**
     * @notice Remove the specified request and return the associated amount.
     * @dev Must be called by the Requester's address.
     * If the Request has already been settled/donation was sent to the Recipient or the current auction is ending soon, this will revert (See { _getRequestStatusAndParams } for calculations)
     * If the Recipient of the Request is marked as inactive, the funds can be returned immediately
     * @param requestId Request Id
     * @param amount The amount sent to the requester
     */
    function remove(uint256 requestId) public returns (uint256 amount) {
        Request memory request = _requests[msg.sender][requestId];
        RequestStatus status;
        bytes32 hash;
        uint16 nounId;

        (status, hash, nounId) = _getRequestStatusAndParams(request);

        if (status == RequestStatus.CAN_REMOVE) {
            return _remove(request, requestId, hash);
        } else if (status == RequestStatus.PLEDGE_SENT) {
            revert PledgeSent();
        } else if (status == RequestStatus.REMOVED) {
            revert AlreadyRemoved();
        } else if (status == RequestStatus.AUCTION_ENDING_SOON) {
            revert AuctionEndingSoon();
        } else if (status == RequestStatus.MATCH_FOUND) {
            revert MatchFound(nounId);
        } else {
            revert();
        }
    }

    /**
     * @notice Sends pledged amounts to recipients by matching a requested trait to an eligible Noun. A portion of the pledged amount is sent to `msg.sender` to offset the gas costs of settling.
     * @dev
     * - Only eligible Noun Ids are accepted. An eligible Noun Id is for the immediately preceeding auctioned Noun, or non-auctioned Noun if it was minted at the same time.
     * - Specifying a Noun Id for an auctioned Noun will match requests for `ANY_AUCTION_ID` in addition to requests for `nounId`.
     * - Specifying a Noun Id for a non-auctioned Noun will match requests for `ANY_NON_AUCTION_ID` in addition to requests for `nounId`.
     *
     * - Cases for eligible matched Nouns:
     *
     * - `Current Noun ID | Eligible Noun ID`
     * - `----------------|-------------------`
     * - `            101 | 99 (*skips 100), ANY_AUCTION_ID`
     * - `            102 | 101, 100 (*includes 100),  ANY_AUCTION_ID, ANY_NON_AUCTION_ID`
     * - `            103 | 102, ANY_AUCTION_ID`
     * @param trait The Trait Type to fetch from an eligible Noun (see `Traits` Enum)
     * @param matchAuctionedNoun If `true` fetch the trait from the previous auctioned Noun. If `false` fetch the trait from the previous non-auctioned Noun.
     * @param recipientIds An array of recipient IDs that have been pledged an amount if a Noun matches the specified trait.
     * @return total Total donated funds before reimbursement
     * @return reimbursement Reimbursement amount
     */
    function settle(
        Traits trait,
        bool matchAuctionedNoun,
        uint16[] memory recipientIds
    ) public whenNotPaused returns (uint256 total, uint256 reimbursement) {
        // The Noun ID of the previous to the current Noun on auction
        uint16 nounId = uint16(auctionHouse.auction().nounId) - 1;

        if (matchAuctionedNoun) {
            // If the previous Noun is non-auctioned, set the ID to the the preceeding Noun
            // Example:
            //   Current Noun on Auction: 101
            //   `nounId`: 100
            //   `nounId` should be 99
            if (_isNonAuctionedNoun(nounId)) {
                nounId = nounId - 1;
            }
        } else {
            // If the previous Noun is non-auctioned, it's ineligible because it was minted at the same time as the current Noun
            // Example:
            //   Current Noun on Auction: 101
            //   `nounId`: 100
            if (_isNonAuctionedNoun(nounId)) {
                revert IneligibleNounId();
            }

            // Get the previous, previous Noun ID
            nounId = nounId - 1;

            // If this Noun is auctioned, then there is no non-auctioned Noun that can be matched.
            if (_isAuctionedNoun(nounId)) {
                revert IneligibleNounId();
            }
        }

        uint16 traitId = _fetchOnChainNounTraitId(trait, nounId);

        uint256[] memory donations;
        (donations, total) = _combineAmountsAndDelete(
            trait,
            traitId,
            nounId,
            recipientIds,
            matchAuctionedNoun
        );

        if (total < 1) {
            revert NoMatch();
        }

        (uint256 effectiveBPS, ) = _effectiveHighPrecisionBPSForPledgeTotal(
            total
        );

        for (uint256 i; i < _recipients.length; i++) {
            uint256 amount = donations[i];
            if (amount < 1) {
                continue;
            }
            uint256 donation = (amount * (1_000_000 - effectiveBPS)) /
                1_000_000;
            reimbursement += amount - donation;
            donations[i] = donation;
            _safeTransferETHWithFallback(_recipients[i].to, donation);
        }
        emit Donated(donations);

        _safeTransferETHWithFallback(msg.sender, reimbursement);
        emit Reimbursed({settler: msg.sender, amount: reimbursement});
    }

    /**
     * @notice Update local Trait counts based on Noun Descriptor totals
     */
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

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * OWNER FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Add a Recipient by specifying the name and address funds should be sent to
     * @dev Adds a Recipient to the recipients set and activates the Recipient
     * @param name The Recipient's name that should be displayed to users/consumers
     * @param to Address that funds should be sent to in order to fund the Recipient
     */
    function addRecipient(
        string calldata name,
        address to,
        string calldata description
    ) external onlyOwner {
        uint16 recipientId = uint16(_recipients.length);
        _recipients.push(Recipient({name: name, to: to, active: true}));
        emit RecipientAdded({
            recipientId: recipientId,
            name: name,
            to: to,
            description: description
        });
    }

    /**
     * @notice Toggles a Recipient's active state by its index within the set, reverts if Recipient is not configured
     * @param recipientId Recipient id based on its index within the recipients set
     * @param active Active state
     * @dev If the Done is not configured, a revert will be triggered
     */
    function setRecipientActive(
        uint256 recipientId,
        bool active
    ) external onlyOwner {
        if (active == _recipients[recipientId].active) return;
        _recipients[recipientId].active = active;
        emit RecipientActiveStatusChanged({
            recipientId: recipientId,
            active: active
        });
    }

    /**
     * @notice Sets the minium value that can be pledged
     * @param newMinValue new minimum value
     */
    function setMinValue(uint256 newMinValue) external onlyOwner {
        // minimum Request value cannot be less than minimum reimbursement
        if (newMinValue < minReimbursement) revert();
        minValue = newMinValue;
        emit MinValueChanged(newMinValue);
    }

    /**
     * @notice Sets the cost of registering a message
     * @param newMessageValue new message cost
     */
    function setMessageValue(uint256 newMessageValue) external onlyOwner {
        messageValue = newMessageValue;
        emit MessageValueChanged(newMessageValue);
    }

    /**
     * @notice Sets the standard reimbursement basis points
     * @param newReimbursementBPS new basis point value
     */
    function setReimbursementBPS(
        uint16 newReimbursementBPS
    ) external onlyOwner {
        // BPS cannot be less than 0.1% or greater than 10%
        if (newReimbursementBPS < 10 || newReimbursementBPS > 1000) {
            revert();
        }
        baseReimbursementBPS = newReimbursementBPS;
        emit ReimbursementBPSChanged(newReimbursementBPS);
    }

    /**
     * @notice Sets the minium reimbursement amount when settling
     * @param newMinReimbursement new minimum value
     */
    function setMinReimbursement(
        uint256 newMinReimbursement
    ) external onlyOwner {
        // Reimbursement cannot be greater than minimum Request value
        if (newMinReimbursement > minValue) revert();
        // Prevent owner from setting reimbursement too high.
        if (newMinReimbursement > 0.05 ether) revert();
        minReimbursement = newMinReimbursement;
        emit MinReimbursementChanged(newMinReimbursement);
    }

    /**
     * @notice Sets the maximum reimbursement amount when settling
     * @param newMaxReimbursement new maximum value
     */
    function setMaxReimbursement(
        uint256 newMaxReimbursement
    ) external onlyOwner {
        // Prevent owner from setting reimbursement too high.
        if (newMaxReimbursement > 1 ether) revert();
        maxReimbursement = newMaxReimbursement;
        emit MaxReimbursementChanged(newMaxReimbursement);
    }

    /**
     * @notice Pauses the NounScout contract. Pausing can be reversed by unpausing.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses (resumes) the NounScout contract. Unpausing can be reversed by pausing.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets reverse ENS name
     */
    function setENSReverseName(
        address ensReverseResolver,
        string memory name
    ) external onlyOwner {
        ENSReverseResolver(ensReverseResolver).setName(name);
    }

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * INTERNAL WRITE FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Creates a Request
     * @dev logs `RequestAdded`
     */
    function _add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 recipientId,
        uint256 amount,
        string memory message
    ) internal returns (uint256 requestId) {
        if (!_recipients[recipientId].active) {
            revert InactiveRecipient();
        }

        bytes32 hash = traitHash(trait, traitId, nounId);

        PledgeGroup memory pledge = pledgeGroups[hash][recipientId];
        pledge.amount += uint240(amount);
        pledgeGroups[hash][recipientId] = pledge;

        requestId = _requests[msg.sender].length;

        _requests[msg.sender].push(
            Request({
                recipientId: recipientId,
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                pledgeGroupId: pledge.id,
                amount: uint128(amount)
            })
        );

        emit RequestAdded({
            requestId: requestId,
            requester: msg.sender,
            trait: trait,
            traitId: traitId,
            recipientId: recipientId,
            nounId: nounId,
            pledgeGroupId: pledge.id,
            traitsHash: hash,
            amount: amount,
            message: message
        });
    }

    /**
     * @notice Deletes a Request
     * @dev Sends funds
     * Logs `RequestRemoved`
     */
    function _remove(
        Request memory request,
        uint256 requestId,
        bytes32 hash
    ) internal returns (uint256 amount) {
        amount = request.amount;

        delete _requests[msg.sender][requestId];

        emit RequestRemoved({
            requestId: requestId,
            requester: msg.sender,
            trait: request.trait,
            traitId: request.traitId,
            nounId: request.nounId,
            pledgeGroupId: request.pledgeGroupId,
            recipientId: request.recipientId,
            traitsHash: hash,
            amount: amount
        });

        pledgeGroups[hash][request.recipientId].amount -= uint240(amount);
        _safeTransferETHWithFallback(msg.sender, amount);

        return amount;
    }

    /**
     * @notice Retrieves requests with params `trait`, `traitId`, and `nounId` to calculate pledge and reimubersement amounts, sets a new PledgeGroup record with amount set to 0 and pledgeGroupId increased by 1.
     * @param trait The trait type requests should match (see `Traits` Enum)
     * @param traitId Specific Trait ID
     * @param nounId Specific Noun ID
     * @param recipientIds Specific set of recipients
     * @param matchAuctionedNoun If `true` matching Noun is auctioned. If `false` matching Noun is non-auctioned.
     * @return pledges Mutated pledges array
     * @return total total
     */
    function _combineAmountsAndDelete(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16[] memory recipientIds,
        bool matchAuctionedNoun
    ) internal returns (uint256[] memory pledges, uint256 total) {
        // Lookup specific and Open ID requests
        uint16[2] memory nounIds = [
            nounId,
            matchAuctionedNoun ? ANY_AUCTION_ID : ANY_NON_AUCTION_ID
        ];
        pledges = new uint256[](_recipients.length);

        // Loop through `nounIds` (hashing the `nounId`, `trait`, and `traitId`) to then inner loop through `recipientIds` to lookup pledged amounts
        for (uint16 i; i < nounIds.length; i++) {
            bytes32 hash = traitHash(trait, traitId, nounIds[i]);
            uint256 traitTotal;

            for (uint16 j; j < recipientIds.length; j++) {
                // Inactive recipients cannot be sent funds
                if (!_recipients[recipientIds[j]].active) continue;

                PledgeGroup memory pledge = pledgeGroups[hash][recipientIds[j]];

                // Request was previously matched and funds were previously sent to this recipient OR no pledges for this recipient
                if (pledge.amount < 1) {
                    continue;
                }

                traitTotal += pledge.amount;
                total += pledge.amount;
                pledges[recipientIds[j]] += pledge.amount;

                pledgeGroups[hash][recipientIds[j]] = PledgeGroup({
                    id: pledge.id + 1,
                    amount: 0
                });
            }

            if (traitTotal < 1) {
                continue;
            }

            emit Matched({
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                traitsHash: hash
            });
        }
    }

    /** @title
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * INTERNAL READ FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Get cumulative pledge amounts for each Recipient scoped by Noun Id, Trait Type, and Trait Id
     */
    function _pledgesForNounIdByTraitId(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        bool includeAnyId,
        uint256 recipientsCount
    ) internal view returns (uint256[] memory pledges) {
        unchecked {
            bool[] memory isActive = _mapRecipientActive(recipientsCount);

            bytes32 hash = traitHash(trait, traitId, nounId);
            bytes32 anyIdHash;
            bool processAnyId = includeAnyId &&
                nounId != ANY_AUCTION_ID &&
                nounId != ANY_NON_AUCTION_ID;
            if (processAnyId) {
                anyIdHash = traitHash(
                    trait,
                    traitId,
                    _isAuctionedNoun(nounId)
                        ? ANY_AUCTION_ID
                        : ANY_NON_AUCTION_ID
                );
            }
            pledges = new uint256[](recipientsCount);
            for (
                uint16 recipientId;
                recipientId < recipientsCount;
                recipientId++
            ) {
                if (!isActive[recipientId]) continue;
                uint256 anyIdAmount = processAnyId
                    ? pledgeGroups[anyIdHash][recipientId].amount
                    : 0;
                pledges[recipientId] =
                    pledgeGroups[hash][recipientId].amount +
                    anyIdAmount;
            }
        }
    }

    /**
     * @notice For an on-chain Noun, get cumulative pledge amounts that would match its seed
     */
    function _pledgesForOnChainNoun(
        uint16 nounId,
        bool includeAnyId,
        uint256 recipientsCount
    ) internal view returns (uint256[][5] memory pledges) {
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

            pledges[trait] = _pledgesForNounIdByTraitId(
                traitEnum,
                traitId,
                nounId,
                includeAnyId,
                recipientsCount
            );
        }
    }

    /**
     * @notice Generates a RequestStatus based on state of the Request, match data, and auction data
     * @dev RequestStatus calculations:
     * - REMOVED: the request amount is 0
     * - PLEDGE_SENT: A Noun was minted with the Request parameters and has been matched
     * - AUCTION_ENDING_SOON: The auction end time falls within the AUCTION_END_LIMIT
     * - MATCH_FOUND: The current or previous Noun matches the Request parameters
     * - MATCH_FOUND Case 1) The current Noun on auction has the requested traits
     * - MATCH_FOUND Case 2) The previous Noun has the requested traits
     * - MATCH_FOUND Case 2b) If the previous Noun is non-auctioned, the previous previous has the requested traits
     * - MATCH_FOUND: Case 3) A Non-Auctioned Noun which matches the request.nounId is the previous previous Noun

     * ```
     * Case # | Example Noun ID | Ineligible Noun ID
     * -------|---------|-------------------
     *    1,3 |     101 | 101, 99 (*skips 100)
     *  1,2,2b|     102 | 102, 101, 100 (*includes 100)
     *    1,2 |     103 | 103, 102
     * ```
     *
     * - CAN_REMOVE: Recipient is inactive and Request has not been matched
     *   - OR Request has not been matched and auction is not ending
     *   - OR Request has not been matched, auction is not ending, and the current or prevous Noun does not match the Request parameters
    //

     * @param request Request to analyze
     * @return requestStatus RequestStatus Enum
     * @return hash generated trait hash to minimize gas ussage
     * @return nounId
     */
    function _getRequestStatusAndParams(
        Request memory request
    )
        internal
        view
        returns (RequestStatus requestStatus, bytes32 hash, uint16 nounId)
    {
        if (request.amount < 1) {
            return (RequestStatus.REMOVED, hash, nounId);
        }

        hash = traitHash(request.trait, request.traitId, request.nounId);

        if (paused()) {
            return (RequestStatus.CAN_REMOVE, hash, nounId);
        }

        uint16 recipientId = request.recipientId;

        // If current pledgeGroup's ID is different than the ID the request was part of, the pledge has been sent
        bool matched = pledgeGroups[hash][recipientId].id >
            request.pledgeGroupId;

        // Recipient is inactive (and/or was inactive at the time of match) and there are funds to return
        if (!_recipients[recipientId].active && !matched)
            return (RequestStatus.CAN_REMOVE, hash, nounId);

        // Recipient was active at time of match, no funds to return
        if (matched) return (RequestStatus.PLEDGE_SENT, hash, nounId);

        // Cannot executed within a time period from an auction's end
        if (
            block.timestamp + AUCTION_END_LIMIT >=
            auctionHouse.auction().endTime
        ) {
            return (RequestStatus.AUCTION_ENDING_SOON, hash, nounId);
        }

        nounId = uint16(auctionHouse.auction().nounId);

        // Case 1
        if (requestMatchesNoun(request, nounId)) {
            return (RequestStatus.MATCH_FOUND, hash, nounId);
        }

        uint16 prevNounId = nounId - 1;
        uint16 prevPrevNounId = nounId - 2;

        // Case 2
        if (_isAuctionedNoun(prevNounId)) {
            if (requestMatchesNoun(request, prevNounId))
                return (RequestStatus.MATCH_FOUND, hash, prevNounId);
            // Case 2b
            if (_isNonAuctionedNoun(prevPrevNounId)) {
                if (requestMatchesNoun(request, prevPrevNounId))
                    return (RequestStatus.MATCH_FOUND, hash, prevPrevNounId);
            }
        } else {
            // Case 3
            if (requestMatchesNoun(request, prevPrevNounId))
                return (RequestStatus.MATCH_FOUND, hash, prevPrevNounId);
        }
    }

    /**
     * @notice Is the specified Noun ID not eligible to be auctioned
     */
    function _isNonAuctionedNoun(uint256 nounId) internal pure returns (bool) {
        return nounId % 10 < 1 && nounId <= 1820;
    }

    /**
     * @notice Is the specified Noun ID eligible to be auctioned
     */
    function _isAuctionedNoun(uint16 nounId) internal pure returns (bool) {
        return nounId % 10 > 0 || nounId > 1820;
    }

    /**
     * @notice Get the specified on-chain Noun's seed and return the Trait ID for a Trait Type
     */
    function _fetchOnChainNounTraitId(
        Traits trait,
        uint16 nounId
    ) internal view returns (uint16 traitId) {
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

    /**
     * @notice Calculate the reimbursement amount and the basis point value for a total, bound to the maximum and minimum reimbursement amount.
     * @dev Use the `baseReimbursementBPS` to calculate a reimbursement amount.
     * If the amount is above the maximum reimbursement allowed, or below the minimum reimbursement allowed,
     * set the the reimbursement amount to the max or min, and calculate the required basis point value to achieve the reimbursement
     * @param total The total amount reimbursement should be based on
     * @return effectiveBPS The basis point value used to calculate the reimbursement given the total
     * @return reimbursement The amount to reimburse based on the total and effectiveBPS
     */
    function _effectiveHighPrecisionBPSForPledgeTotal(
        uint256 total
    ) internal view returns (uint256 effectiveBPS, uint256 reimbursement) {
        if (total < 1) {
            return (effectiveBPS, reimbursement);
        }

        // Add 2 digits extra precision to better derive `effectiveBPS` from total
        // Extra precision basis point = 10_000 * 100 = 1_000_000
        effectiveBPS = baseReimbursementBPS * 100;
        reimbursement = (total * effectiveBPS) / 1_000_000;

        // When the default reimbursement is above the maximum reimbursement amount
        if (reimbursement > maxReimbursement) {
            // set the reimbursement to the maximum amount and derive the effective basis point value
            effectiveBPS = (maxReimbursement * 1_000_000) / total;
            reimbursement = maxReimbursement;
            // When the default reimbursement is below the minimum reimbursement amount
            // and the total is greater than the minimum reimbursement amount
        } else if (
            reimbursement < minReimbursement && total > minReimbursement
        ) {
            // set the reimbursement to the minimum amount and derive the effective basis point value
            effectiveBPS = (minReimbursement * 1_000_000) / total;
            reimbursement = minReimbursement;
        }
    }

    /**
     * @notice Maps array of Recipients to array of active status booleans
     * @param recipientsCount Cached length of _recipients array
     * @return isActive Array of active status booleans
     */
    function _mapRecipientActive(
        uint256 recipientsCount
    ) internal view returns (bool[] memory isActive) {
        unchecked {
            isActive = new bool[](recipientsCount);
            for (uint256 i; i < recipientsCount; i++) {
                isActive[i] = _recipients[i].active;
            }
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            weth.deposit{value: amount}();
            weth.transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function forwards 10,000 gas to the callee.
     */
    function _safeTransferETH(
        address to,
        uint256 value
    ) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 10_000}("");
        return success;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

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

    function seeds(
        uint256 nounId
    ) external view returns (INounsSeederLike.Seed memory);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

interface ENSReverseResolver {
    function setName(string memory) external returns (bytes32);
}