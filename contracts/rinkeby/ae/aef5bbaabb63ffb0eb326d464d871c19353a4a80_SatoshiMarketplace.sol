// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function setApprovalForAll(address operator, bool approved) external;
  
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC2981 is IERC165Upgradeable {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract SatoshiMarketplace is Initializable,AccessControlUpgradeable {
    enum AssetType { UNKNOWN, ERC721, ERC1155 }
    enum ListingStatus { ON_HOLD, ON_SALE, IS_AUCTION}

    struct Listing {
        address contractAddress;
        AssetType assetType;
        ListingStatus status;
        uint numOfCopies;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 commission;
        bool isDropOfTheDay;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(address => mapping(uint256 => mapping(address => Listing))) private _listings;
    mapping(address => uint256) private _outstandingPayments;
    mapping(address=>bool) private _approveForRole;
    uint256 private _defaultCommission;
    uint256 private _defaultAuctionCommission;
    address private _commissionReceiver;
    bytes32 public constant DROP_OF_THE_DAY_CREATOR_ROLE=keccak256("DROP_OF_THE_DAY_CREATOR_ROLE");
    bool private _anyAddressCanCreateItem;
    bool private _askForRole;

    event PurchaseConfirmed(uint256 tokenId, address itemOwner, address buyer);
    event PaymentWithdrawn(uint256 amount);
    event TransferCommission(address indexed reciever, uint indexed tokenId, uint indexed value);
    event TransferRoyalty(address indexed receiver, uint indexed tokenId, uint indexed value);
    event HighestBidIncreased(uint256 tokenId,address itemOwner,address bidder,uint256 amount);
    event AuctionEnded(uint256 tokenId,address itemOwner,address winner,uint256 amount);

    function initialize() initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _defaultCommission = 250;
        _defaultAuctionCommission = 250;
        _commissionReceiver = msg.sender;
    }

    function commissionReceiver() external view returns (address) {
        return _commissionReceiver;
    }

    function setCommissionReceiver(address user) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _commissionReceiver = user;

        return true;
    }

    function defaultCommission() external view returns (uint256) {
        return _defaultCommission;
    }

    function defaultAuctionCommission() external view returns (uint256) {
        return _defaultAuctionCommission;
    }

    function setDefaultCommission(uint256 commission) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        require(commission <= 3000, "commission is too high");
        _defaultCommission = commission;

        return true;
    }

    function setDefaultAuctionCommission(uint256 commission)
        external
        returns (bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        require(commission <= 3000, "commission is too high");
        _defaultAuctionCommission = commission;

        return true;
    }

    function setListing(
        address contractAddress,
        AssetType assetType,
        uint256 tokenId,
        ListingStatus status,
        uint numOfCopies,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 dropOfTheDayCommission,
        bool isDropOfTheDay
    ) external {
        
        require(
            assetType == AssetType.ERC721 || assetType == AssetType.ERC1155,
            "Only ERC721/ERC1155 are supported"
        );

        if (assetType == AssetType.ERC721) {
            require(
                IERC721(contractAddress).balanceOf(msg.sender, tokenId) > 0,
                "Marketplace: Insufficient Balance"
            );
            require(IERC721(contractAddress).isApprovedForAll(msg.sender,address(this)),"Marketplace:should call setApproveForAll");
        } else if(assetType == AssetType.ERC1155) {
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, tokenId) >= 1,
                "Marketplace: Insufficient Balance"
            );
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender,address(this)),"Marketplace:should call setApproveForAll");
        }

        if (status == ListingStatus.ON_HOLD) {
            require(
                _listings[contractAddress][tokenId][msg.sender].highestBidder == address(0),
                "Marketplace: bid already exists"
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:0,
                price: 0,
                startTime: 0,
                endTime: 0,
                commission: 0,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == ListingStatus.ON_SALE) {
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "Marketplace: token not on hold"
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: 0,
                endTime: 0,
                commission: _defaultCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == ListingStatus.IS_AUCTION) {
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "Marketplace: token not on hold"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "endTime should be > startTime. startTime should be > current time"
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: _defaultAuctionCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if(isDropOfTheDay){
            //putting DOTD on auction
            require(
                hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
                "Marketplace: Caller is not a drop of the day creator"
            );
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "Marketplace: token not on hold"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "endTime should be > startTime. startTime should be > current time"
            );
            require(
                dropOfTheDayCommission <= 3000,
                "DOTD: commission is too high"
            );
            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: dropOfTheDayCommission,
                isDropOfTheDay: isDropOfTheDay,
                highestBidder: address(0),
                highestBid: 0
            });
        }
    }

    function listingOf(address contractAddress, address account, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        require(
            account != address(0),
            "ERC1155: address cannot be zero address"
        );

        return _listings[contractAddress][tokenId][account];
        // return (
        //     l.contractAddress,
        //     l.assetType,
        //     l.status,
        //     l.price,
        //     l.numOfCopies,
        //     l.startTime,
        //     l.endTime,
        //     l.commission,
        //     l.isDropOfTheDay,
        //     l.highestBidder,
        //     l.highestBid
        // );
    }

    function buy(uint256 tokenId, uint numOfCopies,address itemOwner, address contractAddress)
        external
        payable
        returns (bool)
    {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.ON_SALE,
            "buy: token not listed for sale"
        );

        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            require(
                IERC721(contractAddress).balanceOf(itemOwner, tokenId) > 0,
                "buy: Insufficient Copies to buy"
            );
            require(msg.value == _listings[contractAddress][tokenId][itemOwner].price*1, "buy: not enough fund");
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            require(
                IERC1155(contractAddress).balanceOf(itemOwner, tokenId) >= _listings[contractAddress][tokenId][itemOwner].numOfCopies,
                " buy: Insufficient Copies to buy"
            );
            require(msg.value == _listings[contractAddress][tokenId][itemOwner].numOfCopies * _listings[contractAddress][tokenId][itemOwner].price, "buy: not enough fund");
        }
       
        if (_listings[contractAddress][tokenId][itemOwner].isDropOfTheDay) {
            require(
                block.timestamp >= _listings[contractAddress][tokenId][itemOwner].startTime &&
                block.timestamp <= _listings[contractAddress][tokenId][itemOwner].endTime,
                "buy(DOTD): DOTD has ended/not started"
            );
        }
        uint256 commision =
            (msg.value * _listings[contractAddress][tokenId][itemOwner].commission) / 10000;

        uint copiesLeft = 0;
        address ownerRoyaltyAddr;
        uint ownerRoyaltyAmount;
        
        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId);
            (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, msg.value);
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId, _listings[contractAddress][tokenId][itemOwner].numOfCopies, "");
            (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, msg.value);
            copiesLeft = _listings[contractAddress][tokenId][itemOwner].numOfCopies - numOfCopies;
        }

         _listings[contractAddress][tokenId][itemOwner] = Listing({
            contractAddress: copiesLeft >= 1 ? contractAddress : address(0),
            assetType: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].assetType : AssetType.UNKNOWN,
            status: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].status : ListingStatus.ON_HOLD,
            numOfCopies: copiesLeft >= 1 ? copiesLeft : 0,
            price: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].price : 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: address(0),
            highestBid: 0
        });
        emit PurchaseConfirmed(tokenId, itemOwner, msg.sender);
        _outstandingPayments[_commissionReceiver] += commision;
        _outstandingPayments[itemOwner] += (msg.value - commision);
        _outstandingPayments[ownerRoyaltyAddr] += ownerRoyaltyAmount;
        emit TransferCommission(_commissionReceiver, tokenId, commision);
        emit TransferRoyalty(ownerRoyaltyAddr, tokenId, ownerRoyaltyAmount);
        return true;
    }

    function withdrawPayment() external returns (bool) {
        uint256 amount = _outstandingPayments[msg.sender];
        if (amount > 0) {
            _outstandingPayments[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingPayments[msg.sender] = amount;
                return false;
            }
            emit PaymentWithdrawn(amount);
        }
        return true;
    }

    function outstandingPayment(address user) external view returns (uint256) {
        return _outstandingPayments[user];
    }

    //Auction
    function bid(address contractAddress, uint256 tokenId, address itemOwner) external payable {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            "Item not listed for auction."
        );
        require(
            block.timestamp <= _listings[contractAddress][tokenId][itemOwner].endTime &&
                block.timestamp >= _listings[contractAddress][tokenId][itemOwner].startTime,
            "Auction not started/already ended."
        );
        require(
            msg.value > _listings[contractAddress][tokenId][itemOwner].highestBid,
            "There already is a higher bid."
        );

        if (_listings[contractAddress][tokenId][itemOwner].highestBid != 0) {
            _outstandingPayments[
                _listings[contractAddress][tokenId][itemOwner].highestBidder
            ] += _listings[contractAddress][tokenId][itemOwner].highestBid;
        }
        _listings[contractAddress][tokenId][itemOwner].highestBidder = msg.sender;
        _listings[contractAddress][tokenId][itemOwner].highestBid = msg.value;
        emit HighestBidIncreased(tokenId, itemOwner, msg.sender, msg.value);
    }

    function auctionEnd(address contractAddress, uint256 tokenId, address itemOwner) external {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            "Auction end: item is not for auction"
        );
        require(
            block.timestamp > _listings[contractAddress][tokenId][itemOwner].endTime,
            "Auction end: auction not yet ended."
        );

        uint256 commision =
            (_listings[contractAddress][tokenId][itemOwner].highestBid *
                _listings[contractAddress][tokenId][itemOwner].commission) / 10000;

        _listings[contractAddress][tokenId][itemOwner] = Listing({
            contractAddress: address(0),
            assetType: AssetType.UNKNOWN,
            status: ListingStatus.ON_HOLD,
            numOfCopies:_listings[contractAddress][tokenId][itemOwner].numOfCopies,
            price: 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: _listings[contractAddress][tokenId][itemOwner].highestBidder,
            highestBid: _listings[contractAddress][tokenId][itemOwner].highestBid
        });
        emit AuctionEnded(
            tokenId,
            itemOwner,
            _listings[contractAddress][tokenId][itemOwner].highestBidder,
            _listings[contractAddress][tokenId][itemOwner].highestBid
        );

        address ownerRoyaltyAddr;
        uint ownerRoyaltyAmount;
        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId);
            (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, _listings[contractAddress][tokenId][itemOwner].highestBid);
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId, 1, "");
            (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, _listings[contractAddress][tokenId][itemOwner].highestBid);
        }

        _outstandingPayments[itemOwner] += commision;
        _outstandingPayments[itemOwner] += (_listings[contractAddress][tokenId][itemOwner].highestBid - commision);
        _outstandingPayments[ownerRoyaltyAddr] += ownerRoyaltyAmount;
        emit TransferCommission(_commissionReceiver, tokenId, commision);
        emit TransferRoyalty(ownerRoyaltyAddr, tokenId, ownerRoyaltyAmount);
    }

    function setDropOfTheDayAuctionEndTime(uint256 tokenId, address contractAddress,address itemOwner,uint256 newEndTime) external{
        require(
            hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
            "caller is not drop of the day creator."
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            "Item is not in auction"
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].isDropOfTheDay,
            "item is not for drop of the day."
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].endTime < newEndTime,
            "newEndTime not greater than current endTime."
        );
        _listings[contractAddress][tokenId][itemOwner].endTime = newEndTime;
    }

    /** transfer ADMIN ROLE functions*/

    //admin call this function first to approve the addr
    function approveAddressForRole(address _receipent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Caller is not an admin");
        _approveForRole[_receipent] = true;
    }
    //approved address will call this function and ask for permission
    function askForRole() external {
        require(_approveForRole[msg.sender], "Not approved to make a call");
        _askForRole = true;
    }
    //admin will call this function and assing the ADMIN role
    function transferRoleOwnership(address _receipent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Caller is not an admin");
        require(_askForRole," No one asked for ownership");
        _approveForRole[_receipent] = false;
        _askForRole = false;
        super.grantRole(DEFAULT_ADMIN_ROLE, _receipent);
        renounceRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
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
     * This empty reserved space is put in place to allow future versions to add new
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
     * This empty reserved space is put in place to allow future versions to add new
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}