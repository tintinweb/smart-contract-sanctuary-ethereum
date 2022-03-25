// contracts/NftMarketFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "NftMarket.sol";

contract NftMarketFactory is Ownable {
    mapping(address => address) public getPair;
    address[] public allPairs;
    address public router;

    event marketCreated(address _nft, address pair, uint256);

    function createMarketPair(
        address _nft,
        address _feeMarketReceiver,
        uint256 _feeMarketNum,
        address _feeCreatorReceiver,
        uint256 _feeCreatorNum
    ) external onlyOwner returns (address pair) {
        require(getPair[_nft] == address(0), "PAIR_EXISTS");
        bytes memory bytecode = type(NftMarket).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_nft, address(this)));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        NftMarket(pair).initialize(_nft, _feeMarketReceiver, _feeMarketNum, _feeCreatorReceiver, _feeCreatorNum, router);
        getPair[_nft] = pair;
        allPairs.push(pair);
        emit marketCreated(_nft, pair, allPairs.length);
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// contracts/NftMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "IERC721.sol";
import "ReentrancyGuard.sol";
import "SafeMath.sol";
import "IERC721ReceiverUpgradeable.sol";
import "TransferHelper.sol";

contract NftMarket is ReentrancyGuard, IERC721ReceiverUpgradeable {
    using SafeMath for uint256;

    address public factory;
    address public router;
    IERC721 public nft;
    address public feeMarketReceiver;
    uint256 public feeMarketNum;
    address public feeCreatorReceiver;
    uint256 public feeCreatorNum;
    // 10 min
    uint256 public updateInterval = 60;
    // tokenId -> owner
    mapping(uint256 => address) public tokenOwners;
    // tokenId -> order index
    TokenMeta[] public nftOrders;
    // nft orders
    mapping(uint256 => uint256) public nftOrderIndexs;

    struct TokenMeta {
        uint256 tokenId;
        uint256 price;
        uint256 sellTime;
        uint256 nextUpdateTime;
    }

    event SellNft(uint256 _tokenId, address seller, uint256 _price, uint256 _sellTime, uint256 _nextUpdateTime);
    event PriceChange(uint256 _tokenId, uint256 _oldPrice, uint256 _newPrice, uint256 _nextUpdateTime);
    event Cancel(uint256 _tokenId, address seller);
    event BuyNft(uint256 _tokenId, address seller, address buyer, uint256 _price, uint256 buyTime);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _nft,
        address _feeMarketReceiver,
        uint256 _feeMarketNum,
        address _feeCreatorReceiver,
        uint256 _feeCreatorNum,
        address _router
    ) external {
        require(msg.sender == factory, "Fund: FORBIDDEN"); // sufficient check
        nft = IERC721(_nft);
        feeMarketReceiver = _feeMarketReceiver;
        feeMarketNum = _feeMarketNum;
        feeCreatorReceiver = _feeCreatorReceiver;
        feeCreatorNum = _feeCreatorNum;
        router = _router;
    }

    function sellItemByRouter(
        address seller,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(msg.sender == router, "only can call by router");
        tokenOwners[_tokenId] = seller;
        nftOrders.push(TokenMeta(_tokenId, _price, block.timestamp, block.timestamp + updateInterval));
        nftOrderIndexs[_tokenId] = nftOrders.length;
        emit SellNft(_tokenId, seller, _price, block.timestamp, block.timestamp + updateInterval);
    }

    function buyItemByRouter(address buyer, uint256 _tokenId) external payable {
        require(msg.sender == router, "only can call by router");
        require(nftOrderIndexs[_tokenId] != 0, "order not exist");
        uint256 idx = nftOrderIndexs[_tokenId] - 1;
        TokenMeta memory order = nftOrders[idx];
        require(msg.value == order.price, "value not equal price");
        address seller = tokenOwners[_tokenId];
        uint256 feeMarket = feeMarketNum.mul(msg.value).div(1000);
        uint256 feeCreator = feeCreatorNum.mul(msg.value).div(1000);
        uint256 feeSeller = msg.value.sub(feeMarket).sub(feeCreator);

        TransferHelper.safeTransferETH(feeMarketReceiver, feeMarket);
        TransferHelper.safeTransferETH(feeCreatorReceiver, feeCreator);
        TransferHelper.safeTransferETH(seller, feeSeller);
        remove(idx);
        nftOrderIndexs[_tokenId] = 0;
        tokenOwners[_tokenId] = address(0);

        nft.safeTransferFrom(address(this), buyer, _tokenId);
        emit BuyNft(_tokenId, seller, buyer, msg.value, block.timestamp);
    }

    function cancelItemByRouter(uint256 _tokenId) external {
        require(msg.sender == router, "only can call by router");
        require(nftOrderIndexs[_tokenId] != 0, "order not exist");
        // require(tokenOwners[_tokenId] == _owner, "not owner");
        uint256 idx = nftOrderIndexs[_tokenId] - 1;
        TokenMeta memory order = nftOrders[idx];
        require(block.timestamp >= order.nextUpdateTime, "cannot cancel on current time");
        remove(idx);
        nft.safeTransferFrom(address(this), tokenOwners[_tokenId], _tokenId);
        nftOrderIndexs[_tokenId] = 0;
        tokenOwners[_tokenId] = address(0);
        emit Cancel(_tokenId, tokenOwners[_tokenId]);
    }

    function changePriceByRouter(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == router, "only can call by router");
        require(_price > 0);
        // require(tokenOwners[_tokenId] == msg.sender, "not owner");
        require(nftOrderIndexs[_tokenId] != 0, "order not exist");
        uint256 idx = nftOrderIndexs[_tokenId] - 1;
        TokenMeta storage order = nftOrders[idx];
        require(block.timestamp >= order.nextUpdateTime, "cannot cancel on current time");
        require(order.tokenId == _tokenId, "order wrong");
        uint256 oldPrice = order.price;
        order.price = _price;
        order.nextUpdateTime = block.timestamp + updateInterval;
        emit PriceChange(_tokenId, oldPrice, _price, order.nextUpdateTime);
    }

    function remove(uint256 index) internal {
        if (index >= nftOrders.length) return;

        if (index != nftOrders.length - 1) {
            nftOrders[index] = nftOrders[nftOrders.length - 1];
            TokenMeta memory order = nftOrders[nftOrders.length - 1];
            nftOrderIndexs[order.tokenId] = index + 1;
        }

        delete nftOrders[nftOrders.length - 1];
        nftOrders.pop();
    }

    function getOwner(uint256 _tokenId) public view returns (address) {
        return tokenOwners[_tokenId];
    }

    function getOrder(uint256 _tokenId) public view returns (TokenMeta memory) {
        uint256 idx = nftOrderIndexs[_tokenId];
        return nftOrders[idx];
    }

    function getOrderPage(uint256 pageIdx, uint256 pageSize) public view returns (TokenMeta[] memory) {
        uint256 startIdx = pageIdx * pageSize;
        require(startIdx <= nftOrders.length, "Page number too high");
        uint256 pageEnd = startIdx + pageSize;
        uint256 endIdx = pageEnd <= nftOrders.length ? pageEnd : nftOrders.length;
        return bulkGetOrders(startIdx, endIdx);
    }

    function bulkGetOrders(uint256 startIdx, uint256 endIdx) public view returns (TokenMeta[] memory ret) {
        ret = new TokenMeta[](endIdx - startIdx);
        for (uint256 idx = startIdx; idx < endIdx; idx++) {
            ret[idx - startIdx] = nftOrders[idx];
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // function sellItem(uint256 _tokenId, uint256 _price) external {
    //     require(_price > 0);
    //     nft.safeTransferFrom(msg.sender, address(this), _tokenId);
    //     tokenOwners[_tokenId] = msg.sender;
    //     nftOrders.push(TokenMeta(_tokenId, _price, block.timestamp, block.timestamp + updateInterval));
    //     nftOrderIndexs[_tokenId] = nftOrders.length;
    //     emit SellNft(_tokenId, msg.sender, _price, block.timestamp, block.timestamp + updateInterval);
    // }

    // function changePrice(uint256 _tokenId, uint256 _price) external {
    //     require(_price > 0);
    //     require(tokenOwners[_tokenId] == msg.sender, "not owner");
    //     require(nftOrderIndexs[_tokenId] != 0, "order not exist");
    //     uint256 idx = nftOrderIndexs[_tokenId] - 1;
    //     TokenMeta storage order = nftOrders[idx];
    //     require(block.timestamp >= order.nextUpdateTime, "cannot cancel on current time");
    //     require(order.tokenId == _tokenId, "order wrong");
    //     uint256 oldPrice = order.price;
    //     order.price = _price;
    //     order.nextUpdateTime = block.timestamp + updateInterval;
    //     emit PriceChange(_tokenId, oldPrice, _price, order.nextUpdateTime);
    // }

    // function cancelItem(uint256 _tokenId) external {
    //     require(tokenOwners[_tokenId] == msg.sender, "not owner");
    //     require(nftOrderIndexs[_tokenId] != 0, "order not exist");
    //     uint256 idx = nftOrderIndexs[_tokenId] - 1;
    //     TokenMeta memory order = nftOrders[idx];
    //     require(block.timestamp >= order.nextUpdateTime, "cannot cancel on current time");
    //     remove(idx);
    //     nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    //     nftOrderIndexs[_tokenId] = 0;
    //     tokenOwners[_tokenId] = address(0);
    //     emit Cancel(_tokenId, msg.sender);
    // }

    // function buyItem(uint256 _tokenId) external payable {
    //     require(nftOrderIndexs[_tokenId] != 0, "order not exist");
    //     uint256 idx = nftOrderIndexs[_tokenId] - 1;
    //     TokenMeta memory order = nftOrders[idx];
    //     require(msg.value == order.price, "value not equal price");
    //     address seller = tokenOwners[_tokenId];
    //     uint256 feeMarket = feeMarketNum.mul(msg.value).div(1000);
    //     uint256 feeCreator = feeCreatorNum.mul(msg.value).div(1000);
    //     uint256 feeSeller = msg.value.sub(feeMarket).sub(feeCreator);

    //     TransferHelper.safeTransferETH(feeMarketReceiver, feeMarket);
    //     TransferHelper.safeTransferETH(feeCreatorReceiver, feeCreator);
    //     TransferHelper.safeTransferETH(seller, feeSeller);
    //     remove(idx);
    //     nftOrderIndexs[_tokenId] = 0;
    //     tokenOwners[_tokenId] = address(0);

    //     nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    //     emit BuyNft(_tokenId, seller, msg.sender, msg.value, block.timestamp);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}