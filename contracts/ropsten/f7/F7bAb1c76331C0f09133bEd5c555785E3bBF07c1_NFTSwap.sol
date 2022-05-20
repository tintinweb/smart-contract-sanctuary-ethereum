// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./NFTSwapAbstract.sol";

contract NFTSwap is Ownable, Pausable, ERC721Holder, ERC1155Holder {

    using Counters for Counters.Counter;

    enum SwapStatus  {Open, Completed, Canceled, Expired}
    enum DAppType {Undefined, ERC721, ERC1155, ERC20, NetworkValue}

    struct SwapItem {
        address dApp;
        DAppType dAppType;
        uint256[] tokenIds;
        uint256[] tokenAmounts;
        bytes data;
    }

    struct SwapOrder {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 expiration;
        uint256 fee;
        uint256 feePaid;
        address addressOne;
        address addressTwo;
        SwapStatus status;
        SwapItem[] addressOneItems;
        SwapItem[] addressTwoItems;
    }

    mapping(uint256 => SwapOrder)swapOrders;
    mapping(address => uint256[])swapAddresses;

    uint256 private _fee;
    Counters.Counter private _orderId;
    uint256 private _swapBalance;

    //Event
    event SwapOrderEvent(uint256 orderId, SwapStatus status);

    receive() external payable {}

    //Interface received
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC1155).interfaceId;
    }

    //Create swap order
    function creatSwapOrder(address addressTwo, SwapItem[] memory swapOneItems, SwapItem[] memory swapTwoItems, uint256 expirationSec) public payable whenNotPaused returns (uint256){
        require(swapOneItems.length > 0, "AIe0");
        require(swapTwoItems.length > 0, "BIe0");
        require(msg.sender != addressTwo, "OeT");

        _orderId.increment();

        swapOrders[_orderId.current()].id = _orderId.current();
        swapOrders[_orderId.current()].start = block.timestamp;
        swapOrders[_orderId.current()].end = 0;
        if (expirationSec > 0) {
            swapOrders[_orderId.current()].expiration = block.timestamp + expirationSec;
        } else {
            swapOrders[_orderId.current()].expiration = 0;
        }

        uint256 swapNetworkValue = msg.value;
        swapOrders[_orderId.current()].fee = getFee();
        swapOrders[_orderId.current()].addressOne = msg.sender;
        swapOrders[_orderId.current()].addressTwo = addressTwo;
        swapOrders[_orderId.current()].status = SwapStatus.Open;

        uint256 i = 0;

        for (i = 0; i < swapOneItems.length; i++) {
            require(swapOneItems[i].dAppType != DAppType.Undefined, "DU");
            swapOrders[_orderId.current()].addressOneItems.push(swapOneItems[i]);
            if (swapOneItems[i].dAppType == DAppType.ERC721) {
                ERC721Interface(swapOneItems[i].dApp).safeTransferFrom(msg.sender, address(this), swapOneItems[i].tokenIds[0], swapOneItems[i].data);
            } else if (swapOneItems[i].dAppType == DAppType.ERC1155) {
                ERC1155Interface(swapOneItems[i].dApp).safeBatchTransferFrom(msg.sender, address(this), swapOneItems[i].tokenIds, swapOneItems[i].tokenAmounts, swapOneItems[i].data);
            } else if (swapOneItems[i].dAppType == DAppType.ERC20) {
                ERC20Interface(swapOneItems[i].dApp).transferFrom(msg.sender, address(this), swapOneItems[i].tokenAmounts[0]);
            } else if (swapOneItems[i].dAppType == DAppType.NetworkValue) {
                require(swapNetworkValue >= swapOneItems[i].tokenAmounts[0], "VltS");
                swapNetworkValue -= swapOneItems[i].tokenAmounts[0];
                _swapBalance += swapOneItems[i].tokenAmounts[0];
            }
        }

        if (swapOrders[_orderId.current()].fee > 0) {
            if (swapNetworkValue > 0) {
                if (swapOrders[_orderId.current()].fee > swapNetworkValue) {
                    swapOrders[_orderId.current()].feePaid = swapNetworkValue;
                    swapNetworkValue -= swapOrders[_orderId.current()].feePaid;
                } else {
                    swapOrders[_orderId.current()].feePaid = swapOrders[_orderId.current()].fee;
                    swapNetworkValue -= swapOrders[_orderId.current()].fee;
                }
            } else {
                swapOrders[_orderId.current()].feePaid = 0;
            }
        }

        require(swapNetworkValue == 0, "VN0");

        for (i = 0; i < swapTwoItems.length; i++) {
            require(swapTwoItems[i].dAppType != DAppType.Undefined, "DU");
            swapOrders[_orderId.current()].addressTwoItems.push(swapTwoItems[i]);
        }

        swapAddresses[msg.sender].push(_orderId.current());
        if (addressTwo != address(0)) {
            swapAddresses[addressTwo].push(_orderId.current());
        }

        emit SwapOrderEvent(_orderId.current(), SwapStatus.Open);

        return _orderId.current();
    }

    //Complete
    function completeSwapOrder(uint256 orderId) public payable returns (bool){
        require(swapOrders[orderId].status == SwapStatus.Open, "NO");
        require(swapOrders[orderId].addressTwo == msg.sender || swapOrders[orderId].addressTwo == address(0), "NA");

        if (swapOrders[orderId].expiration >= block.timestamp || swapOrders[orderId].expiration == 0) {

            swapOrders[orderId].end = block.timestamp;

            uint256 swapNetworkValue = msg.value;
            if (swapOrders[orderId].fee > 0 && swapOrders[orderId].fee > swapOrders[orderId].feePaid) {
                uint256 fpv = (swapOrders[orderId].fee - swapOrders[orderId].feePaid);
                require(swapNetworkValue >= fpv, "VFltS");
                swapOrders[orderId].feePaid += fpv;
                swapNetworkValue -= fpv;
            }

            if (swapOrders[orderId].addressTwo == address(0)) {
                swapAddresses[msg.sender].push(swapOrders[orderId].id);
            }

            swapOrders[orderId].addressTwo = msg.sender;
            swapOrders[orderId].status = SwapStatus.Completed;

            uint256 i;

            for (i = 0; i < swapOrders[orderId].addressTwoItems.length; i++) {
                if (swapOrders[orderId].addressTwoItems[i].dAppType == DAppType.ERC721) {
                    ERC721Interface(swapOrders[orderId].addressTwoItems[i].dApp).safeTransferFrom(msg.sender, swapOrders[orderId].addressOne, swapOrders[orderId].addressTwoItems[i].tokenIds[0], swapOrders[orderId].addressTwoItems[i].data);
                } else if (swapOrders[orderId].addressTwoItems[i].dAppType == DAppType.ERC1155) {
                    ERC1155Interface(swapOrders[orderId].addressTwoItems[i].dApp).safeBatchTransferFrom(msg.sender, swapOrders[orderId].addressOne, swapOrders[orderId].addressTwoItems[i].tokenIds, swapOrders[orderId].addressTwoItems[i].tokenAmounts, swapOrders[orderId].addressTwoItems[i].data);
                } else if (swapOrders[orderId].addressTwoItems[i].dAppType == DAppType.ERC20) {
                    ERC20Interface(swapOrders[orderId].addressTwoItems[i].dApp).transferFrom(msg.sender, swapOrders[orderId].addressOne, swapOrders[orderId].addressTwoItems[i].tokenAmounts[0]);
                } else if (swapOrders[orderId].addressTwoItems[i].dAppType == DAppType.NetworkValue) {
                    require(swapNetworkValue >= swapOrders[orderId].addressTwoItems[i].tokenAmounts[0], "VltS");
                    payable(swapOrders[orderId].addressOne).transfer(swapOrders[orderId].addressTwoItems[i].tokenAmounts[0]);
                    swapNetworkValue -= swapOrders[orderId].addressTwoItems[i].tokenAmounts[0];
                }
            }

            require(swapNetworkValue == 0, "VN0");

            for (i = 0; i < swapOrders[orderId].addressOneItems.length; i++) {
                if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC721) {
                    ERC721Interface(swapOrders[orderId].addressOneItems[i].dApp).safeTransferFrom(address(this), swapOrders[orderId].addressTwo, swapOrders[orderId].addressOneItems[i].tokenIds[0], swapOrders[orderId].addressOneItems[i].data);
                } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC1155) {
                    ERC1155Interface(swapOrders[orderId].addressOneItems[i].dApp).safeBatchTransferFrom(address(this), swapOrders[orderId].addressTwo, swapOrders[orderId].addressOneItems[i].tokenIds, swapOrders[orderId].addressOneItems[i].tokenAmounts, swapOrders[orderId].addressOneItems[i].data);
                } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC20) {
                    ERC20Interface(swapOrders[orderId].addressOneItems[i].dApp).transfer(swapOrders[orderId].addressTwo, swapOrders[orderId].addressOneItems[i].tokenAmounts[0]);
                } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.NetworkValue) {
                    payable(swapOrders[orderId].addressTwo).transfer(swapOrders[orderId].addressOneItems[i].tokenAmounts[0]);
                    _swapBalance -= swapOrders[orderId].addressOneItems[i].tokenAmounts[0];
                }
            }

            emit SwapOrderEvent(orderId, SwapStatus.Completed);

            return true;
        } else {
            swapOrders[orderId].status = SwapStatus.Expired;

            emit SwapOrderEvent(orderId, SwapStatus.Expired);

            return false;
        }
    }

    //Cancel
    function cancelSwapOrder(uint256 orderId) public payable returns (bool){
        require(swapOrders[orderId].status == SwapStatus.Open || swapOrders[orderId].status == SwapStatus.Expired, "C");
        require(swapOrders[orderId].addressOne == msg.sender, "NC");

        swapOrders[orderId].status = SwapStatus.Canceled;
        swapOrders[orderId].end = block.timestamp;

        uint256 swapNetworkValue = msg.value;
        if (swapOrders[orderId].fee > 0 && swapOrders[orderId].fee > swapOrders[orderId].feePaid) {
            uint256 fpv = (swapOrders[orderId].fee - swapOrders[orderId].feePaid);
            require(swapNetworkValue >= fpv, "VFltS");
            swapOrders[orderId].feePaid += fpv;
            swapNetworkValue -= fpv;
        }
        require(swapNetworkValue == 0, "VN0");

        uint256 i;

        for (i = 0; i < swapOrders[orderId].addressOneItems.length; i++) {
            if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC721) {
                ERC721Interface(swapOrders[orderId].addressOneItems[i].dApp).safeTransferFrom(address(this), swapOrders[orderId].addressOne, swapOrders[orderId].addressOneItems[i].tokenIds[0], swapOrders[orderId].addressOneItems[i].data);
            } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC1155) {
                ERC1155Interface(swapOrders[orderId].addressOneItems[i].dApp).safeBatchTransferFrom(address(this), swapOrders[orderId].addressOne, swapOrders[orderId].addressOneItems[i].tokenIds, swapOrders[orderId].addressOneItems[i].tokenAmounts, swapOrders[orderId].addressOneItems[i].data);
            } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.ERC20) {
                ERC20Interface(swapOrders[orderId].addressOneItems[i].dApp).transfer(swapOrders[orderId].addressOne, swapOrders[orderId].addressOneItems[i].tokenAmounts[0]);
            } else if (swapOrders[orderId].addressOneItems[i].dAppType == DAppType.NetworkValue) {
                payable(swapOrders[orderId].addressOne).transfer(swapOrders[orderId].addressOneItems[i].tokenAmounts[0]);
                _swapBalance -= swapOrders[orderId].addressOneItems[i].tokenAmounts[0];
            }
        }

        emit SwapOrderEvent(orderId, SwapStatus.Canceled);

        return true;
    }

    //Order info
    function getOrderById(uint256 orderId) public view returns (SwapOrder memory){
        return swapOrders[orderId];
    }

    function getOrderIdsByAddress(address addressIndex) public view returns (uint256[] memory){
        return swapAddresses[addressIndex];
    }

    function getOrderCount() public view returns (uint256){
        return _orderId.current();
    }

    //Fee
    function getFee() public view returns (uint256){
        return _fee;
    }

    function setFee(uint256 newFee) public onlyOwner {
        _fee = newFee;
    }

    //System
    function switchPause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _getFeeBalance() internal view returns (uint256) {
        return address(this).balance > _swapBalance ? address(this).balance - _swapBalance : 0;
    }

    function getWithdrawBalance(address payable recipient, uint256 amounts) public onlyOwner {
        require(recipient != address(0), "WB0");
        uint256 maxAmount = _getFeeBalance();
        if (amounts == 0 || maxAmount < amounts) {
            recipient.transfer(maxAmount);
        } else {
            recipient.transfer(amounts);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
pragma abicoder v2;

abstract contract ERC721Interface {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external virtual;
}

abstract contract ERC1155Interface {
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external virtual;
}

abstract contract ERC20Interface {
    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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