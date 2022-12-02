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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract NounSeek is Ownable2Step, Pausable {
    /**
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
     * @notice Thrown when an attempting to remove a Request that was previously matched
     */
    error DonationAlreadySent();

    /**
     * @notice Thrown when attempting to remove a Request that was previously removed.
     */
    error AlreadyRemoved();

    /**
     * @notice Thrown when an attempting to match the eligible Noun that has no matching Requests for the specified Trait Type and Trait ID
     */
    error NoMatch();

    /**
     * @notice Thrown when an attempting to add a Request that pledges an amount to an inactive Donee
     */
    error InactiveDonee();

    /**
     * @notice Thrown when an attempting to add a Request with value below `minValue`
     */
    error ValueTooLow();

    /**
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
        uint16 doneeId,
        uint16 indexed nounId,
        bytes32 indexed traitsHash,
        uint256 amount,
        uint16 nonce,
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
        uint16 doneeId,
        bytes32 indexed traitsHash,
        uint256 amount
    );

    /**
     * @notice Emitted when a Donee is added
     */
    event DoneeAdded(
        uint256 doneeId,
        string name,
        address to,
        string description
    );

    /**
     * @notice Emitted when a Donee status has changed
     */
    event DoneeActiveStatusChanged(uint256 doneeId, bool active);

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @dev Used to update and/or invalidate Requests stored off-chain for these parameters
     * @param trait Trait Type that matched
     * @param traitId Trait ID that matched
     * @param nounId Noun Id that matched
     * @param traitsHash Hash of trait, traitId, nounId
     * @param newNonce new incremented nonce; used to invalidated Requests with the prior nonce
     */
    event Matched(
        Traits indexed trait,
        uint16 traitId,
        uint16 indexed nounId,
        bytes32 indexed traitsHash,
        uint16 newNonce
    );

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @param donations The array of amounts indexed by Donee ID sent to donees
     */
    event Donated(uint256[] donations);

    /**
     * @notice Emitted when an eligible Noun matches one or more Requests
     * @param matcher The addressed that performed the matching function
     * @param amount The reimbursement amount
     */
    event Reimbursed(address indexed matcher, uint256 amount);

    /**
     * @notice Emitted when the minValue changes
     */
    event MinValueChanged(uint256 newMinValue);

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

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * CUSTOM TYPES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Stores deposited value, requested traits, donation target, and a nonce for marking stale requests
     */
    struct Request {
        uint16 nonce;
        Traits trait;
        uint16 traitId;
        uint16 doneeId;
        uint16 nounId;
        uint128 amount;
    }

    /**
     * @notice Request with additional `id` and `status` parameters; Returned by `requestsByAddress()`
     */
    struct RequestWithStatus {
        uint256 id;
        uint16 nonce;
        Traits trait;
        uint16 traitId;
        uint16 doneeId;
        uint16 nounId;
        uint128 amount;
        RequestStatus status;
    }

    /**
     * @notice Name, address, and active status where funds can be donated
     */
    struct Donee {
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
        DONATION_SENT,
        AUCTION_ENDING_SOON,
        MATCH_FOUND
    }

    /**
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
     * @notice The value of "open Noun ID" which allows trait matches to be performed against any Noun ID except non-auctioned Nouns
     * @return Set to zero (0)
     */
    uint16 public constant ANY_ID = 0;

    /**
     * @notice cheaper to store than calculate
     */
    uint16 private constant UINT16_MAX = type(uint16).max;

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * STORAGE VARIABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice A portion of donated funds are sent to the address performing a match; owner can update
     * @return baseReimbursementBPS
     */
    uint16 public baseReimbursementBPS = 250;

    /**
     * @notice minimum reimbursement for matching; targets up to 150_000 gas at 20 Gwei/gas; owner can update
     * @return minReimbursement
     */
    uint256 public minReimbursement = 0.003 ether;

    /**
     * @notice maximum reimbursement for matching; with default BPS value, this is reached at 4 ETH total donations; owner can update
     * @return maxReimbursement
     */
    uint256 public maxReimbursement = 0.1 ether;

    /**
     * @notice The minimum donation value; owner can update
     * @return minValue
     */
    uint256 public minValue = 0.01 ether;

    /**
     * @notice Array of Donee details
     */
    Donee[] internal _donees;

    /**
     * @notice the total number of background traits, fetched and cached via `updateTraitCounts()`
     * @return backgroundCount
     */
    uint16 public backgroundCount;

    /**
     * @notice the total number of body traits, fetched and cached via `updateTraitCounts()`
     * @return bodyCount
     */
    uint16 public bodyCount;

    /**
     * @notice the total number of accessory traits, fetched and cached via `updateTraitCounts()`
     * @return accessoryCount
     */
    uint16 public accessoryCount;

    /**
     * @notice the total number of head traits, fetched and cached via `updateTraitCounts()`
     * @return headCount
     */
    uint16 public headCount;

    /**
     * @notice the total number of glasses traits, fetched and cached via `updateTraitCounts()`
     * @return glassesCount
     */
    uint16 public glassesCount;

    /**
     * @notice Cumulative funds for trait parameters send to a specific donee.
     * The first mapping key is can be generated with the `traitsHash` function
     * and the second is doneeId
     */
    mapping(bytes32 => mapping(uint16 => uint256)) public amounts;

    /**
     * @notice Keep track of matched trait parameters using a nonce.
     * When a match is made the nonce is incremented nonce to invalidate
     * request removal. The key can be generated with the `traitsHash` function
     */
    mapping(bytes32 => uint16) public nonces;

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

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * VIEW FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    //----------------//
    //-----Getters----//
    //----------------//

    /**
     * @notice All donees as Donee structs
     */
    function donees() public view returns (Donee[] memory) {
        return _donees;
    }

    /**
     * @notice Get requests, augemented with status, for non-removed Requests
     * @dev Removes Requests marked as REMOVED, and includes Requests that have been previously matched.
     * Do not rely on array index; use `request.id` to specify a Request when calling `remove()`
     * See { _getRequestStatusAndParams } for calculations
     * @param requester The address of the requester
     * @return requests An array of RequestWithStatus Structs
     */
    function requestsByAddress(address requester)
        public
        view
        returns (RequestWithStatus[] memory requests)
    {
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
                    nonce: request.nonce,
                    trait: request.trait,
                    traitId: request.traitId,
                    doneeId: request.doneeId,
                    nounId: request.nounId,
                    amount: request.amount,
                    status: requestStatuses[i]
                });
            }
        }
    }

    /**
     * @notice The canonical key for requests that target the same `trait`, `traitId`, and `nounId`
     * @dev Used to (1) group requests by their parameters in the `amounts` mapping and (2)keep track of matched requests in the `nonces` mapping
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
     * @notice Given a donation total, derive the reimbursement fee and basis points used to calculate it
     * @param total A donation amount
     * @return effectiveBPS The basis point used to cacluate the reimbursement fee
     * @return reimbursement The reimbursement amount
     */
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

    /**
     * @notice Evaluate if the provided Request matches the specified on-chain Noun
     * @param request The Request to compare
     * @param nounId Noun ID to fetch the seed and compare against the given request parameters
     * @return boolean True if the specified Noun has the specified trait and the request Noun ID matches the given Noun ID
     */
    function requestMatchesNoun(Request memory request, uint16 nounId)
        public
        view
        returns (bool)
    {
        // If a specific Noun ID is part of the request, but is not the target Noun id, can exit
        if (request.nounId != ANY_ID && request.nounId != nounId) {
            return false;
        }

        // No Preference Noun ID can only apply to auctioned Nouns
        if (request.nounId == ANY_ID && _isNonAuctionedNoun(nounId)) {
            return false;
        }

        return
            request.traitId == _fetchOnChainNounTraitId(request.trait, nounId);
    }

    /**
     * @notice For a given Noun ID, get cumulative donation amounts for each Donee scoped by Trait Type and Trait ID.
     * @dev The donations array is a nested structure of 3 arrays of Trait Type, Trait ID, and Donee ID.
     * The length of the first array is 5 (five) representing all Trait Types.
     * The length of the second is dependant on the number of traits for that trait type (e.g. 242 for Trait Type 3 aka heads).
     * The length of the third is dependant on the number of donees added to this contract.
     * Example lengths:
     * - `donations[0].length` == 2 representing the two traits possible for a background `cool` (Trait ID 0) and `warm` (Trait ID 1)
     * - `donations[0][0].length` == the size of the number of donees that have been added to this contract. Each value is the amount that has been pledged to a specific donee, indexed by its ID, if a Noun is minted with a cool background.
     * Calling `donationsForNounId(101) returns cumulative matching donations for each Trait Type, Trait ID and Donee ID such that:`
     * - the value at `donations[0][1][2]` is in the total amount that has been pledged to Donee ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)
     * - the value at `donations[0][1][2]` is in the total amount that has been pledged to Donee ID 0 if Noun 101 is minted with a warm background (Trait 0, traitId 1)
     * Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations. E.g. `donationsForNounId(101)` fetches all donations for the open ID value `ANY_ID` as well as specified donations for Noun ID 101.
     * @param nounId The ID of the Noun requests should match.
     * @return donations Cumulative amounts pledged for each Donee, indexed by Trait Type, Trait ID and Donee ID
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

    /**
     * @notice Get cumulative donation amounts scoped to Noun ID and Trait Type.
     * @dev Example: `donationsForNounIdByTrait(3, 25)` accumulates all pledged donations amounts for heads and Noun ID 25.
     * The returned value in `donations[5][2]` is in the total amount that has been pledged to Donee ID 2 if Noun ID 25 is minted with a head of Trait ID 5
     * Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations
     * @param trait The trait type to scope requests to (See `Traits` Enum)
     * @param nounId The Noun ID to scope requests to
     * @return donationsByTraitId Cumulative amounts pledged for each Donee, indexed by Trait ID and Donee ID
     */
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

            uint256 doneesCount = _donees.length;
            donationsByTraitId = new uint256[][](traitCount);

            bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);

            for (uint16 traitId; traitId < traitCount; traitId++) {
                donationsByTraitId[traitId] = _donationsForNounIdByTraitId(
                    trait,
                    traitId,
                    nounId,
                    processAnyId,
                    doneesCount
                );
            }
        }
    }

    /**
     * @notice Get cumulative donation amounts scoped to Noun ID, Trait Type, and Trait ID
     * @dev Example: `donationsForNounIdByTraitId(0, 1, 25)` accumulates all pledged donation amounts for background (Trait Type 0) with Trait ID 1 for Noun ID 25. The value in `donations[2]` is in the total amount that has been pledged to Donee ID 2
     * Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations
     * @param trait The trait type to scope requests to (See `Traits` Enum)
     * @param traitId The trait ID  of the trait to scope requests
     * @param nounId The Noun ID to scope requests to
     * @return donations Cumulative amounts pledged for each Donee, indexed by Donee ID
     */
    function donationsForNounIdByTraitId(
        Traits trait,
        uint16 traitId,
        uint16 nounId
    ) public view returns (uint256[] memory donations) {
        bool processAnyId = nounId != ANY_ID && _isAuctionedNoun(nounId);
        return
            _donationsForNounIdByTraitId(
                trait,
                traitId,
                nounId,
                processAnyId,
                _donees.length
            );
    }

    /**
     * @notice For an existing on-chain Noun, use its seed to find matching donations
     * @dev Example: `noun.seeds(1)` returns a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * Calling `donationsForOnChainNoun(1)` returns cumulative matching donations for each trait that matches the seed such that:
     * - `donations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 for Noun ID 1. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2
     * Note: When accessing a Noun ID for an auctioned Noun, donations for the open ID value `ANY_ID` will be added to total donations
     * @param nounId Noun ID of an existing on-chain Noun
     * @return donations Cumulative amounts pledged for each Donee that matches the on-chain Noun seed indexed by Trait Type and Donee ID
     */
    function donationsForOnChainNoun(uint16 nounId)
        public
        view
        returns (uint256[][5] memory donations)
    {
        return
            _donationsForOnChainNoun(
                nounId,
                _isNonAuctionedNoun(nounId),
                _donees.length
            );
    }

    /**
     * @notice Use the next auctioned Noun Id (and non-auctioned Noun Id that may be minted in the same block) to get cumulative donation amounts for each Donee scoped by possible Trait Type and Trait ID.
     * @dev See { donationsForNounId } for detailed documentation of the nested array structure
     * @return nextAuctionId The ID of the next Noun that will be auctioned
     * @return nextNonAuctionId If two Nouns are due to be minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return nextAuctionDonations Total donations for the next auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Donee ID
     * @return nextNonAuctionDonations If two Nouns are due to be minted, this will contain the total donations for the next non-auctioned Noun as a nested arrays in the order Trait Type, Trait ID, and Donee ID
     */
    function donationsForUpcomingNoun()
        public
        view
        returns (
            uint16 nextAuctionId,
            uint16 nextNonAuctionId,
            uint256[][][5] memory nextAuctionDonations,
            uint256[][][5] memory nextNonAuctionDonations
        )
    {
        unchecked {
            nextAuctionId = uint16(auctionHouse.auction().nounId) + 1;
            nextNonAuctionId = UINT16_MAX;

            if (_isNonAuctionedNoun(nextAuctionId)) {
                nextNonAuctionId = nextAuctionId;
                nextAuctionId++;
            }

            nextAuctionDonations = donationsForNounId(nextAuctionId);

            if (nextNonAuctionId < UINT16_MAX) {
                nextNonAuctionDonations = donationsForNounId(nextNonAuctionId);
            }
        }
    }

    /**
     * @notice For the Noun that is currently on auction (and the previous non-auctioned Noun if it was minted at the same time), get cumulative donation amounts pledged for each Donee using requests that match the Noun's seed.
     * @dev Example: The Noun on auction has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * Calling `donationsForNounOnAuction()` returns cumulative matching donations for each trait that matches the seed such that:
     * - `currentAuctionDonations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2.
     * If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `prevNonAuctionDonations` would be populated
     * @return currentAuctionId The ID of the Noun that is currently being auctioned
     * @return prevNonAuctionId If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return currentAuctionDonations Total donations for the current auctioned Noun as a nested arrays indexed by Trait Type and Donee ID
     * @return prevNonAuctionDonations If two Nouns were minted, this will contain the total donations for the previous non-auctioned Noun as a nested arrays indexed by Trait Type and Donee ID
     */
    function donationsForNounOnAuction()
        public
        view
        returns (
            uint16 currentAuctionId,
            uint16 prevNonAuctionId,
            uint256[][5] memory currentAuctionDonations,
            uint256[][5] memory prevNonAuctionDonations
        )
    {
        unchecked {
            currentAuctionId = uint16(auctionHouse.auction().nounId);
            prevNonAuctionId = UINT16_MAX;

            uint256 doneesCount = _donees.length;

            currentAuctionDonations = _donationsForOnChainNoun({
                nounId: currentAuctionId,
                processAnyId: true,
                doneesCount: doneesCount
            });

            if (_isNonAuctionedNoun(currentAuctionId - 1)) {
                prevNonAuctionId = currentAuctionId - 1;

                prevNonAuctionDonations = _donationsForOnChainNoun({
                    nounId: prevNonAuctionId,
                    processAnyId: false,
                    doneesCount: doneesCount
                });
            }
        }
    }

    /**
     * @notice For the Noun that is eligible to be matched with pledged donations (and the previous non-auctioned Noun if it was minted at the same time), get cumulative donation amounts for each Donee using requests that match the Noun's seed.
     * @dev Example: The Noun that is eligible to match has an ID of 99 and a seed of [1,2,3,4,5] representing background, body, accessory, head, glasses Trait Types and respective Trait IDs.
     * Calling `donationsForMatchableNoun()` returns cumulative matching donations for each trait that matches the seed.
     * `auctionedNounDonations[0]` returns the cumulative doantions amounts for all requests that are seeking background (Trait Type 0) with Trait ID 1 (i.e. the actual background value) for Noun ID 99. The value in `donations[0][2]` is in the total amount that has been pledged to Donee ID 2.
     * If the Noun on auction was ID 101, there would additionally be return values for Noun 100, the non-auctioned Noun minted at the same time and `nonAuctionedNounDonations` would be populated
     * See the documentation in the function body for the cases used to match eligible Nouns
     * @return auctionedNounId The ID of the Noun that is was auctioned
     * @return nonAuctionedNounId If two Nouns were minted, this will be the ID of the non-auctioned Noun, otherwise uint16.max (65,535)
     * @return auctionedNounDonations Total donations for the eligible auctioned Noun as a nested arrays in the order Trait Type and Donee ID
     * @return nonAuctionedNounDonations If two Nouns were minted, this will contain the total donations for the previous non-auctioned Noun as a nested arrays in the order Trait Type and Donee ID
     * @return totalDonationsPerTrait An array of total donation pledged minus reimbursement across all Donees, indexed by Trait Type
     * @return reimbursementPerTrait An array of matcher's reimbursement that will be sent if a Trait Type is matched, indexed by Trait Type
     */
    function donationsForMatchableNoun()
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
        /**
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun ID | Noun ID
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

        uint256 doneesCount = _donees.length;

        auctionedNounDonations = _donationsForOnChainNoun({
            nounId: auctionedNounId,
            processAnyId: true,
            doneesCount: doneesCount
        });

        bool includeNonAuctionedNoun = nonAuctionedNounId < UINT16_MAX;

        if (includeNonAuctionedNoun) {
            nonAuctionedNounDonations = _donationsForOnChainNoun({
                nounId: nonAuctionedNounId,
                processAnyId: false,
                doneesCount: doneesCount
            });
        }

        for (uint256 trait; trait < 5; trait++) {
            for (uint256 doneeId; doneeId < doneesCount; doneeId++) {
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

    /**
     * @notice Get all raw Requests (without status, includes deleted Requests)
     * @dev Exists for low-level queries. The function { requestsByAddress } is better in most use-cases
     * @param requester The address of the requester
     * @return requests An array of Request structs
     */
    function rawRequestsByAddress(address requester)
        public
        view
        returns (Request[] memory requests)
    {
        requests = _requests[requester];
    }

    /**
     * @notice Get a specific raw Request (without status, includes deleted Requests)
     * @dev Exists for low-level queries. The function { requestsByAddress } is better in most use-cases
     * @param request The address of the requester
     * @param requestId The ID of the request
     * @return request The Request struct
     */
    function rawRequestById(address requester, uint256 requestId)
        public
        view
        returns (Request memory request)
    {
        request = _requests[requester][requestId];
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * WRITE FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Create a request for the specific trait and specific or open Noun ID payable to the specified Donee.
     * @dev `msg.value` is used as the pledged Request amount
     * @param trait Trait Type the request is for (see `Traits` Enum)
     * @param traitId ID of the specified Trait that the request is for
     * @param nounId the Noun ID the request is targeted for (or the value of ANY_ID for open requests)
     * @param doneeId the ID of the Donee that should receive the donation if a Noun matching the parameters is minted
     * @return requestId The ID of this requests for msg.sender's address
     */
    function add(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue) {
            revert ValueTooLow();
        }

        requestId = _add(trait, traitId, nounId, doneeId, msg.value, "");
    }

    /**
     * @notice Create a request with a logged message for the specific trait and specific or open Noun ID payable to the specified Donee.
     * @dev The message cost is subtracted from `msg.value` and transfered immediately to the specified Donee.
     * The remaining value is stored as the pledged Request amount request.
     * @param trait Trait Type the request is for (see `Traits` Enum)
     * @param traitId ID of the specified Trait that the request is for
     * @param nounId the Noun ID the request is targeted for (or the value of ANY_ID for open requests)
     * @param doneeId the ID of the Donee that should receive the donation if a Noun matching the parameters is minted
     * @param message The message to log
     * @return requestId The ID of this requests for msg.sender's address
     */
    function addWithMessage(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        uint16 doneeId,
        string memory message
    ) public payable whenNotPaused returns (uint256 requestId) {
        if (msg.value < minValue * 2) {
            revert ValueTooLow();
        }

        requestId = _add(
            trait,
            traitId,
            nounId,
            doneeId,
            msg.value - minValue,
            message
        );

        _safeTransferETHWithFallback(_donees[doneeId].to, minValue);
    }

    /**
     * @notice Remove the specified request and return the associated amount.
     * @dev Must be called by the Requester's address.
     * If the Request has already been matched/sent to the Donee or the current auction is ending soon, this will revert (See { _getRequestStatusAndParams } for calculations)
     * If the Donee of the Request is marked as inactive, the funds can be returned immediately
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
        } else if (status == RequestStatus.DONATION_SENT) {
            revert DonationAlreadySent();
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
     * @notice Match and send all pledged amounts for the previous Noun(s).
     * @dev Matches will made against the previously auctioned Noun using requests that have an open ID (ANY_ID) or specific ID.
     * If immediately preceeding Noun to the previously auctioned Noun is non-auctioned, only specific ID requests will match
     * @param trait The Trait Type to match with the previous Noun (see `Traits` Enum)
     * @return total Total donated funds before reimbursement
     * @return reimbursement Reimbursement amount
     */
    function matchAndDonate(Traits trait)
        public
        returns (uint256 total, uint256 reimbursement)
    {
        /**
         * Cases for eligible matched Nouns:
         *
         * Current | Eligible
         * Noun ID | Noun ID
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
        traitIds[0] = _fetchOnChainNounTraitId(trait, auctionedNounId);
        traitIds[1] = traitIds[0];

        if (nonAuctionedNounId < UINT16_MAX) {
            nounIds[2] = nonAuctionedNounId;
            traitIds[2] = _fetchOnChainNounTraitId(trait, nonAuctionedNounId);
        }

        uint256[] memory donations;
        uint256 doneesCount = _donees.length;

        (donations, total) = _combineAmountsAndDelete(
            trait,
            traitIds,
            nounIds,
            doneesCount
        );

        if (total < 1) {
            revert NoMatch();
        }

        (uint256 effectiveBPS, ) = _effectiveHighPrecisionBPSForDonationTotal(
            total
        );

        for (uint256 i; i < doneesCount; i++) {
            uint256 amount = donations[i];
            if (amount < 1) {
                continue;
            }
            uint256 donation = (amount * (1_000_000 - effectiveBPS)) /
                1_000_000;
            reimbursement += amount - donation;
            donations[i] = donation;
            _safeTransferETHWithFallback(_donees[i].to, donation);
        }
        emit Donated(donations);

        _safeTransferETHWithFallback(msg.sender, reimbursement);
        emit Reimbursed({matcher: msg.sender, amount: reimbursement});
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

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * OWNER FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Add a Donee by specifying the name and address funds should be sent to
     * @dev Adds a Donee to the donees set and activates the Donee
     * @param name The Donee's name that should be displayed to users/consumers
     * @param to Address that funds should be sent to in order to fund the Donee
     */
    function addDonee(
        string calldata name,
        address to,
        string calldata description
    ) external onlyOwner {
        uint16 doneeId = uint16(_donees.length);
        _donees.push(Donee({name: name, to: to, active: true}));
        emit DoneeAdded({
            doneeId: doneeId,
            name: name,
            to: to,
            description: description
        });
    }

    /**
     * @notice Toggles a Donee's active state by its index within the set, reverts if Donee is not configured
     * @param doneeId Donee id based on its index within the donees set
     * @param active Active state
     * @dev If the Done is not configured, a revert will be triggered
     */
    function setDoneeActive(uint256 doneeId, bool active) external onlyOwner {
        if (active == _donees[doneeId].active) return;
        _donees[doneeId].active = active;
        emit DoneeActiveStatusChanged({doneeId: doneeId, active: active});
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
     * @notice Sets the standard reimbursement basis points
     * @param newReimbursementBPS new basis point value
     */
    function setReimbursementBPS(uint16 newReimbursementBPS)
        external
        onlyOwner
    {
        /// BPS cannot be less than 0.1% or greater than 10%
        if (newReimbursementBPS < 10 || newReimbursementBPS > 1000) {
            revert();
        }
        baseReimbursementBPS = newReimbursementBPS;
        emit ReimbursementBPSChanged(newReimbursementBPS);
    }

    /**
     * @notice Sets the minium reimbursement amount when matching
     * @param newMinReimbursement new minimum value
     */
    function setMinReimbursement(uint256 newMinReimbursement)
        external
        onlyOwner
    {
        // Reimbursement cannot be greater than minimum Request value
        if (minReimbursement > minValue) revert();
        minReimbursement = newMinReimbursement;
        emit MinReimbursementChanged(newMinReimbursement);
    }

    /**
     * @notice Sets the maximum reimbursement amount when matching
     * @param newMaxReimbursement new maximum value
     */
    function setMaxReimbursement(uint256 newMaxReimbursement)
        external
        onlyOwner
    {
        maxReimbursement = newMaxReimbursement;
        emit MaxReimbursementChanged(newMaxReimbursement);
    }

    /**
     * @notice Pauses the NounSeek contract. Pausing can be reversed by unpausing.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses (resumes) the NounSeek contract. Unpausing can be reversed by pausing.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
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
        uint16 doneeId,
        uint256 amount,
        string memory message
    ) internal returns (uint256 requestId) {
        if (!_donees[doneeId].active) {
            revert InactiveDonee();
        }

        bytes32 hash = traitHash(trait, traitId, nounId);
        uint16 nonce = nonces[hash];

        amounts[hash][doneeId] += amount;

        requestId = _requests[msg.sender].length;

        _requests[msg.sender].push(
            Request({
                nonce: nonce,
                doneeId: doneeId,
                trait: trait,
                traitId: traitId,
                nounId: nounId,
                amount: uint128(amount)
            })
        );

        emit RequestAdded({
            requestId: requestId,
            requester: msg.sender,
            trait: trait,
            traitId: traitId,
            doneeId: doneeId,
            nounId: nounId,
            traitsHash: hash,
            amount: amount,
            nonce: nonce,
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
            doneeId: request.doneeId,
            traitsHash: hash,
            amount: amount
        });

        amounts[hash][request.doneeId] -= amount;
        _safeTransferETHWithFallback(msg.sender, amount);

        return amount;
    }

    /**
     * @notice Retrieves requests with params `trait`, `traitId`, and `nounId` to calculate donation and reimubesement amounts, then removes the requests from storage.
     * @param trait The trait type requests should match (see `Traits` Enum)
     * @param traitIds Specific trait ID
     * @param nounIds Specific Noun ID
     * @return donations Mutated donations array
     * @return total total
     */
    function _combineAmountsAndDelete(
        Traits trait,
        uint16[] memory traitIds,
        uint16[] memory nounIds,
        uint256 doneesCount
    ) internal returns (uint256[] memory donations, uint256 total) {
        donations = new uint256[](doneesCount);

        // cache Donee active status; we will at lest need to check this once
        bool[] memory isActive = _mapDoneeActive(doneesCount);

        uint256 nounIdsLength = nounIds.length;

        for (uint16 i; i < nounIdsLength; i++) {
            bytes32 hash = traitHash(trait, traitIds[i], nounIds[i]);
            uint256 traitTotal;
            for (uint16 doneeId; doneeId < doneesCount; doneeId++) {
                if (!isActive[doneeId]) continue;

                uint256 amount = amounts[hash][doneeId];
                if (amount < 1) {
                    continue;
                }
                traitTotal += amount;
                total += amount;
                donations[doneeId] += amount;

                delete amounts[hash][doneeId];
            }

            if (traitTotal < 1) {
                continue;
            }

            uint16 newNonce = nonces[hash] + 1;
            nonces[hash] = newNonce;

            emit Matched({
                trait: trait,
                traitId: traitIds[i],
                nounId: nounIds[i],
                traitsHash: hash,
                newNonce: newNonce
            });
        }
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     * INTERNAL READ FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Get cumulative donation amounts for each Donee scoped by Noun Id, Trait Type, and Trait Id
     */
    function _donationsForNounIdByTraitId(
        Traits trait,
        uint16 traitId,
        uint16 nounId,
        bool processAnyId,
        uint256 doneesCount
    ) internal view returns (uint256[] memory donations) {
        unchecked {
            bool[] memory isActive = _mapDoneeActive(doneesCount);

            bytes32 hash = traitHash(trait, traitId, nounId);
            bytes32 anyIdHash;
            if (processAnyId) {
                anyIdHash = traitHash(trait, traitId, ANY_ID);
            }
            donations = new uint256[](doneesCount);
            for (uint16 doneeId; doneeId < doneesCount; doneeId++) {
                if (!isActive[doneeId]) continue;
                uint256 anyIdAmount = processAnyId
                    ? amounts[anyIdHash][doneeId]
                    : 0;
                donations[doneeId] = amounts[hash][doneeId] + anyIdAmount;
            }
        }
    }

    /**
     * @notice For an on-chain Noun, get cumulative donation amounts that would match its seed
     */
    function _donationsForOnChainNoun(
        uint16 nounId,
        bool processAnyId,
        uint256 doneesCount
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

            donations[trait] = _donationsForNounIdByTraitId(
                traitEnum,
                traitId,
                nounId,
                processAnyId,
                doneesCount
            );
        }
    }

    /**
     * @notice Generates a RequestStatus based on state of the Request, match data, and auction data
     * @dev RequestStatus calculations:
     * - REMOVED: the request amount is 0
     * - DONATION_SENT: A Noun was minted with the Request parameters and has been matched
     * - AUCTION_ENDING_SOON: The auction end time falls within the AUCTION_END_LIMIT
     * - MATCH_FOUND: The current or previous Noun matches the Request parameters
     * - CAN_REMOVE: Donee is inactive and Request has not been matched
     *  OR Request has not been matched and auction is not ending
     *  OR Request has not been matched, auction is not ending, and the current or prevous Noun does not match the Request parameters
     * @param request Request to analyze
     * @return requestStatus RequestStatus Enum
     * @return hash generated trait hash to minimize gas ussage
     * @return nounId
     */
    function _getRequestStatusAndParams(Request memory request)
        internal
        view
        returns (
            RequestStatus requestStatus,
            bytes32 hash,
            uint16 nounId
        )
    {
        if (request.amount < 1) {
            return (RequestStatus.REMOVED, hash, nounId);
        }

        hash = traitHash(request.trait, request.traitId, request.nounId);

        uint16 doneeId = request.doneeId;

        // If there is no amount available, a Noun was matched and donations for this Donee were sent
        bool matched = amounts[hash][doneeId] < 1;

        // Donee is inactive (and/or was inactive at the time of match) and there are funds to return
        if (!_donees[doneeId].active && !matched)
            return (RequestStatus.CAN_REMOVE, hash, nounId);

        // Donee was active at time of match, no funds to return
        if (matched) return (RequestStatus.DONATION_SENT, hash, nounId);

        // Cannot executed within a time period from an auction's end
        if (
            block.timestamp + AUCTION_END_LIMIT >=
            auctionHouse.auction().endTime
        ) {
            return (RequestStatus.AUCTION_ENDING_SOON, hash, nounId);
        }

        nounId = uint16(auctionHouse.auction().nounId);

        /**
         * A request cannot be removed if:
         * 1) The current Noun on auction has the requested traits
         * 2) The previous Noun has the requested traits
         * 2b) If the previous Noun is non-auctioned, the previous previous has the requested traits
         * 3) A Non-Auctioned Noun which matches the request.nounId is the previous previous Noun

         * Case # | Example | Ineligible
         *        | Noun ID | Noun ID
         * -------|---------|-------------------
         *    1,3 |     101 | 101, 99 (*skips 100)
         *  1,2,2b|     102 | 102, 101, 100 (*includes 100)
         *    1,2 |     103 | 103, 102
        */
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
    function _fetchOnChainNounTraitId(Traits trait, uint16 nounId)
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

    /**
     * @notice Calculate the reimbursement amount and the basis point value for a total, bound to the maximum and minimum reimbursement amount.
     * @dev Use the `baseReimbursementBPS` to calculate a reimbursement amount.
     * If the amount is above the maximum reimbursement allowed, or below the minimum reimbursement allowed,
     * set the the reimbursement amount to the max or min, and calculate the required basis point value to achieve the reimbursement
     * @param total The total amount reimbursement should be based on
     * @return effectiveBPS The basis point value used to calculate the reimbursement given the total
     * @return reimbursement The amount to reimburse based on the total and effectiveBPS
     */
    function _effectiveHighPrecisionBPSForDonationTotal(uint256 total)
        internal
        view
        returns (uint256 effectiveBPS, uint256 reimbursement)
    {
        if (total < 1) {
            return (effectiveBPS, reimbursement);
        }

        /// Add 2 digits extra precision to better derive `effectiveBPS` from total
        /// Extra precision basis point = 10_000 * 100 = 1_000_000
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
     * @notice Maps array of Donees to array of active status booleans
     * @param doneesCount Cached length of _donees array
     * @return isActive Array of active status booleans
     */
    function _mapDoneeActive(uint256 doneesCount)
        internal
        view
        returns (bool[] memory isActive)
    {
        unchecked {
            isActive = new bool[](doneesCount);
            for (uint256 i; i < doneesCount; i++) {
                isActive[i] = _donees[i].active;
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
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 10_000}("");
        return success;
    }
}