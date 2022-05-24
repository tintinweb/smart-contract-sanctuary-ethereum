// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IManagedIndexFactory.sol";

import "./ManagedIndex.sol";
import "./BaseIndexFactory.sol";

/// @title Managed index factory
/// @notice Contains logic for managed index creation
contract ManagedIndexFactory is IManagedIndexFactory, BaseIndexFactory {
    using ERC165Checker for address;

    constructor(
        address _registry,
        address _vTokenFactory,
        address _reweightingLogic,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    )
        BaseIndexFactory(
            _registry,
            _vTokenFactory,
            _reweightingLogic,
            _defaultMintingFeeInBP,
            _defaultBurningFeeInBP,
            _defaultAUMScaledPerSecondsRate
        )
    {
        require(
            _reweightingLogic.supportsInterface(type(IManagedIndexReweightingLogic).interfaceId),
            "ManagedIndexFactory: INTERFACE"
        );
    }

    /// @inheritdoc IIndexFactory
    function setReweightingLogic(address _reweightingLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(
            _reweightingLogic.supportsInterface(type(IManagedIndexReweightingLogic).interfaceId),
            "ManagedIndexFactory: INTERFACE"
        );

        reweightingLogic = _reweightingLogic;
    }

    /// @inheritdoc IManagedIndexFactory
    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external override onlyRole(INDEX_CREATOR_ROLE) returns (address index) {
        uint assetsCount = _assets.length;
        require(assetsCount > 1 && assetsCount == _weights.length, "ManagedIndexFactory: LENGTH");
        require(assetsCount <= IIndexRegistry(registry).maxComponents(), "ManagedIndexFactory: COMPONENTS");

        uint _totalWeight;

        for (uint i; i < assetsCount; ) {
            address asset = _assets[i];
            if (i != 0) {
                // makes sure that there are no duplicate assets
                require(_assets[i - 1] < asset, "ManagedIndexFactory: SORT");
            }

            uint8 weight = _weights[i];
            require(weight != 0, "ManagedIndexFactory: INVALID");

            require(IAccessControl(registry).hasRole(ASSET_ROLE, asset), "ManagedIndexFactory: INVALID");

            _totalWeight += weight;

            unchecked {
                i = i + 1;
            }
        }

        require(_totalWeight == IndexLibrary.MAX_WEIGHT, "ManagedIndexFactory: MAX");

        bytes32 salt = keccak256(abi.encodePacked(_nameDetails.name, _nameDetails.symbol));
        index = Create2.computeAddress(salt, keccak256(type(ManagedIndex).creationCode));
        IIndexRegistry(registry).registerIndex(index, _nameDetails);
        Create2.deploy(0, salt, type(ManagedIndex).creationCode);

        IFeePool.MintBurnInfo[] memory mintInfo = new IFeePool.MintBurnInfo[](1);
        mintInfo[0] = IFeePool.MintBurnInfo(index, BP.DECIMAL_FACTOR);

        IFeePool(IIndexRegistry(registry).feePool()).initializeIndex(
            index,
            defaultMintingFeeInBP,
            defaultBurningFeeInBP,
            defaultAUMScaledPerSecondsRate,
            mintInfo
        );

        ManagedIndex(index).initialize(_assets, _weights);

        emit ManagedIndexCreated(index, _assets, _weights);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndexFactory).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

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
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
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
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Managed index factory interface
/// @notice Provides method for index creation
interface IManagedIndexFactory is IIndexFactory {
    event ManagedIndexCreated(address index, address[] _assets, uint8[] _weights);

    /// @notice Create managed index with assets and their weights
    /// @param _assets Assets list for the index
    /// @param _weights List of assets corresponding weights. Assets total weight should be equal to 255
    /// @param _nameDetails Name details data (name and symbol) to use for the created index
    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external returns (address index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./interfaces/IManagedIndex.sol";
import "./interfaces/IManagedIndexFactory.sol";
import "./interfaces/IManagedIndexReweightingLogic.sol";

import "./BaseIndex.sol";

/// @title Managed index
/// @notice Contains initialization and reweighting logic
contract ManagedIndex is IManagedIndex, BaseIndex {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Role for index reweighting
    bytes32 internal immutable REWEIGH_INDEX_ROLE;

    constructor() BaseIndex(msg.sender) {
        REWEIGH_INDEX_ROLE = keccak256(abi.encodePacked("REWEIGHT_PERMISSION", address(this)));
    }

    /// @notice Index initialization with assets and their weights
    /// @param _assets Assets list for the index
    /// @param _weights List of assets corresponding weights
    /// @dev Method is called by factory contract only
    function initialize(address[] calldata _assets, uint8[] calldata _weights) external {
        require(msg.sender == factory, "ManagedIndex: FORBIDDEN");

        uint assetsCount = _assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _assets[i];
            uint8 weight = _weights[i];

            weightOf[asset] = weight;
            assets.add(asset);

            emit UpdateAnatomy(asset, weight);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IManagedIndex
    /// @dev Assets total weight should be equal to 255
    function reweight(address[] calldata _updatedAssets, uint8[] calldata _updatedWeights) external override {
        require(
            IAccessControl(registry).hasRole(INDEX_MANAGER_ROLE, msg.sender) ||
                IAccessControl(registry).hasRole(REWEIGH_INDEX_ROLE, msg.sender),
            "ManagedIndex: FORBIDDEN"
        );

        (bool success, bytes memory data) = IManagedIndexFactory(factory).reweightingLogic().delegatecall(
            abi.encodeWithSelector(IManagedIndexReweightingLogic.reweight.selector, _updatedAssets, _updatedWeights)
        );
        if (!success) {
            if (data.length == 0) {
                revert("ManagedIndex: REWEIGH_FAILED");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndex).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/BP.sol";
import "./libraries/AUMCalculationLibrary.sol";

import "./interfaces/IIndexFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IvTokenFactory.sol";

/// @title Base index factory
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
/// @dev Specified fee is minted to factory address and could be withdrawn through withdrawToFeePool method
abstract contract BaseIndexFactory is IIndexFactory, ERC165 {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// @notice 10% in base point format
    uint public constant MAX_FEE_IN_BP = 1000;

    /// @notice 10% in AUM Scaled units
    uint public constant MAX_AUM_FEE = 1000000003340960040392850629;

    /// @notice Role allows configure index related data/components
    bytes32 internal immutable INDEX_MANAGER_ROLE;
    /// @notice Role allows configure fee related data/components
    bytes32 internal immutable FEE_MANAGER_ROLE;
    /// @notice Asset role
    bytes32 internal immutable ASSET_ROLE;
    /// @notice Role allows index creation
    bytes32 internal immutable INDEX_CREATOR_ROLE;

    /// @inheritdoc IIndexFactory
    uint public override defaultAUMScaledPerSecondsRate;
    /// @inheritdoc IIndexFactory
    uint16 public override defaultMintingFeeInBP;
    /// @inheritdoc IIndexFactory
    uint16 public override defaultBurningFeeInBP;

    /// @inheritdoc IIndexFactory
    address public override reweightingLogic;
    /// @inheritdoc IIndexFactory
    address public immutable override registry;
    /// @inheritdoc IIndexFactory
    address public immutable override vTokenFactory;

    /// @notice Checks if provided value is lower than 10% in base point format
    modifier isValidFee(uint16 _value) {
        require(_value <= MAX_FEE_IN_BP, "IndexFactory: INVALID");
        _;
    }

    /// @notice Checks if msg.sender has administrator's permissions
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "IndexFactory: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address _vTokenFactory,
        address _reweightingLogic,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    ) {
        require(
            _defaultMintingFeeInBP <= MAX_FEE_IN_BP &&
                _defaultBurningFeeInBP <= MAX_FEE_IN_BP &&
                _defaultAUMScaledPerSecondsRate <= MAX_AUM_FEE &&
                _defaultAUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE,
            "IndexFactory: INVALID"
        );

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(
            _vTokenFactory.supportsInterface(type(IvTokenFactory).interfaceId) &&
                _registry.supportsAllInterfaces(interfaceIds),
            "IndexFactory: INTERFACE"
        );

        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
        FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
        ASSET_ROLE = keccak256("ASSET_ROLE");
        INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");

        registry = _registry;
        vTokenFactory = _vTokenFactory;
        defaultMintingFeeInBP = _defaultMintingFeeInBP;
        defaultBurningFeeInBP = _defaultBurningFeeInBP;
        defaultAUMScaledPerSecondsRate = _defaultAUMScaledPerSecondsRate;
        reweightingLogic = _reweightingLogic;

        emit SetVTokenFactory(_vTokenFactory);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
        isValidFee(_mintingFeeInBP)
    {
        defaultMintingFeeInBP = _mintingFeeInBP;
        emit SetDefaultMintingFeeInBP(msg.sender, _mintingFeeInBP);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
        isValidFee(_burningFeeInBP)
    {
        defaultBurningFeeInBP = _burningFeeInBP;
        emit SetDefaultBurningFeeInBP(msg.sender, _burningFeeInBP);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        require(
            _AUMScaledPerSecondsRate <= MAX_AUM_FEE &&
                _AUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE,
            "IndexFactory: INVALID"
        );

        defaultAUMScaledPerSecondsRate = _AUMScaledPerSecondsRate;
        emit SetDefaultAUMScaledPerSecondsRate(msg.sender, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IIndexFactory
    function withdrawToFeePool(address _index) external override {
        require(msg.sender == IIndexRegistry(registry).feePool(), "IndexFactory: FORBIDDEN");

        uint amount = IERC20(_index).balanceOf(address(this));
        if (amount != 0) {
            IERC20(_index).safeTransfer(msg.sender, amount);
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexFactory).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index factory interface
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
interface IIndexFactory {
    struct NameDetails {
        string name;
        string symbol;
    }

    event SetVTokenFactory(address vTokenFactory);
    event SetDefaultMintingFeeInBP(address indexed account, uint16 mintingFeeInBP);
    event SetDefaultBurningFeeInBP(address indexed account, uint16 burningFeeInBP);
    event SetDefaultAUMScaledPerSecondsRate(address indexed account, uint AUMScaledPerSecondsRate);

    /// @notice Sets default index minting fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _mintingFeeInBP New minting fee value
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP) external;

    /// @notice Sets default index burning fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _burningFeeInBP New burning fee value
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP) external;

    /// @notice Sets reweighting logic address
    /// @param _reweightingLogic Reweighting logic address
    function setReweightingLogic(address _reweightingLogic) external;

    /// @notice Sets default AUM scaled per seconds rate that will be used for fee calculation
    /**
        @dev Will be set in FeePool on index creation.
        Effective management fee rate (annual, in percent, after dilution) is calculated by the given formula:
        fee = (rpow(scaledPerSecondRate, numberOfSeconds, 10*27) - 10**27) * totalSupply / 10**27, where:

        totalSupply - total index supply;
        numberOfSeconds - delta time for calculation period;
        scaledPerSecondRate - scaled rate, calculated off chain by the given formula:

        scaledPerSecondRate = ((1 + k) ** (1 / 365 days)) * AUMCalculationLibrary.RATE_SCALE_BASE, where:
        k = (aumFeeInBP / BP) / (1 - aumFeeInBP / BP);

        Note: rpow and RATE_SCALE_BASE are provided by AUMCalculationLibrary
        More info: https://docs.enzyme.finance/fee-formulas/management-fee

        After value calculated off chain, scaledPerSecondRate is set to setDefaultAUMScaledPerSecondsRate
    */
    /// @param _AUMScaledPerSecondsRate New AUM scaled per seconds rate
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate) external;

    /// @notice Withdraw fee balance to fee pool for a given index
    /// @param _index Index to withdraw fee balance from
    function withdrawToFeePool(address _index) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Minting fee in base point (BP) format
    /// @return Returns minting fee in base point (BP) format
    function defaultMintingFeeInBP() external view returns (uint16);

    /// @notice Burning fee in base point (BP) format
    /// @return Returns burning fee in base point (BP) format
    function defaultBurningFeeInBP() external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    ///         See setDefaultAUMScaledPerSecondsRate method description for more details.
    /// @return Returns AUM scaled per seconds rate
    function defaultAUMScaledPerSecondsRate() external view returns (uint);

    /// @notice Reweighting logic address
    /// @return Returns reweighting logic address
    function reweightingLogic() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndex.sol";

/// @title Managed index interface
/// @notice Interface for dynamic indexes that could be updated with new anatomy data
interface IManagedIndex is IIndex {
    /// @notice Updates index anatomy with corresponding weights and assets
    /// @param _assets List for new asset(s) for the index
    /// @param _weights List of new asset(s) corresponding weights
    function reweight(address[] calldata _assets, uint8[] calldata _weights) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IAnatomyUpdater.sol";

/// @title ManagedIndex reweighing logic interface
/// @notice Contains reweighing logic
interface IManagedIndexReweightingLogic is IAnatomyUpdater {
    /// @notice Updates index anatomy with corresponding weights and assets
    /// @param _assets List for new asset(s) for the index
    /// @param _weights List of new asset(s) corresponding weights
    function reweight(address[] calldata _assets, uint8[] calldata _weights) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/IndexLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IIndexLogic.sol";
import "./interfaces/IIndexFactory.sol";

import "./PhutureIndex.sol";

/// @title Base index
/// @notice Contains common logic for all indices
abstract contract BaseIndex is PhutureIndex, ReentrancyGuard, IIndex {
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Role allows configure index related data/components
    bytes32 internal immutable INDEX_MANAGER_ROLE;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "Index: FORBIDDEN");
        _;
    }

    constructor(address _factory) {
        require(_factory.supportsInterface(type(IIndexFactory).interfaceId), "Index: INTERFACE");

        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

        factory = _factory;
        lastTransferTime = uint96(block.timestamp);
        registry = IIndexFactory(_factory).registry();
        vTokenFactory = IIndexFactory(_factory).vTokenFactory();
    }

    /// @inheritdoc IIndex
    function mint(address _recipient) external override nonReentrant {
        (bool success, bytes memory data) = IIndexRegistry(registry).indexLogic().delegatecall(
            abi.encodeWithSelector(IIndexLogic.mint.selector, _recipient)
        );
        if (!success) {
            if (data.length == 0) {
                revert("Index: MINT_FAILED");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    /// @inheritdoc IIndex
    function burn(address _recipient) external override nonReentrant {
        (bool success, bytes memory data) = IIndexRegistry(registry).indexLogic().delegatecall(
            abi.encodeWithSelector(IIndexLogic.burn.selector, _recipient)
        );
        if (!success) {
            if (data.length == 0) {
                revert("Index: BURN_FAILED");
            } else {
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    /// @inheritdoc IIndex
    function anatomy() external view override returns (address[] memory _assets, uint8[] memory _weights) {
        _assets = assets.values();
        uint assetsCount = _assets.length;
        _weights = new uint8[](assetsCount);

        for (uint i; i < assetsCount; ) {
            _weights[i] = weightOf[_assets[i]];

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndex
    function inactiveAnatomy() external view override returns (address[] memory) {
        return inactiveAssets.values();
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndex).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexLayout.sol";
import "./IAnatomyUpdater.sol";

/// @title Index interface
/// @notice Interface containing basic logic for indexes: mint, burn, anatomy info
interface IIndex is IIndexLayout, IAnatomyUpdater {
    /// @notice Index minting
    /// @param _recipient Recipient address
    function mint(address _recipient) external;

    /// @notice Index burning
    /// @param _recipient Recipient address
    function burn(address _recipient) external;

    /// @notice Returns index assets weights information
    /// @return _assets Assets list
    /// @return _weights List of assets corresponding weights
    function anatomy() external view returns (address[] memory _assets, uint8[] memory _weights);

    /// @notice Returns inactive assets
    /// @return Assets list
    function inactiveAnatomy() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index layout interface
/// @notice Contains storage layout of index
interface IIndexLayout {
    /// @notice Index factory address
    /// @return Returns index factory address
    function factory() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Registry address
    /// @return Returns registry address
    function registry() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Anatomy Updater interface
/// @notice Contains event for aatomy update
interface IAnatomyUpdater {
    event UpdateAnatomy(address asset, uint8 weight);
    event AssetRemoved(address asset);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./FullMath.sol";
import "./FixedPoint112.sol";

/// @title Index library
/// @notice Provides various utilities for indexes
library IndexLibrary {
    using FullMath for uint;

    /// @notice Initial index quantity to mint
    uint constant INITIAL_QUANTITY = 10000;

    /// @notice Total assets weight within an index
    uint8 constant MAX_WEIGHT = type(uint8).max;

    /// @notice Returns amount of asset equivalent to the given parameters
    /// @param _assetPerBaseInUQ Asset per base price in UQ
    /// @param _weight Weight of the given asset
    /// @param _amountInBase Total assets amount in base
    /// @return Amount of asset
    function amountInAsset(
        uint _assetPerBaseInUQ,
        uint8 _weight,
        uint _amountInBase
    ) internal pure returns (uint) {
        require(_assetPerBaseInUQ != 0, "IndexLibrary: ORACLE");

        return ((_amountInBase * _weight) / MAX_WEIGHT).mulDiv(_assetPerBaseInUQ, FixedPoint112.Q112);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index logic interface
/// @notice Contains mint and burn logic
interface IIndexLogic {
    /// @notice Index minting
    /// @param _recipient Recipient address
    function mint(address _recipient) external;

    /// @notice Index burning
    /// @param _recipient Recipient address
    function burn(address _recipient) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./libraries/AUMCalculationLibrary.sol";

import "./interfaces/IFeePool.sol";
import "./interfaces/INameRegistry.sol";
import "./interfaces/IIndexRegistry.sol";

import "./IndexLayout.sol";

/// @title Phuture index
/// @notice Contains AUM fee's logic, overrides name and symbol
abstract contract PhutureIndex is IndexLayout, ERC20Permit, ERC165 {
    constructor() ERC20Permit("PhutureIndex") ERC20("", "") {}

    /// @notice Index symbol
    /// @return Returns index symbol
    function symbol() public view override returns (string memory) {
        return INameRegistry(registry).symbolOfIndex(address(this));
    }

    /// @notice Index name
    /// @return Returns index name
    function name() public view override returns (string memory) {
        return INameRegistry(registry).nameOfIndex(address(this));
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IIndexLayout).interfaceId ||
            _interfaceId == type(IERC20Permit).interfaceId ||
            _interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @dev Overrides _transfer to include AUM fee logic
    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal override {
        _chargeAUMFee(IIndexRegistry(registry).feePool());
        super._transfer(_from, _to, _value);
    }

    /// @notice Calculates and mints AUM fee
    /// @param _feePool Fee pool address
    function _chargeAUMFee(address _feePool) internal {
        uint timePassed = uint96(block.timestamp) - lastTransferTime;
        if (timePassed != 0) {
            address _factory = factory;
            uint fee = ((totalSupply() - balanceOf(_factory)) *
                (AUMCalculationLibrary.rpow(
                    IFeePool(_feePool).AUMScaledPerSecondsRateOf(address(this)),
                    timePassed,
                    AUMCalculationLibrary.RATE_SCALE_BASE
                ) - AUMCalculationLibrary.RATE_SCALE_BASE)) / AUMCalculationLibrary.RATE_SCALE_BASE;

            if (fee != 0) {
                super._mint(_factory, fee);
                lastTransferTime = uint96(block.timestamp);
            }
        }
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
pragma solidity 0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title FixedPoint112
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint112 {
    uint8 internal constant RESOLUTION = 112;
    /// @dev 2**112
    uint256 internal constant Q112 = 0x10000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title AUM fee calculation library
/// @notice More details https://github.com/enzymefinance/protocol/blob/b671b3dfea92596dd2e962c73b233dcdb22bf753/contracts/release/utils/MakerDaoMath.sol
/// @dev Taken from https://github.com/enzymefinance/protocol
library AUMCalculationLibrary {
    /// @dev A constant used for AUM fee calculation to prevent underflow
    uint constant RATE_SCALE_BASE = 1e27;

    /// @notice Power function for AUM fee calculation
    /// @param _x Base number
    /// @param _n Exponent number
    /// @param _base Base number multiplier
    /// @return z_ Returns value of `_x` raised to power of `_n`
    function rpow(
        uint _x,
        uint _n,
        uint _base
    ) internal pure returns (uint z_) {
        assembly {
            switch _x
            case 0 {
                switch _n
                case 0 {
                    z_ := _base
                }
                default {
                    z_ := 0
                }
            }
            default {
                switch mod(_n, 2)
                case 0 {
                    z_ := _base
                }
                default {
                    z_ := _x
                }
                let half := div(_base, 2)
                for {
                    _n := div(_n, 2)
                } _n {
                    _n := div(_n, 2)
                } {
                    let xx := mul(_x, _x)
                    if iszero(eq(div(xx, _x), _x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    _x := div(xxRound, _base)
                    if mod(_n, 2) {
                        let zx := mul(z_, _x)
                        if and(iszero(iszero(_x)), iszero(eq(div(zx, _x), z_))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z_ := div(zxRound, _base)
                    }
                }
            }
        }

        return z_;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Fee pool interface
/// @notice Provides methods for fee management
interface IFeePool {
    struct MintBurnInfo {
        address recipient;
        uint share;
    }

    event Mint(address indexed index, address indexed recipient, uint share);
    event Burn(address indexed index, address indexed recipient, uint share);
    event SetMintingFeeInBP(address indexed account, address indexed index, uint16 mintingFeeInBP);
    event SetBurningFeeInBP(address indexed account, address indexed index, uint16 burningFeeInPB);
    event SetAUMScaledPerSecondsRate(address indexed account, address indexed index, uint AUMScaledPerSecondsRate);

    event Withdraw(address indexed index, address indexed recipient, uint amount);

    /// @notice Initializes FeePool with the given params
    /// @param _registry Index registry address
    function initialize(address _registry) external;

    /// @notice Initializes index with provided fees and makes initial mint
    /// @param _index Index to initialize
    /// @param _mintingFeeInBP Minting fee to initialize with
    /// @param _burningFeeInBP Burning fee to initialize with
    /// @param _AUMScaledPerSecondsRate Aum scaled per second rate to initialize with
    /// @param _mintInfo Mint info object array containing mint recipient and amount for initial mint
    function initializeIndex(
        address _index,
        uint16 _mintingFeeInBP,
        uint16 _burningFeeInBP,
        uint _AUMScaledPerSecondsRate,
        MintBurnInfo[] calldata _mintInfo
    ) external;

    /// @notice Mints fee pool shares to the given recipient in specified amount
    /// @param _index Index to mint fee pool's shares for
    /// @param _mintInfo Mint info object containing mint recipient and amount
    function mint(address _index, MintBurnInfo calldata _mintInfo) external;

    /// @notice Burns fee pool shares to the given recipient in specified amount
    /// @param _index Index to burn fee pool's shares for
    /// @param _burnInfo Burn info object containing burn recipient and amount
    function burn(address _index, MintBurnInfo calldata _burnInfo) external;

    /// @notice Mints fee pool shares to the given recipients in specified amounts
    /// @param _index Index to mint fee pool's shares for
    /// @param _mintInfo Mint info object array containing mint recipients and amounts
    function mintMultiple(address _index, MintBurnInfo[] calldata _mintInfo) external;

    /// @notice Burns fee pool shares to the given recipients in specified amounts
    /// @param _index Index to burn fee pool's shares for
    /// @param _burnInfo Burn info object array containing burn recipients and amounts
    function burnMultiple(address _index, MintBurnInfo[] calldata _burnInfo) external;

    /// @notice Sets index minting fee in base point format
    /// @param _index Index to set minting fee for
    /// @param _mintingFeeInBP New minting fee value
    function setMintingFeeInBP(address _index, uint16 _mintingFeeInBP) external;

    /// @notice Sets index burning fee in base point format
    /// @param _index Index to set burning fee for
    /// @param _burningFeeInBP New burning fee value
    function setBurningFeeInBP(address _index, uint16 _burningFeeInBP) external;

    /// @notice Sets AUM scaled per seconds rate that will be used for fee calculation
    /// @param _index Index to set AUM scaled per seconds rate for
    /// @param _AUMScaledPerSecondsRate New AUM scaled per seconds rate
    function setAUMScaledPerSecondsRate(address _index, uint _AUMScaledPerSecondsRate) external;

    /// @notice Withdraws sender fees from the given index
    /// @param _index Index to withdraw fees from
    function withdraw(address _index) external;

    /// @notice Withdraws platform fees from the given index to specified address
    /// @param _index Index to withdraw fees from
    /// @param _recipient Recipient to send fees to
    function withdrawPlatformFeeOf(address _index, address _recipient) external;

    /// @notice Total shares in the given index
    /// @return Returns total shares in the given index
    function totalSharesOf(address _index) external view returns (uint);

    /// @notice Shares of specified recipient in the given index
    /// @return Returns shares of specified recipient in the given index
    function shareOf(address _index, address _account) external view returns (uint);

    /// @notice Minting fee in base point format
    /// @return Returns minting fee in base point (BP) format
    function mintingFeeInBPOf(address _index) external view returns (uint16);

    /// @notice Burning fee in base point format
    /// @return Returns burning fee in base point (BP) format
    function burningFeeInBPOf(address _index) external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    /// @return Returns AUM scaled per seconds rate
    function AUMScaledPerSecondsRateOf(address _index) external view returns (uint);

    /// @notice Returns withdrawable amount for specified account from given index
    /// @param _index Index to check withdrawable amount
    /// @param _account Recipient to check withdrawable amount for
    function withdrawableAmountOf(address _index, address _account) external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Name registry interface
/// @notice Providing information about index names and symbols
interface INameRegistry {
    event SetName(address index, string name);
    event SetSymbol(address index, string name);

    /// @notice Sets name of the given index
    /// @param _index Index address
    /// @param _name New index name
    function setIndexName(address _index, string calldata _name) external;

    /// @notice Sets symbol for the given index
    /// @param _index Index address
    /// @param _symbol New index symbol
    function setIndexSymbol(address _index, string calldata _symbol) external;

    /// @notice Returns index address by name
    /// @param _name Index name to look for
    /// @return Index address
    function indexOfName(string calldata _name) external view returns (address);

    /// @notice Returns index address by symbol
    /// @param _symbol Index symbol to look for
    /// @return Index address
    function indexOfSymbol(string calldata _symbol) external view returns (address);

    /// @notice Returns name of the given index
    /// @param _index Index address
    /// @return Index name
    function nameOfIndex(address _index) external view returns (string memory);

    /// @notice Returns symbol of the given index
    /// @param _index Index address
    /// @return Index symbol
    function symbolOfIndex(address _index) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Index registry interface
/// @notice Contains core components, addresses and asset market capitalizations
interface IIndexRegistry {
    event SetIndexLogic(address indexed account, address indexLogic);
    event SetMaxComponents(address indexed account, uint maxComponents);
    event UpdateAsset(address indexed asset, uint marketCap);
    event SetOrderer(address indexed account, address orderer);
    event SetFeePool(address indexed account, address feePool);
    event SetPriceOracle(address indexed account, address priceOracle);

    /// @notice Initializes IndexRegistry with the given params
    /// @param _indexLogic Index logic address
    /// @param _maxComponents Maximum assets for an index
    function initialize(address _indexLogic, uint _maxComponents) external;

    /// @notice Sets maximum assets for an index
    /// @param _maxComponents Maximum assets for an index
    function setMaxComponents(uint _maxComponents) external;

    /// @notice Index logic address
    /// @return Returns index logic address
    function indexLogic() external returns (address);

    /// @notice Sets index logic address
    /// @param _indexLogic Index logic address
    function setIndexLogic(address _indexLogic) external;

    /// @notice Sets adminRole as role's admin role.
    /// @param _role Role
    /// @param _adminRole AdminRole of given role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /// @notice Registers new index
    /// @param _index Index address
    /// @param _nameDetails Name details (name and symbol) for provided index
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external;

    /// @notice Registers asset in the system, updates it's market capitalization and assigns required roles
    /// @param _asset Asset to register
    /// @param _marketCap It's current market capitalization
    function addAsset(address _asset, uint _marketCap) external;

    /// @notice Removes assets from the system
    /// @param _asset Asset to remove
    function removeAsset(address _asset) external;

    /// @notice Updates market capitalization for the given asset
    /// @param _asset Asset address to update market capitalization for
    /// @param _marketCap Market capitalization value
    function updateAssetMarketCap(address _asset, uint _marketCap) external;

    /// @notice Sets price oracle address
    /// @param _priceOracle Price oracle address
    function setPriceOracle(address _priceOracle) external;

    /// @notice Sets orderer address
    /// @param _orderer Orderer address
    function setOrderer(address _orderer) external;

    /// @notice Sets fee pool address
    /// @param _feePool Fee pool address
    function setFeePool(address _feePool) external;

    /// @notice Maximum assets for an index
    /// @return Returns maximum assets for an index
    function maxComponents() external view returns (uint);

    /// @notice Market capitalization of provided asset
    /// @return _asset Returns market capitalization of provided asset
    function marketCapOf(address _asset) external view returns (uint);

    /// @notice Returns total market capitalization of the given assets
    /// @param _assets Assets array to calculate market capitalization of
    /// @return _marketCaps Corresponding capitalizations of the given asset
    /// @return _totalMarketCap Total market capitalization of the given assets
    function marketCapsOf(address[] calldata _assets)
        external
        view
        returns (uint[] memory _marketCaps, uint _totalMarketCap);

    /// @notice Total market capitalization of all registered assets
    /// @return Returns total market capitalization of all registered assets
    function totalMarketCap() external view returns (uint);

    /// @notice Price oracle address
    /// @return Returns price oracle address
    function priceOracle() external view returns (address);

    /// @notice Orderer address
    /// @return Returns orderer address
    function orderer() external view returns (address);

    /// @notice Fee pool address
    /// @return Returns fee pool address
    function feePool() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IIndexLayout.sol";

/// @title Index layout
/// @notice Contains storage layout of index
abstract contract IndexLayout is IIndexLayout {
    /// @inheritdoc IIndexLayout
    address public override factory;
    /// @inheritdoc IIndexLayout
    address public override vTokenFactory;
    /// @inheritdoc IIndexLayout
    address public override registry;

    /// @notice Timestamp of last AUM fee charge
    uint96 internal lastTransferTime;

    /// @notice Set with asset addresses
    EnumerableSet.AddressSet internal assets;
    /// @notice Set with previously used asset addresses
    EnumerableSet.AddressSet internal inactiveAssets;
    /// @notice Map of assets and their corresponding weights in index
    mapping(address => uint8) internal weightOf;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Base point library
/// @notice Contains constant used to prevent underflow of math operations
library BP {
    /// @notice Base point number
    /// @dev Used to prevent underflow of math operations
    uint16 constant DECIMAL_FACTOR = 10_000;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title vToken factory interface
/// @notice Contains vToken creation logic
interface IvTokenFactory {
    event VTokenCreated(address vToken, address asset);

    /// @notice Initialize vToken factory with the given params
    /// @param _registry Index registry address
    /// @param _vTokenImpl Address of vToken implementation
    function initialize(address _registry, address _vTokenImpl) external;

    /// @notice Upgrades beacon implementation
    /// @param _vTokenImpl Address of vToken implementation
    function upgradeBeaconTo(address _vTokenImpl) external;

    /// @notice Creates vToken for the given asset
    /// @param _asset Asset to create vToken for
    function createVToken(address _asset) external;

    /// @notice Creates and returns or returns address of previously created vToken for the given asset
    /// @param _asset Asset to create or return vToken for
    function createdVTokenOf(address _asset) external returns (address);

    /// @notice Returns beacon address
    /// @return Beacon address
    function beacon() external view returns (address);

    /// @notice Returns vToken for the given asset
    /// @param _asset Asset to retrieve vToken for
    /// @return vToken for the given asset
    function vTokenOf(address _asset) external view returns (address);
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