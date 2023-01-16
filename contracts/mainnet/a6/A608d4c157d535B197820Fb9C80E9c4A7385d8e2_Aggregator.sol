// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./bases/TokenHolder.sol";
import "./bases/Constants.sol";
import "./bases/TransferHelper.sol";
import "./markets/MarketRegistry.sol";
import "./interfaces/IWETH.sol";

contract Aggregator is Ownable, Pausable, TokenHolder, TransferHelper {
    IWETH public immutable WETH; //immutable不占用slot
    MarketRegistry public marketRegistry;
    address public protocolFeeRecipient;
    uint256 private reentrancyStatus = 1;

    // Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
    modifier nonReentrant() {
        require(reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        reentrancyStatus = 2;
        _;
        reentrancyStatus = 1;
    }

    event TradeResult(uint256 index, bool status);
    event RewardsClaimed(address token, uint256 amount);

    constructor(
        address _marketRegistry,
        address _weth,
        address _protocolFeeRecipient
    ) {
        marketRegistry = MarketRegistry(_marketRegistry);
        WETH = IWETH(_weth);
        protocolFeeRecipient = _protocolFeeRecipient;
        // TODO : 授权opensea\looksrare\x2y2 可以扣除本合约中的weth。其余token的授权可以调用下方的 setOneTimeApproval()
        WETH.approve(SEAPORT, 2**256 - 1); // "type(uint256).max" or  "2**256 - 1"
        WETH.approve(LOOKSRARE, 2**256 - 1);
        WETH.approve(X2Y2, 2**256 - 1);
    }

    // receive ETH
    receive() external payable {}

    // 用 主网币+erc20 去代购NFT。首先需要将用户的erc20 转到本合约中（因为用户只对本合约进行过授权）
    /// @notice Execute purchase with the given token and inputs
    /// @param erc20Details payment token
    /// @param tradeDetails the inputs to call
    /// @param amountToWETH eth -> weth amount
    /// @param amountToETH  weth -> eth amount(weth should be contained in the "erc20Details")
    /// @param protocolFeeAmount protocol fee amount
    function batchBuy(
        ERC20Detail[] calldata erc20Details,
        TradeDetail[] calldata tradeDetails,
        uint256 amountToWETH,
        uint256 amountToETH, //两者只有一个大于0
        uint256 protocolFeeAmount
    ) external payable nonReentrant whenNotPaused {
        // 1.transfer ERC20 tokens from the sender to this contract
        if (erc20Details.length > 0) {
            _transferERC20s(erc20Details, msg.sender, address(this));
        }
        // 2.Convert eth and weth if needed
        if (amountToWETH > 0 && amountToETH > 0) {
            revert("batchBuy: invalid amountToWETH or amountToETH");
        }
        if (amountToWETH > 0) {
            WETH.deposit{value: amountToWETH}();
        } else if (amountToETH > 0) {
            // in _transferERC20s(), sender has deposited in weth
            WETH.withdraw(amountToETH);
        }

        // 3.  charge protocolFee
        if (protocolFeeAmount > 0) {
            _transferETH(protocolFeeRecipient, protocolFeeAmount);
        }

        //4.execute trades
        _trade(tradeDetails);

        // 5. return dust tokens (if any)
        _returnDust(erc20Details);
    }

    // market Proxy-> xxxMarket contract
    function _trade(
        TradeDetail[] calldata _tradeDetails //marketId- value- tradeData
    ) internal {
        TradeDetail calldata detail;
        bool status;
        // bytes memory result;
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            detail = _tradeDetails[i];
            // get market details
            (address _proxy, bool _isLib, bool _isActive) = marketRegistry
                .markets(detail.marketId);
            // market should be active
            require(_isActive, "_trade: InActive Market");

            (status, ) = _isLib
                ? _proxy.delegatecall(detail.tradeData) //注：_proxy合约中不能定义变量，否则delegatecall的时候读取slot时会出错！！
                : _proxy.call{value: detail.value}(detail.tradeData); // 以seaport为例、call的返回值可能非常长，因此此处不再取返回值
            //call调用时，这里的proxy不要设置成ERC20、ERC721等“本合约会被授权的合约”，例如proxy是USDC合约，而很多用户又将USDC授权给本合约，那么黑客就可以构造“detail数据=transfer普通用户的USDC”，盗取那些用户授权给本合约的USDC。

            emit TradeResult(i, status); //不同的_proxy情况下，result的数据格式是不确定的，因此无法进行decode
        }
    }

    // function bytesToUint(bytes memory b) public pure returns (uint256) {
    //     //该方法中的参数b可以是任意长度。相比之下， abi.decode(result, (uint256)) 中result必须是标准的32字节才能解码出结果
    //     uint256 number;
    //     for (uint256 i = 0; i < b.length; i++) {
    //         number = number + uint8(b[i]) * (2**(8 * (b.length - (i + 1))));
    //     }
    //     return number;
    // }

    // Return the remaining tokens(eth、erc20s、weth) to the user
    function _returnDust(ERC20Detail[] calldata _tokens) internal {
        // 1.return remaining ETH (if any)
        uint256 selfBalance = address(this).balance;
        if (selfBalance > 0) {
            _transferETH(msg.sender, selfBalance);
        }
        // 2.return remaining erc20 tokens (if any)
        address tokenAddr;
        uint256 tokenBalance;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenAddr = _tokens[i].tokenAddr;
            tokenBalance = IERC20(tokenAddr).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokenAddr).transfer(msg.sender, tokenBalance);
            }
        }
        // 3.spectial treatement:weth
        if (WETH.balanceOf(address(this)) > 0) {
            WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
        }
    }

    //////////////// 参数设置等管理员权限的方法   //////////
    // 将本合约拥有的token授权给各个market，用于支付代购费用
    function setOneTimeApproval(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    //本合约负责帮用户代购，因此可能会有代币奖励
    /// @notice Performs a call to claim token rewards and transfer to owner. e.g. LOOKS、X2Y2
    /// @param rewardsDistributor The address of rewards distributor
    /// @param claimData The inputs to call rewardsDistributor
    /// @param rewardsToken The address of reward token
    /// @dev In looksrare,earn crypto just by staking, trading and listing. For looksrare, the parameters: (LOOKSRARE_REWARDS_DISTRIBUTOR,0x...,LOOKSRARE_TOKEN)
    /// @dev X2Y2 shares 100% of its profit to X2Y2 token holders. For X2Y2, the parameters: (X2Y2_REWARDS_DISTRIBUTOR,对应入参...,X2Y2_TOKEN)
    function collectMarketRewards(
        address rewardsDistributor,
        bytes calldata claimData,
        address rewardsToken
    ) external onlyOwner {
        (bool success, ) = rewardsDistributor.call(claimData);
        require(success, "collectLooksRareRewards: Claim Failed");

        uint256 tokenBalance = IERC20(rewardsToken).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(rewardsToken).transfer(msg.sender, tokenBalance);
            emit RewardsClaimed(rewardsToken, tokenBalance);
        }
    }

    function setMarketRegistry(MarketRegistry _marketRegistry)
        external
        onlyOwner
    {
        marketRegistry = _marketRegistry;
    }

    function setProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    /////////////////////////////////////
    ////////////////////////////////////////

    // withdraw tokens
    function rescueETH(address recipient) external onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function rescueERC20(address token, address recipient) external onlyOwner {
        IERC20(token).transfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    function rescueERC721(
        address collection,
        uint256 tokenId,
        address recipient
    ) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
    }

    function rescueERC1155(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        IERC1155(collection).safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//// Do not define "state variables" in this contract！
contract Constants {
    //`constant`和`immutable`变量不占用存储槽，因此不会影响delegatecall时slot的读取
    // market id
    uint256 public constant SEAPORT_MARKET_ID = 0;
    uint256 public constant DEFAULT_MARKET_ID = 1;

    //market address(seaport looksrare x2y2 cryptopunk mooncat)
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;

    address public constant LOOKSRARE =
        0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address public constant LOOKSRARE_REWARDS_DISTRIBUTOR =
        0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72; // 领取LOOKS代币奖励
    address public constant LOOKSRARE_TOKEN =
        0xf4d2888d29D722226FafA5d9B24F9164c092421E; //LOOKS代币地址

    address public constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3; //单个购买时的market合约
    address public constant X2Y2_REWARDS_DISTRIBUTOR =
        0x897249FEf87Fa6D1E7FeDCB960c2A01Ec99ecC6C; // 领取X2Y2代币奖励
    address public constant X2Y2_TOKEN =
        0x1E4EDE388cbc9F4b5c79681B7f94d36a11ABEBC9; //X2Y2代币地址
    // address public constant X2Y2_BATCH =
    //     0x56Dd5bbEDE9BFDB10a2845c4D70d4a2950163044; // 批量购买时的market合约--参考用

    address public constant CRYPTOPUNK =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    address public constant MOONCAT =
        0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;

    address public constant NFTX = 0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d;

    address public constant FOUNDATION =
        0xcDA72070E455bb31C7690a170224Ce43623d0B6f;

    address public constant SUDOSWAP =
        0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address public constant NFT20 = 0xA42f6cADa809Bcf417DeefbdD69C5C5A909249C0;

    address public constant BLUR = 0x000000000000Ad05Ccc4F10045630fb830B95127;

    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256 id;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }

    enum ItemType {
        INVALID,
        NATIVE,
        ERC20,
        ERC721,
        ERC1155
    }
    struct OrderItem {
        ItemType itemType;
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }

    struct TradeInput {
        //单次调用某一market
        uint256 value; // 此次调用x2y2\looksrare\..需传递的主网币数量
        bytes inputData; //此次调用的input data
        OrderItem[] tokens; // 本次调用要购买的NFT信息,可能会有多个（例如捆绑销售时）
    }
    struct TradeDetail {
        //批量调用同一个market
        uint256 marketId;
        uint256 value;
        bytes tradeData; //包含多个TradeInput信息
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract TokenHolder is IERC721Receiver, IERC1155Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/ICryptoPunks.sol";
import "../interfaces/IMoonCatsRescue.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Constants.sol";

// Do not define "state variables" in this contract ( which will affect the delegatecall to DefaultMarketProxy.batchBuyFromMarket())!!!!
contract TransferHelper is Constants {
    function _uintToBytes5(uint256 id)
        internal
        pure
        returns (bytes5 slicedDataBytes5)
    {
        bytes memory _bytes = new bytes(32);
        assembly {
            mstore(add(_bytes, 32), id)
        }

        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
            let lengthmod := and(5, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
            let mc := add(
                add(tempBytes, lengthmod),
                mul(0x20, iszero(lengthmod))
            )
            let end := add(mc, 5)

            for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                let cc := add(
                    add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
                    27
                )
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, 5)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        assembly {
            slicedDataBytes5 := mload(add(tempBytes, 32))
        }
    }

    // 从msg.sender那买入MoonCat（需要卖方提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptMoonCat(uint256 moonCatId) internal {
        // xxxx -> address(this)
        IMoonCatsRescue moonCat = IMoonCatsRescue(MOONCAT);
        bytes5 catId = _uintToBytes5(moonCatId);
        // address owner = moonCat.catOwners(catId);
        // require(owner == msg.sender, "_acceptMoonCat: invalid mooncat owner");
        moonCat.acceptAdoptionOffer(catId);
    }

    // 将本合约中的MoonCat转出给用户to
    function _transferMoonCat(uint256 moonCatId, address to) internal {
        // address(this) -> msg.sender
        IMoonCatsRescue(MOONCAT).giveCat(_uintToBytes5(moonCatId), to);
    }

    // 从msg.sender那买入CryptoPunk（需要卖方提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptCryptoPunk(uint256 cryptoPunkId) internal {
        // xxxx -> address(this)
        ICryptoPunks cryptoPunk = ICryptoPunks(CRYPTOPUNK);
        // address owner = cryptoPunk.punkIndexToAddress(cryptoPunkId);
        // require(owner == msg.sender, "_acceptCryptoPunk: invalid punk owner");
        cryptoPunk.buyPunk(cryptoPunkId); //msg.value为0
    }

    // 将本合约中的CryptoPunk转出给用户to
    function _transferCryptoPunk(uint256 cryptoPunkId, address to) internal {
        // address(this) -> msg.sender
        ICryptoPunks(CRYPTOPUNK).transferPunk(to, cryptoPunkId);
    }

    // 从本合约中转出主网币 address(this) -> msg.sender
    function _transferETH(address to, uint256 amount) internal {
        payable(to).transfer(amount); //失败则revert
    }

    function _transferERC20s(
        ERC20Detail[] calldata erc20Details, //tokenAddr-amount
        address from,
        address to
    ) internal {
        // from -> to
        for (uint256 i = 0; i < erc20Details.length; i++) {
            // Transfer ERC20
            IERC20(erc20Details[i].tokenAddr).transferFrom(
                from,
                to,
                erc20Details[i].amount
            );
        }
    }

    function _transferERC721s(
        ERC721Detail[] calldata erc721Details, // tokenAddr-id
        address from,
        address to
    ) internal {
        // from -> to
        for (uint256 i = 0; i < erc721Details.length; i++) {
            IERC721(erc721Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc721Details[i].id
            );
        }
    }

    function _transferERC1155s(
        ERC1155Detail[] calldata erc1155Details, //tokenAddr-id- amount
        address from,
        address to
    ) internal {
        // transfer ERC1155 tokens: from -> to
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc1155Details[i].id,
                erc1155Details[i].amount,
                ""
            );
        }
    }

    function _transferItemsFromThis(OrderItem[] calldata items, address to)
        internal
    {
        //transfer CRYPTOPUNK or MOONCAT or ERC20 or ERC721 or ERC1155: address(this) -> to
        OrderItem calldata item;
        uint256 itemNums = items.length;
        uint256 tokenBalance = 0;
        // for-each
        for (uint256 i = 0; i < itemNums; i++) {
            item = items[i];
            if (item.amount == 0) {
                return;
            }

            if (item.tokenAddr == CRYPTOPUNK) {
                if (
                    ICryptoPunks(CRYPTOPUNK).punkIndexToAddress(item.id) ==
                    address(this)
                ) {
                    _transferCryptoPunk(item.id, to);
                }
            } else if (item.tokenAddr == MOONCAT) {
                if (
                    IMoonCatsRescue(MOONCAT).catOwners(
                        _uintToBytes5(item.id)
                    ) == address(this)
                ) {
                    _transferMoonCat(item.id, to);
                }
            } else if (item.itemType == ItemType.ERC20) {
                tokenBalance = IERC20(item.tokenAddr).balanceOf(address(this));
                if (tokenBalance >= item.amount) {
                    IERC20(item.tokenAddr).transfer(to, item.amount);
                }
            } else if (item.itemType == ItemType.ERC721) {
                if (IERC721(item.tokenAddr).ownerOf(item.id) == address(this)) {
                    // Transfer ERC721
                    IERC721(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id
                    );
                }
            } else if (item.itemType == ItemType.ERC1155) {
                if (
                    IERC1155(item.tokenAddr).balanceOf(
                        address(this),
                        item.id
                    ) >= item.amount
                ) {
                    // Transfer ERC1155
                    IERC1155(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id,
                        item.amount,
                        ""
                    );
                }
            } else {
                revert("_transferOrderItem: InvalidItemType");
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index)
        external
        view
        returns (address owner);

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) external payable;

    function makeAdoptionOfferToAddress(
        bytes5 catId,
        uint256 price,
        address to
    ) external;

    function giveCat(bytes5 catId, address to) external;

    function catOwners(bytes5 catId) external view returns (address);

    function rescueOrder(uint256 rescueIndex)
        external
        view
        returns (bytes5 catId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../bases/Constants.sol";

contract MarketRegistry is Ownable, Constants {
    struct Market {
        address proxy; //custom market proxy
        bool isLib; //是否通过委托调用的方式，调用Market市场合约。大多数情况是true，因为Market合约中会校验msg。sender是否为接单者
        bool isActive;
    }

    Market[] public markets;

    constructor(address defaultMarektProxy) {
        markets.push(Market(SEAPORT, false, true)); //market_id=0,call
        markets.push(Market(defaultMarektProxy, true, true)); //market_id=1,delegatecall
    }

    /// @param proxy  必须是交易市场的Market合约，不能是token合约！
    /// @param isLib true表示delegatecall的方式调用proxy；false表示call的方式调用proxy
    function addMarket(address proxy, bool isLib) external onlyOwner {
        markets.push(Market(proxy, isLib, true));
    }

    function addMarkets(address[] memory proxies, bool[] memory isLibs)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < proxies.length; i++) {
            markets.push(Market(proxies[i], isLibs[i], true));
        }
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(
        uint256 marketId,
        address newProxy,
        bool isLib
    ) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
    }
}