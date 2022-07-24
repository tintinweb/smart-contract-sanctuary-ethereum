// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTListing.sol";

/**
 * Contract to describe all Loans, the collateral and conditions accepted by the borrower
 */
contract NFTLoanVault is Ownable {
    // Structure to represent loan - from listing to all agreed on conditions
    struct NFTLoan {
        uint256 borrowedOn;
        NFTListing listing;
        uint256 sold;
        uint256 paid;
        int256 PL;
        uint256 loanExpiry;
        uint256 returnedTknId;
        address returnedCollectionAddress;
        LoanStatus status;
        uint256 returnedOn;
    }

    enum LoanStatus {
        INITIAL,
        RETURN_W_DYVE,
        RETURN_SELF,
        FORTEIT_COLLATERAL,
        OTHER
    }

    //borrower's loans
    mapping(address => mapping(uint256 => NFTLoan)) public loanedNFT;
    uint256 allLoans;

    // Each borrower may have multiple NFTs borrowed
    mapping(address => uint256) public loanedNFTCount;

    // Manage borrowers
    mapping(address => bool) internal borrowerExists;
    address[] borrowers;

    function addBorrower(address borrower) internal {
        if (!borrowerExists[borrower]) {
            borrowers.push(borrower);
            borrowerExists[borrower] = true;
        }
    }

    function borrow(
        address borrower,
        NFTListing memory listing,
        uint256 loanExpiry
    ) public {
        addBorrower(msg.sender);
        allLoans = allLoans + 1;
        loanedNFTCount[borrower] = loanedNFTCount[borrower] + 1;
        uint256 currentCount = loanedNFTCount[borrower];
        loanedNFT[borrower][currentCount] = NFTLoan(
            block.timestamp,
            listing,
            0,
            0,
            0,
            loanExpiry,
            0,
            address(0),
            LoanStatus.INITIAL,
            0
        );
    }

    /**
     * Helper to load test data only
     */
    function borrowedOn(
        address borrower,
        NFTListing memory listing,
        uint256 loanExpiry,
        uint256 borroweOn,
        uint256 price1,
        uint256 price2,
        int256 pl,
        uint256 returnTknId,
        address returnedCollectionAdress,
        LoanStatus loanStatus,
        uint256 returnedOn
    ) public {
        addBorrower(msg.sender);
        allLoans = allLoans + 1;
        uint256 currentCount = loanedNFTCount[borrower];
        loanedNFT[borrower][currentCount] = NFTLoan(
            borroweOn,
            listing,
            price1,
            price2,
            pl,
            loanExpiry,
            returnTknId,
            returnedCollectionAdress,
            loanStatus,
            returnedOn
        );
        loanedNFTCount[borrower] = loanedNFTCount[borrower] + 1;
    }

    /**
     *   Retrieve all Loans
     */
    function getAllLoans() public view returns (NFTLoan[] memory) {
        NFTLoan[] memory ret = new NFTLoan[](allLoans);

        for (uint256 j = 0; j < borrowers.length; j++) {
            for (uint256 i = 0; i < loanedNFTCount[borrowers[j]]; i++) {
                ret[i] = loanedNFT[borrowers[j]][i];
            }
        }
        return ret;
    }

    /**
     *   Testing helper
     */
    function getAllCount() public view returns (uint256) {
        return getAllLoans().length;
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

pragma solidity ^0.8.0;

/*
Structure representing NFTListing for a Lender
*/
struct NFTListing {
    uint256 listedOn;
    address tknAddress;
    uint256 tknId;
    string compliance;
    uint256 dailyFee;
    ReturnCondition returnCondition;
    uint256 expiry;
    NFTCollateral collateral;
}

struct NFTCollateral {
    uint256 amount;
    string currency;
}

enum ReturnCondition {
    SAME,
    ANY
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