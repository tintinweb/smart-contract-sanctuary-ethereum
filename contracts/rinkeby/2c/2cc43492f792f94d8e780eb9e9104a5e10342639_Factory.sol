//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/MYIERC721.sol";
import "./interfaces/IERC20.sol";
import "./DeployHandler/IDeploy.sol";

import "./Contracts/Ownable.sol";
import "./Contracts/librariesViewFunction.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./library/BookingMap.sol";
import "./library/UserMapping.sol";
import "./library/DateTimeLibrary.sol";


contract Factory is Ownable, librariesViewFunction {

    using SafeMath for uint256;

    using BookingMap for BookingMap.Map;
    using UserMapping for UserMapping.Map;

    BookingMap.Map private booking;
    UserMapping.Map private User;


    /***********************************************
    *   variables
    ***********************************************/

    IERC20 private USDT;
    IDeploy private DeployHandler;

    
    

    
    /***********************************************
    *   constructor
    ***********************************************/

    constructor(address _USDT, address _DeployHandler) Ownable(msg.sender) {
        USDT = IERC20(_USDT);
        DeployHandler = IDeploy(_DeployHandler);
    }








    /******************************************************
    *               Buy Ownership (loigc)
    *******************************************************/

    event mint(uint token, address user);


    function buyOwnership (

        uint256 tOwnership_,
        uint256 USDT_,
        address contract_

        ) public {

        require ( tOwnership_ > 0, "!tOwnership");

        ( ,,, uint contractTotalSupply, uint contractTotalOwnership, uint contractPrice, address contractOwner , ) =
            DeployHandler.contractDitals(contract_);

        require ( 
            contractTotalSupply >= (contractTotalOwnership.add(tOwnership_)), 
            "!Total Supply"
        );

        require ( 
            (contractPrice.mul(tOwnership_)) == USDT_, 
            "!Not suffecient USDT"
        );
        

        USDT.transferFrom( msg.sender, contractOwner, USDT_ );
        MYIERC721 IContract = MYIERC721(contract_);

        for (uint256 i = 0; i < tOwnership_; i++) {

            DeployHandler.updateTotalOwnership(contract_, tOwnership_);
            uint _current = contractTotalOwnership.add(tOwnership_);

            User.set(contract_, _msgSender(), _current);
            IContract.safeMint(msg.sender, _current);

            emit mint(_current, msg.sender);

        }

    }

    /******************************************************
    *   BookDate loigc (bookDate, cancelBooking)
    *******************************************************/
    uint public _newYear;
    uint public _bookingBefore = 0; // user can't book date Before (bookingBefore)date
    uint public _bookingAfter  = 604800; // user can't book date After  (bookingAfter)date
    uint public _cancelBefore  = 86400;

    struct _bookDates {
        uint _year;
        uint _month;
        uint _day;
    }

    mapping(address => mapping(uint => uint)) public _indexOfBookedDates;
    mapping(address => mapping(uint => _bookDates[])) private _allBookedDates;
    mapping(address => mapping(uint => mapping ( uint => mapping ( uint => uint )))) public _bookDateID;

    event booked(uint token, address user);
    event _cancelBooking(address _Contract, uint id, uint year, uint month, uint day);

    // update function
    function updateBookingBefore(uint time_) public {
        _bookingBefore = time_;
    }
    function updateBookingAfter(uint time_) public {
        _bookingAfter = time_;
    }
    function updateCancelBefore(uint time_) public {
        _cancelBefore = time_;
    }

    // view function
    function allBookedDates(address contract_, uint newYear_) public view returns(_bookDates[] memory) {
        return _allBookedDates[contract_][newYear_];
    }

    // public function
    function bookDate(

        uint year_, uint month_, uint day_, address contract_, uint id_

        ) public {

        MYIERC721 IContract = MYIERC721(contract_);
        address __owner = IContract.ownerOf(id_);

        require(
            _msgSender() == __owner || IContract.isApprovedForAll(__owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        require ( DateTimeLibrary.isValidDate(year_, month_, day_), "inValid Date");
        uint lnewDAte_ = DateTimeLibrary.timestampFromDate(year_, month_, day_);

        (, uint bookedTime_, uint newYear_) = booking.getTime(contract_, id_);

        if (booking.isInserted(contract_, id_)) {
            require ( lnewDAte_ > newYear_, "Token Already Booked");
        }

        require(bookedTime_ != lnewDAte_, "Date Already Booked");
        
        uint _blockTimestamp = block.timestamp;
        require ( (_blockTimestamp + _bookingBefore) < lnewDAte_, "!booking Before");
        require ( (_blockTimestamp + _bookingAfter ) > lnewDAte_, "!booking After");

        uint lnewYear_ = DateTimeLibrary.timestampFromDate(year_.add(1), 12, 31);

        if (newYear_ != lnewYear_) newYear_ = lnewYear_;
        _indexOfBookedDates[contract_][id_] = _allBookedDates[contract_][newYear_].length;
        _allBookedDates[contract_][newYear_].push(_bookDates(year_, month_, day_));
        _bookDateID[contract_][year_][month_][day_] = id_;

        booking.set(contract_, id_, _msgSender(), _blockTimestamp, lnewDAte_, lnewYear_);

        emit booked(id_, _msgSender());

    }

    function cancelBooking(address contract_, uint id_) public {

        require (booking.isInserted(contract_, id_), "!Booked");
        require (booking.getOwner(contract_, id_) == _msgSender(), "!Owner");

        (, uint _DateAndTime ,) = booking.getTime(contract_, id_);
        require (_DateAndTime > (block.timestamp.sub(_cancelBefore)), "Cant Cancel Booking Now");

        (uint _year, uint _month, uint _day) = DateTimeLibrary.timestampToDate(_DateAndTime);

        booking.remove(contract_, id_);
        delete _bookDateID[contract_][_year][_month][_day];

        uint index = _indexOfBookedDates[contract_][id_];
        uint lastIndex = _allBookedDates[contract_][_newYear].length - 1;
        uint year = _allBookedDates[contract_][_newYear][lastIndex]._year;
        uint month = _allBookedDates[contract_][_newYear][lastIndex]._month;
        uint day = _allBookedDates[contract_][_newYear][lastIndex]._day;

        delete _indexOfBookedDates[contract_][id_];

        _allBookedDates[contract_][_newYear][index] = _bookDates( year, month, day );
        _allBookedDates[contract_][_newYear].pop();

        emit _cancelBooking(contract_, id_, _year, _month, _day);

    }






    /*******************************************************
    *   offer logic (offer, cancelOffer, acceptOffer)
    *******************************************************/

    struct offer_ {
        uint id;
        uint userID;
        uint Price;
        uint Time;
        uint offeredDate;
        address User;
        address Contract;
    }

    uint public _offerBefore; // user can't offer After (offerBefore)date
    uint public _acceptOfferBefore; // user can't acceptOffer After (acceptOfferBefore)date
    uint public _offerPrice; // user have to pay USDT for offer

    mapping(address => mapping(uint => uint)) public _indexOfuserAllOffers;
    mapping(address => mapping(uint => offer_)) public _offers;
    mapping(address => mapping(address => uint[])) private _userAllOffers;
    
    mapping(address => mapping(uint => bool)) public _offerdID;
    mapping(address => mapping(uint => bool)) public _acceptedOffers;

    event offered(uint token, address user);
    event offerAccepted(uint token, address user);

    // update function
    function updateOfferBefore(uint time_) public {
        _offerBefore = time_;
    }
    function updateAcceptOfferBefore(uint time_) public {
        _acceptOfferBefore = time_;
    }
    function updateOfferPrice(uint amount_) public {
        uint decimals = USDT.decimals();
        _offerPrice = (amount_ * 10 ** decimals);
    }

    // view function
    function userAllOffers(address contract_, address user_) public view returns(uint[] memory) {
        return _userAllOffers[contract_][user_];
    }



    function offer(address contract_, uint id_, uint userID_, uint256 USDT_ ) public {

        require(!_offerdID[contract_][id_], "offerdID");

        address _msgSender = _msgSender();

        MYIERC721 IContract = MYIERC721(contract_);

        require(IContract.balanceOf(_msgSender) > 0, "!Token");
        require(IContract.ownerOf(userID_) == _msgSender, "!Owner");

        require ( booking.isInserted(contract_, id_), "!Booked");

        require ( _offerPrice <= USDT_, "!OfferPrice");

        (,uint _DateAndTime,) = booking.getTime(contract_, id_);

        require ( (_DateAndTime.sub(_offerBefore)) > block.timestamp, "!Time Out");

        USDT.transferFrom( _msgSender, address(this), USDT_);

        _offers[contract_][id_] = 
            offer_(id_, userID_, USDT_, (_DateAndTime.sub(_acceptOfferBefore)),  _DateAndTime, _msgSender, contract_);
        _indexOfuserAllOffers[contract_][id_] = _userAllOffers[contract_][_msgSender].length;
        _userAllOffers[contract_][_msgSender].push(id_);
        _offerdID[contract_][id_] = true;

        emit offered(id_, _msgSender);

    }

    function cancelOffer(address contract_, uint id_) public {

        require(_offerdID[contract_][id_],"!offerd");

        address _msgSender = _msgSender();
        require(_offers[contract_][id_].User == _msgSender, "!User");

        USDT.transfer( _msgSender, _offers[contract_][id_].Price);

        uint index = _indexOfuserAllOffers[contract_][id_];
        uint lastIndex = _userAllOffers[contract_][_msgSender].length - 1;
        uint lastKey = _userAllOffers[contract_][_msgSender][lastIndex];

        _indexOfuserAllOffers[contract_][lastKey] = index;
        delete _indexOfuserAllOffers[contract_][id_];

        _userAllOffers[contract_][_msgSender][index] = lastKey;
        _userAllOffers[contract_][_msgSender].pop();

        delete _offers[contract_][id_];
        delete _offerdID[contract_][id_];
    }

    function acceptOffer(address contract_, uint id_) public {

        require ( _offerdID[contract_][id_], "!Offerd");
        require ( booking.getOwner(contract_, id_) == _msgSender(), "!Owner");
        require ( _offers[contract_][id_].Time > block.timestamp, "!Time Out");

        (, uint bookedTime_, uint newYear_) = booking.getTime(contract_, id_);
        booking.remove(contract_, id_);
        booking.set(
            contract_, _offers[contract_][id_].userID, 
            _offers[contract_][id_].User, block.timestamp, bookedTime_, newYear_);

        (uint year, uint month, uint day) = DateTimeLibrary.timestampToDate(bookedTime_);
        _bookDateID[contract_][year][month][day] = _offers[contract_][id_].userID;

        _acceptedOffers[contract_][id_] = true;
        USDT.transfer(_msgSender(), _offers[contract_][id_].Price);

        delete _offerdID[contract_][id_];
        delete _offers[contract_][id_];

        emit offerAccepted(id_, _msgSender());

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface MYIERC721 is IERC165 {
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

    function updateBaseURI(string memory symbol_) external;

    function updateBaseExtension(string memory baseExtension_) external;

    function pause() external;

    function unpause() external;

    function safeMint(address to, uint256 tokenId) external;
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

    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDeploy {
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allContractAddress() external view returns(address[] memory);

    function userAllContractAddress(address user_) external view returns(address[] memory);

    function contractDitals(address contract_) external view returns(
        uint id, string memory name, string memory symbol, uint tSupply, 
        uint tOwnership, uint price, address owner, string memory baseURI
    );

    function updateTotalOwnership(address contract_, uint number_) external returns(bool);

    function deploy(

        string memory name_, string memory symbol_, uint totalSupply_,
        uint price_, address ownerAddress_, string memory baseURI_

    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor(address ownerAddress_) {
        _owner = ownerAddress_;
        emit OwnershipTransferred(address(0), ownerAddress_);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "!owner");
        _;
    }
    
    function _transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "!zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./../library/BookingMap.sol";
import "./../library/UserMapping.sol";

abstract contract librariesViewFunction {

    using BookingMap for BookingMap.Map;
    using UserMapping for UserMapping.Map;

    BookingMap.Map private booking;
    UserMapping.Map private User;

    /*******************************************************
    *   view function from UserMapping library
    *******************************************************/

    function UserIDs(address _contract, address _user) public view returns (uint256[] memory) {
        return User.getTokens(_contract, _user);
    }
    function UserAllContractAddress(address _user) public view returns (address[] memory) {
        return User.getAllContractAddress(_user);
    }
    function AllUser() public view returns (address[] memory) {
        return User.getUser();
    }
    function userKeyAtIndex(uint _id) public view returns (address) {
        return User.getKeyAtIndex(_id);
    }
    function userArraySize() public view returns (uint) {
        return User.getSize();
    }
    function userArraySize(address _contract, address _user) public view returns (bool) {
        return User.isInserted(_contract, _user);
    }



    /*******************************************************
    *   view function from BookingMap library
    *******************************************************/

    function BookedUserIDs(address _Contract) public view returns (
        uint[] memory _userIds
        ) {
        (_userIds ,) = booking.getKeys(_Contract);
    }


    function BookedDate(address _Contract, uint _id) public view returns (
        uint bookingTime_, uint bookedTime_, uint newYear_ ) {

        (bookingTime_, bookedTime_, newYear_) = booking.getTime(_Contract, _id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.12;

library BookingMap {

    struct Map {
        address[] _contract;
        mapping(address => uint[]) id;
        mapping(address => mapping(uint => address)) owner;
        mapping(address => mapping(uint => uint)) bookingTime;
        mapping(address => mapping(uint => uint)) bookedTime;
        mapping(address => mapping(uint => uint)) newYear;
        mapping(address => mapping(uint => uint)) indexOf;
        mapping(address => mapping(uint => bool)) inserted;
    }

    function getKeys(Map storage map, address _Contract) internal view returns (uint[] memory, uint) {
        return (map.id[_Contract], map.id[_Contract].length);
    }

    function getOwner(Map storage map, address _Contract, uint _id) internal view returns (address) {
        return map.owner[_Contract][_id];
    }

    function getKeyAtIndex(Map storage map, address _Contract, uint _index) internal view returns (uint) {
        return map.id[_Contract][_index];
    }

    function isInserted(Map storage map, address _Contract, uint _id) internal view returns (bool) {
        return map.inserted[_Contract][_id];
    }

    function getTime(Map storage map, address _Contract, uint _id) internal view returns (
        uint _bookingTime, uint _bookedTime, uint _newYear
    ) {
        _bookingTime = map.bookingTime[_Contract][_id];
        _bookedTime = map.bookedTime[_Contract][_id];
        _newYear = map.newYear[_Contract][_id];
    }

    function set(
        Map storage map,
        address _Contract,
        uint _id,
        address _owner,
        uint _bookingTime,
        uint _bookedTime,
        uint _newYear
    ) internal {
        if (!map.inserted[_Contract][_id]) {
            map.inserted[_Contract][_id] = true;
            map.indexOf[_Contract][_id] = map.id[_Contract].length;
            map.id[_Contract].push(_id);

            map.owner[_Contract][_id] = _owner;
            map.bookingTime[_Contract][_id] = _bookingTime;
            map.bookedTime[_Contract][_id] = _bookedTime;
            map.newYear[_Contract][_id] = _newYear;
        }
    }

        
    function remove(Map storage map, address _Contract, uint _id) internal {
        if (!map.inserted[_Contract][_id]) {
            return;
        }

        delete map.inserted[_Contract][_id];
        delete map.owner[_Contract][_id];
        delete map.bookingTime[_Contract][_id];
        delete map.bookedTime[_Contract][_id];
        delete map.newYear[_Contract][_id];

        uint index = map.indexOf[_Contract][_id];
        uint lastIndex = map.id[_Contract].length - 1;
        uint lastKey = map.id[_Contract][lastIndex];

        map.indexOf[_Contract][lastKey] = index;
        delete map.indexOf[_Contract][_id];

        map.id[_Contract][index] = lastKey;
        map.id[_Contract].pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UserMapping {

    struct Map {
        address[] user;
        mapping(address => address[]) Contract;
        mapping(address => mapping(address => uint[])) tokens;
        mapping(address => mapping(address => uint)) indexOf;
        mapping(address => mapping(address => bool)) inserted;
    }

    function getTokens(Map storage map, address _contract, address key) internal view returns (uint[] memory) {
        return map.tokens[_contract][key];
    }

    function getAllContractAddress(Map storage map, address _user) internal view returns (address[] memory) {
        return map.Contract[_user];
    }

    function getUser(Map storage map) internal view returns (address[] memory) {
        return map.user;
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.user[index];
    }

    function getSize(Map storage map) internal view returns (uint) {
        return map.user.length;
    }

    function isInserted(Map storage map, address _contract, address key) internal view returns (bool) {
        return map.inserted[_contract][key];
    }

    function set(
        Map storage map,
        address _contract,
        address key,
        uint tokensID
    ) internal {
        if (map.inserted[_contract][key]) {
            map.tokens[_contract][key].push(tokensID);
        } else {
            map.inserted[_contract][key] = true;
            map.tokens[_contract][key].push(tokensID);
            map.indexOf[_contract][key] = map.user.length;
            map.Contract[key].push(_contract);
            map.user.push(key);
        }
    }

    function remove(Map storage map, address _contract, address key) internal {
        if (!map.inserted[_contract][key]) {
            return;
        }

        delete map.inserted[_contract][key];
        delete map.tokens[_contract][key];

        uint index = map.indexOf[_contract][key];
        uint lastIndex = map.user.length - 1;
        address lastKey = map.user[lastIndex];

        map.indexOf[_contract][lastKey] = index;
        delete map.indexOf[_contract][key];

        map.user[index] = lastKey;
        map.user.pop();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
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