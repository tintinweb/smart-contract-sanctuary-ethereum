// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./interfaces/INFTSwap.sol";

error NFTSwap__ZeroAddress();

error NFTSwap__ExchangeExists();

error NFTSwap__NonexistentExchange();

error NFTSwap__NotOwner();

error NFTSwap__AlreadyOwnedToken();

error NFTSwap__TransferFromFailed();

error NFTSwap__InvalidTrader();

error NFTSwap__InvalidRecipient();

error NFTSwap__NotExchangeTrader();

error NFTSwap__RecipientCannotBeTrader();

error NFTSwap__Locked();

contract NFTSwap is INFTSwap {
    uint256 private unlocked = 1;

    Exchange[] private s_allExchanges;

    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => Exchange))))
        private s_exchange;

    mapping(address => Exchange[]) private s_ownerToExchanges;

    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256[]))))
        private s_exchangeIndexes;

    modifier lock() {
        if (unlocked == 0) revert NFTSwap__Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getAllExchanges()
        external
        view
        override
        returns (Exchange[] memory)
    {
        return s_allExchanges;
    }

    function getExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external view override returns (Exchange memory) {
        return s_exchange[nft0][tokenId0][nft1][tokenId1];
    }

    function getOwnerExchanges(address owner)
        external
        view
        override
        returns (Exchange[] memory)
    {
        return s_ownerToExchanges[owner];
    }

    function createExchange(
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        _createExchange(address(0), recipient, nft0, nft1, tokenId0, tokenId1);
    }

    function createExchangeFor(
        address trader,
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (trader == address(0)) revert NFTSwap__ZeroAddress();
        if (trader == msg.sender || trader == nft0 || trader == nft1)
            revert NFTSwap__InvalidTrader();

        _createExchange(trader, recipient, nft0, nft1, tokenId0, tokenId1);
    }

    function trade(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override lock {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (exchange.owner == address(0)) revert NFTSwap__NonexistentExchange();
        if (msg.sender == exchange.owner) revert NFTSwap__InvalidTrader();
        if (exchange.trader != address(0) && msg.sender != exchange.trader)
            revert NFTSwap__NotExchangeTrader();

        IERC721(nft0).safeTransferFrom(address(this), msg.sender, tokenId0, "");
        IERC721(nft1).safeTransferFrom(
            msg.sender,
            exchange.recipient,
            tokenId1,
            ""
        );

        if (
            _getOwnerOf(nft0, tokenId0) != msg.sender &&
            _getOwnerOf(nft1, tokenId1) != exchange.recipient
        ) revert NFTSwap__TransferFromFailed();

        _deleteExchange(nft0, nft1, tokenId0, tokenId1);

        emit Trade(
            nft0,
            nft1,
            exchange.owner,
            msg.sender,
            exchange.recipient,
            tokenId0,
            tokenId1
        );
    }

    function updateExchangeRecipient(
        address newRecipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (newRecipient == address(0)) revert NFTSwap__ZeroAddress();

        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();

        s_exchange[nft0][tokenId0][nft1][tokenId1].recipient = newRecipient;

        emit ExchangeOwnerUpdated(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            newRecipient,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function updateExchangeTrader(
        address newTrader,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();
        if (newTrader == exchange.owner) revert NFTSwap__InvalidTrader();

        s_exchange[nft0][tokenId0][nft1][tokenId1].trader = newTrader;

        emit ExchangeTraderUpdated(
            nft0,
            nft1,
            exchange.owner,
            newTrader,
            exchange.recipient,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function cancelExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();

        IERC721(nft0).safeTransferFrom(
            address(this),
            exchange.recipient,
            tokenId0,
            ""
        );

        _deleteExchange(nft0, nft1, tokenId0, tokenId1);

        emit ExchangeCancelled(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            exchange.recipient,
            tokenId0,
            tokenId1
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _getOwnerOf(address nft, uint256 tokenId)
        private
        view
        returns (address)
    {
        return IERC721(nft).ownerOf(tokenId);
    }

    function _createExchange(
        address trader,
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];
        (nft0, nft1) = nft0 < nft1 ? (nft0, nft1) : (nft1, nft0);

        if (nft0 == address(0) || recipient == address(0))
            revert NFTSwap__ZeroAddress();

        if (exchange.owner != address(0)) revert NFTSwap__ExchangeExists();

        if (_getOwnerOf(nft1, tokenId1) == msg.sender)
            revert NFTSwap__AlreadyOwnedToken();

        if (recipient == trader) revert NFTSwap__RecipientCannotBeTrader();

        IERC721(nft0).safeTransferFrom(msg.sender, address(this), tokenId0, "");

        uint256 allExchangesIndex = s_allExchanges.length;
        uint256 ownerExchangesIndex = s_ownerToExchanges[msg.sender].length;

        s_exchangeIndexes[nft0][tokenId0][nft1][tokenId1] = [
            allExchangesIndex,
            ownerExchangesIndex
        ];
        s_allExchanges.push(
            Exchange(
                msg.sender,
                trader,
                recipient,
                nft0,
                nft1,
                tokenId0,
                tokenId1
            )
        );
        s_exchange[nft0][tokenId0][nft1][tokenId1] = Exchange(
            msg.sender,
            trader,
            recipient,
            nft0,
            nft1,
            tokenId0,
            tokenId1
        );
        s_ownerToExchanges[msg.sender].push(
            Exchange(
                msg.sender,
                trader,
                recipient,
                nft0,
                nft1,
                tokenId0,
                tokenId1
            )
        );

        emit ExchangeCreated(
            nft0,
            nft1,
            msg.sender,
            trader,
            recipient,
            tokenId0,
            tokenId1
        );
    }

    function _deleteExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];
        uint256[] memory indexes = s_exchangeIndexes[nft0][tokenId0][nft1][
            tokenId1
        ];
        Exchange[] memory allExchanges = s_allExchanges;
        Exchange[] memory ownerExchanges = s_ownerToExchanges[exchange.owner];

        delete s_exchangeIndexes[nft0][tokenId0][nft1][tokenId1];

        uint256 lastIndexOfAllExchanges = allExchanges.length - 1;
        uint256 lastIndexOfOwnerExchanges = ownerExchanges.length - 1;
        Exchange memory lastExchange;

        // Swap the index of the last exchange in the list with the index of the exchange to remove
        if (indexes[0] < lastIndexOfAllExchanges) {
            lastExchange = allExchanges[lastIndexOfAllExchanges];
            s_allExchanges[indexes[0]] = lastExchange;
            s_exchangeIndexes[lastExchange.nft0][lastExchange.tokenId0][
                lastExchange.nft1
            ][lastExchange.tokenId1][0] = indexes[0];
        }
        if (indexes[1] < lastIndexOfOwnerExchanges) {
            lastExchange = allExchanges[lastIndexOfOwnerExchanges];
            s_allExchanges[indexes[1]] = lastExchange;
            s_exchangeIndexes[lastExchange.nft0][lastExchange.tokenId0][
                lastExchange.nft1
            ][lastExchange.tokenId1][1] = indexes[1];
        }

        s_allExchanges.pop();
        s_ownerToExchanges[exchange.owner].pop();
        delete s_exchange[nft0][tokenId0][nft1][tokenId1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The NFTSwap interface
/// @notice Manage exchanges and trades
interface INFTSwap {
    /// @notice Emitted when an exchanged is created
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner. Owner initialized as the exchange creator
    /// @param trader The address of the exchange trader. Trader is the zero address if emitted from createExchange()
    /// @param recipient The address of the exchange recipient
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeCreated(
        address nft0,
        address nft1,
        address owner,
        address trader,
        address recipient,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchanged owner is updated
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param newOwner The address of the new exchange owner
    /// @param trader The address of the exchange trader
    /// @param recipient The address of the exchange recipient
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeOwnerUpdated(
        address nft0,
        address nft1,
        address newOwner,
        address trader,
        address recipient,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchanged trader is updated
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param newTrader The address of the new exchange trader
    /// @param recipient The address of the exchange recipient
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeTraderUpdated(
        address nft0,
        address nft1,
        address owner,
        address newTrader,
        address recipient,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchange is cancelled
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param trader The address of the exchange trader
    /// @param recipient The NFT recipient
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeCancelled(
        address nft0,
        address nft1,
        address owner,
        address trader,
        address recipient,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when a trade occurs
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param trader The address of the trader
    /// @param recipient The address of the exchange recipient
    /// @param tokenId0 The token id of {nft0} received
    /// @param tokenId1 The token id of {nft1} traded
    event Trade(
        address nft0,
        address nft1,
        address owner,
        address trader,
        address recipient,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Data model for exchanges
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param owner Address of exchange owner
    /// @param trader Address of trader. Can be set to zero address to allow all traders
    /// @param recipient Address of recipient.
    /// @param nft0 Address of the NFT to be exchanged
    /// @param nft1 Address of the requested NFT
    /// @param tokenId0 The token id of {nft0} to be traded by exchange owner
    /// @param tokenId1 The token id of {nft1} to be received by exchange owner
    struct Exchange {
        address owner;
        address trader;
        address recipient;
        address nft0;
        address nft1;
        uint256 tokenId0;
        uint256 tokenId1;
    }

    /// @notice Retrieves all token id pairs
    /// @return Array of exchanges
    function getAllExchanges() external view returns (Exchange[] memory);

    /// @notice Retreives exchange data of token id pairs
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be traded by exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    /// @return Exchange data (see Exchange struct for data model)
    function getExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external view returns (Exchange memory);

    /// @notice Retrieves all exchanges of {owner}
    /// @param owner Address of the owner
    /// @return Array of exchanges
    function getOwnerExchanges(address owner)
        external
        view
        returns (Exchange[] memory);

    /// @notice Creates an exchange with tokenId0 for tokenId1 that can be traded by anyone
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param recipient Address of recipient
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function createExchange(
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Creates an exchange with tokenId0 for tokenId1 that can be traded by a specific trader
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param trader Address of trader of the token requested
    /// @param recipient Address of recipient
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function createExchangeFor(
        address trader,
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Trades tokenId1 for tokenId0
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param nft0 Address of the NFT to be received by trader
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be received by trader
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function trade(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Updates exchange owner
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param newRecipient Address of the new recipient
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function updateExchangeRecipient(
        address newRecipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Updates exchange trader
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param newTrader Address of the new trader. Can be set to the zero address to allow all traders to trade
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function updateExchangeTrader(
        address newTrader,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Cancels exchange and sends tokenId0 to {to}
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param nft0 Address of the NFT to be traded by the exchange owner
    /// @param nft1 Address of the NFT requested by the exchange owner
    /// @param tokenId0 Token id of {nft0}
    /// @param tokenId1 Token id of {nft1}
    function cancelExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;
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