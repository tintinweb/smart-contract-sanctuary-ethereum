// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.13;

contract Constants {
    //seaport
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    uint256 public constant SEAPORT_MARKET_ID = 0;

    //looksrare
    address public constant LOOKSRARE =
        0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    uint256 public constant LOOKSRARE_MARKET_ID = 1;
    //x2y2
    address public constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3; //单个购买时的market合约
    // address public constant X2Y2_BATCH =
    //     0x56Dd5bbEDE9BFDB10a2845c4D70d4a2950163044; // 批量购买时的market合约--参考用
    uint256 public constant X2Y2_MARKET_ID = 2;
    //cryptopunk
    address public constant CRYPTOPUNK =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    uint256 public constant CRYPTOPUNK_MARKET_ID = 3;
    //mooncat
    address public constant MOONCAT =
        0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;
    uint256 public constant MOONCAT_MARTKET_ID = 4;

    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256 id;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }
    struct OrderItem {
        ItemType itemType;
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }
    enum ItemType {
        INVALID,
        NATIVE,
        ERC20,
        ERC721,
        ERC1155
    }
    struct TradeInput {
        uint256 value; // 此次调用x2y2\looksrare\..需传递的主网币数量
        bytes inputData; //此次调用的input data
        OrderItem[] tokens; // 本次调用要购买的NFT信息
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../bases/Constants.sol";

contract MarketRegistry is Ownable, Constants {
    struct TradeDetail {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy; //custom market proxy
        bool isLib; //是否通过委托调用的方式，调用Market市场合约。大多数情况是true，因为Market合约中会校验msg。sender是否为接单者
        bool isActive;
    }

    Market[] public markets;

    constructor(address universalMarektProxy) {
        markets.push(Market(SEAPORT, false, true)); //market_id=0,call
        markets.push(Market(universalMarektProxy, true, true)); //market_id=1,delegatecall
    }

    function addMarket(address proxy, bool isLib) external onlyOwner {
        markets.push(Market(proxy, isLib, true));
    }

    function addMarkets(address[] memory proxies, bool[] memory isLibs)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < proxies.length; i++) {
            markets.push(Market(proxies[i], isLibs[i], true));
        }
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(
        uint256 marketId,
        address newProxy,
        bool isLib
    ) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.isLib = isLib;
    }
}