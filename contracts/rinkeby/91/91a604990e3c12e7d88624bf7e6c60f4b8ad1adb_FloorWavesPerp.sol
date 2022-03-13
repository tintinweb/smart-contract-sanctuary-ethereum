/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library StringUtils {
    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function notEquals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return !equals(a, b);
    }

    function empty(string memory a)
        internal
        pure
        returns (bool)
    {
        return equals(a, "");
    }

    function notEmpty(string memory a)
        internal
        pure
        returns (bool)
    {
        return !empty(a);
    }
}

// LibCLL using `string` keys
library LibCLLs {
    using StringUtils for string;

    bytes32 public constant VERSION = "LibCLLs 0.4.1";
    string constant NULL = "0";
    string constant HEAD = "0";
    bool constant PREV = false;
    bool constant NEXT = true;

    struct CLL {
        mapping(string => mapping(bool => string)) cll;
    }

    // n: node id  d: direction  r: return node id

    // Return existential state of a list.
    function exists(CLL storage self) internal view returns (bool) {
        return
            self.cll[HEAD][PREV].notEquals(HEAD) ||
            self.cll[HEAD][NEXT].notEquals(HEAD);
    }

    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal view returns (uint256) {
        uint256 r = 0;
        string memory i = step(self, HEAD, NEXT);
        while (i.notEquals(HEAD)) {
            i = step(self, i, NEXT);
            r++;
        }
        return r;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, string memory n)
        internal
        view
        returns (string[2] memory)
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(
        CLL storage self,
        string memory n,
        bool d
    ) internal view returns (string memory) {
        return self.cll[n][d];
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(
        CLL storage self,
        string memory a,
        string memory b,
        bool d
    ) internal {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert(
        CLL storage self,
        string memory a,
        string memory b,
        bool d
    ) internal {
        string memory c = self.cll[a][d];
        stitch(self, a, b, d);
        stitch(self, b, c, d);
    }

    // Remove node
    function remove(CLL storage self, string memory n)
        internal
        returns (string memory)
    {
        if (n.equals(NULL)) return n;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    // Push a new node before or after the head
    function push(
        CLL storage self,
        string memory n,
        bool d
    ) public {
        insert(self, HEAD, n, d);
    }

    // Pop a new node from before or after the head
    function pop(CLL storage self, bool d) internal returns (string memory) {
        return remove(self, step(self, HEAD, d));
    }
}

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

/**
 * @title Types
 * @author FloorWaves
 *
 * @dev Library for common types used in FloorWaves contracts.
 */
library Types {
    using StringUtils for string;
    using SafeMath for uint256;

    // ============ Enums ============

    enum OrderType {
        LONG,
        SHORT
    }

    // ============ Structs ============

    struct Order {
        uint256 margin;
        uint256 floorPrice;
        OrderType orderType;
    }

    struct OrderDetails {
        Order order;
        address creator;
        address underlyingAsset;
        uint256 fwNFTtokenID;
    }

    function getMatchOrder(Order memory self, uint256 _margin)
        internal
        pure
        returns (Order memory)
    {
        Types.Order memory matchOrder;
        matchOrder.margin = _margin;
        matchOrder.floorPrice = self.floorPrice;
        matchOrder.orderType = getMatchOrderType(self);
        return matchOrder;
    }

    function getMatchOrderType(Order memory self)
        internal
        pure
        returns (OrderType)
    {
        return
            (self.orderType == OrderType.LONG)
                ? OrderType.SHORT
                : OrderType.LONG;
    }

    function isLeverageAllowed(Order memory self, uint256 maxLeverage)
        internal
        pure
        returns (bool)
    {
        return
            (self.floorPrice >= self.margin) &&
            (self.floorPrice <= self.margin.mul(maxLeverage));
    }

    // TODO Suggestion: Let's split the margin from the position value in the future.
    function getPositionValue(Order memory self, uint256 currentFloor)
        internal
        pure
        returns (uint256)
    {
        if (
            self.orderType == OrderType.LONG && currentFloor >= self.floorPrice
        ) {
            // LONG made profit
            return (currentFloor.sub(self.floorPrice)).add(self.margin);
        } else if (self.orderType == OrderType.LONG) {
            // LONG made loss
            uint256 floorDiff = self.floorPrice.sub(currentFloor);
            require(
                floorDiff <= self.margin,
                "Types: Order loss for LONG is greater than margin present"
            );
            return self.margin.sub(floorDiff);
        } else if (
            self.orderType == OrderType.SHORT && currentFloor <= self.floorPrice
        ) {
            // SHORT made profit
            return (self.floorPrice.sub(currentFloor)).add(self.margin);
        } else {
            // SHORT made loss
            uint256 floorDiff = currentFloor.sub(self.floorPrice);
            require(
                floorDiff <= self.margin,
                "Types: Order loss for SHORT is greater than margin present"
            );
            return self.margin.sub(floorDiff);
        }
    }
}


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

interface IFloorWavesNFT is IERC721 {
    function safeMint(address to, Types.OrderDetails memory _props) external;

    function getOrderDetails(uint256 tokenId)
        external
        view
        returns (Types.OrderDetails memory);

    function burn(uint256 tokenId) external;
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

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

/**
 * @title FloorWavesPerp contract
 * @author FloorWaves
 * @notice Main point of interaction with an FloorWaves protocol's market
 * - Users can:
 *   # Create a limit order
 *   # Create a market order (match with any limit order in the order book)
 *   # Create a limit for an existing position at which to exit
 *   # Close an existing position by matching with a limit order of another existing position
 *   # Cancle an order
 * @dev This code is still a beta version.
 * Contract is deployed on Rinkeby testnet at 0xce2f61758C1fc60789d8c6E0e5c4aa44907807f6
 **/
contract FloorWavesPerp is Ownable {
    using StringUtils for string;
    using SafeMath for uint256;
    using Types for Types.Order;
    using LibCLLs for LibCLLs.CLL;

    // string will represent the unique value which will have order stored against it
    // global map containing only open orders across all markets
    mapping(string => Types.OrderDetails) public orderMap;

    //TODO Market essentially means NFT project for whom we are enabling future projects
    //TODO Check if market is inactive and usecase is handled
    struct Market {
        // doubly linked list for indexing open orders
        LibCLLs.CLL ordersIndex;
        // address of the underlying asset used
        address underlyingAsset;
        // boolean used to start or stop accepting orders from accounts.
        bool paused;
    }

    // mapping for underlyingAsset => Market struct storing all orders
    mapping(address => Market) internal nftMarketMap;

    // list of addresses of all underlyingAssets registered as markets
    address[] public marketsList;

    // mapping for user => DLL for orders
    // This is independent of markets
    mapping(address => LibCLLs.CLL) internal userOrdersMap;

    //MAX LEVERAGE ALLOWED
    // TODO: for support upto 5 decimal places;
    uint256 public MAX_LEVERAGE = 5;

    uint256 public LIQUIDATION_FEE_PERCENT = 2;

    uint256 public TRADING_FEE_PERCENT = 2;

    //TOKEN WE ACCEPT FOR MARGIN AMOUNT
    //TODO: So far base token can be any token, for now I think should only be WETH
    // Case: Alice creates a market for BAYC with randome SHIT token (value ~0) and deposits
    // _margin to create an order based on worthless tokens which are also used to pay trading fees.
    address public BASE_TOKEN;

    address public FW_NFT;

    constructor(address _baseToken, address _floorWavesNFT) Ownable() {
        BASE_TOKEN = _baseToken;
        FW_NFT = _floorWavesNFT;
    }

    function setMaxLeverage(uint256 _maxLeverage) external onlyOwner {
        require(
            _maxLeverage >= 1 && _maxLeverage <= 100,
            "FloorWavesPerp: Max Leverage should be between 1 and 100"
        );
        MAX_LEVERAGE = _maxLeverage;
    }

    function setLiquidationFeePercent(uint256 _liquidationFeePercent)
        external
        onlyOwner
    {
        require(
            _liquidationFeePercent <= 100,
            "FloorWavesPerp: Liquidation fee percent cannot be greater than 100 percent"
        );
        LIQUIDATION_FEE_PERCENT = _liquidationFeePercent;
    }

    function setTradingFeePercent(uint256 _tradingFeePercent)
        external
        onlyOwner
    {
        require(
            _tradingFeePercent <= 100,
            "FloorWavesPerp: Matching fee percent cannot be greater than 100 percent"
        );
        TRADING_FEE_PERCENT = _tradingFeePercent;
    }

    function addMarket(address _underlyingAsset)
        external
        onlyOwner
        marketNotExists(_underlyingAsset)
    {
        nftMarketMap[_underlyingAsset].underlyingAsset = _underlyingAsset;
        marketsList.push(_underlyingAsset);
    }

    function toggleMarket(address _underlyingAsset, bool _paused)
        external
        onlyOwner
        marketExists(_underlyingAsset)
    {
        require(
            nftMarketMap[_underlyingAsset].paused != _paused,
            "Market: Market is already in the desired state"
        );
        nftMarketMap[_underlyingAsset].paused = _paused;
    }

    function marketListLength() external view returns (uint256) {
        return marketsList.length;
    }

    function isMarketPaused(address _underlyingAsset)
        external
        view
        marketExists(_underlyingAsset)
        returns (bool)
    {
        return nftMarketMap[_underlyingAsset].paused;
    }

    function marketOrdersIterator(address _underlyingAsset, string memory n)
        external
        view
        marketExists(_underlyingAsset)
        returns (string memory)
    {
        return nftMarketMap[_underlyingAsset].ordersIndex.step(n, LibCLLs.NEXT);
    }

    function userOrdersIterator(address _user, string memory n)
        external
        view
        returns (string memory)
    {
        return userOrdersMap[_user].step(n, LibCLLs.NEXT);
    }

    /**
     * @notice Place a limit order for the given underyling NFT. Will mint an sNFT or lNFT when being matched.
     * @param _underlyingAsset Address of the underlying NFT.
     * @param _orderID: A unique string as identifier for the order.
     * @param _order Tuple of strings containing the details of the order, consisting of:
     *    - margin: Amount of BASE_TOKEN to be transfered to the contract. Contract must have enough tokens approved.
     *    - floor price: Floor price in amount of ETH at which you want to buy or sell the underlying NFT.
     *    - order type: 0 = long order, 1 = short order
     */
    function placeOrder(
        address _underlyingAsset,
        string memory _orderID,
        Types.Order memory _order
    ) external marketOn(_underlyingAsset) orderNotExists(_orderID) {
        require(
            _order.isLeverageAllowed(MAX_LEVERAGE),
            "FloorWavesPerp: Leverage factor should be between 1 and max allowed"
        );
        require(
            _order.margin <= _baseTokenAllowance(msg.sender),
            "FloorWavesPerp: Caller has not allowed enough funds for margin deposit"
        );
        require(
            _order.margin <= _baseTokenBalance(msg.sender),
            "FloorWavesPerp: Caller does not have enough funds for margin deposit"
        );

        // last argument 0 for fwNFTtokenID represents this is a fresh order
        Types.OrderDetails memory orderDetails = Types.OrderDetails(
            _order,
            msg.sender,
            _underlyingAsset,
            0
        );
        IERC20(BASE_TOKEN).transferFrom(
            msg.sender,
            address(this),
            _order.margin
        );
        _createOrder(_orderID, orderDetails);
    }

    // This is a limit order to exit an existing position
    // E.g. the user already owns an sNFT/lNFT token

    /**
     * @notice Placing a limit order to exit an existing position. Must have a minted sNFT or lNFT.
     * @param _fwNFTtokenID The unique id (unit) of the NFT position that shall be exited.
     * @param _orderID A unique string as identifier for the order.
     * @param _exitFloorPrice Floor price in amount of ETH at which to exit underlying sNFT or lNFT position.
     *    Has to be greater or equal to the current floor price + fees if the user wants to close a long position.
     *    Has to be smaller or equal to the current floor price - fees if the user wants to close a short position.
     */
    function listFloorWavesNFT(
        uint256 _fwNFTtokenID,
        string memory _orderID,
        uint256 _exitFloorPrice
    ) external orderNotExists(_orderID) {
        require(
            IFloorWavesNFT(FW_NFT).ownerOf(_fwNFTtokenID) == msg.sender,
            "FloorWavesPerp: Caller must be the owner of the FW-NFT"
        );

        Types.OrderDetails memory orderDetails = IFloorWavesNFT(FW_NFT)
            .getOrderDetails(_fwNFTtokenID);
        require(
            !nftMarketMap[orderDetails.underlyingAsset].paused,
            "FloorWavesPerp: Market is not accepting orders"
        );

        // TODO: Restrict user to list already listed NFTs for close positions

        // If this value becomes < 0, transaction will fail due to require checks added within its implementation
        require(
            _getPositionValue(
                orderDetails.order,
                _exitFloorPrice,
                TRADING_FEE_PERCENT
            ) >= 0,
            "FloorWavesPerp: Passed exit floor price makes order value negative"
        );

        orderDetails.creator = msg.sender; // set creator to msg.sender
        orderDetails.fwNFTtokenID = _fwNFTtokenID;
        orderDetails.order.floorPrice = _exitFloorPrice;
        orderDetails.order.orderType = orderDetails.order.getMatchOrderType(); // inverse order type
        _createOrder(_orderID, orderDetails);
    }

    /**
     * @notice Cancling an existing order and removing it from the order book.
     * @param _orderID A unique string as identifier for the order.
     */
    function cancelOrder(string memory _orderID)
        external
        orderExists(_orderID)
        marketOn(orderMap[_orderID].underlyingAsset)
    {
        Types.OrderDetails memory orderDetails = orderMap[_orderID];
        require(
            orderDetails.creator == msg.sender,
            "FloorWavesPerp: Caller is not creator of this order"
        );

        uint256 margin = orderDetails.order.margin;
        if (orderMap[_orderID].fwNFTtokenID == 0) {
            // settle funds only for fresh positions

            require(
                (margin <= _baseTokenBalance(address(this))),
                "FloorWavesPerp: Contract does not have enough funds for settlement"
            );
            IERC20(BASE_TOKEN).transfer(msg.sender, margin);
        }
        _removeOrder(_orderID, orderMap[_orderID]);
    }

    /**
     * @notice Market order which matches an existing order from the order book and mints you an sNFT if you go short or an lNFT if you go long.
     *     Also burns the existing NFT of the matched order if it was a position and transfers the position value to the NFT owner.
     * @dev Can be used in two cases:
     *     1. Case: User does not have an existing position, the matched order does not have an existing position.
     *     2. Case: User does not have an existing position, the matched order does have an existing position.
     * @param _existingOrderID A unique string as identifier for the order from order book that the user wants to match with.
     * @param _margin Amount of BASE_TOKEN to be transfered to the contract. Contract must have enough tokens approved.
     */
    function matchOrderWithFreshPosition(
        string memory _existingOrderID,
        uint256 _margin
    )
        external
        orderExists(_existingOrderID)
        marketOn(orderMap[_existingOrderID].underlyingAsset)
    {
        require(
            _margin <= _baseTokenAllowance(msg.sender),
            "FloorWavesPerp: Caller has not allowed enough funds for margin deposit"
        );
        require(
            _margin <= _baseTokenBalance(msg.sender),
            "FloorWavesPerp: Caller does not have enough funds for margin deposit"
        );

        Types.OrderDetails memory existingOrderDetails = orderMap[
            _existingOrderID
        ];
        Types.Order memory existingOrder = existingOrderDetails.order;

        // myOrder doesn't have id. It is not required, as this order wont be added to order book
        Types.Order memory myOrder = existingOrder.getMatchOrder(_margin);
        require(
            myOrder.isLeverageAllowed(MAX_LEVERAGE),
            "FloorWavesPerp: Leverage factor should be between 1 and max allowed"
        );

        // only when existing order is NFT listed for close, we need to transfer funds
        uint256 existingOrderValue = 0;
        if (existingOrderDetails.fwNFTtokenID != 0) {
            require(
                IFloorWavesNFT(FW_NFT).ownerOf(
                    existingOrderDetails.fwNFTtokenID
                ) == existingOrderDetails.creator,
                // Question: How can someone list an NFT token position if he doesn't own the NFT in the first place?
                "FloorWavesPerp: FW-NFT for existing order is not owned by the one who listed it for closing position"
            );
            Types.OrderDetails memory entryOrderDetails = IFloorWavesNFT(FW_NFT)
                .getOrderDetails(existingOrderDetails.fwNFTtokenID);

            // If this value becomes < 0, transaction will fail due to require checks added within its implementation
            existingOrderValue = _getPositionValue(
                entryOrderDetails.order, // entry order details at which NFT was minted
                existingOrder.floorPrice, // exit floor price
                TRADING_FEE_PERCENT
            );
        }
        require(
            existingOrderValue <= _baseTokenBalance(address(this)),
            "FloorWavesPerp: Contract does not have enough funds for settlement"
        );

        // minting new FW-NFT and charging margin amount in base token.
        // not adding order to order book, as it is already matched.
        Types.OrderDetails memory myOrderDetails = Types.OrderDetails(
            myOrder,
            msg.sender,
            existingOrderDetails.underlyingAsset,
            0
        );

        IERC20(BASE_TOKEN).transferFrom( // take funds from msg.sender into contract
            msg.sender,
            address(this),
            myOrder.margin
        );

        _removeOrder(_existingOrderID, existingOrderDetails); // remove existing order from order book

        _mintFloorWavesNFT(myOrderDetails); // mint new FW-NFT for fresh order

        // if existing order was a fresh order, mint new FW-NFT
        if (existingOrderDetails.fwNFTtokenID == 0) {
            _mintFloorWavesNFT(existingOrderDetails);
            return;
        }

        // if existing order was a FW-NFT (close position), burn FW-NFT and settle his order
        _burnFloorWavesNFT(existingOrderDetails.fwNFTtokenID);
        if (existingOrderValue > 0) {
            IERC20(BASE_TOKEN).transfer(
                existingOrderDetails.creator,
                existingOrderValue
            );
        }
    }

    /// TODO: Users should only receive margin - fee
    /**
     * @notice Market order which matches an existing order, burns the NFT and transfers the funds back to the NFT owner.
     * @dev Can be used in two cases:
     *     1. Case: User does have an existing position, the matched order does not have an existing position.
     *     2. Case: User does have an existing position, the matched order does have an existing position.
     * @param _existingOrderID A unique string as identifier for the order from order book that the user wants to match with.
     * @param _myFWNFTtokenID The identifier for the users existing NFT he wants to exit.
     */
    function matchOrderWithCurrentPosition(
        string memory _existingOrderID,
        uint256 _myFWNFTtokenID
    )
        external
        orderExists(_existingOrderID)
        marketOn(orderMap[_existingOrderID].underlyingAsset)
    {
        // owner check also checks for existence of tokenID
        require(
            IFloorWavesNFT(FW_NFT).ownerOf(_myFWNFTtokenID) == msg.sender,
            "FloorWavesPerp: Caller should be owner of FW-NFT"
        );

        Types.OrderDetails memory existingOrderDetails = orderMap[
            _existingOrderID
        ];
        Types.OrderDetails memory myEntryOrderDetails = IFloorWavesNFT(FW_NFT)
            .getOrderDetails(_myFWNFTtokenID);
        require(
            existingOrderDetails.underlyingAsset ==
                myEntryOrderDetails.underlyingAsset,
            "FloorWavesPerp: Cannot match orders for different underlying asset"
        );

        // myExitOrder will be opposite of myEntryOrder and should be opposite of existingOrder
        // hence, existingOrder's orderType & myEntryOrder's orderType should be same
        require(
            existingOrderDetails.order.orderType ==
                myEntryOrderDetails.order.orderType,
            "FloorWavesPerp: Cannot match same type order"
        );

        Types.Order memory existingOrder = existingOrderDetails.order;
        Types.Order memory myEntryOrder = myEntryOrderDetails.order;
        uint256 existingOrderValue = 0;
        if (existingOrderDetails.fwNFTtokenID != 0) {
            require(
                IFloorWavesNFT(FW_NFT).ownerOf(
                    existingOrderDetails.fwNFTtokenID
                ) == existingOrderDetails.creator,
                "FloorWavesPerp: FW-NFT for existing order is not owned by the one who listed it for closing position"
            );
            Types.OrderDetails memory entryOrderDetails = IFloorWavesNFT(FW_NFT)
                .getOrderDetails(existingOrderDetails.fwNFTtokenID);

            // If this value becomes < 0, transaction will fail due to require checks added within its implementation
            existingOrderValue = _getPositionValue(
                entryOrderDetails.order, // entry order details at which NFT was minted
                existingOrder.floorPrice, // exit floor price
                TRADING_FEE_PERCENT
            );
        }

        // If this value becomes < 0, transaction will fail due to require checks added within its implementation
        uint256 myOrderValue = _getPositionValue(
            myEntryOrder, // entry order details at which NFT was minted
            existingOrder.floorPrice, // exit floor price
            TRADING_FEE_PERCENT
        );
        require(
            existingOrderValue.add(myOrderValue) <=
                _baseTokenBalance(address(this)),
            "FloorWavesPerp: Contract does not have enough funds for settlement"
        );

        _removeOrder(_existingOrderID, existingOrderDetails); // remove existing order from order book

        _burnFloorWavesNFT(_myFWNFTtokenID); // burn FW-NFT for my order & settle funds

        if (existingOrderDetails.fwNFTtokenID == 0) {
            // mint FW-NFT for existing fresh order
            _mintFloorWavesNFT(existingOrderDetails);
        } else {
            _burnFloorWavesNFT(existingOrderDetails.fwNFTtokenID); // burn listed FW-NFT for position close
        }

        //profitability checks are done by _getPositionValue
        // transfer funds to msg.sender
        IERC20(BASE_TOKEN).transfer(msg.sender, myOrderValue);

        // transfer funds to existing order creator
        IERC20(BASE_TOKEN).transfer(
            existingOrderDetails.creator,
            existingOrderValue
        );
    }

    function liquidate(
        uint256 _liquidatedTokenId,
        uint256 _matchedTokenId,
        uint256 _currentFloor
    ) external onlyOwner {
        // fails transaction if tokenId is not yet minted
        Types.OrderDetails memory liquidatedOrderDetails = IFloorWavesNFT(
            FW_NFT
        ).getOrderDetails(_liquidatedTokenId);
        Types.OrderDetails memory matchedOrderDetails = IFloorWavesNFT(FW_NFT)
            .getOrderDetails(_matchedTokenId);

        require(
            liquidatedOrderDetails.underlyingAsset ==
                matchedOrderDetails.underlyingAsset,
            "FloorWavesPerp: Cannot match orders for different underlying asset"
        );

        require(
            liquidatedOrderDetails.order.orderType !=
                matchedOrderDetails.order.orderType,
            "FloorWavesPerp: Cannot match same type order"
        );
        // market paused check is not required as liquidation is only done by owner

        Types.Order memory liquidatedOrder = liquidatedOrderDetails.order;
        Types.Order memory matchedOrder = matchedOrderDetails.order;

        // If this value becomes < 0, transaction will fail due to require checks added within its implementation
        uint256 liquidatedOrderValue = _getPositionValue(
            liquidatedOrder, // entry order details at which NFT was minted
            _currentFloor, // exit floor price
            LIQUIDATION_FEE_PERCENT
        );

        // If this value becomes < 0, transaction will fail due to require checks added within its implementation
        uint256 matchedOrderValue = _getPositionValue(
            matchedOrder, // entry order details at which NFT was minted
            _currentFloor, // exit floor price
            LIQUIDATION_FEE_PERCENT
        );
        require(
            liquidatedOrderValue.add(matchedOrderValue) <=
                _baseTokenBalance(address(this)),
            "FloorWavesPerp: Contract does not have enough funds for settlement"
        );

        // existing order (if any) in order book (for exit)
        // will be dangling (cant be matched) as the NFT is now burned
        _burnFloorWavesNFT(_liquidatedTokenId);
        _burnFloorWavesNFT(_matchedTokenId);

        if (liquidatedOrderValue > 0) {
            IERC20(BASE_TOKEN).transfer(
                IFloorWavesNFT(FW_NFT).ownerOf(_liquidatedTokenId),
                liquidatedOrderValue
            );
        }

        if (matchedOrderValue > 0) {
            IERC20(BASE_TOKEN).transfer(
                IFloorWavesNFT(FW_NFT).ownerOf(_matchedTokenId),
                matchedOrderValue
            );
        }
    }

    function transferFunds(uint256 _amount, address reciever)
        external
        onlyOwner
    {
        require(
            _amount <= _baseTokenBalance(address(this)),
            "FloorWavesPerp: Contract does not have enough funds to transfer"
        );
        IERC20(BASE_TOKEN).transfer(reciever, _amount);
    }

    // ======================= Private function starts =======================

    function _createOrder(
        string memory _orderID,
        Types.OrderDetails memory _orderDetails
    ) private {
        orderMap[_orderID] = _orderDetails; // add order to global map against orderID
        nftMarketMap[_orderDetails.underlyingAsset].ordersIndex.push(
            _orderID,
            LibCLLs.NEXT
        ); // index orderID to market DLL
        userOrdersMap[_orderDetails.creator].push(_orderID, LibCLLs.NEXT); // index orderID to user DLL
    }

    function _removeOrder(
        string memory _orderID,
        Types.OrderDetails memory _orderDetails
    ) private {
        nftMarketMap[_orderDetails.underlyingAsset].ordersIndex.remove(
            _orderID
        ); // remove order index from market DLL
        userOrdersMap[_orderDetails.creator].remove(_orderID); // remove order index from user DLL
        delete orderMap[_orderID]; // remove order from global map
    }

    function _mintFloorWavesNFT(Types.OrderDetails memory _orderDetails)
        private
    {
        IFloorWavesNFT(FW_NFT).safeMint(_orderDetails.creator, _orderDetails);
    }

    function _burnFloorWavesNFT(uint256 _fwNFTtokenID) private {
        IFloorWavesNFT(FW_NFT).burn(_fwNFTtokenID);
    }

    function _getPositionValue(
        Types.Order memory _order,
        uint256 floorPrice,
        uint256 feePercent
    ) private pure returns (uint256) {
        uint256 value = _order.getPositionValue(floorPrice);
        uint256 feeDeduction = (value.mul(feePercent)).div(100);
        return value.sub(feeDeduction);
    }

    function _baseTokenAllowance(address sender)
        private
        view
        returns (uint256)
    {
        return IERC20(BASE_TOKEN).allowance(sender, address(this));
    }

    function _baseTokenBalance(address owner) private view returns (uint256) {
        return IERC20(BASE_TOKEN).balanceOf(owner);
    }

    // ======================= Private function ends =======================

    // ================================ Modifier starts ================================
    modifier marketExists(address _underlyingAsset) {
        require(
            nftMarketMap[_underlyingAsset].underlyingAsset == _underlyingAsset,
            "FloorWavesPerp: Market does not exist for this underlying asset"
        );
        _;
    }

    modifier marketNotExists(address _underlyingAsset) {
        require(
            nftMarketMap[_underlyingAsset].underlyingAsset != _underlyingAsset,
            "FloorWavesPerp: Market already exists for this underlying asset"
        );
        _;
    }

    modifier marketOn(address _underlyingAsset) {
        require(
            nftMarketMap[_underlyingAsset].underlyingAsset == _underlyingAsset,
            "FloorWavesPerp: Market does not exist for this underlying asset"
        );
        require(
            !nftMarketMap[_underlyingAsset].paused,
            "FloorWavesPerp: Market is not accepting orders"
        );
        _;
    }

    modifier orderNotExists(string memory _orderID) {
        require(_orderID.notEmpty(), "FloorWavesPerp: OrderID cannot be empty");
        require(
            orderMap[_orderID].underlyingAsset == address(0),
            "FloorWavesPerp: Market orderID already exists. Please generate a new orderID"
        );
        _;
    }

    modifier orderExists(string memory _orderID) {
        require(_orderID.notEmpty(), "FloorWavesPerp: OrderID cannot be empty");
        require(
            orderMap[_orderID].underlyingAsset != address(0),
            "FloorWavesPerp: Market orderID does not exist"
        );
        _;
    }
    // ================================== Modifier ends ==================================
}