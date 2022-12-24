/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/JayTradzStake.sol


pragma solidity ^0.8.9;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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






pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)



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






//create Staker struct that tracks listingId

contract JayTradzStake is Ownable, ERC1155Holder {
    using SafeMath for uint256;

    IERC1155 public nft;
    IERC20 public token;


mapping(uint256 => Monthly) public listIdToMonthly;
mapping(uint256 => Quarterly) public listIdToQuarterly;
mapping(uint256 => SemiAnnual) public listIdToSemiAnnually;
mapping(uint256 => uint256) public adminPoints;
mapping(uint256 => MTimer) public mTimers;
mapping(uint256 => QTimer) public qTimers;
mapping(uint256 => STimer) public sTimers;
mapping(address => uint256[]) public allMemberships;

mapping(uint256 => address) public referrers;
mapping(address => uint256) public refCodes;
mapping(address => uint256) public referralCount;

uint256 private totalReferralsM;
uint256 private totalReferralsQ;
uint256 private totalReferralsS;

uint256 public totalCapReachedRewardM;
uint256 public totalCapReachedReferralM;
uint256 public totalCapReachedRoyaltyM;
uint256 public totalCapReachedRewardQ;
uint256 public totalCapReachedReferralQ;
uint256 public totalCapReachedRoyaltyQ;
uint256 public totalCapReachedRewardS;
uint256 public totalCapReachedReferralS;
uint256 public totalCapReachedRoyaltyS;

uint256 public count = 0;
    
uint256 public itemsBurned = 0;

bool public claimPeriodActive;
bool public programEnded = false;
bool public kycActive = false;

uint256 adminPointsOutstanding;

uint256[] activeList;

mapping (address => bool) public dashboardAccess;
mapping (address => bool) private kycRegisteredUsers;




struct Monthly {


    bool isMonthly;
    uint256 listId;
    uint256 tokenId;
    address owner;
    uint256 amountPaid;
    uint256 previousReferralPoints;
    uint256 previousRoyaltyPoints;
    uint256 previousRewardPoints;
    uint256 currentReferralPoints;
    uint256 currentRoyaltyPoints;
    uint256 currentRewardPoints;
    uint256 gradBonus;
    bool gradBonusClaimed;
    
}
struct Quarterly {

    bool isQuarterly;
    uint256 listId;
    uint256 tokenId;
    address owner;
    uint256 amountPaid;
    uint256 previousReferralPoints;
    uint256 previousRoyaltyPoints;
    uint256 previousRewardPoints;
    uint256 currentReferralPoints;
    uint256 currentRoyaltyPoints;
    uint256 currentRewardPoints;
    uint256 gradBonus;
    bool gradBonusClaimed;
    
}
struct SemiAnnual {

    bool isSemiAnnual;
    uint256 listId;
    uint256 tokenId;
    address owner;
    uint256 amountPaid;
    uint256 previousReferralPoints;
    uint256 previousRoyaltyPoints;
    uint256 previousRewardPoints;
    uint256 currentReferralPoints;
    uint256 currentRoyaltyPoints;
    uint256 currentRewardPoints;
    uint256 gradBonus;
    bool gradBonusClaimed;
    
}

struct MTimer {

    uint256 listId;
    uint256 termStart;
    uint256 programStart;
    uint256 timeToNextClaim;
    uint256 graduationDate;
}

struct QTimer {

    uint256 listId;
    uint256 termStart;
    uint256 programStart;
    uint256 timeToNextClaim;
    uint256 graduationDate;
}

struct STimer {

    uint256 listId;
    uint256 termStart;
    uint256 programStart;
    uint256 timeToNextClaim;
    uint256 graduationDate;
}

struct Timer {
    uint256 programAge;
    uint256 timeLeft;
    uint256 previousMonth;
    uint256 previousQuarter;
    uint256 currentQuarter;
    uint256 previousHalf;
    uint256 currentHalf;
    uint256 currentMonth;
    uint256 previousYear;
    uint256 currentYear;
    
}

struct PaymentTracker {
    uint256 totalLastMonth;
    uint256 totalThisMonth;
    uint256 totalLastQuarter;
    uint256 totalThisQuarter;
    //uint256 totalLastHalf;
    //uint256 totalThisHalf;
    uint256 totalLastYear;
    uint256 totalThisYear;
    uint256 totalRevenueM;
    uint256 totalRevenueQ;
    uint256 totalRevenueS;
    uint256 totalGradBonusM;
    uint256 totalGradBonusQ;
    uint256 totalGradBonusS;
    uint256 totalPaid;
}

struct ReferralTracker {
    uint256 totalReferralM;
    uint256 totalReferralQ;
    uint256 totalReferralS;
}

mapping (uint8 => PaymentTracker) public paymentTracker;
mapping (uint8 => ReferralTracker) public referralTracker;
mapping (uint8 => Timer) public timer;

uint8 programs;

uint256 public INTERN_PRICE = 500000*10**6; //5000
uint256 public ASSOCIATE_PRICE = 10000*10**6; //10000
uint256 public EXECUTIVE_PRICE = 25000*10**6;//25000
uint256 public PRESIDENTIAL_PRICE = 50000*10**6;//50000
uint256 public CHAIRMAN_PRICE = 100000*10**6;//100000
uint256 public CORPORATE_PRICE = 250000*10**6;//250000

uint8 flight = 1;
uint8 hotel = 2;
uint8 concert = 3;
uint8 swag = 4;



event MonthlyStart(uint256, uint256, uint256);
event QuarterlyStart(uint256, uint256, uint256);
event SemiAnnualStart(uint256, uint256, uint256);
event AdminPointsAwarded(uint256, uint256);
event Payout(uint256, uint256);
event ProgramLaunch(uint256);
event ProgramEnd(uint256);
event ClaimPeriodOpen(uint256);
event ClaimPeriodClosed(uint256);
event Refund(address indexed, uint256);
event Flight(address indexed, uint256 indexed, uint256);
event Hotel(address indexed, uint256 indexed, uint256);
event Concert(address indexed, uint256 indexed, uint256);
event Swag(address indexed, uint256 indexed, uint256);

constructor(address _nft, address _token) {
    nft = IERC1155(_nft);
    token = IERC20(_token);
    launchProgram();
    dashboardAccess[msg.sender] = true;
    dashboardAccess[0x2B0a980C9c5b3aa1D6DeAe44536a9C98cB2FB42a] = true;
    dashboardAccess[0x3415b6ff71c86d5912c7545F6628876A9896df5E] = true;
}


//stake function that updates pricing


function launchProgram() public onlyOwner {
    programs = programs + 1;
    
    emit ProgramLaunch(block.timestamp);

}



function enterProgram(uint16 amount, uint256 tokenId, uint256 refCode) external  {
        uint256 listId;
        uint256 amountPaid;
        uint8 _type;

        require(referrers[refCode] != msg.sender, "Can't refer yourself");

        if(kycActive) {
            require(isKYCRegistered(msg.sender), "Not KYC Registered");
        }
        
        if(refCodes[msg.sender] == 0) {
            addReferralAddress(msg.sender);
        }

        
        if(tokenId == 1) {

                amountPaid = amount * INTERN_PRICE;
                _type = 0;
            } else if (tokenId == 2) {
                amountPaid = amount * INTERN_PRICE;
                _type = 1;
            } else if (tokenId == 3) {
                amountPaid = amount * INTERN_PRICE;
                _type = 2;
            } else if (tokenId == 4){
                amountPaid = amount * ASSOCIATE_PRICE;
                _type = 0;
            } else if (tokenId == 5){
                 amountPaid = amount * ASSOCIATE_PRICE;
                _type = 1;
            } else if (tokenId == 6){
                amountPaid = amount * ASSOCIATE_PRICE;
                _type = 2;
            } else if (tokenId == 7) {
                amountPaid = amount * EXECUTIVE_PRICE;
                _type = 0;
            } else if (tokenId == 8){
                amountPaid = amount * EXECUTIVE_PRICE;
                _type = 1;
            } else if (tokenId == 9){
                _type = 2;
            } else if (tokenId == 10) {
                amountPaid = amount * PRESIDENTIAL_PRICE;
                _type = 0;
            } else if (tokenId == 11){
                amountPaid = amount * PRESIDENTIAL_PRICE;
                _type = 1;
            } else if (tokenId == 12) {
                amountPaid = amount * PRESIDENTIAL_PRICE;
                _type = 2;
            } else if (tokenId == 13) {
                amountPaid = amount * CHAIRMAN_PRICE;
                _type = 0;
            } else if (tokenId == 14){
                amountPaid = amount * CHAIRMAN_PRICE;
                _type = 1;
            } else if (tokenId == 15){
                amountPaid = amount * CHAIRMAN_PRICE;
                _type = 2;
            } else if (tokenId == 16) {
                amountPaid = amount * CORPORATE_PRICE;
                _type = 0;
            } else if (tokenId == 17) {
                amountPaid = amount * CORPORATE_PRICE;
                _type = 1;
            } else if (tokenId == 18){
                amountPaid = amount * CORPORATE_PRICE;
                _type = 2;
            } else {
            revert("invalid tokenId input");
        }

        listId = count + 1;
        
    
        
            
            require(nft.balanceOf(msg.sender, tokenId) >= amount, "Not enough tokens");
            nft.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

            

            if(_type == 0) {

            if(referrers[refCode] != address(0)) {
            referralCount[referrers[refCode]]++;
            totalReferralsM++;
            referralTracker[programs].totalReferralM += amountPaid;
        }

            
            paymentTracker[programs].totalRevenueM += amountPaid;
                listIdToMonthly[listId] = Monthly(
            true,
            listId,
            tokenId,
            msg.sender,
            //100000000,//this amount is to test if the limits are correct
            amountPaid,
            0,
            0,
            0,
            0,
            0,
            0,
            amountPaid,
            false
               
        );

        mTimers[listId] = MTimer(
            listId,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            //block.timestamp + 15000
            block.timestamp + (86400 * 30 * 25)
        );



            } else if(_type == 1) {

                if(referrers[refCode] != address(0)) {
            referralCount[referrers[refCode]]++;
            totalReferralsQ++;
            referralTracker[programs].totalReferralQ += amountPaid;
        }

                paymentTracker[programs].totalRevenueQ += amountPaid;
               
                listIdToQuarterly[listId] = Quarterly(
            true,
            listId,
            tokenId,
            msg.sender,
            amountPaid,
            0,
            0,
            0,
            0,
            0,
            0,
            amountPaid,
            false
              
        );
        qTimers[listId] = QTimer(
            listId,
            block.timestamp,
            block.timestamp,
            //block.timestamp + 1500,
            block.timestamp + (86400 * 87),
            //block.timestamp + 10200
            block.timestamp + (86400 * 30 * 17)
        );
            } else {

                if(referrers[refCode] != address(0)) {
            referralCount[referrers[refCode]]++;
            totalReferralsS++;
            referralTracker[programs].totalReferralS += amountPaid;
        }

                paymentTracker[programs].totalRevenueS += amountPaid;
                listIdToSemiAnnually[listId] = SemiAnnual(
            true,
            listId,
            tokenId,
            msg.sender,
            amountPaid,
            0,
            0,
            0,
            0,
            0,
            0,
            amountPaid,
            false
               
        );

        sTimers[listId] = STimer(
            listId,
            block.timestamp,
            block.timestamp,
            //block.timestamp + 300,
            block.timestamp + (86400 * 177),
            //block.timestamp + 300
            block.timestamp + (86400 * 30 * 13)
        );
            }

            

        count++;
        allMemberships[msg.sender].push(listId);
        
        
        

        
       if(_type == 0) {
           emit MonthlyStart(amount, tokenId, refCode);
       } else if(_type == 1) {
           emit QuarterlyStart(amount, tokenId, refCode);
       } else {
           emit SemiAnnualStart(amount, tokenId, refCode);
       }

        

          
    }


//get owner's listIds

function getMemberships(address _addr) public view returns (uint256[] memory){
    return allMemberships[_addr];
}

function getTotalReferrals() public view returns (uint256) {
    return totalReferralsM + totalReferralsQ + totalReferralsS;
}

function canAccessDashboard(address _addr) external view returns (bool){
    return dashboardAccess[_addr];
}

function getTrueTokenID(uint256 listId) external view returns (uint256){
    uint256 trueId;

    if(listIdToMonthly[listId].isMonthly == true) {
        trueId = listIdToMonthly[listId].tokenId;
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        trueId = listIdToQuarterly[listId].tokenId;  
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        trueId = listIdToSemiAnnually[listId].tokenId;
    } else {
        revert("Invalid listId");
    }

    return trueId;
}

function getAmountPaid(uint256 listId) external view returns (uint256){
    uint256 amountPaid;

    if(listIdToMonthly[listId].isMonthly == true) {
        amountPaid = listIdToMonthly[listId].amountPaid;
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        amountPaid = listIdToQuarterly[listId].amountPaid;  
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        amountPaid = listIdToSemiAnnually[listId].amountPaid;
    } else {
        revert("Invalid listId");
    }

    return amountPaid;

}

function getPeriods() external view returns (uint256, uint256, uint256){
    uint256 month = timer[programs].currentMonth;
    uint256 quarter = timer[programs].currentQuarter;
    uint256 year = timer[programs].currentYear;

    return (month, quarter, year);
    
}

function getRefCode(address _addr) external view returns (uint256){
    return refCodes[_addr];
}

function getPreviousRewardPoints(uint256 listId) public view returns (uint256, bool) {
    uint256 previousReward;
    bool capReached;
    if(listIdToMonthly[listId].isMonthly == true) {
        previousReward = listIdToMonthly[listId].previousRewardPoints;
        if(previousReward >= listIdToMonthly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        previousReward = listIdToQuarterly[listId].previousRewardPoints;  
        if(previousReward >= listIdToQuarterly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        previousReward = listIdToSemiAnnually[listId].previousRewardPoints;
        if(previousReward >= listIdToSemiAnnually[listId].amountPaid) {
            capReached = true;
        }
    } else {
        revert("Invalid listId");
    }

    return (previousReward, capReached);

}
function getPreviousReferralPoints(uint256 listId) public view returns (uint256, bool) {
    uint256 previousReferral;
    bool capReached;
    if(listIdToMonthly[listId].isMonthly == true) {
        previousReferral = listIdToMonthly[listId].previousReferralPoints;
        if(previousReferral >= listIdToMonthly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        previousReferral = listIdToQuarterly[listId].previousReferralPoints;
        if(previousReferral >= listIdToQuarterly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        previousReferral = listIdToSemiAnnually[listId].previousReferralPoints;
        if(previousReferral >= listIdToSemiAnnually[listId].amountPaid) {
            capReached = true;
        }
        
    } else {
        revert("Invalid listId");
    }

    return (previousReferral, capReached);

}
function getPreviousRoyaltyPoints(uint256 listId) public view returns (uint256, bool) {
    uint256 previousRoyalty;
    bool capReached;
    if(listIdToMonthly[listId].isMonthly == true) {
        previousRoyalty = listIdToMonthly[listId].previousRoyaltyPoints;
        if(previousRoyalty >= listIdToMonthly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        previousRoyalty = listIdToQuarterly[listId].previousRoyaltyPoints;
        if(previousRoyalty >= listIdToQuarterly[listId].amountPaid) {
            capReached = true;
        }
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        previousRoyalty = listIdToSemiAnnually[listId].previousRoyaltyPoints;
        if(previousRoyalty >= listIdToSemiAnnually[listId].amountPaid) {
            capReached = true;
        }
    } else {
        revert("Invalid listId");
    }

    return (previousRoyalty, capReached);

}

function calculateGradBonus(uint256 listId) public view returns (bool) {
    bool addBonus = false;

    if(listIdToMonthly[listId].isMonthly == true) {
        if(!listIdToMonthly[listId].gradBonusClaimed && block.timestamp >= mTimers[listId].graduationDate) {
            addBonus = true;
        }  
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        if(!listIdToQuarterly[listId].gradBonusClaimed && block.timestamp >= qTimers[listId].graduationDate) {
        addBonus = true;
        }
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        if(!listIdToSemiAnnually[listId].gradBonusClaimed && block.timestamp >= sTimers[listId].graduationDate){
        addBonus = true;
        }
    } else {
        revert("Invalid listId");
    }

    return addBonus;
}


function claimGradBonus(uint256 listId) external {
    uint256 annBonus;

    if(listIdToMonthly[listId].isMonthly == true) {
        require(listIdToMonthly[listId].owner == msg.sender, "Must be the owner of the listId to claim gradBonus");
        annBonus = listIdToMonthly[listId].gradBonus;
        if(!listIdToMonthly[listId].gradBonusClaimed && block.timestamp >= mTimers[listId].graduationDate) {
            adminPoints[listId]+= annBonus;
            listIdToMonthly[listId].gradBonusClaimed = true;

        }  
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        require(listIdToQuarterly[listId].owner == msg.sender, "Must be the owner of the listId to claim gradBonus");
        annBonus = listIdToQuarterly[listId].gradBonus;
        if(!listIdToQuarterly[listId].gradBonusClaimed && block.timestamp >= qTimers[listId].graduationDate) {
        adminPoints[listId]+= annBonus;
            listIdToQuarterly[listId].gradBonusClaimed = true;
        }
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        require(listIdToSemiAnnually[listId].owner == msg.sender, "Must be the owner of the listId to claim gradBonus");
        annBonus = listIdToSemiAnnually[listId].gradBonus;
        if(!listIdToSemiAnnually[listId].gradBonusClaimed && block.timestamp >= sTimers[listId].graduationDate){
        adminPoints[listId]+= annBonus;
            listIdToSemiAnnually[listId].gradBonusClaimed = true;
        }
    } else {
        revert("Invalid listId");
    }

}


//create random referral code

function random(address _addr) private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _addr))) % 10000000000;
    }

function addReferralAddress(address _addr) private {

        uint256 _referralCode = random(_addr);
        refCodes[_addr] = _referralCode;
        referrers[_referralCode] = _addr;
    }



//payout function that checks 4 balances

function payout(uint256 listId, address _addr, uint256 _amount, bool cashPayout, uint8 _prize) external {
    uint256 id = listId;
    uint256 amount = _amount;
    require(claimPeriodActive, "Claim Period has ended");
    uint256 remainder;
    

    

    bool canClaim = true;

    (uint256 rewardPoints, uint256 referralPoints, uint256 royaltyPoints) = getPoints(listId, _addr);
    uint256 totalAdminPoints = adminPoints[id];
    

    bool gradBonus = calculateGradBonus(id);
    (,bool royalCap) = getPreviousRoyaltyPoints(id);
    (,bool referralCap) = getPreviousRoyaltyPoints(id);
    (,bool rewardCap) = getPreviousRoyaltyPoints(id);



    if(listIdToQuarterly[id].isQuarterly == true) {
        if(block.timestamp <= qTimers[id].timeToNextClaim) {
            canClaim = false; 
        } else {
            
            if(gradBonus) {
                
                
                adminPointsOutstanding+= listIdToQuarterly[id].amountPaid;
                paymentTracker[programs].totalGradBonusQ += listIdToQuarterly[id].amountPaid;
                
            }

            if(royalCap){
        totalCapReachedRoyaltyQ += listIdToQuarterly[id].amountPaid;
            }
            if(referralCap){
                totalCapReachedReferralQ += listIdToQuarterly[id].amountPaid;
            }
            if(rewardCap){
                totalCapReachedRewardQ += listIdToQuarterly[id].amountPaid;
            }
        }


    } else if(listIdToSemiAnnually[id].isSemiAnnual == true) {
        if(block.timestamp <= sTimers[id].timeToNextClaim) {
            canClaim = false;
        } else {
            
            if(gradBonus) {
                
                adminPointsOutstanding+= listIdToSemiAnnually[id].amountPaid;
                paymentTracker[programs].totalGradBonusS += listIdToSemiAnnually[id].amountPaid;
                
            }

             if(royalCap){
        totalCapReachedRoyaltyS += listIdToSemiAnnually[id].amountPaid;
            }
            if(referralCap){
                totalCapReachedReferralS += listIdToSemiAnnually[id].amountPaid;
            }
            if(rewardCap){
                totalCapReachedRewardS += listIdToSemiAnnually[id].amountPaid;
            }
        }
    } else if(listIdToMonthly[id].isMonthly == true) {
        
            if(gradBonus) {
                
                adminPointsOutstanding+= listIdToMonthly[id].amountPaid;
                paymentTracker[programs].totalGradBonusM += listIdToMonthly[id].amountPaid;
                
            }
            if(royalCap){
        totalCapReachedRoyaltyM += listIdToMonthly[id].amountPaid;
            }
            if(referralCap){
                totalCapReachedReferralM += listIdToMonthly[id].amountPaid;
            }
            if(rewardCap){
                totalCapReachedRewardM += listIdToMonthly[id].amountPaid;
            }
    }

    if(listIdToMonthly[id].isMonthly == true) {


    

    if(amount <= totalAdminPoints) {
            
            adminPoints[id] -= amount;
            

        } else {
            require(totalAdminPoints + rewardPoints + referralPoints + royaltyPoints >= amount, "Insufficient points available");
            remainder = amount - totalAdminPoints;
            adminPoints[id] = 0;
            if(remainder <= royaltyPoints) {
                
                listIdToMonthly[id].previousRoyaltyPoints += remainder;
                royaltyPoints -= remainder;
                listIdToMonthly[id].currentRoyaltyPoints = royaltyPoints;
                listIdToMonthly[id].currentRewardPoints = rewardPoints;
                listIdToMonthly[id].currentReferralPoints = referralPoints;




            } else {
                remainder -= royaltyPoints;
                listIdToMonthly[id].previousRoyaltyPoints += royaltyPoints;
                listIdToMonthly[id].currentRoyaltyPoints = 0;
                if(remainder <= referralPoints) {
                    
                    listIdToMonthly[id].previousReferralPoints += remainder;
                    referralPoints -= remainder;
                    listIdToMonthly[id].currentReferralPoints = referralPoints;
                    listIdToMonthly[id].currentRewardPoints = rewardPoints;

                } else {
                    remainder -= referralPoints;
                    listIdToMonthly[id].previousReferralPoints += referralPoints;
                    listIdToMonthly[id].currentReferralPoints = 0;
                    if(remainder <= rewardPoints) {
                        
                        listIdToMonthly[id].previousRewardPoints += remainder;
                        rewardPoints -= remainder;
                        listIdToMonthly[id].currentRewardPoints = rewardPoints;
                    } else {
                        revert("Insufficient balance");
                    }
                }

            }
        } 
        mTimers[id].timeToNextClaim = block.timestamp;
        mTimers[id].termStart = block.timestamp;



        
    } else if(listIdToQuarterly[id].isQuarterly == true) {
        if(canClaim) {
            if(amount <= totalAdminPoints) {
                adminPoints[id] -= amount;
            } else {
                require(totalAdminPoints + rewardPoints + referralPoints + royaltyPoints >= amount, "Insufficient points available");
            remainder = amount - totalAdminPoints;
            adminPoints[id] = 0;
            if(remainder <= royaltyPoints) {
                
                listIdToQuarterly[id].previousRoyaltyPoints += remainder;
                royaltyPoints -= remainder;
                listIdToQuarterly[id].currentRoyaltyPoints = royaltyPoints;
                listIdToQuarterly[id].currentRewardPoints = rewardPoints;
                listIdToQuarterly[id].currentReferralPoints = referralPoints;


            } else {
                remainder -= royaltyPoints;
                listIdToQuarterly[id].previousRoyaltyPoints += royaltyPoints;
                listIdToQuarterly[id].currentRoyaltyPoints = 0;
                if(remainder <= referralPoints) {
                    
                    listIdToQuarterly[id].previousReferralPoints += remainder;
                    referralPoints -= remainder;
                    listIdToQuarterly[id].currentReferralPoints = referralPoints;
                    listIdToQuarterly[id].currentRewardPoints = rewardPoints;

                } else {
                    remainder -= referralPoints;
                    listIdToQuarterly[id].previousReferralPoints += referralPoints;
                    listIdToQuarterly[id].currentReferralPoints = 0;
                    if(remainder <= rewardPoints) {
                        
                        listIdToQuarterly[id].previousRewardPoints += remainder;
                        rewardPoints -= remainder;
                        listIdToQuarterly[id].currentRewardPoints = rewardPoints;
                    } else {
                        revert("Insufficient balance");
                    }
                }

            }
        } 
        
        //qTimers[id].timeToNextClaim = block.timestamp + 1500;
        qTimers[id].timeToNextClaim = block.timestamp + (86400 * 87);
        qTimers[id].termStart = block.timestamp;



        } else {
            require(amount <= totalAdminPoints + referralPoints + royaltyPoints, "Insufficient admin and referral balance. Please wait until your next claim period");

            if(amount <= totalAdminPoints){
                adminPoints[id] -= amount;
            } else {
                remainder = amount - totalAdminPoints;
                adminPoints[id] = 0;
                
                if(remainder <= royaltyPoints) {
                    listIdToQuarterly[id].previousRoyaltyPoints += remainder;
                    royaltyPoints -= remainder;
                    listIdToQuarterly[id].currentRoyaltyPoints = royaltyPoints;
                    listIdToQuarterly[id].currentRewardPoints = rewardPoints;
                listIdToQuarterly[id].currentReferralPoints = referralPoints;
                } else {
                    remainder -= royaltyPoints;
                    listIdToQuarterly[id].previousRoyaltyPoints += royaltyPoints;
                    listIdToQuarterly[id].currentRoyaltyPoints = 0;
                    listIdToQuarterly[id].previousReferralPoints += remainder;
                    listIdToQuarterly[id].currentReferralPoints = referralPoints - remainder;
                    listIdToQuarterly[id].currentRewardPoints = rewardPoints;

            }
        }
        }
            
        
            
         

    } else if(listIdToSemiAnnually[id].isSemiAnnual == true) {
        if(canClaim) {
            if(amount <= totalAdminPoints) {
            adminPoints[id] -= amount;
            } else {
                require(totalAdminPoints + rewardPoints + referralPoints + royaltyPoints >= amount, "Insufficient points available");
                remainder = amount - totalAdminPoints;
                adminPoints[id] = 0;
                if(remainder <= royaltyPoints) {
                    listIdToSemiAnnually[id].previousRoyaltyPoints += remainder;
                    royaltyPoints -= remainder;
                    listIdToSemiAnnually[id].currentRoyaltyPoints = royaltyPoints;
                    listIdToSemiAnnually[id].currentRewardPoints = rewardPoints;
                    listIdToSemiAnnually[id].currentReferralPoints = referralPoints;
                    } else {
                        remainder -= royaltyPoints;
                        listIdToSemiAnnually[id].previousRoyaltyPoints += royaltyPoints;
                        listIdToSemiAnnually[id].currentRoyaltyPoints = 0;
                        if(remainder <= referralPoints) {
                            listIdToSemiAnnually[id].previousReferralPoints += remainder;
                            referralPoints -= remainder;
                            listIdToSemiAnnually[id].currentReferralPoints = referralPoints;
                            listIdToSemiAnnually[id].currentRewardPoints = rewardPoints;
                            } else {
                                remainder -= referralPoints;
                                listIdToSemiAnnually[id].previousReferralPoints += referralPoints;
                                listIdToSemiAnnually[id].currentReferralPoints = 0;
                                if(remainder <= rewardPoints) {
                                    listIdToSemiAnnually[id].previousRewardPoints += remainder;
                                    rewardPoints -= remainder;
                                    listIdToSemiAnnually[id].currentRewardPoints = rewardPoints;
                                    } else {
                                        revert("Insufficient balance");
                                        }
                                }
                        }
            } 
            //sTimers[id].timeToNextClaim = block.timestamp + 3000;
            sTimers[id].timeToNextClaim = block.timestamp + (86400*177);
            sTimers[id].termStart = block.timestamp;
            
        } 
            
            else {
            require(amount <= totalAdminPoints + referralPoints + royaltyPoints, "Insufficient admin and referral balance. Please wait until your next claim period");

            if(amount <= totalAdminPoints){
                adminPoints[id] -= amount;
            } else {
                uint256 deduction = amount - totalAdminPoints;
                adminPoints[id] = 0;
                if(deduction <= royaltyPoints) {
                
                listIdToSemiAnnually[id].previousRoyaltyPoints += deduction;
                royaltyPoints -= deduction;
                listIdToSemiAnnually[id].currentRoyaltyPoints = royaltyPoints;
                listIdToSemiAnnually[id].currentRewardPoints = rewardPoints;
                listIdToSemiAnnually[id].currentReferralPoints = referralPoints;
                } else {
                deduction -= royaltyPoints;
                listIdToSemiAnnually[id].previousRoyaltyPoints += royaltyPoints;
                listIdToSemiAnnually[id].currentRoyaltyPoints = 0;
                listIdToSemiAnnually[id].previousReferralPoints += deduction;
                listIdToSemiAnnually[id].currentReferralPoints = referralPoints - deduction;
                listIdToSemiAnnually[id].currentRewardPoints = rewardPoints;

            }
        }
        }
    } else {
        revert("Cannot withdraw at this time");
    }

    paymentTracker[programs].totalThisMonth+= amount;
    paymentTracker[programs].totalThisQuarter+= amount;
    //paymentTracker[programs].totalThisHalf+= amount;
    paymentTracker[programs].totalThisYear+= amount;
    paymentTracker[programs].totalPaid+= amount;


    if(cashPayout) {
        token.transferFrom(owner(), msg.sender, amount);
        emit Payout(id, amount);
    } else {
        if(_prize == flight) {
            emit Flight(msg.sender, id, amount);
        } else if (_prize == hotel) {
            emit Hotel(msg.sender, id, amount);
        } else if (_prize == concert){
            emit Concert(msg.sender, id, amount);
        } else if (_prize == swag){
            emit Swag(msg.sender, id, amount);
        } else {
            revert("Invalid prize id");
        }
    }
    
}



//get individualPoints

function getAdminPoints(uint256 listId) public view returns (uint256) {
    return adminPoints[listId];
}

function getRewardThisPeriod(uint256 id) internal view returns (uint256) {
    uint256 _reward;
    uint256 amountPaid;
    if(listIdToMonthly[id].isMonthly == true) {
        amountPaid = listIdToMonthly[id].amountPaid;

        _reward = amountPaid.mul(4).div(100);
        
        
    } else if (listIdToQuarterly[id].isQuarterly == true) {

        amountPaid = listIdToQuarterly[id].amountPaid;
        
       _reward = amountPaid.mul(6).div(100);
        


    } else if (listIdToSemiAnnually[id].isSemiAnnual == true) {

        amountPaid = listIdToSemiAnnually[id].amountPaid;
        
        _reward = amountPaid.mul(833).div(10000);
        
    } 
    return _reward;
}

function calculateRewardPoints(uint256 id) internal view returns (uint256){
    (uint256 time, 
    uint256 currentRewardPoints, 
    , 
    , 
    uint256 amountPaid) = getTime(id);

    (uint256 pastRewards, ) = getPreviousRewardPoints(id);

    uint256 rewardThisPeriod = getRewardThisPeriod(id);


    uint256 rewardPointsThisPeriod = time * rewardThisPeriod.div(30).div(86400);

    if(pastRewards >= amountPaid) {
            rewardPointsThisPeriod = 0;
            currentRewardPoints = 0;
        } else if (pastRewards + rewardPointsThisPeriod + currentRewardPoints > amountPaid) {
            rewardPointsThisPeriod = amountPaid - pastRewards;
            currentRewardPoints = 0;
        }
        else if(rewardPointsThisPeriod + currentRewardPoints > amountPaid) {
            rewardPointsThisPeriod = amountPaid;
            currentRewardPoints = 0;
        }

    return rewardPointsThisPeriod + currentRewardPoints;
}





function getPoints(uint256 listId, address _addr) public view returns (uint256, uint256, uint256) {

    uint256 id = listId;
    (uint256 time, 
    , 
    uint256 currentReferralPoints, 
    uint256 currentRoyaltyPoints, 
    uint256 amountPaid) = getTime(listId);

    
    (uint256 pastReferrals, ) = getPreviousReferralPoints(listId);
    (uint256 pastRoyalties,) = getPreviousRoyaltyPoints(listId);

    uint256 refCount = referralCount[_addr];
    

    uint256 referralThisPeriod = refCount * (amountPaid.mul(5).div(100));
    uint256 royaltyThisPeriod = refCount * (amountPaid/100); 
    

    uint256 rewardPointsThisPeriod = calculateRewardPoints(id);
    uint256 referralPointsThisPeriod = time * referralThisPeriod.div(30).div(86400);
    uint256 royaltyPointsThisPeriod = time * royaltyThisPeriod.div(30).div(86400);
        
        
        
        if(pastReferrals >= amountPaid) {
            referralPointsThisPeriod = 0;
            currentReferralPoints = 0;
        } else if (pastReferrals + referralPointsThisPeriod + currentReferralPoints > amountPaid) {
            referralPointsThisPeriod = amountPaid - pastReferrals;
            currentReferralPoints = 0;
        }
        else if(referralPointsThisPeriod + currentReferralPoints > amountPaid) {
            referralPointsThisPeriod = amountPaid;  
            currentReferralPoints = 0;
        }

        
        
        if(pastRoyalties >= amountPaid) {
            royaltyPointsThisPeriod = 0;
            currentRoyaltyPoints = 0;
        } else if (pastRoyalties + royaltyPointsThisPeriod + currentRoyaltyPoints > amountPaid) {
            royaltyPointsThisPeriod = amountPaid - pastRoyalties;
            currentRoyaltyPoints = 0;
        }
        else if(royaltyPointsThisPeriod + currentRoyaltyPoints > amountPaid) {
            royaltyPointsThisPeriod = amountPaid;
            currentRoyaltyPoints = 0;
        }
        

        return (rewardPointsThisPeriod, (referralPointsThisPeriod + currentReferralPoints), (royaltyPointsThisPeriod + currentRoyaltyPoints));


}

function getTime(uint256 listId) public view returns (uint256, uint256, uint256, uint256, uint256) {
    uint256 time;
    uint256 currentReferralPoints;
    uint256 currentRewardPoints;
    uint256 currentRoyaltyPoints;
    uint256 amountPaid;

    if(listIdToMonthly[listId].isMonthly == true) {
        time = block.timestamp - mTimers[listId].termStart;
        currentReferralPoints = listIdToMonthly[listId].currentReferralPoints;
        currentRewardPoints = listIdToMonthly[listId].currentRewardPoints;
        currentRoyaltyPoints = listIdToMonthly[listId].currentRoyaltyPoints;
        
        amountPaid = listIdToMonthly[listId].amountPaid;
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        time = block.timestamp - qTimers[listId].termStart;
        currentReferralPoints = listIdToQuarterly[listId].currentReferralPoints;
        currentRewardPoints = listIdToQuarterly[listId].currentRewardPoints;
        currentRoyaltyPoints = listIdToQuarterly[listId].currentRoyaltyPoints;
        amountPaid = listIdToQuarterly[listId].amountPaid;
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        time = block.timestamp - sTimers[listId].termStart;
        currentReferralPoints = listIdToSemiAnnually[listId].currentReferralPoints;
        currentRewardPoints = listIdToSemiAnnually[listId].currentRewardPoints;
        currentRoyaltyPoints = listIdToSemiAnnually[listId].currentRoyaltyPoints;
        amountPaid = listIdToSemiAnnually[listId].amountPaid;
    } else {
        revert("Invalid listId");
    }

    return (time, currentRewardPoints, currentReferralPoints, currentRoyaltyPoints, amountPaid);


}


//estimate payout monthly, quarterly, semiannually

function getEstimates() external view returns (uint256, uint256, uint256) {

    uint256 totalCapReachedM = totalCapReachedRewardM + totalCapReachedReferralM + totalCapReachedRoyaltyM;
    uint256 totalCapReachedQ = totalCapReachedRewardQ + totalCapReachedReferralQ + totalCapReachedRoyaltyQ;
    uint256 totalCapReachedS = totalCapReachedRewardS + totalCapReachedReferralS + totalCapReachedRoyaltyS;
   

    uint256 adminPointsDue = getAdminPointsOutstanding();

    uint256 monthlyTotalPY = paymentTracker[programs].totalRevenueM - paymentTracker[programs].totalGradBonusM - totalCapReachedM;
    uint256 quarterlyTotalPY = paymentTracker[programs].totalRevenueQ - paymentTracker[programs].totalGradBonusQ - totalCapReachedQ;
    uint256 semiTotalPY = paymentTracker[programs].totalRevenueS - paymentTracker[programs].totalGradBonusS - totalCapReachedS;

    uint256 monthlyTotalR = (referralTracker[programs].totalReferralM).mul(6).div(100);
    uint256 quarterlyTotalR = (referralTracker[programs].totalReferralQ).mul(6).div(100);
    uint256 semiTotalR = (referralTracker[programs].totalReferralS).mul(6).div(100);

    uint256 monthlyTotal = (monthlyTotalPY.mul(4).div(100)) + monthlyTotalR + adminPointsDue;
    uint256 quarterlyTotal = (quarterlyTotalPY.mul(6).div(100)) + quarterlyTotalR + adminPointsDue;
    uint256 semiTotal = (semiTotalPY.mul(833).div(100000)) + semiTotalR + adminPointsDue;

    return (monthlyTotal, quarterlyTotal, semiTotal);
    

    


    

}


//open claimperiod function

function getTimeLeft() external view returns (uint256) {
    return timer[programs].timeLeft - block.timestamp;
}

function getAdminPointsOutstanding() internal view returns (uint256) {
    return adminPointsOutstanding;
}


function openClaimPeriod() external onlyOwner {
    claimPeriodActive = true;
    timer[programs].timeLeft = block.timestamp + 3 days;

    emit ClaimPeriodOpen(block.timestamp);
}



//close claim period function that updates the month, quarter, year

function closeClaimPeriod() external onlyOwner {
    require(claimPeriodActive, "Claim Period already closed");
    claimPeriodActive = false;
    uint256 nextMonth = timer[programs].currentMonth + 1;
    uint256 thisMonth = timer[programs].currentMonth;
    
    //uint256 thisHalf = timer[programs].currentHalf;
    //uint256 nextHalf = timer[programs].currentHalf + 1;
    
    timer[programs].previousMonth = thisMonth;
    timer[programs].currentMonth = nextMonth;

    uint256 currentMPayments = paymentTracker[programs].totalThisMonth;
    paymentTracker[programs].totalLastMonth = currentMPayments;
    paymentTracker[programs].totalThisMonth = 0;



    if(nextMonth % 3 == 0) {
        uint256 thisQuarter = timer[programs].currentQuarter;
        uint256 nextQuarter = timer[programs].currentQuarter + 1;
        timer[programs].previousQuarter = thisQuarter;
        timer[programs].currentQuarter = nextQuarter;
        

        uint256 currentQPayments = paymentTracker[programs].totalThisQuarter;
        paymentTracker[programs].totalLastQuarter = currentQPayments;
        paymentTracker[programs].totalThisQuarter = 0;
    
    }
/*
    if(nextMonth % 6 == 0) {
        timer[programs].previousHalf = thisHalf;
        timer[programs].currentHalf = nextHalf;

        uint256 currentHPayments = paymentTracker[programs].totalThisHalf;

        paymentTracker[programs].totalLastHalf = currentHPayments;
        paymentTracker[programs].totalThisHalf = 0;
    }*/

    if(nextMonth % 12 == 0) {
        uint256 thisYear = timer[programs].currentYear;
        uint256 nextYear = timer[programs].currentYear + 1;
        timer[programs].previousYear = thisYear;
        timer[programs].currentYear = nextYear;
        timer[programs].currentMonth = 0;
        timer[programs].currentQuarter = 0;
        timer[programs].currentHalf = 0;

        uint256 currentYPayments = paymentTracker[programs].totalThisYear;

        paymentTracker[programs].totalLastYear = currentYPayments;
        paymentTracker[programs].totalThisYear = 0;
    }

    emit ClaimPeriodClosed(block.timestamp);



}

function endProgram() external onlyOwner {
    programEnded = true;

    emit ProgramEnd(block.timestamp);
}



//refund function that checks if a person has been paid grad bonus or is past 3 months

function refund(uint256 listId) external {
    uint256 _refund;
    if(programEnded){
        if(listIdToMonthly[listId].isMonthly == true) {
        require(!listIdToMonthly[listId].gradBonusClaimed, "Ineligible for refund. Graduation bonus already claimed");
        _refund = listIdToMonthly[listId].amountPaid;
        } else if(listIdToQuarterly[listId].isQuarterly == true) {
        require(!listIdToQuarterly[listId].gradBonusClaimed, "Ineligible for refund. Graduation bonus already claimed");
        _refund = listIdToQuarterly[listId].amountPaid;
        } else {
            require(!listIdToSemiAnnually[listId].gradBonusClaimed, "Ineligible for refund. Graduation bonus already claimed");
        _refund = listIdToSemiAnnually[listId].amountPaid;
        }
        token.transferFrom(owner(), msg.sender, _refund);

    } else {

    
    if(listIdToMonthly[listId].isMonthly == true) {
        require(block.timestamp < mTimers[listId].programStart + 90 days, "Refund period expired");
        _refund = listIdToMonthly[listId].amountPaid;
        delete listIdToMonthly[listId];
    } else if (listIdToQuarterly[listId].isQuarterly == true) {
        require(block.timestamp < qTimers[listId].programStart + 90 days, "Refund period expired");
        _refund = listIdToQuarterly[listId].amountPaid;
        delete listIdToQuarterly[listId];
    } else if (listIdToSemiAnnually[listId].isSemiAnnual == true) {
        require(block.timestamp < sTimers[listId].programStart + 90 days, "Refund period expired");
        _refund = listIdToSemiAnnually[listId].amountPaid;
        delete listIdToSemiAnnually[listId];
    } else {
        revert("Invalid listId");
    }
    token.transferFrom(owner(), msg.sender, _refund);
    }

    emit Refund(msg.sender, _refund);
}



//send admin points function to allow owner to reward people


function sendAdminPoints(uint256 listId, uint256 _points) external onlyOwner {
    uint256 points = _points * 10**6;
    adminPoints[listId]+= points;
    adminPointsOutstanding += points;

    emit AdminPointsAwarded(listId, points);
}

function approveDashboardAccess(address _addr) public onlyOwner {
    dashboardAccess[_addr] = true;
}

   function isKYCRegistered(address _user) public view returns (bool) {
    return kycRegisteredUsers[_user];
  }

  
  function addKYCRegisteredUser(address[] calldata _users) external onlyOwner {
    // ["","",""]
    for(uint i=0;i<_users.length;i++)
        kycRegisteredUsers[_users[i]] = true;
  }

  function removeKYCRegisteredUser(address[] calldata _users) public onlyOwner {
    // ["","",""]
    for(uint i=0;i<_users.length;i++)
        kycRegisteredUsers[_users[i]] = false;
  }


function toggleKYC() external onlyOwner{
    kycActive = !kycActive;
}

}