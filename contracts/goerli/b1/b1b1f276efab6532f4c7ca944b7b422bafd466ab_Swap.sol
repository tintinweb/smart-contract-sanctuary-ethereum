/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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


// File contracts/Swap.sol

// License-Identifier: MIT
pragma solidity ^0.8.9;

// Contract to trade pandas trustlessly
// For now it will be one contract per NFT collection



contract Swap is Ownable {
    using Counters for Counters.Counter;
    // User should be able to request a trade
    // User should be able to accept or reject a trade
    // User should be able to cancel a trade (also revoke token approval)
    // User should be able to see their list of open trades that they have offered
    // User should be able to see their list of trade requests that they have received
    // Trades should have an expiry date
    // In the future, NFT Contract owner should be able to set a royalty fee for trades of their collection
    // If there is a fee added, the trade sender is probably the one that should have to pay, the receiver pays a higher gas fee because they initiate the transfers.
        // Could have the sender send a small amount of ETH to the contract when sending trades to offset the receiver paying a high fee.
        // What happens in the case where the trade offer is rejected? Does the sender get his funds back?

    struct Trade {
        address sender;
        address receiver;
        uint256 senderTokenId;
        uint256 receiverTokenId;
        bool isTradeOpen;
    }

    address nftContractAddress;
    mapping(uint256 => Trade) trades;
    Counters.Counter private tradeId;

    event TradeCreated(uint256 tradeId, address sender, address receiver, uint256 senderId, uint256 receiverId);
    event TradeUpdated(uint256 tradeId, string);


    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
    }

    

    // I don't think we need to store extra mappings for users -> open/received trade requests
    // I think we should be able to query for trades on the NFTs that the user owns
    // For now, we will just make users input the senderNftId, receiverNftId, and sender/receiver to send/accept trades

    function makeTradeRequest(address _receiver, uint256 _senderTokenId, uint256 _receiverTokenId) public {
        require(IERC721(nftContractAddress).ownerOf(_senderTokenId) == msg.sender, "Sender must own offered NFT");
        require(IERC721(nftContractAddress).ownerOf(_receiverTokenId) == _receiver, "Receiver must own requested NFT");
        require(IERC721(nftContractAddress).getApproved(_senderTokenId) == address(this), "Sender must approve this contract");

        trades[tradeId.current()] = Trade({
            sender: msg.sender,
            receiver: _receiver,
            senderTokenId: _senderTokenId,
            receiverTokenId: _receiverTokenId,
            isTradeOpen: true
        });

        //emit TradeUpdated(tradeId.current(), "pending"); // TODO: Update tests
        emit TradeCreated(tradeId.current(), msg.sender, _receiver, _senderTokenId, _receiverTokenId);
        tradeId.increment();
    }

    function acceptTradeRequest(uint256 _tradeId) public {
        Trade memory trade = trades[_tradeId];
        require(trade.isTradeOpen == true, "Trade is not open");
        require(trade.receiver == msg.sender, "Only trade receiver can accept trade");
        require(IERC721(nftContractAddress).ownerOf(trade.senderTokenId) == trade.sender, "Sender must own offered NFT"); // Redundant
        require(IERC721(nftContractAddress).ownerOf(trade.receiverTokenId) == msg.sender, "Receiver must own requested NFT"); // Redundant
        require(IERC721(nftContractAddress).getApproved(trade.senderTokenId) == address(this), "Sender must approve this contract"); // Redundant
        require(IERC721(nftContractAddress).getApproved(trade.receiverTokenId) == address(this), "Receiver must approve this contract"); // Redundant
        IERC721(nftContractAddress).safeTransferFrom(trade.sender, trade.receiver, trade.senderTokenId);
        IERC721(nftContractAddress).safeTransferFrom(trade.receiver, trade.sender, trade.receiverTokenId);
        
        trades[_tradeId].isTradeOpen = false;
        emit TradeUpdated(_tradeId, "accepted");
    }

    function rejectTradeRequest(uint256 _tradeId) public {
        Trade memory trade = trades[_tradeId];
        require(trade.isTradeOpen == true, "Trade is not open");
        require(trade.receiver == msg.sender, "Only trade receiver can reject trade");

        trades[_tradeId].isTradeOpen = false;
        emit TradeUpdated(_tradeId, "rejected");
    }

    function cancelTradeRequest(uint256 _tradeId) public {
        Trade memory trade = trades[_tradeId];
        require(trade.isTradeOpen == true, "Trade is not open");
        require(trade.sender == msg.sender, "Only trade requester can cancel trade");

        trades[_tradeId].isTradeOpen = false;
        emit TradeUpdated(_tradeId, "canceled");
    }

    function queryTradeRequest(uint256 _tradeId) public view returns (address, address, uint256, uint256, bool) {
        require(_tradeId <= tradeId.current(), "Querying a trade that doesn't exist");
        Trade memory trade = trades[_tradeId];
        return (trade.sender, trade.receiver, trade.senderTokenId, trade.receiverTokenId, trade.isTradeOpen);
    }
}