// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBank is Ownable {

    uint public loanId;
    uint public applicationId;
    uint public millisecondsInMonth = 2629800000;
    uint bankFee;
    uint bankCommission;

    // Creating a structure to store loan details
    struct loan{

        uint _loanId;
        address _nftAddress;
        uint _tokenId;
        address _lender;
        address _lendee;
        uint interestRate;
        uint _tenure;
        uint _loanAmount;
        uint _withdrawLimit;
        uint _endTime;
        uint _emi;
        bool _closed;
    }

    // To keep a record of payments done by any lendee towards a sanctioned loan
    struct loanPayment{
        uint _loanId;
        uint _paidBack;
        bool _default;
    }

    // To store details of all applications for loan
    struct loanApplication{
        
        uint _applicationId;
        address _nftAddress;
        uint _tokenId;
        address _lendee;
        uint _interestRate;
        uint _tenure;
        uint _loanAmount;
        bool _approved;
    }

    // Loan Mappings
    mapping(uint=>loan) public allLoans;
    mapping(address => uint[]) public lendeeLoans;
    mapping(address => uint[]) public lenderLoans;
    mapping(uint=>loanPayment) public loanPayments;
    mapping(uint=>loanApplication) public allApplications;
    mapping(address=>loanApplication[]) public loanApplications;

    // Creating a function so any wallet can showcase their NFT and apply for a loan against it
    function applyForLoan(address _nftAddress, uint _nftId, uint _interestRate, uint _tenure, uint _amount) public {
        require(IERC721(_nftAddress).ownerOf(_nftId)==msg.sender, "Wallet does not own this NFT");        
        applicationId+=1;
        loanApplications[msg.sender].push(loanApplication(applicationId, _nftAddress, _nftId, msg.sender, _interestRate, _tenure, _amount, false));
        allApplications[applicationId] = loanApplication(applicationId, _nftAddress, _nftId, msg.sender, _interestRate, _tenure, _amount, false);
    }

    // This will store the details of any offers given by someone to a loan application
    struct offer{        
        uint _applicationId;
        address _lender;
        uint _interestRate;
        bool _cancelOffer;
        bool _accepted;
        bool _refund;
    }

    // Offer Mappings
    mapping(uint =>offer[]) public offers;
    mapping(uint=>uint) public interestOffered;
    mapping(uint=>address) public offerCreators;
    mapping(uint=>offer) public totalOffers;

    uint offerId;

    // This function can be used to create any offer to a particular loan application if they want to offer different interest rate
    function createOffer(uint _applicationId, uint _interestRate) public payable {
        require(applicationId>=_applicationId,"This application does not exist");
        require(allApplications[_applicationId]._approved==false, "Loan application already approved");
        require(msg.value>=allApplications[_applicationId]._loanAmount);
        offerId+=1;        
        offers[_applicationId].push(offer(_applicationId,msg.sender, _interestRate, false,false, false));
        interestOffered[offerId]= _interestRate;
        offerCreators[offerId]=msg.sender;
        totalOffers[offerId]= offer(_applicationId,msg.sender, _interestRate, false,false, false);        
    }

    // Anyone can cancel their offer if it has not been accepted & processed 
    function cancelOffer(uint _offerId) public{
        require(totalOffers[_offerId]._lender==msg.sender);
        require(totalOffers[_offerId]._refund==false);
        require(totalOffers[_offerId]._accepted==false);
        address payable receiver = payable(totalOffers[_offerId]._lender);        
        if(receiver.send(allApplications[totalOffers[_offerId]._applicationId]._loanAmount)){
            totalOffers[_offerId]._refund=true;
        }
    }

    // Person who applies for the loan can accept an offer if he likes the interest rate offered
    function acceptOffer(uint _offerId) public {
        uint _applicationId = totalOffers[_offerId]._applicationId;
        require(allApplications[_applicationId]._lendee==msg.sender,"This wallet did not create this application");
        require(totalOffers[_offerId]._cancelOffer==false);        
        allApplications[_applicationId]._interestRate = interestOffered[_offerId];
        if(processLoanApplication(_applicationId, interestOffered[_offerId],offerCreators[offerId],msg.sender,
         allApplications[_applicationId]._loanAmount)){
            totalOffers[_offerId]._accepted=true;
         }
    }
    
    // If a person likes a loan application and the interest rate mentioned they can directly lend to that wallet if the application is still open & not processed for loan
    function lend(uint _applicationId) public payable{
        require(msg.value>=allApplications[_applicationId]._loanAmount);
        processLoanApplication(_applicationId, allApplications[_applicationId]._interestRate, msg.sender,allApplications[_applicationId]._lendee, msg.value );
    }
    
    // This is an internal function which generates a loan and enters it in the books whenever someone accepts the offer or directly lends based on open applications
    function processLoanApplication(uint _applicationId, uint _interestRate, address _lender, address _lendee, uint _loanAmount) private returns(bool) {
        require(allApplications[_applicationId]._approved==false, "Loan application already approved");
        require(IERC721(allApplications[_applicationId]._nftAddress).ownerOf(allApplications[_applicationId]._tokenId)==allApplications[_applicationId]._lendee, "Wallet does not own this NFT");
                
        // Seize the NFT colletral by making the smart contract the owner of the NFT
        IERC721(allApplications[_applicationId]._nftAddress).transferFrom(_lendee, address(this), 
        allApplications[_applicationId]._tokenId);

        // Create Loan
        loanId+=1;
        uint _endTime = block.timestamp + (allApplications[_applicationId]._tenure)*millisecondsInMonth;
        uint _emi=calculateEMI( _interestRate, _loanAmount, allApplications[_applicationId]._tenure);
        allLoans[loanId]=loan(loanId,allApplications[_applicationId]._nftAddress, 
        allApplications[_applicationId]._tokenId,_lender,
        _lendee, _interestRate,allApplications[_applicationId]._tenure, _loanAmount, _loanAmount, 
        _endTime,_emi, false);
        loanPayments[loanId]=loanPayment(loanId,0,false);
        allApplications[_applicationId]._approved=true; 
        lendeeLoans[_lendee].push(loanId);
        lenderLoans[_lender].push(loanId);
        return(true);
    }

    // This calculates the EMI a person needs to pay to repay their loan
    function calculateEMI(uint _interestRate, uint _loanAmount, uint _tenure) private pure returns(uint){        
        uint a = SafeMath.mul(_interestRate, _loanAmount);
        uint _totalinterest = SafeMath.div(a,1000);
        uint _emi = SafeMath.div(_totalinterest,_tenure);        
        return(_emi);
    }

    // Once a loan is approved, the person can withdraw his loan amount from the smart contract
    function withdrawLoanAmount(uint _loanId, uint _amount) public {
        require(allLoans[_loanId]._lendee==msg.sender);
        require(allLoans[_loanId]._withdrawLimit>=_amount);
        require(_amount>0);
        address payable receiver = payable(msg.sender);        
        if(receiver.send(_amount)){
            allLoans[loanId]._withdrawLimit = allLoans[loanId]._withdrawLimit - _amount;
        }
    }

    // Lendee can use this function to pay back his loan
    function payEMI(uint _loanId) public payable {
        require(allLoans[_loanId]._closed==false);
        require(loanPayments[_loanId]._paidBack<=allLoans[_loanId]._loanAmount);
        loanPayments[_loanId]._paidBack += msg.value;

        //We charge a small commission on each re-payment
        uint commission = msg.value*bankFee/1000;
        bankCommission+=commission;
    }

    // If the loan is all paid up then it can be closed and the NFT can be released back to the lendee
    function closePaidUpLoan(uint _loanId) public {
        uint _payableAmount = allLoans[_loanId]._loanAmount +(allLoans[_loanId]._emi*allLoans[_loanId]._tenure);
        require(_payableAmount<=loanPayments[_loanId]._paidBack);
        IERC721(allLoans[_loanId]._nftAddress).transferFrom(address(this),allLoans[_loanId]._lendee, 
        allLoans[_loanId]._tokenId);
        allLoans[_loanId]._closed = true;                
    }

    // If Lendee defaults the NFT is transferred to the lender and loan is closed
    function closeDefaultedLoan(uint _loanId) public{
        require(block.timestamp>=allLoans[_loanId]._endTime);
        uint _payableAmount = allLoans[_loanId]._loanAmount +(allLoans[_loanId]._emi*allLoans[_loanId]._tenure);
        require(_payableAmount>=loanPayments[_loanId]._paidBack);
        IERC721(allLoans[_loanId]._nftAddress).transferFrom(address(this),allLoans[_loanId]._lender , 
        allLoans[_loanId]._tokenId);
        allLoans[_loanId]._closed = true;
        loanPayments[_loanId]._default = true;
    }
    
    // Contract owner can set their commission % for each loan re-payment transaction. Denomination 1000
    function setFee(uint _bankFee) public onlyOwner{
        bankFee =_bankFee;
    }

    // Contract Owner can withdraw his commission from transactions
    function withdrawDevCommission() public onlyOwner{
        address payable receiver = payable(owner());
        require(bankCommission>0);
        if(receiver.send(bankCommission)){
            bankCommission =0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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