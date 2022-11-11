// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./IChainPostIndexer.sol";
import "../SkeletonKeyDB/Asset/Asset.sol";

/**
 * @title ChainPostIndexer
 * @dev Standalone Price Feed Database Contract for ChainPost Ecosystem
 *
 * NOT FOR THE END USER, USE THE CHAINPOST CONTRACT INSTEAD
 *
 * @author CyAaron Tai Nava || hemlockStreet.x
 */
contract ChainPostIndexer is IChainPostIndexer, Asset {
    string public constant name = "ChainPost Indexer";

    function compareStrings(string memory self, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(self)) ==
            keccak256(abi.encodePacked(b)));
    }

    mapping(uint => Token) internal _tokens;
    uint internal tokenIds;
    mapping(uint => PriceFeed) internal _priceFeeds;
    uint internal feedIds;

    function supportedTokens() public view override returns (uint tokens) {
        tokens = tokenIds;
    }

    function supportedFeeds() public view override returns (uint feeds) {
        feeds = feedIds;
    }

    constructor(
        string memory symbol,
        address wAddr,
        address pfAddr,
        address db,
        address master
    ) Asset(db, master) {
        tokenIds++;
        _tokens[tokenIds] = Token(symbol, wAddr);
        feedIds++;
        _priceFeeds[feedIds] = PriceFeed(1, "USD", pfAddr);
    }

    function token(uint idx) public view override returns (Token memory) {
        return _tokens[idx];
    }

    function addressOfToken(uint idx) public view override returns (address) {
        return _tokens[idx].addr;
    }

    function priceFeed(uint idx)
        public
        view
        override
        returns (PriceFeed memory)
    {
        return _priceFeeds[idx];
    }

    function addressOfPriceFeed(uint idx)
        public
        view
        override
        returns (address)
    {
        return _priceFeeds[idx].addr;
    }

    function numSupported()
        public
        view
        override
        returns (uint tokens, uint feeds)
    {
        tokens = tokenIds;
        feeds = feedIds;
    }

    function isDefined(PriceFeed memory feed)
        internal
        view
        returns (bool defined)
    {
        defined =
            (feed.addr != address(0)) &&
            (!compareStrings(feed.vs, "")) &&
            (!compareStrings(token(feed.tokenId).symbol, ""));
    }

    function metadata(uint feedId)
        public
        view
        override
        returns (
            address tokenAddress,
            address feedAddress,
            string memory tokenSymbol,
            string memory currencyPair,
            bool defined
        )
    {
        PriceFeed memory pf = priceFeed(feedId);
        Token memory tkn = token(pf.tokenId);
        tokenAddress = tkn.addr;
        feedAddress = pf.addr;
        tokenSymbol = tkn.symbol;
        currencyPair = pf.vs;
        defined = isDefined(pf);
    }

    function queryTokenSymbol(string memory sym)
        public
        view
        override
        returns (uint)
    {
        for (uint i = 0; i <= tokenIds; i++) {
            if (compareStrings(sym, token(i).symbol)) return i;
        }
        return 0;
    }

    function queryFeedToken(uint tokenId, string memory vs)
        public
        view
        override
        returns (uint)
    {
        for (uint i = 0; i <= feedIds; i++) {
            if (
                compareStrings(vs, priceFeed(i).vs) &&
                tokenId == priceFeed(i).tokenId
            ) return i;
        }
        return 0;
    }

    function queryPair(string memory symbol, string memory vs)
        public
        view
        override
        returns (uint feedId)
    {
        uint tokenId = queryTokenSymbol(symbol);
        feedId = queryFeedToken(tokenId, vs);
    }

    // Setters
    function queryTokenAddress(address addr) internal view returns (uint) {
        for (uint i = 0; i <= tokenIds; i++) {
            if (addr == token(i).addr) return i;
        }
        return 0;
    }

    function registerToken(string memory symbol, address addr)
        public
        override
        RequiredTier(1)
        returns (uint successIfNot0)
    {
        uint byAddress = queryTokenAddress(addr);
        uint bySymbol = queryTokenSymbol(symbol);
        uint tokenIdx = (byAddress == bySymbol) ? bySymbol : 0;
        if (tokenIdx == 0) {
            tokenIds++;
            _tokens[tokenIds] = Token(symbol, addr);
        }
        successIfNot0 = tokenIdx;
    }

    function queryFeedAddress(address addr) internal view returns (uint) {
        for (uint i = 0; i <= feedIds; i++) {
            if (addr == priceFeed(i).addr) return i;
        }
        return 0;
    }

    function registerFeed(
        uint tokenId,
        string memory vs,
        address addr
    ) public override RequiredTier(1) returns (uint successIfNot0) {
        uint byAddress = queryFeedAddress(addr);
        uint byPair = queryFeedToken(tokenId, vs);
        uint feedId = (byAddress == byPair) ? byPair : 0;
        if (feedId == 0) {
            feedIds++;
            _priceFeeds[feedIds] = PriceFeed(tokenId, vs, addr);
        }
        successIfNot0 = feedId;
    }

    function updateFeed(
        string memory symbol,
        string memory base,
        address addr
    ) public override RequiredTier(1) returns (uint updated) {
        uint feedIdx = queryPair(symbol, base);
        require(feedIdx != 0, "404");

        uint old = _priceFeeds[feedIdx].tokenId;
        _priceFeeds[feedIdx] = PriceFeed(old, base, addr);
        return feedIdx;
    }

    function updateToken(string memory symbol, address addr)
        public
        override
        RequiredTier(1)
        returns (uint updated)
    {
        uint tokenIdx = queryTokenSymbol(symbol);
        require(tokenIdx != 0, "404");

        _tokens[tokenIdx] = Token(symbol, addr);
        return tokenIdx;
    }
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