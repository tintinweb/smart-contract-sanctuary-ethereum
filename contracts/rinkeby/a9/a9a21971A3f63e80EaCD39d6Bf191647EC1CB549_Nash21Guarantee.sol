// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./utils/UUPSUpgradeableByRole.sol";
import "./interfaces/INash21Factory.sol";
import "./interfaces/INash21Guarantee.sol";
import "./interfaces/INash21Manager.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title The contract of Nash21Guarantee
/// @notice Handles payments of the Nash21 protocol, regarding tokens
/// @dev Gets payments from tenants and pays renters / token owners
contract Nash21Guarantee is INash21Guarantee, UUPSUpgradeableByRole {
    bytes32 internal constant _GUARANTEE_ADMIN_ROLE =
        keccak256("GUARANTEE_ADMIN_ROLE");
    bytes32 internal constant _GUARANTEE_FUNDER_ROLE =
        keccak256("GUARANTEE_FUNDER_ROLE");

    mapping(uint256 => uint256) private _paid;

    mapping(uint256 => uint256) private _distributed;

    mapping(bytes32 => address) private _feeds;

    /** PUBLIC FUNCTIONS */

    /// @inheritdoc INash21Guarantee
    function paid(uint256 id) external view returns (uint256) {
        return _paid[id];
    }

    /// @inheritdoc INash21Guarantee
    function distributed(uint256 id) external view returns (uint256) {
        return _distributed[id];
    }

    /// @inheritdoc INash21Guarantee
    function feeds(bytes32 id) external view returns (address) {
        return _feeds[id];
    }

    /// @inheritdoc INash21Guarantee
    function extractFunds(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(_GUARANTEE_FUNDER_ROLE) whenNotPaused {
        IERC20(token).transfer(to, amount);
    }

    /// @inheritdoc INash21Guarantee
    function fund(
        address token,
        address from,
        uint256 amount
    ) public {
        IERC20(token).transferFrom(from, address(this), amount);
    }

    /// @inheritdoc INash21Guarantee
    function claim(uint256 id) public whenNotPaused {
        INash21Factory factoryInterface = INash21Factory(
            INash21Manager(manager).get(keccak256("FACTORY"))
        );

        address owner = factoryInterface.ownerOf(id);
        (
            ,
            uint256 value,
            bytes32 currency,
            uint256 startDate,
            uint256 endDate,
            ,
            address account,

        ) = factoryInterface.data(id);
        uint256 amount = _claimable(id, startDate, endDate, value);
        require(
            msg.sender == owner || msg.sender == account,
            "Nash21Guarantee: only owner or recipient"
        );
        require(amount > 0, "Nash21Guarantee: nothing to claim");
        _distributed[id] += amount;
        IERC20 tokenInterface = IERC20(
            INash21Manager(manager).get(keccak256("USDT"))
        );
        tokenInterface.transfer(account, _transformCurrency(currency, amount));
        emit Claim(id, account, amount, currency);
    }

    /// @inheritdoc INash21Guarantee
    function claimable(uint256 id) external view returns (uint256) {
        return getReleased(id) - _distributed[id];
    }

    /// @inheritdoc INash21Guarantee
    function getReleased(uint256 id) public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(
            INash21Manager(manager).get(keccak256("FACTORY"))
        );

        (
            ,
            uint256 value,
            ,
            uint256 startDate,
            uint256 endDate,
            ,
            ,

        ) = factoryInterface.data(id);
        return _getReleased(startDate, endDate, value);
    }

    /// @inheritdoc INash21Guarantee
    function setFeeds(bytes32[] memory currencies, address[] memory feeds_)
        public
        onlyRole(_GUARANTEE_ADMIN_ROLE)
    {
        require(
            currencies.length == feeds_.length,
            "Nash21Guarantee: arrays are not the same size"
        );
        for (uint256 i = 0; i < currencies.length; i++) {
            bytes32 currency = currencies[i];
            address feed = feeds_[i];
            _setFeed(currency, feed);
        }
    }

    /// @inheritdoc INash21Guarantee
    function transformCurrency(bytes32 currency, uint256 amount)
        public
        view
        returns (uint256)
    {
        return _transformCurrency(currency, amount);
    }

    /// @inheritdoc INash21Guarantee
    function pay(uint256 id, uint256 amount) public whenNotPaused {
        INash21Factory factoryInterface = INash21Factory(
            INash21Manager(manager).get(keccak256("FACTORY"))
        );
        IERC20 tokenInterface = IERC20(
            INash21Manager(manager).get(keccak256("USDT"))
        );
        (uint256 originId, , , , , , , ) = factoryInterface.data(id);
        (, uint256 value, bytes32 currency, , , , , ) = factoryInterface.data(
            originId
        );
        uint256 left = value - _paid[originId];
        address account = msg.sender;

        if (amount < left) {
            _paid[originId] += amount;
            tokenInterface.transferFrom(
                account,
                address(this),
                transformCurrency(currency, amount)
            );
            emit Pay(originId, account, amount, currency);
        } else {
            require(left > 0, "Nash21Guarantee: token already paid");
            _paid[originId] += left;
            tokenInterface.transferFrom(
                account,
                address(this),
                transformCurrency(currency, left)
            );
            emit Pay(originId, account, left, currency);
        }
    }

    /// @inheritdoc INash21Guarantee
    function split(uint256 id, uint256 timestamp)
        public
        returns (uint256, uint256)
    {
        address account = msg.sender;
        INash21Factory factoryInterface = INash21Factory(
            INash21Manager(manager).get(keccak256("FACTORY"))
        );

        (uint256 id1, uint256 id2) = factoryInterface.split(
            account,
            id,
            timestamp
        );
        (, uint256 value1, , , , , , ) = factoryInterface.data(id1);

        if (_distributed[id] > value1) {
            _distributed[id1] = value1;
            _distributed[id2] = _distributed[id] - value1;
        } else {
            _distributed[id1] = _distributed[id];
        }

        emit Split(id, account, timestamp, id1, id2);
        return (id1, id2);
    }

    /// @inheritdoc INash21Guarantee
    function initialize(bytes32 initialCurrency, address initialFeed)
        public
        initializer
    {
        __AccessControlProxyPausable_init(msg.sender);
        _setFeed(initialCurrency, initialFeed);
    }

    /** PRIVATE/INTERNAL FUNCTIONS */

    function _setFeed(bytes32 currency, address feed) internal {
        _feeds[currency] = feed;
        emit NewFeed(currency, feed);
    }

    function _transformUsd(uint256 usd) internal view returns (uint256) {
        AggregatorV3Interface aggregatorInterface = AggregatorV3Interface(
            INash21Manager(manager).get(keccak256("FEED_USDT_USD"))
        );
        IERC20Metadata tokenInterface = IERC20Metadata(
            INash21Manager(manager).get(keccak256("USDT"))
        );

        uint256 decimals = aggregatorInterface.decimals();
        (, int256 answer, , , ) = aggregatorInterface.latestRoundData();
        uint256 usdt18 = (usd * (10**decimals)) / uint256(answer);
        return (usdt18 * (10**tokenInterface.decimals())) / 1 ether;
    }

    function _claimable(
        uint256 id,
        uint256 startDate,
        uint256 endDate,
        uint256 value
    ) internal view returns (uint256) {
        return _getReleased(startDate, endDate, value) - _distributed[id];
    }

    function _getReleased(
        uint256 startDate,
        uint256 endDate,
        uint256 value
    ) internal view returns (uint256) {
        return
            block.timestamp > endDate ? value : block.timestamp > startDate
                ? (value * (block.timestamp - startDate)) /
                    (endDate - startDate)
                : 0;
    }

    function _transformCurrency(bytes32 currency, uint256 amount)
        internal
        view
        returns (uint256)
    {
        address feed = _feeds[currency];

        if (feed == address(0)) {
            return _transformUsd(amount);
        } else {
            AggregatorV3Interface aggregatorInterface = AggregatorV3Interface(
                _feeds[currency]
            );

            uint256 decimals = aggregatorInterface.decimals();
            (, int256 answer, , , ) = aggregatorInterface.latestRoundData();
            return _transformUsd((amount * uint256(answer)) / (10**decimals));
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../utils/AccessControlProxyPausable.sol";

contract UUPSUpgradeableByRole is AccessControlProxyPausable, UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
        onlyRole(keccak256("UPGRADER_ROLE"))
    {}
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/// @title The interface of Nash21Factory
/// @notice Handles non-fungible tokens balances and actions
/// @dev Any data regarding non-fungible tokens is placed here
interface INash21Factory is IERC721EnumerableUpgradeable {
    struct Data {
        // Origin token identifier
        uint256 origin;
        // Value of the token (in currency)
        uint256 value;
        // Hashed currency symbol
        bytes32 currency;
        // Start date of the token contract
        uint256 startDate;
        // End date of the token contract
        uint256 endDate;
        // Token data URI
        string uri;
        // Recipient address
        address recipient;
        // Hashed property of the contract
        bytes32 hashId;
    }

    /// @notice Emitted when a new token is authorized
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param id Token identifier
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    event Authorize(
        bytes32 indexed hashId,
        address indexed account,
        uint256 indexed id,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string uri
    );

    /// @notice Emitted when a token is burned (usually when splitted)
    /// @param account Owner of the token
    /// @param id Token identifier
    event Burn(address indexed account, uint256 indexed id);

    /// @notice Emitted when a token is minted
    /// @param account Owner of the token
    /// @param id Token identifier
    event Mint(address indexed account, uint256 indexed id);

    /// @notice Emitted when a token URI is set permanently
    /// @param _value URI
    /// @param _id Indexed token identifier
    event PermanentURI(string _value, uint256 indexed _id); //You can indicate to OpenSea that an NFT's metadata is no longer changeable by anyone

    /// @notice Emitted when the contract URI is set
    /// @param contractURI Contract URI
    event SetContractURI(string contractURI);

    /// @notice Emitted when the tokenCreationFee is set
    /// @param hashId Hashed token identifier
    /// @param fee Creation fee
    event SetTokenCreationFee(bytes32 indexed hashId, uint256 fee);

    /// @notice Emitted when the tokenTransferFee is set
    /// @param id Token identificator
    /// @param fee Transfer fee
    event SetTokenTransferFee(uint256 indexed id, uint256 fee);

    /// @notice Emitted when the token URI is set
    /// @param tokenURI Token URI
    event SetTokenURI(uint256 id, string tokenURI);

    /// @notice Emitted when the creation of a token is unauthorized
    /// @param id Token identificator
    event Unauthorize(uint256 id);

    /// @notice Emitted when the creation of a token is unauthorized
    /// @param hash Authorized hash
    event UnauthorizeHash(bytes32 hash);

    /// @notice Authorizes and creates a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @return Token identifier
    function authAndCreate(
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri
    ) external payable returns (uint256);

    /// @notice Authorizes a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @return Token identifier
    function authorize(
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri
    ) external payable returns (uint256);

    /// @notice Authorizes a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param _creationFee CreationFee of the token
    /// @param uri Token data URI
    /// @return Token identifier
    function authorizeAndSetFees(
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        uint256 _creationFee,
        string memory uri
    ) external payable returns (uint256);

    /// @notice Returns authorized owner of a token or zero address if token is not authorized yet
    /// @param id Token identifier
    /// @return Owner of the token
    function authorized(uint256 id) external view returns (address);

    /// @notice Returns the base uri for every token
    /// @return Base URI
    function baseURI() external view returns (string memory);

    /// @notice Returns the factory contract uri
    /// @return Contract URI
    function contractURI() external view returns (string memory);

    /// @notice Creates a previously authorized token
    /// @param id Token identifier
    function create(uint256 id) external payable;

    /// @notice Creates a new token with auth signature
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @param deadline Latest time by which previous data is valid
    /// @param signature Signature of the previous data
    /// @param signer Signer of the previous data
    function createWithSignature(
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri,
        uint256 deadline,
        bytes memory signature,
        address signer
    ) external payable;

    /// @notice Returns the creation fee
    /// @return Creation fee with 18 decimals
    function creationFee() external view returns (uint256);

    /// @notice Returns on-chain data of a token
    /// @param id Token identifier
    /// @return origin Origin id of the token (diff when splitted)
    /// @return value Value of the token
    /// @return currency Hashed currency symbol of the token
    /// @return startDate Start date of the token
    /// @return endDate End date of the token
    /// @return uri Token data URI
    /// @return recipient Recipient address for claiming
    /// @return hashId Hashed property of the contract
    function data(uint256 id)
        external
        view
        returns (
            uint256 origin,
            uint256 value,
            bytes32 currency,
            uint256 startDate,
            uint256 endDate,
            string memory uri,
            address recipient,
            bytes32 hashId
        );

    /// @notice Returns the creation fee for a token
    /// @param id Token identifier
    /// @return Creation fee for a token
    function getCreationFee(uint256 id) external view returns (uint256);

    /// @notice Returns the transfer fee of a token
    /// @param id Token identifier
    /// @return Transfer fee dependant on value
    function getTransferFee(uint256 id) external view returns (uint256);

    /// @notice Initializes the contract
    function initialize() external;

    /// @notice Sets a new base URI
    /// @param uri New URI for the base tokenURIs
    function setBaseURI(string memory uri) external payable;

    /// @notice Sets a new contract URI
    /// @param contractURI_ New URI for the factory contract
    function setContractURI(string memory contractURI_) external payable;

    /// @notice Sets a new creation fee
    /// @param fee Creation fee with 18 decimals
    function setCreationFee(uint256 fee) external payable;

    /// @notice Sets a new address for a token
    /// @param id Token identifier
    /// @param recipient Recipient address
    function setRecipient(uint256 id, address recipient) external payable;

    /// @notice Sets a new creation fee for a token
    /// @param fee Creation fee with 18 decimals
    /// @dev If tokenCreationFee is 0 use global creationFee
    /// @dev If tokenCreationFee is >100 ether use 0
    /// @dev If tokenCreationFee is 0<=fee<=100 ether use tokenCreationFee
    /// @param hashId Hashed token identifier
    function setTokenCreationFee(uint256 fee, bytes32 hashId) external payable;

    /// @notice Sets a new transfer fee for a token
    /// @dev If tokenTransferFee is 0 use global transferFee
    /// @dev If tokenTransferFee is >100 ether use 0
    /// @dev If tokenTransferFee is 0<=fee<=100 ether use tokenTransferFee
    /// @param fee Creation fee with 18 decimals
    /// @param id Token identificator
    function setTokenTransferFee(uint256 fee, uint256 id) external payable;

    /// @notice Sets a new token URI
    /// @param id Token identifier
    /// @param _tokenURI New URI for a specific token
    function setTokenURI(uint256 id, string memory _tokenURI) external payable;

    /// @notice Sets a new transfer fee
    /// @param fee Transfer fee with 18 decimals
    function setTransferFee(uint256 fee) external payable;

    /// @notice Splits a token into two new tokens
    /// @param account Account that splits the token
    /// @param id Token identifier
    /// @param timestamp Date when the token is splitted
    /// @return id1 New token identifier before to split date
    /// @return id2 New token identifier after to split date
    function split(
        address account,
        uint256 id,
        uint256 timestamp
    ) external payable returns (uint256 id1, uint256 id2);

    /// @notice Returns a token URI
    /// @param id Token identifier
    /// @return Token URI
    function tokenURI(uint256 id) external returns (string memory);

    /// @notice Returns the transferFee of a token
    /// @dev If tokenTransferFee is 0 use global transferFee
    /// @dev If tokenTransferFee is >100 ether use 0
    /// @dev If tokenTransferFee is 0<=fee<=100 ether use tokenTransferFee
    /// @param id Token identifier
    /// @return Token transfer fee
    function tokenTransferFee(uint256 id) external view returns (uint256);

    /// @notice Returns the creationFee of a token
    /// @dev If tokenCreationFee is 0 use global creationFee
    /// @dev If tokenCreationFee is >100 ether use 0
    /// @dev If tokenCreationFee is 0<=fee<=100 ether use tokenCreationFee
    /// @param hashId Hashed token identifier
    /// @return Token creation fee
    function tokenCreationFee(bytes32 hashId) external view returns (uint256);

    /// @notice Returns the transfer fee
    /// @return Transfer fee with 18 decimals
    function transferFee() external view returns (uint256);

    /// @notice Unauthorizes the creation of the token for the hashed identifier
    /// @param id Token identifier
    function unauthorize(uint256 id) external payable;

    /// @notice Unauthorizes the creation of the token for authorized data
    /// @param hashId Hashed token identifier
    function unauthorizeOffchainSign(
        bytes32 hashId /*, address account, uint256 value, bytes32 currency, uint256 startDate, uint256 endDate, string memory uri, uint256 deadline */
    ) external payable;

    /// @notice Returns whether the creation of a token for token identifier is unauthorized or not
    /// @param hashId Hashed token identifier
    /// @return Whether the creation of a token for a token identifier is unauthorized or not
    function unauthorized(bytes32 hashId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @title The interface of Nash21Guarantee
/// @notice Handles payments of the Nash21 protocol, regarding tokens
/// @dev Gets payments from tenants and pays renters / token owners
interface INash21Guarantee {
    /// @notice Emitted when someone claims
    /// @param id Token identifier
    /// @param account Owner of the token
    /// @param amount Amount distributed
    /// @param currency Hashed currency symbol
    event Claim(
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        bytes32 currency
    );

    /// @notice Emitted when someone pays
    /// @param id Token identifier
    /// @param account Account paying
    /// @param amount Amount paid
    /// @param currency Hashed currency symbol
    event Pay(
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        bytes32 currency
    );

    /// @notice Emitted when a non-fungible token is splitted
    /// @param id Token identifier
    /// @param account Owner of the token
    /// @param timestamp Time when the token is splitted
    /// @param beforeId Token identifier for the new token before to timestamp
    /// @param afterId Token identifier for the new token after to timestamp
    event Split(
        uint256 indexed id,
        address indexed account,
        uint256 timestamp,
        uint256 beforeId,
        uint256 afterId
    );

    /// @notice Emitted when a new price feed is set
    /// @param currency Hashed currency symbol
    /// @param feed Address of the price feed oracle
    event NewFeed(bytes32 indexed currency, address feed);

    /// @notice Distributes the claimable amount of a token
    /// @param id Token identifier
    function claim(uint256 id) external;

    /// @notice Returns the claimable amount of a token
    /// @param id Token identifier
    /// @return Claimable amount
    function claimable(uint256 id) external view returns (uint256);

    /// @notice Returns the distributed amount of a token
    /// @param id Token identifier
    /// @return Distributed amount
    function distributed(uint256 id) external view returns (uint256);

    /// @notice Extracts ERC20 funds to an address
    /// @param token ERC20 tokens to extract
    /// @param to Address where tokens go to
    /// @param amount Amount of tokens
    function extractFunds(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @notice Funds the guarantee contract with an ERC20 token
    /// @param token ERC20 token for funding
    /// @param from Address from where tokens come
    /// @param amount Amount of tokens
    function fund(
        address token,
        address from,
        uint256 amount
    ) external;

    /// @notice Returns the expected amount released (of the value) for a token
    /// @param id Token identifier
    /// @return Amount released
    function getReleased(uint256 id) external view returns (uint256);

    /// @notice Initializes the contract
    /// @param initialCurrency Hashed currency symbol
    /// @param initialFeed Price feed address
    function initialize(bytes32 initialCurrency, address initialFeed) external;

    /// @notice Returns the paid amount for a token
    /// @param id Token identifier
    /// @return Paid amount
    function paid(uint256 id) external view returns (uint256);

    /// @notice Pays an amount for a token
    /// @param id Token identifier
    /// @param amount Amount to pay
    function pay(uint256 id, uint256 amount) external;

    /// @notice Returns the price feed address for a currency
    /// @param currency Hashed currency symbol
    /// @return Price feed address for a currency
    function feeds(bytes32 currency) external view returns (address);

    /// @notice Sets new price feeds on batch
    /// @param currencies Array of hashed currency symbols
    /// @param feeds Array of price feed addresses
    function setFeeds(bytes32[] memory currencies, address[] memory feeds)
        external;

    /// @notice Splits a token into two new tokens
    /// @dev Manages the distributed and paid amounts
    /// @param id Token identifier
    /// @param timestamp Time when the token is splitted
    /// @return Before to and after to timestamp token identifiers
    function split(uint256 id, uint256 timestamp)
        external
        returns (uint256, uint256);

    /// @notice Returns the amount in USDT of a selected amount of currency
    /// @param currency Hashed currency symbol
    /// @param amount Amount to be transformed
    function transformCurrency(bytes32 currency, uint256 amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

/// @title The interface of Nash21Manager
/// @notice Handles the configuration of Nash21 ecosystem
/// @dev Controls addresses, IDs, deployments, upgrades, proxies, access control and pausability
interface INash21Manager {
    /// @notice Emitted when a new address with ID is setted
    /// @param id Address identifier
    /// @param addr Address
    event NewId(bytes32 indexed id, address addr);

    /// @notice Emitted when a new address with ID is setted
    /// @param id Address identifier
    /// @param proxy New deployed UUPS
    /// @param implementation Proxy's implementation
    /// @param upgrade Whether or not was an upgrade or not
    event Deployment(
        bytes32 indexed id,
        address indexed proxy,
        address implementation,
        bool upgrade
    );

    /// @notice Emitted when an ID is locked for changes
    /// @param id Address identifier
    /// @param addr Address
    event Locked(bytes32 indexed id, address addr);

    /// @notice Deploy a UUPS Proxy and its implementation
    /// @dev If proxy is already deployed upgrades the implementation
    /// @param id Address identifier
    /// @param bytecode Bytecode of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    /// @return implementation Address of the implementation
    function deploy(
        bytes32 id,
        bytes calldata bytecode,
        bytes calldata initializeCalldata
    ) external returns (address implementation);

    /// @notice Deploy a UUPS Proxy with an already deployed implementation
    /// @param id Address identifier
    /// @param implementation Address of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    function deployProxyWithImplementation(
        bytes32 id,
        address implementation,
        bytes calldata initializeCalldata
    ) external;

    /// @notice Returns address of an ID
    /// @param id Address identifier
    /// @return Address of ID
    function get(bytes32 id) external view returns (address);

    /// @notice Returns address of the implementation of a proxy
    /// @param proxy Address of the proxy
    /// @return Implemenation
    function implementationByProxy(address proxy)
        external
        view
        returns (address);

    /// @notice Locks and ID for changes
    /// @param id Address identifier
    function lock(bytes32 id) external;

    /// @notice Returns whether or not an ID is locked
    /// @param id Address of the proxy
    /// @return True for locked false for not locked
    function locked(bytes32 id) external view returns (bool);

    /// @notice Returns ID linked to a proxy
    /// @param proxy Address of the proxy
    /// @return Identificator
    function name(address proxy) external view returns (bytes32);

    /// @notice Sets address linked to an ID
    /// @param id Address identifier
    /// @param addr Address
    function setId(bytes32 id, address addr) external;

    /// @notice Upgrades implementation of an UUPS proxy
    /// @param id Address identifier
    /// @param implementation Address of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    function upgrade(
        bytes32 id,
        address implementation,
        bytes calldata initializeCalldata
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {
    address public manager;

    // solhint-disable-next-line
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    // solhint-disable-next-line
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(
            hasRole(role, account),
            string(
                abi.encodePacked(
                    "AccessControlProxyPausable: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            )
        );
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControlUpgradeable managerInterface = IAccessControlUpgradeable(
            manager
        );
        return managerInterface.hasRole(role, account);
    }

    // solhint-disable-next-line
    function __AccessControlProxyPausable_init(address manager_)
        internal
        initializer
    {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(manager_);
    }

    // solhint-disable-next-line
    function __AccessControlProxyPausable_init_unchained(address manager_)
        internal
        initializer
    {
        manager = manager_;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function updateManager(address manager_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        manager = manager_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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