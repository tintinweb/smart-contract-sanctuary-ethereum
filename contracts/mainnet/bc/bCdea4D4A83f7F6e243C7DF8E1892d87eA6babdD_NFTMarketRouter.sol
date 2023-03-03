// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

import "../../../libraries/AddressLibrary.sol";

/**
 * @title Interface for routing calls to the NFT Collection Factory to create timed edition collections.
 * @author HardlyDifficult
 */
interface INFTCollectionFactoryTimedEditions {
  function createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection);

  function createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Drop Market to create fixed price sales.
 * @author HardlyDifficult & reggieag
 */
interface INFTDropMarketFixedPriceSale {
  function createFixedPriceSaleV3(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Market to set buy now prices.
 * @author HardlyDifficult
 */
interface INFTMarketBuyNow {
  function setBuyPrice(address nftContract, uint256 tokenId, uint256 price) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Market to create reserve auctions.
 * @author HardlyDifficult
 */
interface INFTMarketReserveAuction {
  function createReserveAuctionV2(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice,
    uint256 exhibitionId
  ) external returns (uint256 auctionId);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

struct CallWithoutValue {
  address target;
  bytes callData;
}

error AddressLibrary_Proxy_Call_Did_Not_Return_A_Contract(address addressReturned);

/**
 * @title A library for address helpers not already covered by the OZ library.
 * @author batu-inal & HardlyDifficult
 */
library AddressLibrary {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Calls an external contract with arbitrary data and parse the return value into an address.
   * @param externalContract The address of the contract to call.
   * @param callData The data to send to the contract.
   * @return contractAddress The address of the contract returned by the call.
   */
  function callAndReturnContractAddress(
    address externalContract,
    bytes calldata callData
  ) internal returns (address payable contractAddress) {
    bytes memory returnData = externalContract.functionCall(callData);
    contractAddress = abi.decode(returnData, (address));
    if (!contractAddress.isContract()) {
      revert AddressLibrary_Proxy_Call_Did_Not_Return_A_Contract(contractAddress);
    }
  }

  function callAndReturnContractAddress(
    CallWithoutValue calldata call
  ) internal returns (address payable contractAddress) {
    contractAddress = callAndReturnContractAddress(call.target, call.callData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library TimeLibrary {
  /**
   * @notice Checks if the given timestamp is in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different than `hasBeenReached` in that it will return false if the expiry is now.
   */
  function hasExpired(uint256 expiry) internal view returns (bool) {
    return expiry < block.timestamp;
  }

  /**
   * @notice Checks if the given timestamp is now or in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different from `hasExpired` in that it will return true if the timestamp is now.
   */
  function hasBeenReached(uint256 timestamp) internal view returns (bool) {
    return timestamp <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTCollectionFactoryTimedEditions.sol";
import "../../../libraries/AddressLibrary.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTCollectionFactory contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult & reggieag
 */
abstract contract NFTCollectionFactoryRouterAPIs is NFTMarketRouterCore {
  function _createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) internal returns (address collection) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftCollectionFactory,
      abi.encodeWithSelector(
        INFTCollectionFactoryTimedEditions.createNFTTimedEditionCollection.selector,
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        nonce
      )
    );
    collection = abi.decode(returnData, (address));
  }

  function _createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) internal returns (address collection) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftCollectionFactory,
      abi.encodeWithSelector(
        INFTCollectionFactoryTimedEditions.createNFTTimedEditionCollectionWithPaymentFactory.selector,
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        nonce,
        paymentAddressFactoryCall
      )
    );
    collection = abi.decode(returnData, (address));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTDropMarketFixedPriceSale.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTDropMarket contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult & reggieag
 */
abstract contract NFTDropMarketRouterAPIs is NFTMarketRouterCore {
  function _createFixedPriceSaleV3(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) internal {
    _routeCallFromMsgSender(
      nftDropMarket,
      abi.encodeWithSelector(
        INFTDropMarketFixedPriceSale.createFixedPriceSaleV3.selector,
        nftContract,
        exhibitionId,
        price,
        limitPerAccount,
        generalAvailabilityStartTime,
        txDeadlineTime
      )
    );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTMarketBuyNow.sol";
import "../../../interfaces/internal/routes/INFTMarketReserveAuction.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTMarket contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult
 */
abstract contract NFTMarketRouterAPIs is NFTMarketRouterCore {
  function _createReserveAuctionV2(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice,
    uint256 exhibitionId
  ) internal returns (uint auctionId) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftMarket,
      abi.encodeWithSelector(
        INFTMarketReserveAuction.createReserveAuctionV2.selector,
        nftContract,
        tokenId,
        reservePrice,
        exhibitionId
      )
    );
    auctionId = abi.decode(returnData, (uint256));
  }

  function _setBuyPrice(address nftContract, uint256 tokenId, uint256 price) internal {
    _routeCallFromMsgSender(
      nftMarket,
      abi.encodeWithSelector(INFTMarketBuyNow.setBuyPrice.selector, nftContract, tokenId, price)
    );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../libraries/AddressLibrary.sol";
import "../shared/TxDeadline.sol";

import "./apis/NFTCollectionFactoryRouterAPIs.sol";
import "./apis/NFTDropMarketRouterAPIs.sol";

/// @notice Parameters used to create a timed edition collection.
struct TimedEditionCollectionCreationParams {
  /// @notice The collection's `name`.
  string name;
  /// @notice The collection's `symbol`.
  string symbol;
  /// @notice The token URI for the collection.
  string tokenURI;
  /// @notice The nonce used by the creator to create this collection.
  uint96 nonce;
}

/// @notice Parameters used to create a fixed price sale.
struct FixedPriceSaleParams {
  /// @notice The exhibition to associate this fix priced sale to.
  /// Set this to 0 to exist outside of an exhibition.
  uint256 exhibitionId;
  /// @notice The fixed price per NFT in the collection.
  uint256 price;
  /// @notice The max number of NFTs an account may mint in this sale.
  uint256 limitPerAccount;
  /// @notice The start time of the general availability period, in seconds since the Unix epoch.
  /// @dev When set to 0, general availability is set to the block timestamp the transaction is mined.
  uint256 generalAvailabilityStartTime;
}

/**
 * @title Offers value-added functions for creating edition collections using the NFTCollectionFactory contract
 * and creating sales using the NFTDropMarket contract.
 * An example of a value-added function is the ability to create a collection and sale in a single transaction.
 * @author reggieag & HardlyDifficult
 */
abstract contract NFTCreateAndListTimedEditionCollection is
  TxDeadline,
  NFTCollectionFactoryRouterAPIs,
  NFTDropMarketRouterAPIs
{
  /**
   * @notice How long the minting period is open, after the general availability start time.
   */
  uint256 private constant MINT_END_TIME_DURATION = 1 days;

  /**
   * @notice Create a new edition collection contract and timed sale.
   * The sale will last for 24 hours starting at `fixedPriceSaleParams.generalAvailabilityStartTime`.
   * @param collectionParams The parameters for the edition collection creation.
   * @param fixedPriceSaleParams  The parameters for the sale creation.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * @return collection The address of the newly created collection contract.
   * @dev The collection will include the `nftDropMarket` as an approved minter.
   */
  function createTimedEditionCollectionAndFixedPriceSale(
    TimedEditionCollectionCreationParams calldata collectionParams,
    FixedPriceSaleParams calldata fixedPriceSaleParams,
    uint256 txDeadlineTime
  ) external txDeadlineNotExpired(txDeadlineTime) returns (address collection) {
    uint256 generalAvailabilityStartTime = fixedPriceSaleParams.generalAvailabilityStartTime;
    if (generalAvailabilityStartTime == 0) {
      generalAvailabilityStartTime = block.timestamp;
    }
    collection = _createNFTTimedEditionCollection({
      name: collectionParams.name,
      symbol: collectionParams.symbol,
      tokenURI: collectionParams.tokenURI,
      mintEndTime: generalAvailabilityStartTime + MINT_END_TIME_DURATION,
      approvedMinter: nftDropMarket,
      nonce: collectionParams.nonce
    });
    _createFixedPriceSaleV3({
      nftContract: collection,
      exhibitionId: fixedPriceSaleParams.exhibitionId,
      price: fixedPriceSaleParams.price,
      limitPerAccount: fixedPriceSaleParams.limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      // The deadline provided has already been validated above.
      txDeadlineTime: 0
    });
  }

  /**
   * @notice Create a new edition collection contract and timed sale with a payment factory.
   * The sale will last for 24 hours starting at `fixedPriceSaleParams.generalAvailabilityStartTime`.
   * @param collectionParams The parameters for the edition collection creation.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @param fixedPriceSaleParams  The parameters for the sale creation.
   * @param txDeadlineTime The deadline timestamp for the transaction to be mined, in seconds since Unix epoch.
   * @return collection The address of the newly created collection contract.
   * @dev The collection will include the `nftDropMarket` as an approved minter.
   */
  function createTimedEditionCollectionAndFixedPriceSaleWithPaymentFactory(
    TimedEditionCollectionCreationParams calldata collectionParams,
    CallWithoutValue calldata paymentAddressFactoryCall,
    FixedPriceSaleParams calldata fixedPriceSaleParams,
    uint256 txDeadlineTime
  ) external txDeadlineNotExpired(txDeadlineTime) returns (address collection) {
    uint256 generalAvailabilityStartTime = fixedPriceSaleParams.generalAvailabilityStartTime;
    if (generalAvailabilityStartTime == 0) {
      generalAvailabilityStartTime = block.timestamp;
    }
    collection = _createNFTTimedEditionCollectionWithPaymentFactory({
      name: collectionParams.name,
      symbol: collectionParams.symbol,
      tokenURI: collectionParams.tokenURI,
      mintEndTime: generalAvailabilityStartTime + MINT_END_TIME_DURATION,
      approvedMinter: nftDropMarket,
      nonce: collectionParams.nonce,
      paymentAddressFactoryCall: paymentAddressFactoryCall
    });
    _createFixedPriceSaleV3({
      nftContract: collection,
      exhibitionId: fixedPriceSaleParams.exhibitionId,
      price: fixedPriceSaleParams.price,
      limitPerAccount: fixedPriceSaleParams.limitPerAccount,
      generalAvailabilityStartTime: generalAvailabilityStartTime,
      // The deadline provided has already been validated above.
      txDeadlineTime: 0
    });
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error NFTMarketRouterCore_Call_Failed_Without_Revert_Reason();
error NFTMarketRouterCore_NFT_Collection_Factory_Is_Not_A_Contract();
error NFTMarketRouterCore_NFT_Drop_Market_Is_Not_A_Contract();
error NFTMarketRouterCore_NFT_Market_Is_Not_A_Contract();

/**
 * @title Shared logic for NFT Market Router mixins.
 * @author HardlyDifficult
 */
abstract contract NFTMarketRouterCore {
  using AddressUpgradeable for address;

  /**
   * @notice The address of the NFTMarket contract to which requests will be routed.
   */
  address internal immutable nftMarket;

  /**
   * @notice The address of the NFTDropMarket contract to which requests will be routed.
   */
  address internal immutable nftDropMarket;

  /**
   * @notice The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  address internal immutable nftCollectionFactory;

  /**
   * @notice Initialize the template's immutable variables.
   * @param _nftMarket The address of the NFTMarket contract to which requests will be routed.
   * @param _nftDropMarket The address of the NFTDropMarket contract to which requests will be routed.
   * @param _nftCollectionFactory The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  constructor(address _nftMarket, address _nftDropMarket, address _nftCollectionFactory) {
    if (!_nftCollectionFactory.isContract()) {
      revert NFTMarketRouterCore_NFT_Collection_Factory_Is_Not_A_Contract();
    }
    if (!_nftMarket.isContract()) {
      revert NFTMarketRouterCore_NFT_Market_Is_Not_A_Contract();
    }
    if (!_nftDropMarket.isContract()) {
      revert NFTMarketRouterCore_NFT_Drop_Market_Is_Not_A_Contract();
    }
    nftCollectionFactory = _nftCollectionFactory;
    nftDropMarket = _nftDropMarket;
    nftMarket = _nftMarket;
  }

  /**
   * @notice The address of the NFTMarket contract to which requests will be routed.
   * @return market The address of the NFTMarket contract.
   */
  function getNftMarketAddress() external view returns (address market) {
    market = nftMarket;
  }

  /**
   * @notice The address of the NFTDropMarket contract to which requests will be routed.
   * @return market The address of the NFTDropMarket contract.
   */
  function getNfDropMarketAddress() external view returns (address market) {
    market = nftDropMarket;
  }

  /**
   * @notice The address of the NFTCollectionFactory contract to which requests will be routed.
   * @return collectionFactory The address of the NFTCollectionFactory contract.
   */
  function getNftCollectionFactory() external view returns (address collectionFactory) {
    collectionFactory = nftCollectionFactory;
  }

  /**
   * @notice Routes a call to the specified contract, appending the msg.sender to the end of the calldata.
   * If the call reverts, this will revert the transaction and the original reason is bubbled up.
   * @param to The contract address to call.
   * @param callData The call data to use when calling the contract, without the msg.sender.
   */
  function _routeCallFromMsgSender(address to, bytes memory callData) internal returns (bytes memory returnData) {
    // Forward the call, with the packed msg.sender appended, to the specified contract.
    bool success;
    // solhint-disable-next-line avoid-low-level-calls
    (success, returnData) = to.call(abi.encodePacked(callData, msg.sender));

    // If the call failed, bubble up the revert reason.
    if (!success) {
      _revert(returnData);
    }
  }

  /**
   * @notice Bubbles up the original revert reason of a low-level call failure where possible.
   * @dev Copied from OZ's `Address.sol` library, with a minor modification to the final revert scenario.
   * This should only be used when a low-level call fails.
   */
  function _revert(bytes memory returnData) private pure {
    // Look for revert reason and bubble it up if present
    if (returnData.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert NFTMarketRouterCore_Call_Failed_Without_Revert_Reason();
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./apis/NFTMarketRouterAPIs.sol";

error NFTMarketRouterList_Token_Ids_Not_Set();
error NFTMarketRouterList_Must_Set_Reserve_Or_Buy_Price();
error NFTMarketRouterList_Exhibition_Id_Set_Without_Reserve_Price();
error NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();

/**
 * @title Offers value-added functions for listing NFTs in the NFTMarket contract.
 * @author batu-inal & HardlyDifficult & reggieag
 */
abstract contract NFTMarketRouterList is NFTMarketRouterAPIs {
  /**
   * @notice Batch create reserve auction and/or set a buy price for many NFTs and escrow in the market contract.
   * A reserve auction price and/or a buy price must be set.
   * @param nftContract The address of the NFT contract.
   * @param tokenIds The ids of NFTs from the collection to set prices for.
   * @param exhibitionId The id of the exhibition the auctions are to be listed with.
   * Set this to 0 if n/a. Only applies to creating auctions.
   * @param reservePrice The initial reserve price for the auctions created.
   * Set the reservePrice to 0 to skip creating auctions.
   * @param shouldSetBuyPrice True if buy prices should be set for these NFTs.
   * Set this to false to skip setting buy prices. 0 is a valid buy price enabling a giveaway.
   * @param buyPrice The price at which someone could buy these NFTs.
   * @return firstAuctionIdOfSequence 0 if reservePrice is 0, otherwise this is the id of the first auction listed.
   * The other auctions in the batch are listed sequentially from `first id` to `first id + count`.
   * @dev Notes:
   *   a) Approval should be granted for the NFTMarket contract before using this function.
   *   b) If any NFT is already listed for auction then the entire batch call will revert.
   */
  function batchListFromCollection(
    address nftContract,
    uint256[] calldata tokenIds,
    uint256 exhibitionId,
    uint256 reservePrice,
    bool shouldSetBuyPrice,
    uint256 buyPrice
  ) external returns (uint256 firstAuctionIdOfSequence) {
    // Validate input.
    if (tokenIds.length == 0) {
      revert NFTMarketRouterList_Token_Ids_Not_Set();
    }
    if (!shouldSetBuyPrice && buyPrice != 0) {
      revert NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();
    }

    // List NFTs for sale.
    if (reservePrice != 0) {
      // Create auctions.

      // Process the first NFT in order to capture that auction ID as the return value.
      firstAuctionIdOfSequence = _createReserveAuctionV2(nftContract, tokenIds[0], reservePrice, exhibitionId);
      if (shouldSetBuyPrice) {
        // And set buy prices.
        _setBuyPrice(nftContract, tokenIds[0], buyPrice);
      }

      for (uint256 i = 1; i < tokenIds.length; ) {
        _createReserveAuctionV2(nftContract, tokenIds[i], reservePrice, exhibitionId);
        if (shouldSetBuyPrice) {
          _setBuyPrice(nftContract, tokenIds[i], buyPrice);
        }
        unchecked {
          ++i;
        }
      }
    } else {
      // Set buy prices only (no auctions).

      if (exhibitionId != 0) {
        // Exhibitions are only for auctions ATM.
        revert NFTMarketRouterList_Exhibition_Id_Set_Without_Reserve_Price();
      }
      if (!shouldSetBuyPrice) {
        revert NFTMarketRouterList_Must_Set_Reserve_Or_Buy_Price();
      }

      for (uint256 i = 0; i < tokenIds.length; ) {
        _setBuyPrice(nftContract, tokenIds[i], buyPrice);
        unchecked {
          ++i;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../libraries/TimeLibrary.sol";

error TxDeadline_Tx_Deadline_Expired();

/**
 * @title A mixin that provides a modifier to check that a transaction deadline has not expired.
 * @author HardlyDifficult
 */
abstract contract TxDeadline {
  using TimeLibrary for uint256;

  /// @notice Requires the deadline provided is 0, now, or in the future.
  modifier txDeadlineNotExpired(uint256 txDeadlineTime) {
    // No transaction deadline when set to 0.
    if (txDeadlineTime != 0 && txDeadlineTime.hasExpired()) {
      revert TxDeadline_Tx_Deadline_Expired();
    }
    _;
  }

  // This mixin does not use any storage.
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./mixins/shared/TxDeadline.sol";

import "./mixins/nftMarketRouter/NFTMarketRouterCore.sol";
import "./mixins/nftMarketRouter/NFTMarketRouterList.sol";
import "./mixins/nftMarketRouter/NFTCreateAndListTimedEditionCollection.sol";

import "./mixins/nftMarketRouter/apis/NFTMarketRouterAPIs.sol";
import "./mixins/nftMarketRouter/apis/NFTDropMarketRouterAPIs.sol";
import "./mixins/nftMarketRouter/apis/NFTCollectionFactoryRouterAPIs.sol";

/**
 * @title A contract which offers value-added APIs and routes requests to the NFTMarket's existing API.
 * @dev Features in this contract can be created with a clear separation of concerns from the NFTMarket contract.
 * It also provides the contract size space required for targeted APIs and to experiment with new features.
 * @author batu-inal & HardlyDifficult & reggieag
 */
contract NFTMarketRouter is
  TxDeadline,
  NFTMarketRouterCore,
  NFTMarketRouterAPIs,
  NFTCollectionFactoryRouterAPIs,
  NFTDropMarketRouterAPIs,
  NFTMarketRouterList,
  NFTCreateAndListTimedEditionCollection
{
  /**
   * @notice Initialize the template's immutable variables.
   * @param _nftMarket The address of the NFTMarket contract to which requests will be routed.
   * @param _nftDropMarket The address of the NFTDropMarket contract to which requests will be routed.
   * @param _nftCollectionFactory The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  constructor(
    address _nftMarket,
    address _nftDropMarket,
    address _nftCollectionFactory
  ) NFTMarketRouterCore(_nftMarket, _nftDropMarket, _nftCollectionFactory) {}
}