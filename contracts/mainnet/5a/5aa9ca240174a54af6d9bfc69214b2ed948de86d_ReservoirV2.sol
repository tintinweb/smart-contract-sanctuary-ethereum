// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ExchangeKind} from "./interfaces/IExchangeKind.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "./interfaces/ILooksRare.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "./interfaces/IWyvernV23.sol";

contract ReservoirV2 is Ownable {
    address public weth;

    address public looksRare;
    address public looksRareTransferManagerERC721;
    address public looksRareTransferManagerERC1155;

    address public wyvernV23;
    address public wyvernV23Proxy;

    address public zeroExV4;

    address public foundation;

    address public x2y2;
    address public x2y2ERC721Delegate;

    constructor(
        address wethAddress,
        address looksRareAddress,
        address wyvernV23Address,
        address zeroExV4Address,
        address foundationAddress,
        address x2y2Address,
        address x2y2ERC721DelegateAddress
    ) {
        weth = wethAddress;

        // --- LooksRare setup ---

        looksRare = looksRareAddress;

        // Cache the transfer manager contracts
        address transferSelectorNFT = ILooksRare(looksRare)
            .transferSelectorNFT();
        looksRareTransferManagerERC721 = ILooksRareTransferSelectorNFT(
            transferSelectorNFT
        ).TRANSFER_MANAGER_ERC721();
        looksRareTransferManagerERC1155 = ILooksRareTransferSelectorNFT(
            transferSelectorNFT
        ).TRANSFER_MANAGER_ERC1155();

        // --- WyvernV23 setup ---

        wyvernV23 = wyvernV23Address;

        // Create a user proxy
        address proxyRegistry = IWyvernV23(wyvernV23).registry();
        IWyvernV23ProxyRegistry(proxyRegistry).registerProxy();
        wyvernV23Proxy = IWyvernV23ProxyRegistry(proxyRegistry).proxies(
            address(this)
        );

        // Approve the token transfer proxy
        IERC20(weth).approve(
            IWyvernV23(wyvernV23).tokenTransferProxy(),
            type(uint256).max
        );

        // --- ZeroExV4 setup ---

        zeroExV4 = zeroExV4Address;

        // --- Foundation setup ---

        foundation = foundationAddress;

        // --- X2Y2 setup ---

        x2y2 = x2y2Address;
        x2y2ERC721Delegate = x2y2ERC721DelegateAddress;
    }

    receive() external payable {
        // For unwrapping WETH
    }

    function makeCalls(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external payable onlyOwner {
        bool success;
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = payable(targets[i]).call{value: values[i]}(data[i]);
            require(success, "Unsuccessfull call");
        }
    }

    // Terminology:
    // - "single" -> buy single token
    // - "batch" -> buy multiple tokens (natively, only 0xv4 supports this)
    // - "multi" -> buy multiple tokens (via the router)

    function singleERC721ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        uint16 feeBps
    ) external payable {
        address target;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
        } else if (exchangeKind == ExchangeKind.FOUNDATION) {
            target = foundation;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.WYVERN_V23) {
            // When filling LooksRare or ZeroExV4 listings we need to send
            // the NFT to the taker's wallet after the fill (since they do
            // not allow specifying a different recipient than the taker).
            IERC721(collection).transferFrom(address(this), receiver, tokenId);
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function singleERC721ListingFillWithPrecheck(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        address expectedOwner,
        uint16 feeBps
    ) external payable {
        if (expectedOwner != address(0)) {
            require(
                IERC721(collection).ownerOf(tokenId) == expectedOwner,
                "Unexpected owner"
            );
        }

        address target;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
        } else if (exchangeKind == ExchangeKind.FOUNDATION) {
            target = foundation;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.WYVERN_V23) {
            // When filling LooksRare or ZeroExV4 listings we need to send
            // the NFT to the taker's wallet after the fill (since they do
            // not allow specifying a different recipient than the taker).
            IERC721(collection).transferFrom(address(this), receiver, tokenId);
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function singleERC721BidFill(
        address, // referrer
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        address receiver,
        bool unwrapWeth
    ) external payable {
        address target;
        address operator;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            operator = wyvernV23Proxy;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            operator = looksRareTransferManagerERC721;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            operator = zeroExV4;
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
            operator = x2y2ERC721Delegate;
        } else {
            revert("Unsupported exchange");
        }

        // Approve the exchange to transfer the NFT out of the router.
        bool isApproved = IERC721(collection).isApprovedForAll(
            address(this),
            operator
        );
        if (!isApproved) {
            IERC721(collection).setApprovalForAll(operator, true);
        }

        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "Unsuccessfull fill");

        // Send the payment to the actual taker.
        uint256 balance = IERC20(weth).balanceOf(address(this));
        if (unwrapWeth) {
            IWETH(weth).withdraw(balance);
            (success, ) = payable(receiver).call{value: balance}("");
            require(success, "Could not send payment");
        } else {
            IERC20(weth).transfer(receiver, balance);
        }
    }

    function singleERC1155ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        uint256 amount,
        address receiver,
        uint256 feeBps
    ) external payable {
        address target;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.WYVERN_V23) {
            // When filling LooksRare or ZeroExV4 listings we need to send
            // the NFT to the taker's wallet after the fill (since they do
            // not allow specifying a different recipient than the taker).
            IERC1155(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId,
                amount,
                ""
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function singleERC1155ListingFillWithPrecheck(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        uint256 amount,
        address receiver,
        address expectedOwner,
        uint256 feeBps
    ) external payable {
        if (expectedOwner != address(0)) {
            require(
                IERC1155(collection).balanceOf(expectedOwner, tokenId) >=
                    amount,
                "Unexpected owner/balance"
            );
        }

        address target;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.WYVERN_V23) {
            // When filling LooksRare or ZeroExV4 listings we need to send
            // the NFT to the taker's wallet after the fill (since they do
            // not allow specifying a different recipient than the taker).
            IERC1155(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId,
                amount,
                ""
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function batchERC1155ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address[] memory collections,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address receiver,
        uint256 feeBps
    ) external payable {
        address target;
        if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        for (uint256 i = 0; i < collections.length; i++) {
            // When filling LooksRare or ZeroExV4 listings we need to send
            // the NFT to the taker's wallet after the fill (since they do
            // not allow specifying a different recipient than the taker).
            IERC1155(collections[i]).safeTransferFrom(
                address(this),
                receiver,
                tokenIds[i],
                amounts[i],
                ""
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function singleERC1155BidFill(
        address, // referrer
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        address receiver,
        bool unwrapWeth
    ) external payable {
        address target;
        address operator;
        if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            operator = wyvernV23Proxy;
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            operator = looksRareTransferManagerERC1155;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            operator = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        // Approve the exchange to transfer the NFT out of the router.
        bool isApproved = IERC1155(collection).isApprovedForAll(
            address(this),
            operator
        );
        if (!isApproved) {
            IERC1155(collection).setApprovalForAll(operator, true);
        }

        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "Unsuccessfull fill");

        // Send the payment to the actual taker.
        uint256 balance = IERC20(weth).balanceOf(address(this));
        if (unwrapWeth) {
            IWETH(weth).withdraw(balance);
            (success, ) = payable(receiver).call{value: balance}("");
            require(success, "Could not send payment");
        } else {
            IERC20(weth).transfer(receiver, balance);
        }
    }

    function multiListingFill(
        bytes[] calldata data,
        uint256[] calldata values,
        bool revertIfIncomplete
    ) external payable {
        bool success;
        for (uint256 i = 0; i < data.length; i++) {
            (success, ) = address(this).call{value: values[i]}(data[i]);
            if (revertIfIncomplete) {
                require(success, "Atomic fill failed");
            }
        }

        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Could not send payment");
    }

    // ERC721 / ERC1155 overrides

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length == 0) {
            return this.onERC721Received.selector;
        }

        bytes4 selector = bytes4(data[:4]);
        require(
            selector == this.singleERC721BidFill.selector,
            "Wrong selector"
        );

        (bool success, ) = address(this).call(data);
        require(success, "Unsuccessfull fill");

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // tokenId
        uint256, // amount
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length == 0) {
            return this.onERC1155Received.selector;
        }

        bytes4 selector = bytes4(data[:4]);
        require(
            selector == this.singleERC1155BidFill.selector,
            "Wrong selector"
        );

        (bool success, ) = address(this).call(data);
        require(success, "Unsuccessfull fill");

        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
pragma solidity ^0.8.9;

enum ExchangeKind {
    WYVERN_V23,
    LOOKS_RARE,
    ZEROEX_V4,
    FOUNDATION,
    X2Y2,
    SEAPORT
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILooksRare {
    function transferSelectorNFT() external view returns (address);
}

interface ILooksRareTransferSelectorNFT {
    function TRANSFER_MANAGER_ERC721() external view returns (address);

    function TRANSFER_MANAGER_ERC1155() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWyvernV23 {
    function registry() external view returns (address);

    function tokenTransferProxy() external view returns (address);
}

interface IWyvernV23ProxyRegistry {
    function registerProxy() external;

    function proxies(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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