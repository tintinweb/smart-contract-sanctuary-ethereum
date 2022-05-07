/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicense

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


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


// File: nftMarketplace.sol

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

interface IInstagramNFT is IERC721{

    function getForAuction() external view returns (address payable, uint256);

}

contract InstagramNFTMarketplace is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    address private signatureContract;

    address payable public marketplaceFeeWallet;

    uint8 public marketplacePercentage;
    uint8 public minterPercentage;
    uint8 public instagrammerPercentage;
    uint8 public ownerPercentage;

    uint8 public minimumBidIncreasePercentage;

    uint256 public startingBid;
    uint256 public bidExpiryTime;
    uint256 public bumpBidExpiryTime;

    struct HighestBid {
        address payable highestBidder;
        uint256 highestBidAmount;
    }

    struct Bid {
        address payable bidder;
        uint256 bidAmount;
    }

    struct InstagramInfo {
        address payable instagrammer;
        address payable minter;
        address payable owner;
        string identifier;
        bool isApproved;
    }

    mapping(uint256 => InstagramInfo) public tokenIdForInstagramInfo;
    mapping(uint256 => mapping(uint256 => Bid)) public tokenIdForAllBids;
    mapping(uint256 => uint256) public lengthForAllBids;
    mapping(uint256 => HighestBid) public tokenIdForHighestBid;

    IERC20 public WETH;

    IInstagramNFT public instagramNFT;

    // Events

    event ChangedFeePercentages (
        uint8 _marketplacePercentage,
        uint8 _minterPercentage
    );

    event ChangedMarketplaceFeeWallet (
        address indexed _marketplaceFeeWallet
    );

    event ChangedInstagramNFTContractAddress (
        address indexed _instagramNFTContractAddress
    );

    event AuctionMade (
        address indexed _instagrammer,
        address indexed _minter,
        address indexed _owner,
        string _identifier,
        bool _isApproved,
        uint256 _tokenId
    );

    event Approved (
        address indexed _instagrammer,
        address indexed _minter,
        address indexed _owner,
        string _identifier,
        bool _isApproved,
        uint256 _tokenId
    );

    event BidMade (
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );

    event BidCancelled (
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );

    event ClaimedAndTransferred (
        address indexed _instagrammer,
        address indexed _minter,
        address indexed _bidder,
        string _identifier,
        uint256 _amount,
        uint256 _tokenId
    );

    event ERC721Received (
        address indexed _operator,
        address indexed _to,
        uint256 _tokenId,
        bytes data
    );

    // Constructor

    constructor() {
        marketplaceFeeWallet = payable(msg.sender); // TODO

        marketplacePercentage = 10;
        minterPercentage = 10;
        instagrammerPercentage = 80;
        ownerPercentage = 90;

        minimumBidIncreasePercentage = 1;
        
        startingBid = 0.01 ether;

        // WETH = IERC20(0x70c61BE68924dbb8DfBEc732772030874113345C); //Testnet
        // WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //Mainnet
    }

    // setters

    function setInstagramNFTContractAddress(address _instagramNFTContractAddress) public onlyOwner {
        instagramNFT = IInstagramNFT(_instagramNFTContractAddress);

        emit ChangedInstagramNFTContractAddress(address(instagramNFT));
    }
    
    function setWETHContractAddress(address _stablecoinContractAddress) public onlyOwner {
        WETH = IERC20(_stablecoinContractAddress);
    }

    function setMarketplaceFeeWallet(address payable _marketplaceFeeWallet) public onlyOwner {
        marketplaceFeeWallet = _marketplaceFeeWallet;

        emit ChangedMarketplaceFeeWallet(_marketplaceFeeWallet);
    }

    function setFeePercentages(uint8 _marketplacePercentage) external onlyOwner {
        require(_marketplacePercentage < 100, "setFeePercentages::The marketplace cut should be less then 100%");

        marketplacePercentage = _marketplacePercentage;
        minterPercentage = 100 - marketplacePercentage;

        emit ChangedFeePercentages(marketplacePercentage, minterPercentage);
    }

    function setMinimumBidIncreasePercentage(uint8 _percentage) external onlyOwner {
        minimumBidIncreasePercentage = _percentage;
    }

    // getters

    function getInstagramNFTContractAddress() public view onlyOwner returns (address) {
        return address(instagramNFT);
    }

    function getMarketplaceFeeWallet() public view onlyOwner returns (address payable) {
        return marketplaceFeeWallet;
    }

    // functions

    function setOnAuction(address payable _instagrammer, address payable _minter, string memory _identifier, uint256 _tokenId) external onlyContract {
        tokenIdForInstagramInfo[_tokenId] = InstagramInfo(_instagrammer, _minter, payable(address(this)), _identifier, false);

        emit AuctionMade(_instagrammer, _minter, payable(address(this)), _identifier, false, _tokenId);
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns (bytes4) {
        emit ERC721Received(_operator, _from, _tokenId, _data);

        return IERC721Receiver.onERC721Received.selector;
    }

    function approve(uint256 _tokenId, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(msg.sender == tokenIdForInstagramInfo[_tokenId].instagrammer, "approve::Only Instagrammer can call this function");
        require(signatureContract == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, msg.sender , _deadline))), v, r, s), "approve::Owner should sign transaction");

        tokenIdForInstagramInfo[_tokenId].isApproved = true;

        emit Approved(tokenIdForInstagramInfo[_tokenId].instagrammer, tokenIdForInstagramInfo[_tokenId].minter, tokenIdForInstagramInfo[_tokenId].owner, tokenIdForInstagramInfo[_tokenId].identifier, tokenIdForInstagramInfo[_tokenId].isApproved, _tokenId);
    }

    function bid(uint256 _newBid, uint256 _tokenId) external nonReentrant {
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        InstagramInfo memory tempInstagramInfo = tokenIdForInstagramInfo[_tokenId];
        uint256 currentHighestBid = tokenIdForHighestBid[_tokenId].highestBidAmount;
        require(_newBid != 0, "bid::Bid cannot be 0 Wei");
        if (currentHighestBid == 0) {
            currentHighestBid = startingBid;
            tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId]] = Bid(payable(0x0), startingBid);
            lengthForAllBids[_tokenId]++;
        }
        require(_newBid > currentHighestBid.add(currentHighestBid.mul(minimumBidIncreasePercentage).div(100)), "bid::Bid must be higher than 1% of current highest bid");
        require(msg.sender != tempInstagramInfo.minter, "bid::Minter cannot bid");
        require(allowance != 0, "bid::Approved WETH must not be 0 Wei or Approval must be given");
        require(allowance >= _newBid, "bid::Approved WETH must be greater than or equal to the bid amount");


        require(WETH.transferFrom(msg.sender, address(this), _newBid), "bid::Error in WETH.transferFrom");

        tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId]] = Bid(payable(msg.sender), _newBid);
        lengthForAllBids[_tokenId]++;
        tokenIdForHighestBid[_tokenId] = HighestBid(payable(msg.sender), _newBid);

        emit BidMade(msg.sender, _newBid, _tokenId);
    }

    function cancelBid(uint256 _bidAmount, uint256 _tokenId) external nonReentrant {
        require(_bidAmount > startingBid, "cancelBid::No bid less than the starting bid price can exist anyways");


        address payable tempBidder;
        uint256 tempBidAmount;

        bool isExistingBid = false;
        
        if (tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidder == msg.sender && 
        tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidAmount == _bidAmount) {
            isExistingBid = true;

            tempBidder = tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidder;
            tempBidAmount = tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidAmount;

            require(WETH.transferFrom(address(this), tempBidder, tempBidAmount), "cancelBid::Error in WETH.transfer");

            tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1] = Bid(payable(0x0), 0 ether);
            for (uint256 i = lengthForAllBids[_tokenId] - 2 ; i > 0 ; i--) {
                if (tokenIdForAllBids[_tokenId][i].bidAmount != 0) {
                    tokenIdForHighestBid[_tokenId].highestBidder = tokenIdForAllBids[_tokenId][i].bidder;
                    tokenIdForHighestBid[_tokenId].highestBidAmount = tokenIdForAllBids[_tokenId][i].bidAmount;
                    lengthForAllBids[_tokenId]--;
                    break;
                }
                else {
                    lengthForAllBids[_tokenId]--;
                }
            }
        }
        else {
            for (uint256 i = 1 ; i < lengthForAllBids[_tokenId] ; i++) {
                if (tokenIdForAllBids[_tokenId][i].bidder == msg.sender && 
                tokenIdForAllBids[_tokenId][i].bidAmount == _bidAmount) {
                    isExistingBid = true;
                    tempBidder = tokenIdForAllBids[_tokenId][i].bidder;
                    tempBidAmount = tokenIdForAllBids[_tokenId][i].bidAmount;

                    require(WETH.transferFrom(address(this), tempBidder, tempBidAmount), "cancelBid::Error in WETH.transfer");
                    tokenIdForAllBids[_tokenId][i] = Bid(payable(0x0), 0 ether);
                }
            }
        }

        require(isExistingBid, "cancelBid::Only bidder can cancel their own bid or Incorrect bid amount");
 
        emit BidCancelled(tempBidder, tempBidAmount, _tokenId);
    }

    function claim(uint256 _tokenId, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        InstagramInfo memory tempInstagramInfo = tokenIdForInstagramInfo[_tokenId];
        HighestBid memory tempHighestBid = tokenIdForHighestBid[_tokenId];
        // address payable tempBidder = tokenIdForHighestBid[_tokenId].highestBidder;
        // uint256 tempBidAmount = tokenIdForHighestBid[_tokenId].highestBidAmount;
        require(msg.sender == tokenIdForInstagramInfo[_tokenId].instagrammer, "claim::Only Instagrammer can call this function");
        require(signatureContract == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, msg.sender , _deadline))), v, r, s), "claim::Owner should sign transaction");


        if (address(this) == tempInstagramInfo.owner) {
            uint256 dividend = 100;

            uint256 marketplaceShare = tempHighestBid.highestBidAmount.div(dividend.div(marketplacePercentage));
            uint256 instagrammerShare = tempHighestBid.highestBidAmount.div(dividend.div(instagrammerPercentage));
            uint256 minterShare = tempHighestBid.highestBidAmount.div(dividend.div(minterPercentage));
            require(marketplaceShare + instagrammerShare + minterShare == tempHighestBid.highestBidAmount, "bid::Div error checker failed");
            
            require(WETH.transferFrom(address(this), marketplaceFeeWallet, marketplaceShare), "claim::Error in WETH.transfer");
            require(WETH.transferFrom(address(this), tempInstagramInfo.instagrammer, instagrammerShare), "claim::Error in WETH.transfer");
            require(WETH.transferFrom(address(this), tempInstagramInfo.minter, minterShare), "claim::Error in WETH.transfer");

            instagramNFT.transferFrom(address(this), tempHighestBid.highestBidder, _tokenId);
        }
        else {
            uint256 dividend = 100;
            
            uint256 ownerShare = tempHighestBid.highestBidAmount.div(dividend.div(ownerPercentage));
            uint256 marketplaceShare = tempHighestBid.highestBidAmount.sub(ownerShare);
            require(ownerShare + marketplaceShare == tempHighestBid.highestBidAmount, "bid::Div error checker failed");
            
            require(WETH.transferFrom(address(this), tempInstagramInfo.owner, ownerShare), "claim::Error in WETH.transfer");
            require(WETH.transferFrom(address(this), marketplaceFeeWallet, marketplaceShare), "claim::Error in WETH.transfer");

            instagramNFT.transferFrom(address(this), tempHighestBid.highestBidder, _tokenId);
        }

        revertAllOtherBids(_tokenId);

        emit ClaimedAndTransferred(tempInstagramInfo.instagrammer, tempInstagramInfo.minter, tempHighestBid.highestBidder, tempInstagramInfo.identifier, tempHighestBid.highestBidAmount, _tokenId);
    }

    function revertAllOtherBids(uint256 _tokenId) internal {
        for (uint256 i = 0 ; i < lengthForAllBids[_tokenId] - 1 ; i++) {
            if (tokenIdForAllBids[_tokenId][i].bidAmount > startingBid) {
                require(WETH.transferFrom(address(this), tokenIdForAllBids[_tokenId][i].bidder, tokenIdForAllBids[_tokenId][i].bidAmount), "revertAllOtherBids::Error in WETH.transfer");
            }
        }
    }

    function getSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    receive() external payable {
        
    }

    modifier onlyContract {
        require(msg.sender == address(instagramNFT), "onlyContract::Only InstagramNFT Contract can call this function");
        _;
    }
}

/*

add both scenarios to claim
keccak stuff for claim

-> scenario 1 : newly minted NFT
minter = 10
platform = 10
instagrammer = 80
-> scenario 2 : NFT has had ownership transferred atleast once
currentOwner = 90
platform = 10
*/

// confirm wether anyone besides the picture's instagrammer can mint it as an NFT

// require us to somehow save the minter's nft metadata for ownership transfer to true owner/instagrammer when he approves
// lock minters nft if ^ is unfeasible

// minter can take anyone's instagram images and submit for minting
// minter and instagrammer can be the same person
// instagrammer needs to give approval or else the NFT is trashed and wont be minted
// hash verification to make sure that image is instagrammer's when he approves for minting

/*
structs
events
function bid etc
function mint etc
function getInsta etc
-> define a unique base uri for each different instagram account as they will be considered as a seperate collection
function payback
function sendValue
-> use OpenCanvas Marketplace
*/

// understand logic for ownershipUpgradeable
// determine what libraries/interfaces to use and what not to use
// figure out if