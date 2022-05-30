/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
// File: contracts/library/BridgeSecurity.sol

pragma solidity ^0.8.7;

library BridgeSecurity {
    function generateSignerMsgHash(uint64 epoch, address[] memory signers)
        internal
        pure
        returns (bytes32 msgHash)
    {
        msgHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                address(0),
                epoch,
                _encodeAddressArr(signers)
            )
        );
    }

    function generatePackMsgHash(
        address thisAddr,
        uint64 epoch,
        uint8 networkId,
        uint64[2] memory blockScanRange,
        uint256[] memory txHashes,
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) internal pure returns (bytes32 msgHash) {
        msgHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                thisAddr,
                epoch,
                _encodeFixed2Uint64Arr(blockScanRange),
                networkId,
                _encodeUint256Arr(txHashes),
                _encodeAddressArr(tokens),
                _encodeAddressArr(recipients),
                _encodeUint256Arr(amounts)
            )
        );
    }

    function signersVerification(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s,
        address[] memory signers,
        mapping(address => bool) storage mapSigners
    ) internal view returns (bool) {
        uint64 totalSigners = 0;
        for (uint64 i = 0; i < signers.length; i++) {
            if (mapSigners[signers[i]]) totalSigners++;
        }
        return (_getVerifiedSigners(msgHash, v, r, s, mapSigners) ==
            (totalSigners / 2) + 1);
    }

    function _getVerifiedSigners(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s,
        mapping(address => bool) storage mapSigners
    ) private view returns (uint8 verifiedSigners) {
        address lastAddr = address(0);
        verifiedSigners = 0;
        for (uint64 i = 0; i < v.length; i++) {
            address recovered = ecrecover(msgHash, v[i], r[i], s[i]);
            if (recovered > lastAddr && mapSigners[recovered])
                verifiedSigners++;
            lastAddr = recovered;
        }
    }

    function _encodeAddressArr(address[] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }

    function _encodeUint256Arr(uint256[] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }

    function _encodeFixed2Uint64Arr(uint64[2] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }
}

// File: contracts/BaseToken/interface/ITokenFactory.sol

pragma solidity ^0.8.7;

interface ITokenFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event BridgeChanged(address indexed oldBridge, address indexed newBridge);

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    event TokenCreated(
        string name,
        string indexed symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap,
        address indexed token
    );

    event TokenRemoved(address indexed token);

    event TokenDecimalChanged(
        address indexed token,
        uint8 oldDecimal,
        uint8 newDecimal
    );

    function owner() external view returns (address);

    function tokens() external view returns (address[] memory);

    function tokenExist(address token) external view returns (bool);

    function bridge() external view returns (address);

    function admin() external view returns (address);

    function setBridge(address bridge) external;

    function setAdmin(address admin) external;

    function createToken(
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap
    ) external returns (address token);

    function removeToken(address token) external;

    function setTokenDecimal(address token, uint8 decimal) external;
}

// File: contracts/BaseBridgeV2/interface/IBridgeV2.sol

pragma solidity ^0.8.7;

struct TokenReq {
    bool exist;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 chargePercent;
    uint256 minCharge;
    uint256 maxCharge;
}

struct CrossTokenInfo {
    string name;
    string symbol;
}

struct NetworkInfo {
    uint8 id;
    string name;
}

struct TokenData {
    address[] tokens;
    address[] crossTokens;
    uint256[] minAmounts;
    uint256[] maxAmounts;
    uint256[] chargePercents;
    uint256[] minCharges;
    uint256[] maxCharges;
    uint8[] tokenTypes;
}

struct TokensInfo {
    uint8[] ids;
    address[][] tokens;
    address[][] crossTokens;
    uint256[][] minAmounts;
    uint256[][] maxAmounts;
    uint256[][] chargePercents;
    uint256[][] minCharges;
    uint256[][] maxCharges;
    uint8[][] tokenTypes;
}

interface IBridgeV2 {
    event TokenConnected(
        address indexed token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge,
        address indexed crossToken,
        string symbol
    );

    event TokenReqChanged(
        uint64 blockIndex,
        address indexed token,
        uint256[2] minAmount,
        uint256[2] maxAmount,
        uint256[2] percent,
        uint256[2] minCharge,
        uint256[2] maxCharge
    );

    function initialize(
        address factory,
        address admin,
        address tokenFactory,
        address wMech,
        uint8 networkId,
        string memory networkName
    ) external;

    function factory() external view returns (address);

    function admin() external view returns (address);

    function network() external view returns (uint8, string memory);

    function activeTokenCount() external view returns (uint8);

    function crossToken(address crossToken)
        external
        view
        returns (string memory, string memory);

    function tokens(uint64 futureBlock, uint64 searchBlockIndex)
        external
        view
        returns (TokenData memory data);

    function blockScanRange() external view returns (uint64[] memory);

    function txHash(uint256 txHash) external view returns (bool);

    function setTokenConnection(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge
    ) external;

    function resetTokenConnection(address token, address crossToken) external;

    function processPack(
        uint64[2] memory blockScanRange,
        uint256[] memory txHashes,
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) external;

    function setScanRange(uint64[2] memory scanRange) external;
}

// File: contracts/library/BridgeUtilsV2.sol

pragma solidity ^0.8.7;

library BridgeUtilsV2 {
    uint256 internal constant FUTURE_BLOCK_INTERVAL = 100;
    uint256 public constant CHARGE_PERCENTAGE_DIVIDER = 10000;

    function roundFuture(uint256 blockIndex) internal pure returns (uint64) {
        uint256 _futureBlockIndex;
        if (blockIndex <= FUTURE_BLOCK_INTERVAL) {
            _futureBlockIndex = FUTURE_BLOCK_INTERVAL;
        } else {
            _futureBlockIndex =
                FUTURE_BLOCK_INTERVAL *
                ((blockIndex / FUTURE_BLOCK_INTERVAL) + 1);
        }
        return uint64(_futureBlockIndex);
    }

    function getFuture(uint256 blockIndex)
        internal
        pure
        returns (uint64 futureBlockIndex)
    {
        uint256 _futureBlockIndex;
        if (blockIndex <= FUTURE_BLOCK_INTERVAL) {
            _futureBlockIndex = 0;
        } else {
            _futureBlockIndex =
                FUTURE_BLOCK_INTERVAL *
                (blockIndex / FUTURE_BLOCK_INTERVAL);
        }
        return uint64(_futureBlockIndex);
    }

    function getBlockScanRange(
        uint16 count,
        uint8[] memory networks,
        mapping(uint8 => address) storage bridges
    )
        internal
        view
        returns (uint8[] memory _networks, uint64[][] memory _ranges)
    {
        _networks = new uint8[](count);
        _ranges = new uint64[][](count);
        uint64 k = 0;
        for (uint64 i = 0; i < networks.length; i++) {
            if (bridges[networks[i]] != address(0)) {
                _networks[k] = networks[i];
                _ranges[k] = IBridgeV2(bridges[networks[i]]).blockScanRange();
                k++;
            }
        }
    }

    function getTokenReq(
        uint64 futureBlock,
        address token,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    )
        internal
        view
        returns (
            uint256 minAmount,
            uint256 maxAmount,
            uint256 percent,
            uint256 minCharge,
            uint256 maxCharge
        )
    {
        TokenReq memory _req = getReq(
            futureBlock,
            token,
            futureBlocks,
            tokenReqs
        );
        minAmount = _req.minAmount;
        maxAmount = _req.maxAmount;
        percent = _req.chargePercent;
        minCharge = _req.minCharge;
        maxCharge = _req.maxCharge;
    }

    function updateMap(
        address[] memory arr,
        bool status,
        mapping(address => bool) storage map
    ) internal {
        for (uint64 i = 0; i < arr.length; i++) {
            map[arr[i]] = status;
        }
    }

    function getReq(
        uint64 blockIndex,
        address token,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    ) internal view returns (TokenReq memory req) {
        req = tokenReqs[token][blockIndex];
        if (!req.exist) {
            for (uint256 i = futureBlocks.length; i > 0; i--) {
                if (futureBlocks[i - 1] <= blockIndex) {
                    req = tokenReqs[token][futureBlocks[i - 1]];
                    if (req.exist) return req;
                }
            }
        }
    }

    function getCountBySearchIndex(
        uint64 searchBlockIndex,
        address[] memory tokens,
        mapping(address => bool) storage mapTokens,
        mapping(address => uint64) storage mapTokenCreatedBlockIndex
    ) internal view returns (uint64 k) {
        for (uint64 i = 0; i < tokens.length; i++) {
            if (
                mapTokens[tokens[i]] &&
                (mapTokenCreatedBlockIndex[tokens[i]] <= searchBlockIndex)
            ) {
                k++;
            }
        }
    }
}

// File: contracts/BaseCrossBridgeV2/interface/ICrossBridgeStorageV2.sol

pragma solidity ^0.8.7;

interface ICrossBridgeStorageV2 {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event SignersChanged(
        address[] indexed oldSigners,
        address[] indexed newSigners
    );

    event RelayersChanged(
        address[] indexed oldRelayers,
        address[] indexed newRelayers
    );

    function owner() external view returns (address);

    function admin() external view returns (address);

    function bridge() external view returns (address);

    function network() external view returns (NetworkInfo memory);

    function epoch() external view returns (uint64);

    function signers() external view returns (address[] memory);

    function relayers() external view returns (address[] memory);

    function mapSigner(address signer) external view returns (bool);

    function mapRelayer(address relayer) external view returns (bool);

    function setCallers(address admin, address bridge) external;

    function setEpoch(uint64 epoch) external;

    function setSigners(address[] memory signers_) external;

    function setRelayers(address[] memory relayers_) external;

    function signerVerification(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external view returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

// File: contracts/BaseCrossBridgeV2/base/CrossBridgeStorageUpgradeableV2.sol

pragma solidity ^0.8.7;

contract CrossBridgeStorageUpgradeableV2 is
    Initializable,
    OwnableUpgradeable,
    ICrossBridgeStorageV2
{
    using BridgeSecurity for *;
    using BridgeUtilsV2 for *;

    address private _admin;
    address private _bridge;

    NetworkInfo private _network;
    uint64 private _epoch;
    address[] private _signers;
    address[] private _relayers;
    mapping(address => bool) private _mapSigners;
    mapping(address => bool) private _mapRelayers;

    function __CrossBridgeStorage_init(
        uint8 networkId,
        string memory networkName
    ) internal initializer {
        __Ownable_init();
        _network.id = networkId;
        _network.name = networkName;
    }

    function owner()
        public
        view
        override(OwnableUpgradeable, ICrossBridgeStorageV2)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function admin() public view virtual override returns (address) {
        return _admin;
    }

    function bridge() public view virtual override returns (address) {
        return _bridge;
    }

    modifier onlyAllowedOwner() {
        require(msg.sender == bridge() || msg.sender == admin());
        _;
    }

    function network()
        external
        view
        virtual
        override
        returns (NetworkInfo memory)
    {
        return _network;
    }

    function epoch() external view virtual override returns (uint64) {
        return _epoch;
    }

    function signers()
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        return _signers;
    }

    function relayers()
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        return _relayers;
    }

    function mapSigner(address signer)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _mapSigners[signer];
    }

    function mapRelayer(address relayer)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _mapRelayers[relayer];
    }

    function setCallers(address admin_, address bridge_)
        external
        virtual
        override
        onlyOwner
    {
        _admin = admin_;
        _bridge = bridge_;
    }

    function setEpoch(uint64 epoch_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        _epoch = epoch_;
    }

    function setSigners(address[] memory signers_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        emit SignersChanged(_signers, signers_);
        BridgeUtilsV2.updateMap(_signers, false, _mapSigners);
        delete _signers;
        _signers = signers_;
        BridgeUtilsV2.updateMap(signers_, true, _mapSigners);
    }

    function setRelayers(address[] memory relayers_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        emit RelayersChanged(_relayers, relayers_);
        BridgeUtilsV2.updateMap(_relayers, false, _mapRelayers);
        delete _relayers;
        _relayers = relayers_;
        BridgeUtilsV2.updateMap(relayers_, true, _mapRelayers);
    }

    function signerVerification(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external view virtual override returns (bool) {
        return msgHash.signersVerification(v, r, s, _signers, _mapSigners);
    }
}

// File: contracts/Net-Ethereum/BridgeV2/EthereumBridgeStorageV2.sol

pragma solidity ^0.8.7;

contract EthereumBridgeStorageV2 is CrossBridgeStorageUpgradeableV2 {
    function initialize(uint8 networkId, string memory networkName)
        public
        initializer
    {
        __CrossBridgeStorage_init(networkId, networkName);
    }
}