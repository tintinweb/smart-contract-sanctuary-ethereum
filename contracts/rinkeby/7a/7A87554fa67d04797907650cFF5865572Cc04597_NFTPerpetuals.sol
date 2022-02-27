/**
 *Submitted for verification at Etherscan.io on 2022-02-27
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

    enum BidType {
        LONG,
        SHORT
    }

    // ============ Structs ============
    /**
     * @dev Used to represent the open bids in Perpetuals contract
     **/
    struct BidDetails {
        string id;
        uint256 margin;
        uint256 floorPrice;
        BidType bidType;
        address creator;
        address underlyingNFT;
        uint256 perpNFTtokenID;
    }

    function leverageFactor(BidDetails memory self)
        internal
        pure
        returns (uint256)
    {
        return self.floorPrice.div(self.margin);
    }

    function valid(BidDetails memory self) internal view returns (bool) {
        return
            self.id.notEmpty() &&
            self.creator == msg.sender &&
            self.underlyingNFT != address(0x0) &&
            self.perpNFTtokenID == 0;
    }

    function bidValue(Types.BidDetails memory self, uint256 currentFloor)
        internal
        pure
        returns (uint256)
    {
        if (self.bidType == BidType.LONG && currentFloor >= self.floorPrice) {
            // LONG made profit
            return currentFloor.sub(self.floorPrice).add(self.margin);
        } else if (self.bidType == BidType.LONG) {
            // LONG made loss
            return self.floorPrice.sub(currentFloor).sub(self.margin);
        } else if (
            self.bidType == BidType.SHORT && currentFloor <= self.floorPrice
        ) {
            // SHORT made profit
            return self.floorPrice.sub(currentFloor).add(self.margin);
        } else {
            // SHORT made loss
            return currentFloor.sub(self.floorPrice).sub(self.margin);
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

interface IPerpERC721 is IERC721 {
    function safeMint(address to, Types.BidDetails calldata _props)
        external
        returns (uint256);

    function bid(uint256 tokenId)
        external
        view
        returns (Types.BidDetails memory);

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

contract NFTPerpetuals is Ownable {

    using StringUtils for string;
    using Types for Types.BidDetails;
    using LibCLLs for LibCLLs.CLL;

    // string will represent the unique value which will have bid stored against it
    // global map containing only open bids across all markets
    //TODO: Need to check the usecases of bids getting cancelled, bids with NFTs, bids without NFTs etc
    mapping(string => Types.BidDetails) public bidMap;

    //TODO Market essentially means NFT project for whom we are enabling future projects
    //TODO Check if market is inactive and usecase is handled
    struct Market {
        // doubly linked list for indexing open bids
        LibCLLs.CLL bidsIndex;
        // address of the underlying NFT used
        address underlyingNFT;
        // boolean used to start or stop accepting bids from accounts.
        bool paused;
    }

    // mapping for underlyingNFT => Market struct storing all bids
    mapping(address => Market) private nftMarketMap;

    // mapping for user => DLL for bids
    // This is independent of markets
    mapping(address => LibCLLs.CLL) private userBidsMap;

    //MAX LEVERAGE ALLOWED
    // TODO: for support upto 5 decimal places;
    uint256 public MAX_LEVERAGE = 5;

    uint256 public LIQUIDATION_FEE_PERCENT = 2;

    uint256 public MATCHING_FEE_PERCENT = 2;

    //TOKEN WE ACCEPT FOR MARGIN AMOUNT
    address public BASE_TOKEN;

    address public PERP_NFT;

    constructor(address _baseToken, address _perpERC721Token) Ownable() {
        BASE_TOKEN = _baseToken;
        PERP_NFT = _perpERC721Token;
    }

    function setMaxLeverage(uint256 _maxLeverage) external onlyOwner {
        require(
            _maxLeverage <= 100,
            "NFTPerpetuals: Max Leverage cannot be greater than 100 percent"
        );
        MAX_LEVERAGE = _maxLeverage;
    }

    function setLiquidationFeePercent(uint256 _liquidationFeePercent)
        external
        onlyOwner
    {
        require(
            _liquidationFeePercent <= 100,
            "NFTPerpetuals: Liquidation fee percent cannot be greater than 100 percent"
        );
        LIQUIDATION_FEE_PERCENT = _liquidationFeePercent;
    }

    function setMatchingFeePercent(uint256 _matchingFeePercent)
        external
        onlyOwner
    {
        require(
            _matchingFeePercent <= 100,
            "NFTPerpetuals: Matching fee percent cannot be greater than 100 percent"
        );
        MATCHING_FEE_PERCENT = _matchingFeePercent;
    }

    function addMarket(address _underlyingNFT)
        external
        onlyOwner
        marketNotExists(_underlyingNFT)
    {
        nftMarketMap[_underlyingNFT].underlyingNFT = _underlyingNFT;
    }

    // function bidSize(address _underlyingNFT) external view returns (uint256) {
    //     return nftMarketMap[_underlyingNFT].bidsIndex.sizeOf();
    // }

    function removeMarket(address _underlyingNFT)
        external
        onlyOwner
        marketExists(_underlyingNFT)
    {
        require(
            !nftMarketMap[_underlyingNFT].bidsIndex.exists(),
            "NFTPerpetuals: Market has open bids"
        );
        nftMarketMap[_underlyingNFT].paused = true;
        delete nftMarketMap[_underlyingNFT];
    }

    function toggleMarket(address _underlyingNFT, bool _paused)
        external
        onlyOwner
        marketExists(_underlyingNFT)
    {
        require(
            nftMarketMap[_underlyingNFT].paused != _paused,
            "Market: Market is already in the desired state"
        );
        nftMarketMap[_underlyingNFT].paused = _paused;
    }

    function placeBid(Types.BidDetails memory _bid)
        external
        marketOn(_bid.underlyingNFT)
        bidNotExists(_bid.id)
    {
        require(_bid.valid(), "NFTPerpetuals: Invalid bid struct");
        require(
            _bid.leverageFactor() <= MAX_LEVERAGE,
            "NFTPerpetuals: Leverage factor is greater than the max allowed"
        );
        require(
            _bid.margin <= _baseTokenAllowance(msg.sender),
            "NFTPerpetuals: Caller has not allowed enough funds for margin deposit"
        );
        require(
            _bid.margin <= _baseTokenBalance(msg.sender),
            "NFTPerpetuals: Caller does not have enough funds for margin deposit"
        );

        _createBid(_bid);
        IERC20(BASE_TOKEN).transferFrom(_bid.creator, address(this), _bid.margin);
    }

    function cancelBid(string memory _bidID)
        external
        bidExists(_bidID)
        marketOn(bidMap[_bidID].underlyingNFT)
    {
        require(
            bidMap[_bidID].creator == msg.sender,
            "NFTPerpetuals: Only bid creator can cancel its bid"
        );
        require(
            bidMap[_bidID].margin < _baseTokenBalance(address(this)),
            "NFTPerpetuals: Contract does not have enough funds for settlement"
        );

        uint256 margin = bidMap[_bidID].margin;
        _removeBid(bidMap[_bidID]);
        IERC20(BASE_TOKEN).transfer(msg.sender, margin);
    }

    function matchBid(string memory _oldBidID, Types.BidDetails memory _newBid)
        external
        bidExists(_oldBidID)
        bidNotExists(_newBid.id)
        marketOn(bidMap[_oldBidID].underlyingNFT)
    {
        require(_newBid.valid(), "NFTPerpetuals: Invalid new bid struct");
        require(
            _newBid.leverageFactor() <= MAX_LEVERAGE,
            "NFTPerpetuals: Leverage factor is greater than the max allowed for new bid"
        );
        require(
            _newBid.margin <= _baseTokenAllowance(msg.sender),
            "NFTPerpetuals: Caller has not allowed enough funds for margin deposit"
        );
        require(
            _newBid.margin <= _baseTokenBalance(msg.sender),
            "NFTPerpetuals: Caller does not have enough funds for margin deposit"
        );
        require(
            bidMap[_oldBidID].underlyingNFT == _newBid.underlyingNFT,
            "NFTPerpetuals: Cannot match bids for different underlying NFT"
        );
        require(
            bidMap[_oldBidID].bidType != _newBid.bidType,
            "NFTPerpetuals: Cannot match same type bid"
        );

        Types.BidDetails storage oldBid = bidMap[_oldBidID];
        uint256 oldBidValue = oldBid.perpNFTtokenID != 0
            ? _bidValue(oldBid, _newBid.floorPrice, MATCHING_FEE_PERCENT)
            : 0;
        require(
            oldBidValue <= _baseTokenBalance(address(this)),
            "NFTPerpetuals: Contract does not have enough funds for settlement"
        );
        if (oldBid.perpNFTtokenID == 0) {
            _mintPerpNFT(oldBid);
        } else {
            _burnPerpNFT(oldBid);
            if (oldBidValue > 0) {
                address owner = IPerpERC721(PERP_NFT).ownerOf(
                    oldBid.perpNFTtokenID
                );
                IERC20(BASE_TOKEN).transfer(owner, oldBidValue);
            }
        }

        _createBid(_newBid);
        IERC20(BASE_TOKEN).transferFrom(_newBid.creator, address(this), _newBid.margin);
        Types.BidDetails storage newBid = bidMap[_newBid.id];
        _mintPerpNFT(newBid);
    }

    function matchBid(string memory _bidID1, string memory _bidID2)
        external
        bidExists(_bidID1)
        bidExists(_bidID2)
        marketOn(bidMap[_bidID1].underlyingNFT)
    {
        require(
            bidMap[_bidID1].underlyingNFT == bidMap[_bidID2].underlyingNFT,
            "NFTPerpetuals: Cannot match bids for different underlying NFT"
        );
        require(
            bidMap[_bidID1].bidType != bidMap[_bidID2].bidType,
            "NFTPerpetuals: Cannot match same type bid"
        );

        Types.BidDetails storage bid1 = bidMap[_bidID1];
        Types.BidDetails storage bid2 = bidMap[_bidID2];
        uint256 v1 = bid1.perpNFTtokenID != 0
            ? _bidValue(bid1, bid2.floorPrice, MATCHING_FEE_PERCENT)
            : 0;
        uint256 v2 = bid2.perpNFTtokenID != 0
            ? _bidValue(bid2, bid1.floorPrice, MATCHING_FEE_PERCENT)
            : 0;
        require(
            v1 + v2 <= _baseTokenBalance(address(this)),
            "NFTPerpetuals: Contract does not have enough funds for settlement"
        );

        if (bid1.perpNFTtokenID == 0) {
            _mintPerpNFT(bid1);
        } else {
            _burnPerpNFT(bid1);
            if (v1 > 0) {
                address owner1 = IPerpERC721(PERP_NFT).ownerOf(
                    bid1.perpNFTtokenID
                );
                IERC20(BASE_TOKEN).transfer(owner1, v1);
            }
        }

        if (bid2.perpNFTtokenID == 0) {
            _mintPerpNFT(bid2);
        } else {
            _burnPerpNFT(bid2);
            if (v2 > 0) {
                address owner2 = IPerpERC721(PERP_NFT).ownerOf(
                    bid2.perpNFTtokenID
                );
                IERC20(BASE_TOKEN).transfer(owner2, v2);
            }
        }
    }

    function liquidate(
        uint256 _liquidatedTokenId,
        uint256 _againstTokenId,
        uint256 _currentFloor
    ) external onlyOwner {
        IPerpERC721 perpNft = IPerpERC721(PERP_NFT);

        // owner check fails transaction if tokenId is not yet minted
        perpNft.ownerOf(_liquidatedTokenId);
        address o2 = perpNft.ownerOf(_againstTokenId);

        Types.BidDetails memory liquidatedBid = perpNft.bid(_liquidatedTokenId);
        Types.BidDetails memory againstBid = perpNft.bid(_againstTokenId);
        require(
            liquidatedBid.underlyingNFT == againstBid.underlyingNFT,
            "NFTPerpetuals: Cannot match bids for different underlying NFT"
        );
        require(
            liquidatedBid.bidType != againstBid.bidType,
            "NFTPerpetuals: Cannot match same type bid"
        );
        require(
            nftMarketMap[liquidatedBid.underlyingNFT].underlyingNFT ==
                liquidatedBid.underlyingNFT,
            "NFTPerpetuals: Market does not exist for this underlying NFT"
        );
        // market paused check is not required as liquidation is only done by owner

        uint256 v1 = liquidatedBid.bidValue(_currentFloor);
        require(
            v1 == 0, //TODO: Have this as some min value check
            "NFTPerpetuals: passed NFT for liquidation is not to be liquidated yet"
        );

        uint256 v2 = againstBid.bidValue(_currentFloor);
        require(
            v2 > 0,
            "NFTPerpetuals: passed NFT to match liquidation is not to be matched yet"
        );
        require(
            v2 <= _baseTokenBalance(address(this)),
            "NFTPerpetuals: Contract does not have enough funds for settlement"
        );

        // transfer funds to owner of auto deleveraged NFT
        IERC20(BASE_TOKEN).transfer(o2, v2);

        // burn liquidated bids
        IPerpERC721(PERP_NFT).burn(_liquidatedTokenId);
        IPerpERC721(PERP_NFT).burn(_againstTokenId);
    }

    //***************NFT LISTING***************
    // function matchNFTOnSale ( NFT id, bidFloorPrice, bidLeverage) {
    //     // require
    //     // - contract is ON
    //     // - NFT is owned by requester
    //     //     - leverage is under defined leverage by smart contract
    //     // - it is not getting liquidated basis current floor price
    //     // OR
    //     // - intake of money should be more than equal to outward of money (Keeping a check at current state to avoid scams)
    // }

    // // Pending
    // function placeNFTOnSale ( NFT id, bidSellingFloorPrice) {
    //     // require
    //     // - contract is ON
    //     // - NFT is owned by the requester
    //     // - put the bid (logic needs to be rethink)
    // }

    // // Pending
    // function cancelNFTOnSale ( NFT id, bidSellingFloorPrice) {
    //     // require
    //     // - contract is ON
    //     // - NFT is owned by the requester
    //     // - put the bid (logic needs to be rethink)
    // }

    //***************ONLY OWNER***************
    // function transferFunds() onlyOwner {

    // }

    // ======================= Private function starts =======================

    function _createBid(Types.BidDetails memory _bid) private {
        bidMap[_bid.id] = _bid; // add bid to global map against bidID
        nftMarketMap[_bid.underlyingNFT].bidsIndex.push(_bid.id, LibCLLs.NEXT); // index bidID to market DLL
        userBidsMap[_bid.creator].push(_bid.id, LibCLLs.NEXT); // index bidID to user DLL
    }

    function _removeBid(Types.BidDetails memory _bid) private {
        nftMarketMap[_bid.underlyingNFT].bidsIndex.remove(_bid.id); // remove bid index from market DLL
        userBidsMap[_bid.creator].remove(_bid.id); // remove bid index from user DLL
        delete bidMap[_bid.id]; // remove bid from global map
    }

    function _mintPerpNFT(Types.BidDetails storage _bid) private {
        uint256 tokenID = IPerpERC721(PERP_NFT).safeMint(_bid.creator, _bid);
        _bid.perpNFTtokenID = tokenID;
    }

    function _burnPerpNFT(Types.BidDetails storage _bid) private {
        IPerpERC721(PERP_NFT).burn(_bid.perpNFTtokenID);
        _removeBid(_bid);
    }

    function _bidValue(
        Types.BidDetails memory _bid,
        uint256 currentFloor,
        uint256 feePercent
    ) private pure returns (uint256) {
        uint256 value = _bid.bidValue(currentFloor);
        uint256 feeDeduction = (value * feePercent) / 100;
        return value - feeDeduction;
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
    modifier marketExists(address _underlyingNFT) {
        require(
            nftMarketMap[_underlyingNFT].underlyingNFT == _underlyingNFT,
            "NFTPerpetuals: Market does not exist for this underlying NFT"
        );
        _;
    }

    modifier marketNotExists(address _underlyingNFT) {
        require(
            nftMarketMap[_underlyingNFT].underlyingNFT != _underlyingNFT,
            "NFTPerpetuals: Market already exists for this underlying NFT"
        );
        _;
    }

    modifier marketOn(address _underlyingNFT) {
        require(
            nftMarketMap[_underlyingNFT].underlyingNFT == _underlyingNFT,
            "NFTPerpetuals: Market does not exist for this underlying NFT"
        );
        require(
            !nftMarketMap[_underlyingNFT].paused,
            "NFTPerpetuals: Market is not accepting orders"
        );
        _;
    }

    modifier bidNotExists(string memory _bidID) {
        require(_bidID.notEmpty(), "NFTPerpetuals: BidID cannot be empty");
        require(
            bidMap[_bidID].id.empty(),
            "NFTPerpetuals: Market bidID already exists. Please generate a new bidID"
        );
        _;
    }

    modifier bidExists(string memory _bidID) {
        require(_bidID.notEmpty(), "NFTPerpetuals: BidID cannot be empty");
        require(
            bidMap[_bidID].id.notEmpty(),
            "NFTPerpetuals: Market bidID does not exist"
        );
        _;
    }
    // ================================== Modifier ends ==================================
}