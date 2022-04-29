// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import {Ownable} from "./lib/Ownable.sol";
import {IGouda} from "./lib/interfaces.sol";
import {IMadMouse} from "./lib/interfaces.sol";

import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

error AuctionOngoing();
error AuctionInactive();
error AuctionCancelled();

error ContractCallNotAllowed();

error InvalidTimestamp();
error BidTooLow();
error NoBidPlaced();
error CannotWithdrawWinningBid();
error IncorrectWinner();
error RequirementNotFulfilled();

error QualifierMaxEntrantsReached();
error QualifierInactive();
error QualifierSeedNotSet();
error QualifierNotEntered();
error QualifierAlreadyEntered();
error QualifierNotRequired();
error QualifierRevealInvalidTimeFrame();
error QualifierRandomSeedSet();

contract AuctionHouse is Ownable {
    event BidPlaced(uint256 indexed auctionId, address sender, uint256 price);

    struct Auction {
        uint16 qualifierNumEntrants;
        uint16 qualifierMaxEntrants;
        uint40 qualifierDuration;
        uint16 qualifierChance;
        uint16 qualifierRandomSeed;
        uint8 requirement;
        uint40 start;
        uint40 duration;
        uint40 currentBid; // in multiples of 1e18
        bool cancelled;
        address prizeNFT;
        uint40 prizeTokenId;
    }

    uint256 public numAuctions;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    IGouda constant gouda = IGouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    IMadMouse constant genesis = IMadMouse(0x3aD30c5e2985e960E89F4a28eFc91BA73e104b77);
    IMadMouse constant troupe = IMadMouse(0x74d9d90a7fc261FBe92eD47B606b6E0E00d75E70);

    uint256 constant ONE_MONTH = 3600 * 24 * 7 * 4;
    uint256 constant AUCTION_EXTEND_DURATION = 5 * 60;

    /* ------------- External ------------- */

    function placeBid(
        uint256 auctionId,
        uint40 bid,
        uint256 requirementData
    ) external noContract {
        Auction storage auction = auctions[auctionId];

        if (bid <= auction.currentBid) revert BidTooLow();

        uint256 qualifierDuration = auction.qualifierDuration;

        unchecked {
            uint256 start = uint256(auction.start) + auction.qualifierDuration;
            uint256 duration = auction.duration;

            if (duration < block.timestamp - start) revert AuctionInactive();

            uint256 end = start + duration;
            if (end - block.timestamp < AUCTION_EXTEND_DURATION) {
                auction.duration = uint40(duration + AUCTION_EXTEND_DURATION);
            }
        }

        if (auction.cancelled) revert AuctionCancelled();

        uint256 callerBid = bids[auctionId][msg.sender];

        // if callerBid is > qualifierDownpayment,
        // we don't have to re-evaluate qualifications,
        // since this check has already been performed
        if (callerBid <= 1) {
            uint256 requirement = auction.requirement;
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            if (qualifierDuration != 0) {
                uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
                if (qualifierRandomSeed == 0) revert QualifierSeedNotSet();
                if (callerBid == 0) revert QualifierNotEntered(); // non-zero for valid entry because of downpayment when entering qualifier
                uint256 roll = uint256(keccak256(abi.encodePacked(msg.sender, qualifierRandomSeed)));
                if (roll & 0xFFFF > auction.qualifierChance) revert QualifierNotEntered();
            }
        }

        unchecked {
            // type(uint40).max * 1e18 < 2^256: can't overflow
            // underflow assumption: callerBid <= auction.currentBid < bid
            gouda.burnFrom(msg.sender, (uint256(bid) - callerBid) * 1e18);
            emit BidPlaced(auctionId, msg.sender, uint256(bid) * 1e18);
        }

        bids[auctionId][msg.sender] = bid;
        auction.currentBid = bid;
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            else if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            else if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            else if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            else if (
                requirement == 5 &&
                (
                    data > 5000
                        ? genesis.getLevel(data - 5000) > 2 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 2 && troupe.ownerOf(data) == user
                )
            ) return true;
            return false;
        }
    }

    function claimPrize(uint256 auctionId) external noContract {
        resolveBid(auctionId);
    }

    function reclaimGouda(uint256 auctionId) external noContract {
        resolveBid(auctionId);
    }

    function enterQualifier(uint256 auctionId, uint256 requirementData) external noContract {
        Auction storage auction = auctions[auctionId];
        unchecked {
            if (++auction.qualifierNumEntrants > auction.qualifierMaxEntrants) revert QualifierMaxEntrantsReached();
            if (auction.qualifierDuration < block.timestamp - auction.start) revert QualifierInactive();
        }

        uint256 requirement = auction.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        if (bids[auctionId][msg.sender] >= 1) revert QualifierAlreadyEntered();

        gouda.burnFrom(msg.sender, 1e18);
        bids[auctionId][msg.sender] = 1;
    }

    /* ------------- View ------------- */

    function qualifierChosen(uint256 auctionId, address user) external view returns (bool) {
        Auction storage auction = auctions[auctionId];

        if (auction.duration == 0) return false; // no qualifier required

        uint256 callerBid = bids[auctionId][user];
        if (callerBid == 0) return false; // downpayment signals successful qualifier entry

        uint256 qualifierRandomSeed = auction.qualifierRandomSeed;
        if (qualifierRandomSeed == 0) return false;

        uint256 roll = uint256(keccak256(abi.encodePacked(user, qualifierRandomSeed)));
        if (roll & 0xFFFF > auction.qualifierChance) return false;

        return true;
    }

    /* ------------- Private ------------- */

    function resolveBid(uint256 auctionId) private {
        unchecked {
            Auction storage auction = auctions[auctionId];
            uint256 qualifierDuration = auction.qualifierDuration;
            uint256 end = auction.start + qualifierDuration + auction.duration;

            bool cancelled = auction.cancelled;

            if (block.timestamp <= end && !cancelled) revert AuctionOngoing();

            uint256 callerBid = bids[auctionId][msg.sender];
            delete bids[auctionId][msg.sender];

            if (callerBid == 0) revert NoBidPlaced();

            if (auction.currentBid == callerBid && !cancelled) {
                IERC721(auction.prizeNFT).transferFrom(address(this), msg.sender, auction.prizeTokenId);
            } else {
                // callerBid >= 1
                if (qualifierDuration != 0) callerBid -= 1; // keep the qualifier downpayment
                if (callerBid == 0) revert NoBidPlaced();
                gouda.mint(msg.sender, callerBid * 1e18);
            }
        }
    }

    /* ------------- Owner ------------- */

    function createAuction(
        address nft,
        uint40 tokenId,
        uint16 qualifierMaxEntrants,
        uint40 qualifierDuration,
        uint16 qualifierChance,
        uint8 requirement,
        uint40 start,
        uint40 duration
    ) external onlyOwner {
        uint256 auctionId;
        unchecked {
            auctionId = ++numAuctions;
        }

        if (start < block.timestamp || duration > ONE_MONTH || qualifierDuration > ONE_MONTH) revert InvalidTimestamp();

        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        Auction storage auction = auctions[auctionId];

        auction.qualifierMaxEntrants = qualifierMaxEntrants;
        auction.qualifierDuration = qualifierDuration;
        auction.qualifierChance = qualifierChance;

        auction.requirement = requirement;
        auction.start = start;
        auction.duration = duration;

        auction.prizeNFT = nft;
        auction.prizeTokenId = tokenId;
    }

    function cancelAuction(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        auction.cancelled = true;

        IERC721(auction.prizeNFT).transferFrom(address(this), msg.sender, auction.prizeTokenId);
    }

    function revealQualifier(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];

        uint256 qualifierDuration = auction.qualifierDuration;
        if (qualifierDuration == 0) revert QualifierNotRequired();

        unchecked {
            if (block.timestamp < auction.start + qualifierDuration) revert QualifierRevealInvalidTimeFrame();
            if (auction.qualifierRandomSeed != 0) revert QualifierRandomSeedSet();

            auction.qualifierRandomSeed = uint16(uint256(blockhash(block.number - 1)));
        }
    }

    function rescueToys(IERC721 toy, uint256[] calldata toyIds) external onlyOwner {
        unchecked {
            for (uint256 i; i < toyIds.length; ++i) toy.transferFrom(address(this), msg.sender, toyIds[i]);
        }
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error CallerNotOwner();

abstract contract Ownable {
    address _owner = msg.sender;

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IGouda {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function mint(address user, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IMadMouse {
    function numStaked(address user) external returns (uint256);

    function numOwned(address user) external returns (uint256);

    function balanceOf(address user) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function getLevel(uint256 tokenId) external view returns (uint256);

    function getDNA(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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