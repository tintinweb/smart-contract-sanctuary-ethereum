// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibOrder.sol";
import "./IMarket.sol";
import "./copyright_payment.sol";
import "./common/meta-transactions/EIP712Base.sol";


contract haexMarket is EIP712Base, ReentrancyGuard, IMarket, CopyrightPayment {
    bytes32 public constant HashOrderStruct = keccak256(
        "Order(address taker,address maker,uint256 maker_nonce,uint64 listing_time,uint64 expiration_time,address nft_contract,uint256 token_id,address payment_token,uint256 fixed_price,uint256 amount,bytes32 extend)"
    );

    mapping(address => bool) public operators;
    string name;
    string version;

    mapping(address => bool) public allowedNft;
    bool public allNftAllowed;
    mapping(address => uint256) public allowedPayment;
    mapping(bytes32 => bool) public finalizedOrder;
    mapping(address => uint256) public userNonce;
    mapping(address => mapping(bytes32 => bool)) public canceledOrder;
    mapping(address => address) public proxies;

    uint256 constant public feeDenominator = 1000000000; // 1,000,000,000
    uint256 public maxRoyaltyRate = feeDenominator / 10; // 10%
    uint256 public feeRate = 20000000;  // 20,000,000 / 1,000,000,000 == 2%
    address public feeRecipient;

    event OrderCancelled(address indexed maker, bytes32 indexed order_digest);
    event AllOrdersCancelled(address indexed maker, uint256 current_nonce);
    event FixedPriceOrderMatched(address tx_origin, address taker, address maker, bytes32 order_digest, bytes order_bytes); // FixedPriceOrder order);
    event Fallback(address indexed addr, uint256 value, bool success);

    modifier onlyMarketOperator() {
        require(operators[msg.sender] || msg.sender == owner(), "Caller is not market operator");
        _;
    }

    constructor (string memory _name, string memory _version, address _feeRecipient) {
        name = _name;
        version = _version;
        feeRecipient = _feeRecipient;
        _initializeEIP712(name, _version);
    }

    function setMarketOperator(address addr, bool flag) external onlyOwner {
        if (!flag) {
            delete operators[addr];
        } else {
            operators[addr] = true;
        }
        SetCopyrightOperator(addr, flag);
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= feeDenominator, "Fee rate is too high");
        feeRate = _feeRate;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getVersion() public view returns (string memory) {
        return version;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient rate is address(0)");
        feeRecipient = _feeRecipient;
    }

    function setAllNftAllowed(bool _allNftAllowed) external onlyMarketOperator {
        allNftAllowed = _allNftAllowed;
    }

    function setNftAllowed(address _contract, bool flag) external onlyMarketOperator {
        if (!flag) {
            delete allowedNft[_contract];
        } else {
            allowedNft[_contract] = true;
        }
    }

    function setPaymentAllowed(address _contract, uint256 min_price) external onlyMarketOperator {
        if (min_price == 0) {
            delete allowedPayment[_contract];
        } else {
            allowedPayment[_contract] = min_price;
        }
    }

    function exchangeFixedPrice(bool maker_sells_nft, address taker, LibOrder.Order memory order, LibOrder.Sig memory maker_sig, LibOrder.Sig memory taker_sig) external override nonReentrant{
        (bytes32 order_digest, bytes memory order_bytes) = checkOrder(taker, order, maker_sig, taker_sig);

        address nft_seller = order.maker;
        address nft_buyer = taker;
        if (!maker_sells_nft) {
            nft_seller = taker;
            nft_buyer = order.maker;
        }

        // order.amount > 0 is erc1155 contract
        if (order.amount > 0 ) {
            require(IERC1155(order.nft_contract).isApprovedForAll(nft_seller, address(this)) == true, "The contract does not allow me to operate this NFT");
            IERC1155(order.nft_contract).safeTransferFrom(nft_seller, nft_buyer, order.token_id, order.amount, "");
        } else {
            require(IERC721(order.nft_contract).getApproved(order.token_id) == address(this), "The contract does not allow me to operate this NFT");
            IERC721(order.nft_contract).safeTransferFrom(nft_seller, nft_buyer, order.token_id, "");
        }

        address receiver;
        uint256 royaltyAmount;
        try IERC2981(order.nft_contract).supportsInterface(type(IERC2981).interfaceId) returns (bool support) {
            if (support) {
                (receiver, royaltyAmount) = IERC2981(order.nft_contract).royaltyInfo(order.token_id, order.fixed_price);
            }
        } catch {
            receiver = address(0);
            royaltyAmount = 0;
        }

        if (receiver == address(0)) {
            (receiver, royaltyAmount) = CopyrightFee(order.nft_contract, order.token_id);
        }

        if (receiver != address(0) && royaltyAmount > 0) {
            royaltyAmount = order.fixed_price * royaltyAmount;
        }

        payToken(order, nft_seller, nft_buyer, receiver, royaltyAmount);
        finalizedOrder[order_digest] = true;
        emit FixedPriceOrderMatched(tx.origin, taker, order.maker, order_digest, order_bytes);
    }

    function checkOrder(address taker, LibOrder.Order memory order, LibOrder.Sig memory makerSig, LibOrder.Sig memory takerSig) public view returns(bytes32 order_digest, bytes memory order_bytes) {
        address maker = order.maker;
        if (order.taker != address(0)) {
            require(taker == order.taker, "Taker is not the one set by maker");
        }

        require(maker != taker, "Taker is same as maker");
        require(maker != address(0) && taker != address(0), "Maker or Taker is address(0)");
        require(order.expiration_time >= block.timestamp && order.listing_time <= block.timestamp, "Time error");
        require(order.maker_nonce == userNonce[maker], "Maker nonce doesn't match");
        require(allNftAllowed || allowedNft[order.nft_contract], "NFT contract is not supported");
        uint256 min_price = allowedPayment[order.payment_token];
        require(order.fixed_price > min_price && min_price > 0, "Payment token contract is not supported or price is too low");

        order_bytes = fixedPriceOrderEIP712Encode(order);
        order_digest = toTypedMessageHash(keccak256(order_bytes));

        require((!finalizedOrder[order_digest]) && (!canceledOrder[maker][order_digest]) && (!canceledOrder[taker][order_digest]), "The order is finalized or canceled");
        require(maker == ecrecover(order_digest, makerSig.v, makerSig.r, makerSig.s), "Maker's signature doesn't match");
        require(taker == ecrecover(order_digest, takerSig.v, takerSig.r, takerSig.s), "Taker's signature doesn't match");

        return (order_digest, order_bytes);
    }

    function payToken(LibOrder.Order memory order, address nft_seller, address nft_buyer, address royalty, uint256 royalty_amount) private {
        uint256 platform_amount = order.fixed_price * feeRate / feeDenominator;
        uint256 remain_amount;

        if (royalty != address(0)) {
            remain_amount = order.fixed_price  - (royalty_amount + platform_amount);
        } else {
            remain_amount = order.fixed_price  - platform_amount;
        }

        // 合约token
        if (order.payment_token != address(0)) {
            require(msg.value == 0, "Msg.value should be zero");
            require(IERC20(order.payment_token).transferFrom(nft_buyer, feeRecipient, platform_amount), "Token payment (platform fee) failed");
            require(IERC20(order.payment_token).transferFrom(nft_buyer, nft_seller, remain_amount), "Token payment (to seller) failed");
            if (royalty != address(0)) {
                require(IERC20(order.payment_token).transferFrom(nft_buyer, royalty, royalty_amount), "Token payment (royalty fee) failed");
            }

        } else {
            bool failed = false;
            require(failed == true, "Currently, native tokens are not supported");
        }
    }

    function cancelOrder(LibOrder.Order memory order) external  {
        bytes memory order_bytes = fixedPriceOrderEIP712Encode(order);
        bytes32 order_digest = toTypedMessageHash(keccak256(order_bytes));
        require(!finalizedOrder[order_digest], "Order is finalized");

        if (msg.sender != order.maker && operators[msg.sender] == false) {
            return;
        }

        canceledOrder[order.maker][order_digest] = true;

        emit OrderCancelled(order.maker, order_digest);
    }

    function cancelAllOrders(address addr) external {
        address sender = msg.sender;
        if (operators[sender] == true) {
            sender = addr;
        }
        ++userNonce[sender];
        uint256 nonce = userNonce[sender];

        emit AllOrdersCancelled(sender, nonce);
    }

    function fixedPriceOrderEIP712Encode(LibOrder.Order memory order) internal pure returns(bytes memory) {
        bytes memory order_bytes = abi.encode(
            HashOrderStruct,
            order
        );
        return order_bytes;
    }

    fallback() payable external {
        (bool success, ) = msg.sender.call{value: msg.value}("0x");
        emit Fallback(msg.sender, msg.value, success);
    }

    receive() external payable {}

    function addUserProxy(address user, address proxy) external onlyMarketOperator {
        proxies[user] = proxy;
    }

    function delUserProxy(address user) external onlyMarketOperator {
        if (proxies[user] != address(0)) {
            delete(proxies[user]);
        }
    }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    constructor() {
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

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library LibOrder {
    using LibOrder for Order;

    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    // OrderType: FixedPrice; EnglishAuction; DutchAuction
    struct Order {
       address taker; // address(0) means anyone can trade
       address maker;
       uint256 maker_nonce;
       uint64 listing_time;
       uint64 expiration_time;
       address nft_contract;
       uint256 token_id;
       address payment_token; // address(0) means the coin of the public chain (ETH, HT, MATIC...)
       uint256 fixed_price;
       uint256 amount; // ERC20 amount=0, ERC1155 amount>0
        bytes32 extend;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;
import "./LibOrder.sol";

interface IMarket {
    function exchangeFixedPrice(bool maker_sells_nft, address taker, LibOrder.Order memory order, LibOrder.Sig memory maker_sig, LibOrder.Sig memory taker_sig) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CopyrightPayment is Ownable {

    string internal constant _officialMask = "haexCopyright";

    struct copyrightItem {
        address payable owner;
        address nft;
        uint fee;
        bool valid;
        uint tokenId;
    }

    mapping(address => bool) private _operator;
    mapping(address => bool) private _officialNft;
    mapping(bytes32 => copyrightItem) private _copyrightOwners;

    constructor() Ownable() {}

    event AddCopyright(address nft, address owner, uint256 tokenId, uint256 fee, bytes32 key);
    event DelCopyright(address nft, address owner, uint256 tokenId, bytes32 key);

    // 设置操作者地址，仅可以合约所有者设置
    function SetCopyrightOperator(address operator, bool flag) public {
        require(msg.sender == owner(), "Not the owner of contract");
        _operator[operator] = flag;
    }

    function IsCopyrightOperator(address operator) public view returns (bool) {
        return _operator[operator] || operator == owner();
    }

    function SetCopyrightOfficial(address officialNft, bool flag) public {
        require(msg.sender == owner(), "Not the owner of contract");
        _officialNft[officialNft] = flag;
    }

    function IsCopyrightOfficial(address officialNft) public view returns (bool) {
        return _officialNft[officialNft];
    }

    function CopyrightFee(address nft, uint tokenId) public view returns (address, uint) {
        bytes32 key = _getCopyrightKey(nft, tokenId);
        uint fee = _copyrightOwners[key].fee;
        address addr = _copyrightOwners[key].owner;
        if (_copyrightOwners[key].nft != nft) {
            return(address(0), 0);
        }
        if (_copyrightOwners[key].valid == true) {
            return (addr, fee);
        }

        return (addr, 0);
    }

    function AddCopyrightPayment(address nft, address owner, uint tokenId, uint fee) public {
        require(IsCopyrightOperator(msg.sender) == true, "Not the operator of contract");
        require(fee <= 500, "The copyright fee cannot exceed 50%");
        bytes32 key = _getCopyrightKey(nft, tokenId);
        _copyrightOwners[key] = copyrightItem(payable(owner), nft, fee, true, tokenId);

        emit AddCopyright(nft, owner, tokenId, fee, key);
    }

    function BatchAddCopyrightPayment(address[] memory nfts, address[] memory owners, uint[] memory tokenIds, uint[] memory fees) public {
        require(nfts.length == fees.length && owners.length == fees.length && tokenIds.length == fees.length,  "batch params num is require");
        for (uint256 i = 0; i < fees.length; i++) {
            AddCopyrightPayment(nfts[i], owners[i], tokenIds[i], fees[i]);
        }
    }

    function DelCopyrightPayment(address nft, uint tokenId) public {
        require(IsCopyrightOperator(msg.sender) == true, "Not the operator of contract");
        bytes32 key = _getCopyrightKey(nft, tokenId);
        address owner = _copyrightOwners[key].owner;
        delete _copyrightOwners[key];

        emit DelCopyright(nft, owner, tokenId, key);
    }

    function BatchDelCopyrightPayment(address[] memory nfts, uint[] memory tokenIds) public {
        require(nfts.length == tokenIds.length,  "batch params num is require");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            DelCopyrightPayment(nfts[i], tokenIds[i]);
        }
    }

    function _getCopyrightKey(address nft, uint256 tokenId) private view returns (bytes32){
        if (IsCopyrightOfficial(nft)) {
            return keccak256(abi.encode(nft, tokenId));
        } else {
            return keccak256(abi.encode(nft, _officialMask));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Initializable.sol";

contract EIP712Base is Initializable {
	struct EIP712Domain {
		string name;
		string version;
		address verifyingContract;
		bytes32 salt;
	}

//	string public constant ERC712_VERSION = "1";

	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
	keccak256(
		bytes(
			"EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
		)
	);
	bytes32 internal domainSeperator;

	// supposed to be called once while initializing.
	// one of the contracts that inherits this contract follows proxy pattern
	// so it is not possible to do this in a constructor
	function _initializeEIP712(string memory name, string memory version) internal initializer {
		_setDomainSeperator(name, version);
	}

	function _setDomainSeperator(string memory name, string memory version) internal {
		domainSeperator = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version)),
				address(this),
				bytes32(getChainId())
			)
		);
	}

	function getDomainSeperator() public view returns (bytes32) {
		return domainSeperator;
	}

	function getChainId() public view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}

	/**
	 * Accept message hash and returns hash message in EIP712 compatible form
	 * So that it can be used to recover signer from signature signed using EIP712 formatted data
	 * https://eips.ethereum.org/EIPS/eip-712
	 * "\\x19" makes the encoding deterministic
	 * "\\x01" is the version byte to make it compatible to EIP-191
	 */
	function toTypedMessageHash(bytes32 messageHash)
	internal
	view
	returns (bytes32)
	{
		return
		keccak256(
			abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
		);
	}
}

// SPDX-License-Identifier: MIT

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

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Initializable {
	bool inited = false;

	modifier initializer() {
		require(!inited, "already inited");
		_;
		inited = true;
	}
}