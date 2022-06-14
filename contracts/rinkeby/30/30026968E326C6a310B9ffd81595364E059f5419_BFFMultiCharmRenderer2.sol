// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721MembershipOwnerChecker} from "./IERC721MembershipOwnerChecker.sol";
import {BFFSingleCharmRenderer} from "./BFFSingleCharmRenderer.sol";


/// This is a custom renderer that returns "charms" on a BFF bracelet
/// This current implementation supports up to 7 different charms
contract BFFMultiCharmRenderer2 is IERC721MembershipOwnerChecker {
    address public bffBraceletContract;
    BFFSingleCharmRenderer private singleCharmRenderer;

    // Metadata URIs for charms.
    //mapping(uint256 => string) public charmPermutationIdToUri;

    // This contract only supports up to 7 charms per bracelet
    // Mapping of a Bracelet's TokenID to its charm statuses, represented as an array of booleans
    // The position of the boolean in the array directly corresponds to which charm it is representing
    // An array such as [0,0,0,0,1,0] would represent a bracelet that has Charms #1 and #6 attached to it.
    // Charm #0's state is stored in the SingleCharmRenderer dependency contract and should be read directly from there.
    mapping(uint256 => bool[6]) private tokenIdToCharmStatuses;

    // The total permutations of possible charms on a bracelet is 2^n where n is the number of charms
    // since this contract supports 7 charms, there are a total of 128 different versions to render
    // This array holds a different uri for each permutation
    // The permutaton's array index is equal to the bitmap representation of its charm statuses
    string[128] public charmUris;

    event TokenURIUpdated(string uri, uint256 charmPermutationId);

    /// Constructor to initialize the charm renderer
    /// @param _bffBraceletContract Address of the BFF Bracelet contract. This
    /// is used for owner-related tasks
    /// @param _singleCharmRendererContract Address of the Single Charm renderer address. This
    /// is used to read status state for the very first charm that was added to the bracelet.
    constructor(address _bffBraceletContract, address _singleCharmRendererContract) {
        bffBraceletContract = _bffBraceletContract;
        singleCharmRenderer = BFFSingleCharmRenderer(_singleCharmRendererContract);
    }

    /// Updates token URI - only available to owner
    /// @param uri URI to use for a given charm status
    /// @param charmPermutationId The ID of the charm permutation to set
    function updateTokenURI(string memory uri, uint256 charmPermutationId)
        external
        onlyMembershipOwner(bffBraceletContract)
    {
        charmUris[charmPermutationId] = uri;
        emit TokenURIUpdated(uri, charmPermutationId);
    }

    /// Gets token URI for a given BFF Bracelet ID
    /// @return URI of a given bracelet based on the charm status
    function tokenURI(uint256 bffBraceletId)
        external
        view
        returns (string memory)
    {
        uint256 charmPermutationId = getCharmPermutationIdFromCharmStatuses(bffBraceletId);
        return charmUris[charmPermutationId];
    }

    /// Add a charm to one or more bracelets
    /// @param bffBraceletIds The IDs of the BFF bracelets to add a charm to
    /// @dev addCharm and removeCharm are separate to avoid needing to pass in
    /// an array of booleans representing the charm status (which would increase
    /// gas usage)
    function addCharms(uint256[] calldata bffBraceletIds, uint256 charmId)
        external
        onlyMembershipOwner(bffBraceletContract) {
        require(charmId > 0, "CharmID 0 is handled in the SingleCharmRenderer contract, cannot be set here.");

        // charmId's index in the array
        uint256 charmIdIndex = charmId - 1;

        // This for loop cannot realistically overflow due to the array length
        // (it would run out of gas before that point)
        unchecked {
            for (uint256 i = 0; i < bffBraceletIds.length; i++) {
                tokenIdToCharmStatuses[bffBraceletIds[i]][charmIdIndex] = true;
            }
        }
    }

    /// Add one or more charms to one or bracelets
    /// @param bffBraceletIds The IDs of the BFF bracelets to add a charm to
    /// @dev addCharm and removeCharm are separate to avoid needing to pass in
    /// an array of booleans representing the charm status (which would increase
    /// gas usage)
    function addMultipleCharms(uint256[] calldata bffBraceletIds, uint256[] calldata charmIds)
        external
        onlyMembershipOwner(bffBraceletContract) {
        // This for loop cannot realistically overflow due to the array length
        // (it would run out of gas before that point)
        unchecked {
            for (uint256 i = 0; i < bffBraceletIds.length; i++) {
                for (uint256 j = 0; j < charmIds.length; j++) {
                    require(charmIds[j] > 0, "CharmID 0 is handled in the SingleCharmRenderer contract, cannot be set here.");

                    // charmId's index in the array
                    uint256 charmIdIndex = charmIds[j] - 1;
                    tokenIdToCharmStatuses[bffBraceletIds[i]][charmIdIndex] = true;
                }
            }
        }
    }


    function removeCharms(uint256[] calldata bffBraceletIds, uint256 charmId)
        external
        onlyMembershipOwner(bffBraceletContract) {
        require(charmId > 0, "CharmID 0 is handled in the SingleCharmRenderer contract, cannot be set here.");
        // charmId's index in the array
        uint256 charmIdIndex = charmId - 1;

        // This for loop cannot realistically overflow due to the array length
        // (it would run out of gas before that point)
        unchecked {
            for (uint256 i = 0; i < bffBraceletIds.length; i++) {
                tokenIdToCharmStatuses[bffBraceletIds[i]][charmIdIndex] = false;
            }
        }
    }

    // Convert array of booleans representing binary to an integer value
    function bitmapToUint(bool[6] memory bitmap) internal pure returns (uint256) {
        uint256 n = 0;

        for (uint256 i = bitmap.length; i > 0; i--) {
            n *= 2;
            // using i-1 to avoid uint underflow error
            if (bitmap[i-1] == true) {
                n += 1;
            }
        }

        return n;
    }

    function getCharmPermutationIdFromCharmStatuses(uint bffBraceletId) internal view returns (uint256) {
        uint256 charmPermutationId = bitmapToUint(tokenIdToCharmStatuses[bffBraceletId]);
        // Incorporate the charm status from the Single Charm Renderer contract into the bitmap conversion

        charmPermutationId *= 2;
        if (singleCharmRenderer.checkCharmStatus(bffBraceletId)) {
            charmPermutationId += 1;
        }
        return charmPermutationId;
    }

    function getCharmStatusByIdForBracelet(uint256 bffBraceletId, uint256 charmId) public view returns (bool) {
        if (charmId == 0) {
            return singleCharmRenderer.checkCharmStatus(bffBraceletId);
        }
        uint256 charmIdIndex = charmId - 1;
        return tokenIdToCharmStatuses[bffBraceletId][charmIdIndex];
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// Mixin can be used by any module that needs to check if an address is the
/// owner of the ERC721 Membership.
abstract contract IERC721MembershipOwnerChecker {
    /// Only proceed if msg.sender is membership owner
    /// @param membership membership to update
    modifier onlyMembershipOwner(address membership) {
        _onlyMembershipOwner(membership);
        _;
    }

    function _onlyMembershipOwner(address membership) internal view {
        require(
            msg.sender == Ownable(membership).owner(),
            "IERC721MembershipOwnerChecker: Caller not membership owner"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721MembershipOwnerChecker} from "./IERC721MembershipOwnerChecker.sol";

/// @dev A simple interface to grab the token redemption status from the BFF
/// Phase 1 contract
interface BFFPhase1TokenRedeemed {
    function tokenRedeemed(uint256 tokenId) external view returns (bool);
}

/// This is a custom renderer that returns a "charm" on a BFF bracelet
/// If the bracelet minted a You PFP (defined by the Phase 1 contract or the
/// owner), the charm returns as true
/// If the bracelet minted has not minted a You PFP, the charm returns as false
contract BFFSingleCharmRenderer is IERC721MembershipOwnerChecker {
    address public bffBraceletContract;
    address public bffPhase1Contract;
    BFFPhase1TokenRedeemed public bffPhase1TokenRedeemedStatus;

    // Metadata URIs for both false and true charms. False is the default URI
    mapping(bool => string) public uriCharm;

    // Mapping of BFF bracelet ID to charm status set by owner
    // Note that the owner cannot override the Phase 1 contract's charm status.
    // If the Phase 1 charm status is true, the bracelet's charm status will
    // always be true (i.e. a bracelet cannot be demoted to remove a charm)
    mapping(uint256 => bool) public charmStatus;

    event TokenURIUpdated(string uri, bool uriCharmStatus);

    /// Constructor to initialize the charm renderer
    /// @param bffBraceletContract_ Address of the BFF Bracelet contract. This
    /// is used for owner-related tasks
    /// @param bffPhase1Contract_ Address of the BFF Mint Module Phase 1
    /// contract. This is used for checking the token redemption status
    constructor(address bffBraceletContract_, address bffPhase1Contract_) {
        bffBraceletContract = bffBraceletContract_;
        bffPhase1Contract = bffPhase1Contract_;
        bffPhase1TokenRedeemedStatus = BFFPhase1TokenRedeemed(
            bffPhase1Contract_
        );
    }

    /// Updates token URI - only available to owner
    /// @param uri URI to use for a given charm status
    /// @param uriCharmStatus The charm statu URI to update
    function updateTokenURI(string memory uri, bool uriCharmStatus)
        external
        onlyMembershipOwner(bffBraceletContract)
    {
        uriCharm[uriCharmStatus] = uri;
        emit TokenURIUpdated(uri, uriCharmStatus);
    }

    /// Gets token URI for a given BFF Bracelet ID
    /// @return URI of a given bracelet based on the charm status
    function tokenURI(uint256 bffBraceletId)
        external
        view
        returns (string memory)
    {
        return uriCharm[checkCharmStatus(bffBraceletId)];
    }

    /// Add a charm to a bracelet
    /// @param bffBraceletIds The IDs of the BFF bracelets to add a charm to
    /// @dev addCharm and removeCharm are separate to avoid needing to pass in
    /// an array of booleans representing the charm status (which would increase
    /// gas usage)
    function addCharms(uint256[] calldata bffBraceletIds)
        external
        onlyMembershipOwner(bffBraceletContract)
    {
        // This for loop cannot realistically overflow due to the array length
        // (it would run out of gas before that point)
        unchecked {
            for (uint256 i = 0; i < bffBraceletIds.length; i++) {
                charmStatus[bffBraceletIds[i]] = true;
            }
        }
    }

    /// Remove a charm from a bracelet
    /// @param bffBraceletIds The IDs of the BFF bracelets to remove a charm from
    function removeCharms(uint256[] calldata bffBraceletIds)
        external
        onlyMembershipOwner(bffBraceletContract)
    {
        // This for loop cannot realistically overflow due to the array length
        // (it would run out of gas before that point)
        unchecked {
            for (uint256 i = 0; i < bffBraceletIds.length; i++) {
                charmStatus[bffBraceletIds[i]] = false;
            }
        }
    }

    /// Check whether a charm is present for a given bracelet
    /// @param bffBraceletId The ID of the BFF bracelet to check
    function checkCharmStatus(uint256 bffBraceletId)
        public
        view
        returns (bool)
    {
        if (
            bffPhase1TokenRedeemedStatus.tokenRedeemed(bffBraceletId) ||
            charmStatus[bffBraceletId]
        ) {
            return true;
        } else {
            return false;
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