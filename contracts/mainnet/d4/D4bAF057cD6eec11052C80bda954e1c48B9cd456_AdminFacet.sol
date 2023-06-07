// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOwnershipFacet} from "./interface/IOwnershipFacet.sol";
import {IAdminFacet} from "./interface/IAdminFacet.sol";
import {Ray} from "./DataStructure/Objects.sol";
import {SupplyPosition, Protocol} from "./DataStructure/Storage.sol";
import {protocolStorage, supplyPositionMetadataStorage, ONE} from "./DataStructure/Global.sol";
import {CallerIsNotOwner} from "./DataStructure/Errors.sol";
import {RayMath} from "./utils/RayMath.sol";

/// @notice admin-only setters for global protocol parameters
contract AdminFacet is IAdminFacet {
    using RayMath for Ray;

    /// @notice restrict a method access to the protocol owner only
    modifier onlyOwner() {
        // the admin/owner is the same account that can upgrade the protocol.
        address admin = IOwnershipFacet(address(this)).owner();
        if (msg.sender != admin) {
            revert CallerIsNotOwner(admin);
        }
        _;
    }

    /// @notice sets the time it takes to auction prices to fall to 0 for future loans
    /// @param newAuctionDuration number of seconds of the duration
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        protocolStorage().auction.duration = newAuctionDuration;
        emit NewAuctionDuration(newAuctionDuration);
    }

    /// @notice sets the factor applied to the loan to value setting initial price of auction for future loans
    /// @param newAuctionPriceFactor the new factor multiplied to the loan to value
    function setAuctionPriceFactor(Ray newAuctionPriceFactor) external onlyOwner {
        // see auction facet for the rationale of this check
        require(newAuctionPriceFactor.gte(ONE.mul(5).div(2)), "");
        protocolStorage().auction.priceFactor = newAuctionPriceFactor;
        emit NewAuctionPriceFactor(newAuctionPriceFactor);
    }

    /// @notice creates a new tranche at a new identifier for lenders to provide offers for
    /// @param newTranche the interest rate of the new tranche
    function createTranche(Ray newTranche) external onlyOwner returns (uint256 newTrancheId) {
        Protocol storage proto = protocolStorage();

        newTrancheId = proto.nbOfTranches++;
        proto.tranche[newTrancheId] = newTranche;

        emit NewTranche(newTranche, newTrancheId);
    }

    /* Both minimal offer cost and lower amount per offer lower bound are anti ddos mechanisms used to prevent the
    borrowers to spam the minting of supply positions that lenders would have no incentive to claim the corresponding
    dust funds from due to gas costs. The minimal offer cost mainly prevents this for claims after repayment, the amount
    per offer lower bound mainly prevents this for claims after liquidation. The governance setting those parameters
    effectively makes new erc20 available to use on the platform (they are disallowed otherwise). This should not
    be done for any fee-on-transfer token. */

    /// @notice updates the minimum amount to repay per used loan offer when borrowing a certain currency
    /// @param currency the erc20 on which a new minimum borrow cost will take effect
    /// @param newMinOfferCost the new minimum amount that will need to be repaid per loan offer used
    function setMinOfferCost(IERC20 currency, uint256 newMinOfferCost) external onlyOwner {
        protocolStorage().minOfferCost[currency] = newMinOfferCost;
        emit NewMininimumOfferCost(currency, newMinOfferCost);
    }

    /// @notice updates the borrow amount lower bound per offer for one currency
    /// @param currency the erc20 on which a new borrow amount lower bound is taking effect
    /// @param newLowerBound the new lower bound
    function setBorrowAmountPerOfferLowerBound(IERC20 currency, uint256 newLowerBound) external onlyOwner {
        protocolStorage().offerBorrowAmountLowerBound[currency] = newLowerBound;
        emit NewBorrowAmountPerOfferLowerBound(currency, newLowerBound);
    }

    /// @notice updates the base metadata uri to which the token id will be appended to get the metadata uri
    /// @param baseMetadataUri the new base metadata uri
    function setBaseMetadataUri(string calldata baseMetadataUri) external onlyOwner {
        supplyPositionMetadataStorage().baseUri = baseMetadataUri;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFToken, Offer} from "./Objects.sol";

error BadCollateral(Offer offer, NFToken providedNft);
error ERC20TransferFailed(IERC20 token, address from, address to);
error OfferHasExpired(Offer offer, uint256 expirationDate);
error RequestedAmountIsUnderMinimum(Offer offer, uint256 requested, uint256 lowerBound);
error RequestedAmountTooHigh(uint256 requested, uint256 offered, Offer offer);
error LoanAlreadyRepaid(uint256 loanId);
error LoanNotRepaidOrLiquidatedYet(uint256 loanId);
error NotBorrowerOfTheLoan(uint256 loanId);
error BorrowerAlreadyClaimed(uint256 loanId);
error CallerIsNotOwner(address admin);
error InvalidTranche(uint256 nbOfTranches);
error CollateralIsNotLiquidableYet(uint256 endDate, uint256 loanId);
error UnsafeAmountLent(uint256 lent);
error MultipleOffersUsed();
error PriceOverMaximum(uint256 maxPrice, uint256 price);
error CurrencyNotSupported(IERC20 currency);
error ShareMatchedIsTooLow(Offer offer, uint256 requested);

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Protocol, SupplyPosition, SupplyPositionOffChainMetadata} from "./Storage.sol";
import {Ray} from "./Objects.sol";

/* rationale of the naming of the hash is to use kairos loan's ENS as domain, the subject of the storage struct as
subdomain and the version to anticipate upgrade. Order is revered compared to urls as it's the usage in code such as in
java imports */
bytes32 constant PROTOCOL_SP = keccak256("eth.kairosloan.protocol.v1.0");
bytes32 constant SUPPLY_SP = keccak256("eth.kairosloan.supply-position.v1.0");
bytes32 constant POSITION_OFF_CHAIN_METADATA_SP = keccak256("eth.kairosloan.position-off-chain-metadata.v1.0");

/* Ray is chosed as the only fixed-point decimals approach as it allow extreme and versatile precision accross erc20s
and timeframes */
uint256 constant RAY = 1e27;
Ray constant ONE = Ray.wrap(RAY);
Ray constant ZERO = Ray.wrap(0);

/* solhint-disable func-visibility */

/// @dev getters of storage regions of the contract for specified usage

/* we access storage only through functions in facets following the diamond storage pattern */

function protocolStorage() pure returns (Protocol storage protocol) {
    bytes32 position = PROTOCOL_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        protocol.slot := position
    }
}

function supplyPositionStorage() pure returns (SupplyPosition storage sp) {
    bytes32 position = SUPPLY_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        sp.slot := position
    }
}

function supplyPositionMetadataStorage() pure returns (SupplyPositionOffChainMetadata storage position) {
    bytes32 position_off_chain_metadata_sp = POSITION_OFF_CHAIN_METADATA_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        position.slot := position_off_chain_metadata_sp
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice file for type definitions not used in storage

/// @notice 27-decimals fixed point unsigned number
type Ray is uint256;

/// @notice Arguments to buy the collateral of one loan
/// @param loanId loan identifier
/// @param to address that will receive the collateral
/// @param maxPrice maximum price to pay for the collateral
struct BuyArg {
    uint256 loanId;
    address to;
    uint256 maxPrice;
}

/// @notice Arguments to borrow from one collateral
/// @param nft asset to use as collateral
/// @param args arguments for the borrow parameters of the offers to use with the collateral
struct BorrowArg {
    NFToken nft;
    OfferArg[] args;
}

/// @notice Arguments for the borrow parameters of an offer
/// @dev '-' means n^th
/// @param signature - of the offer
/// @param amount - to borrow from this offer
/// @param offer intended for usage in the loan
struct OfferArg {
    bytes signature;
    uint256 amount;
    Offer offer;
}

/// @notice Data on collateral state during the matching process of a NFT
///     with multiple offers
/// @param matched proportion from 0 to 1 of the collateral value matched by offers
/// @param assetLent - ERC20 that the protocol will send as loan
/// @param tranche identifier of the interest rate tranche that will be used for the loan
/// @param minOfferDuration minimal duration among offers used
/// @param minOfferLoanToValue
/// @param maxOfferLoanToValue
/// @param from original owner of the nft (borrower in most cases)
/// @param nft the collateral asset
/// @param loanId loan identifier
struct CollateralState {
    Ray matched;
    IERC20 assetLent;
    uint256 tranche;
    uint256 minOfferDuration;
    uint256 minOfferLoanToValue;
    uint256 maxOfferLoanToValue;
    address from;
    NFToken nft;
    uint256 loanId;
}

/// @notice Loan offer
/// @param assetToLend address of the ERC-20 to lend
/// @param loanToValue amount to lend per collateral
/// @param duration in seconds, time before mandatory repayment after loan start
/// @param expirationDate date after which the offer can't be used
/// @param tranche identifier of the interest rate tranche
/// @param collateral the NFT that can be used as collateral with this offer
struct Offer {
    IERC20 assetToLend;
    uint256 loanToValue;
    uint256 duration;
    uint256 expirationDate;
    uint256 tranche;
    NFToken collateral;
}

/// @title Non Fungible Token
/// @notice describes an ERC721 compliant token, can be used as single spec
///     I.e Collateral type accepting one specific NFT
/// @dev found in storgae
/// @param implem address of the NFT contract
/// @param id token identifier
struct NFToken {
    IERC721 implem;
    uint256 id;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFToken, Ray} from "./Objects.sol";

/// @notice type definitions of data permanently stored

/// @notice Parameters affecting liquidations by dutch auctions. The current auction parameters
///         are assigned to new loans at borrow time and can't be modified during the loan life.
/// @param duration number of seconds after the auction start when the price hits 0
/// @param priceFactor multiplier of the mean tvl used as start price for the auction
struct Auction {
    uint256 duration;
    Ray priceFactor;
}

/// @notice General protocol
/// @param nbOfLoans total number of loans ever issued (active and ended)
/// @param nbOfTranches total number of interest rates tranches ever created (active and inactive)
/// @param auctionParams - sets auctions duration and initial prices
/// @param tranche interest rate of tranche of provided id, in multiplier per second
///         I.e lent * time since loan start * tranche = interests to repay
/// @param loan - of id -
/// @param minOfferCost minimum amount repaid per offer used in a loan
/// @param offerBorrowAmountLowerBound borrow amount per offer has to be strightly higher than this value
struct Protocol {
    uint256 nbOfLoans;
    uint256 nbOfTranches;
    Auction auction;
    mapping(uint256 => Ray) tranche;
    mapping(uint256 => Loan) loan;
    mapping(IERC20 => uint256) minOfferCost;
    mapping(IERC20 => uint256) offerBorrowAmountLowerBound;
}

/// @notice Issued Loan (corresponding to one collateral)
/// @param assetLent currency lent
/// @param lent total amount lent
/// @param shareLent between 0 and 1, the share of the collateral value lent
/// @param startDate timestamp of the borrowing transaction
/// @param endDate timestamp after which sale starts & repay is impossible
/// @param auction duration and price factor of the collateral auction in case of liquidation
/// @param interestPerSecond share of the amount lent added to the debt per second
/// @param borrower borrowing account
/// @param collateral NFT asset used as collateral
/// @param payment data on the payment, a non-0 payment.paid value means the loan lifecyle is over
struct Loan {
    IERC20 assetLent;
    uint256 lent;
    Ray shareLent;
    uint256 startDate;
    uint256 endDate;
    Auction auction;
    Ray interestPerSecond;
    address borrower;
    NFToken collateral;
    Payment payment;
}

/// @notice tracking of the payment state of a loan
/// @param paid amount sent on the tx closing the loan, non-zero value means loan's lifecycle is over
/// @param minInterestsToRepay minimum amount of interests that the borrower will need to repay
/// @param liquidated this loan has been closed at the liquidation stage, the collateral has been sold
/// @param borrowerClaimed borrower claimed his rights on this loan (either collateral or share of liquidation)
struct Payment {
    uint256 paid;
    uint256 minInterestsToRepay;
    bool liquidated;
    bool borrowerClaimed;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param name - of the NFT collection
/// @param symbol - of the NFT collection
/// @param totalSupply number of supply position ever issued - not decreased on burn
/// @param owner - of nft of id -
/// @param balance number of positions owned by -
/// @param tokenApproval address approved to transfer position of id - on behalf of its owner
/// @param operatorApproval address is approved to transfer all positions of - on his behalf
/// @param provision supply position metadata
struct SupplyPosition {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(uint256 => address) owner;
    mapping(address => uint256) balance;
    mapping(uint256 => address) tokenApproval;
    mapping(address => mapping(address => bool)) operatorApproval;
    mapping(uint256 => Provision) provision;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param baseUri - base uri
struct SupplyPositionOffChainMetadata {
    string baseUri;
}

/// @notice data on a liquidity provision from a supply offer in one existing loan
/// @param amount - supplied for this provision
/// @param share - of the collateral matched by this provision
/// @param loanId identifier of the loan the liquidity went to
struct Provision {
    uint256 amount;
    Ray share;
    uint256 loanId;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Ray} from "../DataStructure/Objects.sol";

interface IAdminFacet {
    /// @notice duration of future auctions has been updated
    /// @param newAuctionDuration duration of liquidation for new loans
    event NewAuctionDuration(uint256 indexed newAuctionDuration);

    /// @notice initial price factor of future auctions has been updated
    /// @param newAuctionPriceFactor factor of loan to value setting initial price of auctions
    event NewAuctionPriceFactor(Ray indexed newAuctionPriceFactor);

    /// @notice a new interest rate tranche has been created
    /// @param tranche the interest rate of the new tranche, in multiplier per second
    /// @param newTrancheId identifier of the new tranche
    event NewTranche(Ray indexed tranche, uint256 indexed newTrancheId);

    /// @notice the minimum cost to repay per used loan offer
    ///     when borrowing a certain currency has been updated
    /// @param currency the erc20 on which a new minimum borrow cost is taking effect
    /// @param newMinOfferCost the new minimum amount that will need to be repaid per loan offer used
    event NewMininimumOfferCost(IERC20 indexed currency, uint256 indexed newMinOfferCost);

    /// @notice the borrow amount lower bound per offer has been updated
    /// @param currency the erc20 on which a new borrow amount lower bound is taking effect
    /// @param newLowerBound the new lower bound
    event NewBorrowAmountPerOfferLowerBound(IERC20 indexed currency, uint256 indexed newLowerBound);

    function setAuctionDuration(uint256 newAuctionDuration) external;

    function setAuctionPriceFactor(Ray newAuctionPriceFactor) external;

    function createTranche(Ray newTranche) external returns (uint256 newTrancheId);

    function setMinOfferCost(IERC20 currency, uint256 newMinOfferCost) external;

    function setBorrowAmountPerOfferLowerBound(IERC20 currency, uint256 newLowerBound) external;

    function setBaseMetadataUri(string calldata baseMetadataUri) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IOwnershipFacet {
    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {RAY} from "../DataStructure/Global.sol";
import {Ray} from "../DataStructure/Objects.sol";

/// @notice Manipulates fixed-point unsigned decimals numbers
/// @dev all uints are considered integers (no wad)
library RayMath {
    // ~~~ calculus ~~~ //

    /// @notice `a` plus `b`
    /// @return result
    function add(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) + Ray.unwrap(b));
    }

    /// @notice `a` minus `b`
    /// @return result
    function sub(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) - Ray.unwrap(b));
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * Ray.unwrap(b)) / RAY);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) * b);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * Ray.unwrap(b)) / RAY;
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * RAY) / Ray.unwrap(b));
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) / b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * RAY) / Ray.unwrap(b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap((a * RAY) / b);
    }

    // ~~~ comparisons ~~~ //

    /// @notice is `a` less than `b`
    /// @return result
    function lt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) < Ray.unwrap(b);
    }

    /// @notice is `a` greater than `b`
    /// @return result
    function gt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) > Ray.unwrap(b);
    }

    /// @notice is `a` greater or equal to `b`
    /// @return result
    function gte(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) >= Ray.unwrap(b);
    }

    /// @notice is `a` equal to `b`
    /// @return result
    function eq(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) == Ray.unwrap(b);
    }

    // ~~~ uint256 method ~~~ //

    /// @notice highest value among `a` and `b`
    /// @return maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}