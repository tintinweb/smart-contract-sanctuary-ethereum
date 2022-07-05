/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

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

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}

interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface IWETH{
    function withdraw(uint amount) external;
}

interface IStructure{

    enum TradingType{trading,auction}

    enum State{solding,saled,cancelled,nul}

    enum PriceState{effective,invalid}

    event Created(TradingType indexed tradingType,address indexed owner,uint256 orderId,uint256 time);

    event Purchase(address indexed purchaser,uint256 orderId,uint256 price,uint256 time);

    event Cancel(TradingType indexed tradingType,address indexed canceller,uint256 orderId,uint256 time);

    event Modify(TradingType indexed tradingType,address indexed moder,uint256 orderId,uint256 single,uint256 time);

    event Bidding(address indexed bidder,uint256 orderId,uint256 offerId,uint256 price,uint256 time);

    event Delivery(address indexed deliverer,address recever,uint256 orderId,uint256 offerId,uint256 price,uint256 time);

    event CancelBidding(address indexed canceller,uint256 orderId,uint256 offerId,uint256 time);
    struct Option{
        TradingType tradingType;
        address token;
        address creator;
        uint    tokenId;
        uint256 amount;
        uint256 single;
        uint256 expiration;
        uint256 expect;
    }
    //[]
    //"0","0x7D0937319cF4Be8eDF60f4ff32ee4A6d1Fe056B9","0x3024a5c0870dde2b65ddDd1BFC139f94941EDCAC","1","1","1000000","70","0"

    struct Offer{
        address bidder;
        uint256 price;
    }

    struct StandardOffer{
        address bidder;
        uint256 price;
        PriceState state;
    }

    struct StandardOption{
        TradingType tradingType;
        address token;
        address creator;
        uint    tokenId;
        uint256 amount;
        uint256 single;
        uint256 expect;
        uint256 expiration;
        State   state;
    }

}

interface ISynchron{

    function add(address customer,bytes memory info) external  returns(uint256 optionId);

    function update(uint256 optionId,bytes memory info) external;

    function updateWithProperty(uint256 optionId,bytes memory info) external;

    function addBidding(uint256 optionId,bytes memory offer,address customer) external returns(uint256 offerId);

    function cancelBiding(uint256 offerId,bytes memory offer) external;
    
    function getBiddingForOrder(uint256 optionId) external  view returns(uint256[] memory offers);

    function getOptions() external  view returns(uint256[] memory effective,uint256[] memory invalid);

    function getUserOptions(address customer) external view returns(uint256[] memory sale,uint256[] memory purchase,uint256[] memory offer);
    
    function optionInfo(uint256 optionId) external view returns(bytes memory info);

    function bidCorrespondingOption(uint256 offerId) external view returns(uint256 optionId);

    function getOptionCorrespondingBid(uint256 optionId) external view returns(uint256[] memory offerIds);

    function offerInfo(uint256 offerId) external view returns(bytes memory offerInfo);

    function safeTransfer(address token,address recipient,uint256 tokenId,uint256 amount) external;

    function safeTranferWeth(address token,address sender,address creator,address feeTo,address royal,uint256 amount,uint256 fee,uint256 toReward,uint256 toRoyal) external;
}

contract Synchron is ISynchron,ERC1155Holder,ERC721Holder,IStructure{
    using SafeMath for uint256;

    uint256[] effectiveOptionIds;

    uint256[] invalidOptionIds;

    struct User{

        uint256[] saleOptionIds;

        uint256[] purchaseOptionIds;

        uint256[] offerIds;
    }
    mapping(address => User) userInfo;

    mapping(uint256 => bytes) public override optionInfo;
    
    mapping(uint256 => uint) public optionIndex;

    mapping(uint256 => uint256[]) optionCorrespondingBid;

    mapping(uint256 => uint256) public override bidCorrespondingOption;

    mapping(uint256 => bytes) public override offerInfo;

    mapping(uint256 => uint) public offerIndex;

    uint256 initOptionNumber;

    uint256 initOfferNumber = 1;

    address operator;

    address owner;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender,"Synchron:not permit!");
        _;
    }

    modifier onlyOperator(){
        require(operator == msg.sender,"Synchron:not permit!");
        _;
    }

    function updateOperator(address _operator) public onlyOwner{
        operator = _operator;
    }

    function add(address customer,bytes memory info) external override onlyOperator returns(uint256 optionId){
        optionInfo[initOptionNumber] = info;
        effectiveOptionIds.push(initOptionNumber);
        optionIndex[initOptionNumber] = effectiveOptionIds.length - 1;
        optionId = initOptionNumber;
        User storage user = userInfo[customer];
        user.saleOptionIds.push(initOptionNumber);
        initOptionNumber++;
    }

    function update(uint256 optionId,bytes memory info) external override onlyOperator{
        optionInfo[optionId] = info;
    }

    function updateWithProperty(uint256 optionId,bytes memory info) external override onlyOperator{   
        if(effectiveOptionIds.length > 0 && optionIndex[optionId] < effectiveOptionIds.length - 1){
            effectiveOptionIds[optionIndex[optionId]] = effectiveOptionIds[effectiveOptionIds.length - 1];
        }
        effectiveOptionIds.pop();
        optionInfo[optionId] = info;
        invalidOptionIds.push(optionId);
    }

    function addBidding(uint256 optionId,bytes memory offer,address customer) external override onlyOperator returns(uint256 offerId){
        offerId = initOfferNumber;
        offerInfo[initOfferNumber] = offer;
        optionCorrespondingBid[optionId].push(initOfferNumber);
        bidCorrespondingOption[initOfferNumber] = optionId;
        offerIndex[initOfferNumber] = optionCorrespondingBid[optionId].length - 1;
        User storage user = userInfo[customer];
        user.offerIds.push(initOfferNumber);
        initOfferNumber++;
    }

    function cancelBiding(uint256 offerId,bytes memory offer) external override onlyOperator{
        uint256 optionId = bidCorrespondingOption[offerId];
        offerInfo[offerId] = offer;
        delete optionCorrespondingBid[optionId][offerIndex[offerId]];
    }

    function getBiddingForOrder(uint256 optionId) external override view returns(uint256[] memory offers){
        offers = optionCorrespondingBid[optionId];
    }

    function getOptions() external override view returns(uint256[] memory effective,uint256[] memory invalid){
        effective = effectiveOptionIds;
        invalid = invalidOptionIds;
    }

    function getUserOptions(address customer) external override view returns(uint256[] memory sale,uint256[] memory purchase,uint256[] memory offer){
        User storage user = userInfo[customer];
        sale = user.saleOptionIds;
        purchase = user.purchaseOptionIds;
        offer = user.offerIds;
    }

    function getOptionCorrespondingBid(uint256 optionId) external override view returns(uint256[] memory offerIds){
        return optionCorrespondingBid[optionId];
    }

    function safeTransfer(address token,address recipient,uint256 tokenId,uint256 amount) external override onlyOperator{
        if(IERC165(token).supportsInterface(0xd9b67a26) != false){
            IERC1155(token).safeTransferFrom(address(this), recipient, tokenId, amount, new bytes(0));
        }else{
            IERC721(token).safeTransferFrom(address(this), recipient, tokenId, new bytes(0));
        }
        //supportsInterface(0xd9b67a26)
    }

    function safeTranferWeth(address token,address sender,address creator,address feeTo,address royal,uint256 amount,uint256 fee,uint256 toReward,uint256 toRoyal) external override onlyOperator{
        TransferHelper.safeTransferFrom(token, sender, address(this), amount);
        IWETH(token).withdraw(amount);
        TransferHelper.safeTransferETH(creator, toReward);
        TransferHelper.safeTransferETH(feeTo, fee);
        if(royal != address(0) && toRoyal > 0){
            TransferHelper.safeTransferETH(royal, toRoyal);
        }   
    }
}

interface IGlibrary is IStructure{

    function analyseOption(bytes memory optionInfo) external pure returns(StandardOption memory option);

    function getPurchaseStatus(bytes memory optionInfo,address customer,uint256 price) external view returns(bool state);

    function getCancelStatus(bytes memory optionInfo,address operator,uint256[] memory offerIds) external view returns(bool state);

    function analyseOffer(bytes memory offerInfo) external pure returns(StandardOffer memory offer);

    function getCancelBiddingStatus(bytes memory optionInfo,bytes memory offerInfo,address customer) external view returns(bool state);

    function getDeliveryStatus(bytes memory optionInfo,address customer) external view returns(bool state);

    function getModifyStatus(bytes memory optionInfo,address customer,uint256 price) external view returns(bool state);
}

contract Glibrary is IGlibrary{

    using SafeMath for uint256;

    function analyseOption(bytes memory optionInfo) public override pure returns(StandardOption memory option){
        (TradingType tradingType,address token,address creator,uint tokenId,uint256 amount,
        uint256 single,uint256 expect,uint256 expiration,State   state) = abi.decode(optionInfo,(TradingType,address,address,
        uint,uint256,uint256,uint256,uint256,State));
        option = StandardOption(tradingType,token,creator,tokenId,amount,single,expect,expiration,state);
    }

    function analyseOffer(bytes memory offerInfo) public override pure returns(StandardOffer memory offer){
        (address customer,uint256 price,PriceState state) = abi.decode(offerInfo,(address,uint256,PriceState));
        offer = StandardOffer(customer,price,state);
    }

    function getPurchaseStatus(bytes memory optionInfo,address customer,uint256 price) external override view returns(bool state){
        StandardOption memory option = analyseOption(optionInfo);
        if(block.timestamp <= option.expiration && option.tradingType == TradingType.trading){
            if(option.creator != customer && price >= option.single.mul(option.amount) && option.state == State.solding) state = true;
        }
    }

    function getModifyStatus(bytes memory optionInfo,address customer,uint256 price) external override view returns(bool state){
        StandardOption memory option = analyseOption(optionInfo);
        if(block.timestamp <= option.expiration){
            if(option.creator == customer){
                if(option.tradingType == TradingType.trading && option.state == State.solding) state = true;
                if(option.tradingType == TradingType.auction && price <= option.single && option.state == State.solding) state = true; 
            }
        }
    }

    function getCancelStatus(bytes memory optionInfo,address operator,uint256[] memory offerIds) external override view returns(bool state){
        StandardOption memory option = analyseOption(optionInfo);
        if(option.tradingType == TradingType.trading){
            if(option.creator == operator && option.state == State.solding) state = true;
        }else{
            if(option.creator == operator && option.state == State.solding){
                if(offerIds.length == 0 || block.timestamp > option.expiration){
                    state = true;
                }
            }
        }     
    }

    function getCancelBiddingStatus(bytes memory optionInfo,bytes memory offerInfo,address customer) external override view returns(bool state){
        StandardOption memory option = analyseOption(optionInfo);
        if(option.expiration > block.timestamp && option.state == State.solding){
            StandardOffer memory offer = analyseOffer(offerInfo);
            if(offer.bidder == customer && offer.state == PriceState.effective){
                state = true;
            }
        }
    }

    function getDeliveryStatus(bytes memory optionInfo,address customer) external override view returns(bool state){
        StandardOption memory option = analyseOption(optionInfo);
        if(option.creator == customer && block.timestamp >= option.expiration) state = true;
    }


}

interface ITrading is IStructure{
    function getPayment(uint256 optionId) external view returns(uint256 payment,uint256 expect);

    function getEffectiveOffer(uint256 optionId) external view returns(uint256 offerId);

    function getBiddingStatus(uint256 optionId,address customer,uint256 price) external view returns(bool state);

    function createOption(Option calldata option) external returns(bytes memory orderHash);

    function modify(uint256 optionId,uint256 price) external;

    function purchase(uint256 optionId) external payable;

    function cancelOption(uint256 optionId) external;

    function bidding(uint256 optionId,uint256 price) external;

    function cancelBidding(uint256 optionId,uint256 offerId) external;

    function getDeliverableOffer(uint256 optionId) external view returns(uint256 offerId);

    function delivery(uint256 optionId) external;
}

contract Trading is ITrading{

    using SafeMath for uint256;

    address synchron;

    address glibrary;

    address owner;

    address feeTo;

    address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    uint256 fixedFee = 2;

    uint256 auctionFee = 25;


    constructor(address _sync,address _library){
        owner = msg.sender;
        synchron = _sync;
        glibrary = _library;
        feeTo = owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"Trading:not permit");
        _;
    }

    function setFeeInfo(uint256 _fixed,uint256 _auction,address _to) public onlyOwner{
        fixedFee = _fixed;
        auctionFee = _auction;
        feeTo = _to;
    }

    function safeTransfer(address token,address sender,address recipient,uint256 tokenId,uint256 amount) internal {
        if(IERC165(token).supportsInterface(0xd9b67a26) != false){
            //判断是否授权，如果没有授权则去调permit函数
            IERC1155(token).safeTransferFrom(sender, recipient, tokenId, amount, new bytes(0));
        }else{
            IERC721(token).safeTransferFrom(sender, recipient, tokenId, new bytes(0));
        }
    }

    function getPayment(uint256 optionId) public override view returns(uint256 payment,uint256 expect){
        bytes memory info = ISynchron(synchron).optionInfo(optionId);
        StandardOption memory option = IGlibrary(glibrary).analyseOption(info);
        if(option.tradingType == TradingType.trading){
            payment = option.amount.mul(option.single);
            expect = 0;
        }else{
            payment = option.amount.mul(option.single);
            expect = option.amount.mul(option.expect);
        }
    }

    function getApproved(address customer) internal view returns(uint256){
        return IERC20(weth).allowance(customer, synchron);
    }

    function getEffectiveOffer(uint256 optionId) public override view returns(uint256 offerId){
        uint256[] memory offerIds = ISynchron(synchron).getOptionCorrespondingBid(optionId);
        for(uint i=0; i<offerIds.length; i++){
            if(offerIds[i] > 0){
                offerId = offerIds[i];
            }
        }
    }

    function getBiddingStatus(uint256 optionId,address customer,uint256 price) public override view returns(bool state){
        bytes memory info = ISynchron(synchron).optionInfo(optionId);
        //uint256[] memory offerIds = ISynchron(synchron).getOptionCorrespondingBid(optionId);
        StandardOption memory option = IGlibrary(glibrary).analyseOption(info);
        if(option.expiration > block.timestamp && customer != option.creator && option.tradingType != TradingType.trading && option.state == State.solding){
            uint256 currentPrice;
            if(getEffectiveOffer(optionId) == 0) currentPrice = option.amount.mul(option.single);
            if(getEffectiveOffer(optionId) > 0)  {
                bytes memory offerInfo = ISynchron(synchron).offerInfo(getEffectiveOffer(optionId));
                StandardOffer memory offer = IGlibrary(glibrary).analyseOffer(offerInfo);
                currentPrice = offer.price.add(offer.price.mul(5).div(100));
            }

            uint256 property = IERC20(weth).balanceOf(customer);
            if(property >= price && price >= currentPrice && getApproved(customer) >= price) state = true;
        }
    }

    function createOption(Option calldata option) external override returns(bytes memory orderHash){
        require(option.token != address(0) && option.creator != address(0),"Trading:Zero address");
        require(option.expiration > 0 && option.single > 0 && option.amount > 0,"Trading:Order information error");
        safeTransfer(option.token, msg.sender, synchron, option.tokenId, option.amount);
        StandardOption memory info = StandardOption(
            option.tradingType,
            option.token,
            option.creator,
            option.tokenId,
            option.amount,
            option.single,
            option.expect,
            option.expiration.mul(3600).add(block.timestamp),
            State.solding
            );
        uint256 optionId = ISynchron(synchron).add(msg.sender,abi.encode(info));
        orderHash = abi.encode(info);
        emit Created(option.tradingType, option.creator, optionId, block.timestamp);
    }

    function modify(uint256 optionId,uint256 price) external override{
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        require(IGlibrary(glibrary).getModifyStatus(optionInfo, msg.sender, price)==true,"Trading:Error in modifying information");
        StandardOption memory option = IGlibrary(glibrary).analyseOption(optionInfo);
        option.single = price;
        ISynchron(synchron).update(optionId, abi.encode(option));
        emit Modify(option.tradingType, msg.sender, optionId, price, block.timestamp);
    }

    function purchase(uint256 optionId) external override payable{
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        require(IGlibrary(glibrary).getPurchaseStatus(optionInfo,msg.sender,msg.value) == true,"Trading:Purchase information error!");
        StandardOption memory option = IGlibrary(glibrary).analyseOption(optionInfo);
        option.state = State.saled;
        ISynchron(synchron).safeTransfer(option.token, msg.sender, option.tokenId, option.amount);
        //考虑外来合约不支持eip2981
        (address receiver,uint256 amount) = IERC2981(option.token).royaltyInfo(option.tokenId, msg.value);
        uint256 fee = msg.value.mul(fixedFee).div(100);
        uint256 toCreator = msg.value.sub(fee).sub(amount);
        if(receiver != address(0) && amount > 0){
            TransferHelper.safeTransferETH(receiver,amount);
        }     
        TransferHelper.safeTransferETH(feeTo, fee);
        TransferHelper.safeTransferETH(option.creator, toCreator);
        ISynchron(synchron).updateWithProperty(optionId, abi.encode(option));
        emit Purchase(msg.sender, optionId, msg.value, block.timestamp);
    }

    function cancelOption(uint256 optionId) external override{
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        uint256[] memory offerIds = ISynchron(synchron).getOptionCorrespondingBid(optionId);
        require(IGlibrary(glibrary).getCancelStatus(optionInfo, msg.sender, offerIds) == true,"Trading:Order cancellation failed");
        StandardOption memory option = IGlibrary(glibrary).analyseOption(optionInfo);
        ISynchron(synchron).safeTransfer(option.token, option.creator, option.tokenId, option.amount);
        option.state = State.cancelled;
        ISynchron(synchron).updateWithProperty(optionId, abi.encode(option));
        emit Cancel(option.tradingType, msg.sender, optionId, block.timestamp);
    }

    function bidding(uint256 optionId,uint256 price) external override{
        require(getBiddingStatus(optionId, msg.sender, price) == true,"Trading:Failed to participate in bidding");
        StandardOffer memory offer = StandardOffer(msg.sender,price,PriceState.effective);
        uint256 offerId = ISynchron(synchron).addBidding(optionId, abi.encode(offer), msg.sender);
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        StandardOption memory option = IGlibrary(glibrary).analyseOption(optionInfo);
        if(option.expect > 0 && price >= option.amount.mul(option.expect)){
            (address receiver,uint256 amount) = IERC2981(option.token).royaltyInfo(option.tokenId, price);
            uint256 fee = price.mul(auctionFee).div(1000);
            uint256 toCreator = price.sub(amount).sub(fee);
            ISynchron(synchron).safeTranferWeth(weth, msg.sender, option.creator, feeTo, receiver, amount, fee, toCreator, amount);
            ISynchron(synchron).safeTransfer(option.token, msg.sender, option.tokenId, option.amount);
            option.state = State.saled;
            ISynchron(synchron).updateWithProperty(optionId, abi.encode(option));
            emit Delivery(msg.sender, msg.sender, optionId, offerId, price, block.timestamp);
        }
        if(option.expiration > block.timestamp){
            if(option.expiration.sub(block.timestamp) < 600 && option.state == State.solding){
                option.expiration = option.expiration.add(600);
                ISynchron(synchron).updateWithProperty(optionId, abi.encode(option));
            } 
        }
        emit Bidding(msg.sender, optionId, offerId, price, block.timestamp);
    }

    function cancelBidding(uint256 optionId,uint256 offerId) external override{
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        bytes memory offerInfo = ISynchron(synchron).offerInfo(offerId);
        require(optionId == ISynchron(synchron).bidCorrespondingOption(offerId),"Trading:The information provided when canceling bidding is wrong");
        //IGlibrary(glibrary).getCancelBiddingStatus(optionInfo, offerInfo, customer);
        require(IGlibrary(glibrary).getCancelBiddingStatus(optionInfo, offerInfo, msg.sender) == true,"Trading:Failed to cancel bidding");
        StandardOffer memory offer = IGlibrary(glibrary).analyseOffer(offerInfo);
        offer.state = PriceState.invalid;
        ISynchron(synchron).cancelBiding(offerId, abi.encode(offer));
        emit CancelBidding(msg.sender, optionId, offerId, block.timestamp);
    }

    function getDeliverableOffer(uint256 optionId) public override view returns(uint256 offerId){
        uint256[] memory offerIds = ISynchron(synchron).getOptionCorrespondingBid(optionId);
        for(uint i=0; i<offerIds.length; i++){
            if(offerIds[i] > 0){
                bytes memory offerInfo = ISynchron(synchron).offerInfo(offerIds[i]);
                StandardOffer memory offer = IGlibrary(glibrary).analyseOffer(offerInfo);
                if(IERC20(weth).balanceOf(offer.bidder) >= offer.price){
                    offerId = offerIds[i];
                }
            }
        }
    }

    function delivery(uint256 optionId) external override{
        bytes memory optionInfo = ISynchron(synchron).optionInfo(optionId);
        require(getDeliverableOffer(optionId) > 0,"Trading:There is no auction available for delivery");
        require(IGlibrary(glibrary).getDeliveryStatus(optionInfo, msg.sender) == true,"Trading:Delivery operation failed");
        uint256 offerId = getDeliverableOffer(optionId);
        StandardOption memory option = IGlibrary(glibrary).analyseOption(optionInfo);
        bytes memory offerInfo = ISynchron(synchron).offerInfo(offerId);
        StandardOffer memory offer = IGlibrary(glibrary).analyseOffer(offerInfo);
        ISynchron(synchron).safeTransfer(option.token, offer.bidder, option.tokenId, option.amount);
        (address receiver,uint256 amount) = IERC2981(option.token).royaltyInfo(option.tokenId, offer.price);
        uint256 fee = offer.price.mul(auctionFee).div(100);
        uint256 toCreator = offer.price.sub(amount).sub(fee);
        ISynchron(synchron).safeTranferWeth(weth, offer.bidder, option.creator, feeTo, receiver, amount, fee, toCreator, amount);
        //ISynchron(synchron).safeTranferWeth(weth, offer.bidder, option.creator, offer.price);
        option.state = State.saled;
        ISynchron(synchron).updateWithProperty(optionId, abi.encode(option));
        emit Delivery(msg.sender, offer.bidder, optionId, offerId, offer.price, block.timestamp);
    }
    

}

//token721:

//synchron:0x181EcBF053d2643Fbb03fae22E7bb1EBa4425014

//glibrary:0xf4a1c00c07A553506C3BB0C21780e4F8c029047c

//trading:0x22D53bE5fE2D40b800bAcE8AE694D11278Bcf3B7