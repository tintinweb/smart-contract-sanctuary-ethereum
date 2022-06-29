// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// Contract @title Dwarf Pawn
/// Contract @author Stinky (@nomamesgwei)
/// Description @notice: DwarfPawn is a prototype in development by Degen Dwarfs, DYOR before using.
/// Version: 0.2

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Interfaces/IListings.sol";
import "./Interfaces/ILoans.sol";

contract DwarfPawn is Ownable, ReentrancyGuard {
    /// @dev Address of contract beneficiary
    address private beneficiary;
    /// @dev Address of Listings Contract
    address private listingsContract;
    /// @dev Address of Loans Contract
    address private loansContract;
    /// @notice Status of listing
    bool public listingOpen;
    /// @notice Length of maximum loan period measured in days
    uint256 public maxLoanPeriod;
    /// @notice Mapping of ERC-20 token contract to whitelist status
    mapping(address => bool) public tokenWhitelist;

    error ListingNotOpen();
    error InvalidInterestRate();
    error InvalidLoanAmount();
    error InvalidLoanRequest();
    error InvalidOfferId();
    error NotWhitelisted();

    /// @notice Initializes Loans and Listings contracts
    constructor(address _loansContract, address _listingsContract) {
        loansContract = _loansContract;
        listingsContract = _listingsContract;
        maxLoanPeriod = 366;
        listingOpen = true;
    }

    /// @notice Accepts a specific listing that has not yet expired
    /// @param _listingId ID of the listing
    function acceptListing(uint256 _listingId) external nonReentrant {
        if (!listingOpen) revert ListingNotOpen();
        IListings(listingsContract).acceptListing(_listingId, _msgSender());
    }

    /// @notice Accepts an offer for a specific listing
    /// @param _listingId ID of the listing
    /// @param _offerId ID of the offer
    function acceptOffer(uint256 _listingId, uint256 _offerId) external nonReentrant {
        if (_offerId == 0) revert InvalidOfferId();
        IListings(listingsContract).acceptOffer(_listingId, _offerId);
    }

    /// @notice Cancel an active listing
    /// @param _listingId ID of the listing
    function cancelListing(uint256 _listingId) external nonReentrant {
        IListings(listingsContract).cancelListing(_listingId, _msgSender());
    }

    /// @notice Cancel an offer
    /// @param _listingId ID of the listing
    /// @param _offerId  ID of the offer
    function cancelOffer(uint256 _listingId, uint256 _offerId) external nonReentrant {
        IListings(listingsContract).cancelOffer(_listingId, _offerId, _msgSender());
    }

    /// @notice Counters an offer of a specific listing
    /// @param _listingId ID of the listing
    /// @param _loanAmount Loan amount in wei
    /// @param _interestRate Rate of interest in wei
    /// @param _token Address of the ERC-20 token
    function counterOffer(
        uint256 _listingId,
        uint256 _loanAmount,
        uint256 _loanLength,
        uint256 _interestRate,
        address _token
    ) external nonReentrant {
        if (_loanAmount == 0) revert InvalidLoanAmount();
        if (_interestRate == 0) revert InvalidInterestRate();
        if (_loanLength == 0 || _loanLength >= maxLoanPeriod) revert InvalidLoanRequest();

        IListings(listingsContract).counterOffer(
            _listingId,
            _msgSender(),
            _loanAmount,
            _loanLength,
            _interestRate,
            _token
        );
    }

    /// @notice Creates a new listing
    /// @param _token ERC-20 token address
    /// @param _loanAmount Loan amount in wei
    /// @param _loanLength Days to repay loan
    /// @param _nft Address of the NFT
    /// @param _tokenId ID of the NFT token
    /// @param _interestRate The interest rate in wei
    function createListing(
        address _token,
        uint256 _loanAmount,
        uint256 _loanLength,
        address _nft,
        uint256 _tokenId,
        uint256 _interestRate
    ) external nonReentrant {
        if (!listingOpen) revert ListingNotOpen();
        if (_loanLength == 0 || _loanLength >= maxLoanPeriod) revert InvalidLoanRequest();
        if (!tokenWhitelist[_token]) revert NotWhitelisted();

        IListings(listingsContract).createListing(
            _msgSender(),
            _token,
            _loanAmount,
            _loanLength,
            _nft,
            _tokenId,
            _interestRate
        );
    }

    /// @notice Liquidates specific loan and burns ticket NFT for the collateral NFT
    /// @param _loanId ID of the Loan
    function liquidateLoan(uint256 _loanId) external nonReentrant {
        ILoans(loansContract).liquidateLoan(_loanId, _msgSender());
    }

    /// @notice Settles a specific loan by calling the loans contract
    /// @param _loanId ID of the loan
    function settleLoan(uint256 _loanId) external nonReentrant {
        ILoans(loansContract).settleLoan(_loanId, _msgSender());
    }

    /// @notice Sets the mininum and maximum loan periods
    /// @param _max Maximum loan period measured in days
    function setLoanPeriods(uint256 _max) external onlyOwner {
        maxLoanPeriod = _max;
    }

    /// @notice Whitelists multiple ERC-20 tokens
    /// @dev This is done to control the tokens being used on the platform
    /// @param _tokens List of token addresses
    function setWhitelist(address[] calldata _tokens) external onlyOwner {
        uint256 length = _tokens.length;
        for (uint i = 0; i < length; ) {
            tokenWhitelist[_tokens[i]] = true;
            // Cannot possibly overflow due to size of array
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Toggles the listing status from on/off
    function toggleListingOpen() external onlyOwner {
        listingOpen = !listingOpen;
    }

    /// @notice Upgrades the Loans and Listings contracts
    /// @param _loansContract Address of new Loans contract
    /// @param _listingsContract Address of new Listings contract
    function upgradeContracts(address _loansContract, address _listingsContract) external onlyOwner {
        loansContract = _loansContract;
        listingsContract = _listingsContract;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IListings {
    ///@notice Accept a Listing and create loan
    ///@param _listingId the Job ID Number
    ///@param _lender address of lender accepting listing
    function acceptListing(uint256 _listingId, address _lender) external;

    /// @notice Listing creator can accept counter offers
    /// @param _listingId Listing Id number
    /// @param _idOffer Offer Id number
    function acceptOffer(uint256 _listingId, uint256 _idOffer) external;

    /// @notice Cancel an open listing
    /// @param _listingId Listing Id number
    /// @param _requester The address for the requesting party
    function cancelListing(uint256 _listingId, address _requester) external;

    /// @notice Cancel an offer
    /// @param _listingId Listing Id number    
    /// @param _offerId Offer Id number
    /// @param _requester The address for the requesting party
    function cancelOffer(uint256 _listingId, uint256 _offerId, address _requester) external;

    /// @notice Send a counter offer to a specific active listing
    /// @param _listingId The listing you are counter offering
    /// @param _lender Address for the Lender
    /// @param _loanAmount Amount of Tokens to be loaned
    /// @param _loanLength Length of the loan in days
    /// @param _interestRate interest rate charged on loanAmount
    /// @param _tokenAddress The address for the token being loaned
    function counterOffer(
        uint256 _listingId,
        address _lender,
        uint256 _loanAmount,
        uint256 _loanLength, 
        uint256 _interestRate,
        address _tokenAddress
    ) external;

    /// @notice Create a listing for a Loan Request
    /// @param _tokenAddress ERC-20 Address
    /// @param _loanAmount Loan amount in wei
    /// @param _loanLength Days to repay loan
    /// @param _nftAddress Address of NFT
    /// @param _nftId tokenId of NFT
    /// @param _interestRate loan interest rate
    function createListing(
        address _creator,
        address _tokenAddress,
        uint256 _loanAmount,
        uint256 _loanLength,
        address _nftAddress,
        uint256 _nftId,
        uint256 _interestRate
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Loan } from '../Structs/Loan.sol';

interface ILoans {
    /// @notice Create a loan based on accepting listing/offer specs
    /// @dev Loan Length is the only one that is not wei format. If you want a 1 day loan pass 1 not 1000000000000000000
    /// @param _borrow Address of Borrower
    /// @param _lender Address of Lender
    /// @param _token ERC-20 Address
    /// @param _loanAmount Loan amount in wei
    /// @param _loanLength Days to repay loan
    /// @param _nft Address of NFT
    /// @param _tokenId ID of the NFT token 
    /// @param _rate Interest rate on the loan       
    function createLoan(
        address _borrow,
        address _lender,
        address _token,
        uint256 _loanAmount,
        uint256 _loanLength,
        address _nft,
        uint256 _tokenId,
        uint256 _rate
    ) external;

    /// @notice Only the Pawn Ticket NFT holder can call this
    /// @dev Burn ticket NFT and transfer the collateral NFT
    /// @param _id Loan ID #
    /// @param _claimer Claimer Address
    function liquidateLoan(uint256 _id, address _claimer) external;

    /// @notice Settle an active loan by paying the amount plus interest
    /// @dev The Loan contract will need to be approved for the specific ERC-20
    /// @param _id Loan ID #
    /// @param _borrower Borrowers Address
    function settleLoan(uint256 _id, address _borrower) external;

    /// @notice Returns the data for a specific Loan
    function loans(uint256 ) external view returns (Loan memory);

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
pragma solidity ^0.8.13;

struct Loan {
    // Loan #ID
    uint256 id;
    // Loan Date
    uint256 loanDate;
    // Borrower Address
    address borrower;
    // Lender Address
    address lender;
    // Status
    bool isActive;
    // Token for Loan
    address tokenAddress;
    // Token Loan Amount
    uint256 loanAmount;
    // Interest Rate
    uint256 interestRate;
    // NFT Collateral
    address nftAddress;
    // NFT ID
    uint256 nftId;
    // Loan Expiration
    uint256 expirationDate;
}