// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../utils/KarmSentry.sol";

import "../interfaces/iKarmIndividual.sol";

contract KarmSimpleRater is KarmSentry {
    using SafeMath for uint256;

    iKarmIndividual KI;

    uint256 private ratingID;

    mapping ( address => uint256 ) private isRated;

    uint256 private rateLimit;

    mapping ( uint256 => uint256 ) private counter;

    uint256 private minValues;

    uint256 private maxValues;

    modifier isValidRating( uint256 _min , uint256 _max , uint256 _rate ){
        require( isRated[msg.sender] <= rateLimit , "KarmSimpleRater : Rate Limit Exceeded");
        require( _rate > _min ,"KarmSimpleRater : Rating out of bound");
        require( _rate <= _max ,"KarmSimpleRater : Rating out of bound");
        _;
    }

    event rateEvent( uint256 indexed _id , uint256 _min , uint256 _max , uint256 _rating , uint256 _newRating );

    constructor( address _addr , uint256 _ratingID , uint256 _minValues , uint256 _maxValues ) KarmSentry() {
        KI = iKarmIndividual(_addr);
        rateLimit = 10;
        minValues = _minValues;
        maxValues = _maxValues;
        ratingID = _ratingID;
    }

    function activation( address _gov ) external {
        activate(_gov);
    }

    function setRateLimit( uint256 _limit ) isGov external {
        rateLimit = _limit;
    }

    function setRateID( uint256 _ID ) isGov external {
        ratingID = _ID;
    }

    function rate( uint256 _individualID , uint256 _minValue , uint256 _maxValues , uint256 _rating ) isValidRating( _minValue , _maxValues , _rating ) external {
        uint256 prvRating = KI.fetchRating( _individualID , ratingID );
        uint256 nCtr = counter[_individualID].add(1);
        uint256 newRating = normalize(counter[_individualID] , nCtr , prvRating , _minValue , _maxValues , _rating , minValues ,maxValues );
        KI.setRating(_individualID , ratingID , newRating);
        counter[_individualID] = nCtr;
        isRated[msg.sender] = isRated[msg.sender].add(1);
        emit rateEvent( _individualID , _minValue , _maxValues , _rating, newRating);
    }

    function normalize(
        uint256 ctr0,
        uint256 ctr1,
        uint256 prevRating,
        uint256 _SMin,
        uint256 _SMax,
        uint256 _rating,
        uint256 miR,
        uint256 maR
    ) internal pure returns (uint256 value) {
        value = _rating.sub(_SMin);
        value = value.mul(maR.sub(miR));
        value = value.div(_SMax.sub(_SMin));
        value = (value.add(prevRating.mul(ctr0))).div(ctr1);
    }

    function fetchMinValues ( ) external view returns ( uint256 ){
        return minValues;
    }

    function fetchMaxValues ( ) external view returns ( uint256 ){
        return maxValues;
    }

    function fetchRateLimit ( ) external view returns ( uint256 ){
        return rateLimit;
    }

    function fetchUserRateLimit ( address _addr ) external view returns ( uint256 ){
        return isRated[_addr];
    }

    function fetchTokenCounter ( uint256 _id ) external view returns ( uint256 ){
        return counter[_id];
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
pragma solidity ^0.8.0;

contract KarmSentry {

    address private Governance;

    address private deployer;

    bool private active;

    modifier isDeployer(){
        require(msg.sender == deployer, "KarmSentry: Sender is not deployer");
        _;
    }

    modifier isInActive(){
        require(active == false, "KarmSentry: contract is active");
        _;
    }

    modifier isActive(){
        require(active == true, "KarmSentry: contract is not active");
        _;
    }

    modifier isGov() {
        require( msg.sender == Governance , "KarmSentry: Invalid Governance Address");
        _;
    }

    constructor ( ) {
        deployer = msg.sender;
        active = false;
    }

    function activate( address _Governance ) internal isDeployer isInActive {
        deployer = address(0);
        Governance = _Governance;
        active = true;
    }

    function fetchGovernance( ) external view returns ( address ) {
        return Governance;
    }

    function fetchDeployer( ) external view returns ( address ) {
        return deployer;
    }

    function fetchActive( ) external view returns ( bool ) {
        return active;
    }

    function setGovernance( address _governance ) external isGov isActive {
        require( Governance != address(this) , "KarmSentry : Cant Governance of MetaDAOCouncil");
        Governance = _governance;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface iKarmIndividual is IERC721 {

    struct IndividualStruct {
        uint256 collectionID;
        string name;
        string uri;
        bool status;
    }

    function activatation( address _gov ) external;

    function setMinter( address _addr ) external;

    function unsetMinter( address _addr ) external;

    function setRater( address _addr ) external;

    function unsetRater( address _addr ) external;

    function pauseToken() external returns (bool);

    function unpauseToken() external returns (bool);

    function mint( address to, uint256 collectionID, string memory uri, string memory name) external returns (bool);

    function setRating( uint256 _tokenID , uint256 _ratingMethod , uint256 _rating ) external;

    function fetchRating( uint256 _tokenID , uint256 _ratingMethod ) external view returns ( uint256 );

    function fetchIndividualInfo( uint256 _id ) external view returns ( IndividualStruct memory );

    function fetchisMinter( address _addr ) external view returns ( bool );


    function totalSupply() external view returns (uint256);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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