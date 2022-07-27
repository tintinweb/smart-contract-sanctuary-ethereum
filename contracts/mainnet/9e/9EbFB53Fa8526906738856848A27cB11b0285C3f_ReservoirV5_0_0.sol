// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ExchangeKind} from "./interfaces/IExchangeKind.sol";
import {IWETH} from "./interfaces/IWETH.sol";

import {IFoundation} from "./interfaces/IFoundation.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "./interfaces/ILooksRare.sol";
import {ISeaport} from "./interfaces/ISeaport.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "./interfaces/IWyvernV23.sol";
import {IX2Y2} from "./interfaces/IX2Y2.sol";
import {IZeroExV4} from "./interfaces/IZeroExV4.sol";

contract ReservoirV5_0_0 is Ownable, ReentrancyGuard {
    address public immutable weth;

    address public immutable looksRare;
    address public immutable looksRareTransferManagerERC721;
    address public immutable looksRareTransferManagerERC1155;

    address public immutable wyvernV23;
    address public immutable wyvernV23Proxy;

    address public immutable zeroExV4;

    address public immutable foundation;

    address public immutable x2y2;
    address public immutable x2y2ERC721Delegate;

    address public immutable seaport;

    error UnexpectedOwnerOrBalance();
    error UnexpectedSelector();
    error UnsuccessfulCall();
    error UnsuccessfulFill();
    error UnsuccessfulPayment();
    error UnsupportedExchange();

    constructor(
        address wethAddress,
        address looksRareAddress,
        address wyvernV23Address,
        address zeroExV4Address,
        address foundationAddress,
        address x2y2Address,
        address x2y2ERC721DelegateAddress,
        address seaportAddress
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

        // --- Seaport setup ---

        seaport = seaportAddress;

        // Approve the exchange
        IERC20(weth).approve(seaport, type(uint256).max);
    }

    receive() external payable {
        // For unwrapping WETH
    }

    function makeCalls(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external payable onlyOwner nonReentrant {
        bool success;

        uint256 length = targets.length;
        for (uint256 i = 0; i < length; ) {
            (success, ) = payable(targets[i]).call{value: values[i]}(data[i]);
            if (!success) {
                revert UnsuccessfulCall();
            }

            unchecked {
                ++i;
            }
        }
    }

    // Terminology:
    // - "single" -> buy single token
    // - "batch" -> buy multiple tokens (natively, only 0xv4, Seaport and X2Y2 support this)
    // - "multi" -> buy multiple tokens (via the router)

    function singleERC721ListingFill(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        bytes4 selector = bytes4(data[:4]);

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            if (
                selector !=
                ILooksRare.matchAskWithTakerBidUsingETHAndWETH.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            if (selector != IZeroExV4.buyERC721.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
            if (selector != IX2Y2.run.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.FOUNDATION) {
            target = foundation;
            if (selector != IFoundation.buyV2.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient other than the taker)
            IERC721(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function singleERC721ListingFillWithPrecheck(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        address expectedOwner,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        if (
            expectedOwner != address(0) &&
            IERC721(collection).ownerOf(tokenId) != expectedOwner
        ) {
            revert UnexpectedOwnerOrBalance();
        }

        bytes4 selector = bytes4(data[:4]);

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            if (
                selector !=
                ILooksRare.matchAskWithTakerBidUsingETHAndWETH.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            if (selector != IZeroExV4.buyERC721.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
            if (selector != IX2Y2.run.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.FOUNDATION) {
            target = foundation;
            if (selector != IFoundation.buyV2.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient other than the taker)
            IERC721(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function batchERC721ListingFill(
        bytes calldata data,
        address[] calldata collections,
        uint256[] calldata tokenIds,
        address receiver,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        // Only `zeroExV4` is supported
        if (bytes4(data[:4]) != IZeroExV4.batchBuyERC721s.selector) {
            revert UnexpectedSelector();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = zeroExV4.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        // When filling anything other than Wyvern or Seaport we need to send
        // the NFT to the taker's wallet after the fill (since we cannot have
        // a recipient other than the taker)
        uint256 length = collections.length;
        for (uint256 i = 0; i < length; ) {
            IERC721(collections[i]).safeTransferFrom(
                address(this),
                receiver,
                tokenIds[i]
            );

            unchecked {
                ++i;
            }
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function singleERC721BidFill(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        address receiver,
        bool unwrapWeth
    ) external payable nonReentrant {
        bytes4 selector = bytes4(data[:4]);

        address target;
        address operator;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            operator = wyvernV23Proxy;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            operator = looksRareTransferManagerERC721;
            if (selector != ILooksRare.matchBidWithTakerAsk.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            operator = zeroExV4;
            if (selector != IZeroExV4.sellERC721.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.X2Y2) {
            target = x2y2;
            operator = x2y2ERC721Delegate;
            if (selector != IX2Y2.run.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        // Approve the exchange to transfer the NFT out of the router
        bool isApproved = IERC721(collection).isApprovedForAll(
            address(this),
            operator
        );
        if (!isApproved) {
            IERC721(collection).setApprovalForAll(operator, true);
        }

        // Get the WETH balance before filling
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));

        (bool success, ) = target.call{value: msg.value}(data);
        if (!success) {
            revert UnsuccessfulPayment();
        }

        // Send the payment to the actual taker
        uint256 balance = IERC20(weth).balanceOf(address(this)) -
            wethBalanceBefore;
        if (unwrapWeth) {
            IWETH(weth).withdraw(balance);

            (success, ) = payable(receiver).call{value: balance}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        } else {
            IERC20(weth).transfer(receiver, balance);
        }
    }

    function singleERC1155ListingFill(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        uint256 amount,
        address receiver,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        bytes4 selector = bytes4(data[:4]);

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            if (
                selector !=
                ILooksRare.matchAskWithTakerBidUsingETHAndWETH.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            if (selector != IZeroExV4.buyERC1155.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient other than the taker)
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
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function singleERC1155ListingFillWithPrecheck(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        uint256 amount,
        address receiver,
        address expectedOwner,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        if (
            expectedOwner != address(0) &&
            IERC1155(collection).balanceOf(expectedOwner, tokenId) < amount
        ) {
            revert UnexpectedOwnerOrBalance();
        }

        bytes4 selector = bytes4(data[:4]);

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            if (
                selector !=
                ILooksRare.matchAskWithTakerBidUsingETHAndWETH.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            if (selector != IZeroExV4.buyERC1155.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient other than the taker)
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
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function batchERC1155ListingFill(
        bytes calldata data,
        address[] calldata collections,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address receiver,
        address feeRecipient,
        uint16 feeBps
    ) external payable nonReentrant {
        // Only `zeroExV4` is supported
        if (bytes4(data[:4]) != IZeroExV4.batchBuyERC1155s.selector) {
            revert UnexpectedSelector();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = zeroExV4.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        // Avoid "Stack too deep" errors
        {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient other than the taker)
            uint256 length = collections.length;
            for (uint256 i = 0; i < length; ) {
                IERC1155(collections[i]).safeTransferFrom(
                    address(this),
                    receiver,
                    tokenIds[i],
                    amounts[i],
                    ""
                );

                unchecked {
                    ++i;
                }
            }
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function singleERC1155BidFill(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        address receiver,
        bool unwrapWeth
    ) external payable nonReentrant {
        bytes4 selector = bytes4(data[:4]);

        address target;
        address operator;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
            if (
                selector != ISeaport.fulfillAdvancedOrder.selector &&
                selector != ISeaport.matchAdvancedOrders.selector
            ) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
            target = wyvernV23;
            operator = wyvernV23Proxy;
            if (selector != IWyvernV23.atomicMatch_.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.LOOKS_RARE) {
            target = looksRare;
            operator = looksRareTransferManagerERC1155;
            if (selector != ILooksRare.matchBidWithTakerAsk.selector) {
                revert UnexpectedSelector();
            }
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
            operator = zeroExV4;
            if (selector != IZeroExV4.sellERC1155.selector) {
                revert UnexpectedSelector();
            }
        } else {
            revert UnsupportedExchange();
        }

        // Approve the exchange to transfer the NFT out of the router
        bool isApproved = IERC1155(collection).isApprovedForAll(
            address(this),
            operator
        );
        if (!isApproved) {
            IERC1155(collection).setApprovalForAll(operator, true);
        }

        // Get the WETH balance before filling
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));

        (bool success, ) = target.call{value: msg.value}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        // Send the payment to the actual taker
        uint256 balance = IERC20(weth).balanceOf(address(this)) -
            wethBalanceBefore;
        if (unwrapWeth) {
            IWETH(weth).withdraw(balance);

            (success, ) = payable(receiver).call{value: balance}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
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

        uint256 balanceBefore = address(this).balance - msg.value;

        uint256 length = data.length;
        for (uint256 i = 0; i < length; ) {
            (success, ) = address(this).call{value: values[i]}(data[i]);
            if (revertIfIncomplete && !success) {
                revert UnsuccessfulFill();
            }

            unchecked {
                ++i;
            }
        }

        uint256 balanceAfter = address(this).balance;

        if (balanceAfter > balanceBefore) {
            (success, ) = msg.sender.call{value: balanceAfter - balanceBefore}(
                ""
            );
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
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
        if (selector != this.singleERC721BidFill.selector) {
            revert UnexpectedSelector();
        }

        (bool success, ) = address(this).call(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

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
        if (selector != this.singleERC1155BidFill.selector) {
            revert UnexpectedSelector();
        }

        (bool success, ) = address(this).call(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        return this.onERC1155Received.selector;
    }
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

interface IFoundation {
    function buyV2(
        address nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        address referrer
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOrderTypes {
    struct MakerOrder {
        bool isOrderAsk;
        address signer;
        address collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isOrderAsk;
        address taker;
        uint256 price;
        uint256 tokenId;
        uint256 minPercentageToAsk;
        bytes params;
    }
}

interface ILooksRare {
    function transferSelectorNFT() external view returns (address);

    function matchAskWithTakerBidUsingETHAndWETH(
        IOrderTypes.TakerOrder calldata takerBid,
        IOrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchBidWithTakerAsk(
        IOrderTypes.TakerOrder calldata takerAsk,
        IOrderTypes.MakerOrder calldata makerBid
    ) external;
}

interface ILooksRareTransferSelectorNFT {
    function TRANSFER_MANAGER_ERC721() external view returns (address);

    function TRANSFER_MANAGER_ERC1155() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISeaport {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address recipient;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address recipient;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    function matchAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWyvernV23 {
    function registry() external view returns (address);

    function tokenTransferProxy() external view returns (address);

    function atomicMatch_(
        address[14] calldata addrs,
        uint256[18] calldata uints,
        uint8[8] calldata feeMethodsSidesKindsHowToCalls,
        bytes calldata calldataBuy,
        bytes calldata calldataSell,
        bytes calldata replacementPatternBuy,
        bytes calldata replacementPatternSell,
        bytes calldata staticExtradataBuy,
        bytes calldata staticExtradataSell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata
    ) external payable;
}

interface IWyvernV23ProxyRegistry {
    function registerProxy() external;

    function proxies(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IX2Y2 {
    struct OrderItem {
        uint256 price;
        bytes data;
    }

    struct Order {
        uint256 salt;
        address user;
        uint256 network;
        uint256 intent;
        uint256 delegateType;
        uint256 deadline;
        address currency;
        bytes dataMask;
        OrderItem[] items;
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signVersion;
    }

    struct SettleShared {
        uint256 salt;
        uint256 deadline;
        uint256 amountToEth;
        uint256 amountToWeth;
        address user;
        bool canFail;
    }

    struct Fee {
        uint256 percentage;
        address to;
    }

    enum Op {
        INVALID,
        COMPLETE_SELL_OFFER,
        COMPLETE_BUY_OFFER,
        CANCEL_OFFER,
        BID,
        COMPLETE_AUCTION,
        REFUND_AUCTION,
        REFUND_AUCTION_STUCK_ITEM
    }

    struct SettleDetail {
        Op op;
        uint256 orderIdx;
        uint256 itemIdx;
        uint256 price;
        bytes32 itemHash;
        address executionDelegate;
        bytes dataReplacement;
        uint256 bidIncentivePct;
        uint256 aucMinIncrementPct;
        uint256 aucIncDurationSecs;
        Fee[] fees;
    }

    struct RunInput {
        Order[] orders;
        SettleDetail[] details;
        SettleShared shared;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function run(RunInput calldata input) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IZeroExV4 {
    struct Property {
        address propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct ERC721Order {
        uint8 direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        address erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc721Token;
        uint256 erc721TokenId;
        Property[] erc721TokenProperties;
    }

    struct ERC1155Order {
        uint8 direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        address erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        uint128 erc1155TokenAmount;
    }

    struct Signature {
        uint8 signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function buyERC721(
        ERC721Order calldata sellOrder,
        Signature calldata signature,
        bytes memory callbackData
    ) external payable;

    function batchBuyERC721s(
        ERC721Order[] calldata sellOrders,
        Signature[] calldata signatures,
        bytes[] calldata callbackData,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory);

    function sellERC721(
        ERC721Order calldata buyOrder,
        Signature calldata signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        bytes memory callbackData
    ) external;

    function buyERC1155(
        ERC1155Order calldata sellOrder,
        Signature calldata signature,
        uint128 erc1155BuyAmount,
        bytes calldata callbackData
    ) external payable;

    function batchBuyERC1155s(
        ERC1155Order[] calldata sellOrders,
        Signature[] calldata signatures,
        uint128[] calldata erc1155FillAmounts,
        bytes[] calldata callbackData,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    function sellERC1155(
        ERC1155Order calldata buyOrder,
        Signature calldata signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes calldata callbackData
    ) external;
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