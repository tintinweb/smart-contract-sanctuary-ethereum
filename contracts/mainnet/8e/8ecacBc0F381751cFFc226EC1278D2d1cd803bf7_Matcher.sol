pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOpenSea.sol";
import "./IToken.sol";
import "./Types.sol";


contract Matcher is Ownable, Types {

    event NewPF(uint indexed nftId, uint indexed newPrice);

    Seaport public openSea;
    mapping(address => bool) public isValidPayToken;
    address public matchNft;
    address public USDC;
    // step - require next trade to be above idPriceFloor by this amount
    uint256 public step;

    mapping(uint256 => uint256) public idPriceFloor;

    constructor(address _os, address _pt, address _altPt,  address _nft) {
        openSea = Seaport(_os);
        isValidPayToken[_pt] = true;
        isValidPayToken[_altPt] = true;
        matchNft = _nft;
        USDC = _altPt;
    }

    function setStep(uint256 _step) public onlyOwner {
        require(_step < 1000);
        step = _step * 10**18;
    }

    function areMatchable(Order[] calldata orders, Fulfillment[] calldata fulfillments, uint256 base18price) public view returns (bool) {
        OfferItem memory bidOffer = orders[0].parameters.offer[0];
        OfferItem memory listingOffer = orders[1].parameters.offer[0];
        return (orders.length == 2 &&
                fulfillments.length == 4 &&
                orders[0].parameters.orderType == OrderType(2) &&
                orders[1].parameters.orderType == OrderType(2) &&
                orders[0].parameters.offer.length == 1 &&
                orders[1].parameters.offer.length == 1 &&
                listingOffer.itemType == ItemType(2) &&
                listingOffer.token == matchNft &&
                listingOffer.endAmount == 1 && listingOffer.startAmount == 1 &&
                bidOffer.itemType == ItemType(1) &&
                isValidPayToken[bidOffer.token] &&
                bidOffer.endAmount == bidOffer.startAmount &&
                // price floor read
                base18price > idPriceFloor[listingOffer.identifierOrCriteria]
        );
    }

    function updPriceWithValidation(Order[] calldata orders, Fulfillment[] calldata fulfillments) internal returns (bool isMatchable) {
        uint256 base18price;
        if (orders[0].parameters.offer[0].token == USDC) {
           base18price = orders[0].parameters.offer[0].endAmount * 10**12;
        } else {
           base18price = orders[0].parameters.offer[0].endAmount;
        }
        isMatchable = areMatchable(orders, fulfillments, base18price);
        require(isMatchable);
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        // price floor write
        idPriceFloor[nftId] = base18price + step;
        emit NewPF(nftId, base18price);
    }

    function matchOrders(Order[] calldata orders, Fulfillment[] calldata fulfillments) public
    {
        require(updPriceWithValidation(orders, fulfillments));
        uint256 nftId = orders[1].parameters.offer[0].identifierOrCriteria;
        IToken(matchNft).setTxOk(nftId, true);
        openSea.matchOrders(orders, fulfillments);
        IToken(matchNft).setTxOk(nftId, false);
    }
}

pragma solidity ^0.8.6;

interface Types  {
// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}


struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

struct Order {
    OrderParameters parameters;
    bytes signature;
}
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

}

pragma solidity ^0.8.6;

interface IToken  {
    function setTxOk(uint256 _id, bool _ok) external;
}

pragma solidity ^0.8.6;
import "./Types.sol";

interface Seaport is Types {
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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