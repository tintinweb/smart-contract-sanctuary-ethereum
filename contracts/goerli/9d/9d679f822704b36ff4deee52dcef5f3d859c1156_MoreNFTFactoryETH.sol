// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./IMintableCollection.sol";
import "./IMoreNFTRoyaltiesManager.sol";

//TODO: Maximum auction duration

contract MoreNFTFactoryETH is AccessControlUpgradeable {

    bytes32 public constant FACTORY_ADMIN = keccak256("FACTORY_ADMIN");
    bytes32 public constant SALES_MANAGER_ROLE = keccak256("SALES_MANAGER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    uint256 public constant PERCENTAGE_DIVIDER = 10000;

    IMoreNFTRoyaltiesManager public royaltiesManager;

    uint256 public collectedFees;
    mapping(address => uint256) public failedRefunds;

    AggregatorV3Interface internal ethToUSDPriceFeed;

    struct CollectionSale {
        address collection;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 basePrice; // in USD with 8 decimals
        mapping(uint256 => uint256) bids;
        mapping(uint256 => address) bidders;
        mapping(uint256 => uint64) endOffsets;
        mapping(uint256 => bool) finalized;
        uint64 startBlock;
        uint64 endBlock; // endBlock == 0 && startBlock > 0 means sale with no end
        uint64 maxOffset;
        uint32 fee;
        bool isAuction;
        bool toMint;
        uint256[5] __slackForFutureUsage;
    }

    mapping(bytes32 => CollectionSale) public collectionSales;
    mapping(address => uint256[2][]) public collectionSalesLookup;

    uint256 public minimumRebid; // in PERCENTAGE_DIVIDER
    uint256 public minimumRebidBlocks;

    uint256[42] private __slackForFutureUsage;

    function version() external pure returns (uint8, uint8, uint8) {
        return (0,8,1);
    }

    function initialize(uint256 _rebid, uint256 _rebidTime, address _royaltiesManager) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        minimumRebid = _rebid; //in percentage
        minimumRebidBlocks = _rebidTime; //in blocks
        royaltiesManager = IMoreNFTRoyaltiesManager(_royaltiesManager);
    }

    function newCollectionSale(
        address collection,
        uint64 startBlock,
        uint64 endBlock,
        uint256 startTokenId,
        uint256 endTokenId,
        uint256 basePrice,
        uint32 fee,
        bool isAuction,
        bool toMint
    ) external onlyRole(SALES_MANAGER_ROLE) {
        require(startBlock > block.number);
        if (isAuction) {
            require(endBlock >= startBlock + minimumRebidBlocks, "Auction with duration smaller than rebid blocks");
        }
        if (toMint) {
            require(IERC165(collection).supportsInterface(type(IMintableCollection).interfaceId), "toMint on sale requires IMintableInterface");
        }
        require(fee <= PERCENTAGE_DIVIDER, "Fee can't exceed 100%");
        CollectionSale storage sale = collectionSales[computeSaleId(collection, startTokenId, endTokenId)];
        _checkAndSetCollectionSaleId(collection, startTokenId, endTokenId);
        sale.collection = collection;
        sale.startBlock = startBlock;
        sale.endBlock = endBlock;
        sale.basePrice = basePrice;
        sale.startTokenId = startTokenId;
        sale.endTokenId = endTokenId;
        sale.fee = fee;
        sale.toMint = toMint;
        sale.isAuction = isAuction;
        emit Sale(collection, startTokenId, endTokenId);
    }

    function bid(bytes32 saleId, uint256 tokenId) external payable {
        CollectionSale storage sale = collectionSales[saleId];
        require(sale.isAuction, "Bid can be done on auction sales only");
        require(tokenId >= sale.startTokenId && tokenId <= sale.endTokenId, "Invalid tokenId");
        uint256 endBlock = sale.endBlock + sale.endOffsets[tokenId];
        require(sale.startBlock <= block.number && endBlock >= block.number, "Auction is not active");
        require(sale.bidders[tokenId] != _msgSender(), "Bidder is already the leading one");
        require(price(saleId, tokenId) <= msg.value, "Too low bid");
        
        if (sale.bidders[tokenId] != address(0)) {
            address toRefund = sale.bidders[tokenId];
            uint256 toRefundAmount = sale.bids[tokenId];
            sale.bidders[tokenId] = _msgSender();
            sale.bids[tokenId] = msg.value;
            _refund(toRefund, toRefundAmount);
        } else {
            sale.bidders[tokenId] = _msgSender();
            sale.bids[tokenId] = msg.value;
        }

        //Update auction duration if under minimum
        if (endBlock - block.number < minimumRebidBlocks) {
            sale.endOffsets[tokenId] += uint64(minimumRebidBlocks + block.number - endBlock);
            if (sale.maxOffset < sale.endOffsets[tokenId]) {
                sale.maxOffset = sale.endOffsets[tokenId];
            }
        }
        emit Bid(sale.collection, tokenId, _msgSender(), msg.value);
    }

    function buy(bytes32 saleId, uint256 tokenId) external payable {
        CollectionSale storage sale = collectionSales[saleId];
        require(sale.startBlock > 0 && sale.startBlock <= block.number, "Sale not open");
        require(!sale.finalized[tokenId], "Element already sold");
        require(!sale.isAuction, "Sale is an auction");
        require(sale.endBlock == 0 || block.number <= sale.endBlock, "Sale ended");
        require(tokenId >= sale.startTokenId && tokenId <= sale.endTokenId, "Invalid tokenId");
        uint256 currentPrice = price(saleId, tokenId);
        require(msg.value >= currentPrice, "Price is higher than ETH sent");
        sale.finalized[tokenId] = true;
        if (msg.value - currentPrice > 0) {
            payable(_msgSender()).transfer(msg.value - currentPrice);
        }
        _payFeeAndRoyalties(saleId, tokenId, currentPrice);
        require(_transferNft(saleId, tokenId, _msgSender()), "NFT transfer failed");
        emit Bought(sale.collection, tokenId, _msgSender());
    }

    function price(bytes32 saleId, uint256 tokenId) public view returns(uint256) {
        CollectionSale storage sale = collectionSales[saleId];
        uint256 _currentBid = sale.bids[tokenId];
        if (_currentBid == 0) {
            return usd2Eth(sale.basePrice);
        }
        return _currentBid+_currentBid*minimumRebid/PERCENTAGE_DIVIDER;
    }

    function priceUSD(bytes32 saleId, uint256 tokenId) external view returns(uint256) {
        CollectionSale storage sale = collectionSales[saleId];
        uint256 _currentBid = sale.bids[tokenId];
        if (_currentBid == 0) {
            return sale.basePrice;
        }
        return eth2Usd(_currentBid+_currentBid*minimumRebid/PERCENTAGE_DIVIDER);
    }

    function currentBidder(bytes32 saleId, uint256 tokenId) external view returns(address) {
        return collectionSales[saleId].bidders[tokenId];
    }

    function currentBid(bytes32 saleId, uint256 tokenId) external view returns(uint256) {
        return collectionSales[saleId].bids[tokenId];
    }

    function saleStart(bytes32 saleId) external view returns(uint256) {
        return collectionSales[saleId].startBlock;
    }

    function saleEnd(bytes32 saleId, uint256 tokenId) external view returns(uint256) {
        return collectionSales[saleId].endBlock + collectionSales[saleId].endOffsets[tokenId];
    }

    function finalizeAuction(bytes32 saleId, uint256 tokenId) external {
        CollectionSale storage auction = collectionSales[saleId];
        require(auction.endBlock + auction.endOffsets[tokenId] < block.number, "Auction not yet closed");
        require(auction.bids[tokenId] > 0, "No bid found for the auction");
        require(!auction.finalized[tokenId], "Auction was already finalized");
        auction.finalized[tokenId] = true;
        if (_transferNft(saleId, tokenId, auction.bidders[tokenId])) {
            _payFeeAndRoyalties(saleId, tokenId, auction.bids[tokenId]);
            emit Bought(auction.collection, tokenId, auction.bidders[tokenId]);
        } else {
            _refund(auction.bidders[tokenId], auction.bids[tokenId]);
        }
    }

    function _payFeeAndRoyalties(bytes32 saleId, uint256 tokenId, uint256 salePrice) internal {
        CollectionSale storage sale = collectionSales[saleId];
        uint256 factoryFee = salePrice * collectionSales[saleId].fee / PERCENTAGE_DIVIDER;
        collectedFees += factoryFee;
        // Only interested in the receiver. PERCENTAGE_DIVIDER passed just to not use 0, but it is not necessary
        (address receiver,) = royaltiesManager.royaltyInfo(sale.collection, tokenId, PERCENTAGE_DIVIDER);
        payable(receiver).transfer(salePrice - factoryFee);
    }

    function _transferNft(bytes32 saleId, uint256 tokenId, address to) internal returns(bool) {
        CollectionSale storage sale = collectionSales[saleId];
        if (sale.toMint) {
            try IMintableCollection(sale.collection).safeMint(to, tokenId) {
                return true;
            } catch {
                return false;
            }
        } else {
            try IERC721Upgradeable(sale.collection).safeTransferFrom(address(this), to, tokenId) {
                return true;
            } catch  {
                return false;
            }
        }
    }

    function _checkAndSetCollectionSaleId(address collection, uint256 startTokenId, uint256 endTokenId) internal {
        uint256[2][] storage lookup = collectionSalesLookup[collection];
        for (uint8 index = 0; index < lookup.length; index++) {
            uint256[2] storage idBounds = lookup[index];
            if ((idBounds[0] <= startTokenId && idBounds[1] >= startTokenId) || //startTokenId is inside a sale
                (idBounds[0] <= endTokenId && idBounds[1] >= endTokenId) || //endTokenId is inside a sale
                (startTokenId <= idBounds[0] && endTokenId >= idBounds[1]) //start and end wrap a sale
            ) {
                CollectionSale storage sale = collectionSales[computeSaleId(collection, idBounds[0], idBounds[1])];
                require(
                    sale.endBlock > 0 && sale.endBlock + sale.maxOffset < block.number,
                    "Can't overlap sales"
                );
            }
        }
        lookup.push([startTokenId, endTokenId]);
    }

    function computeSaleId(address collection, uint256 startTokenId, uint256 endTokenId) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(collection, startTokenId, endTokenId));
    }

    function getSaleId(address collection, uint256 tokenId) public view returns(bytes32) {
        uint256[2][] storage lookup = collectionSalesLookup[collection];
        for (uint256 index = lookup.length; index != 0; index--) {
            uint256[2] storage idBounds = lookup[index-1];
            if (idBounds[0] <= tokenId && idBounds[1] >= tokenId) {
                return computeSaleId(collection, idBounds[0], idBounds[1]);
            }
        }
        return bytes32(0);
    }

    function withdrawSale(bytes32 saleId) external onlyRole(SALES_MANAGER_ROLE) {
        CollectionSale storage sale = collectionSales[saleId];
        require(sale.startBlock > 0 && (sale.endBlock > block.number || sale.endBlock  == 0), "Can't withdraw an inactive sale");
        require(!sale.isAuction, "Can't withdraw an auction");
        sale.endBlock = uint64(block.number);
        emit SaleWithdrawn(sale.collection, sale.startTokenId, sale.endTokenId);
    }

    function withdrawFees(address to) external onlyRole(FEE_MANAGER_ROLE) {
        payable(to).transfer(collectedFees);
        collectedFees = 0;
    }

    function setMinimumRebidConf(uint256 _newMinimumRebid, uint256 _newMinimumRebidBlocks) external onlyRole(FACTORY_ADMIN) {
        minimumRebid = _newMinimumRebid;
        minimumRebidBlocks = _newMinimumRebidBlocks;
        emit MinimumRebid(_newMinimumRebid, _newMinimumRebidBlocks);
    }

    function setPriceFeed(address _newPriceFeed) external onlyRole(FACTORY_ADMIN) {
        ethToUSDPriceFeed = AggregatorV3Interface(_newPriceFeed);
        emit NewEthUsdPriceFeed(_newPriceFeed);
    }

    function setRoyaltiesManager(IMoreNFTRoyaltiesManager _newRoyaltiesManager) external onlyRole(FACTORY_ADMIN) {
        royaltiesManager = _newRoyaltiesManager;
        require(
            _newRoyaltiesManager.supportsInterface(type(IMoreNFTRoyaltiesManager).interfaceId),
            "Provided address is not a IMoreNFTRoyaltiesManager"    
        );
        emit NewRoyaltiesManager(address(_newRoyaltiesManager));
    }

    function _refund(address _to, uint256 _amount) internal {
        if (!payable(_to).send(_amount)) {
            failedRefunds[_to] += _amount;
        }
    }

    function recoverRefund() external {
        payable(_msgSender()).transfer(failedRefunds[_msgSender()]);
        failedRefunds[_msgSender()] = 0;
    }

    function usd2Eth(uint256 _amount) public view returns(uint256) {
        (,int ethToUsdPrice,,,) = ethToUSDPriceFeed.latestRoundData();
        return _amount*(1 ether)/uint256(ethToUsdPrice);
    }

    function eth2Usd(uint256 _amount) public view returns(uint256) {
        (,int ethToUsdPrice,,,) = ethToUSDPriceFeed.latestRoundData();
        return _amount*uint256(ethToUsdPrice)/(1 ether);
    }

    event Bid(address indexed collection, uint256 indexed tokenId, address indexed by, uint256 amount); //swap by and amount
    event Bought(address indexed collection, uint256 indexed tokenId, address indexed by);
    event Refund(address indexed collection, uint256 indexed tokenId, address indexed to);
    event Sale(address indexed collection, uint256 indexed startTokenId, uint256 indexed endTokenId);
    event SaleWithdrawn(address indexed collection, uint256 indexed startTokenId, uint256 indexed endTokenId);

    event MinimumRebid(uint256 indexed rebid, uint256 indexed rebidBlocks);
    event NewEthUsdPriceFeed(address indexed priceFeed);
    event NewRoyaltiesManager(address indexed royaltiesManager);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IMoreNFTRoyaltiesManager is IERC165 {
    function royaltyInfo(address _collection, uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMintableCollection {
    function safeMint(address to, uint256 tokenId) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
interface IERC165Upgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}