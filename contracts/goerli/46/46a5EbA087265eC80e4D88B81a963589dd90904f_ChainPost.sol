// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../SkeletonKeyDB/Asset/Asset.sol";
import "./IChainPost.sol";
import "./IChainPostIndexer.sol";
import "./IPriceConverter.sol";

/**
 * @title ChainPost
 * @dev Main ChainPost Contract
 *
 * Coordinates the i/o of the Indexer & Administrative Panel Contract
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
contract ChainPost is Asset, IChainPost {
    string public constant name = "ChainPost";

    address public _indexer;
    address public _converter;
    mapping(string => string) public _analogs;
    mapping(string => bool) public _supported;
    uint public gasIndex;

    function isGas(string memory symbol) public view override returns (bool) {
        return (IChainPostIndexer(_indexer).queryTokenSymbol(symbol) ==
            gasIndex);
    }

    constructor(address db, address cnvrt) Asset(db, address(0)) {
        _converter = cnvrt;
        gasIndex = 1;
    }

    function _setGas(uint idx) public RequiredTier(2) {
        gasIndex = idx;
    }

    function _setConverter(address addr) public RequiredTier(2) {
        _converter = addr;
    }

    function _setIndexer(address addr) public RequiredTier(2) {
        _indexer = addr;
    }

    modifier Registered(string memory symbol) {
        uint idx = IChainPostIndexer(_indexer).queryTokenSymbol(symbol);
        require(idx != 0, "404");
        _;
    }

    function _toggleSupport(string memory symbol)
        public
        RequiredTier(2)
        Registered(symbol)
    {
        _supported[symbol] = !_supported[symbol];
    }

    modifier Supported(string memory symbol) {
        require(_supported[symbol], "Under Maintenance");
        _;
    }

    function _registerAnalog(string memory symbol, string memory analog)
        public
        RequiredTier(2)
        Registered(symbol)
    {
        _analogs[symbol] = analog;
        _analogs[analog] = symbol;
    }

    function _deleteAnalog(string memory symbol) public RequiredTier(2) {
        string memory analog = _analogs[symbol];
        require(!compareStrings("", symbol), "404");
        delete _analogs[symbol];
        delete _analogs[analog];
    }

    function numSupported()
        public
        view
        override
        returns (uint tokens, uint feeds)
    {
        IChainPostIndexer indexer = IChainPostIndexer(_indexer);
        (uint registeredTokens, uint registeredFeeds) = indexer.numSupported();
        uint tkn = 0;
        uint pf = 0;
        string[] memory cache = new string[](registeredTokens);
        for (uint i = 1; i <= registeredFeeds; i++) {
            (, , string memory tknSymbol, , bool defined) = indexer.metadata(i);
            if (defined && _supported[tknSymbol]) pf++;
            bool present = false;
            for (uint j = 0; j < cache.length; j++) {
                if (compareStrings(cache[j], tknSymbol)) present = true;
            }
            if (!present) {
                cache[tkn] = tknSymbol;
                tkn++;
            }
        }
        tokens = tkn;
        feeds = pf;
    }

    function _supportedAssets() internal view returns (string[] memory) {
        (uint sTkns, ) = numSupported();
        string[] memory result = new string[](sTkns);

        IChainPostIndexer indexer = IChainPostIndexer(_indexer);

        (uint rTkns, uint rFeeds) = indexer.numSupported();
        string[] memory registered = new string[](rTkns);
        uint idx = 0;
        string memory tknSymbol = "";
        bool present = false;

        for (uint i = 1; i <= rFeeds; i++) {
            (, , tknSymbol, , ) = indexer.metadata(i);
            present = false;
            for (uint j = 0; j < registered.length; j++) {
                if (compareStrings(registered[j], tknSymbol)) present = true;
            }
            if (!present) {
                registered[idx] = tknSymbol;
                idx++;
            }
        }

        idx = 0;
        for (uint i = 0; i < rTkns; i++) {
            tknSymbol = registered[i];
            present = false;
            for (uint j = 0; j < sTkns; j++) {
                if (compareStrings(result[j], tknSymbol)) present = true;
            }
            if (!present) {
                result[idx] = tknSymbol;
                idx++;
            }
        }

        return result;
    }

    function supportedTokens() public view override returns (string[] memory) {
        IChainPostIndexer indexer = IChainPostIndexer(_indexer);

        string[] memory assets = _supportedAssets();
        uint numTkns = 0;
        for (uint i = 0; i < assets.length; i++) {
            uint tIdx = indexer.queryTokenSymbol(assets[i]);
            uint fIdx = indexer.queryFeedToken(tIdx, "USD");
            (address tkn, address pf, , , bool defined) = indexer.metadata(
                fIdx
            );
            if (defined && tkn != address(0) && pf != tkn) numTkns++;
        }

        string[] memory result = new string[](numTkns);
        uint idx;
        for (uint i = 0; i < assets.length; i++) {
            uint tIdx = indexer.queryTokenSymbol(assets[i]);
            uint fIdx = indexer.queryFeedToken(tIdx, "USD");
            (address tkn, address pf, , , bool defined) = indexer.metadata(
                fIdx
            );
            if (defined && tkn != address(0) && pf != tkn) {
                result[idx] = assets[i];
                idx++;
            }
        }

        return result;
    }

    function findPair(string memory symbol, string memory basePair)
        public
        view
        override
        Registered(symbol)
        Supported(symbol)
        returns (address tknAddr, address pfAddr)
    {
        IChainPostIndexer indexer = IChainPostIndexer(_indexer);
        string memory analog = _analogs[symbol];
        bool hasAnalog = !compareStrings(analog, "");

        uint idx = indexer.queryPair(symbol, basePair);
        (tknAddr, pfAddr, , , ) = indexer.metadata(idx);

        if (hasAnalog) {
            uint apIdx = indexer.queryPair(analog, basePair);
            address analogPricefeed = indexer.addressOfPriceFeed(apIdx);
            if (pfAddr == address(0)) pfAddr = analogPricefeed;

            uint tIdx;
            if (tknAddr == address(0)) {
                tIdx = indexer.queryTokenSymbol(symbol);
                address tokenAddr = indexer.addressOfToken(tIdx);
                tknAddr = tokenAddr;
            }

            if (tknAddr == pfAddr) {
                tIdx = indexer.queryTokenSymbol(analog);
                address tokenAddr = indexer.addressOfToken(tIdx);
                tknAddr = tokenAddr;
            }
        }
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        bytes32 aBytes = keccak256(abi.encodePacked(a));
        bytes32 bBytes = keccak256(abi.encodePacked(b));
        return (aBytes == bBytes);
    }

    function conversion(string memory symbol) internal view returns (int) {
        (address tkn, address feed) = findPair(symbol, "USD");
        int amount = IPriceConverter(_converter).getDerivedPrice(
            _converter,
            feed
        );

        uint feedDec = AggregatorV3Interface(feed).decimals();
        uint tknDec = IERC20Metadata(tkn).decimals();
        if (feedDec == tknDec) return amount;
        else {
            uint diff = (tknDec > feedDec)
                ? tknDec - feedDec
                : feedDec - tknDec;
            if (tknDec > feedDec) return amount * int(10**diff);
            else return amount / int(10**diff);
        }
    }

    function tokensPerDollar(string memory symbol) internal view returns (int) {
        string memory analog = _analogs[symbol];
        bool isAnalog = !compareStrings(analog, "");

        if (isAnalog) {
            // usd * (usd/wbtc) || (usd/wbtc) = (usd/btc) * (btc/wbtc) || btc/usd && wbtc/btc
            (address tkn, address feed) = findPair(symbol, analog);
            AggregatorV3Interface pf = AggregatorV3Interface(feed);
            IPriceConverter cnvrtr = IPriceConverter(_converter);

            int rate = cnvrtr.getDerivedPrice(_converter, feed); // (btc/wbtc)
            int secondaryPrice = conversion(analog); // (usd/btc)

            uint pfDec = pf.decimals();
            uint tknDec = IERC20Metadata(tkn).decimals();
            int adjustment = int(10**(pfDec - 1));

            int price = (secondaryPrice * rate) / adjustment;
            if (pfDec == tknDec) return price;
            else {
                uint diff = (tknDec > pfDec) ? tknDec - pfDec : pfDec - tknDec;
                if (tknDec > pfDec) return price * int(10**diff);
                else return price / int(10**diff);
            }
        } else return conversion(symbol);
    }

    function dollarAmountToTokens(int dollars, string memory symbol)
        public
        view
        override
        Registered(symbol)
        Supported(symbol)
        returns (int)
    {
        return dollars * tokensPerDollar(symbol);
    }

    function userCanPay(address user, int dollars) public view returns (bool) {
        string[] memory all = supportedTokens();
        int value = 0;
        for (uint i = 0; i < all.length; i++) {
            (address thisTkn, ) = findPair(all[i], "USD");
            IERC20Metadata std = IERC20Metadata(thisTkn);
            uint bal = std.balanceOf(user);

            int tpd = tokensPerDollar(all[i]);
            value += int(bal) / tpd;
        }
        return value >= dollars;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IPriceConverter {
    function getDerivedPrice(address from, address to)
        external
        view
        returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Contract by CAT6#2699

interface IChainPostIndexer {
    struct Token {
        string symbol;
        address addr;
    }

    struct PriceFeed {
        uint tokenId;
        string vs;
        address addr;
    }

    function supportedTokens() external view returns (uint);

    function supportedFeeds() external view returns (uint);

    function token(uint idx) external view returns (Token memory);

    function addressOfToken(uint idx) external view returns (address);

    function priceFeed(uint idx) external view returns (PriceFeed memory);

    function addressOfPriceFeed(uint idx) external view returns (address);

    function numSupported() external view returns (uint, uint);

    function queryTokenSymbol(string memory sym) external view returns (uint);

    function queryFeedToken(uint assedId, string memory vs)
        external
        view
        returns (uint);

    function queryPair(string memory symbol, string memory vs)
        external
        view
        returns (uint);

    function metadata(uint idx)
        external
        view
        returns (
            address tokenAddress,
            address feedAddress,
            string memory tokenSymbol,
            string memory currencyPair,
            bool defined
        );

    function registerToken(string memory symbol, address addr)
        external
        returns (uint);

    function registerFeed(
        uint assetId,
        string memory vs,
        address addr
    ) external returns (uint);

    function updateFeed(
        string memory symbol,
        string memory base,
        address addr
    ) external returns (uint updated);

    function updateToken(string memory symbol, address addr)
        external
        returns (uint updated);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IChainPost {
    function numSupported() external view returns (uint tokens, uint feeds);

    function supportedTokens() external view returns (string[] memory);

    function findPair(string memory symbol, string memory basePair)
        external
        view
        returns (address tknAddr, address pfAddr);

    function dollarAmountToTokens(int dollars, string memory symbol)
        external
        view
        returns (int);

    function isGas(string memory symbol) external view returns (bool);

    function userCanPay(address user, int dollars) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "../ISkeletonKeyDB.sol";
import "./IAsset.sol";

/**
 * @title Asset
 * @dev Standalone Asset template for SkeletonKeyDB compatibility
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */

abstract contract Asset is IAsset {
    address private _deployer;
    address private _skdb;
    address private _asset;

    /**
     * @dev Constructor
     *
     * @param db SkeletonKeyDB address
     *
     * @param asset Javascript `==` logic applies. (falsy & truthy values)
     * Use `address(0)` for standalone assets (typically Web2-based) assets.
     * Use actual asset address otherwise
     */
    constructor(address db, address asset) {
        _skdb = db;
        _deployer = msg.sender;
        bool standalone = asset == address(0);
        _asset = standalone ? address(this) : asset;
    }

    function _skdbMetadata()
        public
        view
        override
        returns (
            address asset,
            address skdb,
            address deployer
        )
    {
        asset = _asset;
        skdb = _skdb;
        deployer = _deployer;
    }

    function _owner() internal view returns (address) {
        return ISkeletonKeyDB(_skdb).skeletonKeyHolder(_asset);
    }

    function _skdbAccessTier(address user) internal view returns (uint) {
        return ISkeletonKeyDB(_skdb).accessTier(_asset, user);
    }

    modifier RequiredTier(uint tier) {
        require(_skdbAccessTier(msg.sender) >= tier, "!Authorized");
        _;
    }

    function _setSkdb(address newDb) public override RequiredTier(3) {
        _skdb = newDb;
    }

    function _setAsset(address newAst) public override RequiredTier(3) {
        require((newAst != _asset) && (_asset != address(this)), "disabled");
        _asset = newAst;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ISkeletonKeyDB
 * @dev SkeletonKeyDB Interface
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface ISkeletonKeyDB {
    function skeletonKeyHolder(address asset) external view returns (address);

    function executiveKeyHolder(address asset) external view returns (address);

    function adminKeyHolders(address asset)
        external
        view
        returns (address[] memory);

    function akIds(address asset) external view returns (uint[] memory ids);

    function diag(address asset)
        external
        view
        returns (
            address skHolder,
            address skToken,
            uint skId,
            address ekHolder,
            address ekToken,
            uint ekId,
            address[] memory akHolders,
            address akToken,
            uint[] memory akId
        );

    function isAdminKeyHolder(address asset, address user)
        external
        view
        returns (bool);

    function accessTier(address asset, address holder)
        external
        view
        returns (uint);

    function defineSkeletonKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineExecutiveKey(
        address asset,
        address token,
        uint id
    ) external;

    function defineAdminKey(
        address asset,
        address token,
        uint[] memory ids
    ) external;

    function manageAdmins(
        address asset,
        uint[] memory ids,
        bool grant
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IAsset
 * @dev Standard Asset Interface for SkeletonKeyDB
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
interface IAsset {
    function _skdbMetadata()
        external
        view
        returns (
            address asset,
            address skdb,
            address deployer
        );

    function _setSkdb(address newDb) external;

    function _setAsset(address newAst) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}