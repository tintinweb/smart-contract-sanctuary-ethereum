// SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract BNPL is ReentrancyGuard, Ownable, IERC721Receiver {

    address payable public immutable govAccount;
    address payable private pool;
    uint256 public feePercent;

    uint256 public itemCount;

    string private key;

    enum ItemState{
        // Default value
        Inactive,
        // The Item has been Created on the list 
        Created,
        // The Item has been already sold
        Sold,
        // The Item has been canceled
        Canceled
    }

    enum OrderState{
        // Default value
        Inactive,
        // The Order is Created 
        Created,
        // The Order has already paid
        Paid
    }
    

    struct Item{
        uint256 itemId;
        IERC721 nft;
        uint256 tokenId;
        address payable seller;
        ItemState state;
    }

    struct Order{
        uint256 OrderId;
        address buyer;
        address custodioWallet;
        IERC721 nft;
        uint256 tokenId;
        uint256 price;
        uint256 downPayment;
        uint256 rest;
        OrderState state;
    }

    mapping(uint256 => Item) public items;
    mapping(uint256 => Order) public orders;
    mapping(address => address) public wallets;


    event Deposit(uint256 amount);

    event Offered(
        uint256 itemId,
        address indexed nft,
        uint256 tokenId,
        address indexed seller
    );
    

    event OrderList(
        uint256 indexed OrderId,
        address indexed buyer,
        address custodioWallet,
        address nft,
        uint256 tokenId,
        uint256 price,
        uint256 downPayment,
        OrderState state,
        address indexed seller
    );

    event Repayment(
        uint256 indexed OrderId,
        address indexed buyer,
        uint256 indexed amount
    );

    constructor(){
        govAccount = payable(msg.sender);
    }
    
    // overwrite openzeppelin ERC721 received
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // manipulate wallet map
    function mapWallet(address _userWallet, address _custodioWallet) external onlyOwner {
        wallets[_userWallet] = _custodioWallet;
    }

    function getCustodioWallet(address _userWallet) view external returns(address) {
        return wallets[_userWallet];
    }

    function setPool(address _pool) external onlyOwner{
        pool = payable(_pool);
    }

    function getOrder(uint256 _orderId) external view returns(Order memory){
        return orders[_orderId];
    }
  
    /* @dev buy now
       List method TBD
    */ 
     function buyNow(uint256 _itemId, uint256 _orderId, uint256 _nftPrice, uint256 _downPayment, address _custodioWallet, bytes32 _sign) external payable nonReentrant{
        
        bytes32 sign = hashByShaToString(_downPayment, _orderId, key);
        require(sign == _sign, "Inequivalent sign");

        // check item exist
        require(_itemId > 0 && _itemId <= itemCount,"item does not exist");
        // nft price need to greater than 0
        require(_nftPrice>0, "Invalid Price");
        // down payment need to between 0 and nft price
        require(_downPayment>0 && _downPayment <= _nftPrice, "Invalid Down Payment");
        // value need to cover down payment
        require(msg.value >= _downPayment, "not enough ether to cover item price and market fee");
        // custodio wallet need to exist
        require(_custodioWallet != address(0), "Cusridio Wallet does not exist");

        // Get item
        Item storage item = items[_itemId];
        // Check item is available
        require(item.state == ItemState.Created, "item is unavailable");
        // Check the balance of contract is greater than price
        require(address(this).balance >= _nftPrice, "Insufficient balance to lend");
        uint rest = _nftPrice - _downPayment;

        orders[_orderId] = Order(
            _orderId,
            msg.sender,
            _custodioWallet,
            item.nft,
            item.tokenId,
            _nftPrice,
            _downPayment,
            rest,
            OrderState.Created
            );

        // pay seller 
        item.seller.transfer(_nftPrice);
         // update item state
        item.state = ItemState.Sold;
        items[_itemId] = item;
        // transfer nft to pool
        item.nft.transferFrom(address(this), pool, item.tokenId);
        
        emit OrderList(
            _orderId,
            msg.sender,
            _custodioWallet,
            address(item.nft),
            item.tokenId,
            _nftPrice,
            _downPayment,
            OrderState.Created,
            item.seller
        );
     }

    function repay(uint256 _orderId, uint256 _amount, bytes32 _sign) external payable nonReentrant{
        
        // bytes32 sign = hashByShaToString(_amount, _orderId, key);
        // require(sign == _sign, "Inequivalent sign");
        
        Order memory order = orders[_orderId];
        require(order.state == OrderState.Created, "Invalid order");
        require(msg.sender==order.buyer, "No privilege to pay this order" );
        require(_amount > 0, "Invalid amount to pay this order");
        require(msg.value>=_amount, "Insufficient value to pay");
        
        order.rest -= _amount;
        orders[_orderId] = order;

        emit Repayment(
            _orderId,
            msg.sender,
            _amount
        );
    }

    function orderFinish(uint256 _orderId) external onlyOwner{
        Order memory order = orders[_orderId];
        order.state = OrderState.Paid;
        orders[_orderId] = order;
    }

    /* 
       List item in marketplace
    */ 
    function listItem(IERC721 _nft, uint256 _tokenId) external nonReentrant {
        require(_tokenId >= 0, "Token Id is unavailable!");

        itemCount ++;

        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        items[itemCount] = Item(
            itemCount,
            _nft,
            _tokenId,
            payable(msg.sender),
            ItemState.Created
        );

        // emit Offered event
        emit Offered(
            itemCount, 
            address(_nft), 
            _tokenId, 
            msg.sender);
    }

    // cancel listed item and get item back
    function cancelItem(uint256 _itemId) external nonReentrant {
        Item storage item = items[_itemId];
        require(msg.sender == item.seller, "No privilege to cancel this item");
        item.state = ItemState.Canceled;
        items[_itemId] = item;
       item.nft.safeTransferFrom(address(this), msg.sender, item.tokenId);
    }

    // pool deposit 
    function deposit() external payable {
        emit Deposit(msg.value);
    }

    // withdraw to pool - only deployer
    function withdraw(uint256 _amount) external onlyOwner returns(bool) {
        require(_amount<=address(this).balance, "Insufficient balance");
        return payable(pool).send(_amount);
    }

    // Get contracts balance
    function getBalance() external view returns(uint256){
        return address(this).balance;
  }

    // set key 
    function setKey(string memory _key) external onlyOwner{
        key = _key;
    }


    // Convert to string & Hash by sha256
    function hashByShaToString(uint256 _downPayment,  uint256 _orderId,  string memory _key) public pure returns(bytes32) {
      string memory down_payment = Strings.toString(_downPayment);
      string memory order_id = Strings.toString(_orderId);
      
      return sha256(abi.encodePacked(down_payment, order_id, _key));
    }

    function encode(uint256 _downPayment,  uint256 _orderId,  string memory _key) public pure returns(bytes memory) {
      string memory down_payment = Strings.toString(_downPayment);
      string memory order_id = Strings.toString(_orderId);
      
      return abi.encodePacked(down_payment, order_id, _key);
    }

    function checkSign(uint256 _downPayment, uint256 _orderId,  string memory _key, bytes32 _sign) external pure returns(bool){
        bytes32 sign = hashByShaToString(_downPayment,_orderId, _key);
        return sign == _sign;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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