// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../../auction/interfaces/IAuctionManager.sol";
import "../../royaltyManager/interfaces/IRoyaltyManager.sol";

/**
 * @notice Instance of MultipleEditions contract (multiple fixed size editions)
 * @author highlight.xyz
 */
contract MultipleEditions is Proxy {
    /**
     * @notice Initialize MultipleEditions instance with first edition, and potentially auction
     * @param implementation_ ERC721Editions implementation
     * @param initializeData Data to initialize instance
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param metadataRendererAddress Contract returning metadata for each edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinters Initial minters to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @param _editionInfo Edition metadata info
     * @ param IEditionsMetadataRenderer.TokenEditionInfo
     * @param editionSize Edition size
     * @param _editionTokenManager Edition's token manager
     * @param editionRoyalty Edition's royalty
     * @param auctionData Data to create auction
     * @ param auctionManagerAddress AuctionManager address. Auction not created if this is the null address
     * @ param auctionId Auction ID
     * @ param auctionCurrency Auction currency
     * @ param auctionPaymentRecipient Auction payment recipient
     * @ param auctionEndTime Auction end time
     */
    constructor(
        address implementation_,
        bytes memory initializeData,
        bytes memory _editionInfo,
        uint256 editionSize,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty,
        bytes memory auctionData
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(implementation_, abi.encodeWithSignature("initialize(bytes)", initializeData));

        if (_editionInfo.length > 0) {
            // create edition
            Address.functionDelegateCall(
                implementation_,
                abi.encodeWithSignature(
                    "createEdition(bytes,uint256,address,(address,uint16))",
                    _editionInfo,
                    editionSize,
                    _editionTokenManager,
                    editionRoyalty
                )
            );
        }

        if (auctionData.length > 0) {
            // if creating auction for this edition, validate that edition size was 1
            require(editionSize == 1, "Invalid edition size for auction");

            (
                address auctionManagerAddress,
                bytes32 auctionId,
                address auctionCurrency,
                address payable auctionPaymentRecipient,
                uint256 auctionEndTime
            ) = abi.decode(auctionData, (address, bytes32, address, address, uint256));

            IAuctionManager.EnglishAuction memory auction = IAuctionManager.EnglishAuction(
                address(this),
                auctionCurrency,
                msg.sender,
                auctionPaymentRecipient,
                auctionEndTime,
                0,
                true,
                IAuctionManager.AuctionState.LIVE_ON_CHAIN
            );

            // edition id guaranteed to be = 0
            IAuctionManager(auctionManagerAddress).createAuctionForNewEdition(auctionId, auction, 0);
        }
    }

    /**
     * @notice Return the contract type
     */
    function contractType() external view returns (string memory) {
        return "MultipleEditions";
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import { IMinimalForwarder } from "./IMinimalForwarder.sol";

/**
 * @title Interface for AuctionManager
 * @notice Defines behaviour encapsulated in AuctionManager
 * @author [email protected]
 */
interface IAuctionManager {
    /**
     * @notice The state an auction is in
     * @param NON_EXISTENT Default state of auction pre-creation
     * @param LIVE_ON_CHAIN State of auction after creation but before the auction ends or is cancelled
     * @param CANCELLED_ON_CHAIN State of auction after auction is cancelled
     * @param FULFILLED State of auction after winning bid has been dispersed and NFT has left escrow
     */
    enum AuctionState {
        NON_EXISTENT,
        LIVE_ON_CHAIN,
        CANCELLED_ON_CHAIN,
        FULFILLED
    }

    /**
     * @notice The data structure containing all fields on an English Auction that need to be on-chain
     * @param collection The collection hosting the auctioned NFT
     * @param currency The currency bids must be made in
     * @param owner The auction owner
     * @param paymentRecipient The recipient account of the winning bid
     * @param endTime When the auction will tentatively end. Is 0 if first bid hasn't been made
     * @param tokenId The ID of the NFT being auctioned
     * @param mintWhenReserveMet If true, new NFT will be minted when reserve crossing bid is made
     * @param state Auction state
     */
    struct EnglishAuction {
        address collection;
        address currency;
        address owner;
        address payable paymentRecipient;
        uint256 endTime;
        uint256 tokenId; // if nft already exists
        bool mintWhenReserveMet;
        AuctionState state;
    }

    /**
     * @notice Used for information about auctions on editions
     * @param used True if the auction is for an auction on an edition
     * @param editionId ID of the edition used for this auction
     */
    struct EditionAuction {
        bool used;
        uint256 editionId;
    }

    /**
     * @notice Data required for a bidder to make a bid. Claims are signed, hashed and validated, acting as bid keys
     * @param auctionId ID of auction
     * @param bidPrice Price that bidder is bidding
     * @param reservePrice Price that bidder must bid greater than. Only relevant for the first bid on an auction
     * @param maxClaimsPerAccount Max bids that an account can make on an auction. Unlimited if 0
     * @param claimExpiryTimestamp Time when claim expires
     * @param buffer Minimum time that must be left in an auction after a bid is made
     * @param minimumIncrementPerBidPctBPS Minimum % that a bid must be higher than the previous highest bid by,
     *                                     in basis points
     * @param claimer Account that can use the claim
     */
    struct Claim {
        bytes32 auctionId;
        uint256 bidPrice;
        uint256 reservePrice;
        uint256 maxClaimsPerAccount;
        uint256 claimExpiryTimestamp;
        uint256 buffer;
        uint256 minimumIncrementPerBidPctBPS;
        address payable claimer;
    }

    /**
     * @notice Structure hosting highest bidder info
     * @param bidder Bidder with current highest bid
     * @param preferredNFTRecipient The account that the current highest bidder wants the NFT to go to if they win.
     *                              Useful for non-transferable NFTs being auctioned.
     * @param amount Amount of current highest bid
     */
    struct HighestBidderData {
        address payable bidder;
        address preferredNFTRecipient;
        uint256 amount;
    }

    /**
     * @notice Emitted when an english auction is created
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param collection Collection that NFT being auctioned is on
     * @param tokenId ID of NFT being auctioned
     * @param currency The currency bids must be made in
     * @param paymentRecipient The recipient account of the winning bid
     * @param endTime Auction end time
     */
    event EnglishAuctionCreated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed collection,
        uint256 tokenId,
        address currency,
        address paymentRecipient,
        uint256 endTime
    );

    /**
     * @notice Emitted when a valid bid is made on an auction
     * @param auctionId ID of auction
     * @param bidder Bidder with new highest bid
     * @param firstBid True if this is the first bid, ie. first bid greater than reserve price
     * @param collection Collection that NFT being auctioned is on
     * @param tokenId ID of NFT being auctioned
     * @param value Value of bid
     * @param timeLengthened True if this bid extended the end time of the auction (by being bid >= endTime - buffer)
     * @param preferredNFTRecipient The account that the current highest bidder wants the NFT to go to if they win.
     *                              Useful for non-transferable NFTs being auctioned.
     * @param endTime The current end time of the auction
     */
    event Bid(
        bytes32 indexed auctionId,
        address indexed bidder,
        bool indexed firstBid,
        address collection,
        uint256 tokenId,
        uint256 value,
        bool timeLengthened,
        address preferredNFTRecipient,
        uint256 endTime
    );

    /**
     * @notice Emitted when an auction's end time is extended
     * @param auctionId ID of auction
     * @param tokenId ID of NFT being auctioned
     * @param collection Collection that NFT being auctioned is on
     * @param buffer Minimum time that must be left in an auction after a bid is made
     * @param newEndTime New end time of auction
     */
    event TimeLengthened(
        bytes32 indexed auctionId,
        uint256 indexed tokenId,
        address indexed collection,
        uint256 buffer,
        uint256 newEndTime
    );

    /**
     * @notice Emitted when an auction is won, and its terms are fulfilled
     * @param auctionId ID of auction
     * @param tokenId ID of NFT being auctioned
     * @param collection Collection that NFT being auctioned is on
     * @param owner Auction owner
     * @param winner Winning bidder
     * @param paymentRecipient The recipient account of the winning bid
     * @param nftRecipient The account receiving the auctioned NFT
     * @param currency The currency bids were made in
     * @param amount Winning bid value
     * @param paymentRecipientPctBPS The percentage of the winning bid going to the paymentRecipient, in basis points
     */
    event AuctionWon(
        bytes32 indexed auctionId,
        uint256 indexed tokenId,
        address indexed collection,
        address owner,
        address winner,
        address paymentRecipient,
        address nftRecipient,
        address currency,
        uint256 amount,
        uint256 paymentRecipientPctBPS
    );

    /**
     * @notice Emitted when an auction is cancelled on-chain (before any valid bids have been made).
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param collection Collection that NFT was being auctioned on
     * @param tokenId ID of NFT that was being auctioned
     */
    event AuctionCanceledOnChain(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed collection,
        uint256 tokenId
    );

    /**
     * @notice Emitted when the payment recipient of an auction is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newPaymentRecipient New payment recipient of auction
     */
    event PaymentRecipientUpdated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed newPaymentRecipient
    );

    /**
     * @notice Emitted when the preferred NFT recipient of an auctionbid  is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newPreferredNFTRecipient New preferred nft recipient of auction
     */
    event PreferredNFTRecipientUpdated(
        bytes32 indexed auctionId,
        address indexed owner,
        address indexed newPreferredNFTRecipient
    );

    /**
     * @notice Emitted when the end time of an auction is updated
     * @param auctionId ID of auction
     * @param owner Auction owner
     * @param newEndTime New end time
     */
    event EndTimeUpdated(bytes32 indexed auctionId, address indexed owner, uint256 indexed newEndTime);

    /**
     * @notice Emitted when the platform is updated
     * @param newPlatform New platform
     */
    event PlatformUpdated(address newPlatform);

    /**
     * @notice Create an auction that mints the NFT being auctioned into escrow (mints the next NFT on the collection)
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForNewToken(bytes32 auctionId, EnglishAuction memory auction) external;

    /**
     * @notice Create an auction that mints an edition being auctioned into escrow (mints the next NFT on the edition)
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForNewEdition(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        uint256 editionId
    ) external;

    /**
     * @notice Create an auction for an existing NFT
     * @param auctionId ID of auction
     * @param auction The auction details
     */
    function createAuctionForExistingToken(bytes32 auctionId, EnglishAuction memory auction) external;

    /**
     * @notice Create an auction for an existing NFT, with atomic transfer approval meta-tx packets
     * @param auctionId ID of auction
     * @param auction The auction details
     * @param req The request containing the call to transfer the auctioned NFT into escrow
     * @param requestSignature The signed request
     */
    function createAuctionForExistingTokenWithMetaTxPacket(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        IMinimalForwarder.ForwardRequest calldata req,
        bytes calldata requestSignature
    ) external;

    /**
     * @notice Update the payment recipient for an auction
     * @param auctionId ID of auction being updated
     * @param newPaymentRecipient New payment recipient on the auction
     */
    function updatePaymentRecipient(bytes32 auctionId, address payable newPaymentRecipient) external;

    /**
     * @notice Update the preferred nft recipient of a bid
     * @param auctionId ID of auction being updated
     * @param newPreferredNFTRecipient New nft recipient on the auction bid
     */
    function updatePreferredNFTRecipient(bytes32 auctionId, address newPreferredNFTRecipient) external;

    /**
     * @notice Makes a bid on an auction
     * @param claim Claim needed to make the bid
     * @param claimSignature Claim signature to be unwrapped and validated
     * @param preferredNftRecipient Bidder's preferred recipient of NFT if they win auction
     */
    function bid(
        IAuctionManager.Claim calldata claim,
        bytes calldata claimSignature,
        address preferredNftRecipient
    ) external payable;

    /**
     * @notice Fulfill auction and disperse winning bid / auctioned NFT.
     * @dev Anyone can call this function
     * @param auctionId ID of auction to fulfill
     */
    function fulfillAuction(bytes32 auctionId) external;

    /**
     * @notice "Cancels" an auction on-chain, if a valid bid hasn't been made yet. Transfers NFT back to auction owner
     * @param auctionId ID of auction being "cancelled"
     */
    function cancelAuctionOnChain(bytes32 auctionId) external;

    /**
     * @notice Updates the platform account receiving a portion of winning bids
     * @param newPlatform New account to receive portion
     */
    function updatePlatform(address payable newPlatform) external;

    /**
     * @notice Updates the platform cut
     * @param newCutBPS New account to receive portion
     */
    function updatePlatformCut(uint256 newCutBPS) external;

    /**
     * @notice Update an auction's end time before first valid bid is made on auction
     * @param auctionId Auction ID
     * @param newEndTime New end time
     */
    function updateEndTime(bytes32 auctionId, uint256 newEndTime) external;

    /**
     * @notice Verifies the validity of a claim, simulating call to bid()
     * @param claim Claim needed to make the bid
     * @param claimSignature Claim signature to be unwrapped and validated
     * @param expectedMsgSender Expected msg.sender when bid() is called, that is being simulated
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata claimSignature,
        address expectedMsgSender
    ) external view returns (bool);

    /**
     * @notice Get all data about an auction except for number of bids made per user
     * @param auctionId ID of auction
     */
    function getFullAuctionData(bytes32 auctionId)
        external
        view
        returns (
            EnglishAuction memory,
            HighestBidderData memory,
            EditionAuction memory
        );

    /**
     * @notice Get all data about a set of auctions except for number of bids made per user
     * @param auctionIds IDs of auctions
     */
    function getFullAuctionsData(bytes32[] calldata auctionIds)
        external
        view
        returns (
            EnglishAuction[] memory,
            HighestBidderData[] memory,
            EditionAuction[] memory
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title IRoyaltyManager
 * @author [email protected]
 * @notice Enables interfacing with custom royalty managers that define conditions on setting royalties for
 *         NFT contracts
 */
interface IRoyaltyManager {
    /**
     * @notice Struct containing values required to adhere to ERC-2981
     * @param recipientAddress Royalty recipient - can be EOA, royalty splitter contract, etc.
     * @param royaltyPercentageBPS Royalty cut, in basis points
     */
    struct Royalty {
        address recipientAddress;
        uint16 royaltyPercentageBPS;
    }

    /**
     * @notice Defines conditions around being able to swap royalty manager for another one
     * @param newRoyaltyManager New royalty manager being swapped in
     * @param sender msg sender
     */
    function canSwap(address newRoyaltyManager, address sender) external view returns (bool);

    /**
     * @notice Defines conditions around being able to remove current royalty manager
     * @param sender msg sender
     */
    function canRemoveItself(address sender) external view returns (bool);

    /**
     * @notice Defines conditions around being able to set granular royalty (per token or per edition)
     * @param id Edition / token ID whose royalty is being set
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetGranularRoyalty(
        uint256 id,
        Royalty calldata royalty,
        address sender
    ) external view returns (bool);

    /**
     * @notice Defines conditions around being able to set default royalty
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetDefaultRoyalty(Royalty calldata royalty, address sender) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

/**
 * @title Minimal forwarder interface
 * @author [email protected]
 */
interface IMinimalForwarder {
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        external
        payable
        returns (bool, bytes memory);

    function getNonce(address from) external view returns (uint256);

    function verify(ForwardRequest calldata req, bytes calldata signature) external view returns (bool);
}