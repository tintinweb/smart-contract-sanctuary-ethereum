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

interface INFTMarketBuyNow {
  function setBuyPrice(address nftContract, uint256 tokenId, uint256 price) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

interface INFTMarketReserveAuction {
  function createReserveAuctionV2(address nftContract, uint256 tokenId, uint256 reservePrice, uint256 exhibitionId)
    external
    returns (uint256 auctionId);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../interfaces/internal/routes/INFTMarketBuyNow.sol";
import "../../interfaces/internal/routes/INFTMarketReserveAuction.sol";

import "./NFTMarketRouterCore.sol";

/**
 * @title Wrap external calls to the NFTMarket contract.
 */
abstract contract NFTMarketRouterAPIs is NFTMarketRouterCore {
  function _createReserveAuctionV2(address nftContract, uint256 tokenId, uint256 reservePrice, uint256 exhibitionId)
    internal
    returns (uint auctionId)
  {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returnData) = nftMarket.call(
      abi.encodeWithSelector(
        INFTMarketReserveAuction.createReserveAuctionV2.selector,
        nftContract,
        tokenId,
        reservePrice,
        exhibitionId,
        msg.sender
      )
    );
    if (!success) {
      _revert(returnData);
    }
    auctionId = abi.decode(returnData, (uint256));
  }

  function _setBuyPrice(address nftContract, uint256 tokenId, uint256 price) internal {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returnData) = nftMarket.call(
      abi.encodeWithSelector(INFTMarketBuyNow.setBuyPrice.selector, nftContract, tokenId, price, msg.sender)
    );
    if (!success) {
      _revert(returnData);
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error NFTMarketRouter_Call_Failed_Without_Revert_Reason();
error NFTMarketRouter_Market_Is_Not_A_Contract();

/**
 * @title Shared logic for NFT Market Router mixins.
 */
abstract contract NFTMarketRouterCore {
  using AddressUpgradeable for address;

  address public immutable nftMarket;

  constructor(address _nftMarket) {
    if (!_nftMarket.isContract()) {
      revert NFTMarketRouter_Market_Is_Not_A_Contract();
    }
    nftMarket = _nftMarket;
  }

  /**
   * @notice Bubbles up the original revert reason where possible.
   * @dev Copied from OZ's `Address.sol` library, with minor modifications.
   */
  function _revert(bytes memory returnData) internal pure {
    // Look for revert reason and bubble it up if present
    if (returnData.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert NFTMarketRouter_Call_Failed_Without_Revert_Reason();
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./NFTMarketRouterAPIs.sol";

error NFTMarketRouterList_Token_Ids_Not_Set();
error NFTMarketRouterList_Must_Set_Reserve_Or_Buy_Price();
error NFTMarketRouterList_Exhibition_Id_Set_Without_Reserve_Price();
error NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();

// solhint-disable-next-line no-empty-blocks
abstract contract NFTMarketRouterList is NFTMarketRouterAPIs {
  /**
   * @notice Batch create reserve auction and or set a buy price for many NFTs and escrow in the market contract.
   * A reserve auction price and or a buy price must be set.
   * @param nftContract The address of the NFT contract.
   * @param tokenIds The ids of the NFTs in the batch.
   * @param exhibitionId The id of the exhibition the auctions are listed with.
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
  /* solhint-disable-next-line code-complexity */
  function batchCreateAuctionAndSetBuyPrice(
    address nftContract,
    uint256[] calldata tokenIds,
    uint256 exhibitionId,
    uint256 reservePrice,
    bool shouldSetBuyPrice,
    uint256 buyPrice
  ) external returns (uint256 firstAuctionIdOfSequence) {
    if (tokenIds.length == 0) {
      revert NFTMarketRouterList_Token_Ids_Not_Set();
    }
    if (!shouldSetBuyPrice && buyPrice > 0) {
      revert NFTMarketRouterList_Buy_Price_Set_But_Should_Set_Buy_Price_Is_False();
    }
    if (reservePrice > 0) {
      firstAuctionIdOfSequence = _createReserveAuctionV2(nftContract, tokenIds[0], reservePrice, exhibitionId);
      if (shouldSetBuyPrice) {
        _setBuyPrice(nftContract, tokenIds[0], buyPrice);
        for (uint256 i = 1; i < tokenIds.length; ) {
          _createReserveAuctionV2(nftContract, tokenIds[i], reservePrice, exhibitionId);
          _setBuyPrice(nftContract, tokenIds[i], buyPrice);
          unchecked {
            ++i;
          }
        }
      } else {
        for (uint256 i = 1; i < tokenIds.length; ) {
          _createReserveAuctionV2(nftContract, tokenIds[i], reservePrice, exhibitionId);
          unchecked {
            ++i;
          }
        }
      }
    } else {
      if (exhibitionId > 0) {
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

import "./mixins/nftMarketRouter/NFTMarketRouterCore.sol";
import "./mixins/nftMarketRouter/NFTMarketRouterAPIs.sol";
import "./mixins/nftMarketRouter/NFTMarketRouterList.sol";

contract NFTMarketRouter is NFTMarketRouterCore, NFTMarketRouterAPIs, NFTMarketRouterList {
  constructor(address _nftMarket)
    NFTMarketRouterCore(_nftMarket) // solhint-disable-next-line no-empty-blocks
  {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/internal/routes/INFTMarketBuyNow.sol";

abstract contract $INFTMarketBuyNow is INFTMarketBuyNow {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../../contracts/interfaces/internal/routes/INFTMarketReserveAuction.sol";

abstract contract $INFTMarketReserveAuction is INFTMarketReserveAuction {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarketRouter/NFTMarketRouterAPIs.sol";

contract $NFTMarketRouterAPIs is NFTMarketRouterAPIs {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_createReserveAuctionV2(uint256 auctionId);

    constructor(address _nftMarket) NFTMarketRouterCore(_nftMarket) {}

    function $_createReserveAuctionV2(address nftContract,uint256 tokenId,uint256 reservePrice,uint256 exhibitionId) external returns (uint256 auctionId) {
        (auctionId) = super._createReserveAuctionV2(nftContract,tokenId,reservePrice,exhibitionId);
        emit return$_createReserveAuctionV2(auctionId);
    }

    function $_setBuyPrice(address nftContract,uint256 tokenId,uint256 price) external {
        super._setBuyPrice(nftContract,tokenId,price);
    }

    function $_revert(bytes calldata returnData) external pure {
        super._revert(returnData);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarketRouter/NFTMarketRouterCore.sol";

contract $NFTMarketRouterCore is NFTMarketRouterCore {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _nftMarket) NFTMarketRouterCore(_nftMarket) {}

    function $_revert(bytes calldata returnData) external pure {
        super._revert(returnData);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/mixins/nftMarketRouter/NFTMarketRouterList.sol";

contract $NFTMarketRouterList is NFTMarketRouterList {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_createReserveAuctionV2(uint256 auctionId);

    constructor(address _nftMarket) NFTMarketRouterCore(_nftMarket) {}

    function $_createReserveAuctionV2(address nftContract,uint256 tokenId,uint256 reservePrice,uint256 exhibitionId) external returns (uint256 auctionId) {
        (auctionId) = super._createReserveAuctionV2(nftContract,tokenId,reservePrice,exhibitionId);
        emit return$_createReserveAuctionV2(auctionId);
    }

    function $_setBuyPrice(address nftContract,uint256 tokenId,uint256 price) external {
        super._setBuyPrice(nftContract,tokenId,price);
    }

    function $_revert(bytes calldata returnData) external pure {
        super._revert(returnData);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/NFTMarketRouter.sol";

contract $NFTMarketRouter is NFTMarketRouter {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event return$_createReserveAuctionV2(uint256 auctionId);

    constructor(address _nftMarket) NFTMarketRouter(_nftMarket) {}

    function $_createReserveAuctionV2(address nftContract,uint256 tokenId,uint256 reservePrice,uint256 exhibitionId) external returns (uint256 auctionId) {
        (auctionId) = super._createReserveAuctionV2(nftContract,tokenId,reservePrice,exhibitionId);
        emit return$_createReserveAuctionV2(auctionId);
    }

    function $_setBuyPrice(address nftContract,uint256 tokenId,uint256 price) external {
        super._setBuyPrice(nftContract,tokenId,price);
    }

    function $_revert(bytes calldata returnData) external pure {
        super._revert(returnData);
    }

    receive() external payable {}
}