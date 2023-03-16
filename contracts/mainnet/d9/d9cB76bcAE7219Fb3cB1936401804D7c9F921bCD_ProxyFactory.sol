// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistryAdminned is ISelfMulticall {
    function accessControlRegistry() external view returns (address);

    function adminRoleDescription() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlRegistryAdminned.sol";

interface IAccessControlRegistryAdminnedWithManager is
    IAccessControlRegistryAdminned
{
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDapiServer.sol";
import "./IBeaconUpdatesWithSignedData.sol";

interface IApi3ServerV1 is IOevDapiServer, IBeaconUpdatesWithSignedData {
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function dataFeeds(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IBeaconUpdatesWithSignedData is IDataFeedServer {
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bytes32 beaconId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../access-control-registry/interfaces/IAccessControlRegistryAdminnedWithManager.sol";
import "./IDataFeedServer.sol";

interface IDapiServer is
    IAccessControlRegistryAdminnedWithManager,
    IDataFeedServer
{
    event SetDapiName(
        bytes32 indexed dataFeedId,
        bytes32 indexed dapiName,
        address sender
    );

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function dapiNameSetterRole() external view returns (bytes32);

    function dapiNameHashToDataFeedId(
        bytes32 dapiNameHash
    ) external view returns (bytes32 dataFeedId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/IExtendedSelfMulticall.sol";

interface IDataFeedServer is IExtendedSelfMulticall {
    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) external returns (bytes32 beaconSetId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDataFeedServer.sol";
import "./IDapiServer.sol";

interface IOevDapiServer is IOevDataFeedServer, IDapiServer {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IOevDataFeedServer is IDataFeedServer {
    event UpdatedOevProxyBeaconWithSignedData(
        bytes32 indexed beaconId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedOevProxyBeaconSetWithSignedData(
        bytes32 indexed beaconSetId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event Withdrew(
        address indexed oevProxy,
        address oevBeneficiary,
        uint256 amount
    );

    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable;

    function withdraw(address oevProxy) external;

    function oevProxyToBalance(
        address oevProxy
    ) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDapiProxy.sol";
import "../interfaces/IApi3ServerV1.sol";

/// @title An immutable proxy contract that is used to read a specific dAPI of
/// a specific Api3ServerV1 contract
/// @notice In an effort to reduce the bytecode of this contract, its
/// constructor arguments are validated by ProxyFactory, rather than
/// internally. If you intend to deploy this contract without using
/// ProxyFactory, you are recommended to implement an equivalent validation.
/// @dev The proxy contracts are generalized to support most types of numerical
/// data feeds. This means that the user of this proxy is expected to validate
/// the read values according to the specific use-case. For example, `value` is
/// a signed integer, yet it being negative may not make sense in the case that
/// the data feed represents the spot price of an asset. In that case, the user
/// is responsible with ensuring that `value` is not negative.
/// In the case that the data feed is from a single source, `timestamp` is the
/// system time of the Airnode when it signed the data. In the case that the
/// data feed is from multiple sources, `timestamp` is the median of system
/// times of the Airnodes when they signed the respective data. There are two
/// points to consider while using `timestamp` in your contract logic: (1) It
/// is based on the system time of the Airnodes, and not the block timestamp.
/// This may be relevant when either of them drifts. (2) `timestamp` is an
/// off-chain value that is being reported, similar to `value`. Both should
/// only be trusted as much as the Airnode(s) that report them.
contract DapiProxy is IDapiProxy {
    /// @notice Api3ServerV1 address
    address public immutable override api3ServerV1;
    /// @notice Hash of the dAPI name
    bytes32 public immutable override dapiNameHash;

    /// @param _api3ServerV1 Api3ServerV1 address
    /// @param _dapiNameHash Hash of the dAPI name
    constructor(address _api3ServerV1, bytes32 _dapiNameHash) {
        api3ServerV1 = _api3ServerV1;
        dapiNameHash = _dapiNameHash;
    }

    /// @notice Reads the dAPI that this proxy maps to
    /// @return value dAPI value
    /// @return timestamp dAPI timestamp
    function read()
        external
        view
        virtual
        override
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = IApi3ServerV1(api3ServerV1)
            .readDataFeedWithDapiNameHash(dapiNameHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DapiProxy.sol";
import "./interfaces/IOevProxy.sol";

/// @title An immutable proxy contract that is used to read a specific dAPI of
/// a specific Api3ServerV1 contract and inform Api3ServerV1 about the
/// beneficiary of the respective OEV proceeds
/// @notice In an effort to reduce the bytecode of this contract, its
/// constructor arguments are validated by ProxyFactory, rather than
/// internally. If you intend to deploy this contract without using
/// ProxyFactory, you are recommended to implement an equivalent validation.
/// @dev See DapiProxy.sol for comments about usage
contract DapiProxyWithOev is DapiProxy, IOevProxy {
    /// @notice OEV beneficiary address
    address public immutable override oevBeneficiary;

    /// @param _api3ServerV1 Api3ServerV1 address
    /// @param _dapiNameHash Hash of the dAPI name
    /// @param _oevBeneficiary OEV beneficiary
    constructor(
        address _api3ServerV1,
        bytes32 _dapiNameHash,
        address _oevBeneficiary
    ) DapiProxy(_api3ServerV1, _dapiNameHash) {
        oevBeneficiary = _oevBeneficiary;
    }

    /// @notice Reads the dAPI that this proxy maps to
    /// @return value dAPI value
    /// @return timestamp dAPI timestamp
    function read()
        external
        view
        virtual
        override
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = IApi3ServerV1(api3ServerV1)
            .readDataFeedWithDapiNameHashAsOevProxy(dapiNameHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDataFeedProxy.sol";
import "../interfaces/IApi3ServerV1.sol";

/// @title An immutable proxy contract that is used to read a specific data
/// feed (Beacon or Beacon set) of a specific Api3ServerV1 contract
/// @notice In an effort to reduce the bytecode of this contract, its
/// constructor arguments are validated by ProxyFactory, rather than
/// internally. If you intend to deploy this contract without using
/// ProxyFactory, you are recommended to implement an equivalent validation.
/// @dev See DapiProxy.sol for comments about usage
contract DataFeedProxy is IDataFeedProxy {
    /// @notice Api3ServerV1 address
    address public immutable override api3ServerV1;
    /// @notice Data feed ID
    bytes32 public immutable override dataFeedId;

    /// @param _api3ServerV1 Api3ServerV1 address
    /// @param _dataFeedId Data feed (Beacon or Beacon set) ID
    constructor(address _api3ServerV1, bytes32 _dataFeedId) {
        api3ServerV1 = _api3ServerV1;
        dataFeedId = _dataFeedId;
    }

    /// @notice Reads the data feed that this proxy maps to
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function read()
        external
        view
        virtual
        override
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = IApi3ServerV1(api3ServerV1).readDataFeedWithId(
            dataFeedId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataFeedProxy.sol";
import "./interfaces/IOevProxy.sol";

/// @title An immutable proxy contract that is used to read a specific data
/// feed (Beacon or Beacon set) of a specific Api3ServerV1 contract and inform
/// Api3ServerV1 about the beneficiary of the respective OEV proceeds
/// @notice In an effort to reduce the bytecode of this contract, its
/// constructor arguments are validated by ProxyFactory, rather than
/// internally. If you intend to deploy this contract without using
/// ProxyFactory, you are recommended to implement an equivalent validation.
/// @dev See DapiProxy.sol for comments about usage
contract DataFeedProxyWithOev is DataFeedProxy, IOevProxy {
    /// @notice OEV beneficiary address
    address public immutable override oevBeneficiary;

    /// @param _api3ServerV1 Api3ServerV1 address
    /// @param _dataFeedId Data feed (Beacon or Beacon set) ID
    /// @param _oevBeneficiary OEV beneficiary
    constructor(
        address _api3ServerV1,
        bytes32 _dataFeedId,
        address _oevBeneficiary
    ) DataFeedProxy(_api3ServerV1, _dataFeedId) {
        oevBeneficiary = _oevBeneficiary;
    }

    /// @notice Reads the data feed that this proxy maps to
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function read()
        external
        view
        virtual
        override
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = IApi3ServerV1(api3ServerV1)
            .readDataFeedWithIdAsOevProxy(dataFeedId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProxy.sol";

interface IDapiProxy is IProxy {
    function dapiNameHash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProxy.sol";

interface IDataFeedProxy is IProxy {
    function dataFeedId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOevProxy {
    function oevBeneficiary() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyFactory {
    event DeployedDataFeedProxy(
        address indexed proxyAddress,
        bytes32 indexed dataFeedId,
        bytes metadata
    );

    event DeployedDapiProxy(
        address indexed proxyAddress,
        bytes32 indexed dapiName,
        bytes metadata
    );

    event DeployedDataFeedProxyWithOev(
        address indexed proxyAddress,
        bytes32 indexed dataFeedId,
        address oevBeneficiary,
        bytes metadata
    );

    event DeployedDapiProxyWithOev(
        address indexed proxyAddress,
        bytes32 indexed dapiName,
        address oevBeneficiary,
        bytes metadata
    );

    function deployDataFeedProxy(
        bytes32 dataFeedId,
        bytes calldata metadata
    ) external returns (address proxyAddress);

    function deployDapiProxy(
        bytes32 dapiName,
        bytes calldata metadata
    ) external returns (address proxyAddress);

    function deployDataFeedProxyWithOev(
        bytes32 dataFeedId,
        address oevBeneficiary,
        bytes calldata metadata
    ) external returns (address proxyAddress);

    function deployDapiProxyWithOev(
        bytes32 dapiName,
        address oevBeneficiary,
        bytes calldata metadata
    ) external returns (address proxyAddress);

    function computeDataFeedProxyAddress(
        bytes32 dataFeedId,
        bytes calldata metadata
    ) external view returns (address proxyAddress);

    function computeDapiProxyAddress(
        bytes32 dapiName,
        bytes calldata metadata
    ) external view returns (address proxyAddress);

    function computeDataFeedProxyWithOevAddress(
        bytes32 dataFeedId,
        address oevBeneficiary,
        bytes calldata metadata
    ) external view returns (address proxyAddress);

    function computeDapiProxyWithOevAddress(
        bytes32 dapiName,
        address oevBeneficiary,
        bytes calldata metadata
    ) external view returns (address proxyAddress);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataFeedProxy.sol";
import "./DapiProxy.sol";
import "./DataFeedProxyWithOev.sol";
import "./DapiProxyWithOev.sol";
import "./interfaces/IProxyFactory.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/// @title Contract factory that deterministically deploys proxies that read
/// data feeds (Beacons or Beacon sets) or dAPIs, along with optional OEV
/// support
/// @dev The proxies are deployed normally and not cloned to minimize the gas
/// cost overhead while using them to read data feed values
contract ProxyFactory is IProxyFactory {
    /// @notice Api3ServerV1 address
    address public immutable override api3ServerV1;

    /// @param _api3ServerV1 Api3ServerV1 address
    constructor(address _api3ServerV1) {
        require(_api3ServerV1 != address(0), "Api3ServerV1 address zero");
        api3ServerV1 = _api3ServerV1;
    }

    /// @notice Deterministically deploys a data feed proxy
    /// @param dataFeedId Data feed ID
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function deployDataFeedProxy(
        bytes32 dataFeedId,
        bytes calldata metadata
    ) external override returns (address proxyAddress) {
        require(dataFeedId != bytes32(0), "Data feed ID zero");
        proxyAddress = address(
            new DataFeedProxy{salt: keccak256(metadata)}(
                api3ServerV1,
                dataFeedId
            )
        );
        emit DeployedDataFeedProxy(proxyAddress, dataFeedId, metadata);
    }

    /// @notice Deterministically deploys a dAPI proxy
    /// @param dapiName dAPI name
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function deployDapiProxy(
        bytes32 dapiName,
        bytes calldata metadata
    ) external override returns (address proxyAddress) {
        require(dapiName != bytes32(0), "dAPI name zero");
        proxyAddress = address(
            new DapiProxy{salt: keccak256(metadata)}(
                api3ServerV1,
                keccak256(abi.encodePacked(dapiName))
            )
        );
        emit DeployedDapiProxy(proxyAddress, dapiName, metadata);
    }

    /// @notice Deterministically deploys a data feed proxy with OEV support
    /// @param dataFeedId Data feed ID
    /// @param oevBeneficiary OEV beneficiary
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function deployDataFeedProxyWithOev(
        bytes32 dataFeedId,
        address oevBeneficiary,
        bytes calldata metadata
    ) external override returns (address proxyAddress) {
        require(dataFeedId != bytes32(0), "Data feed ID zero");
        require(oevBeneficiary != address(0), "OEV beneficiary zero");
        proxyAddress = address(
            new DataFeedProxyWithOev{salt: keccak256(metadata)}(
                api3ServerV1,
                dataFeedId,
                oevBeneficiary
            )
        );
        emit DeployedDataFeedProxyWithOev(
            proxyAddress,
            dataFeedId,
            oevBeneficiary,
            metadata
        );
    }

    /// @notice Deterministically deploys a dAPI proxy with OEV support
    /// @param dapiName dAPI name
    /// @param oevBeneficiary OEV beneficiary
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function deployDapiProxyWithOev(
        bytes32 dapiName,
        address oevBeneficiary,
        bytes calldata metadata
    ) external override returns (address proxyAddress) {
        require(dapiName != bytes32(0), "dAPI name zero");
        require(oevBeneficiary != address(0), "OEV beneficiary zero");
        proxyAddress = address(
            new DapiProxyWithOev{salt: keccak256(metadata)}(
                api3ServerV1,
                keccak256(abi.encodePacked(dapiName)),
                oevBeneficiary
            )
        );
        emit DeployedDapiProxyWithOev(
            proxyAddress,
            dapiName,
            oevBeneficiary,
            metadata
        );
    }

    /// @notice Computes the address of the data feed proxy
    /// @param dataFeedId Data feed ID
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function computeDataFeedProxyAddress(
        bytes32 dataFeedId,
        bytes calldata metadata
    ) external view override returns (address proxyAddress) {
        require(dataFeedId != bytes32(0), "Data feed ID zero");
        proxyAddress = Create2.computeAddress(
            keccak256(metadata),
            keccak256(
                abi.encodePacked(
                    type(DataFeedProxy).creationCode,
                    abi.encode(api3ServerV1, dataFeedId)
                )
            )
        );
    }

    /// @notice Computes the address of the dAPI proxy
    /// @param dapiName dAPI name
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function computeDapiProxyAddress(
        bytes32 dapiName,
        bytes calldata metadata
    ) external view override returns (address proxyAddress) {
        require(dapiName != bytes32(0), "dAPI name zero");
        proxyAddress = Create2.computeAddress(
            keccak256(metadata),
            keccak256(
                abi.encodePacked(
                    type(DapiProxy).creationCode,
                    abi.encode(
                        api3ServerV1,
                        keccak256(abi.encodePacked(dapiName))
                    )
                )
            )
        );
    }

    /// @notice Computes the address of the data feed proxy with OEV support
    /// @param dataFeedId Data feed ID
    /// @param oevBeneficiary OEV beneficiary
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function computeDataFeedProxyWithOevAddress(
        bytes32 dataFeedId,
        address oevBeneficiary,
        bytes calldata metadata
    ) external view override returns (address proxyAddress) {
        require(dataFeedId != bytes32(0), "Data feed ID zero");
        require(oevBeneficiary != address(0), "OEV beneficiary zero");
        proxyAddress = Create2.computeAddress(
            keccak256(metadata),
            keccak256(
                abi.encodePacked(
                    type(DataFeedProxyWithOev).creationCode,
                    abi.encode(api3ServerV1, dataFeedId, oevBeneficiary)
                )
            )
        );
    }

    /// @notice Computes the address of the dAPI proxy with OEV support
    /// @param dapiName dAPI name
    /// @param oevBeneficiary OEV beneficiary
    /// @param metadata Metadata associated with the proxy
    /// @return proxyAddress Proxy address
    function computeDapiProxyWithOevAddress(
        bytes32 dapiName,
        address oevBeneficiary,
        bytes calldata metadata
    ) external view override returns (address proxyAddress) {
        require(dapiName != bytes32(0), "dAPI name zero");
        require(oevBeneficiary != address(0), "OEV beneficiary zero");
        proxyAddress = Create2.computeAddress(
            keccak256(metadata),
            keccak256(
                abi.encodePacked(
                    type(DapiProxyWithOev).creationCode,
                    abi.encode(
                        api3ServerV1,
                        keccak256(abi.encodePacked(dapiName)),
                        oevBeneficiary
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISelfMulticall.sol";

interface IExtendedSelfMulticall is ISelfMulticall {
    function getChainId() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function containsBytecode(address account) external view returns (bool);

    function getBlockNumber() external view returns (uint256);

    function getBlockTimestamp() external view returns (uint256);

    function getBlockBasefee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISelfMulticall {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory returndata);

    function tryMulticall(
        bytes[] calldata data
    ) external returns (bool[] memory successes, bytes[] memory returndata);
}