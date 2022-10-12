// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint256 punkIndex)
        external
        view
        returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transferPunk(address to, uint256 punkIndex) external;

    function buyPunk(uint256 punkIndex) external payable;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ICryptoPunksMarket} from "../interfaces/ICryptoPunksMarket.sol";

// Since the CryptoPunks are not ERC721 standard-compliant, you cannot create
// orders for them on modern exchange protocols like Seaport. The workarounds
// include using the wrapped version of CryptoPunks (cumbersome and costly to
// use) or using the native CryptoPunks exchange (it lacks features available
// available when using newer exchange protocols - off-chain orders, bids for
// the whole collection or for a set of attributes). To overcome all of these
// we created a new contract called `PunksProxy` which acts in a similiar way
// to the wrapped version of the CryptoPunks but in a zero-abstraction manner
// with everything abstracted out (eg. no need to wrap or unwrap). It acts as
// a standard ERC721 with the caveat that for any transfer operation there is
// a corresponding CryptoPunks-native approval (basically a private offer for
// a price of zero to the proxy contract).
contract PunksProxy {
    using Address for address;

    // --- Fields ---

    ICryptoPunksMarket public constant EXCHANGE =
        ICryptoPunksMarket(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // --- Errors ---

    error Unauthorized();
    error UnsuccessfulSafeTransfer();

    // --- ERC721 standard events ---

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // --- ERC721 standard methods ---

    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = EXCHANGE.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = EXCHANGE.punkIndexToAddress(tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        returns (address approved)
    {
        approved = tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool approved)
    {
        approved = operatorApprovals[owner][operator];
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Unauthorized();
        }

        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        transfer(from, to, tokenId);
        checkOnERC721Received(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transfer(from, to, tokenId);
        checkOnERC721Received(from, to, tokenId, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transfer(from, to, tokenId);
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address owner = ownerOf(tokenId);
        if (from != owner) {
            revert Unauthorized();
        }

        if (
            msg.sender != owner &&
            getApproved(tokenId) != msg.sender &&
            !isApprovedForAll(owner, msg.sender)
        ) {
            revert Unauthorized();
        }

        EXCHANGE.buyPunk(tokenId);
        EXCHANGE.transferPunk(to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 result) {
                if (result != IERC721Receiver.onERC721Received.selector) {
                    revert UnsuccessfulSafeTransfer();
                }
            } catch {
                revert UnsuccessfulSafeTransfer();
            }
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
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract ReservoirV6_0_0 is ReentrancyGuard {
    using Address for address;

    // --- Structs ---

    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }

    struct AmountCheckInfo {
        address target;
        bytes data;
        uint256 threshold;
    }

    // --- Errors ---

    error UnsuccessfulExecution();
    error UnsuccessfulPayment();

    // --- Modifiers ---

    modifier refundETH() {
        _;

        uint256 leftover = address(this).balance;
        if (leftover > 0) {
            (bool success, ) = payable(msg.sender).call{value: leftover}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    // --- Fallback ---

    receive() external payable {}

    // --- Public ---

    // Trigger a set of executions atomically
    function execute(ExecutionInfo[] calldata executionInfos)
        external
        payable
        nonReentrant
        refundETH
    {
        uint256 length = executionInfos.length;
        for (uint256 i = 0; i < length; ) {
            _executeInternal(executionInfos[i]);

            unchecked {
                ++i;
            }
        }
    }

    // Trigger a set of executions with amount checking. As opposed to the regular
    // `execute` method, `executeWithAmountCheck` supports stopping the executions
    // once the provided amount check reaches a certain value. This is useful when
    // trying to fill orders with slippage (eg. provide multiple orders and try to
    // fill until a certain balance is reached). In order to be flexible, checking
    // the amount is done generically by calling the `target` contract with `data`.
    // For example, this could be used to check the ERC721 total owned balance (by
    // using `balanceOf(owner)`), the ERC1155 total owned balance per token id (by
    // using `balanceOf(owner, tokenId)`), but also for checking the ERC1155 total
    // owned balance per multiple token ids (by using a custom contract that wraps
    // `balanceOfBatch(owners, tokenIds)`).
    function executeWithAmountCheck(
        ExecutionInfo[] calldata executionInfos,
        AmountCheckInfo calldata amountCheckInfo
    ) external payable nonReentrant refundETH {
        // Cache some data for efficiency
        address target = amountCheckInfo.target;
        bytes calldata data = amountCheckInfo.data;
        uint256 threshold = amountCheckInfo.threshold;

        uint256 length = executionInfos.length;
        for (uint256 i = 0; i < length; ) {
            // Check the amount and break if it exceeds the threshold
            uint256 amount = _getAmount(target, data);
            if (amount >= threshold) {
                break;
            }

            _executeInternal(executionInfos[i]);

            unchecked {
                ++i;
            }
        }
    }

    // --- Internal ---

    function _executeInternal(ExecutionInfo calldata executionInfo) internal {
        address module = executionInfo.module;

        // Ensure the target is a contract
        if (!module.isContract()) {
            revert UnsuccessfulExecution();
        }

        (bool success, ) = module.call{value: executionInfo.value}(
            executionInfo.data
        );
        if (!success) {
            revert UnsuccessfulExecution();
        }
    }

    function _getAmount(address target, bytes calldata data)
        internal
        view
        returns (uint256 amount)
    {
        // Ensure the target is a contract
        if (!target.isContract()) {
            revert UnsuccessfulExecution();
        }

        (bool success, bytes memory result) = target.staticcall(data);
        if (!success) {
            revert UnsuccessfulExecution();
        }

        amount = abi.decode(result, (uint256));
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
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ExchangeKind} from "../interfaces/IExchangeKind.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import {IFoundation} from "../interfaces/IFoundation.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "../interfaces/ILooksRare.sol";
import {ISeaport} from "../interfaces/ISeaport.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "../interfaces/IWyvernV23.sol";
import {IX2Y2} from "../interfaces/IX2Y2.sol";
import {IZeroExV4} from "../interfaces/IZeroExV4.sol";

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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFoundation {
    function buyV2(
        IERC721 nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        address referrer
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILooksRare {
    struct MakerOrder {
        bool isOrderAsk;
        address signer;
        IERC165 collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        IERC20 currency;
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

    function transferSelectorNFT() external view returns (address);

    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
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

    struct OrderComponents {
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
        uint256 counter;
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

    struct Order {
        OrderParameters parameters;
        bytes signature;
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

    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

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

    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

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

    struct Pair {
        address token;
        uint256 tokenId;
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

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        IERC721 erc721Token;
        uint256 erc721TokenId;
        Property[] erc721TokenProperties;
    }

    struct ERC1155Order {
        uint8 direction;
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        IERC1155 erc1155Token;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {IZeroExV4} from "../../../interfaces/IZeroExV4.sol";

// Notes:
// - supports filling listings (both ERC721/ERC1155)
// - supports filling offers (both ERC721/ERC1155)

contract ZeroExV4Module is BaseExchangeModule {
    using SafeERC20 for IERC20;

    // --- Fields ---

    IZeroExV4 public constant EXCHANGE =
        IZeroExV4(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- [ERC721] Single ETH listing ---

    function acceptETHListingERC721(
        IZeroExV4.ERC721Order calldata order,
        IZeroExV4.Signature calldata signature,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC721(
            order,
            signature,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Single ERC20 listing ---

    function acceptERC20ListingERC721(
        IZeroExV4.ERC721Order calldata order,
        IZeroExV4.Signature calldata signature,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC721(
            order,
            signature,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Multiple ETH listings ---

    function acceptETHListingsERC721(
        IZeroExV4.ERC721Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC721s(
            orders,
            signatures,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Multiple ERC20 listings ---

    function acceptERC20ListingsERC721(
        IZeroExV4.ERC721Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC721s(
            orders,
            signatures,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC1155] Single ETH listing ---

    function acceptETHListingERC1155(
        IZeroExV4.ERC1155Order calldata order,
        IZeroExV4.Signature calldata signature,
        uint128 amount,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC1155(
            order,
            signature,
            amount,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC1155] Single ERC20 listing ---

    function acceptERC20ListingERC1155(
        IZeroExV4.ERC1155Order calldata order,
        IZeroExV4.Signature calldata signature,
        uint128 amount,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC1155(
            order,
            signature,
            amount,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC1155] Multiple ETH listings ---

    function acceptETHListingsERC1155(
        IZeroExV4.ERC1155Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        uint128[] memory amounts,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC1155s(
            orders,
            signatures,
            amounts,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC1155] Multiple ERC20 listings ---

    function acceptERC20ListingsERC1155(
        IZeroExV4.ERC1155Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        uint128[] memory amounts,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC1155s(
            orders,
            signatures,
            amounts,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Single offer ---

    function acceptERC721Offer(
        IZeroExV4.ERC721Order calldata order,
        IZeroExV4.Signature calldata signature,
        OfferParams calldata params,
        uint256 tokenId
    ) external nonReentrant {
        // Approve the exchange if needed
        _approveERC721IfNeeded(order.erc721Token, address(EXCHANGE));

        // Execute fill
        try EXCHANGE.sellERC721(order, signature, tokenId, false, "") {
            order.erc20Token.safeTransfer(
                params.fillTo,
                order.erc20TokenAmount
            );
        } catch {
            // Revert if specified
            if (params.revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, order.erc721Token, tokenId);
    }

    // --- [ERC1155] Single offer ---

    function acceptERC1155Offer(
        IZeroExV4.ERC1155Order calldata order,
        IZeroExV4.Signature calldata signature,
        uint128 amount,
        OfferParams calldata params,
        uint256 tokenId
    ) external nonReentrant {
        // Approve the exchange if needed
        _approveERC1155IfNeeded(order.erc1155Token, address(EXCHANGE));

        // Execute fill
        try EXCHANGE.sellERC1155(order, signature, tokenId, amount, false, "") {
            order.erc20Token.safeTransfer(
                params.fillTo,
                (order.erc20TokenAmount * order.erc1155TokenAmount) / amount
            );
        } catch {
            // Revert if specified
            if (params.revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }

        // Refund any ERC1155 leftover
        _sendAllERC1155(params.refundTo, order.erc1155Token, tokenId);
    }

    // --- ERC721 / ERC1155 hooks ---

    // Single token offer acceptance can be done approval-less by using the
    // standard `safeTransferFrom` method together with specifying data for
    // further contract calls. An example:
    // `safeTransferFrom(
    //      0xWALLET,
    //      0xMODULE,
    //      TOKEN_ID,
    //      0xABI_ENCODED_ROUTER_EXECUTION_CALLDATA_FOR_OFFER_ACCEPTANCE
    // )`

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
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
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC1155Received.selector;
    }

    // --- Internal ---

    function _buyERC721(
        IZeroExV4.ERC721Order calldata order,
        IZeroExV4.Signature calldata signature,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        // Execute fill
        try EXCHANGE.buyERC721{value: value}(order, signature, "") {
            order.erc721Token.safeTransferFrom(
                address(this),
                receiver,
                order.erc721TokenId
            );
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC1155(
        IZeroExV4.ERC1155Order calldata order,
        IZeroExV4.Signature calldata signature,
        uint128 amount,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        try EXCHANGE.buyERC1155{value: value}(order, signature, amount, "") {
            order.erc1155Token.safeTransferFrom(
                address(this),
                receiver,
                order.erc1155TokenId,
                amount,
                ""
            );
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC721s(
        IZeroExV4.ERC721Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        uint256 length = orders.length;

        // Execute fill
        try
            EXCHANGE.batchBuyERC721s{value: value}(
                orders,
                signatures,
                new bytes[](length),
                revertIfIncomplete
            )
        returns (bool[] memory fulfilled) {
            for (uint256 i = 0; i < length; ) {
                if (fulfilled[i]) {
                    orders[i].erc721Token.safeTransferFrom(
                        address(this),
                        receiver,
                        orders[i].erc721TokenId
                    );
                }

                unchecked {
                    ++i;
                }
            }
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC1155s(
        IZeroExV4.ERC1155Order[] calldata orders,
        IZeroExV4.Signature[] calldata signatures,
        uint128[] memory amounts,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        uint256 length = orders.length;

        uint128[] memory fillAmounts = new uint128[](length);
        for (uint256 i = 0; i < length; ) {
            fillAmounts[i] = amounts[i];

            unchecked {
                ++i;
            }
        }

        // Execute fill
        try
            EXCHANGE.batchBuyERC1155s{value: value}(
                orders,
                signatures,
                fillAmounts,
                new bytes[](length),
                revertIfIncomplete
            )
        returns (bool[] memory fulfilled) {
            for (uint256 i = 0; i < length; ) {
                if (fulfilled[i]) {
                    orders[i].erc1155Token.safeTransferFrom(
                        address(this),
                        receiver,
                        orders[i].erc1155TokenId,
                        fillAmounts[i],
                        ""
                    );
                }

                unchecked {
                    ++i;
                }
            }
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseModule} from "../BaseModule.sol";

// Notes:
// - includes common helpers useful for all marketplace/exchange modules

abstract contract BaseExchangeModule is BaseModule {
    using SafeERC20 for IERC20;

    // --- Structs ---

    // Every fill execution has the following parameters:
    // - `fillTo`: the recipient of the received items
    // - `refundTo`: the recipient of any refunds
    // - `revertIfIncomplete`: whether to revert or skip unsuccessful fills

    // The below `ETHListingParams` and `ERC20ListingParams` rely on the
    // off-chain execution encoder to ensure that the orders filled with
    // the passed in listing parameters exactly match (eg. order amounts
    // and payment tokens match).

    struct ETHListingParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
        // The total amount of ETH to be provided when filling
        uint256 amount;
    }

    struct ERC20ListingParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
        // The ERC20 payment token for the listings
        IERC20 token;
        // The total amount of `token` to be provided when filling
        uint256 amount;
    }

    struct OfferParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
    }

    struct Fee {
        address recipient;
        uint256 amount;
    }

    // --- Fields ---

    address public immutable router;

    // --- Errors ---

    error UnsuccessfulFill();

    // --- Constructor ---

    constructor(address routerAddress) {
        router = routerAddress;
    }

    // --- Modifiers ---

    modifier refundETHLeftover(address refundTo) {
        _;

        uint256 leftover = address(this).balance;
        if (leftover > 0) {
            _sendETH(refundTo, leftover);
        }
    }

    modifier refundERC20Leftover(address refundTo, IERC20 token) {
        _;

        uint256 leftover = token.balanceOf(address(this));
        if (leftover > 0) {
            token.safeTransfer(refundTo, leftover);
        }
    }

    modifier chargeETHFees(Fee[] calldata fees, uint256 amount) {
        if (fees.length == 0) {
            _;
        } else {
            uint256 balanceBefore = address(this).balance;

            _;

            uint256 length = fees.length;
            if (length > 0) {
                uint256 balanceAfter = address(this).balance;
                uint256 actualPaid = balanceBefore - balanceAfter;

                uint256 actualFee;
                for (uint256 i = 0; i < length; ) {
                    // Adjust the fee to what was actually paid
                    actualFee = (fees[i].amount * actualPaid) / amount;
                    if (actualFee > 0) {
                        _sendETH(fees[i].recipient, actualFee);
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    modifier chargeERC20Fees(
        Fee[] calldata fees,
        IERC20 token,
        uint256 amount
    ) {
        if (fees.length == 0) {
            _;
        } else {
            uint256 balanceBefore = token.balanceOf(address(this));

            _;

            uint256 length = fees.length;
            if (length > 0) {
                uint256 balanceAfter = token.balanceOf(address(this));
                uint256 actualPaid = balanceBefore - balanceAfter;

                uint256 actualFee;
                for (uint256 i = 0; i < length; ) {
                    // Adjust the fee to what was actually paid
                    actualFee = (fees[i].amount * actualPaid) / amount;
                    if (actualFee > 0) {
                        token.safeTransfer(fees[i].recipient, actualFee);
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    // --- Helpers ---

    function _sendAllERC20(address to, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(to, balance);
        }
    }

    function _sendAllERC721(
        address to,
        IERC721 token,
        uint256 tokenId
    ) internal {
        if (token.ownerOf(tokenId) == address(this)) {
            token.safeTransferFrom(address(this), to, tokenId);
        }
    }

    function _sendAllERC1155(
        address to,
        IERC1155 token,
        uint256 tokenId
    ) internal {
        uint256 balance = token.balanceOf(address(this), tokenId);
        if (balance > 0) {
            token.safeTransferFrom(address(this), to, tokenId, balance, "");
        }
    }

    function _approveERC20IfNeeded(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.approve(spender, amount - allowance);
        }
    }

    function _approveERC721IfNeeded(IERC721 token, address operator) internal {
        bool isApproved = token.isApprovedForAll(address(this), operator);
        if (!isApproved) {
            token.setApprovalForAll(operator, true);
        }
    }

    function _approveERC1155IfNeeded(IERC1155 token, address operator)
        internal
    {
        bool isApproved = token.isApprovedForAll(address(this), operator);
        if (!isApproved) {
            token.setApprovalForAll(operator, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {TwoStepOwnable} from "../../misc/TwoStepOwnable.sol";

// Notes:
// - includes common helpers useful for all modules

abstract contract BaseModule is TwoStepOwnable, ReentrancyGuard {
    // --- Events ---

    event CallExecuted(address target, bytes data, uint256 value);

    // --- Errors ---

    error UnsuccessfulCall();
    error UnsuccessfulPayment();
    error WrongParams();

    // --- Constructor ---

    constructor(address owner) TwoStepOwnable(owner) {}

    // --- Owner ---

    // To be able to recover anything that gets stucked by mistake in the module,
    // we allow the owner to perform any arbitrary call. Since the goal is to be
    // stateless, this should only happen in case of mistakes. In addition, this
    // method is also useful for withdrawing any earned trading rewards.
    function makeCalls(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external payable onlyOwner nonReentrant {
        uint256 length = targets.length;
        for (uint256 i = 0; i < length; ) {
            _makeCall(targets[i], data[i], values[i]);
            emit CallExecuted(targets[i], data[i], values[i]);

            unchecked {
                ++i;
            }
        }
    }

    // --- Helpers ---

    function _sendETH(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) {
            revert UnsuccessfulPayment();
        }
    }

    function _makeCall(
        address target,
        bytes memory data,
        uint256 value
    ) internal {
        (bool success, ) = payable(target).call{value: value}(data);
        if (!success) {
            revert UnsuccessfulCall();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Adapted from:
// https://github.com/boringcrypto/BoringSolidity/blob/e74c5b22a61bfbadd645e51a64aa1d33734d577a/contracts/BoringOwnable.sol
contract TwoStepOwnable {
    // --- Fields ---

    address public owner;
    address public pendingOwner;

    // --- Events ---

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // --- Errors ---

    error InvalidParams();
    error Unauthorized();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    // --- Methods ---

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        if (msg.sender != _pendingOwner) {
            revert Unauthorized();
        }

        owner = _pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, _pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseModule} from "./BaseModule.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

// The way we deal with unwrapping WETH as part of accepting an offer is
// via a custom module. Funds earned from offer acceptance should all be
// routed to this module, which then takes care of unwrapping (of course,
// in the end forwarding the unwrapped funds to the specified recipient).
contract UnwrapWETHModule is BaseModule {
    // --- Fields ---

    IWETH public constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // --- Constructor ---

    constructor(address owner) BaseModule(owner) {}

    // --- Fallback ---

    receive() external payable {}

    // --- Unwrap ---

    function unwrapWETH(address receiver) external nonReentrant {
        uint256 balance = WETH.balanceOf(address(this));
        WETH.withdraw(balance);
        _sendETH(receiver, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ExchangeKind} from "../interfaces/IExchangeKind.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "../interfaces/ILooksRare.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "../interfaces/IWyvernV23.sol";

contract ReservoirV4_0_0 is Ownable, ReentrancyGuard {
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

    address public seaport;

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
    ) external payable onlyOwner {
        bool success;
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = payable(targets[i]).call{value: values[i]}(data[i]);
            require(success, "Unsuccessfull call");
        }
    }

    // Terminology:
    // - "single" -> buy single token
    // - "batch" -> buy multiple tokens (natively, only 0xv4 and Seaport support this)
    // - "multi" -> buy multiple tokens (via the router)

    function singleERC721ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        uint16 feeBps
    ) external payable nonReentrant {
        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            IERC721(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId
            );
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
    ) external payable nonReentrant {
        if (expectedOwner != address(0)) {
            require(
                IERC721(collection).ownerOf(tokenId) == expectedOwner,
                "Unexpected owner"
            );
        }

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            IERC721(collection).safeTransferFrom(
                address(this),
                receiver,
                tokenId
            );
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function batchERC721ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address[] memory collections,
        uint256[] memory tokenIds,
        address receiver,
        uint256 feeBps
    ) external payable nonReentrant {
        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.SEAPORT) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            for (uint256 i = 0; i < collections.length; i++) {
                IERC721(collections[i]).safeTransferFrom(
                    address(this),
                    receiver,
                    tokenIds[i],
                    ""
                );
            }
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
    ) external payable nonReentrant {
        address target;
        address operator;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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
    ) external payable nonReentrant {
        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
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
    ) external payable nonReentrant {
        if (expectedOwner != address(0)) {
            require(
                IERC1155(collection).balanceOf(expectedOwner, tokenId) >=
                    amount,
                "Unexpected owner/balance"
            );
        }

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
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
    ) external payable nonReentrant {
        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.SEAPORT) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            for (uint256 i = 0; i < collections.length; i++) {
                IERC1155(collections[i]).safeTransferFrom(
                    address(this),
                    receiver,
                    tokenIds[i],
                    amounts[i],
                    ""
                );
            }
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
    ) external payable nonReentrant {
        address target;
        address operator;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ExchangeKind} from "../interfaces/IExchangeKind.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "../interfaces/ILooksRare.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "../interfaces/IWyvernV23.sol";

contract ReservoirV3_0_0 is Ownable {
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

    address public seaport;

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
    ) external payable onlyOwner {
        bool success;
        for (uint256 i = 0; i < targets.length; i++) {
            (success, ) = payable(targets[i]).call{value: values[i]}(data[i]);
            require(success, "Unsuccessfull call");
        }
    }

    // Terminology:
    // - "single" -> buy single token
    // - "batch" -> buy multiple tokens (natively, only 0xv4 and Seaport support this)
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            IERC721(collection).transferFrom(address(this), receiver, tokenId);
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(referrer).call{value: fee}("");
            require(success, "Could not send payment");
        }
    }

    function batchERC721ListingFill(
        address referrer,
        bytes memory data,
        ExchangeKind exchangeKind,
        address[] memory collections,
        uint256[] memory tokenIds,
        address receiver,
        uint256 feeBps
    ) external payable {
        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.SEAPORT) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            for (uint256 i = 0; i < collections.length; i++) {
                IERC721(collections[i]).safeTransferFrom(
                    address(this),
                    receiver,
                    tokenIds[i],
                    ""
                );
            }
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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

        if (
            exchangeKind != ExchangeKind.SEAPORT &&
            exchangeKind != ExchangeKind.WYVERN_V23
        ) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
        } else if (exchangeKind == ExchangeKind.ZEROEX_V4) {
            target = zeroExV4;
        } else {
            revert("Unsupported exchange");
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        require(success, "Unsuccessfull fill");

        if (exchangeKind != ExchangeKind.SEAPORT) {
            // When filling anything other than Wyvern or Seaport we need to send
            // the NFT to the taker's wallet after the fill (since we cannot have
            // a recipient recipient than the taker).
            for (uint256 i = 0; i < collections.length; i++) {
                IERC1155(collections[i]).safeTransferFrom(
                    address(this),
                    receiver,
                    tokenIds[i],
                    amounts[i],
                    ""
                );
            }
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
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            operator = seaport;
        } else if (exchangeKind == ExchangeKind.WYVERN_V23) {
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
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ExchangeKind} from "../interfaces/IExchangeKind.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "../interfaces/ILooksRare.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "../interfaces/IWyvernV23.sol";

contract ReservoirV2_0_0 is Ownable {
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
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ExchangeKind} from "../interfaces/IExchangeKind.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ILooksRare, ILooksRareTransferSelectorNFT} from "../interfaces/ILooksRare.sol";
import {IWyvernV23, IWyvernV23ProxyRegistry} from "../interfaces/IWyvernV23.sol";

contract ReservoirV1_0_0 is Ownable {
    address public weth;

    address public looksRare;
    address public looksRareTransferManagerERC721;
    address public looksRareTransferManagerERC1155;

    address public wyvernV23;
    address public wyvernV23Proxy;

    address public zeroExV4;

    constructor(
        address wethAddress,
        address looksRareAddress,
        address wyvernV23Address,
        address zeroExV4Address
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ReservoirErc721 is ERC721, Ownable {
    string private baseTokenURI;

    constructor(string memory _baseTokenURI) ERC721("Reservoir", "RSV") {
        baseTokenURI = _baseTokenURI;
    }

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }

    function updateBaseTokenURI(string memory _baseTokenURI)
        external
        onlyOwner
    {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {ILooksRare} from "../../../interfaces/ILooksRare.sol";

// Notes:
// - supports filling listings (both ERC721/ERC1155 but only ETH-denominated)
// - supports filling offers (both ERC721/ERC1155)

contract LooksRareModule is BaseExchangeModule {
    using SafeERC20 for IERC20;

    // --- Fields ---

    ILooksRare public constant EXCHANGE =
        ILooksRare(0x59728544B08AB483533076417FbBB2fD0B17CE3a);

    address public constant ERC721_TRANSFER_MANAGER =
        0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
    address public constant ERC1155_TRANSFER_MANAGER =
        0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051;

    bytes4 public constant ERC721_INTERFACE = 0x80ac58cd;
    bytes4 public constant ERC1155_INTERFACE = 0xd9b67a26;

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Single ETH listing ---

    function acceptETHListing(
        ILooksRare.TakerOrder calldata takerBid,
        ILooksRare.MakerOrder calldata makerAsk,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buy(
            takerBid,
            makerAsk,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- Multiple ETH listings ---

    function acceptETHListings(
        ILooksRare.TakerOrder[] calldata takerBids,
        ILooksRare.MakerOrder[] calldata makerAsks,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // LooksRare does not support batch filling so we fill orders one by one
        for (uint256 i = 0; i < takerBids.length; ) {
            // Use `memory` to avoid `Stack too deep` errors
            ILooksRare.TakerOrder memory takerBid = takerBids[i];

            // Execute fill
            _buy(
                takerBids[i],
                makerAsks[i],
                params.fillTo,
                params.revertIfIncomplete,
                takerBid.price
            );

            unchecked {
                ++i;
            }
        }
    }

    // --- [ERC721] Single offer ---

    function acceptERC721Offer(
        ILooksRare.TakerOrder calldata takerAsk,
        ILooksRare.MakerOrder calldata makerBid,
        OfferParams calldata params
    ) external nonReentrant {
        IERC721 collection = IERC721(address(makerBid.collection));

        // Approve the transfer manager if needed
        _approveERC721IfNeeded(collection, ERC721_TRANSFER_MANAGER);

        // Execute the fill
        _sell(takerAsk, makerBid, params.fillTo, params.revertIfIncomplete);

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, collection, takerAsk.tokenId);
    }

    // --- [ERC1155] Single offer ---

    function acceptERC1155Offer(
        ILooksRare.TakerOrder calldata takerAsk,
        ILooksRare.MakerOrder calldata makerBid,
        OfferParams calldata params
    ) external nonReentrant {
        IERC1155 collection = IERC1155(address(makerBid.collection));

        // Approve the transfer manager if needed
        _approveERC1155IfNeeded(collection, ERC1155_TRANSFER_MANAGER);

        // Execute the fill
        _sell(takerAsk, makerBid, params.fillTo, params.revertIfIncomplete);

        // Refund any ERC1155 leftover
        _sendAllERC1155(params.refundTo, collection, takerAsk.tokenId);
    }

    // --- ERC721 / ERC1155 hooks ---

    // Single token offer acceptance can be done approval-less by using the
    // standard `safeTransferFrom` method together with specifying data for
    // further contract calls. An example:
    // `safeTransferFrom(
    //      0xWALLET,
    //      0xMODULE,
    //      TOKEN_ID,
    //      0xABI_ENCODED_ROUTER_EXECUTION_CALLDATA_FOR_OFFER_ACCEPTANCE
    // )`

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
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
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC1155Received.selector;
    }

    // --- Internal ---

    function _buy(
        ILooksRare.TakerOrder calldata takerBid,
        ILooksRare.MakerOrder calldata makerAsk,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        // Execute the fill
        try
            EXCHANGE.matchAskWithTakerBidUsingETHAndWETH{value: value}(
                takerBid,
                makerAsk
            )
        {
            IERC165 collection = makerAsk.collection;

            // Forward any token to the specified receiver
            bool isERC721 = collection.supportsInterface(ERC721_INTERFACE);
            if (isERC721) {
                IERC721(address(collection)).safeTransferFrom(
                    address(this),
                    receiver,
                    takerBid.tokenId
                );
            } else {
                bool isERC1155 = collection.supportsInterface(
                    ERC1155_INTERFACE
                );
                if (isERC1155) {
                    IERC1155(address(collection)).safeTransferFrom(
                        address(this),
                        receiver,
                        takerBid.tokenId,
                        makerAsk.amount,
                        ""
                    );
                }
            }
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _sell(
        ILooksRare.TakerOrder calldata takerAsk,
        ILooksRare.MakerOrder calldata makerBid,
        address receiver,
        bool revertIfIncomplete
    ) internal {
        // Execute the fill
        try EXCHANGE.matchBidWithTakerAsk(takerAsk, makerBid) {
            // Forward any payment to the specified receiver
            makerBid.currency.safeTransfer(receiver, takerAsk.price);
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {IX2Y2} from "../../../interfaces/IX2Y2.sol";

// Notes on the X2Y2 module:
// - supports filling listings (only ERC721 and ETH-denominated)

contract X2Y2Module is BaseExchangeModule {
    using SafeERC20 for IERC20;

    // --- Fields ---

    IX2Y2 public constant EXCHANGE =
        IX2Y2(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    address public constant ERC721_DELEGATE =
        0xF849de01B080aDC3A814FaBE1E2087475cF2E354;

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Single ETH listing ---

    function acceptETHListing(
        IX2Y2.RunInput calldata input,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buy(input, params.fillTo, params.revertIfIncomplete, params.amount);
    }

    // --- Multiple ETH listings ---

    function acceptETHListings(
        IX2Y2.RunInput[] calldata inputs,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // X2Y2 does not support batch filling so we fill orders one by one
        uint256 length = inputs.length;
        for (uint256 i = 0; i < length; ) {
            // Execute fill
            _buy(
                inputs[i],
                params.fillTo,
                params.revertIfIncomplete,
                inputs[i].details[0].price
            );

            unchecked {
                ++i;
            }
        }
    }

    // --- ERC721 / ERC1155 hooks ---

    // Single token offer acceptance can be done approval-less by using the
    // standard `safeTransferFrom` method together with specifying data for
    // further contract calls. An example:
    // `safeTransferFrom(
    //      0xWALLET,
    //      0xMODULE,
    //      TOKEN_ID,
    //      0xABI_ENCODED_ROUTER_EXECUTION_CALLDATA_FOR_OFFER_ACCEPTANCE
    // )`

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
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
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC1155Received.selector;
    }

    // --- Internal ---

    function _buy(
        IX2Y2.RunInput calldata input,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        if (input.details.length != 1) {
            revert WrongParams();
        }

        // Extract the order's corresponding token
        IX2Y2.SettleDetail calldata detail = input.details[0];
        IX2Y2.OrderItem calldata orderItem = input
            .orders[detail.orderIdx]
            .items[detail.itemIdx];
        if (detail.op != IX2Y2.Op.COMPLETE_SELL_OFFER) {
            revert WrongParams();
        }
        IX2Y2.Pair[] memory pairs = abi.decode(orderItem.data, (IX2Y2.Pair[]));
        if (pairs.length != 1) {
            revert WrongParams();
        }

        // Execute fill
        try EXCHANGE.run{value: value}(input) {
            IERC721(pairs[0].token).safeTransferFrom(
                address(this),
                receiver,
                pairs[0].tokenId
            );
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {ISeaport} from "../../../interfaces/ISeaport.sol";

// Notes on the Seaport module:
// - supports filling listings (both ERC721/ERC1155)
// - supports filling offers (both ERC721/ERC1155)

contract SeaportModule is BaseExchangeModule {
    // --- Structs ---

    // Helper struct for avoiding "Stack too deep" errors
    struct SeaportFulfillments {
        ISeaport.FulfillmentComponent[][] offer;
        ISeaport.FulfillmentComponent[][] consideration;
    }

    // --- Fields ---

    address public constant EXCHANGE =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Single ETH listing ---

    function acceptETHListing(
        ISeaport.AdvancedOrder calldata order,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                params.amount
            )
            : _fillSingleOrder(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                params.amount
            );
    }

    // --- Single ERC20 listing ---

    function acceptERC20Listing(
        ISeaport.AdvancedOrder calldata order,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, EXCHANGE, params.amount);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                0
            )
            : _fillSingleOrder(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                0
            );
    }

    // --- Multiple ETH listings ---

    function acceptETHListings(
        ISeaport.AdvancedOrder[] calldata orders,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        SeaportFulfillments memory fulfillments,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute the fill
        params.revertIfIncomplete
            ? _fillMultipleOrdersWithRevertIfIncomplete(
                orders,
                new ISeaport.CriteriaResolver[](0),
                fulfillments,
                params.fillTo,
                params.amount
            )
            : _fillMultipleOrders(
                orders,
                new ISeaport.CriteriaResolver[](0),
                fulfillments,
                params.fillTo,
                params.amount
            );
    }

    // --- Multiple ERC20 listings ---

    function acceptERC20Listings(
        ISeaport.AdvancedOrder[] calldata orders,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        SeaportFulfillments memory fulfillments,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, EXCHANGE, params.amount);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillMultipleOrdersWithRevertIfIncomplete(
                orders,
                new ISeaport.CriteriaResolver[](0),
                fulfillments,
                params.fillTo,
                0
            )
            : _fillMultipleOrders(
                orders,
                new ISeaport.CriteriaResolver[](0),
                fulfillments,
                params.fillTo,
                0
            );
    }

    // --- Single ERC721 offer ---

    function acceptERC721Offer(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        OfferParams calldata params
    ) external nonReentrant {
        // Extract the ERC721 token from the consideration items
        ISeaport.ConsiderationItem calldata nftItem = order
            .parameters
            .consideration[0];
        if (
            nftItem.itemType != ISeaport.ItemType.ERC721 &&
            nftItem.itemType != ISeaport.ItemType.ERC721_WITH_CRITERIA
        ) {
            revert WrongParams();
        }
        IERC721 nftToken = IERC721(nftItem.token);

        // Extract the payment token from the offer items
        ISeaport.OfferItem calldata paymentItem = order.parameters.offer[0];
        IERC20 paymentToken = IERC20(paymentItem.token);

        // Approve the exchange if needed
        _approveERC721IfNeeded(nftToken, EXCHANGE);
        _approveERC20IfNeeded(paymentToken, EXCHANGE, type(uint256).max);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                criteriaResolvers,
                address(this),
                0
            )
            : _fillSingleOrder(order, criteriaResolvers, address(this), 0);

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, nftToken, nftItem.identifierOrCriteria);

        // Forward any payment to the specified receiver
        _sendAllERC20(params.fillTo, paymentToken);
    }

    // --- Single ERC1155 offer ---

    function acceptERC1155Offer(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        OfferParams calldata params
    ) external nonReentrant {
        // Extract the ERC1155 token from the consideration items
        ISeaport.ConsiderationItem calldata nftItem = order
            .parameters
            .consideration[0];
        if (
            nftItem.itemType != ISeaport.ItemType.ERC1155 &&
            nftItem.itemType != ISeaport.ItemType.ERC1155_WITH_CRITERIA
        ) {
            revert WrongParams();
        }
        IERC1155 nftToken = IERC1155(nftItem.token);

        // Extract the payment token from the offer items
        ISeaport.OfferItem calldata paymentItem = order.parameters.offer[0];
        IERC20 paymentToken = IERC20(paymentItem.token);

        // Approve the exchange if needed
        _approveERC1155IfNeeded(nftToken, EXCHANGE);
        _approveERC20IfNeeded(paymentToken, EXCHANGE, type(uint256).max);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                criteriaResolvers,
                address(this),
                0
            )
            : _fillSingleOrder(order, criteriaResolvers, address(this), 0);

        // Refund any ERC1155 leftover
        _sendAllERC1155(
            params.refundTo,
            nftToken,
            nftItem.identifierOrCriteria
        );

        // Forward any payment to the specified receiver
        _sendAllERC20(params.fillTo, paymentToken);
    }

    // --- Generic handler (used for Seaport-based approvals) ---

    function matchOrders(
        ISeaport.Order[] calldata orders,
        ISeaport.Fulfillment[] calldata fulfillments
    ) external nonReentrant {
        // We don't perform any kind of input or return value validation,
        // so this function should be used with precaution - the official
        // way to use it is only for Seaport-based approvals
        ISeaport(EXCHANGE).matchOrders(orders, fulfillments);
    }

    // --- ERC721 / ERC1155 hooks ---

    // Single token offer acceptance can be done approval-less by using the
    // standard `safeTransferFrom` method together with specifying data for
    // further contract calls. An example:
    // `safeTransferFrom(
    //      0xWALLET,
    //      0xMODULE,
    //      TOKEN_ID,
    //      0xABI_ENCODED_ROUTER_EXECUTION_CALLDATA_FOR_OFFER_ACCEPTANCE
    // )`

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
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
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC1155Received.selector;
    }

    // --- Internal ---

    // NOTE: In lots of cases, Seaport will not revert if fills were not
    // fully executed. An example of that is partial filling, which will
    // successfully fill any amount that is still available (including a
    // zero amount). One way to ensure that we revert in case of partial
    // executions is to check the order's filled amount before and after
    // we trigger the fill (we can use Seaport's `getOrderStatus` method
    // to check). Since this can be expensive in terms of gas, we have a
    // separate method variant to be called when reverts are enabled.

    function _fillSingleOrder(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        address receiver,
        uint256 value
    ) internal {
        // Execute the fill
        try
            ISeaport(EXCHANGE).fulfillAdvancedOrder{value: value}(
                order,
                criteriaResolvers,
                bytes32(0),
                receiver
            )
        {} catch {}
    }

    function _fillSingleOrderWithRevertIfIncomplete(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        address receiver,
        uint256 value
    ) internal {
        // Cache the order's hash
        bytes32 orderHash = _getOrderHash(order.parameters);

        // Before filling, get the order's filled amount
        uint256 beforeFilledAmount = _getFilledAmount(orderHash);

        // Execute the fill
        bool success;
        try
            ISeaport(EXCHANGE).fulfillAdvancedOrder{value: value}(
                order,
                criteriaResolvers,
                bytes32(0),
                receiver
            )
        returns (bool fulfilled) {
            success = fulfilled;
        } catch {
            revert UnsuccessfulFill();
        }

        if (!success) {
            revert UnsuccessfulFill();
        } else {
            // After successfully filling, get the order's filled amount
            uint256 afterFilledAmount = _getFilledAmount(orderHash);

            // Make sure the amount filled as part of this call is correct
            if (afterFilledAmount - beforeFilledAmount != order.numerator) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _fillMultipleOrders(
        ISeaport.AdvancedOrder[] calldata orders,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        SeaportFulfillments memory fulfillments,
        address receiver,
        uint256 value
    ) internal {
        // Execute the fill
        ISeaport(EXCHANGE).fulfillAvailableAdvancedOrders{value: value}(
            orders,
            criteriaResolvers,
            fulfillments.offer,
            fulfillments.consideration,
            bytes32(0),
            receiver,
            // Assume at most 255 orders can be filled at once
            0xff
        );
    }

    function _fillMultipleOrdersWithRevertIfIncomplete(
        ISeaport.AdvancedOrder[] calldata orders,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        SeaportFulfillments memory fulfillments,
        address receiver,
        uint256 value
    ) internal {
        uint256 length = orders.length;

        bytes32[] memory orderHashes = new bytes32[](length);
        uint256[] memory beforeFilledAmounts = new uint256[](length);
        {
            for (uint256 i = 0; i < length; ) {
                // Cache each order's hashes
                orderHashes[i] = _getOrderHash(orders[i].parameters);
                // Before filling, get each order's filled amount
                beforeFilledAmounts[i] = _getFilledAmount(orderHashes[i]);

                unchecked {
                    ++i;
                }
            }
        }

        // Execute the fill
        (bool[] memory fulfilled, ) = ISeaport(EXCHANGE)
            .fulfillAvailableAdvancedOrders{value: value}(
            orders,
            criteriaResolvers,
            fulfillments.offer,
            fulfillments.consideration,
            bytes32(0),
            receiver,
            // Assume at most 255 orders can be filled at once
            0xff
        );

        for (uint256 i = 0; i < length; ) {
            // After successfully filling, get the order's filled amount
            uint256 afterFilledAmount = _getFilledAmount(orderHashes[i]);

            // Make sure the amount filled as part of this call is correct
            if (
                fulfilled[i] &&
                afterFilledAmount - beforeFilledAmounts[i] !=
                orders[i].numerator
            ) {
                fulfilled[i] = false;
            }

            if (!fulfilled[i]) {
                revert UnsuccessfulFill();
            }

            unchecked {
                ++i;
            }
        }
    }

    function _getOrderHash(
        // Must use `memory` instead of `calldata` for the below cast
        ISeaport.OrderParameters memory orderParameters
    ) internal view returns (bytes32 orderHash) {
        // `OrderParameters` and `OrderComponents` share the exact same
        // fields, apart from the last one, so here we simply treat the
        // `orderParameters` argument as `OrderComponents` and then set
        // the last field to the correct data
        ISeaport.OrderComponents memory orderComponents;
        assembly {
            orderComponents := orderParameters
        }
        orderComponents.counter = ISeaport(EXCHANGE).getCounter(
            orderParameters.offerer
        );

        orderHash = ISeaport(EXCHANGE).getOrderHash(orderComponents);
    }

    function _getFilledAmount(bytes32 orderHash)
        internal
        view
        returns (uint256 totalFilled)
    {
        (, , totalFilled, ) = ISeaport(EXCHANGE).getOrderStatus(orderHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISeaport} from "../interfaces/ISeaport.sol";

// One way to stay approval-less is to use one-time Seaport orders
// that effectively act as gifts. These are prone to front-running
// though. To prevent this, all such approval orders should ensure
// the offerer matches the transaction's sender (eg. `tx.origin`).
// Although relying on `tx.origin` is considered bad practice, the
// validity time of these orders should be in the range of minutes
// so that the risk of reusing them via a malicious contract which
// forwards them is low.
contract SeaportApprovalOrderZone {
    // --- Errors ---

    error Unauthorized();

    // --- Seaport `ZoneInterface` overrides ---

    function isValidOrder(
        bytes32,
        address,
        address offerer,
        bytes32
    ) external view returns (bytes4 validOrderMagicValue) {
        if (offerer != tx.origin) {
            revert Unauthorized();
        }

        validOrderMagicValue = this.isValidOrder.selector;
    }

    function isValidOrderIncludingExtraData(
        bytes32,
        address,
        ISeaport.AdvancedOrder calldata order,
        bytes32[] calldata,
        ISeaport.CriteriaResolver[] calldata
    ) external view returns (bytes4 validOrderMagicValue) {
        if (order.parameters.offerer != tx.origin) {
            revert Unauthorized();
        }

        validOrderMagicValue = this.isValidOrder.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ReservoirErc1155 is ERC1155, Ownable {
    using Strings for uint256;

    constructor(string memory _uri) ERC1155(_uri) {}

    function mint(uint256 tokenId, uint256 amount) external {
        _mint(msg.sender, tokenId, amount, "");
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }

    function updateURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseModule} from "./BaseModule.sol";

// When sniping NFTs, a lot of gas is lost when someone else's fill transaction
// gets included right before. To optimize the amount of gas that is lost, this
// module performs a balance/owner check so that we revert as early as possible
// and spend as few gas as possible.
contract BalanceAssertModule {
    // --- Errors ---

    error AssertFailed();

    // --- [ERC721] Single assert ---

    function assertERC721Owner(
        IERC721 token,
        uint256 tokenId,
        address owner
    ) external view {
        address actualOwner = token.ownerOf(tokenId);
        if (owner != actualOwner) {
            revert AssertFailed();
        }
    }

    // --- [ERC1155] Single assert ---

    function assertERC1155Balance(
        IERC1155 token,
        uint256 tokenId,
        address owner,
        uint256 balance
    ) external view {
        uint256 actualBalance = token.balanceOf(owner, tokenId);
        if (balance < actualBalance) {
            revert AssertFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("https://mock.com") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId, 1, "");
    }

    function mintMany(uint256 tokenId, uint256 amount) external {
        _mint(msg.sender, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MOCK") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV3Router {
    struct ExactOutputSingleParams {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function refundETH() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {IUniswapV3Router} from "../../../interfaces/IUniswapV3Router.sol";

// Notes:
// - supports swapping ETH and ERC20 to any token via a direct path

contract UniswapV3Module is BaseExchangeModule {
    // --- Fields ---

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant SWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Swaps ---

    function ethToExactOutput(
        IUniswapV3Router.ExactOutputSingleParams calldata params,
        address refundTo
    ) external payable refundETHLeftover(refundTo) {
        if (
            address(params.tokenIn) != WETH ||
            msg.value != params.amountInMaximum
        ) {
            revert WrongParams();
        }

        // Execute the swap
        IUniswapV3Router(SWAP_ROUTER).exactOutputSingle{value: msg.value}(
            params
        );

        // Refund any ETH stucked in the router
        IUniswapV3Router(SWAP_ROUTER).refundETH();
    }

    function erc20ToExactOutput(
        IUniswapV3Router.ExactOutputSingleParams calldata params,
        address refundTo
    ) external refundERC20Leftover(refundTo, params.tokenIn) {
        // Approve the router if needed
        _approveERC20IfNeeded(
            params.tokenIn,
            SWAP_ROUTER,
            params.amountInMaximum
        );

        // Execute the swap
        IUniswapV3Router(SWAP_ROUTER).exactOutputSingle(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {IFoundation} from "../../../interfaces/IFoundation.sol";

// Notes:
// - only supports filling "buy now" listings (ERC721 and ETH-denominated)

contract FoundationModule is BaseExchangeModule {
    // --- Structs ---

    struct Listing {
        IERC721 token;
        uint256 tokenId;
        uint256 price;
    }

    // --- Fields ---

    IFoundation public constant EXCHANGE =
        IFoundation(0xcDA72070E455bb31C7690a170224Ce43623d0B6f);

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Single ETH listing ---

    function acceptETHListing(
        Listing calldata listing,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buy(
            listing.token,
            listing.tokenId,
            params.fillTo,
            params.revertIfIncomplete,
            listing.price
        );
    }

    // --- Multiple ETH listings ---

    function acceptETHListings(
        Listing[] calldata listings,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Foundation does not support batch filling so we fill orders one by one
        for (uint256 i = 0; i < listings.length; ) {
            _buy(
                listings[i].token,
                listings[i].tokenId,
                params.fillTo,
                params.revertIfIncomplete,
                listings[i].price
            );

            unchecked {
                ++i;
            }
        }
    }

    // --- Internal ---

    function _buy(
        IERC721 token,
        uint256 tokenId,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        // Execute fill
        try EXCHANGE.buyV2{value: value}(token, tokenId, value, receiver) {
            token.safeTransferFrom(address(this), receiver, tokenId);
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("Mock", "MOCK") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}