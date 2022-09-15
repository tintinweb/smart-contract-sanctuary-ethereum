// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./interfaces/IAVAXHelper.sol";

contract AVAXHelper is IAVAXHelper {
    bytes32 internal immutable ASSET_ROLE;
    bytes32 internal immutable INDEX_MANAGER_ROLE;

    IAccessControl public override registry;
    IIndexRouter public override router;
    IManagedIndexFactory public override factory;

    modifier manageAssetRole(address _asset) {
        registry.grantRole(ASSET_ROLE, _asset);
        _;
        registry.revokeRole(ASSET_ROLE, _asset);
    }

    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "AVAXHelper: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address payable _router,
        address _factory
    ) {
        registry = IAccessControl(_registry);
        router = IIndexRouter(_router);
        factory = IManagedIndexFactory(_factory);

        ASSET_ROLE = keccak256("ASSET_ROLE");
        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
    }

    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset)
        external
        payable
        override
        onlyRole(INDEX_MANAGER_ROLE)
        manageAssetRole(_asset)
    {
        router.mintSwapValue{ value: msg.value }(_params);
    }

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external override onlyRole(INDEX_MANAGER_ROLE) manageAssetRole(_asset) {
        factory.createIndex(_assets, _weights, _nameDetails);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IIndexRouter.sol";
import "./IManagedIndexFactory.sol";

interface IAVAXHelper {
    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset) external payable;

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external;

    function registry() external view returns (IAccessControl);

    function router() external view returns (IIndexRouter);

    function factory() external view returns (IManagedIndexFactory);
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index router interface
/// @notice Describes methods allowing to mint and redeem index tokens
interface IIndexRouter {
    struct MintParams {
        address index;
        uint amountInBase;
        address recipient;
    }

    struct MintSwapParams {
        address index;
        address inputToken;
        uint amountInInputToken;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct MintSwapValueParams {
        address index;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct BurnParams {
        address index;
        uint amount;
        address recipient;
    }

    struct BurnSwapParams {
        address index;
        uint amount;
        address outputAsset;
        address recipient;
        BurnQuoteParams[] quotes;
    }

    struct MintQuoteParams {
        address asset;
        address swapTarget;
        uint buyAssetMinAmount;
        bytes assetQuote;
    }

    struct BurnQuoteParams {
        address swapTarget;
        uint buyAssetMinAmount;
        bytes assetQuote;
    }

    /// @notice WETH receive payable method
    receive() external payable;

    /// @notice Initializes IndexRouter
    /// @param _WETH WETH address
    /// @param _registry IndexRegistry contract address
    function initialize(address _WETH, address _registry) external;

    /// @notice Mints index in exchange for appropriate index tokens withdrawn from the sender
    /// @param _params Mint params structure containing mint amounts, token references and other details
    /// @return _amount Amount of index to be minted for the given assets
    function mint(MintParams calldata _params) external returns (uint _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwap(MintSwapParams calldata _params) external returns (uint _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwapWithPermit(
        MintSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Mints index in exchange for ETH withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given value
    function mintSwapValue(MintSwapValueParams calldata _params) external payable returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burn(BurnParams calldata _params) external;

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @return _amounts Returns amount of tokens returned after burn
    function burnWithAmounts(BurnParams calldata _params) external returns (uint[] memory _amounts);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnWithPermit(
        BurnParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwap(BurnSwapParams calldata _params) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwapValue(BurnSwapParams calldata _params) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice WETH contract address
    /// @return Returns WETH contract address
    function WETH() external view returns (address);

    /// @notice Amount of index to be minted for the given amount of token
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of token
    function mintSwapIndexAmount(MintSwapParams calldata _params) external view returns (uint _amount);

    /// @notice Amount of tokens returned after index burn
    /// @param _index Index contract address
    /// @param _amount Amount of index to burn
    /// @return _amounts Returns amount of tokens returned after burn
    function burnTokensAmount(address _index, uint _amount) external view returns (uint[] memory _amounts);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./TestIndex.sol";
import "../BaseIndexFactory.sol";

contract TestIndexFactory is BaseIndexFactory {
    event TestIndexCreated(address index, address[] assets, uint8[] weights);

    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 internal constant MAX_WEIGHT = type(uint8).max;

    constructor(
        address _registry,
        address _vTokenFactory,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    )
        BaseIndexFactory(
            _registry,
            _vTokenFactory,
            address(0),
            _defaultMintingFeeInBP,
            _defaultBurningFeeInBP,
            _defaultAUMScaledPerSecondsRate
        )
    {}

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external onlyRole(INDEX_CREATOR_ROLE) returns (address index) {
        require(
            _assets.length > 1 &&
                _assets.length <= IIndexRegistry(registry).maxComponents() &&
                _weights.length == _assets.length,
            "TestIndexFactory: INVALID"
        );
        {
            // stack too deep: start scope
            uint totalWeight;
            for (uint i; i < _assets.length; ) {
                require(_assets[i] != address(0) && _weights[i] != 0, "TestIndexFactory: ZERO");
                if (i > 0) {
                    // makes sure that there are no duplicate assets
                    require(_assets[i - 1] < _assets[i], "TestIndexFactory: SORT");
                }
                totalWeight += _weights[i];

                unchecked {
                    i = i + 1;
                }
            }
            require(totalWeight == MAX_WEIGHT, "TestIndexFactory: MAX");
            bytes32 salt = keccak256(abi.encodePacked(_assets, _weights));
            index = Create2.computeAddress(salt, keccak256(type(TestIndex).creationCode));
            IIndexRegistry(registry).registerIndex(index, _nameDetails);
            Create2.deploy(0, salt, type(TestIndex).creationCode);
        }
        // stack too deep: end scope

        IFeePool.MintBurnInfo[] memory mintInfo = new IFeePool.MintBurnInfo[](1);
        mintInfo[0] = IFeePool.MintBurnInfo(index, BP.DECIMAL_FACTOR);

        IFeePool(IIndexRegistry(registry).feePool()).initializeIndex(
            index,
            defaultMintingFeeInBP,
            defaultBurningFeeInBP,
            defaultAUMScaledPerSecondsRate,
            mintInfo
        );

        TestIndex(index).initialize(_assets, _weights);
        emit TestIndexCreated(index, _assets, _weights);
    }

    /// @inheritdoc IIndexFactory
    function setReweightingLogic(address _reweightingLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        reweightingLogic = _reweightingLogic;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../interfaces/IReweightableIndex.sol";

import "../BaseIndex.sol";

contract TestIndex is IReweightableIndex, BaseIndex {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() BaseIndex(msg.sender) {}

    function initialize(address[] calldata _assets, uint8[] calldata _weights) external {
        require(msg.sender == factory, "TestIndex: FORBIDDEN");

        for (uint i; i < _assets.length; ) {
            address asset = _assets[i];
            uint8 weight = _weights[i];
            assets.add(asset);
            weightOf[asset] = weight;
            emit UpdateAnatomy(asset, weight);

            unchecked {
                i = i + 1;
            }
        }
    }

    function testOnlyRole(bytes32 _role) external view onlyRole(_role) returns (bool) {
        return true;
    }

    function reweight() external override {}

    function replaceAsset(address _from, address _to) external {
        assets.remove(_from);
        inactiveAssets.add(_from);
        assets.add(_to);
        inactiveAssets.remove(_to);
        weightOf[_to] = weightOf[_from];
        weightOf[_from] = 0;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.13;

/// @title Rewightable index interface
/// @notice Contains reweighting logic
interface IReweightableIndex {
    /// @notice Call index reweight process
    function reweight() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.13;

import "../interfaces/IManagedIndexReweightingLogic.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract TestManagedIndexReweightingLogic is IManagedIndexReweightingLogic, ERC165 {
    // test implementation which reverts
    function reweight(address[] calldata _updatedAssets, uint8[] calldata _updatedWeights) external override {
        revert();
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndexReweightingLogic).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "./libraries/FixedPoint112.sol";
import "./interfaces/IUniswapV3PriceOracle.sol";

/// @title Uniswap V3 price oracle
/// @notice Contains logic for price calculation of assets using Uniswap V3 Pool
/// @dev Oracle works through base asset which is set in initialize function
contract UniswapV3PriceOracle is IUniswapV3PriceOracle, ERC165 {
    using ERC165Checker for address;
    using FullMath for uint;

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    /// @notice Uniswap pool of the two assets
    IUniswapV3Pool public immutable pool;

    /// @notice Asset0 in the pool
    address public immutable asset0;

    /// @notice Asset1 in the pool
    address public immutable asset1;

    /// @notice Twap interval
    uint32 public twapInterval;

    constructor(
        address _factory,
        address _assetA,
        address _assetB,
        uint24 _fee,
        uint32 _twapInterval,
        address _registry
    ) {
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "UniswapV3PriceOracle: INTERFACE");
        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
        registry = IAccessControl(_registry);

        IUniswapV3Pool _pool = IUniswapV3Pool(IUniswapV3Factory(_factory).getPool(_assetA, _assetB, _fee));
        pool = _pool;
        asset0 = _pool.token0();
        asset1 = _pool.token1();
        twapInterval = _twapInterval;
    }

    /// @inheritdoc IUniswapV3PriceOracle
    function setTwapInterval(uint32 _twapInterval) external {
        require(registry.hasRole(ASSET_MANAGER_ROLE, msg.sender), "UniswapV3PriceOracle: FORBIDDEN");
        twapInterval = _twapInterval;
    }

    /// @inheritdoc IPriceOracle
    /// @notice Returns average asset per base
    function refreshedAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        return getPriceInUQ(_asset, getSqrtTwapX96Asset0());
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint) {
        return getPriceInUQ(_asset, getSqrtTwapX96Asset0());
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapV3PriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Gets square root of price in x96 format
    function getSqrtTwapX96Asset0() internal view returns (uint) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = twapInterval; // from (before)
        secondsAgo[1] = 0; // to (now)

        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);
        // The current price of the pool as a sqrt(asset1/asset0) Q64.96 value
        uint160 asset0sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(secondsAgo[0])))
        );
        return uint(asset0sqrtPriceX96);
    }

    /// @notice Gets price of asset in UQ format
    /// @param _asset Address of the asset
    /// @param _asset0sqrtPriceX96 Square root of price for asset0
    function getPriceInUQ(address _asset, uint _asset0sqrtPriceX96) internal view returns (uint _price) {
        // if asset == asset1 return price0Average
        if (_asset == asset1) {
            // (asset0sqrtPriceX96 * asset0sqrtPriceX96 / 2**192) * 2**112
            _price = _asset0sqrtPriceX96.mulDiv(_asset0sqrtPriceX96, 2**80);
        } else {
            require(_asset == asset0, "UniswapV3PriceOracle: UNKNOWN");
            // (2**192 / asset0sqrtPriceX96 * asset0sqrtPriceX96) * 2**112
            _price = (2**192 / _asset0sqrtPriceX96).mulDiv(FixedPoint112.Q112, _asset0sqrtPriceX96);
        }
        require(_price > 0, "UniswapV3PriceOracle: ZERO");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.13;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    uint24 internal constant MAX_TICK = 887272;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap price oracle interface
/// @notice Contains logic for price calculation of asset using Uniswap V3 Pool
interface IUniswapV3PriceOracle is IPriceOracle {
    /// @notice Sets twap interval for oracle
    /// @param _twapInterval Twap interval for oracle
    function setTwapInterval(uint32 _twapInterval) external;

    /// @notice Twap oracle update interval
    /// @return Twap interval in seconds
    function twapInterval() external view returns (uint32);

    /// @notice Asset0 in the pair
    /// @return Address of asset0 in the pair
    function asset0() external view returns (address);

    /// @notice Asset1 in the pair
    /// @return Address of asset1 in the pair
    function asset1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Price oracle interface
/// @notice Returns price of single asset in relation to base
interface IPriceOracle {
    /// @notice Updates and returns asset per base
    /// @return Asset per base in UQ
    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint);

    /// @notice Returns last asset per base
    /// @return Asset per base in UQ
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../interfaces/IPriceOracle.sol";

contract TestPriceOracle is IPriceOracle {
    mapping(address => uint) public assetPrice;

    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint) {
        return assetPrice[_asset];
    }

    function lastAssetPerBaseInUQ(address _asset) external view returns (uint) {
        return assetPrice[_asset];
    }

    function setPrice(address _asset, uint price) external {
        assetPrice[_asset] = price;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/FixedPoint112.sol";

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Phuture price oracle
/// @notice Aggregates all price oracles and works with them through IPriceOracle interface
contract PhuturePriceOracle is IPhuturePriceOracle, UUPSUpgradeable, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    /// @notice Scaling factor for index price
    uint8 internal constant INDEX_PRICE_SCALING_FACTOR = 2;

    /// @inheritdoc IPhuturePriceOracle
    mapping(address => address) public override priceOracleOf;

    /// @notice Index registry address
    address public registry;

    /// @notice Base asset address
    address public base;

    /// @notice Decimals of base asset
    uint8 internal baseDecimals;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "PhuturePriceOracle: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IPhuturePriceOracle
    function initialize(address _registry, address _base) external override initializer {
        require(_base != address(0), "PhuturePriceOracle: ZERO");

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "PhuturePriceOracle: INTERFACE");

        __UUPSUpgradeable_init();
        __ERC165_init();

        base = _base;
        baseDecimals = IERC20Metadata(_base).decimals();
        registry = _registry;
    }

    /// @inheritdoc IPhuturePriceOracle
    function setOracleOf(address _asset, address _oracle) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_oracle.supportsInterface(type(IPriceOracle).interfaceId), "PhuturePriceOracle: INTERFACE");

        priceOracleOf[_asset] = _oracle;
    }

    /// @inheritdoc IPhuturePriceOracle
    function removeOracleOf(address _asset) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(priceOracleOf[_asset] != address(0), "PhuturePriceOracle: UNSET");

        delete priceOracleOf[_asset];
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        if (_asset == base) {
            return FixedPoint112.Q112;
        }

        address priceOracle = priceOracleOf[_asset];
        require(priceOracle != address(0), "PhuturePriceOracle: UNSET");

        return IPriceOracle(priceOracle).refreshedAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPhuturePriceOracle
    function convertToIndex(uint _baseAmount, uint8 _indexDecimals) external view override returns (uint) {
        return (_baseAmount * 10**(_indexDecimals - INDEX_PRICE_SCALING_FACTOR)) / 10**baseDecimals;
    }

    /// @inheritdoc IPhuturePriceOracle
    function containsOracleOf(address _asset) external view override returns (bool) {
        return priceOracleOf[_asset] != address(0) || _asset == base;
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        if (_asset == base) {
            return FixedPoint112.Q112;
        }

        address priceOracle = priceOracleOf[_asset];
        require(priceOracle != address(0), "PhuturePriceOracle: UNSET");

        return IPriceOracle(priceOracle).lastAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPhuturePriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ASSET_MANAGER_ROLE) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IPriceOracle).interfaceId;
        interfaceIds[1] = type(IPhuturePriceOracle).interfaceId;
        require(_newImpl.supportsAllInterfaces(interfaceIds), "PhuturePriceOracle: INTERFACE");
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Phuture price oracle interface
/// @notice Aggregates all price oracles and works with them through IPriceOracle interface
interface IPhuturePriceOracle is IPriceOracle {
    /// @notice Initializes price oracle
    /// @param _registry Index registry address
    /// @param _base Base asset
    function initialize(address _registry, address _base) external;

    /// @notice Assigns given oracle to specified asset. Then oracle will be used to manage asset price
    /// @param _asset Asset to register
    /// @param _oracle Oracle to assign
    function setOracleOf(address _asset, address _oracle) external;

    /// @notice Removes oracle of specified asset
    /// @param _asset Asset to remove oracle from
    function removeOracleOf(address _asset) external;

    /// @notice Converts to index amount
    /// @param _baseAmount Amount in base
    /// @param _indexDecimals Index's decimals
    /// @return Asset per base in UQ with index decimals
    function convertToIndex(uint _baseAmount, uint8 _indexDecimals) external view returns (uint);

    /// @notice Checks if the given asset has oracle assigned
    /// @param _asset Asset to check
    /// @return Returns boolean flag defining if the given asset has oracle assigned
    function containsOracleOf(address _asset) external view returns (bool);

    /// @notice Price oracle assigned to the given `_asset`
    /// @param _asset Asset to obtain price oracle for
    /// @return Returns price oracle assigned to the `_asset`
    function priceOracleOf(address _asset) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
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
library StorageSlotUpgradeable {
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../PhuturePriceOracle.sol";

contract PhuturePriceOracleV2 is PhuturePriceOracle {
    function test() external pure returns (string memory) {
        return "Success";
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "../interfaces/IIndexRegistry.sol";
import "../interfaces/IPhuturePriceOracle.sol";
import "../interfaces/IOrderer.sol";
import "../interfaces/IFeePool.sol";
import "./EmptyUpgradable.sol";

/// @title Index registry
/// @notice Contains core components, addresses and asset market capitalizations
/// @dev After initializing call next methods: setPriceOracle, setOrderer, setFeePool
contract TestIndexRegistry is IIndexRegistry, EmptyUpgradable {
    using ERC165CheckerUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Responsible for all index related permissions
    bytes32 internal constant INDEX_ADMIN_ROLE = keccak256("INDEX_ADMIN_ROLE");
    /// @notice Responsible for all asset related permissions
    bytes32 internal constant ASSET_ADMIN_ROLE = keccak256("ASSET_ADMIN_ROLE");
    /// @notice Responsible for all ordering related permissions
    bytes32 internal constant ORDERING_ADMIN_ROLE = keccak256("ORDERING_ADMIN_ROLE");
    /// @notice Responsible for all exchange related permissions
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");

    /// @notice Role for index factory
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role for index
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Role allows index creation
    bytes32 internal constant INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    /// @notice Role for asset
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Role for assets which should be skipped during index burning
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Role allows update asset's market caps and vault reserve
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");
    /// @notice Role for orderer contract
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");
    /// @notice Role allows order execution
    bytes32 internal constant ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
    /// @notice Role allows perform validator's work
    bytes32 internal constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    /// @notice Role for keep3r job contract
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Role for UniswapV2Factory contract
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

    /// @inheritdoc IIndexRegistry
    mapping(address => uint) public override marketCapOf;
    /// @inheritdoc IIndexRegistry
    uint public override totalMarketCap;

    /// @inheritdoc IIndexRegistry
    uint public override maxComponents;

    /// @inheritdoc IIndexRegistry
    address public override orderer;
    /// @inheritdoc IIndexRegistry
    address public override priceOracle;
    /// @inheritdoc IIndexRegistry
    address public override feePool;
    /// @inheritdoc IIndexRegistry
    address public override indexLogic;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IIndexRegistry
    function initialize(address _indexLogic, uint _maxComponents) external override initializer {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        __EmptyUpgradable_init();

        indexLogic = _indexLogic;
        maxComponents = _maxComponents;

        _setupRoles();
        _setupRoleAdmins();
    }

    /// @inheritdoc IIndexRegistry
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external override {
        require(!hasRole(INDEX_ROLE, _index), "IndexRegistry: EXISTS");

        grantRole(INDEX_ROLE, _index);
    }

    /// @inheritdoc IIndexRegistry
    function setMaxComponents(uint _maxComponents) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        maxComponents = _maxComponents;
        emit SetMaxComponents(msg.sender, _maxComponents);
    }

    /// @inheritdoc IIndexRegistry
    function setIndexLogic(address _indexLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");

        indexLogic = _indexLogic;
        emit SetIndexLogic(msg.sender, _indexLogic);
    }

    /// @inheritdoc IIndexRegistry
    function setPriceOracle(address _priceOracle) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_priceOracle.supportsInterface(type(IPhuturePriceOracle).interfaceId), "IndexRegistry: INTERFACE");

        priceOracle = _priceOracle;
        emit SetPriceOracle(msg.sender, _priceOracle);
    }

    /// @inheritdoc IIndexRegistry
    function setOrderer(address _orderer) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderer.supportsInterface(type(IOrderer).interfaceId), "IndexRegistry: INTERFACE");

        if (orderer != address(0)) {
            revokeRole(ORDERER_ROLE, orderer);
        }

        orderer = _orderer;
        grantRole(ORDERER_ROLE, _orderer);
        emit SetOrderer(msg.sender, _orderer);
    }

    /// @inheritdoc IIndexRegistry
    function setFeePool(address _feePool) external override onlyRole(FEE_MANAGER_ROLE) {
        require(_feePool.supportsInterface(type(IFeePool).interfaceId), "IndexRegistry: INTERFACE");

        feePool = _feePool;
        emit SetFeePool(msg.sender, _feePool);
    }

    /// @inheritdoc IIndexRegistry
    function addAsset(address _asset, uint _marketCap) external override {
        require(IPhuturePriceOracle(priceOracle).containsOracleOf(_asset), "IndexRegistry: ORACLE");

        grantRole(ASSET_ROLE, _asset);
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function removeAsset(address _asset) external override {
        _updateMarketCap(_asset, 0);
        revokeRole(ASSET_ROLE, _asset);
    }

    /// @inheritdoc IIndexRegistry
    function updateAssetMarketCap(address _asset, uint _marketCap) external override onlyRole(ORACLE_ROLE) {
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IIndexRegistry
    function marketCapsOf(address[] calldata _assets)
        external
        view
        override
        returns (uint[] memory _marketCaps, uint _totalMarketCap)
    {
        uint assetsCount = _assets.length;
        _marketCaps = new uint[](assetsCount);

        for (uint i; i < assetsCount; ) {
            uint marketCap = marketCapOf[_assets[i]];
            _marketCaps[i] = marketCap;
            _totalMarketCap += marketCap;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Updates market capitalization of the given asset
    /// @dev Emits UpdateAsset event
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateAsset(address _asset, uint _marketCap) internal {
        require(_marketCap > 0, "IndexAssetRegistry: INVALID");

        _updateMarketCap(_asset, _marketCap);
        emit UpdateAsset(_asset, _marketCap);
    }

    /// @notice Setups initial roles
    function _setupRoles() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(INDEX_ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_ADMIN_ROLE, msg.sender);
        _setupRole(ORDERING_ADMIN_ROLE, msg.sender);
        _setupRole(EXCHANGE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Setups initial role admins
    function _setupRoleAdmins() internal {
        _setRoleAdmin(FACTORY_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_CREATOR_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_MANAGER_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(FEE_MANAGER_ROLE, INDEX_ADMIN_ROLE);

        _setRoleAdmin(INDEX_ROLE, FACTORY_ROLE);

        _setRoleAdmin(ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(SKIPPED_ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ASSET_MANAGER_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(RESERVE_MANAGER_ROLE, ASSET_ADMIN_ROLE);

        _setRoleAdmin(ORDERER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDERING_MANAGER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDER_EXECUTOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(KEEPER_JOB_ROLE, ORDERING_ADMIN_ROLE);

        _setRoleAdmin(EXCHANGE_FACTORY_ROLE, EXCHANGE_ADMIN_ROLE);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newImpl.supportsInterface(type(IIndexRegistry).interfaceId), "IndexRegistry: INTERFACE");
        super._authorizeUpgrade(_newImpl);
    }

    /// @notice Updates market capitalization of the given asset
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateMarketCap(address _asset, uint _marketCap) internal {
        require(hasRole(ASSET_ROLE, _asset), "IndexAssetRegistry: NOT_FOUND");

        totalMarketCap = totalMarketCap - marketCapOf[_asset] + _marketCap;
        marketCapOf[_asset] = _marketCap;
    }

    uint256[43] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IvToken.sol";

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrderer {
    struct Order {
        uint creationTimestamp;
        OrderAsset[] assets;
    }

    struct OrderAsset {
        address asset;
        OrderSide side;
        uint shares;
    }

    struct InternalSwap {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        address[] buyPath;
    }

    struct ExternalSwap {
        address factory;
        address account;
        uint maxSellShares;
        uint minSwapOutputAmount;
        address[] buyPath;
    }

    enum OrderSide {
        Sell,
        Buy
    }

    event PlaceOrder(address creator, uint id);
    event UpdateOrder(uint id, address asset, uint share, bool isSellSide);
    event CompleteOrder(uint id, address sellAsset, uint soldShares, address buyAsset, uint boughtShares);

    /// @notice Initializes orderer with the given params
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxAllowedPriceImpactInBP
    ) external;

    /// @notice Sets max allowed exchange price impact
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external;

    /// @notice Sets order lifetime in which it stays valid
    /// @param _orderLifetime Order lifetime in which it stays valid
    function setOrderLifetime(uint64 _orderLifetime) external;

    /// @notice Places order to orderer queue and returns order id
    /// @return Order id of the placed order
    function placeOrder() external returns (uint);

    /// @notice Fulfills specified order with order details
    /// @param _orderId Order id to fulfill
    /// @param _asset Asset address to be exchanged
    /// @param _shares Amount of asset to be exchanged
    /// @param _side Order side: buy or sell
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external;

    /// @notice Updates shares for order
    /// @param _asset Asset address
    /// @param _shares New amount of shares
    function updateOrderDetails(address _asset, uint _shares) external;

    /// @notice Updates asset amount for the latest order placed by the sender
    /// @param _asset Asset to change amount for
    /// @param _newTotalSupply New amount value
    /// @param _oldTotalSupply Old amount value
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external;

    /// @notice Reweighs the given index
    /// @param _index Index address to call reweight for
    function reweight(address _index) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwap calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwap calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxAllowedPriceImpactInBP() external view returns (uint16);

    /// @notice Order lifetime in which it stays valid
    /// @return Returns order lifetime in which it stays valid
    function orderLifetime() external view returns (uint64);

    /// @notice Returns last order of the given account
    /// @param _account Account to get last order for
    /// @return order Last order of the given account
    function orderOf(address _account) external view returns (Order memory order);

    /// @notice Returns last order id of the given account
    /// @param _account Account to get last order for
    /// @return Last order id of the given account
    function lastOrderIdOf(address _account) external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "../interfaces/INameRegistry.sol";

abstract contract EmptyUpgradable is AccessControlUpgradeable, UUPSUpgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure index related data/components
    bytes32 internal constant INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

    /// @notice Initializes empty upgradable
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    function __EmptyUpgradable_init() internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault token interface
/// @notice Contains logic for index's asset management
interface IvToken {
    struct AssetData {
        uint maxShares;
        uint amountInAsset;
    }

    event UpdateDeposit(address indexed account, uint depositedAmount);
    event SetVaultController(address vaultController);
    event VTokenTransfer(address indexed from, address indexed to, uint amount);

    /// @notice Initializes vToken with the given parameters
    /// @param _asset Asset that will be stored
    /// @param _registry Index registry address
    function initialize(address _asset, address _registry) external;

    /// @notice Sets vault controller for the vault
    /// @param _vaultController Vault controller to set
    function setController(address _vaultController) external;

    /// @notice Updates reserve to expected deposit target
    function deposit() external;

    /// @notice Withdraws all deposited amount
    function withdraw() external;

    /// @notice Transfers shares between given accounts
    /// @param _from Account to transfer shares from
    /// @param _to Account to transfer shares to
    /// @param _shares Amount of shares to transfer
    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external;

    /// @notice Transfers asset to the given recipient
    /// @dev Method is restricted to orderer
    /// @param _recipient Recipient address
    /// @param _amount Amount to transfer
    function transferAsset(address _recipient, uint _amount) external;

    /// @notice Mints shares for the current sender
    /// @return shares Amount of minted shares
    function mint() external returns (uint shares);

    /// @notice Burns shares for the given recipient and returns assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return amount Amount of sent assets
    function burn(address _recipient) external returns (uint amount);

    /// @notice Transfers shares from the sender to the given recipient
    /// @param _recipient Account to transfer shares to
    /// @param _amount Amount of shares to transfer
    function transfer(address _recipient, uint _amount) external;

    /// @notice Manually synchronizes shares balances
    function sync() external;

    /// @notice Mints shares for the given recipient
    /// @param _recipient Recipient to mint shares for
    /// @return Returns minted shares amount
    function mintFor(address _recipient) external returns (uint);

    /// @notice Burns shares and sends assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return Returns amount of sent assets
    function burnFor(address _recipient) external returns (uint);

    /// @notice Virtual supply amount: current balance + expected to be withdrawn using vault controller
    /// @return Returns virtual supply amount
    function virtualTotalAssetSupply() external view returns (uint);

    /// @notice Total supply amount: current balance + deposited using vault controller
    /// @return Returns total supply amount
    function totalAssetSupply() external view returns (uint);

    /// @notice Amount deposited using vault controller
    /// @return Returns amount deposited using vault controller
    function deposited() external view returns (uint);

    /// @notice Returns mintable amount of shares for given asset's amount
    /// @param _amount Amount of assets to mint shares for
    /// @return Returns amount of shares available for minting
    function mintableShares(uint _amount) external view returns (uint);

    /// @notice Returns amount of assets for the given account with the given shares amount
    /// @return Amount of assets for the given account with the given shares amount
    function assetDataOf(address _account, uint _shares) external view returns (AssetData memory);

    /// @notice Returns amount of assets for the given shares amount
    /// @param _shares Amount of shares
    /// @return Amount of assets
    function assetBalanceForShares(uint _shares) external view returns (uint);

    /// @notice Asset balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns asset balance of the given address
    function assetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance for the given address
    /// @param _account Address to check balance of
    /// @return Returns last asset balance for the given address
    function lastAssetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance
    /// @return Returns last asset balance
    function lastAssetBalance() external view returns (uint);

    /// @notice Total shares supply
    /// @return Returns total shares supply
    function totalSupply() external view returns (uint);

    /// @notice Shares balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns shares balance of the given address
    function balanceOf(address _account) external view returns (uint);

    /// @notice Returns the change in shares for a given amount of an asset
    /// @param _account Account to calculate shares for
    /// @param _amountInAsset Amount of asset to calculate shares
    /// @return newShares New shares value
    /// @return oldShares Old shares value
    function shareChange(address _account, uint _amountInAsset) external view returns (uint newShares, uint oldShares);

    /// @notice Vault controller address
    /// @return Returns vault controller address
    function vaultController() external view returns (address);

    /// @notice Stored asset address
    /// @return Returns stored asset address
    function asset() external view returns (address);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Percentage deposited using vault controller
    /// @return Returns percentage deposited using vault controller
    function currentDepositedPercentageInBP() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./interfaces/INameRegistry.sol";

/// @title Name registry
/// @notice Contains access control logic and information about names and symbols of indexes
abstract contract NameRegistry is INameRegistry, AccessControlUpgradeable, UUPSUpgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure index related data/components
    bytes32 internal constant INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

    /// @inheritdoc INameRegistry
    mapping(string => address) public override indexOfName;
    /// @inheritdoc INameRegistry
    mapping(string => address) public override indexOfSymbol;
    /// @inheritdoc INameRegistry
    mapping(address => string) public override nameOfIndex;
    /// @inheritdoc INameRegistry
    mapping(address => string) public override symbolOfIndex;

    /// @inheritdoc INameRegistry
    function setIndexName(address _index, string calldata _name) external override onlyRole(INDEX_MANAGER_ROLE) {
        _setIndexName(_index, _name);
    }

    /// @inheritdoc INameRegistry
    function setIndexSymbol(address _index, string calldata _symbol) external override onlyRole(INDEX_MANAGER_ROLE) {
        _setIndexSymbol(_index, _symbol);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(INameRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Assigns name to the given index
    /// @param _index Index to assign name for
    /// @param _name Name to assign
    function _setIndexName(address _index, string calldata _name) internal {
        // make sure that name is unique and not set by any other index
        require(indexOfName[_name] == address(0), "NameRegistry: EXISTS");

        uint length = bytes(_name).length;
        require(length >= 1 && length <= 32, "NameRegistry: INVALID");

        delete indexOfName[nameOfIndex[_index]];
        indexOfName[_name] = _index;
        nameOfIndex[_index] = _name;

        emit SetName(_index, _name);
    }

    /// @notice Initializes name registry
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    function __NameRegistry_init() internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /// @notice Assigns symbol to the given index
    /// @param _index Index to assign symbol for
    /// @param _symbol Symbol to assign
    function _setIndexSymbol(address _index, string calldata _symbol) internal {
        // make sure that symbol is unique and not set by any other index
        require(indexOfSymbol[_symbol] == address(0), "NameRegistry: EXISTS");

        uint length = bytes(_symbol).length;
        require(length >= 3 && length <= 6, "NameRegistry: INVALID");

        delete indexOfSymbol[symbolOfIndex[_index]];
        indexOfSymbol[_symbol] = _index;
        symbolOfIndex[_index] = _symbol;

        emit SetSymbol(_index, _symbol);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newImpl.supportsInterface(type(INameRegistry).interfaceId), "NameRegistry: INTERFACE");
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../NameRegistry.sol";

contract TestNameRegistry is NameRegistry {
    constructor() {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IIndexFactory.sol";
import "../interfaces/IIndexRegistry.sol";
import "../interfaces/IPhuturePriceOracle.sol";

import "../FeePool.sol";
import "../NameRegistry.sol";

contract IndexRegistryV2Test is IIndexRegistry, NameRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Responsible for all index related permissions
    bytes32 internal constant INDEX_ADMIN_ROLE = keccak256("INDEX_ADMIN_ROLE");
    /// @notice Responsible for all asset related permissions
    bytes32 internal constant ASSET_ADMIN_ROLE = keccak256("ASSET_ADMIN_ROLE");
    /// @notice Responsible for all ordering related permissions
    bytes32 internal constant ORDERING_ADMIN_ROLE = keccak256("ORDERING_ADMIN_ROLE");
    /// @notice Responsible for all exchange related permissions
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");

    /// @notice Role for index factory
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role for index
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Role allows index creation
    bytes32 internal constant INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    /// @notice Role for asset
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Role for assets which should be skiped during index burning
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Role allows update asset's market caps and vault reserve
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");
    /// @notice Role for orderer contract
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");
    /// @notice Role allows order execution
    bytes32 internal constant ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
    /// @notice Role allows perform validator's work
    bytes32 internal constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    /// @notice Role for keep3r job contract
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Role for Uniswap/Sushiswap factory contract
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

    mapping(address => uint) public override marketCapOf;
    uint public override totalMarketCap;

    uint public override maxComponents;

    address public override orderer;
    address public override priceOracle;
    address public override feePool;
    address public override indexLogic;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _indexLogic, uint _maxComponents) external override initializer {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        __NameRegistry_init();

        indexLogic = _indexLogic;
        maxComponents = _maxComponents;

        _setupRoles();
        _setupRoleAdmins();
    }

    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external override {
        require(!hasRole(INDEX_ROLE, _index), "IndexRegistry: EXISTS");

        grantRole(INDEX_ROLE, _index);
        _setIndexName(_index, _nameDetails.name);
        _setIndexSymbol(_index, _nameDetails.symbol);
    }

    function setMaxComponents(uint _maxComponents) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxComponents >= 5, "IndexRegistry: INVALID");
        maxComponents = _maxComponents;
        emit SetMaxComponents(msg.sender, _maxComponents);
    }

    function setIndexLogic(address _indexLogic) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        indexLogic = _indexLogic;
        emit SetIndexLogic(msg.sender, _indexLogic);
    }

    function setPriceOracle(address _priceOracle) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        priceOracle = _priceOracle;
        emit SetPriceOracle(msg.sender, _priceOracle);
    }

    function setOrderer(address _orderer) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        orderer = _orderer;
        revert("IndexRegistry: FORBIDDEN");
    }

    function setFeePool(address _feePool) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        feePool = _feePool;
        emit SetFeePool(msg.sender, _feePool);
    }

    function addAsset(address _asset, uint _marketCap) external override {
        require(IPhuturePriceOracle(priceOracle).containsOracleOf(_asset), "IndexRegistry: ORACLE");
        grantRole(ASSET_ROLE, _asset);
        _updateAsset(_asset, _marketCap);
    }

    function removeAsset(address _asset) external override {
        _updateMarketCap(_asset, 0);
        revokeRole(ASSET_ROLE, _asset);
    }

    function updateAssetMarketCap(address _asset, uint _marketCap) external override onlyRole(ORACLE_ROLE) {
        _updateAsset(_asset, _marketCap);
    }

    function marketCapsOf(address[] calldata _assets)
        external
        view
        override
        returns (uint[] memory _marketCaps, uint _totalMarketCap)
    {
        _marketCaps = new uint[](_assets.length);
        for (uint i; i < _assets.length; ) {
            uint marketCap = marketCapOf[_assets[i]];
            _marketCaps[i] = marketCap;
            _totalMarketCap += marketCap;

            unchecked {
                i = i + 1;
            }
        }
    }

    function _updateAsset(address _asset, uint _marketCap) internal {
        require(_marketCap > 0, "IndexAssetRegistry: INVALID");

        _updateMarketCap(_asset, _marketCap);
        emit UpdateAsset(_asset, _marketCap);
    }

    function _updateMarketCap(address _asset, uint _marketCap) internal {
        require(hasRole(ASSET_ROLE, _asset), "IndexAssetRegistry: NOT_FOUND");

        totalMarketCap = totalMarketCap - marketCapOf[_asset] + _marketCap;
        marketCapOf[_asset] = _marketCap;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    function test() external pure returns (string memory) {
        return "Success";
    }

    /// @inheritdoc IIndexRegistry
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice Setups initial roles
    function _setupRoles() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(INDEX_ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_ADMIN_ROLE, msg.sender);
        _setupRole(ORDERING_ADMIN_ROLE, msg.sender);
        _setupRole(EXCHANGE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Setups initial role admins
    function _setupRoleAdmins() internal {
        _setRoleAdmin(FACTORY_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_CREATOR_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_MANAGER_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(FEE_MANAGER_ROLE, INDEX_ADMIN_ROLE);

        _setRoleAdmin(INDEX_ROLE, FACTORY_ROLE);

        _setRoleAdmin(ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(SKIPPED_ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ASSET_MANAGER_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(RESERVE_MANAGER_ROLE, ASSET_ADMIN_ROLE);

        _setRoleAdmin(ORDERER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDERING_MANAGER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDER_EXECUTOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(KEEPER_JOB_ROLE, ORDERING_ADMIN_ROLE);

        _setRoleAdmin(EXCHANGE_FACTORY_ROLE, EXCHANGE_ADMIN_ROLE);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/AUMCalculationLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIndexFactory.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title Fee pool
/// @notice Responsible for index fee management logic and accumulation
contract FeePool is IFeePool, UUPSUpgradeable, ReentrancyGuardUpgradeable, ERC165Upgradeable {
    using Address for address;
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice 10% in base point format
    uint public constant MAX_FEE_IN_BP = 1000;

    /// @notice 10% in AUM Scaled units
    uint public constant MAX_AUM_FEE = 1000000003340960040392850629;

    /// @notice Index factory role
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /// @inheritdoc IFeePool
    mapping(address => uint) public override totalSharesOf;
    /// @inheritdoc IFeePool
    mapping(address => mapping(address => uint)) public override shareOf;

    /// @inheritdoc IFeePool
    mapping(address => uint16) public override mintingFeeInBPOf;
    /// @inheritdoc IFeePool
    mapping(address => uint16) public override burningFeeInBPOf;
    /// @inheritdoc IFeePool
    mapping(address => uint) public override AUMScaledPerSecondsRateOf;

    /// @notice Withdrawable amounts for accounts from indexes
    mapping(address => mapping(address => uint)) internal withdrawableOf;
    /// @notice Accumulated rewards for accounts from indexes
    mapping(address => mapping(address => uint)) internal lastAccumulatedTokenPerTotalSupplyInBaseOf;
    /// @notice Accumulated index rewards per total supply
    mapping(address => uint) internal accumulatedTokenPerTotalSupplyInBaseOf;
    /// @notice Index token balances
    mapping(address => uint) internal lastTokenBalanceOf;

    /// @notice Index registry address
    address internal registry;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "FeePool: FORBIDDEN");
        _;
    }

    /// @notice Checks if provided value is lower than 10% in base point format
    modifier isValidFee(uint16 _value) {
        require(_value <= MAX_FEE_IN_BP, "FeePool: INVALID");
        _;
    }

    /// @notice Accumulates account rewards per index
    modifier accumulateRewards(address _index, address _account) {
        if (_index.code.length != 0) {
            IIndexFactory(IIndex(_index).factory()).withdrawToFeePool(_index);
        }

        uint _totalShares = totalSharesOf[_index];
        if (_totalShares != 0) {
            uint tokenIncrease = IERC20(_index).balanceOf(address(this)) - lastTokenBalanceOf[_index];
            if (tokenIncrease != 0) {
                unchecked {
                    // overflow is desired
                    accumulatedTokenPerTotalSupplyInBaseOf[_index] +=
                        (tokenIncrease * BP.DECIMAL_FACTOR) /
                        _totalShares;
                }
            }
        }

        _accumulateAccountRewards(_index, _account);
        _;

        if (_totalShares != 0) {
            lastTokenBalanceOf[_index] = IERC20(_index).balanceOf(address(this));
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IFeePool
    function initialize(address _registry) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "FeePool: INTERFACE");

        __ERC165_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        registry = _registry;
    }

    /// @inheritdoc IFeePool
    function initializeIndex(
        address _index,
        uint16 _mintingFeeInBP,
        uint16 _burningFeeInBP,
        uint _AUMScaledPerSecondsRate,
        MintBurnInfo[] calldata _mintInfo
    ) external override onlyRole(FACTORY_ROLE) {
        mintingFeeInBPOf[_index] = _mintingFeeInBP;
        burningFeeInBPOf[_index] = _burningFeeInBP;
        AUMScaledPerSecondsRateOf[_index] = _AUMScaledPerSecondsRate;

        _mintMultiple(_index, _mintInfo);

        emit SetMintingFeeInBP(msg.sender, _index, _mintingFeeInBP);
        emit SetBurningFeeInBP(msg.sender, _index, _burningFeeInBP);
        emit SetAUMScaledPerSecondsRate(msg.sender, _index, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IFeePool
    function setMintingFeeInBP(address _index, uint16 _mintingFeeInBP)
        external
        override
        isValidFee(_mintingFeeInBP)
        onlyRole(FEE_MANAGER_ROLE)
    {
        mintingFeeInBPOf[_index] = _mintingFeeInBP;
        emit SetMintingFeeInBP(msg.sender, _index, _mintingFeeInBP);
    }

    /// @inheritdoc IFeePool
    function setBurningFeeInBP(address _index, uint16 _burningFeeInBP)
        external
        override
        isValidFee(_burningFeeInBP)
        onlyRole(FEE_MANAGER_ROLE)
    {
        burningFeeInBPOf[_index] = _burningFeeInBP;
        emit SetBurningFeeInBP(msg.sender, _index, _burningFeeInBP);
    }

    /// @inheritdoc IFeePool
    function setAUMScaledPerSecondsRate(address _index, uint _AUMScaledPerSecondsRate)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        require(_AUMScaledPerSecondsRate <= MAX_AUM_FEE, "FeePool: INVALID");
        require(_AUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE, "FeePool: INVALID");

        AUMScaledPerSecondsRateOf[_index] = _AUMScaledPerSecondsRate;
        emit SetAUMScaledPerSecondsRate(msg.sender, _index, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IFeePool
    function withdraw(address _index) external override nonReentrant {
        _withdraw(_index, msg.sender, msg.sender);
    }

    /// @inheritdoc IFeePool
    function withdrawPlatformFeeOf(address _index, address _recipient)
        external
        override
        nonReentrant
        onlyRole(FEE_MANAGER_ROLE)
    {
        _withdraw(_index, _index, _recipient);
    }

    /// @inheritdoc IFeePool
    function burn(address _index, MintBurnInfo calldata _burnInfo) external override onlyRole(FEE_MANAGER_ROLE) {
        _burn(_index, _burnInfo.recipient, _burnInfo.share);
    }

    /// @inheritdoc IFeePool
    function mint(address _index, MintBurnInfo calldata _mintInfo) external override onlyRole(FEE_MANAGER_ROLE) {
        _mint(_index, _mintInfo.recipient, _mintInfo.share);
    }

    /// @inheritdoc IFeePool
    function burnMultiple(address _index, MintBurnInfo[] calldata _burnInfo)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        uint infosCount = _burnInfo.length;
        for (uint i; i < infosCount; ) {
            MintBurnInfo memory info = _burnInfo[i];
            _burn(_index, info.recipient, info.share);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IFeePool
    function mintMultiple(address _index, MintBurnInfo[] calldata _mintInfo)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        _mintMultiple(_index, _mintInfo);
    }

    /// @inheritdoc IFeePool
    function withdrawableAmountOf(address _index, address _account) external view override returns (uint) {
        uint _currentBalance = IERC20(_index).balanceOf(address(this)) +
            IERC20(_index).balanceOf(IIndex(_index).factory());
        uint _accumulatedTokenPerTotalSupplyInBase = accumulatedTokenPerTotalSupplyInBaseOf[_index];
        uint _totalShares = totalSharesOf[_index];
        if (_totalShares != 0) {
            uint tokenIncrease = _currentBalance - lastTokenBalanceOf[_index];
            if (tokenIncrease != 0) {
                unchecked {
                    // overflow is desired
                    _accumulatedTokenPerTotalSupplyInBase += (tokenIncrease * BP.DECIMAL_FACTOR) / _totalShares;
                }
            }
        }

        uint _lastAccumulatedTokenPerTotalSupplyInBase = shareOf[_index][_account] == 0
            ? _accumulatedTokenPerTotalSupplyInBase
            : lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account];
        uint accumulatedTokenPerTotalSupplyInBaseIncrease;
        unchecked {
            // overflow is desired
            accumulatedTokenPerTotalSupplyInBaseIncrease =
                _accumulatedTokenPerTotalSupplyInBase -
                _lastAccumulatedTokenPerTotalSupplyInBase;
        }
        uint increase = (shareOf[_index][_account] * accumulatedTokenPerTotalSupplyInBaseIncrease) / BP.DECIMAL_FACTOR;

        return increase + withdrawableOf[_index][_account];
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IFeePool).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Accumulates account rewards per index
    function _accumulateAccountRewards(address _index, address _account) internal {
        uint _lastAccumulatedTokenPerTotalSupplyInBase = shareOf[_index][_account] == 0
            ? accumulatedTokenPerTotalSupplyInBaseOf[_index]
            : lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account];

        uint accumulatedTokenPerTotalSupplyInBaseIncrease;
        unchecked {
            // overflow is desired
            accumulatedTokenPerTotalSupplyInBaseIncrease =
                accumulatedTokenPerTotalSupplyInBaseOf[_index] -
                _lastAccumulatedTokenPerTotalSupplyInBase;
        }

        if (accumulatedTokenPerTotalSupplyInBaseIncrease != 0) {
            uint increase = (shareOf[_index][_account] * accumulatedTokenPerTotalSupplyInBaseIncrease) /
                BP.DECIMAL_FACTOR;
            if (increase != 0) {
                withdrawableOf[_index][_account] += increase;
            }
        }

        lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account] = accumulatedTokenPerTotalSupplyInBaseOf[_index];
    }

    function _mintMultiple(address _index, MintBurnInfo[] calldata _mintInfo) internal {
        uint infosCount = _mintInfo.length;
        for (uint i; i < infosCount; ) {
            MintBurnInfo memory info = _mintInfo[i];
            _mint(_index, info.recipient, info.share);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Withdraws balance from `_src` address and transfers to `_recipient` within the given index
    /// @param _index Index to withdraw
    /// @param _src Source address
    /// @param _recipient Recipient address
    function _withdraw(
        address _index,
        address _src,
        address _recipient
    ) internal accumulateRewards(_index, _src) {
        uint amount = withdrawableOf[_index][_src];
        if (amount != 0) {
            withdrawableOf[_index][_src] = 0;
            IERC20(_index).safeTransfer(_recipient, amount);

            emit Withdraw(_index, _recipient, amount);
        }
    }

    /// @notice Mints shares for `_recipient` address within the given index
    /// @param _index Index to mint fee pool's shares for
    /// @param _recipient Recipient address
    /// @param _share Shares amount to mint
    function _mint(
        address _index,
        address _recipient,
        uint _share
    ) internal accumulateRewards(_index, _recipient) {
        shareOf[_index][_recipient] += _share;
        totalSharesOf[_index] += _share;

        emit Mint(_index, _recipient, _share);
    }

    /// @notice Burns shares for `_recipient` address within the given index
    /// @param _index Index to burn fee pool's shares for
    /// @param _recipient Recipient address
    /// @param _share Shares amount to burn
    function _burn(
        address _index,
        address _recipient,
        uint _share
    ) internal accumulateRewards(_index, _recipient) {
        shareOf[_index][_recipient] -= _share;
        totalSharesOf[_index] -= _share;

        emit Burn(_index, _recipient, _share);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(FEE_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IFeePool).interfaceId), "FeePool: INTERFACE");
    }

    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../FeePool.sol";

contract FeePoolV2Test is FeePool {
    function test() external pure returns (string memory) {
        return "Success";
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title vToken factory
/// @notice Contains vToken creation logic
contract vTokenFactory is IvTokenFactory, UUPSUpgradeable, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IvTokenFactory
    address public override beacon;
    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IvTokenFactory
    mapping(address => address) public override vTokenOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "vTokenFactory: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IvTokenFactory
    function initialize(address _registry, address _vTokenImpl) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "vTokenFactory: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        beacon = address(new UpgradeableBeacon(_vTokenImpl));
    }

    /// @inheritdoc IvTokenFactory
    function upgradeBeaconTo(address _vTokenImpl) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_vTokenImpl.supportsInterface(type(IvToken).interfaceId), "vTokenFactory: INTERFACE");

        UpgradeableBeacon(beacon).upgradeTo(_vTokenImpl);
    }

    /// @inheritdoc IvTokenFactory
    function createVToken(address _asset) external override {
        require(vTokenOf[_asset] == address(0), "vTokenFactory: EXISTS");

        _createVToken(_asset);
    }

    /// @inheritdoc IvTokenFactory
    function createdVTokenOf(address _asset) external override returns (address) {
        if (vTokenOf[_asset] == address(0)) {
            _createVToken(_asset);
        }

        return vTokenOf[_asset];
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IvTokenFactory).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Creates vToken contract
    /// @param _asset Asset to create vToken for
    function _createVToken(address _asset) internal {
        address proxy = address(
            new BeaconProxy(beacon, abi.encodeWithSelector(IvToken.initialize.selector, _asset, registry))
        );
        vTokenOf[_asset] = proxy;

        emit VTokenCreated(proxy, _asset);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IvTokenFactory).interfaceId), "vTokenFactory: INTERFACE");
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IOrdererV2.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IReweightableIndex.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title OrdererAvax
/// @notice Contains logic for reweigh execution, order creation and execution
contract OrdererAvax is IOrderer, IOrdererV2, UUPSUpgradeable, ERC165Upgradeable {
    using FullMath for uint;
    using ERC165CheckerUpgradeable for address;
    using SafeERC20 for IERC20;

    /// @notice Order details structure containing assets list, creator address, creation timestamp and assetDetails
    struct OrderDetails {
        uint creationTimestamp;
        address creator;
        address[] assets;
        mapping(address => AssetDetails) assetDetails;
    }

    /// @notice Asset details structure containing order side (buy/sell) and order shares amount
    struct AssetDetails {
        OrderSide side;
        uint248 shares;
    }

    struct SwapDetails {
        address sellAsset;
        address buyAsset;
        IvToken sellVToken;
        IvToken buyVToken;
        IPhuturePriceOracle priceOracle;
    }

    struct InternalSwapVaultsInfo {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        IvToken buyVTokenSellAccount;
        IvToken buyVTokenBuyAccount;
        SwapDetails details;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Ordering Executor role
    bytes32 internal constant ORDERING_EXECUTOR_ROLE = keccak256("ORDERING_EXECUTOR_ROLE");
    /// @notice Exchange factory role
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

    /// @notice Last placed order id
    uint internal _lastOrderId;

    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IOrderer
    uint64 public override orderLifetime;

    /// @inheritdoc IOrderer
    uint16 public override maxAllowedPriceImpactInBP;

    /// @inheritdoc IOrdererV2
    uint16 public override maxSlippageInBP;

    /// @inheritdoc IOrderer
    mapping(address => uint) public override lastOrderIdOf;

    /// @notice Mapping of order id to order details
    mapping(uint => OrderDetails) internal orderDetailsOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "OrdererAvax: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOrdererV2
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external override(IOrderer, IOrdererV2) initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "OrdererAvax: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        orderLifetime = _orderLifetime;
        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_maxSlippageInBP != 0 && _maxSlippageInBP <= BP.DECIMAL_FACTOR, "OrdererAvax: INVALID");

        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setOrderLifetime(uint64 _orderLifetime) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderLifetime != 0, "OrdererAvax: INVALID");

        orderLifetime = _orderLifetime;
    }

    /// @inheritdoc IOrderer
    function placeOrder() external override onlyRole(INDEX_ROLE) returns (uint _orderId) {
        delete orderDetailsOf[lastOrderIdOf[msg.sender]];
        unchecked {
            ++_lastOrderId;
        }
        _orderId = _lastOrderId;
        OrderDetails storage order = orderDetailsOf[_orderId];
        order.creationTimestamp = block.timestamp;
        order.creator = msg.sender;
        lastOrderIdOf[msg.sender] = _orderId;
        emit PlaceOrder(msg.sender, _orderId);
    }

    /// @inheritdoc IOrderer
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external override onlyRole(INDEX_ROLE) {
        if (_asset != address(0) && _shares != 0) {
            OrderDetails storage order = orderDetailsOf[_orderId];
            order.assets.push(_asset);
            order.assetDetails[_asset] = AssetDetails({ side: _side, shares: uint248(_shares) });
            emit UpdateOrder(_orderId, _asset, _shares, _side == OrderSide.Sell);
        }
    }

    function updateOrderDetails(address _asset, uint _shares) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0 && _asset != address(0)) {
            uint248 shares = uint248(_shares);
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            order.assetDetails[_asset].shares = shares;
            emit UpdateOrder(lastOrderId, _asset, shares, order.assetDetails[_asset].side == OrderSide.Sell);
        }
    }

    /// @inheritdoc IOrderer
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0) {
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            uint shares = order.assetDetails[_asset].shares;
            if (shares != 0) {
                uint248 newShares = uint248((shares * _newTotalSupply) / _oldTotalSupply);
                order.assetDetails[_asset].shares = newShares;
                emit UpdateOrder(lastOrderId, _asset, newShares, order.assetDetails[_asset].side == OrderSide.Sell);
            }
        }
    }

    /// @inheritdoc IOrderer
    function reweight(address _index) external override onlyRole(ORDERING_EXECUTOR_ROLE) {
        IReweightableIndex(_index).reweight();
    }

    /// @inheritdoc IOrderer
    function internalSwap(InternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrderer
    function externalSwap(ExternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function internalSwap(InternalSwapV2 calldata _info) external override onlyRole(ORDERING_EXECUTOR_ROLE) {
        require(_info.maxSellShares != 0 && _info.buyAccount != _info.sellAccount, "OrdererAvax: INVALID");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.buyAccount) &&
                IAccessControl(registry).hasRole(INDEX_ROLE, _info.sellAccount),
            "OrdererAvax: INDEX"
        );

        address sellVTokenFactory = IIndex(_info.sellAccount).vTokenFactory();
        address buyVTokenFactory = IIndex(_info.buyAccount).vTokenFactory();
        SwapDetails memory _details = _swapDetails(
            sellVTokenFactory,
            buyVTokenFactory,
            _info.sellAsset,
            _info.buyAsset
        );

        if (sellVTokenFactory == buyVTokenFactory) {
            _internalWithinVaultSwap(_info, _details);
        } else {
            _internalBetweenVaultsSwap(
                InternalSwapVaultsInfo(
                    _info.sellAccount,
                    _info.buyAccount,
                    _info.maxSellShares,
                    IvToken(IvTokenFactory(sellVTokenFactory).vTokenOf(_details.buyAsset)),
                    IvToken(IvTokenFactory(buyVTokenFactory).vTokenOf(_details.sellAsset)),
                    _details
                )
            );
        }
    }

    /// @inheritdoc IOrdererV2
    function externalSwap(ExternalSwapV2 calldata _info) external override onlyRole(ORDERING_EXECUTOR_ROLE) {
        require(_info.swapTarget != address(0) && _info.swapData.length > 0, "OrdererAvax: INVALID");
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _info.account), "OrdererAvax: INVALID");

        SwapDetails memory _details = _swapDetails(
            IIndex(_info.account).vTokenFactory(),
            address(0),
            _info.sellAsset,
            _info.buyAsset
        );

        (uint lastOrderId, AssetDetails storage orderSellAsset, AssetDetails storage orderBuyAsset) = _validatedOrder(
            _info.account,
            _details.sellAsset,
            _details.buyAsset
        );

        require(orderSellAsset.shares >= _info.sellShares, "OrdererAvax: MAX");

        uint sellAssetPerBase = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);

        if (
            orderSellAsset.shares == _details.sellVToken.balanceOf(_info.account) &&
            _details.sellVToken.assetDataOf(_info.account, orderSellAsset.shares).amountInAsset.mulDiv(
                FixedPoint112.Q112,
                sellAssetPerBase
            ) <
            MIN_SWAP_AMOUNT
        ) {
            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), orderSellAsset.shares);
            _details.sellVToken.burnFor(address(_details.sellVToken));

            emit CompleteOrder(lastOrderId, _details.sellAsset, orderSellAsset.shares, _details.buyAsset, 0);
        } else {
            uint sellAmount = _details.sellVToken.assetDataOf(_info.account, _info.sellShares).amountInAsset;

            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), _info.sellShares);
            _details.sellVToken.burnFor(address(this));

            uint sellBalanceBefore = IERC20(_details.sellAsset).balanceOf(address(this));

            {
                uint allowance = IERC20(_details.sellAsset).allowance(address(this), _info.swapTarget);
                IERC20(_details.sellAsset).safeIncreaseAllowance(_info.swapTarget, type(uint256).max - allowance);
            }

            {
                (bool success, bytes memory data) = _info.swapTarget.call(_info.swapData);
                if (!success) {
                    if (data.length == 0) {
                        revert("OrdererAvax: SWAP_FAILED");
                    } else {
                        assembly {
                            revert(add(32, data), mload(data))
                        }
                    }
                }
            }

            {
                uint sellAmountInBase = sellAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                uint soldAmount = sellBalanceBefore - IERC20(_details.sellAsset).balanceOf(address(this));
                uint soldAmountInBase = soldAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                // checks diff between input and swap amounts
                require(sellAmountInBase - soldAmountInBase <= MIN_SWAP_AMOUNT, "OrdererAvax: AMOUNT");

                uint boughtAmount = IERC20(_details.buyAsset).balanceOf(address(this));
                uint boughtAmountInBase = boughtAmount.mulDiv(
                    FixedPoint112.Q112,
                    _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset)
                );
                uint ratio = (boughtAmountInBase * BP.DECIMAL_FACTOR) / (soldAmountInBase);

                require(
                    ratio >= BP.DECIMAL_FACTOR - maxSlippageInBP && ratio <= BP.DECIMAL_FACTOR + maxSlippageInBP,
                    "OrdererAvax: SLIPPAGE"
                );

                IERC20(_details.buyAsset).safeTransfer(address(_details.buyVToken), boughtAmount);
            }

            uint248 _buyShares = uint248(Math.min(_details.buyVToken.mintFor(_info.account), orderBuyAsset.shares));

            orderSellAsset.shares -= uint248(_info.sellShares);
            orderBuyAsset.shares -= _buyShares;

            emit CompleteOrder(lastOrderId, _details.sellAsset, _info.sellShares, _details.buyAsset, _buyShares);

            uint change = IERC20(_details.sellAsset).balanceOf(address(this));
            if (change > 0) {
                IERC20(_details.sellAsset).safeTransfer(address(_details.sellVToken), change);
                _details.sellVToken.sync();
            }

            IERC20(_details.sellAsset).safeApprove(_info.swapTarget, 0);
        }
    }

    /// @inheritdoc IOrderer
    function orderOf(address _account) external view override returns (Order memory order) {
        OrderDetails storage _order = orderDetailsOf[lastOrderIdOf[_account]];
        order = Order({ creationTimestamp: _order.creationTimestamp, assets: new OrderAsset[](_order.assets.length) });

        uint assetsCount = _order.assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _order.assets[i];
            order.assets[i] = OrderAsset({
                asset: asset,
                side: _order.assetDetails[asset].side,
                shares: _order.assetDetails[asset].shares
            });

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IOrdererV2).interfaceId ||
            _interfaceId == type(IOrderer).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Executes internal swap within single vault
    function _internalWithinVaultSwap(InternalSwapV2 calldata _info, SwapDetails memory _details) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _details.sellAsset, _details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _details.buyAsset, _details.sellAsset);

        uint248 sellShares;
        uint248 buyShares;
        {
            uint _sellShares = Math.min(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares
            );
            uint _buyShares = Math.min(sellOrderBuyAsset.shares, buyOrderSellAsset.shares);
            (sellShares, buyShares) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _details,
                _sellShares,
                _buyShares
            );
        }

        if (sellShares != 0 && buyShares != 0) {
            _details.sellVToken.transferFrom(_info.sellAccount, _info.buyAccount, sellShares);
            _details.buyVToken.transferFrom(_info.buyAccount, _info.sellAccount, buyShares);

            sellOrderSellAsset.shares -= sellShares;
            sellOrderBuyAsset.shares -= buyShares;
            buyOrderSellAsset.shares -= buyShares;
            buyOrderBuyAsset.shares -= sellShares;

            emit CompleteOrder(lastSellOrderId, _details.sellAsset, sellShares, _details.buyAsset, buyShares);
            emit CompleteOrder(lastBuyOrderId, _details.buyAsset, buyShares, _details.sellAsset, sellShares);
        }
    }

    /// @notice Executes internal swap between different vaults
    function _internalBetweenVaultsSwap(InternalSwapVaultsInfo memory _info) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _info.details.sellAsset, _info.details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _info.details.buyAsset, _info.details.sellAsset);

        uint248 sellSharesSellAccount;
        uint248 sellSharesBuyAccount;
        {
            uint _sellSharesSellAccount = _scaleShares(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares,
                _info.sellAccount,
                _info.details.sellVToken,
                _info.buyVTokenBuyAccount
            );
            uint _buySharesBuyAccount = _scaleShares(
                buyOrderSellAsset.shares,
                sellOrderBuyAsset.shares,
                _info.buyAccount,
                _info.details.buyVToken,
                _info.buyVTokenSellAccount
            );

            (sellSharesSellAccount, sellSharesBuyAccount) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _info.details,
                _sellSharesSellAccount,
                _buySharesBuyAccount
            );
        }

        _info.details.sellVToken.transferFrom(
            _info.sellAccount,
            address(_info.details.sellVToken),
            sellSharesSellAccount
        );
        _info.details.sellVToken.burnFor(address(_info.buyVTokenBuyAccount));
        uint248 buySharesBuyAccount = uint248(_info.buyVTokenBuyAccount.mintFor(_info.buyAccount));

        _info.details.buyVToken.transferFrom(_info.buyAccount, address(_info.details.buyVToken), sellSharesBuyAccount);
        _info.details.buyVToken.burnFor(address(_info.buyVTokenSellAccount));
        uint248 buySharesSellAccount = uint248(_info.buyVTokenSellAccount.mintFor(_info.sellAccount));

        sellOrderSellAsset.shares -= sellSharesSellAccount;
        sellOrderBuyAsset.shares -= buySharesSellAccount;
        buyOrderSellAsset.shares -= sellSharesBuyAccount;
        buyOrderBuyAsset.shares -= buySharesBuyAccount;

        emit CompleteOrder(
            lastSellOrderId,
            _info.details.sellAsset,
            sellSharesSellAccount,
            _info.details.buyAsset,
            buySharesSellAccount
        );
        emit CompleteOrder(
            lastBuyOrderId,
            _info.details.buyAsset,
            sellSharesBuyAccount,
            _info.details.sellAsset,
            buySharesBuyAccount
        );
    }

    /// @notice Returns validated order's info
    /// @param _index Index address
    /// @param _sellAsset Sell asset address
    /// @param _buyAsset Buy asset address
    /// @return lastOrderId Id of last order
    /// @return orderSellAsset Order's details for sell asset
    /// @return orderBuyAsset Order's details for buy asset
    function _validatedOrder(
        address _index,
        address _sellAsset,
        address _buyAsset
    )
        internal
        view
        returns (
            uint lastOrderId,
            AssetDetails storage orderSellAsset,
            AssetDetails storage orderBuyAsset
        )
    {
        lastOrderId = lastOrderIdOf[_index];
        OrderDetails storage order = orderDetailsOf[lastOrderId];

        orderSellAsset = order.assetDetails[_sellAsset];
        orderBuyAsset = order.assetDetails[_buyAsset];

        require(order.creationTimestamp + orderLifetime > block.timestamp, "OrdererAvax: EXPIRED");
        require(orderSellAsset.side == OrderSide.Sell && orderBuyAsset.side == OrderSide.Buy, "OrdererAvax: SIDE");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IOrderer).interfaceId), "OrdererAvax: INTERFACE");
    }

    /// @notice Scales down shares
    function _scaleShares(
        uint _sellShares,
        uint _buyShares,
        address _sellAccount,
        IvToken _sellVToken,
        IvToken _buyVToken
    ) internal view returns (uint) {
        uint sharesInAsset = _sellVToken.assetDataOf(_sellAccount, _sellShares).amountInAsset;
        uint mintableShares = _buyVToken.mintableShares(sharesInAsset);
        return Math.min(_sellShares, (_sellShares * _buyShares) / mintableShares);
    }

    /// @notice Calculates internal swap shares (buy and sell) for the given swap details
    function _calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 _sellShares, uint248 _buyShares) {
        uint sellAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);
        uint buyAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset);
        {
            uint buyAmountInBuyAsset = _details.buyVToken.assetBalanceForShares(_buyOrderShares);
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(sellAssetPerBaseInUQ, buyAssetPerBaseInUQ);
            _sellOrderShares = Math.min(_sellOrderShares, _details.sellVToken.mintableShares(buyAmountInSellAsset));
        }
        {
            uint sellAmountInSellAsset = _details.sellVToken.assetDataOf(sellAccount, _sellOrderShares).amountInAsset;
            uint sellAmountInBuyAsset = sellAmountInSellAsset.mulDiv(buyAssetPerBaseInUQ, sellAssetPerBaseInUQ);
            _buyOrderShares = Math.min(_buyOrderShares, _details.buyVToken.mintableShares(sellAmountInBuyAsset));
        }
        _sellShares = uint248(_sellOrderShares);
        _buyShares = uint248(_buyOrderShares);
    }

    /// @notice Returns swap details for the provided buy path
    /// @param _sellVTokenFactory vTokenFactory address of sell account
    /// @param _buyVTokenFactory vTokenFactory address of buy account
    /// @param _sellAsset Address of sell asset
    /// @param _buyAsset Address address of buy asset
    /// @return Swap details
    function _swapDetails(
        address _sellVTokenFactory,
        address _buyVTokenFactory,
        address _sellAsset,
        address _buyAsset
    ) internal view returns (SwapDetails memory) {
        require(_sellAsset != address(0) && _buyAsset != address(0), "OrdererAvax: ZERO");
        require(_sellAsset != _buyAsset, "OrdererAvax: INVALID");

        address buyVToken = IvTokenFactory(
            (_sellVTokenFactory == _buyVTokenFactory || _buyVTokenFactory == address(0))
                ? _sellVTokenFactory
                : _buyVTokenFactory
        ).vTokenOf(_buyAsset);

        return
            SwapDetails({
                sellAsset: _sellAsset,
                buyAsset: _buyAsset,
                sellVToken: IvToken(IvTokenFactory(_sellVTokenFactory).vTokenOf(_sellAsset)),
                buyVToken: IvToken(buyVToken),
                priceOracle: IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
            });
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrdererV2 {
    struct InternalSwapV2 {
        address sellAccount;
        address buyAccount;
        address sellAsset;
        address buyAsset;
        uint maxSellShares;
    }

    struct ExternalSwapV2 {
        address account;
        address sellAsset;
        address buyAsset;
        uint sellShares;
        address swapTarget;
        bytes swapData;
    }

    /// @notice Initializes orderer with the given params (overrides IOrderer's initialize)
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxSlippageInBP Max slippage in BP
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external;

    /// @notice Sets max allowed slippage
    /// @param _maxSlippageInBP Max allowed slippage
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwapV2 calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxSlippageInBP() external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IOrdererV2.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IReweightableIndex.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Orderer
/// @notice Contains logic for reweigh execution, order creation and execution
contract Orderer is IOrderer, IOrdererV2, UUPSUpgradeable, ERC165Upgradeable {
    using FullMath for uint;
    using ERC165CheckerUpgradeable for address;
    using SafeERC20 for IERC20;

    /// @notice Order details structure containing assets list, creator address, creation timestamp and assetDetails
    struct OrderDetails {
        uint creationTimestamp;
        address creator;
        address[] assets;
        mapping(address => AssetDetails) assetDetails;
    }

    /// @notice Asset details structure containing order side (buy/sell) and order shares amount
    struct AssetDetails {
        OrderSide side;
        uint248 shares;
    }

    struct SwapDetails {
        address sellAsset;
        address buyAsset;
        IvToken sellVToken;
        IvToken buyVToken;
        IPhuturePriceOracle priceOracle;
    }

    struct InternalSwapVaultsInfo {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        IvToken buyVTokenSellAccount;
        IvToken buyVTokenBuyAccount;
        SwapDetails details;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Keeper job role
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Exchange factory role
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

    /// @notice Last placed order id
    uint internal _lastOrderId;

    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IOrderer
    uint64 public override orderLifetime;

    /// @inheritdoc IOrderer
    uint16 public override maxAllowedPriceImpactInBP;

    /// @inheritdoc IOrdererV2
    uint16 public override maxSlippageInBP;

    /// @inheritdoc IOrderer
    mapping(address => uint) public override lastOrderIdOf;

    /// @notice Mapping of order id to order details
    mapping(uint => OrderDetails) internal orderDetailsOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "Orderer: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOrdererV2
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external override(IOrderer, IOrdererV2) initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "Orderer: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        orderLifetime = _orderLifetime;
        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_maxSlippageInBP != 0 && _maxSlippageInBP <= BP.DECIMAL_FACTOR, "Orderer: INVALID");

        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setOrderLifetime(uint64 _orderLifetime) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderLifetime != 0, "Orderer: INVALID");

        orderLifetime = _orderLifetime;
    }

    /// @inheritdoc IOrderer
    function placeOrder() external override onlyRole(INDEX_ROLE) returns (uint _orderId) {
        delete orderDetailsOf[lastOrderIdOf[msg.sender]];
        unchecked {
            ++_lastOrderId;
        }
        _orderId = _lastOrderId;
        OrderDetails storage order = orderDetailsOf[_orderId];
        order.creationTimestamp = block.timestamp;
        order.creator = msg.sender;
        lastOrderIdOf[msg.sender] = _orderId;
        emit PlaceOrder(msg.sender, _orderId);
    }

    /// @inheritdoc IOrderer
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external override onlyRole(INDEX_ROLE) {
        if (_asset != address(0) && _shares != 0) {
            OrderDetails storage order = orderDetailsOf[_orderId];
            order.assets.push(_asset);
            order.assetDetails[_asset] = AssetDetails({ side: _side, shares: uint248(_shares) });
            emit UpdateOrder(_orderId, _asset, _shares, _side == OrderSide.Sell);
        }
    }

    function updateOrderDetails(address _asset, uint _shares) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0 && _asset != address(0)) {
            uint248 shares = uint248(_shares);
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            order.assetDetails[_asset].shares = shares;
            emit UpdateOrder(lastOrderId, _asset, shares, order.assetDetails[_asset].side == OrderSide.Sell);
        }
    }

    /// @inheritdoc IOrderer
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0) {
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            uint shares = order.assetDetails[_asset].shares;
            if (shares != 0) {
                uint248 newShares = uint248((shares * _newTotalSupply) / _oldTotalSupply);
                order.assetDetails[_asset].shares = newShares;
                emit UpdateOrder(lastOrderId, _asset, newShares, order.assetDetails[_asset].side == OrderSide.Sell);
            }
        }
    }

    /// @inheritdoc IOrderer
    function reweight(address _index) external override onlyRole(KEEPER_JOB_ROLE) {
        IReweightableIndex(_index).reweight();
    }

    /// @inheritdoc IOrderer
    function internalSwap(InternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrderer
    function externalSwap(ExternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function internalSwap(InternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.maxSellShares != 0 && _info.buyAccount != _info.sellAccount, "Orderer: INVALID");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.buyAccount) &&
                IAccessControl(registry).hasRole(INDEX_ROLE, _info.sellAccount),
            "Orderer: INDEX"
        );

        address sellVTokenFactory = IIndex(_info.sellAccount).vTokenFactory();
        address buyVTokenFactory = IIndex(_info.buyAccount).vTokenFactory();
        SwapDetails memory _details = _swapDetails(
            sellVTokenFactory,
            buyVTokenFactory,
            _info.sellAsset,
            _info.buyAsset
        );

        if (sellVTokenFactory == buyVTokenFactory) {
            _internalWithinVaultSwap(_info, _details);
        } else {
            _internalBetweenVaultsSwap(
                InternalSwapVaultsInfo(
                    _info.sellAccount,
                    _info.buyAccount,
                    _info.maxSellShares,
                    IvToken(IvTokenFactory(sellVTokenFactory).vTokenOf(_details.buyAsset)),
                    IvToken(IvTokenFactory(buyVTokenFactory).vTokenOf(_details.sellAsset)),
                    _details
                )
            );
        }
    }

    /// @inheritdoc IOrdererV2
    function externalSwap(ExternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.swapTarget != address(0) && _info.swapData.length > 0, "Orderer: INVALID");
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _info.account), "Orderer: INVALID");

        SwapDetails memory _details = _swapDetails(
            IIndex(_info.account).vTokenFactory(),
            address(0),
            _info.sellAsset,
            _info.buyAsset
        );

        (uint lastOrderId, AssetDetails storage orderSellAsset, AssetDetails storage orderBuyAsset) = _validatedOrder(
            _info.account,
            _details.sellAsset,
            _details.buyAsset
        );

        require(orderSellAsset.shares >= _info.sellShares, "Orderer: MAX");

        uint sellAssetPerBase = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);

        if (
            orderSellAsset.shares == _details.sellVToken.balanceOf(_info.account) &&
            _details.sellVToken.assetDataOf(_info.account, orderSellAsset.shares).amountInAsset.mulDiv(
                FixedPoint112.Q112,
                sellAssetPerBase
            ) <
            MIN_SWAP_AMOUNT
        ) {
            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), orderSellAsset.shares);
            _details.sellVToken.burnFor(address(_details.sellVToken));

            emit CompleteOrder(lastOrderId, _details.sellAsset, orderSellAsset.shares, _details.buyAsset, 0);
        } else {
            uint sellAmount = _details.sellVToken.assetDataOf(_info.account, _info.sellShares).amountInAsset;

            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), _info.sellShares);
            _details.sellVToken.burnFor(address(this));

            uint sellBalanceBefore = IERC20(_details.sellAsset).balanceOf(address(this));

            {
                uint allowance = IERC20(_details.sellAsset).allowance(address(this), _info.swapTarget);
                IERC20(_details.sellAsset).safeIncreaseAllowance(_info.swapTarget, type(uint256).max - allowance);
            }

            {
                (bool success, bytes memory data) = _info.swapTarget.call(_info.swapData);
                if (!success) {
                    if (data.length == 0) {
                        revert("Orderer: SWAP_FAILED");
                    } else {
                        assembly {
                            revert(add(32, data), mload(data))
                        }
                    }
                }
            }

            {
                uint sellAmountInBase = sellAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                uint soldAmount = sellBalanceBefore - IERC20(_details.sellAsset).balanceOf(address(this));
                uint soldAmountInBase = soldAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                // checks diff between input and swap amounts
                require(sellAmountInBase - soldAmountInBase <= MIN_SWAP_AMOUNT, "Orderer: AMOUNT");

                uint boughtAmount = IERC20(_details.buyAsset).balanceOf(address(this));
                uint boughtAmountInBase = boughtAmount.mulDiv(
                    FixedPoint112.Q112,
                    _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset)
                );
                uint ratio = (boughtAmountInBase * BP.DECIMAL_FACTOR) / (soldAmountInBase);

                require(
                    ratio >= BP.DECIMAL_FACTOR - maxSlippageInBP && ratio <= BP.DECIMAL_FACTOR + maxSlippageInBP,
                    "Orderer: SLIPPAGE"
                );

                IERC20(_details.buyAsset).safeTransfer(address(_details.buyVToken), boughtAmount);
            }

            uint248 _buyShares = uint248(Math.min(_details.buyVToken.mintFor(_info.account), orderBuyAsset.shares));

            orderSellAsset.shares -= uint248(_info.sellShares);
            orderBuyAsset.shares -= _buyShares;

            emit CompleteOrder(lastOrderId, _details.sellAsset, _info.sellShares, _details.buyAsset, _buyShares);

            uint change = IERC20(_details.sellAsset).balanceOf(address(this));
            if (change > 0) {
                IERC20(_details.sellAsset).safeTransfer(address(_details.sellVToken), change);
                _details.sellVToken.sync();
            }

            IERC20(_details.sellAsset).safeApprove(_info.swapTarget, 0);
        }
    }

    /// @inheritdoc IOrderer
    function orderOf(address _account) external view override returns (Order memory order) {
        OrderDetails storage _order = orderDetailsOf[lastOrderIdOf[_account]];
        order = Order({ creationTimestamp: _order.creationTimestamp, assets: new OrderAsset[](_order.assets.length) });

        uint assetsCount = _order.assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _order.assets[i];
            order.assets[i] = OrderAsset({
                asset: asset,
                side: _order.assetDetails[asset].side,
                shares: _order.assetDetails[asset].shares
            });

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IOrdererV2).interfaceId ||
            _interfaceId == type(IOrderer).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Executes internal swap within single vault
    function _internalWithinVaultSwap(InternalSwapV2 calldata _info, SwapDetails memory _details) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _details.sellAsset, _details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _details.buyAsset, _details.sellAsset);

        uint248 sellShares;
        uint248 buyShares;
        {
            uint _sellShares = Math.min(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares
            );
            uint _buyShares = Math.min(sellOrderBuyAsset.shares, buyOrderSellAsset.shares);
            (sellShares, buyShares) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _details,
                _sellShares,
                _buyShares
            );
        }

        if (sellShares != 0 && buyShares != 0) {
            _details.sellVToken.transferFrom(_info.sellAccount, _info.buyAccount, sellShares);
            _details.buyVToken.transferFrom(_info.buyAccount, _info.sellAccount, buyShares);

            sellOrderSellAsset.shares -= sellShares;
            sellOrderBuyAsset.shares -= buyShares;
            buyOrderSellAsset.shares -= buyShares;
            buyOrderBuyAsset.shares -= sellShares;

            emit CompleteOrder(lastSellOrderId, _details.sellAsset, sellShares, _details.buyAsset, buyShares);
            emit CompleteOrder(lastBuyOrderId, _details.buyAsset, buyShares, _details.sellAsset, sellShares);
        }
    }

    /// @notice Executes internal swap between different vaults
    function _internalBetweenVaultsSwap(InternalSwapVaultsInfo memory _info) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _info.details.sellAsset, _info.details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _info.details.buyAsset, _info.details.sellAsset);

        uint248 sellSharesSellAccount;
        uint248 sellSharesBuyAccount;
        {
            uint _sellSharesSellAccount = _scaleShares(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares,
                _info.sellAccount,
                _info.details.sellVToken,
                _info.buyVTokenBuyAccount
            );
            uint _buySharesBuyAccount = _scaleShares(
                buyOrderSellAsset.shares,
                sellOrderBuyAsset.shares,
                _info.buyAccount,
                _info.details.buyVToken,
                _info.buyVTokenSellAccount
            );

            (sellSharesSellAccount, sellSharesBuyAccount) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _info.details,
                _sellSharesSellAccount,
                _buySharesBuyAccount
            );
        }

        _info.details.sellVToken.transferFrom(
            _info.sellAccount,
            address(_info.details.sellVToken),
            sellSharesSellAccount
        );
        _info.details.sellVToken.burnFor(address(_info.buyVTokenBuyAccount));
        uint248 buySharesBuyAccount = uint248(_info.buyVTokenBuyAccount.mintFor(_info.buyAccount));

        _info.details.buyVToken.transferFrom(_info.buyAccount, address(_info.details.buyVToken), sellSharesBuyAccount);
        _info.details.buyVToken.burnFor(address(_info.buyVTokenSellAccount));
        uint248 buySharesSellAccount = uint248(_info.buyVTokenSellAccount.mintFor(_info.sellAccount));

        sellOrderSellAsset.shares -= sellSharesSellAccount;
        sellOrderBuyAsset.shares -= buySharesSellAccount;
        buyOrderSellAsset.shares -= sellSharesBuyAccount;
        buyOrderBuyAsset.shares -= buySharesBuyAccount;

        emit CompleteOrder(
            lastSellOrderId,
            _info.details.sellAsset,
            sellSharesSellAccount,
            _info.details.buyAsset,
            buySharesSellAccount
        );
        emit CompleteOrder(
            lastBuyOrderId,
            _info.details.buyAsset,
            sellSharesBuyAccount,
            _info.details.sellAsset,
            buySharesBuyAccount
        );
    }

    /// @notice Returns validated order's info
    /// @param _index Index address
    /// @param _sellAsset Sell asset address
    /// @param _buyAsset Buy asset address
    /// @return lastOrderId Id of last order
    /// @return orderSellAsset Order's details for sell asset
    /// @return orderBuyAsset Order's details for buy asset
    function _validatedOrder(
        address _index,
        address _sellAsset,
        address _buyAsset
    )
        internal
        view
        returns (
            uint lastOrderId,
            AssetDetails storage orderSellAsset,
            AssetDetails storage orderBuyAsset
        )
    {
        lastOrderId = lastOrderIdOf[_index];
        OrderDetails storage order = orderDetailsOf[lastOrderId];

        orderSellAsset = order.assetDetails[_sellAsset];
        orderBuyAsset = order.assetDetails[_buyAsset];

        require(order.creationTimestamp + orderLifetime > block.timestamp, "Orderer: EXPIRED");
        require(orderSellAsset.side == OrderSide.Sell && orderBuyAsset.side == OrderSide.Buy, "Orderer: SIDE");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IOrderer).interfaceId), "Orderer: INTERFACE");
    }

    /// @notice Scales down shares
    function _scaleShares(
        uint _sellShares,
        uint _buyShares,
        address _sellAccount,
        IvToken _sellVToken,
        IvToken _buyVToken
    ) internal view returns (uint) {
        uint sharesInAsset = _sellVToken.assetDataOf(_sellAccount, _sellShares).amountInAsset;
        uint mintableShares = _buyVToken.mintableShares(sharesInAsset);
        return Math.min(_sellShares, (_sellShares * _buyShares) / mintableShares);
    }

    /// @notice Calculates internal swap shares (buy and sell) for the given swap details
    function _calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 _sellShares, uint248 _buyShares) {
        uint sellAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);
        uint buyAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset);
        {
            uint buyAmountInBuyAsset = _details.buyVToken.assetBalanceForShares(_buyOrderShares);
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(sellAssetPerBaseInUQ, buyAssetPerBaseInUQ);
            _sellOrderShares = Math.min(_sellOrderShares, _details.sellVToken.mintableShares(buyAmountInSellAsset));
        }
        {
            uint sellAmountInSellAsset = _details.sellVToken.assetDataOf(sellAccount, _sellOrderShares).amountInAsset;
            uint sellAmountInBuyAsset = sellAmountInSellAsset.mulDiv(buyAssetPerBaseInUQ, sellAssetPerBaseInUQ);
            _buyOrderShares = Math.min(_buyOrderShares, _details.buyVToken.mintableShares(sellAmountInBuyAsset));
        }
        _sellShares = uint248(_sellOrderShares);
        _buyShares = uint248(_buyOrderShares);
    }

    /// @notice Returns swap details for the provided buy path
    /// @param _sellVTokenFactory vTokenFactory address of sell account
    /// @param _buyVTokenFactory vTokenFactory address of buy account
    /// @param _sellAsset Address of sell asset
    /// @param _buyAsset Address address of buy asset
    /// @return Swap details
    function _swapDetails(
        address _sellVTokenFactory,
        address _buyVTokenFactory,
        address _sellAsset,
        address _buyAsset
    ) internal view returns (SwapDetails memory) {
        require(_sellAsset != address(0) && _buyAsset != address(0), "Orderer: ZERO");
        require(_sellAsset != _buyAsset, "Orderer: INVALID");

        address buyVToken = IvTokenFactory(
            (_sellVTokenFactory == _buyVTokenFactory || _buyVTokenFactory == address(0))
                ? _sellVTokenFactory
                : _buyVTokenFactory
        ).vTokenOf(_buyAsset);

        return
            SwapDetails({
                sellAsset: _sellAsset,
                buyAsset: _buyAsset,
                sellVToken: IvToken(IvTokenFactory(_sellVTokenFactory).vTokenOf(_sellAsset)),
                buyVToken: IvToken(buyVToken),
                priceOracle: IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
            });
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../Orderer.sol";

contract TestOrderer is Orderer {
    function calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) external returns (uint248 _sellShares, uint248 _buyShares) {
        return _calculateInternalSwapShares(sellAccount, buyAccount, _details, _sellOrderShares, _buyOrderShares);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/ValidatorLibrary.sol";

import "./interfaces/IOrdererV2.sol";
import "./interfaces/IPhutureJob.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/external/IKeep3r.sol";

/// @title Phuture job
/// @notice Contains signature verification and order execution logic
contract PhutureJob is IPhutureJob, Pausable {
    using ERC165Checker for address;
    using Counters for Counters.Counter;
    using ValidatorLibrary for ValidatorLibrary.Sign;

    /// @notice Validator role
    bytes32 internal immutable VALIDATOR_ROLE;
    /// @notice Order executor role
    bytes32 internal immutable ORDER_EXECUTOR_ROLE;
    /// @notice Role allows configure ordering related data/components
    bytes32 internal immutable ORDERING_MANAGER_ROLE;

    /// @notice Nonce
    Counters.Counter internal _nonce;
    /// @inheritdoc IPhutureJob
    address public immutable override keep3r;
    /// @inheritdoc IPhutureJob
    address public immutable override registry;

    /// @inheritdoc IPhutureJob
    uint256 public override minAmountOfSigners = 1;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "PhutureJob: FORBIDDEN");
        _;
    }

    /// @notice Pays keeper for work
    modifier payKeeper(address _keeper) {
        require(IKeep3r(keep3r).isKeeper(_keeper), "PhutureJob: !KEEP3R");
        _;
        IKeep3r(keep3r).worked(_keeper);
    }

    constructor(address _keep3r, address _registry) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "PhutureJob: INTERFACE");

        VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
        ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
        ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

        keep3r = _keep3r;
        registry = _registry;

        _pause();
    }

    /// @inheritdoc IPhutureJob
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_minAmountOfSigners != 0, "PhutureJob: INVALID");

        minAmountOfSigners = _minAmountOfSigners;
    }

    /// @inheritdoc IPhutureJob
    function pause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IPhutureJob
    function unpause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IPhutureJob
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
        whenNotPaused
        payKeeper(msg.sender)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
        whenNotPaused
        payKeeper(msg.sender)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function internalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function externalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function nonce() external view override returns (uint256) {
        return _nonce.current();
    }

    /// @notice Verifies that list of signatures provided by validator have signed given `_data` object
    /// @param _signs List of signatures
    /// @param _data Data object to verify signature
    function _validate(ValidatorLibrary.Sign[] calldata _signs, bytes memory _data) internal {
        uint signsCount = _signs.length;
        require(signsCount >= minAmountOfSigners, "PhutureJob: !ENOUGH_SIGNERS");

        address lastAddress = address(0);
        for (uint i; i < signsCount; ) {
            address signer = _signs[i].signer;
            require(uint160(signer) > uint160(lastAddress), "PhutureJob: UNSORTED");
            require(
                _signs[i].verify(_data, _useNonce()) && IAccessControl(registry).hasRole(VALIDATOR_ROLE, signer),
                string.concat("PhutureJob: SIGN ", Strings.toHexString(uint160(signer), 20))
            );

            lastAddress = signer;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return the current value of nonce and increment
    /// @return current Current nonce of signer
    function _useNonce() internal virtual returns (uint256 current) {
        current = _nonce.current();
        _nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Validator library
/// @notice Library containing set of utilities related to Phuture job validation
library ValidatorLibrary {
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address signer;
        uint deadline;
    }

    /// @notice Verifies if the given `_data` object was signed by proper signer
    /// @param self Sign object reference
    /// @param _data Data object to verify signature
    function verify(
        Sign calldata self,
        bytes memory _data,
        uint _nonce
    ) internal view returns (bool) {
        require(block.timestamp <= self.deadline, "ValidatorLibrary: EXPIRED");

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,uint256 nonce,uint256 deadline)"
                ),
                keccak256(bytes("PhutureJob")),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                _nonce,
                self.deadline
            )
        );

        return
            self.signer ==
            ecrecover(
                keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, keccak256(_data))),
                self.v,
                self.r,
                self.s
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "../libraries/ValidatorLibrary.sol";

import "./IOrdererV2.sol";

/// @title Phuture job interface
/// @notice Contains signature verification and order execution logic
interface IPhutureJob {
    /// @notice Pause order execution
    function pause() external;

    /// @notice Unpause order execution
    function unpause() external;

    /// @notice Sets minimum amount of signers required to sign a job
    /// @param _minAmountOfSigners Minimum amount of signers required to sign a job
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external;

    /// @notice Swap shares internally
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info) external;

    /// @notice Swap shares internally (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external;

    /// @notice Swap shares using DEX (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Keep3r address
    /// @return Returns address of keep3r network
    function keep3r() external view returns (address);

    /// @notice Nonce of signer
    /// @return Returns nonce of given signer
    function nonce() external view returns (uint256);

    /// @notice Minimum amount of signers required to sign a job
    /// @return Returns minimum amount of signers required to sign a job
    function minAmountOfSigners() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

interface IKeep3r {
    function isKeeper(address _keeper) external returns (bool _isKeeper);

    function worked(address _keeper) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IKeep3r.sol";

import "./DepositManager.sol";

contract DepositManagerJob is DepositManager {
    /// @notice Address of Keeper Network V2
    address public immutable keep3r;

    constructor(
        address _keep3r,
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) DepositManager(_registry, _maxLossInBP, _depositInterval) {
        keep3r = _keep3r;
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public override {
        require(IKeep3r(keep3r).isKeeper(msg.sender), "DepositManager: !KEEP3R");

        super.updateDeposits();

        IKeep3r(keep3r).worked(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IVaultController.sol";

contract DepositManager is IDepositManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Base point number
    uint16 internal constant BP = 10_000;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal immutable RESERVE_MANAGER_ROLE;
    /// @inheritdoc IDepositManager
    address public immutable override registry;

    /// @notice vTokens to deposit for
    EnumerableSet.AddressSet internal vTokens;

    /// @inheritdoc IDepositManager
    uint32 public override depositInterval;

    /// @inheritdoc IDepositManager
    uint16 public override maxLossInBP;

    /// @inheritdoc IDepositManager
    mapping(address => uint96) public override lastDepositTimestamp;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "DepositManager: FORBIDDEN");
        _;
    }

    /// @notice Checks if max loss is within an acceptable range
    modifier isValidMaxLoss(uint16 _maxLossInBP) {
        require(_maxLossInBP <= BP, "DepositManager: MAX_LOSS");
        _;
    }

    constructor(
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) isValidMaxLoss(_maxLossInBP) {
        RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

        registry = _registry;
        maxLossInBP = _maxLossInBP;
        depositInterval = _depositInterval;
    }

    /// @inheritdoc IDepositManager
    function addVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.add(_vToken), "DepositManager: EXISTS");
    }

    /// @inheritdoc IDepositManager
    function removeVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.remove(_vToken), "DepositManager: !FOUND");
    }

    /// @inheritdoc IDepositManager
    function setDepositInterval(uint32 _interval) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_interval > 0, "DepositManager: INVALID");
        depositInterval = _interval;
    }

    /// @inheritdoc IDepositManager
    function setMaxLoss(uint16 _maxLossInBP) external isValidMaxLoss(_maxLossInBP) onlyRole(RESERVE_MANAGER_ROLE) {
        maxLossInBP = _maxLossInBP;
    }

    /// @inheritdoc IDepositManager
    function canUpdateDeposits() external view override returns (bool) {
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            address vToken = vTokens.at(i);
            if (block.timestamp - lastDepositTimestamp[vToken] >= depositInterval) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IDepositManager
    function containsVToken(address _vToken) external view override returns (bool) {
        return vTokens.contains(_vToken);
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public virtual override {
        bool deposited;
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            IvToken vToken = IvToken(vTokens.at(i));
            if (block.timestamp - lastDepositTimestamp[address(vToken)] >= depositInterval) {
                uint _depositedBefore = vToken.deposited();
                uint _totalBefore = vToken.totalAssetSupply();

                vToken.deposit();

                require(
                    _isValidMaxLoss(_depositedBefore, _totalBefore, vToken.totalAssetSupply()),
                    "DepositManager: MAX_LOSS"
                );

                lastDepositTimestamp[address(vToken)] = uint96(block.timestamp);
                deposited = true;
            }
        }

        require(deposited, "DepositManager: !DEPOSITED");
    }

    function _isValidMaxLoss(
        uint _depositedBefore,
        uint _totalBefore,
        uint _totalAfter
    ) internal view returns (bool) {
        if (_totalAfter < _totalBefore) {
            return _totalBefore - _totalAfter <= (_depositedBefore * maxLossInBP) / BP;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

interface IDepositManager {
    /// @notice Adds vToken to vTokens list
    /// @param _vToken Address of vToken
    function addVToken(address _vToken) external;

    /// @notice Removes vToken from vTokens list
    /// @param _vToken Address of vToken
    function removeVToken(address _vToken) external;

    /// @notice Sets deposit interval
    /// @param _interval deposit interval
    function setDepositInterval(uint32 _interval) external;

    /// @notice Sets maximum loss
    /// @dev Max loss range is [0 - 10_000]
    /// @param _maxLoss Maximum loss allowed
    function setMaxLoss(uint16 _maxLoss) external;

    /// @notice Updates deposits for vTokens
    function updateDeposits() external;

    /// @notice Address of Registry
    /// @return Returns address of Registry
    function registry() external view returns (address);

    /// @notice Maximum loss allowed during depositing and withdrawal
    /// @return Returns maximum loss allowed
    function maxLossInBP() external view returns (uint16);

    /// @notice Deposit interval
    /// @return Returns deposit interval
    function depositInterval() external view returns (uint32);

    /// @notice Last deposit timestamp of given vToken address
    /// @param _vToken Address of vToken
    /// @return Returns last deposit timestamp
    function lastDepositTimestamp(address _vToken) external view returns (uint96);

    /// @notice Checks if deposits can be updated
    /// @return Returns if deposits can be updated
    function canUpdateDeposits() external view returns (bool);

    /// @notice Checks if vTokens list contains vToken
    /// @param _vToken Address of vToken
    /// @return Returns if vTokens list contains vToken
    function containsVToken(address _vToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault controller interface
/// @notice Contains common logic for VaultControllers
interface IVaultController {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event SetDepositInfo(uint _targetDepositPercentageInBP, uint percentageInBPPerStep, uint stepDuration);

    /// @notice Sets deposit info for the vault
    /// @param _targetDepositPercentageInBP Target deposit percentage
    /// @param _percentageInBPPerStep Deposit percentage per step
    /// @param _stepDuration Deposit interval duration
    function setDepositInfo(
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;

    /// @notice Deposits asset using vault controller
    function deposit() external;

    /// @notice Withdraws asset using vault controller
    function withdraw() external;

    /// @notice vToken's asset address
    /// @return Returns vToken's asset address
    function asset() external view returns (address);

    /// @notice vToken address
    /// @return Returns vToken address
    function vToken() external view returns (address);

    /// @notice Index Registry address
    /// @return Returns Index Registry address
    function registry() external view returns (address);

    /// @notice Expected amount of asset that can be withdrawn using vault controller
    /// @return Returns expected amount of token that can be withdrawn using vault controller
    function expectedWithdrawableAmount() external view returns (uint);

    /// @notice Total percentage of token amount that will be deposited using vault controller to earn interest
    /// @return Returns total percentage of token amount that will be deposited using vault controller to earn interest
    function targetDepositPercentageInBP() external view returns (uint16);

    /// @notice Percentage of token amount that will be deposited using vault controller per deposit step
    /// @return Returns percentage of token amount that will be deposited using vault controller per deposit step
    function percentageInBPPerStep() external view returns (uint16);

    /// @notice Deposit interval duration
    /// @return Returns deposit interval duration
    /// @dev    vToken deposit is updated gradually at defined intervals (steps). Every interval has time duration defined.
    ///         Deposited amount is calculated as timeElapsedFromLastDeposit / stepDuration * percentageInBPPerStep
    function stepDuration() external view returns (uint32);

    /// @notice Calculates deposit amount
    /// @param _currentDepositedPercentageInBP Current deposited percentage
    /// @return Returns deposit amount
    function calculatedDepositAmount(uint _currentDepositedPercentageInBP) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/NAV.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IVaultController.sol";

/// @title Vault token
/// @notice Contains logic for index's asset management
contract vToken is IvToken, Initializable, ReentrancyGuardUpgradeable, ERC165Upgradeable {
    using NAV for NAV.Data;
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Oracle role
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Orderer role
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IvToken
    address public override vaultController;
    /// @inheritdoc IvToken
    address public override asset;
    /// @inheritdoc IvToken
    address public override registry;

    /// @inheritdoc IvToken
    uint public override deposited;

    /// @notice NAV library used to track contract shares between indexes
    NAV.Data internal _NAV;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "vToken: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IvToken
    /// @dev also sets initial values for public variables
    function initialize(address _asset, address _registry) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "vToken: INTERFACE");
        require(_asset != address(0), "vToken: ZERO");

        __ERC165_init();
        __ReentrancyGuard_init();

        asset = _asset;
        registry = _registry;
    }

    /// @inheritdoc IvToken
    function transferAsset(address _recipient, uint _amount) external override nonReentrant {
        require(msg.sender == IIndexRegistry(registry).orderer(), "vToken: FORBIDDEN");

        _transferAsset(_recipient, _amount);
    }

    /// @inheritdoc IvToken
    function setController(address _vaultController) external override onlyRole(RESERVE_MANAGER_ROLE) {
        if (vaultController != address(0)) {
            IVaultController(vaultController).withdraw();
            _updateDeposited(0);
        }

        if (_vaultController != address(0)) {
            require(_vaultController.supportsInterface(type(IVaultController).interfaceId), "vToken: INTERFACE");
        }

        vaultController = _vaultController;
        emit SetVaultController(_vaultController);
    }

    /// @inheritdoc IvToken
    function withdraw() external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vaultController != address(0), "vToken: ZERO");

        IVaultController(vaultController).withdraw();
        _updateDeposited(0);
    }

    /// @inheritdoc IvToken
    function deposit() external override onlyRole(ORACLE_ROLE) {
        require(vaultController != address(0), "vToken: ZERO");

        uint _currentDepositedPercentageInBP = currentDepositedPercentageInBP();
        IVaultController(vaultController).withdraw();
        uint amount = IVaultController(vaultController).calculatedDepositAmount(_currentDepositedPercentageInBP);
        IERC20(asset).safeTransfer(vaultController, amount);
        IVaultController(vaultController).deposit();
        _updateDeposited(amount);
    }

    /// @inheritdoc IvToken
    function transfer(address _recipient, uint _amount) external override nonReentrant {
        _transfer(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IvToken
    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external override nonReentrant onlyRole(ORDERER_ROLE) {
        _transfer(_from, _to, _shares);
    }

    /// @inheritdoc IvToken
    function mint() external override nonReentrant onlyRole(INDEX_ROLE) returns (uint shares) {
        return _mint(msg.sender);
    }

    /// @inheritdoc IvToken
    function burn(address _recipient) external override nonReentrant onlyRole(INDEX_ROLE) returns (uint amount) {
        return _burn(_recipient);
    }

    /// @inheritdoc IvToken
    function mintFor(address _recipient) external override nonReentrant onlyRole(ORDERER_ROLE) returns (uint) {
        return _mint(_recipient);
    }

    /// @inheritdoc IvToken
    function burnFor(address _recipient) external override nonReentrant onlyRole(ORDERER_ROLE) returns (uint) {
        return _burn(_recipient);
    }

    /// @inheritdoc IvToken
    function sync() external override nonReentrant {
        _NAV.sync(totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function virtualTotalAssetSupply() external view override returns (uint) {
        if (vaultController == address(0)) {
            return IERC20(asset).balanceOf(address(this));
        }

        return IERC20(asset).balanceOf(address(this)) + IVaultController(vaultController).expectedWithdrawableAmount();
    }

    /// @inheritdoc IvToken
    function balanceOf(address _account) external view override returns (uint) {
        return _NAV.balanceOf[_account];
    }

    /// @inheritdoc IvToken
    function lastAssetBalance() external view override returns (uint) {
        return _NAV.lastAssetBalance;
    }

    /// @inheritdoc IvToken
    function mintableShares(uint _amount) external view override returns (uint) {
        return _NAV.mintableShares(_amount);
    }

    /// @inheritdoc IvToken
    function totalSupply() external view override returns (uint) {
        return _NAV.totalSupply;
    }

    /// @inheritdoc IvToken
    function lastAssetBalanceOf(address _account) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_NAV.balanceOf[_account], _NAV.lastAssetBalance);
    }

    /// @inheritdoc IvToken
    function assetBalanceOf(address _account) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_NAV.balanceOf[_account], totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function assetDataOf(address _account, uint _shares) external view override returns (AssetData memory) {
        _shares = Math.min(_shares, _NAV.balanceOf[_account]);
        return
            AssetData({ maxShares: _shares, amountInAsset: _NAV.assetBalanceForShares(_shares, totalAssetSupply()) });
    }

    /// @inheritdoc IvToken
    function assetBalanceForShares(uint _shares) external view override returns (uint) {
        return _NAV.assetBalanceForShares(_shares, totalAssetSupply());
    }

    /// @inheritdoc IvToken
    function shareChange(address _account, uint _amountInAsset)
        external
        view
        override
        returns (uint newShares, uint oldShares)
    {
        oldShares = _NAV.balanceOf[_account];
        uint _totalSupply = _NAV.totalSupply;
        if (_totalSupply > 0) {
            uint _balance = _NAV.balanceOf[_account];
            uint _assetBalance = totalAssetSupply();
            uint availableAssets = (_balance * _assetBalance) / _totalSupply;
            newShares = (_amountInAsset * (_totalSupply - oldShares)) / (_assetBalance - availableAssets);
        } else {
            newShares = _amountInAsset < NAV.INITIAL_QUANTITY ? 0 : _amountInAsset - NAV.INITIAL_QUANTITY;
        }
    }

    /// @inheritdoc IvToken
    function currentDepositedPercentageInBP() public view override returns (uint) {
        if (vaultController == address(0)) {
            return 0;
        }

        uint total = IERC20(asset).balanceOf(address(this)) + deposited;
        if (total > 0) {
            return (deposited * BP.DECIMAL_FACTOR) / total;
        }

        return 0;
    }

    /// @inheritdoc IvToken
    function totalAssetSupply() public view override returns (uint) {
        return IERC20(asset).balanceOf(address(this)) + deposited;
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IvToken).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Mints shares to `_recipient` address
    /// @param _recipient Shares recipient
    /// @return shares Amount of minted shares
    function _mint(address _recipient) internal returns (uint shares) {
        uint _totalAssetSupply = totalAssetSupply();
        shares = _NAV.mint(_totalAssetSupply, _recipient);
        _NAV.sync(_totalAssetSupply);
    }

    /// @notice Burns shares from `_recipient` address
    /// @param _recipient Recipient of assets from burnt shares
    /// @return amount Amount of asset for burnt shares
    function _burn(address _recipient) internal returns (uint amount) {
        amount = _NAV.burn(totalAssetSupply());
        _transferAsset(_recipient, amount);
        _NAV.sync(totalAssetSupply());
    }

    /// @notice Transfers `_amount` of shares from one address to another
    /// @param _from Address to transfer shares from
    /// @param _to Address to transfer shares to
    /// @param _amount Amount of shares to transfer
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal {
        _NAV.transfer(_from, _to, _amount);
    }

    /// @notice Transfers `_amount` of asset to `_recipient` address
    /// @param _recipient Recipient of assets
    /// @param _amount Amount of assets to transfer
    function _transferAsset(address _recipient, uint _amount) internal {
        uint balance = IERC20(asset).balanceOf(address(this));
        if (balance < _amount && vaultController != address(0)) {
            IVaultController(vaultController).withdraw();
            _updateDeposited(0);
            balance = IERC20(asset).balanceOf(address(this));
        }

        IERC20(asset).safeTransfer(_recipient, Math.min(_amount, balance));
    }

    /// @notice Updates deposited value
    function _updateDeposited(uint _deposited) internal {
        deposited = _deposited;
        _NAV.sync(totalAssetSupply());
        emit UpdateDeposit(msg.sender, deposited);
    }

    uint256[42] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/// @title NAV library
/// @notice Library for transfer, mint, burn and distribute vToken shares
/// @dev Used in conjunction with vToken
library NAV {
    event VTokenTransfer(address indexed from, address indexed to, uint amount);

    /// @notice Initial shares quantity
    uint internal constant INITIAL_QUANTITY = 10000;

    struct Data {
        uint lastAssetBalance;
        uint totalSupply;
        mapping(address => uint) balanceOf;
    }

    /// @notice Transfer `_amount` of shares between given addresses
    /// @param _from Account to send shares from
    /// @param _to Account to send shares to
    /// @param _amount Amount of shares to send
    function transfer(
        Data storage self,
        address _from,
        address _to,
        uint _amount
    ) internal {
        self.balanceOf[_from] = self.balanceOf[_from] - _amount;
        self.balanceOf[_to] = self.balanceOf[_to] + _amount;
        emit VTokenTransfer(_from, _to, _amount);
    }

    /// @notice Mints shares to the `_recipient` account
    /// @param self Data structure reference
    /// @param _balance New shares maximum limit
    /// @param _recipient Recipient that will receive minted shares
    function mint(
        Data storage self,
        uint _balance,
        address _recipient
    ) internal returns (uint shares) {
        uint amount = _balance - self.lastAssetBalance;
        uint _totalSupply = self.totalSupply;
        if (_totalSupply != 0) {
            shares = (amount * _totalSupply) / self.lastAssetBalance;
        } else {
            shares = amount - INITIAL_QUANTITY;
            _mint(self, address(0), INITIAL_QUANTITY);
        }

        require(shares != 0, "NAV: INSUFFICIENT_AMOUNT");

        _mint(self, _recipient, shares);
    }

    /// @notice Burns shares from the `_recipient` account
    /// @param self Data structure reference
    /// @param _balance Shares balance
    function burn(Data storage self, uint _balance) internal returns (uint amount) {
        uint value = self.balanceOf[address(this)];
        amount = (value * _balance) / self.totalSupply;
        require(amount != 0, "NAV: INSUFFICIENT_SHARES_BURNED");

        _burn(self, address(this), value);
    }

    /// @notice Synchronizes token balances
    /// @param self Data structure reference
    /// @param _newBalance Total asset amount
    function sync(Data storage self, uint _newBalance) internal {
        if (self.lastAssetBalance != _newBalance) {
            self.lastAssetBalance = _newBalance;
        }
    }

    /// @notice Returns amount of tokens corresponding to the given `_shares` amount
    /// @param self Data structure reference
    /// @param _shares Amount of shares
    /// @param _balance Shares balance
    /// @return Amount of tokens corresponding to given shares
    function assetBalanceForShares(
        Data storage self,
        uint _shares,
        uint _balance
    ) internal view returns (uint) {
        uint _totalSupply = self.totalSupply;

        return _totalSupply != 0 ? (_shares * _balance) / _totalSupply : 0;
    }

    /// @notice Returns amount of shares that will be minted for the given tokens amount
    /// @param self Data structure reference
    /// @param _amount Tokens amount
    /// @return Amount of mintable shares
    function mintableShares(Data storage self, uint _amount) internal view returns (uint) {
        uint _totalSupply = self.totalSupply;

        return _totalSupply != 0 ? (_amount * _totalSupply) / self.lastAssetBalance : _amount - INITIAL_QUANTITY;
    }

    /// @notice Mints shares for the given account
    /// @param self Data structure reference
    /// @param _account Account to mint shares for
    /// @param _amount Amount shares to mint
    function _mint(
        Data storage self,
        address _account,
        uint _amount
    ) internal {
        self.balanceOf[_account] = self.balanceOf[_account] + _amount;
        self.totalSupply += _amount;
        emit VTokenTransfer(address(0), _account, _amount);
    }

    /// @notice Burns shares of the given account
    /// @param self Data structure reference
    /// @param _account Account to burn shares of
    /// @param _amount Amount shares to burn
    function _burn(
        Data storage self,
        address _account,
        uint _amount
    ) internal {
        self.balanceOf[_account] = self.balanceOf[_account] - _amount;
        self.totalSupply -= _amount;
        emit VTokenTransfer(_account, address(0), _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../vToken.sol";

contract vTokenV2Test is vToken {
    function test() external pure returns (string memory) {
        return "Success";
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./libraries/IndexLibrary.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPhuturePriceOracle.sol";
import "./interfaces/IManagedIndexReweightingLogic.sol";

import "./IndexLayout.sol";

/// @title ManagedIndex reweighting logic
/// @notice Contains reweighting logic
contract ManagedIndexReweightingLogic is IndexLayout, IManagedIndexReweightingLogic, ERC165 {
    using FullMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Asset role
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @inheritdoc IManagedIndexReweightingLogic
    function reweight(address[] calldata _updatedAssets, uint8[] calldata _updatedWeights) external override {
        uint updatedAssetsCount = _updatedAssets.length;
        require(updatedAssetsCount > 1 && updatedAssetsCount == _updatedWeights.length, "ManagedIndex: INVALID");

        IPhuturePriceOracle oracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
        uint virtualEvaluationInBase;

        uint activeAssetCount = assets.length();
        uint totalAssetCount = activeAssetCount + inactiveAssets.length();
        for (uint i; i < totalAssetCount; ) {
            address asset = i < activeAssetCount ? assets.at(i) : inactiveAssets.at(i - activeAssetCount);
            uint assetBalance = IvToken(IvTokenFactory(vTokenFactory).createdVTokenOf(asset)).assetBalanceOf(
                address(this)
            );
            virtualEvaluationInBase += assetBalance.mulDiv(FixedPoint112.Q112, oracle.refreshedAssetPerBaseInUQ(asset));

            unchecked {
                i = i + 1;
            }
        }

        IOrderer orderer = IOrderer(IIndexRegistry(registry).orderer());
        uint orderId = orderer.placeOrder();

        uint _totalWeight = IndexLibrary.MAX_WEIGHT;

        for (uint i; i < updatedAssetsCount; ) {
            address asset = _updatedAssets[i];
            require(asset != address(0), "ManagedIndex: ZERO");

            if (i != 0) {
                // makes sure that there are no duplicate assets
                require(_updatedAssets[i - 1] < asset, "ManagedIndex: SORT");
            }

            uint8 newWeight = _updatedWeights[i];
            if (newWeight != 0) {
                require(IAccessControl(registry).hasRole(ASSET_ROLE, asset), "ManagedIndex: INVALID_ASSET");
                assets.add(asset);
                inactiveAssets.remove(asset);

                uint8 prevWeight = weightOf[asset];
                if (prevWeight != newWeight) {
                    emit UpdateAnatomy(asset, newWeight);
                }

                _totalWeight = _totalWeight + newWeight - prevWeight;
                weightOf[asset] = newWeight;

                uint amountInBase = (virtualEvaluationInBase * weightOf[asset]) / IndexLibrary.MAX_WEIGHT;
                uint amountInAsset = amountInBase.mulDiv(oracle.refreshedAssetPerBaseInUQ(asset), FixedPoint112.Q112);
                (uint newShares, uint oldShares) = IvToken(IvTokenFactory(vTokenFactory).createdVTokenOf(asset))
                    .shareChange(address(this), amountInAsset);

                if (newShares > oldShares) {
                    orderer.addOrderDetails(orderId, asset, newShares - oldShares, IOrderer.OrderSide.Buy);
                } else if (oldShares > newShares) {
                    orderer.addOrderDetails(orderId, asset, oldShares - newShares, IOrderer.OrderSide.Sell);
                }
            } else {
                require(assets.remove(asset), "ManagedIndex: INVALID");

                inactiveAssets.add(asset);
                _totalWeight -= weightOf[asset];

                delete weightOf[asset];

                emit UpdateAnatomy(asset, 0);
            }

            unchecked {
                i = i + 1;
            }
        }

        require(assets.length() <= IIndexRegistry(registry).maxComponents(), "ManagedIndex: COMPONENTS");

        address[] memory _inactiveAssets = inactiveAssets.values();

        uint inactiveAssetsCount = _inactiveAssets.length;
        for (uint i; i < inactiveAssetsCount; ) {
            address inactiveAsset = _inactiveAssets[i];
            uint shares = IvToken(IvTokenFactory(vTokenFactory).vTokenOf(inactiveAsset)).balanceOf(address(this));
            if (shares > 0) {
                orderer.addOrderDetails(orderId, inactiveAsset, shares, IOrderer.OrderSide.Sell);
            } else {
                inactiveAssets.remove(inactiveAsset);
                emit AssetRemoved(inactiveAsset);
            }

            unchecked {
                i = i + 1;
            }
        }

        require(_totalWeight == IndexLibrary.MAX_WEIGHT, "ManagedIndex: MAX");
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IManagedIndexReweightingLogic).interfaceId || super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./libraries/BP.sol";
import "./libraries/IndexLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IvToken.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIndexRouter.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/external/IWETH.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Index router
/// @notice Contains methods allowing to mint and redeem index tokens in exchange for various assets
contract IndexRouter is IIndexRouter, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using FullMath for uint;
    using SafeERC20 for IERC20;
    using IndexLibrary for uint;
    using ERC165Checker for address;

    struct MintDetails {
        uint minAmountInBase;
        uint[] amountsInBase;
        uint[] inputAmountInToken;
        IvTokenFactory vTokenFactory;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Asset role
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Exchange admin role
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");
    /// @notice Skipped asset role
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Exchange target role
    bytes32 internal constant EXCHANGE_TARGET_ROLE = keccak256("EXCHANGE_TARGET_ROLE");

    /// @inheritdoc IIndexRouter
    address public override WETH;
    /// @inheritdoc IIndexRouter
    address public override registry;

    /// @notice Checks if `_index` has INDEX_ROLE
    /// @param _index Index address
    modifier isValidIndex(address _index) {
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _index), "IndexRouter: INVALID");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IIndexRouter
    function initialize(address _WETH, address _registry) external override initializer {
        require(_WETH != address(0), "IndexRouter: ZERO");

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "IndexRouter: INTERFACE");

        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        WETH = _WETH;
        registry = _registry;
    }

    /// @inheritdoc IIndexRouter
    /// @dev only accept ETH via fallback from the WETH contract
    receive() external payable override {
        require(msg.sender == WETH);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapIndexAmount(MintSwapParams calldata _params) external view override returns (uint _amount) {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_params.index).anatomy();

        uint assetBalanceInBase;
        uint minAmountInBase = type(uint).max;

        for (uint i; i < _weights.length; ) {
            if (_weights[i] != 0) {
                uint _amount = _params.quotes[i].buyAssetMinAmount;

                uint assetPerBaseInUQ = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
                    .lastAssetPerBaseInUQ(_assets[i]);
                {
                    uint _minAmountInBase = _amount.mulDiv(
                        FixedPoint112.Q112 * IndexLibrary.MAX_WEIGHT,
                        assetPerBaseInUQ * _weights[i]
                    );
                    if (_minAmountInBase < minAmountInBase) {
                        minAmountInBase = _minAmountInBase;
                    }
                }

                IvToken vToken = IvToken(IvTokenFactory(IIndex(_params.index).vTokenFactory()).vTokenOf(_assets[i]));
                if (address(vToken) != address(0)) {
                    assetBalanceInBase += vToken.lastAssetBalanceOf(_params.index).mulDiv(
                        FixedPoint112.Q112,
                        assetPerBaseInUQ
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        IPhuturePriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
        {
            address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

            uint inactiveAssetsCount = inactiveAssets.length;
            for (uint i; i < inactiveAssetsCount; ) {
                address inactiveAsset = inactiveAssets[i];
                if (!IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, inactiveAsset)) {
                    uint balanceInAsset = IvToken(
                        IvTokenFactory((IIndex(_params.index).vTokenFactory())).vTokenOf(inactiveAsset)
                    ).lastAssetBalanceOf(_params.index);

                    assetBalanceInBase += balanceInAsset.mulDiv(
                        FixedPoint112.Q112,
                        priceOracle.lastAssetPerBaseInUQ(inactiveAsset)
                    );
                }
                unchecked {
                    i = i + 1;
                }
            }
        }

        assert(minAmountInBase != type(uint).max);

        uint8 _indexDecimals = IERC20Metadata(_params.index).decimals();
        if (IERC20(_params.index).totalSupply() != 0) {
            _amount =
                (priceOracle.convertToIndex(minAmountInBase, _indexDecimals) * IERC20(_params.index).totalSupply()) /
                priceOracle.convertToIndex(assetBalanceInBase, _indexDecimals);
        } else {
            _amount = priceOracle.convertToIndex(minAmountInBase, _indexDecimals) - IndexLibrary.INITIAL_QUANTITY;
        }

        uint256 fee = (_amount * IFeePool(IIndexRegistry(registry).feePool()).mintingFeeInBPOf(_params.index)) /
            BP.DECIMAL_FACTOR;
        _amount -= fee;
    }

    /// @inheritdoc IIndexRouter
    function burnTokensAmount(address _index, uint _amount) external view override returns (uint[] memory _amounts) {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_index).anatomy();
        address[] memory inactiveAssets = IIndex(_index).inactiveAnatomy();
        _amounts = new uint[](_weights.length + inactiveAssets.length);

        uint assetsCount = _assets.length;

        bool containsBlacklistedAssets;
        for (uint i; i < assetsCount; ) {
            if (!IAccessControl(registry).hasRole(ASSET_ROLE, _assets[i])) {
                containsBlacklistedAssets = true;
                break;
            }

            unchecked {
                i = i + 1;
            }
        }

        if (!containsBlacklistedAssets) {
            _amount -=
                (_amount * IFeePool(IIndexRegistry(registry).feePool()).burningFeeInBPOf(_index)) /
                BP.DECIMAL_FACTOR;
        }

        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        for (uint i; i < totalAssetsCount; ) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            if (!(containsBlacklistedAssets && IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, asset))) {
                uint indexAssetBalance = IvToken(IvTokenFactory(IIndex(_index).vTokenFactory()).vTokenOf(asset))
                    .assetBalanceOf(_index);

                _amounts[i] = (_amount * indexAssetBalance) / IERC20(_index).totalSupply();
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndexRouter
    function mint(MintParams calldata _params)
        external
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IIndex index = IIndex(_params.index);
        (address[] memory _assets, uint8[] memory _weights) = index.anatomy();

        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IPriceOracle oracle = IPriceOracle(IIndexRegistry(registry).priceOracle());

        uint assetsCount = _assets.length;
        for (uint i; i < assetsCount; ) {
            if (_weights[i] > 0) {
                address asset = _assets[i];
                IERC20(asset).safeTransferFrom(
                    msg.sender,
                    vTokenFactory.createdVTokenOf(_assets[i]),
                    oracle.refreshedAssetPerBaseInUQ(asset).amountInAsset(_weights[i], _params.amountInBase)
                );
            }

            unchecked {
                i = i + 1;
            }
        }

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        index.mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function mintSwap(MintSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IERC20(_params.inputToken).safeTransferFrom(msg.sender, address(this), _params.amountInInputToken);
        _mint(_params.index, _params.inputToken, _params.amountInInputToken, _params.quotes);

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        IIndex(_params.index).mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function mintSwapWithPermit(
        MintSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.inputToken).permit(
            msg.sender,
            address(this),
            _params.amountInInputToken,
            _deadline,
            _v,
            _r,
            _s
        );

        return mintSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapValue(MintSwapValueParams calldata _params)
        external
        payable
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        IWETH(WETH).deposit{ value: msg.value }();
        _mint(_params.index, WETH, msg.value, _params.quotes);

        uint balance = IERC20(_params.index).balanceOf(_params.recipient);
        IIndex(_params.index).mint(_params.recipient);

        return IERC20(_params.index).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function burn(BurnParams calldata _params) public override nonReentrant isValidIndex(_params.index) {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(_params.recipient);
    }

    /// @inheritdoc IIndexRouter
    function burnWithAmounts(BurnParams calldata _params)
        external
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint[] memory _amounts)
    {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);

        (address[] memory _assets, ) = IIndex(_params.index).anatomy();
        uint assetsCount = _assets.length;
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        uint[] memory balancesBefore = new uint[](totalAssetsCount);
        for (uint i; i < totalAssetsCount; ++i) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            balancesBefore[i] = IERC20(asset).balanceOf(_params.recipient);
        }

        IIndex(_params.index).burn(_params.recipient);

        _amounts = new uint[](totalAssetsCount);
        for (uint i; i < totalAssetsCount; ++i) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            _amounts[i] = IERC20(asset).balanceOf(_params.recipient) - balancesBefore[i];
        }
    }

    /// @inheritdoc IIndexRouter
    function burnSwap(BurnSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint)
    {
        _burn(_params);

        uint balance = IERC20(_params.outputAsset).balanceOf(_params.recipient);
        IERC20(_params.outputAsset).safeTransfer(
            _params.recipient,
            IERC20(_params.outputAsset).balanceOf(address(this))
        );

        return IERC20(_params.outputAsset).balanceOf(_params.recipient) - balance;
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValue(BurnSwapParams calldata _params)
        public
        override
        nonReentrant
        isValidIndex(_params.index)
        returns (uint wethBalance)
    {
        require(_params.outputAsset == WETH, "IndexRouter: OUTPUT_ASSET");
        _burn(_params);
        wethBalance = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(wethBalance);
        TransferHelper.safeTransferETH(_params.recipient, wethBalance);
    }

    /// @inheritdoc IIndexRouter
    function burnWithPermit(
        BurnParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        burn(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        return burnSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        return burnSwapValue(_params);
    }

    /// @notice Swaps and sends assets in certain proportions to vTokens to mint index
    /// @param _index Index token address
    /// @param _inputToken Input token address
    /// @param _amountInInputToken Amount in input token
    /// @param _quotes Quotes for each asset
    function _mint(
        address _index,
        address _inputToken,
        uint _amountInInputToken,
        MintQuoteParams[] calldata _quotes
    ) internal {
        uint quotesCount = _quotes.length;
        IvTokenFactory vTokenFactory = IvTokenFactory(IIndex(_index).vTokenFactory());
        uint _inputBalanceBefore = IERC20(_inputToken).balanceOf(address(this));
        for (uint i; i < quotesCount; i++) {
            address asset = _quotes[i].asset;

            // if one of the assets is inputToken we transfer it directly to the vault
            if (asset == _inputToken) {
                IERC20(_inputToken).safeTransfer(
                    vTokenFactory.createdVTokenOf(_inputToken),
                    _quotes[i].buyAssetMinAmount
                );
                continue;
            }
            address swapTarget = _quotes[i].swapTarget;
            require(IAccessControl(registry).hasRole(EXCHANGE_TARGET_ROLE, swapTarget), "IndexRouter: INVALID_TARGET");
            _safeApprove(_inputToken, swapTarget, _amountInInputToken);
            // execute the swap with the quote for the asset
            _fillQuote(swapTarget, _quotes[i].assetQuote);
            uint assetBalanceAfter = IERC20(asset).balanceOf(address(this));
            require(assetBalanceAfter >= _quotes[i].buyAssetMinAmount, "IndexRouter: UNDERBOUGHT_ASSET");
            IERC20(asset).safeTransfer(vTokenFactory.createdVTokenOf(asset), assetBalanceAfter);
        }
        require(
            _inputBalanceBefore - IERC20(_inputToken).balanceOf(address(this)) == _amountInInputToken,
            "IndexRouter: INVALID_INPUT_AMOUNT"
        );
    }

    /// @notice Burns index and swaps assets to the output asset
    /// @param _params Contains the quotes for each asset, output asset and other details
    function _burn(BurnSwapParams calldata _params) internal {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(address(this));

        (address[] memory assets, ) = IIndex(_params.index).anatomy();
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

        uint assetsCount = assets.length;
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        IPriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
        for (uint i; i < totalAssetsCount; ) {
            IERC20 inputAsset = IERC20(i < assetsCount ? assets[i] : inactiveAssets[i - assetsCount]);
            uint inputAssetBalanceBefore = inputAsset.balanceOf(address(this));
            // if asset is input asset no need to swap => (address(inputAsset) != _params.outputAsset)
            if (inputAssetBalanceBefore > 0 && address(inputAsset) != _params.outputAsset) {
                // if the amount of asset is less than minimum directly transfer to the user
                if (
                    inputAssetBalanceBefore.mulDiv(
                        FixedPoint112.Q112,
                        priceOracle.refreshedAssetPerBaseInUQ(address(inputAsset))
                    ) < MIN_SWAP_AMOUNT
                ) {
                    inputAsset.safeTransfer(_params.recipient, inputAssetBalanceBefore);
                }
                // otherwise exchange the asset for the desired output asset
                else {
                    address swapTarget = _params.quotes[i].swapTarget;
                    require(
                        IAccessControl(registry).hasRole(EXCHANGE_TARGET_ROLE, swapTarget),
                        "IndexRouter: INVALID_TARGET"
                    );
                    uint outputAssetBalanceBefore = IERC20(_params.outputAsset).balanceOf(address(this));

                    _safeApprove(address(inputAsset), swapTarget, inputAssetBalanceBefore);
                    _fillQuote(swapTarget, _params.quotes[i].assetQuote);

                    // checks if all input asset was exchanged and output asset generated from the swap is greater than minOutputAmount desired.
                    // it is important to estimate correctly the inputAmount for each asset for the index amount to burn,
                    // otherwise the transaction will revert due to over or under estimation.
                    // this ensures if all swaps are successful there is no leftover assets in indexRouter's ownership.
                    require(
                        IERC20(_params.outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore >=
                            _params.quotes[i].buyAssetMinAmount,
                        "IndexRouter: INVALID_SWAP"
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Fills the quote for the `_swapTarget` with the `quote`
    /// @param _swapTarget Swap target address
    /// @param _quote Quote to fill
    function _fillQuote(address _swapTarget, bytes memory _quote) internal {
        (bool success, bytes memory returnData) = _swapTarget.call(_quote);
        if (!success) {
            if (returnData.length == 0) {
                revert("IndexRouter: INVALID_SWAP");
            } else {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }
    }

    /// @notice Approves the `_spender` to spend `_requiredAllowance` of `_token`
    /// @param _token Token address
    /// @param _spender Spender address
    /// @param _requiredAllowance Required allowance
    function _safeApprove(
        address _token,
        address _spender,
        uint _requiredAllowance
    ) internal {
        uint allowance = IERC20(_token).allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            IERC20(_token).safeIncreaseAllowance(_spender, type(uint256).max - allowance);
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override {
        require(IAccessControl(registry).hasRole(EXCHANGE_ADMIN_ROLE, msg.sender), "IndexRouter: FORBIDDEN");
    }

    uint256[44] private __gap;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IYakStrategyPayable.sol";
import "./interfaces/IYakStrategyController.sol";
import "../interfaces/external/IWETH.sol";

import "../BaseVaultController.sol";

/// @title Yearn vault controller
/// @notice Contains logic for depositing into into the Yearn Protocol
contract YakStrategyPayableController is IYakStrategyController, BaseVaultController {
    /// @inheritdoc IYakStrategyController
    address public override strategy;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    receive() external payable {
        require(msg.sender == strategy || msg.sender == asset, "Controller: RECEIVE");
    }

    /// @inheritdoc IYakStrategyController
    function initialize(
        address _vToken,
        address _strategy,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override initializer {
        require(IYakStrategyPayable(_strategy).depositToken() == address(0), "Controller: INVALID");

        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        strategy = _strategy;
    }

    /// @inheritdoc IVaultController
    function expectedWithdrawableAmount() external view override returns (uint) {
        return IYakStrategyPayable(strategy).getDepositTokensForShares(IERC20(strategy).balanceOf(address(this)));
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IYakStrategyController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Deposits assets
    /// @param _amount Deposit amount
    function _deposit(uint _amount) internal override {
        if (_amount != 0) {
            IWETH(asset).withdraw(_amount);
            IYakStrategyPayable(strategy).deposit{ value: _amount }();
        }
    }

    /// @notice Withdraws deposited assets
    function _withdraw() internal override {
        uint amount = IERC20(strategy).balanceOf(address(this));
        if (amount != 0) {
            IERC20(strategy).approve(strategy, amount);
            IYakStrategyPayable(strategy).withdraw(amount);
            IWETH(asset).deposit{ value: address(this).balance }();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title YieldYak Strategy Interface
/// @notice Describes YieldYak Strategy methods
interface IYakStrategyPayable {
    /// @notice Deposits value to YieldYak Strategy
    function deposit() external payable;

    /// @notice Withdraws amount from YieldYak Strategy
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external;

    /// @notice Returns amount of deposited tokens for shares
    /// @param amount Amount of shares
    /// @return deposit tokens for shares
    function getDepositTokensForShares(uint amount) external view returns (uint);

    /// @notice Returns number decimals of Strategy
    /// @return Number of decimals
    function decimals() external view returns (uint);

    /// @notice Deposit token
    /// @return Returns deposit token address
    function depositToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title YieldYak vault controller interface
/// @notice Contains logic for depositing into into the YieldYak Protocol
interface IYakStrategyController {
    /// @notice YieldYak strategy address
    /// @return Returns YieldYak strategy address
    function strategy() external returns (address);

    /// @notice Initializes YieldYak vault controller with the given parameters
    /// @param _vToken vToken address
    /// @param _strategy YieldYak strategy's address
    function initialize(
        address _vToken,
        address _strategy,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IVaultController.sol";

/// @title Base vault controller
/// @notice Contains common logic for VaultControllers
abstract contract BaseVaultController is
    IVaultController,
    UUPSUpgradeable,
    ERC165Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IVaultController
    address public override asset;

    /// @inheritdoc IVaultController
    address public override vToken;

    /// @inheritdoc IVaultController
    address public override registry;

    /// @notice Timestamp of last deposit
    uint32 private lastDepositUpdateTimestamp;

    /// @inheritdoc IVaultController
    uint32 public override stepDuration;

    /// @inheritdoc IVaultController
    uint16 public override targetDepositPercentageInBP;
    /// @inheritdoc IVaultController
    uint16 public override percentageInBPPerStep;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "VaultController: FORBIDDEN");
        _;
    }

    /// @notice Requires msg.sender to be a vToken
    modifier onlyVToken() {
        require(msg.sender == vToken, "VaultController: FORBIDDEN");
        _;
    }

    /// @inheritdoc IVaultController
    function setDepositInfo(
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(
            _stepDuration > 0 &&
                _targetDepositPercentageInBP > 0 &&
                _targetDepositPercentageInBP <= BP.DECIMAL_FACTOR &&
                _percentageInBPPerStep > 0 &&
                _percentageInBPPerStep <= BP.DECIMAL_FACTOR,
            "VaultController: INVALID_DEPOSIT_INFO"
        );

        targetDepositPercentageInBP = _targetDepositPercentageInBP;
        percentageInBPPerStep = _percentageInBPPerStep;
        stepDuration = _stepDuration;

        emit SetDepositInfo(_targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);
    }

    /// @inheritdoc IVaultController
    function deposit() external override nonReentrant onlyVToken {
        uint balance = IERC20(asset).balanceOf(address(this));
        if (balance != 0) {
            _deposit(balance);
            lastDepositUpdateTimestamp = uint32(block.timestamp);
        }

        emit Deposit(balance);
    }

    /// @inheritdoc IVaultController
    function withdraw() external override nonReentrant onlyVToken {
        _withdraw();

        IERC20 _asset = IERC20(asset);
        uint balance = _asset.balanceOf(address(this));
        if (balance != 0) {
            _asset.safeTransfer(vToken, balance);
        }

        emit Withdraw(balance);
    }

    /// @inheritdoc IVaultController
    function calculatedDepositAmount(uint _currentDepositedPercentageInBP) external view override returns (uint) {
        uint newPercentageInBP = _calculateNewPercentageInBP(_currentDepositedPercentageInBP);

        return newPercentageInBP != 0 ? (IERC20(asset).balanceOf(vToken) * newPercentageInBP) / BP.DECIMAL_FACTOR : 0;
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IVaultController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Initializes vault controller with the given parameters
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    /// @param _vToken vToken contract address
    /// @param _targetDepositPercentageInBP total percentage of asset to be deposited
    /// @param _percentageInBPPerStep percentage to deposit per step
    /// @param _stepDuration timestamp between deposit steps
    function __BaseVaultController_init(
        address _vToken,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) internal onlyInitializing {
        require(_vToken.supportsInterface(type(IvToken).interfaceId), "VaultController: INTERFACE");

        __ERC165_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        vToken = _vToken;
        asset = IvToken(_vToken).asset();
        registry = IvToken(_vToken).registry();

        targetDepositPercentageInBP = _targetDepositPercentageInBP;
        percentageInBPPerStep = _percentageInBPPerStep;
        stepDuration = _stepDuration;
        emit SetDepositInfo(_targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);
    }

    /// @notice Virtual deposit method to be overridden in derived classes
    /// @param _amount Amount of deposit
    function _deposit(uint _amount) internal virtual;

    /// @notice Virtual withdraw method to be overridden in derived classes
    function _withdraw() internal virtual;

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal view virtual override onlyRole(RESERVE_MANAGER_ROLE) {}

    /// @notice Calculates new deposited percentage in BP
    /// @param _currentDepositedPercentInBP Current deposited percentage in BP (base point)
    function _calculateNewPercentageInBP(uint _currentDepositedPercentInBP) private view returns (uint) {
        uint stepsPassed = (block.timestamp - lastDepositUpdateTimestamp) / stepDuration;
        uint percentageChangeInBP = stepsPassed * percentageInBPPerStep;

        return Math.min(targetDepositPercentageInBP, _currentDepositedPercentInBP + percentageChangeInBP);
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IYearnVault.sol";
import "./interfaces/IYearnVaultVTokenController.sol";

import "./BaseVaultController.sol";

/// @title Yearn vault controller
/// @notice Contains logic for depositing into into the Yearn Protocol
contract YearnVaultVTokenController is IYearnVaultVTokenController, BaseVaultController {
    /// @inheritdoc IYearnVaultVTokenController
    address public override vault;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IYearnVaultVTokenController
    function initialize(
        address _vToken,
        address _vault,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override initializer {
        require(IYearnVault(_vault).token() == IvToken(_vToken).asset(), "Controller: INVALID");

        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        vault = _vault;
    }

    /// @inheritdoc IVaultController
    function expectedWithdrawableAmount() external view override returns (uint) {
        if (IERC20(vault).totalSupply() == 0) {
            return 0;
        }

        uint shares = IERC20(vault).balanceOf(address(this));
        return (IYearnVault(vault).pricePerShare() * shares) / 10**IYearnVault(vault).decimals();
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IYearnVaultVTokenController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Deposits assets
    /// @param _amount Deposit amount
    function _deposit(uint _amount) internal override {
        if (_amount != 0) {
            IERC20(IvToken(vToken).asset()).approve(vault, _amount);
            IYearnVault(vault).deposit(_amount);
        }
    }

    /// @notice Withdraws deposited assets
    function _withdraw() internal override {
        uint amount = IERC20(vault).balanceOf(address(this));
        if (amount != 0) {
            IERC20(vault).approve(vault, amount);
            IYearnVault(vault).withdraw(amount);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title yToken interface
/// @notice Describes Yearn token methods
interface IYearnVault {
    /// @notice Deposits specified amount to Yearn vault
    /// @param amount Amount to deposit
    function deposit(uint amount) external;

    /// @notice Withdraws amount from Yearn vault
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external;

    /// @notice Returns price per single share
    /// @return Price per share
    function pricePerShare() external view returns (uint);

    /// @notice Returns number decimals of Vault
    /// @return Number of decimals
    function decimals() external view returns (uint);

    /// @notice yToken address
    /// @return Returns yToken address
    function token() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Yearn vault controller interface
/// @notice Contains logic for depositing into into the Yearn Protocol
interface IYearnVaultVTokenController {
    /// @notice Yearn Vault's address
    /// @return Returns Yearn Vault's address
    function vault() external returns (address);

    /// @notice Initializes Yearn vault controller with the given parameters
    /// @param _vToken vToken address
    /// @param _vault Yearn Vault's address
    function initialize(
        address _vToken,
        address _vault,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IYakStrategy.sol";
import "./interfaces/IYakStrategyController.sol";

import "../BaseVaultController.sol";

/// @title YieldYak Strategy controller
/// @notice Contains logic for depositing into the YieldYak Protocol
contract YakStrategyController is IYakStrategyController, BaseVaultController {
    /// @inheritdoc IYakStrategyController
    address public override strategy;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IYakStrategyController
    function initialize(
        address _vToken,
        address _strategy,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override initializer {
        require(IYakStrategy(_strategy).depositToken() == IvToken(_vToken).asset(), "Controller: INVALID");

        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        strategy = _strategy;
    }

    /// @inheritdoc IVaultController
    function expectedWithdrawableAmount() external view override returns (uint) {
        return IYakStrategy(strategy).getDepositTokensForShares(IERC20(strategy).balanceOf(address(this)));
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IYakStrategyController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Deposits assets
    /// @param _amount Deposit amount
    function _deposit(uint _amount) internal override {
        if (_amount != 0) {
            IERC20(IvToken(vToken).asset()).approve(strategy, _amount);
            IYakStrategy(strategy).deposit(_amount);
        }
    }

    /// @notice Withdraws deposited assets
    function _withdraw() internal override {
        uint amount = IERC20(strategy).balanceOf(address(this));
        if (amount != 0) {
            IERC20(strategy).approve(strategy, amount);
            IYakStrategy(strategy).withdraw(amount);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title YieldYak Strategy Interface
/// @notice Describes YieldYak Strategy methods
interface IYakStrategy {
    /// @notice Deposits specified amount to Yearn vault
    /// @param amount Amount to deposit
    function deposit(uint amount) external;

    /// @notice Withdraws amount from Yearn vault
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external;

    /// @notice Returns amount of deposited tokens for shares
    /// @param amount Amount of shares
    /// @return deposit tokens for shares
    function getDepositTokensForShares(uint amount) external view returns (uint);

    /// @notice Returns number decimals of Strategy
    /// @return Number of decimals
    function decimals() external view returns (uint);

    /// @notice Deposit token
    /// @return Returns deposit token address
    function depositToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./VaultStakingMock.sol";
import "../BaseVaultController.sol";

contract VaultControllerMock is BaseVaultController {
    address public staking;

    function initialize(
        address _vToken,
        address _staking,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external initializer {
        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        staking = _staking;
    }

    function _deposit(uint amount) internal override {
        IERC20(IVaultStakingMock(staking).asset()).approve(staking, amount);
        IVaultStakingMock(staking).stake(amount);
    }

    function _withdraw() internal override {
        IVaultStakingMock(staking).withdraw();
    }

    function expectedWithdrawableAmount() external view virtual override returns (uint) {
        return VaultStakingMock(staking).withdrawable();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVaultStakingMock {
    function asset() external returns (address);

    function stake(uint amount) external;

    function withdraw() external;

    function withdrawable() external view returns (uint);
}

contract VaultStakingMock is IVaultStakingMock {
    using SafeERC20 for IERC20;

    address public override asset;

    constructor(address _asset) {
        asset = _asset;
    }

    function stake(uint amount) external override {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw() external override {
        IERC20(asset).safeTransfer(msg.sender, IERC20(asset).balanceOf(address(this)));
    }

    function withdrawable() external view override returns (uint) {
        return IERC20(asset).balanceOf(address(this));
    }

    function transfer(address _recipient, uint _amount) external {
        IERC20(asset).safeTransfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "./VaultControllerMock.sol";

contract VaultControllerMockV2 is VaultControllerMock {
    function test() external pure returns (string memory) {
        return "Success";
    }

    function expectedWithdrawableAmount() external view virtual override returns (uint) {
        return VaultStakingMock(staking).withdrawable() + 1;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/UniswapV2Library.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "../../interfaces/external/IWETH.sol";

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeERC20 for IERC20;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        _transferPairAssets(tokenA, msg.sender, pair, amountA);
        _transferPairAssets(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function _transferPairAssets(
        address _token,
        address _account,
        address _pair,
        uint _amount
    ) private {
        IERC20(_token).safeTransferFrom(_account, _pair, _amount);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        IERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(WETH).deposit{ value: amountETH }();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        IERC20(token).safeTransfer(to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{ value: amounts[0] }();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{ value: amounts[0] }();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn);
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        uint amountIn = msg.value;
        IWETH(WETH).deposit{ value: amountIn }();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        IERC20(path[0]).safeTransferFrom(msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/// @title Uniswap V2 library
/// @notice Provides list of helper functions to calculate pair amounts and reserves
library UniswapV2Library {
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return token0 One of pair tokens that goes first after sorting
    /// @return token1 One of pair token that goes second after sorting
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /// @notice Returns address of pair for given tokens
    /// @param factory Uniswap V2 factory
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return pair Returns pair address of the provided tokens
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Uniswap V2 factory
    /// @param tokenA First pair token
    /// @param tokenB Second pair token
    /// @return reserveA Reserves of the token that goes first after sorting
    /// @return reserveB Reserves of the token that goes second after sorting
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @param amountA Amount of token A
    /// @param reserveA Token A reserves
    /// @param reserveB Token B reserves
    /// @return amountB Equivalent amount of token B
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA != 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA != 0 && reserveB != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    /// @param amountIn Input token amount
    /// @param reserveIn Input token reserves
    /// @param reserveOut Output token reserves
    /// @return amountOut Output token amount
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn != 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn != 0 && reserveOut != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param amountOut Output token amount
    /// @param reserveIn Input token reserves
    /// @param reserveOut Output token reserves
    /// @return amountIn Input token amount
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut != 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn != 0 && reserveOut != 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    /// @notice Performs chained getAmountOut calculations on any number of pairs
    /// @param factory Uniswap V2 factory
    /// @param amountIn Input amount for the first token
    /// @param path List of tokens, that will be used to compose pairs for chained getAmountOut calculations
    /// @return amounts Array of output amounts
    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; ) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Performs chained getAmountIn calculations on any number of pairs
    /// @param factory Uniswap V2 factory
    /// @param amountOut Output amount for the first token
    /// @param path List of tokens, that will be used to compose pairs for chained getAmountIn calculations
    /// @return amounts Array of input amounts
    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/UniswapV2OracleLibrary.sol";

import "./interfaces/IUniswapV2PriceOracle.sol";

/// @title Uniswap V2 price oracle
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
/// @dev Oracle works through base asset which is set in initialize function
contract UniswapV2PriceOracle is IUniswapV2PriceOracle, ERC165 {
    using ERC165Checker for address;
    using UniswapV2OracleLibrary for address;

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    IUniswapV2Pair immutable pair;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset0;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset1;

    uint32 internal blockTimestampLast;

    uint internal price0CumulativeLast;
    uint internal price1CumulativeLast;
    uint internal price0Average;
    uint internal price1Average;

    /// @inheritdoc IUniswapV2PriceOracle
    uint public override minUpdateInterval;

    constructor(
        address _factory,
        address _assetA,
        address _assetB,
        address _registry,
        uint _minUpdateInterval
    ) {
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "UniswapV2PriceOracle: INTERFACE");

        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

        registry = IAccessControl(_registry);
        minUpdateInterval = _minUpdateInterval;

        IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(_factory).getPair(_assetA, _assetB));
        pair = _pair;
        asset0 = _pair.token0();
        asset1 = _pair.token1();

        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "UniswapV2PriceOracle: RESERVES");

        uint _price0CumulativeLast = _pair.price0CumulativeLast();
        uint _price1CumulativeLast = _pair.price1CumulativeLast();
        (uint price0Cml, uint price1Cml, uint32 blockTimestamp) = address(_pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        price0CumulativeLast = _price0CumulativeLast;
        price1CumulativeLast = _price1CumulativeLast;
        price0Average = (price0Cml - _price0CumulativeLast) / timeElapsed;
        price1Average = (price1Cml - _price1CumulativeLast) / timeElapsed;
    }

    /// @inheritdoc IUniswapV2PriceOracle
    /// @dev Requires msg.sender to have `_role` role
    function setMinUpdateInterval(uint _minUpdateInterval) external override {
        require(registry.hasRole(ASSET_MANAGER_ROLE, msg.sender), "UniswapV2PriceOracle: FORBIDDEN");
        minUpdateInterval = _minUpdateInterval;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Updates and returns cumulative price value
    /// @dev If min update interval hasn't passed (24h), previously cached value is returned
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = address(pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed >= minUpdateInterval) {
            price0Average = (price0Cumulative - price0CumulativeLast) / timeElapsed;
            price1Average = (price1Cumulative - price1CumulativeLast) / timeElapsed;

            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
        }

        return lastAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Returns cumulative price value cached during last refresh call
    function lastAssetPerBaseInUQ(address _asset) public view override returns (uint _price) {
        if (_asset == asset0) {
            _price = price1Average;
        } else {
            require(_asset == asset1, "UniswapV2PriceOracle: UNKNOWN");

            _price = price0Average;
        }
        require(_price > 0, "UniswapV2PriceOracle: ZERO");
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPriceOracle).interfaceId ||
            _interfaceId == type(IUniswapV2PriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}

pragma solidity >=0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    /// @dev produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = uint32(block.timestamp);
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            unchecked {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
                // counterfactual
                price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap price oracle interface
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
interface IUniswapV2PriceOracle is IPriceOracle {
    /// @notice Sets minimum update interval for oracle
    /// @param _minUpdateInterval Minimum update interval for oracle
    function setMinUpdateInterval(uint _minUpdateInterval) external;

    /// @notice Minimum oracle update interval
    /// @dev If min update interval hasn't passed before update, previously cached value is returned
    /// @return Minimum update interval in seconds
    function minUpdateInterval() external view returns (uint);

    /// @notice Asset0 in the pair
    /// @return Address of asset0 in the pair
    function asset0() external view returns (address);

    /// @notice Asset1 in the pair
    /// @return Address of asset1 in the pair
    function asset1() external view returns (address);
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/ValidatorLibrary.sol";

import "./interfaces/IOrdererV2.sol";
import "./interfaces/IOrderingExecutor.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title Phuture job
/// @notice Contains signature verification and order execution logic
contract OrderingExecutor is IOrderingExecutor, Pausable {
    using ERC165Checker for address;
    using Counters for Counters.Counter;
    using ValidatorLibrary for ValidatorLibrary.Sign;

    /// @notice Validator role
    bytes32 internal immutable VALIDATOR_ROLE;
    /// @notice Order executor role
    bytes32 internal immutable ORDER_EXECUTOR_ROLE;
    /// @notice Role allows configure ordering related data/components
    bytes32 internal immutable ORDERING_MANAGER_ROLE;

    /// @notice Nonce
    Counters.Counter internal _nonce;

    /// @inheritdoc IOrderingExecutor
    address public immutable override registry;

    /// @inheritdoc IOrderingExecutor
    uint256 public override minAmountOfSigners = 1;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "OrderingExecutor: FORBIDDEN");
        _;
    }

    constructor(address _registry) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "OrderingExecutor: INTERFACE");

        VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
        ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
        ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

        registry = _registry;
    }

    /// @inheritdoc IOrderingExecutor
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_minAmountOfSigners != 0, "OrderingExecutor: INVALID");

        minAmountOfSigners = _minAmountOfSigners;
    }

    /// @inheritdoc IOrderingExecutor
    function pause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IOrderingExecutor
    function unpause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IOrderingExecutor
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
    {
        require(
            !paused() || IAccessControl(registry).hasRole(ORDER_EXECUTOR_ROLE, msg.sender),
            "OrderingExecutor: PAUSED"
        );

        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IOrderingExecutor
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
    {
        require(
            !paused() || IAccessControl(registry).hasRole(ORDER_EXECUTOR_ROLE, msg.sender),
            "OrderingExecutor: PAUSED"
        );

        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IOrderingExecutor
    function nonce() external view override returns (uint256) {
        return _nonce.current();
    }

    /// @notice Verifies that list of signatures provided by validator have signed given `_data` object
    /// @param _signs List of signatures
    /// @param _data Data object to verify signature
    function _validate(ValidatorLibrary.Sign[] calldata _signs, bytes memory _data) internal {
        uint signsCount = _signs.length;
        require(signsCount >= minAmountOfSigners, "OrderingExecutor: !ENOUGH_SIGNERS");

        address lastAddress = address(0);
        for (uint i; i < signsCount; ) {
            address signer = _signs[i].signer;
            require(uint160(signer) > uint160(lastAddress), "OrderingExecutor: UNSORTED");
            require(
                _signs[i].verify(_data, _useNonce()) && IAccessControl(registry).hasRole(VALIDATOR_ROLE, signer),
                string.concat("OrderingExecutor: SIGN ", Strings.toHexString(uint160(signer), 20))
            );

            lastAddress = signer;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return the current value of nonce and increment
    /// @return current Current nonce of signer
    function _useNonce() internal virtual returns (uint256 current) {
        current = _nonce.current();
        _nonce.increment();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "../libraries/ValidatorLibrary.sol";

import "./IOrdererV2.sol";

/// @title Ordering Executor interface
/// @notice Contains signature verification and order execution logic
interface IOrderingExecutor {
    /// @notice Pause order execution
    function pause() external;

    /// @notice Unpause order execution
    function unpause() external;

    /// @notice Sets minimum amount of signers required to sign an order
    /// @param _minAmountOfSigners Minimum amount of signers required to sign an order
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external;

    /// @notice Swap shares internally
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Nonce of signer
    /// @return Returns nonce of given signer
    function nonce() external view returns (uint256);

    /// @notice Minimum amount of signers required to sign an order
    /// @return Returns minimum amount of signers required to sign an order
    function minAmountOfSigners() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../libraries/ValidatorLibrary.sol";

contract TestValidatorLibrary {
    using ValidatorLibrary for ValidatorLibrary.Sign;

    function verify(
        ValidatorLibrary.Sign calldata sign,
        bytes memory _data,
        uint _nonce
    ) external view returns (bool) {
        return sign.verify(_data, _nonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20ForTest is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialAccount,
        uint256 _initialBalance
    ) ERC20(_name, _symbol) {
        _mint(_initialAccount, _initialBalance);
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }

    function transferInternal(
        address _from,
        address _to,
        uint256 _value
    ) public {
        _transfer(_from, _to, _value);
    }

    function approveInternal(
        address _owner,
        address _spender,
        uint256 _value
    ) public {
        _approve(_owner, _spender, _value);
    }

    function deposit(uint256 _amount) external payable {
        // Function added for compatibility with WETH
    }
}

// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./libraries/LiquidityAmounts.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/FixedPoint96.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";

import "../interfaces/external/IWeth9.sol";
import "../interfaces/IUniV3PairManager.sol";

import "./peripherals/Governable.sol";

contract UniV3PairManager is IUniV3PairManager, Governable {
    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @inheritdoc IERC20
    uint256 public override totalSupply = 0;

    /// @inheritdoc IPairManager
    address public immutable override token0;

    /// @inheritdoc IPairManager
    address public immutable override token1;

    /// @inheritdoc IPairManager
    address public immutable override pool;

    /// @inheritdoc IUniV3PairManager
    uint24 public immutable override fee;

    /// @inheritdoc IUniV3PairManager
    uint160 public immutable override sqrtRatioAX96;

    /// @inheritdoc IUniV3PairManager
    uint160 public immutable override sqrtRatioBX96;

    /// @notice Lowest possible tick in the Uniswap's curve
    int24 private constant _TICK_LOWER = -887200;

    /// @notice Highest possible tick in the Uniswap's curve
    int24 private constant _TICK_UPPER = 887200;

    /// @inheritdoc IERC20Metadata
    //solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = 18;

    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @inheritdoc IERC20
    mapping(address => uint256) public override balanceOf;

    /// @notice Struct that contains token0, token1, and fee of the Uniswap pool
    PoolAddress.PoolKey private _poolKey;

    constructor(address _pool, address _governance) Governable(_governance) {
        pool = _pool;
        uint24 _fee = IUniswapV3Pool(_pool).fee();
        fee = _fee;
        address _token0 = IUniswapV3Pool(_pool).token0();
        address _token1 = IUniswapV3Pool(_pool).token1();
        token0 = _token0;
        token1 = _token1;
        name = string(abi.encodePacked("Keep3rLP - ", ERC20(_token0).symbol(), "/", ERC20(_token1).symbol()));
        symbol = string(abi.encodePacked("kLP-", ERC20(_token0).symbol(), "/", ERC20(_token1).symbol()));
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_TICK_LOWER);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_TICK_UPPER);
        _poolKey = PoolAddress.PoolKey({ token0: _token0, token1: _token1, fee: _fee });
    }

    // This low-level function should be called from a contract which performs important safety checks
    /// @inheritdoc IUniV3PairManager
    function mint(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external override returns (uint128 liquidity) {
        (liquidity, , ) = _addLiquidity(amount0Desired, amount1Desired, amount0Min, amount1Min);
        _mint(to, liquidity);
    }

    /// @inheritdoc IUniV3PairManager
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        if (msg.sender != pool) revert OnlyPool();
        if (amount0Owed > 0) _pay(decoded._poolKey.token0, decoded.payer, pool, amount0Owed);
        if (amount1Owed > 0) _pay(decoded._poolKey.token1, decoded.payer, pool, amount1Owed);
    }

    /// @inheritdoc IUniV3PairManager
    function burn(
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = IUniswapV3Pool(pool).burn(_TICK_LOWER, _TICK_UPPER, liquidity);

        if (amount0 < amount0Min || amount1 < amount1Min) revert ExcessiveSlippage();

        IUniswapV3Pool(pool).collect(to, _TICK_LOWER, _TICK_UPPER, uint128(amount0), uint128(amount1));
        _burn(msg.sender, liquidity);
    }

    /// @inheritdoc IUniV3PairManager
    function collect() external override onlyGovernance returns (uint256 amount0, uint256 amount1) {
        (, , , uint128 tokensOwed0, uint128 tokensOwed1) = IUniswapV3Pool(pool).positions(
            keccak256(abi.encodePacked(address(this), _TICK_LOWER, _TICK_UPPER))
        );
        (amount0, amount1) = IUniswapV3Pool(pool).collect(
            governance,
            _TICK_LOWER,
            _TICK_UPPER,
            tokensOwed0,
            tokensOwed1
        );
    }

    /// @inheritdoc IUniV3PairManager
    function position()
        external
        view
        override
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1) = IUniswapV3Pool(pool)
            .positions(keccak256(abi.encodePacked(address(this), _TICK_LOWER, _TICK_UPPER)));
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transferTokens(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }

    /// @notice Adds liquidity to an initialized pool
    /// @dev Reverts if the returned amount0 is less than amount0Min or if amount1 is less than amount1Min
    /// @dev This function calls the mint function of the corresponding Uniswap pool, which in turn calls UniswapV3Callback
    /// @param amount0Desired The amount of token0 we would like to provide
    /// @param amount1Desired The amount of token1 we would like to provide
    /// @param amount0Min The minimum amount of token0 we want to provide
    /// @param amount1Min The minimum amount of token1 we want to provide
    /// @return liquidity The calculated liquidity we get for the token amounts we provided
    /// @return amount0 The amount of token0 we ended up providing
    /// @return amount1 The amount of token1 we ended up providing
    function _addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    )
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0Desired,
            amount1Desired
        );

        (amount0, amount1) = IUniswapV3Pool(pool).mint(
            address(this),
            _TICK_LOWER,
            _TICK_UPPER,
            liquidity,
            abi.encode(MintCallbackData({ _poolKey: _poolKey, payer: msg.sender }))
        );

        if (amount0 < amount0Min || amount1 < amount1Min) revert ExcessiveSlippage();
    }

    /// @notice Transfers the passed-in token from the payer to the recipient for the corresponding value
    /// @param token The token to be transferred to the recipient
    /// @param from The address of the payer
    /// @param to The address of the passed-in tokens recipient
    /// @param value How much of that token to be transferred from payer to the recipient
    function _pay(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        _safeTransferFrom(token, from, to, value);
    }

    /// @notice Mints Keep3r credits to the passed-in address of recipient and increases total supply of Keep3r credits by the corresponding amount
    /// @param to The recipient of the Keep3r credits
    /// @param amount The amount Keep3r credits to be minted to the recipient
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Burns Keep3r credits to the passed-in address of recipient and reduces total supply of Keep3r credits by the corresponding amount
    /// @param to The address that will get its Keep3r credits burned
    /// @param amount The amount Keep3r credits to be burned from the recipient/recipient
    function _burn(address to, uint256 amount) internal {
        totalSupply -= amount;
        balanceOf[to] -= amount;
        emit Transfer(to, address(0), amount);
    }

    /// @notice Transfers amount of Keep3r credits between two addresses
    /// @param from The user that transfers the Keep3r credits
    /// @param to The user that receives the Keep3r credits
    /// @param amount The amount of Keep3r credits to be transferred
    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    /// @notice Transfers the passed-in token from the specified "from" to the specified "to" for the corresponding value
    /// @dev Reverts with IUniV3PairManager#UnsuccessfulTransfer if the transfer was not successful,
    ///      or if the passed data length is different than 0 and the decoded data is not a boolean
    /// @param token The token to be transferred to the specified "to"
    /// @param from  The address which is going to transfer the tokens
    /// @param value How much of that token to be transferred from "from" to "to"
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert UnsuccessfulTransfer();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

// solhint-disable
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

library PoolAddress {
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

library FixedPoint96 {
    // solhint-disable
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

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

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// solhint-disable

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
///         prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    ///         at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // Divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IPairManager.sol";
import "../contracts/libraries/PoolAddress.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./peripherals/IGovernable.sol";

/// @title Pair Manager contract
/// @notice Creates a UniswapV3 position, and tokenizes in an ERC20 manner
///         so that the user can use it as liquidity for a Keep3rJob
interface IUniV3PairManager is IGovernable, IPairManager {
    // Structs

    /// @notice The data to be decoded by the UniswapV3MintCallback function
    struct MintCallbackData {
        PoolAddress.PoolKey _poolKey; // Struct that contains token0, token1, and fee of the pool passed into the constructor
        address payer; // The address of the payer, which will be the msg.sender of the mint function
    }

    // Variables

    /// @notice The fee of the Uniswap pool passed into the constructor
    /// @return _fee The fee of the Uniswap pool passed into the constructor
    function fee() external view returns (uint24 _fee);

    /// @notice The sqrtRatioAX96 at the lowest tick (-887200) of the Uniswap pool
    /// @return _sqrtPriceA96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    ///         at the lowest tick
    function sqrtRatioAX96() external view returns (uint160 _sqrtPriceA96);

    /// @notice The sqrtRatioBX96 at the highest tick (887200) of the Uniswap pool
    /// @return _sqrtPriceBX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    ///         at the highest tick
    function sqrtRatioBX96() external view returns (uint160 _sqrtPriceBX96);

    // Errors

    /// @notice Throws when the caller of the function is not the pool
    error OnlyPool();

    /// @notice Throws when the slippage exceeds what the user is comfortable with
    error ExcessiveSlippage();

    /// @notice Throws when a transfer is unsuccessful
    error UnsuccessfulTransfer();

    // Methods

    /// @notice This function is called after a user calls IUniV3PairManager#mint function
    ///         It ensures that any tokens owed to the pool are paid by the msg.sender of IUniV3PairManager#mint function
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data The encoded token0, token1, fee (_poolKey) and the payer (msg.sender) of the IUniV3PairManager#mint function
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;

    /// @notice Mints kLP tokens to an address according to the liquidity the msg.sender provides to the UniswapV3 pool
    /// @dev Triggers UniV3PairManager#uniswapV3MintCallback
    /// @param amount0Desired The amount of token0 we would like to provide
    /// @param amount1Desired The amount of token1 we would like to provide
    /// @param amount0Min The minimum amount of token0 we want to provide
    /// @param amount1Min The minimum amount of token1 we want to provide
    /// @param to The address to which the kLP tokens are going to be minted to
    /// @return liquidity kLP tokens sent in exchange for the provision of tokens
    function mint(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint128 liquidity);

    /// @notice Returns the pair manager's position in the corresponding UniswapV3 pool
    /// @return liquidity The amount of liquidity provided to the UniswapV3 pool by the pair manager
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function position()
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Calls the UniswapV3 pool's collect function, which collects up to a maximum amount of fees
    //          owed to a specific position to the recipient, in this case, that recipient is the pair manager
    /// @dev The collected fees will be sent to governance
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect() external returns (uint256 amount0, uint256 amount1);

    /// @notice Burns the corresponding amount of kLP tokens from the msg.sender and withdraws the specified liquidity
    //          in the entire range
    /// @param liquidity The amount of liquidity to be burned
    /// @param amount0Min The minimum amount of token0 we want to send to the recipient (to)
    /// @param amount1Min The minimum amount of token1 we want to send to the recipient (to)
    /// @param to The address that will receive the due fees
    /// @return amount0 The calculated amount of token0 that will be sent to the recipient
    /// @return amount1 The calculated amount of token1 that will be sent to the recipient
    function burn(
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../interfaces/peripherals/IGovernable.sol";

abstract contract Governable is IGovernable {
    /// @inheritdoc IGovernable
    address public override governance;

    /// @inheritdoc IGovernable
    address public override pendingGovernance;

    constructor(address _governance) {
        if (_governance == address(0)) revert NoGovernanceZeroAddress();
        governance = _governance;
    }

    /// @inheritdoc IGovernable
    function setGovernance(address _governance) external override onlyGovernance {
        pendingGovernance = _governance;
        emit GovernanceProposal(_governance);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override onlyPendingGovernance {
        governance = pendingGovernance;
        delete pendingGovernance;
        emit GovernanceSet(governance);
    }

    /// @notice Functions with this modifier can only be called by governance
    modifier onlyGovernance() {
        if (msg.sender != governance) revert OnlyGovernance();
        _;
    }

    /// @notice Functions with this modifier can only be called by pendingGovernance
    modifier onlyPendingGovernance() {
        if (msg.sender != pendingGovernance) revert OnlyPendingGovernance();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title  Pair Manager interface
/// @notice Generic interface for Keep3r liquidity pools (kLP)
interface IPairManager is IERC20Metadata {
    /// @notice Address of the pool from which the Keep3r pair manager will interact with
    /// @return _pool The pool's address
    function pool() external view returns (address _pool);

    /// @notice Token0 of the pool
    /// @return _token0 The address of token0
    function token0() external view returns (address _token0);

    /// @notice Token1 of the pool
    /// @return _token1 The address of token1
    function token1() external view returns (address _token1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Governable contract
/// @notice Manages the governance role
interface IGovernable {
    // Events

    /// @notice Emitted when pendingGovernance accepts to be governance
    /// @param _governance Address of the new governance
    event GovernanceSet(address _governance);

    /// @notice Emitted when a new governance is proposed
    /// @param _pendingGovernance Address that is proposed to be the new governance
    event GovernanceProposal(address _pendingGovernance);

    // Errors

    /// @notice Throws if the caller of the function is not governance
    error OnlyGovernance();

    /// @notice Throws if the caller of the function is not pendingGovernance
    error OnlyPendingGovernance();

    /// @notice Throws if trying to set governance to zero address
    error NoGovernanceZeroAddress();

    // Variables

    /// @notice Stores the governance address
    /// @return _governance The governance address
    function governance() external view returns (address _governance);

    /// @notice Stores the pendingGovernance address
    /// @return _pendingGovernance The pendingGovernance address
    function pendingGovernance() external view returns (address _pendingGovernance);

    // Methods

    /// @notice Proposes a new address to be governance
    /// @param _governance The address of the user proposed to be the new governance
    function setGovernance(address _governance) external;

    /// @notice Changes the governance from the current governance to the previously proposed address
    function acceptGovernance() external;
}

// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IPairManagerFactory.sol";
import "./UniV3PairManager.sol";
import "./peripherals/Governable.sol";

/// @title Factory of Pair Managers
/// @notice This contract creates new pair managers
contract UniV3PairManagerFactory is IPairManagerFactory, Governable {
    mapping(address => address) public override pairManagers;

    constructor() Governable(msg.sender) {}

    ///@inheritdoc IPairManagerFactory
    function createPairManager(address _pool) external override returns (address _pairManager) {
        if (pairManagers[_pool] != address(0)) revert AlreadyInitialized();
        _pairManager = address(new UniV3PairManager(_pool, governance));
        pairManagers[_pool] = _pairManager;
        emit PairCreated(_pool, _pairManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./peripherals/IGovernable.sol";

/// @title Factory of Pair Managers
/// @notice This contract creates new pair managers
interface IPairManagerFactory is IGovernable {
    // Variables

    /// @notice Maps the address of a Uniswap pool, to the address of the corresponding PairManager
    ///         For example, the uniswap address of DAI-WETH, will return the Keep3r/DAI-WETH pair manager address
    /// @param _pool The address of the Uniswap pool
    /// @return _pairManager The address of the corresponding pair manager
    function pairManagers(address _pool) external view returns (address _pairManager);

    // Events

    /// @notice Emitted when a new pair manager is created
    /// @param _pool The address of the corresponding Uniswap pool
    /// @param _pairManager The address of the just-created pair manager
    event PairCreated(address _pool, address _pairManager);

    // Errors

    /// @notice Throws an error if the pair manager is already initialized
    error AlreadyInitialized();

    /// @notice Throws an error if the caller is not the owner
    error OnlyOwner();

    // Methods

    /// @notice Creates a new pair manager based on the address of a Uniswap pool
    ///         For example, the uniswap address of DAI-WETH, will create the Keep3r/DAI-WETH pool
    /// @param _pool The address of the Uniswap pool the pair manager will be based of
    /// @return _pairManager The address of the just-created pair manager
    function createPairManager(address _pool) external returns (address _pairManager);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../contracts/peripherals/Governable.sol";
import "../../interfaces/peripherals/IDustCollector.sol";

abstract contract DustCollector is IDustCollector, Governable {
    using SafeERC20 for IERC20;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function sendDust(
        address _token,
        uint256 _amount,
        address _to
    ) external override onlyGovernance {
        if (_to == address(0)) revert ZeroAddress();
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_token, _amount, _to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./IBaseErrors.sol";

interface IDustCollector is IBaseErrors {
    /// @notice Emitted when dust is sent
    /// @param _to The address which wil received the funds
    /// @param _token The token that will be transferred
    /// @param _amount The amount of the token that will be transferred
    event DustSent(address _token, uint256 _amount, address _to);

    /// @notice Allows an authorized user to transfer the tokens or eth that may have been left in a contract
    /// @param _token The token that will be transferred
    /// @param _amount The amount of the token that will be transferred
    /// @param _to The address that will receive the idle funds
    function sendDust(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface IBaseErrors {
    /// @notice Throws if a variable is assigned to the zero address
    error ZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IBaseErrors.sol";

/// @title Keep3rParameters contract
/// @notice Handles and sets all the required parameters for Keep3r

interface IKeep3rParameters is IBaseErrors {
    // Events

    /// @notice Emitted when the Keep3rHelper address is changed
    /// @param _keep3rHelper The address of Keep3rHelper's contract
    event Keep3rHelperChange(address _keep3rHelper);

    /// @notice Emitted when the Keep3rV1 address is changed
    /// @param _keep3rV1 The address of Keep3rV1's contract
    event Keep3rV1Change(address _keep3rV1);

    /// @notice Emitted when the Keep3rV1Proxy address is changed
    /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
    event Keep3rV1ProxyChange(address _keep3rV1Proxy);

    /// @notice Emitted when the KP3R-WETH pool address is changed
    /// @param _kp3rWethPool The address of the KP3R-WETH pool
    event Kp3rWethPoolChange(address _kp3rWethPool);

    /// @notice Emitted when bondTime is changed
    /// @param _bondTime The new bondTime
    event BondTimeChange(uint256 _bondTime);

    /// @notice Emitted when _liquidityMinimum is changed
    /// @param _liquidityMinimum The new _liquidityMinimum
    event LiquidityMinimumChange(uint256 _liquidityMinimum);

    /// @notice Emitted when _unbondTime is changed
    /// @param _unbondTime The new _unbondTime
    event UnbondTimeChange(uint256 _unbondTime);

    /// @notice Emitted when _rewardPeriodTime is changed
    /// @param _rewardPeriodTime The new _rewardPeriodTime
    event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

    /// @notice Emitted when the inflationPeriod is changed
    /// @param _inflationPeriod The new inflationPeriod
    event InflationPeriodChange(uint256 _inflationPeriod);

    /// @notice Emitted when the fee is changed
    /// @param _fee The new token credits fee
    event FeeChange(uint256 _fee);

    // Variables

    /// @notice Address of Keep3rHelper's contract
    /// @return _keep3rHelper The address of Keep3rHelper's contract
    function keep3rHelper() external view returns (address _keep3rHelper);

    /// @notice Address of Keep3rV1's contract
    /// @return _keep3rV1 The address of Keep3rV1's contract
    function keep3rV1() external view returns (address _keep3rV1);

    /// @notice Address of Keep3rV1Proxy's contract
    /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
    function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

    /// @notice Address of the KP3R-WETH pool
    /// @return _kp3rWethPool The address of KP3R-WETH pool
    function kp3rWethPool() external view returns (address _kp3rWethPool);

    /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
    /// @return _days The required bondTime in days
    function bondTime() external view returns (uint256 _days);

    /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
    /// @return _days The required unbondTime in days
    function unbondTime() external view returns (uint256 _days);

    /// @notice The minimum amount of liquidity required to fund a job per liquidity
    /// @return _amount The minimum amount of liquidity in KP3R
    function liquidityMinimum() external view returns (uint256 _amount);

    /// @notice The amount of time between each scheduled credits reward given to a job
    /// @return _days The reward period in days
    function rewardPeriodTime() external view returns (uint256 _days);

    /// @notice The inflation period is the denominator used to regulate the emission of KP3R
    /// @return _period The denominator used to regulate the emission of KP3R
    function inflationPeriod() external view returns (uint256 _period);

    /// @notice The fee to be sent to governance when a user adds liquidity to a job
    /// @return _amount The fee amount to be sent to governance when a user adds liquidity to a job
    function fee() external view returns (uint256 _amount);

    // solhint-disable func-name-mixedcase
    /// @notice The base that will be used to calculate the fee
    /// @return _base The base that will be used to calculate the fee
    function BASE() external view returns (uint256 _base);

    /// @notice The minimum rewardPeriodTime value to be set
    /// @return _minPeriod The minimum reward period in seconds
    function MIN_REWARD_PERIOD_TIME() external view returns (uint256 _minPeriod);

    // solhint-enable func-name-mixedcase

    // Errors

    /// @notice Throws if the reward period is less than the minimum reward period time
    error MinRewardPeriod();

    /// @notice Throws if either a job or a keeper is disputed
    error Disputed();

    /// @notice Throws if there are no bonded assets
    error BondsUnexistent();

    /// @notice Throws if the time required to bond an asset has not passed yet
    error BondsLocked();

    /// @notice Throws if there are no bonds to withdraw
    error UnbondsUnexistent();

    /// @notice Throws if the time required to withdraw the bonds has not passed yet
    error UnbondsLocked();

    // Methods

    /// @notice Sets the Keep3rHelper address
    /// @param _keep3rHelper The Keep3rHelper address
    function setKeep3rHelper(address _keep3rHelper) external;

    /// @notice Sets the Keep3rV1 address
    /// @param _keep3rV1 The Keep3rV1 address
    function setKeep3rV1(address _keep3rV1) external;

    /// @notice Sets the Keep3rV1Proxy address
    /// @param _keep3rV1Proxy The Keep3rV1Proxy address
    function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

    /// @notice Sets the KP3R-WETH pool address
    /// @param _kp3rWethPool The KP3R-WETH pool address
    function setKp3rWethPool(address _kp3rWethPool) external;

    /// @notice Sets the bond time required to activate as a keeper
    /// @param _bond The new bond time
    function setBondTime(uint256 _bond) external;

    /// @notice Sets the unbond time required unbond what has been bonded
    /// @param _unbond The new unbond time
    function setUnbondTime(uint256 _unbond) external;

    /// @notice Sets the minimum amount of liquidity required to fund a job
    /// @param _liquidityMinimum The new minimum amount of liquidity
    function setLiquidityMinimum(uint256 _liquidityMinimum) external;

    /// @notice Sets the time required to pass between rewards for jobs
    /// @param _rewardPeriodTime The new amount of time required to pass between rewards
    function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

    /// @notice Sets the new inflation period
    /// @param _inflationPeriod The new inflation period
    function setInflationPeriod(uint256 _inflationPeriod) external;

    /// @notice Sets the new fee
    /// @param _fee The new fee
    function setFee(uint256 _fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./peripherals/IKeep3rJobs.sol";
import "./peripherals/IKeep3rKeepers.sol";
import "./peripherals/IKeep3rAccountance.sol";
import "./peripherals/IKeep3rRoles.sol";
import "./peripherals/IKeep3rParameters.sol";

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rV2 contract
/// @notice This contract inherits all the functionality of Keep3rV2
interface IKeep3r is IKeep3rJobs, IKeep3rKeepers, IKeep3rAccountance, IKeep3rRoles, IKeep3rParameters {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rJobFundableCredits contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobFundableCredits {
    // Events

    /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
    /// @param _job The address of the job being credited
    /// @param _token The address of the token being provided
    /// @param _provider The user that calls the function
    /// @param _amount The amount of credit being added to the job
    event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

    /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
    /// @param _job The address of the job from which the credits are withdrawn
    /// @param _token The credit being withdrawn from the job
    /// @param _receiver The user that receives the tokens
    /// @param _amount The amount of credit withdrawn
    event TokenCreditWithdrawal(
        address indexed _job,
        address indexed _token,
        address indexed _receiver,
        uint256 _amount
    );

    // Errors

    /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
    error TokenUnallowed();

    /// @notice Throws when the token withdraw cooldown has not yet passed
    error JobTokenCreditsLocked();

    /// @notice Throws when the user tries to withdraw more tokens than it has
    error InsufficientJobTokenCredits();

    // Variables

    /// @notice Last block where tokens were added to the job [job => token => timestamp]
    /// @return _timestamp The last block where tokens were added to the job
    function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

    // Methods

    /// @notice Add credit to a job to be paid out for work
    /// @param _job The address of the job being credited
    /// @param _token The address of the token being credited
    /// @param _amount The amount of credit being added
    function addTokenCreditsToJob(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    /// @notice Withdraw credit from a job
    /// @param _job The address of the job from which the credits are withdrawn
    /// @param _token The address of the token being withdrawn
    /// @param _amount The amount of token to be withdrawn
    /// @param _receiver The user that will receive tokens
    function withdrawTokenCreditsFromJob(
        address _job,
        address _token,
        uint256 _amount,
        address _receiver
    ) external;
}

/// @title  Keep3rJobFundableLiquidity contract
/// @notice Handles the funding of jobs through specific liquidity pairs
interface IKeep3rJobFundableLiquidity {
    // Events

    /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
    /// @param _liquidity The address of the liquidity pair being approved
    event LiquidityApproval(address _liquidity);

    /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
    /// @param _liquidity The address of the liquidity pair being revoked
    event LiquidityRevocation(address _liquidity);

    /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
    /// @param _job The address of the job to which liquidity will be added
    /// @param _liquidity The address of the liquidity being added
    /// @param _provider The user that calls the function
    /// @param _amount The amount of liquidity being added
    event LiquidityAddition(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _amount
    );

    /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
    /// @param _job The address of the job of which liquidity will be withdrawn from
    /// @param _liquidity The address of the liquidity being withdrawn
    /// @param _receiver The receiver of the liquidity tokens
    /// @param _amount The amount of liquidity being withdrawn from the job
    event LiquidityWithdrawal(
        address indexed _job,
        address indexed _liquidity,
        address indexed _receiver,
        uint256 _amount
    );

    /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
    /// @param _job The address of the job whose credits will be updated
    /// @param _rewardedAt The time at which the job was last rewarded
    /// @param _currentCredits The current credits of the job
    /// @param _periodCredits The credits of the job for the current period
    event LiquidityCreditsReward(
        address indexed _job,
        uint256 _rewardedAt,
        uint256 _currentCredits,
        uint256 _periodCredits
    );

    /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
    /// @param _job The address of the job whose credits will be updated
    /// @param _rewardedAt The time at which the job was last rewarded
    /// @param _currentCredits The current credits of the job
    event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

    // Errors

    /// @notice Throws when the liquidity being approved has already been approved
    error LiquidityPairApproved();

    /// @notice Throws when the liquidity being removed has not been approved
    error LiquidityPairUnexistent();

    /// @notice Throws when trying to add liquidity to an unapproved pool
    error LiquidityPairUnapproved();

    /// @notice Throws when the job doesn't have the requested liquidity
    error JobLiquidityUnexistent();

    /// @notice Throws when trying to remove more liquidity than the job has
    error JobLiquidityInsufficient();

    /// @notice Throws when trying to add less liquidity than the minimum liquidity required
    error JobLiquidityLessThanMin();

    // Structs

    /// @notice Stores the tick information of the different liquidity pairs
    struct TickCache {
        int56 current; // Tracks the current tick
        int56 difference; // Stores the difference between the current tick and the last tick
        uint256 period; // Stores the period at which the last observation was made
    }

    // Variables

    /// @notice Lists liquidity pairs
    /// @return _list An array of addresses with all the approved liquidity pairs
    function approvedLiquidities() external view returns (address[] memory _list);

    /// @notice Amount of liquidity in a specified job
    /// @param _job The address of the job being checked
    /// @param _liquidity The address of the liquidity we are checking
    /// @return _amount Amount of liquidity in the specified job
    function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

    /// @notice Last time the job was rewarded liquidity credits
    /// @param _job The address of the job being checked
    /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
    function rewardedAt(address _job) external view returns (uint256 _timestamp);

    /// @notice Last time the job was worked
    /// @param _job The address of the job being checked
    /// @return _timestamp Timestamp of the last time the job was worked
    function workedAt(address _job) external view returns (uint256 _timestamp);

    // Methods

    /// @notice Returns the liquidity credits of a given job
    /// @param _job The address of the job of which we want to know the liquidity credits
    /// @return _amount The liquidity credits of a given job
    function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

    /// @notice Returns the credits of a given job for the current period
    /// @param _job The address of the job of which we want to know the period credits
    /// @return _amount The credits the given job has at the current period
    function jobPeriodCredits(address _job) external view returns (uint256 _amount);

    /// @notice Calculates the total credits of a given job
    /// @param _job The address of the job of which we want to know the total credits
    /// @return _amount The total credits of the given job
    function totalJobCredits(address _job) external view returns (uint256 _amount);

    /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
    /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
    /// @param _liquidity The liquidity to provide
    /// @param _amount The amount of liquidity to provide
    /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
    function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

    /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
    /// @param _liquidity The liquidity pair being observed
    /// @return _tickCache The updated TickCache
    function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

    /// @notice Gifts liquidity credits to the specified job
    /// @param _job The address of the job being credited
    /// @param _amount The amount of liquidity credits to gift
    function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

    /// @notice Approve a liquidity pair for being accepted in future
    /// @param _liquidity The address of the liquidity accepted
    function approveLiquidity(address _liquidity) external;

    /// @notice Revoke a liquidity pair from being accepted in future
    /// @param _liquidity The liquidity no longer accepted
    function revokeLiquidity(address _liquidity) external;

    /// @notice Allows anyone to fund a job with liquidity
    /// @param _job The address of the job to assign liquidity to
    /// @param _liquidity The liquidity being added
    /// @param _amount The amount of liquidity tokens to add
    function addLiquidityToJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external;

    /// @notice Unbond liquidity for a job
    /// @dev Can only be called by the job's owner
    /// @param _job The address of the job being unbound from
    /// @param _liquidity The liquidity being unbound
    /// @param _amount The amount of liquidity being removed
    function unbondLiquidityFromJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external;

    /// @notice Withdraw liquidity from a job
    /// @param _job The address of the job being withdrawn from
    /// @param _liquidity The liquidity being withdrawn
    /// @param _receiver The address that will receive the withdrawn liquidity
    function withdrawLiquidityFromJob(
        address _job,
        address _liquidity,
        address _receiver
    ) external;
}

/// @title Keep3rJobManager contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobManager {
    // Events

    /// @notice Emitted when Keep3rJobManager#addJob is called
    /// @param _job The address of the job to add
    /// @param _jobOwner The job's owner
    event JobAddition(address indexed _job, address indexed _jobOwner);

    // Errors

    /// @notice Throws when trying to add a job that has already been added
    error JobAlreadyAdded();

    /// @notice Throws when the address that is trying to register as a keeper is already a keeper
    error AlreadyAKeeper();

    // Methods

    /// @notice Allows any caller to add a new job
    /// @param _job Address of the contract for which work should be performed
    function addJob(address _job) external;
}

/// @title Keep3rJobWorkable contract
/// @notice Handles the mechanisms jobs can pay keepers with along with the restrictions jobs can put on keepers before they can work on jobs
interface IKeep3rJobWorkable {
    // Events

    /// @notice Emitted when a keeper is validated before a job
    /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
    event KeeperValidation(uint256 _gasLeft);

    /// @notice Emitted when a keeper works a job
    /// @param _credit The address of the asset in which the keeper is paid
    /// @param _job The address of the job the keeper has worked
    /// @param _keeper The address of the keeper that has worked the job
    /// @param _amount The amount that has been paid out to the keeper in exchange for working the job
    /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
    event KeeperWork(
        address indexed _credit,
        address indexed _job,
        address indexed _keeper,
        uint256 _amount,
        uint256 _gasLeft
    );

    // Errors

    /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
    error JobUnapproved();

    /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
    error InsufficientFunds();

    // Methods

    /// @notice Confirms if the current keeper is registered, can be used for general (non critical) functions
    /// @param _keeper The keeper being investigated
    /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
    function isKeeper(address _keeper) external returns (bool _isKeeper);

    /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset. Should be used for protected functions
    /// @param _keeper The keeper to check
    /// @param _bond The bond token being evaluated
    /// @param _minBond The minimum amount of bonded tokens
    /// @param _earned The minimum funds earned in the keepers lifetime
    /// @param _age The minimum keeper age required
    /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
    function isBondedKeeper(
        address _keeper,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) external returns (bool _isBondedKeeper);

    /// @notice Implemented by jobs to show that a keeper performed work
    /// @dev Automatically calculates the payment for the keeper
    /// @param _keeper Address of the keeper that performed the work
    function worked(address _keeper) external;

    /// @notice Implemented by jobs to show that a keeper performed work
    /// @dev Pays the keeper that performs the work with KP3R
    /// @param _keeper Address of the keeper that performed the work
    /// @param _payment The reward that should be allocated for the job
    function bondedPayment(address _keeper, uint256 _payment) external;

    /// @notice Implemented by jobs to show that a keeper performed work
    /// @dev Pays the keeper that performs the work with a specific token
    /// @param _token The asset being awarded to the keeper
    /// @param _keeper Address of the keeper that performed the work
    /// @param _amount The reward that should be allocated
    function directTokenPayment(
        address _token,
        address _keeper,
        uint256 _amount
    ) external;
}

/// @title Keep3rJobOwnership contract
/// @notice Handles the ownership of the jobs
interface IKeep3rJobOwnership {
    // Events

    /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
    /// @param _job The address of the job proposed to have a change of owner
    /// @param _owner The current owner of the job
    /// @param _pendingOwner The new address proposed to be the owner of the job
    event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

    /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
    /// @param _job The address of the job which the proposed owner will now own
    /// @param _previousOwner The previous owner of the job
    /// @param _newOwner The newowner of the job
    event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

    // Errors

    /// @notice Throws when the caller of the function is not the job owner
    error OnlyJobOwner();

    /// @notice Throws when the caller of the function is not the pending job owner
    error OnlyPendingJobOwner();

    // Variables

    /// @notice Maps the job to the owner of the job (job => user)
    /// @return _owner The addres of the owner of the job
    function jobOwner(address _job) external view returns (address _owner);

    /// @notice Maps the owner of the job to its pending owner (job => user)
    /// @return _pendingOwner The address of the pending owner of the job
    function jobPendingOwner(address _job) external view returns (address _pendingOwner);

    // Methods

    /// @notice Proposes a new address to be the owner of the job
    function changeJobOwnership(address _job, address _newOwner) external;

    /// @notice The proposed address accepts to be the owner of the job
    function acceptJobOwnership(address _job) external;
}

/// @title Keep3rJobMigration contract
/// @notice Handles the migration process of jobs to different addresses
interface IKeep3rJobMigration {
    // Events

    /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
    /// @param _fromJob The address of the job that requests to migrate
    /// @param _toJob The address at which the job requests to migrate
    event JobMigrationRequested(address indexed _fromJob, address _toJob);

    /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
    /// @param _fromJob The address of the job that requested to migrate
    /// @param _toJob The address at which the job had requested to migrate
    event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

    // Errors

    /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
    error JobMigrationImpossible();

    /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
    error JobMigrationUnavailable();

    /// @notice Throws when cooldown between migrations has not yet passed
    error JobMigrationLocked();

    // Variables

    /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
    /// @return _toJob The address to which the job has requested to migrate to
    function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

    // Methods

    /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
    /// @param _fromJob The address of the job that is requesting to migrate
    /// @param _toJob The address at which the job is requesting to migrate
    function migrateJob(address _fromJob, address _toJob) external;

    /// @notice Completes the migration process for a job
    /// @dev Unbond/withdraw process doesn't get migrated
    /// @param _fromJob The address of the job that requested to migrate
    /// @param _toJob The address to which the job wants to migrate to
    function acceptJobMigration(address _fromJob, address _toJob) external;
}

/// @title Keep3rJobDisputable contract
/// @notice Handles the actions that can be taken on a disputed job
interface IKeep3rJobDisputable is IKeep3rJobFundableCredits, IKeep3rJobFundableLiquidity {
    // Events

    /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
    /// @param _job The address of the job from which the token will be slashed
    /// @param _token The address of the token being slashed
    /// @param _slasher The user that slashes the token
    /// @param _amount The amount of the token being slashed
    event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

    /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
    /// @param _job The address of the job from which the liquidity will be slashed
    /// @param _liquidity The address of the liquidity being slashed
    /// @param _slasher The user that slashes the liquidity
    /// @param _amount The amount of the liquidity being slashed
    event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

    // Errors

    /// @notice Throws when the token trying to be slashed doesn't exist
    error JobTokenUnexistent();

    /// @notice Throws when someone tries to slash more tokens than the job has
    error JobTokenInsufficient();

    // Methods

    /// @notice Allows governance or slasher to slash a job specific token
    /// @param _job The address of the job from which the token will be slashed
    /// @param _token The address of the token that will be slashed
    /// @param _amount The amount of the token that will be slashed
    function slashTokenFromJob(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    /// @notice Allows governance or a slasher to slash liquidity from a job
    /// @param _job The address being slashed
    /// @param _liquidity The address of the liquidity that will be slashed
    /// @param _amount The amount of liquidity that will be slashed
    function slashLiquidityFromJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external;
}

// solhint-disable-next-line no-empty-blocks
interface IKeep3rJobs is
    IKeep3rJobOwnership,
    IKeep3rJobDisputable,
    IKeep3rJobMigration,
    IKeep3rJobManager,
    IKeep3rJobWorkable
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rKeeperFundable contract
/// @notice Handles the actions required to become a keeper
interface IKeep3rKeeperFundable {
    // Events

    /// @notice Emitted when Keep3rKeeperFundable#activate is called
    /// @param _keeper The keeper that has been activated
    /// @param _bond The asset the keeper has bonded
    /// @param _amount The amount of the asset the keeper has bonded
    event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

    /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
    /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
    /// @param _bond The asset to withdraw from the bonding pool
    /// @param _amount The amount of funds withdrawn
    event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

    // Errors

    /// @notice Throws when the address that is trying to register as a job is already a job
    error AlreadyAJob();

    // Methods

    /// @notice Beginning of the bonding process
    /// @param _bonding The asset being bound
    /// @param _amount The amount of bonding asset being bound
    function bond(address _bonding, uint256 _amount) external;

    /// @notice Beginning of the unbonding process
    /// @param _bonding The asset being unbound
    /// @param _amount Allows for partial unbonding
    function unbond(address _bonding, uint256 _amount) external;

    /// @notice End of the bonding process after bonding time has passed
    /// @param _bonding The asset being activated as bond collateral
    function activate(address _bonding) external;

    /// @notice Withdraw funds after unbonding has finished
    /// @param _bonding The asset to withdraw from the bonding pool
    function withdraw(address _bonding) external;
}

/// @title Keep3rKeeperDisputable contract
/// @notice Handles the actions that can be taken on a disputed keeper
interface IKeep3rKeeperDisputable {
    // Events

    /// @notice Emitted when Keep3rKeeperDisputable#slash is called
    /// @param _keeper The slashed keeper
    /// @param _slasher The user that called Keep3rKeeperDisputable#slash
    /// @param _amount The amount of credits slashed from the keeper
    event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

    /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
    /// @param _keeper The revoked keeper
    /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
    event KeeperRevoke(address indexed _keeper, address indexed _slasher);

    /// @notice Keeper revoked

    // Methods

    /// @notice Allows governance to slash a keeper based on a dispute
    /// @param _keeper The address being slashed
    /// @param _bonded The asset being slashed
    /// @param _amount The amount being slashed
    function slash(
        address _keeper,
        address _bonded,
        uint256 _amount
    ) external;

    /// @notice Blacklists a keeper from participating in the network
    /// @param _keeper The address being slashed
    function revoke(address _keeper) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rKeepers contract
interface IKeep3rKeepers is IKeep3rKeeperDisputable {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Disputes keepers, or if they're already disputed, it can resolve the case
/// @dev Argument `bonding` can be the address of either a token or a liquidity
interface IKeep3rAccountance {
    // Events

    /// @notice Emitted when the bonding process of a new keeper begins
    /// @param _keeper The caller of Keep3rKeeperFundable#bond function
    /// @param _bonding The asset the keeper has bonded
    /// @param _amount The amount the keeper has bonded
    event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

    /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
    /// @param _keeperOrJob The keeper or job that began the unbonding process
    /// @param _unbonding The liquidity pair or asset being unbonded
    /// @param _amount The amount being unbonded
    event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

    // Variables

    /// @notice Tracks the total KP3R earnings of a keeper since it started working
    /// @return _workCompleted Total KP3R earnings of a keeper since it started working
    function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

    /// @notice Tracks when a keeper was first registered
    /// @return timestamp The time at which the keeper was first registered
    function firstSeen(address _keeper) external view returns (uint256 timestamp);

    /// @notice Tracks if a keeper or job has a pending dispute
    /// @return _disputed Whether a keeper or job has a pending dispute
    function disputes(address _keeperOrJob) external view returns (bool _disputed);

    /// @notice Tracks how much a keeper has bonded of a certain token
    /// @return _bonds Amount of a certain token that a keeper has bonded
    function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

    /// @notice The current token credits available for a job
    /// @return _amount The amount of token credits available for a job
    function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

    /// @notice Tracks the amount of assets deposited in pending bonds
    /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
    function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

    /// @notice Tracks when a bonding for a keeper can be activated
    /// @return _timestamp Time at which the bonding for a keeper can be activated
    function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

    /// @notice Tracks when keeper bonds are ready to be withdrawn
    /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
    function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

    /// @notice Tracks how much keeper bonds are to be withdrawn
    /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
    function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

    /// @notice Checks whether the address has ever bonded an asset
    /// @return _hasBonded Whether the address has ever bonded an asset
    function hasBonded(address _keeper) external view returns (bool _hasBonded);

    // Methods
    /// @notice Lists all jobs
    /// @return _jobList Array with all the jobs in _jobs
    function jobs() external view returns (address[] memory _jobList);

    /// @notice Lists all keepers
    /// @return _keeperList Array with all the jobs in keepers
    function keepers() external view returns (address[] memory _keeperList);

    // Errors

    /// @notice Throws when an address is passed as a job, but that address is not a job
    error JobUnavailable();

    /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
    error JobDisputed();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rRoles contract
/// @notice Manages the Keep3r specific roles
interface IKeep3rRoles {
    // Events

    /// @notice Emitted when a slasher is added
    /// @param _slasher Address of the added slasher
    event SlasherAdded(address _slasher);

    /// @notice Emitted when a slasher is removed
    /// @param _slasher Address of the removed slasher
    event SlasherRemoved(address _slasher);

    /// @notice Emitted when a disputer is added
    /// @param _disputer Address of the added disputer
    event DisputerAdded(address _disputer);

    /// @notice Emitted when a disputer is removed
    /// @param _disputer Address of the removed disputer
    event DisputerRemoved(address _disputer);

    // Variables

    /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
    /// @return _isSlasher Whether the address is a slasher or not
    function slashers(address _slasher) external view returns (bool _isSlasher);

    /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
    /// @return _isDisputer Whether the address is a disputer or not
    function disputers(address _disputer) external view returns (bool _isDisputer);

    // Errors

    /// @notice Throws if the address is already a registered slasher
    error SlasherExistent();

    /// @notice Throws if caller is not a registered slasher
    error SlasherUnexistent();

    /// @notice Throws if the address is already a registered disputer
    error DisputerExistent();

    /// @notice Throws if caller is not a registered disputer
    error DisputerUnexistent();

    /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
    error OnlySlasher();

    /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
    error OnlyDisputer();

    // Methods

    /// @notice Registers a slasher by updating the slashers mapping
    function addSlasher(address _slasher) external;

    /// @notice Removes a slasher by updating the slashers mapping
    function removeSlasher(address _slasher) external;

    /// @notice Registers a disputer by updating the disputers mapping
    function addDisputer(address _disputer) external;

    /// @notice Removes a disputer by updating the disputers mapping
    function removeDisputer(address _disputer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IKeep3r.sol";

contract JobForTest {
    error InvalidKeeper();
    address public keep3r;
    uint256 public nonce;

    constructor(address _keep3r) {
        keep3r = _keep3r;
    }

    function work() external {
        if (!IKeep3r(keep3r).isKeeper(msg.sender)) revert InvalidKeeper();

        for (uint256 i = 0; i < 1000; i++) {
            nonce++;
        }

        IKeep3r(keep3r).worked(msg.sender);
    }

    function workHard(uint256 _factor) external {
        if (!IKeep3r(keep3r).isKeeper(msg.sender)) revert InvalidKeeper();

        for (uint256 i = 0; i < 1000 * _factor; i++) {
            nonce++;
        }

        IKeep3r(keep3r).worked(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../interfaces/peripherals/IKeep3rRoles.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Governable.sol";

contract Keep3rRoles is IKeep3rRoles, Governable {
    /// @inheritdoc IKeep3rRoles
    mapping(address => bool) public override slashers;

    /// @inheritdoc IKeep3rRoles
    mapping(address => bool) public override disputers;

    constructor(address _governance) Governable(_governance) {}

    /// @inheritdoc IKeep3rRoles
    function addSlasher(address _slasher) external override onlyGovernance {
        if (slashers[_slasher]) revert SlasherExistent();
        slashers[_slasher] = true;
        emit SlasherAdded(_slasher);
    }

    /// @inheritdoc IKeep3rRoles
    function removeSlasher(address _slasher) external override onlyGovernance {
        if (!slashers[_slasher]) revert SlasherUnexistent();
        delete slashers[_slasher];
        emit SlasherRemoved(_slasher);
    }

    /// @inheritdoc IKeep3rRoles
    function addDisputer(address _disputer) external override onlyGovernance {
        if (disputers[_disputer]) revert DisputerExistent();
        disputers[_disputer] = true;
        emit DisputerAdded(_disputer);
    }

    /// @inheritdoc IKeep3rRoles
    function removeDisputer(address _disputer) external override onlyGovernance {
        if (!disputers[_disputer]) revert DisputerUnexistent();
        delete disputers[_disputer];
        emit DisputerRemoved(_disputer);
    }

    /// @notice Functions with this modifier can only be called by either a slasher or governance
    modifier onlySlasher() {
        if (!slashers[msg.sender]) revert OnlySlasher();
        _;
    }

    /// @notice Functions with this modifier can only be called by either a disputer or governance
    modifier onlyDisputer() {
        if (!disputers[msg.sender]) revert OnlyDisputer();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobOwnership.sol";
import "../Keep3rRoles.sol";
import "../Keep3rParameters.sol";
import "../../../interfaces/peripherals/IKeep3rJobs.sol";

abstract contract Keep3rJobManager is IKeep3rJobManager, Keep3rJobOwnership, Keep3rRoles, Keep3rParameters {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IKeep3rJobManager
    function addJob(address _job) external override {
        if (_jobs.contains(_job)) revert JobAlreadyAdded();
        if (hasBonded[_job]) revert AlreadyAKeeper();
        _jobs.add(_job);
        jobOwner[_job] = msg.sender;
        emit JobAddition(msg.sender, _job);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../../interfaces/peripherals/IKeep3rJobs.sol";

abstract contract Keep3rJobOwnership is IKeep3rJobOwnership {
    /// @inheritdoc IKeep3rJobOwnership
    mapping(address => address) public override jobOwner;

    /// @inheritdoc IKeep3rJobOwnership
    mapping(address => address) public override jobPendingOwner;

    /// @inheritdoc IKeep3rJobOwnership
    function changeJobOwnership(address _job, address _newOwner) external override onlyJobOwner(_job) {
        jobPendingOwner[_job] = _newOwner;
        emit JobOwnershipChange(_job, jobOwner[_job], _newOwner);
    }

    /// @inheritdoc IKeep3rJobOwnership
    function acceptJobOwnership(address _job) external override onlyPendingJobOwner(_job) {
        address _previousOwner = jobOwner[_job];

        jobOwner[_job] = jobPendingOwner[_job];
        delete jobPendingOwner[_job];

        emit JobOwnershipAssent(msg.sender, _job, _previousOwner);
    }

    modifier onlyJobOwner(address _job) {
        if (msg.sender != jobOwner[_job]) revert OnlyJobOwner();
        _;
    }

    modifier onlyPendingJobOwner(address _job) {
        if (msg.sender != jobPendingOwner[_job]) revert OnlyPendingJobOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../interfaces/IKeep3rHelper.sol";
import "../../interfaces/peripherals/IKeep3rParameters.sol";
import "./Keep3rAccountance.sol";
import "./Keep3rRoles.sol";

abstract contract Keep3rParameters is IKeep3rParameters, Keep3rAccountance, Keep3rRoles {
    /// @inheritdoc IKeep3rParameters
    address public override keep3rV1;

    /// @inheritdoc IKeep3rParameters
    address public override keep3rV1Proxy;

    /// @inheritdoc IKeep3rParameters
    address public override keep3rHelper;

    /// @inheritdoc IKeep3rParameters
    address public override kp3rWethPool;

    /// @inheritdoc IKeep3rParameters
    uint256 public override bondTime = 3 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override unbondTime = 14 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override liquidityMinimum = 3 ether;

    /// @inheritdoc IKeep3rParameters
    uint256 public override rewardPeriodTime = 5 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override inflationPeriod = 34 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override fee = 30;

    /// @inheritdoc IKeep3rParameters
    uint256 public constant override BASE = 10000;

    /// @inheritdoc IKeep3rParameters
    uint256 public constant override MIN_REWARD_PERIOD_TIME = 1 days;

    constructor(
        address _keep3rHelper,
        address _keep3rV1,
        address _keep3rV1Proxy,
        address _kp3rWethPool
    ) {
        keep3rHelper = _keep3rHelper;
        keep3rV1 = _keep3rV1;
        keep3rV1Proxy = _keep3rV1Proxy;
        kp3rWethPool = _kp3rWethPool;
        _liquidityPool[kp3rWethPool] = kp3rWethPool;
        _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(kp3rWethPool);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rHelper(address _keep3rHelper) external override onlyGovernance {
        if (_keep3rHelper == address(0)) revert ZeroAddress();
        keep3rHelper = _keep3rHelper;
        emit Keep3rHelperChange(_keep3rHelper);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rV1(address _keep3rV1) external override onlyGovernance {
        if (_keep3rV1 == address(0)) revert ZeroAddress();
        keep3rV1 = _keep3rV1;
        emit Keep3rV1Change(_keep3rV1);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rV1Proxy(address _keep3rV1Proxy) external override onlyGovernance {
        if (_keep3rV1Proxy == address(0)) revert ZeroAddress();
        keep3rV1Proxy = _keep3rV1Proxy;
        emit Keep3rV1ProxyChange(_keep3rV1Proxy);
    }

    /// @inheritdoc IKeep3rParameters
    function setKp3rWethPool(address _kp3rWethPool) external override onlyGovernance {
        if (_kp3rWethPool == address(0)) revert ZeroAddress();
        kp3rWethPool = _kp3rWethPool;
        _liquidityPool[kp3rWethPool] = kp3rWethPool;
        _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_kp3rWethPool);
        emit Kp3rWethPoolChange(_kp3rWethPool);
    }

    /// @inheritdoc IKeep3rParameters
    function setBondTime(uint256 _bondTime) external override onlyGovernance {
        bondTime = _bondTime;
        emit BondTimeChange(_bondTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setUnbondTime(uint256 _unbondTime) external override onlyGovernance {
        unbondTime = _unbondTime;
        emit UnbondTimeChange(_unbondTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setLiquidityMinimum(uint256 _liquidityMinimum) external override onlyGovernance {
        liquidityMinimum = _liquidityMinimum;
        emit LiquidityMinimumChange(_liquidityMinimum);
    }

    /// @inheritdoc IKeep3rParameters
    function setRewardPeriodTime(uint256 _rewardPeriodTime) external override onlyGovernance {
        if (_rewardPeriodTime < MIN_REWARD_PERIOD_TIME) revert MinRewardPeriod();
        rewardPeriodTime = _rewardPeriodTime;
        emit RewardPeriodTimeChange(_rewardPeriodTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setInflationPeriod(uint256 _inflationPeriod) external override onlyGovernance {
        inflationPeriod = _inflationPeriod;
        emit InflationPeriodChange(_inflationPeriod);
    }

    /// @inheritdoc IKeep3rParameters
    function setFee(uint256 _fee) external override onlyGovernance {
        fee = _fee;
        emit FeeChange(_fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Keep3rHelper contract
/// @notice Contains all the helper functions used throughout the different files.
interface IKeep3rHelper {
    // Errors

    /// @notice Throws when none of the tokens in the liquidity pair is KP3R
    error LiquidityPairInvalid();

    // Variables

    /// @notice Address of KP3R token
    /// @return _kp3r Address of KP3R token
    // solhint-disable func-name-mixedcase
    function KP3R() external view returns (address _kp3r);

    /// @notice Address of KP3R-WETH pool to use as oracle
    /// @return _kp3rWeth Address of KP3R-WETH pool to use as oracle
    function KP3R_WETH_POOL() external view returns (address _kp3rWeth);

    /// @notice The minimum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
    ///         For example: if the quoted gas used is 1000, then the minimum amount to be paid will be 1000 * MIN / BOOST_BASE
    /// @return _multiplier The MIN multiplier
    function MIN() external view returns (uint256 _multiplier);

    /// @notice The maximum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
    ///         For example: if the quoted gas used is 1000, then the maximum amount to be paid will be 1000 * MAX / BOOST_BASE
    /// @return _multiplier The MAX multiplier
    function MAX() external view returns (uint256 _multiplier);

    /// @notice The boost base used to calculate the boost rewards for the keeper
    /// @return _base The boost base number
    function BOOST_BASE() external view returns (uint256 _base);

    /// @notice The targeted amount of bonded KP3Rs to max-up reward multiplier
    ///         For example: if the amount of KP3R the keeper has bonded is TARGETBOND or more, then the keeper will get
    ///                      the maximum boost possible in his rewards, if it's less, the reward boost will be proportional
    /// @return _target The amount of KP3R that comforms the TARGETBOND
    function TARGETBOND() external view returns (uint256 _target);

    // Methods
    // solhint-enable func-name-mixedcase

    /// @notice Calculates the amount of KP3R that corresponds to the ETH passed into the function
    /// @dev This function allows us to calculate how much KP3R we should pay to a keeper for things expressed in ETH, like gas
    /// @param _eth The amount of ETH
    /// @return _amountOut The amount of KP3R
    function quote(uint256 _eth) external view returns (uint256 _amountOut);

    /// @notice Returns the amount of KP3R the keeper has bonded
    /// @param _keeper The address of the keeper to check
    /// @return _amountBonded The amount of KP3R the keeper has bonded
    function bonds(address _keeper) external view returns (uint256 _amountBonded);

    /// @notice Calculates the reward (in KP3R) that corresponds to a keeper for using gas
    /// @param _keeper The address of the keeper to check
    /// @param _gasUsed The amount of gas used that will be rewarded
    /// @return _kp3r The amount of KP3R that should be awarded to the keeper
    function getRewardAmountFor(address _keeper, uint256 _gasUsed) external view returns (uint256 _kp3r);

    /// @notice Calculates the boost in the reward given to a keeper based on the amount of KP3R that keeper has bonded
    /// @param _bonds The amount of KP3R tokens bonded by the keeper
    /// @return _rewardBoost The reward boost that corresponds to the keeper
    function getRewardBoostFor(uint256 _bonds) external view returns (uint256 _rewardBoost);

    /// @notice Calculates the reward (in KP3R) that corresponds to tx.origin for using gas
    /// @param _gasUsed The amount of gas used that will be rewarded
    /// @return _amount The amount of KP3R that should be awarded to tx.origin
    function getRewardAmount(uint256 _gasUsed) external view returns (uint256 _amount);

    /// @notice Given a pool address, returns the underlying tokens of the pair
    /// @param _pool Address of the correspondant pool
    /// @return _token0 Address of the first token of the pair
    /// @return _token1 Address of the second token of the pair
    function getPoolTokens(address _pool) external view returns (address _token0, address _token1);

    /// @notice Defines the order of the tokens in the pair for twap calculations
    /// @param _pool Address of the correspondant pool
    /// @return _isKP3RToken0 Boolean indicating the order of the tokens in the pair
    function isKP3RToken0(address _pool) external view returns (bool _isKP3RToken0);

    /// @notice Given an array of secondsAgo, returns UniswapV3 pool cumulatives at that moment
    /// @param _pool Address of the pool to observe
    /// @param _secondsAgo Array with time references to observe
    /// @return _tickCumulative1 Cummulative sum of ticks until first time reference
    /// @return _tickCumulative2 Cummulative sum of ticks until second time reference
    /// @return _success Boolean indicating if the observe call was succesfull
    function observe(address _pool, uint32[] memory _secondsAgo)
        external
        view
        returns (
            int56 _tickCumulative1,
            int56 _tickCumulative2,
            bool _success
        );

    /// @notice Given a tick and a liquidity amount, calculates the underlying KP3R tokens
    /// @param _liquidityAmount Amount of liquidity to be converted
    /// @param _tickDifference Tick value used to calculate the quote
    /// @param _timeInterval Time value used to calculate the quote
    /// @return _kp3rAmount Amount of KP3R tokens underlying on the given liquidity
    function getKP3RsAtTick(
        uint256 _liquidityAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) external pure returns (uint256 _kp3rAmount);

    /// @notice Given a tick and a token amount, calculates the output in correspondant token
    /// @param _baseAmount Amount of token to be converted
    /// @param _tickDifference Tick value used to calculate the quote
    /// @param _timeInterval Time value used to calculate the quote
    /// @return _quoteAmount Amount of credits deserved for the baseAmount at the tick value
    function getQuoteAtTick(
        uint128 _baseAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) external pure returns (uint256 _quoteAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../interfaces/peripherals/IKeep3rAccountance.sol";

abstract contract Keep3rAccountance is IKeep3rAccountance {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice List of all enabled keepers
    EnumerableSet.AddressSet internal _keepers;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => uint256) public override workCompleted;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => uint256) public override firstSeen;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => bool) public override disputes;

    /// @inheritdoc IKeep3rAccountance
    /// @notice Mapping (job => bonding => amount)
    mapping(address => mapping(address => uint256)) public override bonds;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => mapping(address => uint256)) public override jobTokenCredits;

    /// @notice The current liquidity credits available for a job
    mapping(address => uint256) internal _jobLiquidityCredits;

    /// @notice Map the address of a job to its correspondent periodCredits
    mapping(address => uint256) internal _jobPeriodCredits;

    /// @notice Enumerable array of Job Tokens for Credits
    mapping(address => EnumerableSet.AddressSet) internal _jobTokens;

    /// @notice List of liquidities that a job has (job => liquidities)
    mapping(address => EnumerableSet.AddressSet) internal _jobLiquidities;

    /// @notice Liquidity pool to observe
    mapping(address => address) internal _liquidityPool;

    /// @notice Tracks if a pool has KP3R as token0
    mapping(address => bool) internal _isKP3RToken0;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => mapping(address => uint256)) public override pendingBonds;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => mapping(address => uint256)) public override canActivateAfter;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => mapping(address => uint256)) public override canWithdrawAfter;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => mapping(address => uint256)) public override pendingUnbonds;

    /// @inheritdoc IKeep3rAccountance
    mapping(address => bool) public override hasBonded;

    /// @notice List of all enabled jobs
    EnumerableSet.AddressSet internal _jobs;

    /// @inheritdoc IKeep3rAccountance
    function jobs() external view override returns (address[] memory _list) {
        _list = _jobs.values();
    }

    /// @inheritdoc IKeep3rAccountance
    function keepers() external view override returns (address[] memory _list) {
        _list = _keepers.values();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../../interfaces/peripherals/IKeep3rJobs.sol";
import "./Keep3rJobFundableCredits.sol";
import "./Keep3rJobFundableLiquidity.sol";

abstract contract Keep3rJobMigration is IKeep3rJobMigration, Keep3rJobFundableCredits, Keep3rJobFundableLiquidity {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant _MIGRATION_COOLDOWN = 1 minutes;

    /// @inheritdoc IKeep3rJobMigration
    mapping(address => address) public override pendingJobMigrations;
    mapping(address => mapping(address => uint256)) internal _migrationCreatedAt;

    /// @inheritdoc IKeep3rJobMigration
    function migrateJob(address _fromJob, address _toJob) external override onlyJobOwner(_fromJob) {
        if (_fromJob == _toJob) revert JobMigrationImpossible();

        pendingJobMigrations[_fromJob] = _toJob;
        _migrationCreatedAt[_fromJob][_toJob] = block.timestamp;

        emit JobMigrationRequested(_fromJob, _toJob);
    }

    /// @inheritdoc IKeep3rJobMigration
    function acceptJobMigration(address _fromJob, address _toJob) external override onlyJobOwner(_toJob) {
        if (disputes[_fromJob] || disputes[_toJob]) revert JobDisputed();
        if (pendingJobMigrations[_fromJob] != _toJob) revert JobMigrationUnavailable();
        if (block.timestamp < _migrationCreatedAt[_fromJob][_toJob] + _MIGRATION_COOLDOWN) revert JobMigrationLocked();

        // force job credits update for both jobs
        _settleJobAccountance(_fromJob);
        _settleJobAccountance(_toJob);

        // migrate tokens
        while (_jobTokens[_fromJob].length() > 0) {
            address _tokenToMigrate = _jobTokens[_fromJob].at(0);
            jobTokenCredits[_toJob][_tokenToMigrate] += jobTokenCredits[_fromJob][_tokenToMigrate];
            jobTokenCredits[_fromJob][_tokenToMigrate] = 0;
            _jobTokens[_fromJob].remove(_tokenToMigrate);
            _jobTokens[_toJob].add(_tokenToMigrate);
        }

        // migrate liquidities
        while (_jobLiquidities[_fromJob].length() > 0) {
            address _liquidity = _jobLiquidities[_fromJob].at(0);

            liquidityAmount[_toJob][_liquidity] += liquidityAmount[_fromJob][_liquidity];
            delete liquidityAmount[_fromJob][_liquidity];

            _jobLiquidities[_toJob].add(_liquidity);
            _jobLiquidities[_fromJob].remove(_liquidity);
        }

        // migrate job balances
        _jobPeriodCredits[_toJob] += _jobPeriodCredits[_fromJob];
        delete _jobPeriodCredits[_fromJob];

        _jobLiquidityCredits[_toJob] += _jobLiquidityCredits[_fromJob];
        delete _jobLiquidityCredits[_fromJob];

        // stop _fromJob from being a job
        delete rewardedAt[_fromJob];
        _jobs.remove(_fromJob);

        // delete unused data slots
        delete jobOwner[_fromJob];
        delete jobPendingOwner[_fromJob];
        delete _migrationCreatedAt[_fromJob][_toJob];
        delete pendingJobMigrations[_fromJob];

        emit JobMigrationSuccessful(_fromJob, _toJob);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobOwnership.sol";
import "../Keep3rAccountance.sol";
import "../Keep3rParameters.sol";
import "../../../interfaces/peripherals/IKeep3rJobs.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract Keep3rJobFundableCredits is
    IKeep3rJobFundableCredits,
    ReentrancyGuard,
    Keep3rJobOwnership,
    Keep3rParameters
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @notice Cooldown between withdrawals
    uint256 internal constant _WITHDRAW_TOKENS_COOLDOWN = 1 minutes;

    /// @inheritdoc IKeep3rJobFundableCredits
    mapping(address => mapping(address => uint256)) public override jobTokenCreditsAddedAt;

    /// @inheritdoc IKeep3rJobFundableCredits
    function addTokenCreditsToJob(
        address _job,
        address _token,
        uint256 _amount
    ) external override nonReentrant {
        if (!_jobs.contains(_job)) revert JobUnavailable();
        // KP3R shouldn't be used for direct token payments
        if (_token == keep3rV1) revert TokenUnallowed();
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _received = IERC20(_token).balanceOf(address(this)) - _before;
        uint256 _tokenFee = (_received * fee) / BASE;
        jobTokenCredits[_job][_token] += _received - _tokenFee;
        jobTokenCreditsAddedAt[_job][_token] = block.timestamp;
        IERC20(_token).safeTransfer(governance, _tokenFee);
        _jobTokens[_job].add(_token);

        emit TokenCreditAddition(_job, _token, msg.sender, _received);
    }

    /// @inheritdoc IKeep3rJobFundableCredits
    function withdrawTokenCreditsFromJob(
        address _job,
        address _token,
        uint256 _amount,
        address _receiver
    ) external override nonReentrant onlyJobOwner(_job) {
        if (block.timestamp <= jobTokenCreditsAddedAt[_job][_token] + _WITHDRAW_TOKENS_COOLDOWN)
            revert JobTokenCreditsLocked();
        if (jobTokenCredits[_job][_token] < _amount) revert InsufficientJobTokenCredits();
        if (disputes[_job]) revert JobDisputed();

        jobTokenCredits[_job][_token] -= _amount;
        IERC20(_token).safeTransfer(_receiver, _amount);

        if (jobTokenCredits[_job][_token] == 0) {
            _jobTokens[_job].remove(_token);
        }

        emit TokenCreditWithdrawal(_job, _token, _receiver, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobOwnership.sol";
import "../Keep3rAccountance.sol";
import "../Keep3rParameters.sol";
import "../../../interfaces/IPairManager.sol";
import "../../../interfaces/peripherals/IKeep3rJobs.sol";

import "../../libraries/FullMath.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract Keep3rJobFundableLiquidity is
    IKeep3rJobFundableLiquidity,
    ReentrancyGuard,
    Keep3rJobOwnership,
    Keep3rParameters
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @notice List of liquidities that are accepted in the system
    EnumerableSet.AddressSet internal _approvedLiquidities;

    /// @inheritdoc IKeep3rJobFundableLiquidity
    mapping(address => mapping(address => uint256)) public override liquidityAmount;

    /// @inheritdoc IKeep3rJobFundableLiquidity
    mapping(address => uint256) public override rewardedAt;

    /// @inheritdoc IKeep3rJobFundableLiquidity
    mapping(address => uint256) public override workedAt;

    /// @notice Tracks an address and returns its TickCache
    mapping(address => TickCache) internal _tick;

    // Views

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function approvedLiquidities() external view override returns (address[] memory _list) {
        _list = _approvedLiquidities.values();
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function jobPeriodCredits(address _job) public view override returns (uint256 _periodCredits) {
        for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
            address _liquidity = _jobLiquidities[_job].at(i);
            if (_approvedLiquidities.contains(_liquidity)) {
                TickCache memory _tickCache = observeLiquidity(_liquidity);
                if (_tickCache.period != 0) {
                    int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
                    _periodCredits += _getReward(
                        IKeep3rHelper(keep3rHelper).getKP3RsAtTick(
                            liquidityAmount[_job][_liquidity],
                            _tickDifference,
                            rewardPeriodTime
                        )
                    );
                }
            }
        }
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function jobLiquidityCredits(address _job) public view override returns (uint256 _liquidityCredits) {
        uint256 _periodCredits = jobPeriodCredits(_job);

        // A job can have liquidityCredits without periodCredits (forced by Governance)
        if (rewardedAt[_job] > _period(block.timestamp - rewardPeriodTime)) {
            // Will calculate job credits only if it was rewarded later than last period
            if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
                // Will return a full period if job was rewarded more than a period ago
                _liquidityCredits = _periodCredits;
            } else {
                // Will update minted job credits (not forced) to new twaps if credits are outdated
                _liquidityCredits = _periodCredits > 0
                    ? (_jobLiquidityCredits[_job] * _periodCredits) / _jobPeriodCredits[_job]
                    : _jobLiquidityCredits[_job];
            }
        } else {
            // Will return a full period if job credits are expired
            _liquidityCredits = _periodCredits;
        }
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function totalJobCredits(address _job) external view override returns (uint256 _credits) {
        uint256 _periodCredits = jobPeriodCredits(_job);
        uint256 _cooldown;

        if ((rewardedAt[_job] > _period(block.timestamp - rewardPeriodTime))) {
            // Will calculate cooldown if it outdated
            if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
                // Will calculate cooldown from last reward reference in this period
                _cooldown = block.timestamp - (rewardedAt[_job] + rewardPeriodTime);
            } else {
                // Will calculate cooldown from last reward timestamp
                _cooldown = block.timestamp - rewardedAt[_job];
            }
        } else {
            // Will calculate cooldown from period start if expired
            _cooldown = block.timestamp - _period(block.timestamp);
        }
        _credits = jobLiquidityCredits(_job) + _phase(_cooldown, _periodCredits);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function quoteLiquidity(address _liquidity, uint256 _amount)
        external
        view
        override
        returns (uint256 _periodCredits)
    {
        if (_approvedLiquidities.contains(_liquidity)) {
            TickCache memory _tickCache = observeLiquidity(_liquidity);
            if (_tickCache.period != 0) {
                int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
                return
                    _getReward(IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime));
            }
        }
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function observeLiquidity(address _liquidity) public view override returns (TickCache memory _tickCache) {
        if (_tick[_liquidity].period == _period(block.timestamp)) {
            // Will return cached twaps if liquidity is updated
            _tickCache = _tick[_liquidity];
        } else {
            bool success;
            uint256 lastPeriod = _period(block.timestamp - rewardPeriodTime);

            if (_tick[_liquidity].period == lastPeriod) {
                // Will only ask for current period accumulator if liquidity is outdated
                uint32[] memory _secondsAgo = new uint32[](1);
                int56 previousTick = _tick[_liquidity].current;

                _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));

                (_tickCache.current, , success) = IKeep3rHelper(keep3rHelper).observe(
                    _liquidityPool[_liquidity],
                    _secondsAgo
                );

                _tickCache.difference = _tickCache.current - previousTick;
            } else if (_tick[_liquidity].period < lastPeriod) {
                // Will ask for 2 accumulators if liquidity is expired
                uint32[] memory _secondsAgo = new uint32[](2);

                _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));
                _secondsAgo[1] = uint32(block.timestamp - _period(block.timestamp) + rewardPeriodTime);

                int56 _tickCumulative2;
                (_tickCache.current, _tickCumulative2, success) = IKeep3rHelper(keep3rHelper).observe(
                    _liquidityPool[_liquidity],
                    _secondsAgo
                );

                _tickCache.difference = _tickCache.current - _tickCumulative2;
            }
            if (success) {
                _tickCache.period = _period(block.timestamp);
            } else {
                _tickCache.period = 0;
            }
        }
    }

    // Methods

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function forceLiquidityCreditsToJob(address _job, uint256 _amount) external override onlyGovernance {
        if (!_jobs.contains(_job)) revert JobUnavailable();
        _settleJobAccountance(_job);
        _jobLiquidityCredits[_job] += _amount;
        emit LiquidityCreditsForced(_job, rewardedAt[_job], _jobLiquidityCredits[_job]);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function approveLiquidity(address _liquidity) external override onlyGovernance {
        if (!_approvedLiquidities.add(_liquidity)) revert LiquidityPairApproved();
        _liquidityPool[_liquidity] = IPairManager(_liquidity).pool();
        _isKP3RToken0[_liquidity] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_liquidityPool[_liquidity]);
        _tick[_liquidity] = observeLiquidity(_liquidity);
        emit LiquidityApproval(_liquidity);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function revokeLiquidity(address _liquidity) external override onlyGovernance {
        if (!_approvedLiquidities.remove(_liquidity)) revert LiquidityPairUnexistent();
        emit LiquidityRevocation(_liquidity);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function addLiquidityToJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external override nonReentrant {
        if (!_approvedLiquidities.contains(_liquidity)) revert LiquidityPairUnapproved();
        if (!_jobs.contains(_job)) revert JobUnavailable();

        _jobLiquidities[_job].add(_liquidity);

        _settleJobAccountance(_job);

        if (_quoteLiquidity(liquidityAmount[_job][_liquidity] + _amount, _liquidity) < liquidityMinimum)
            revert JobLiquidityLessThanMin();

        emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);

        IERC20(_liquidity).safeTransferFrom(msg.sender, address(this), _amount);
        liquidityAmount[_job][_liquidity] += _amount;
        _jobPeriodCredits[_job] += _getReward(_quoteLiquidity(_amount, _liquidity));
        emit LiquidityAddition(_job, _liquidity, msg.sender, _amount);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function unbondLiquidityFromJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external override onlyJobOwner(_job) {
        canWithdrawAfter[_job][_liquidity] = block.timestamp + unbondTime;
        pendingUnbonds[_job][_liquidity] += _amount;
        _unbondLiquidityFromJob(_job, _liquidity, _amount);

        uint256 _remainingLiquidity = liquidityAmount[_job][_liquidity];
        if (_remainingLiquidity > 0 && _quoteLiquidity(_remainingLiquidity, _liquidity) < liquidityMinimum)
            revert JobLiquidityLessThanMin();

        emit Unbonding(_job, _liquidity, _amount);
    }

    /// @inheritdoc IKeep3rJobFundableLiquidity
    function withdrawLiquidityFromJob(
        address _job,
        address _liquidity,
        address _receiver
    ) external override onlyJobOwner(_job) {
        if (_receiver == address(0)) revert ZeroAddress();
        if (canWithdrawAfter[_job][_liquidity] == 0) revert UnbondsUnexistent();
        if (canWithdrawAfter[_job][_liquidity] >= block.timestamp) revert UnbondsLocked();
        if (disputes[_job]) revert Disputed();

        uint256 _amount = pendingUnbonds[_job][_liquidity];
        IERC20(_liquidity).safeTransfer(_receiver, _amount);
        emit LiquidityWithdrawal(_job, _liquidity, _receiver, _amount);

        pendingUnbonds[_job][_liquidity] = 0;
    }

    // Internal functions

    /// @notice Updates or rewards job liquidity credits depending on time since last job reward
    function _updateJobCreditsIfNeeded(address _job) internal returns (bool _rewarded) {
        if (rewardedAt[_job] < _period(block.timestamp)) {
            // Will exit function if job has been rewarded in current period
            if (rewardedAt[_job] <= _period(block.timestamp - rewardPeriodTime)) {
                // Will reset job to period syncronicity if a full period passed without rewards
                _updateJobPeriod(_job);
                _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
                rewardedAt[_job] = _period(block.timestamp);
                _rewarded = true;
            } else if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
                // Will reset job's syncronicity if last reward was more than epoch ago
                _updateJobPeriod(_job);
                _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
                rewardedAt[_job] += rewardPeriodTime;
                _rewarded = true;
            } else if (workedAt[_job] < _period(block.timestamp)) {
                // First keeper on period has to update job accountance to current twaps
                uint256 previousPeriodCredits = _jobPeriodCredits[_job];
                _updateJobPeriod(_job);
                _jobLiquidityCredits[_job] =
                    (_jobLiquidityCredits[_job] * _jobPeriodCredits[_job]) /
                    previousPeriodCredits;
                // Updating job accountance does not reward job
            }
        }
    }

    /// @notice Only called if _jobLiquidityCredits < payment
    function _rewardJobCredits(address _job) internal {
        /// @notice Only way to += jobLiquidityCredits is when keeper rewarding (cannot pay work)
        /* WARNING: this allows to top up _jobLiquidityCredits to a max of 1.99 but have to spend at least 1 */
        _jobLiquidityCredits[_job] += _phase(block.timestamp - rewardedAt[_job], _jobPeriodCredits[_job]);
        rewardedAt[_job] = block.timestamp;
    }

    /// @notice Updates accountance for _jobPeriodCredits
    function _updateJobPeriod(address _job) internal {
        _jobPeriodCredits[_job] = _calculateJobPeriodCredits(_job);
    }

    /// @notice Quotes the outdated job liquidities and calculates _periodCredits
    /// @dev This function is also responsible for keeping the KP3R/WETH quote updated
    function _calculateJobPeriodCredits(address _job) internal returns (uint256 _periodCredits) {
        if (_tick[kp3rWethPool].period != _period(block.timestamp)) {
            // Updates KP3R/WETH quote if needed
            _tick[kp3rWethPool] = observeLiquidity(kp3rWethPool);
        }

        for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
            address _liquidity = _jobLiquidities[_job].at(i);
            if (_approvedLiquidities.contains(_liquidity)) {
                if (_tick[_liquidity].period != _period(block.timestamp)) {
                    // Updates liquidity cache only if needed
                    _tick[_liquidity] = observeLiquidity(_liquidity);
                }
                _periodCredits += _getReward(_quoteLiquidity(liquidityAmount[_job][_liquidity], _liquidity));
            }
        }
    }

    /// @notice Updates job accountance calculating the impact of the unbonded liquidity amount
    function _unbondLiquidityFromJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) internal nonReentrant {
        if (!_jobLiquidities[_job].contains(_liquidity)) revert JobLiquidityUnexistent();
        if (liquidityAmount[_job][_liquidity] < _amount) revert JobLiquidityInsufficient();

        // Ensures current twaps in job liquidities
        _updateJobPeriod(_job);
        uint256 _periodCreditsToRemove = _getReward(_quoteLiquidity(_amount, _liquidity));

        // A liquidity can be revoked causing a job to have 0 periodCredits
        if (_jobPeriodCredits[_job] > 0) {
            // Removes a % correspondant to a full rewardPeriodTime for the liquidity withdrawn vs all of the liquidities
            _jobLiquidityCredits[_job] -=
                (_jobLiquidityCredits[_job] * _periodCreditsToRemove) /
                _jobPeriodCredits[_job];
            _jobPeriodCredits[_job] -= _periodCreditsToRemove;
        }

        liquidityAmount[_job][_liquidity] -= _amount;
        if (liquidityAmount[_job][_liquidity] == 0) {
            _jobLiquidities[_job].remove(_liquidity);
        }
    }

    /// @notice Returns a fraction of the multiplier or the whole multiplier if equal or more than a rewardPeriodTime has passed
    function _phase(uint256 _timePassed, uint256 _multiplier) internal view returns (uint256 _result) {
        if (_timePassed < rewardPeriodTime) {
            _result = (_timePassed * _multiplier) / rewardPeriodTime;
        } else _result = _multiplier;
    }

    /// @notice Returns the start of the period of the provided timestamp
    function _period(uint256 _timestamp) internal view returns (uint256 _periodTimestamp) {
        return _timestamp - (_timestamp % rewardPeriodTime);
    }

    /// @notice Calculates relation between rewardPeriod and inflationPeriod
    function _getReward(uint256 _baseAmount) internal view returns (uint256 _credits) {
        return FullMath.mulDiv(_baseAmount, rewardPeriodTime, inflationPeriod);
    }

    /// @notice Returns underlying KP3R amount for a given liquidity amount
    function _quoteLiquidity(uint256 _amount, address _liquidity) internal view returns (uint256 _quote) {
        if (_tick[_liquidity].period != 0) {
            int56 _tickDifference = _isKP3RToken0[_liquidity]
                ? _tick[_liquidity].difference
                : -_tick[_liquidity].difference;
            _quote = IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime);
        }
    }

    /// @notice Updates job credits to current quotes and rewards job's pending minted credits
    /// @dev Ensures a maximum of 1 period of credits
    function _settleJobAccountance(address _job) internal virtual {
        _updateJobCreditsIfNeeded(_job);
        _rewardJobCredits(_job);
        _jobLiquidityCredits[_job] = Math.min(_jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }
}

// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.7 <0.9.0;

import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";
import "../interfaces/IKeep3r.sol";
import "../interfaces/external/IKeep3rV1.sol";
import "../interfaces/IKeep3rHelper.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract Keep3rHelper is IKeep3rHelper {
    address public immutable keep3rV2;

    constructor(address _keep3rV2) {
        keep3rV2 = _keep3rV2;
    }

    /// @inheritdoc IKeep3rHelper
    address public constant override KP3R = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;

    /// @inheritdoc IKeep3rHelper
    address public constant override KP3R_WETH_POOL = 0x11B7a6bc0259ed6Cf9DB8F499988F9eCc7167bf5;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override MIN = 11_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override MAX = 12_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override BOOST_BASE = 10_000;

    /// @inheritdoc IKeep3rHelper
    uint256 public constant override TARGETBOND = 200 ether;

    /// @inheritdoc IKeep3rHelper
    function quote(uint256 _eth) public view override returns (uint256 _amountOut) {
        bool _isKP3RToken0 = isKP3RToken0(KP3R_WETH_POOL);
        int56 _tickDifference = IKeep3r(keep3rV2).observeLiquidity(KP3R_WETH_POOL).difference;
        _tickDifference = _isKP3RToken0 ? _tickDifference : -_tickDifference;
        uint256 _tickInterval = IKeep3r(keep3rV2).rewardPeriodTime();
        _amountOut = getQuoteAtTick(uint128(_eth), _tickDifference, _tickInterval);
    }

    /// @inheritdoc IKeep3rHelper
    function bonds(address _keeper) public view override returns (uint256 _amountBonded) {
        return IKeep3r(keep3rV2).bonds(_keeper, KP3R);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardAmountFor(address _keeper, uint256 _gasUsed) public view override returns (uint256 _kp3r) {
        uint256 _boost = getRewardBoostFor(bonds(_keeper));
        _kp3r = quote((_gasUsed * _boost) / BOOST_BASE);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardAmount(uint256 _gasUsed) external view override returns (uint256 _amount) {
        // solhint-disable-next-line avoid-tx-origin
        return getRewardAmountFor(tx.origin, _gasUsed);
    }

    /// @inheritdoc IKeep3rHelper
    function getRewardBoostFor(uint256 _bonds) public view override returns (uint256 _rewardBoost) {
        _bonds = Math.min(_bonds, TARGETBOND);
        uint256 _cap = Math.max(MIN, (MAX * _bonds) / TARGETBOND);
        _rewardBoost = _cap * _getBasefee();
    }

    /// @inheritdoc IKeep3rHelper
    function getPoolTokens(address _pool) public view override returns (address _token0, address _token1) {
        return (IUniswapV3Pool(_pool).token0(), IUniswapV3Pool(_pool).token1());
    }

    /// @inheritdoc IKeep3rHelper
    function isKP3RToken0(address _pool) public view override returns (bool _isKP3RToken0) {
        address _token0;
        address _token1;
        (_token0, _token1) = getPoolTokens(_pool);
        if (_token0 == KP3R) {
            return true;
        } else if (_token1 != KP3R) {
            revert LiquidityPairInvalid();
        }
    }

    /// @inheritdoc IKeep3rHelper
    function observe(address _pool, uint32[] memory _secondsAgo)
        public
        view
        override
        returns (
            int56 _tickCumulative1,
            int56 _tickCumulative2,
            bool _success
        )
    {
        try IUniswapV3Pool(_pool).observe(_secondsAgo) returns (int56[] memory _uniswapResponse, uint160[] memory) {
            _tickCumulative1 = _uniswapResponse[0];
            if (_uniswapResponse.length > 1) {
                _tickCumulative2 = _uniswapResponse[1];
            }
            _success = true;
        } catch (bytes memory) {}
    }

    /// @inheritdoc IKeep3rHelper
    function getKP3RsAtTick(
        uint256 _liquidityAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) public pure override returns (uint256 _kp3rAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));
        _kp3rAmount = FullMath.mulDiv(1 << 96, _liquidityAmount, sqrtRatioX96);
    }

    /// @inheritdoc IKeep3rHelper
    function getQuoteAtTick(
        uint128 _baseAmount,
        int56 _tickDifference,
        uint256 _timeInterval
    ) public pure override returns (uint256 _quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(int24(_tickDifference / int256(_timeInterval)));

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            _quoteAmount = FullMath.mulDiv(1 << 192, _baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            _quoteAmount = FullMath.mulDiv(1 << 128, _baseAmount, ratioX128);
        }
    }

    /// @notice Gets the block's base fee
    /// @return _baseFee The block's basefee
    function _getBasefee() internal view virtual returns (uint256 _baseFee) {
        return block.basefee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// solhint-disable func-name-mixedcase
interface IKeep3rV1 is IERC20, IERC20Metadata {
    // Structs
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // Events
    event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);
    event DelegateVotesChanged(address indexed _delegate, uint256 _previousBalance, uint256 _newBalance);
    event SubmitJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event ApplyCredit(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event RemoveJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event UnbondJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event JobAdded(address indexed _job, uint256 _block, address _governance);
    event JobRemoved(address indexed _job, uint256 _block, address _governance);
    event KeeperWorked(
        address indexed _credit,
        address indexed _job,
        address indexed _keeper,
        uint256 _block,
        uint256 _amount
    );
    event KeeperBonding(address indexed _keeper, uint256 _block, uint256 _active, uint256 _bond);
    event KeeperBonded(address indexed _keeper, uint256 _block, uint256 _activated, uint256 _bond);
    event KeeperUnbonding(address indexed _keeper, uint256 _block, uint256 _deactive, uint256 _bond);
    event KeeperUnbound(address indexed _keeper, uint256 _block, uint256 _deactivated, uint256 _bond);
    event KeeperSlashed(address indexed _keeper, address indexed _slasher, uint256 _block, uint256 _slash);
    event KeeperDispute(address indexed _keeper, uint256 _block);
    event KeeperResolved(address indexed _keeper, uint256 _block);
    event TokenCreditAddition(
        address indexed _credit,
        address indexed _job,
        address indexed _creditor,
        uint256 _block,
        uint256 _amount
    );

    // Variables
    function KPRH() external returns (address);

    function delegates(address _delegator) external view returns (address);

    function checkpoints(address _account, uint32 _checkpoint) external view returns (Checkpoint memory);

    function numCheckpoints(address _account) external view returns (uint32);

    function DOMAIN_TYPEHASH() external returns (bytes32);

    function DOMAINSEPARATOR() external returns (bytes32);

    function DELEGATION_TYPEHASH() external returns (bytes32);

    function PERMIT_TYPEHASH() external returns (bytes32);

    function nonces(address _user) external view returns (uint256);

    function BOND() external returns (uint256);

    function UNBOND() external returns (uint256);

    function LIQUIDITYBOND() external returns (uint256);

    function FEE() external returns (uint256);

    function BASE() external returns (uint256);

    function ETH() external returns (address);

    function bondings(address _user, address _bonding) external view returns (uint256);

    function canWithdrawAfter(address _user, address _bonding) external view returns (uint256);

    function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256);

    function pendingbonds(address _keeper, address _bonding) external view returns (uint256);

    function bonds(address _keeper, address _bonding) external view returns (uint256);

    function votes(address _delegator) external view returns (uint256);

    function firstSeen(address _keeper) external view returns (uint256);

    function disputes(address _keeper) external view returns (bool);

    function lastJob(address _keeper) external view returns (uint256);

    function workCompleted(address _keeper) external view returns (uint256);

    function jobs(address _job) external view returns (bool);

    function credits(address _job, address _credit) external view returns (uint256);

    function liquidityProvided(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityUnbonding(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityAmountsUnbonding(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function jobProposalDelay(address _job) external view returns (uint256);

    function liquidityApplied(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityAmount(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function keepers(address _keeper) external view returns (bool);

    function blacklist(address _keeper) external view returns (bool);

    function keeperList(uint256 _index) external view returns (address);

    function jobList(uint256 _index) external view returns (address);

    function governance() external returns (address);

    function pendingGovernance() external returns (address);

    function liquidityAccepted(address _liquidity) external view returns (bool);

    function liquidityPairs(uint256 _index) external view returns (address);

    // Methods
    function getCurrentVotes(address _account) external view returns (uint256);

    function addCreditETH(address _job) external payable;

    function addCredit(
        address _credit,
        address _job,
        uint256 _amount
    ) external;

    function addVotes(address _voter, uint256 _amount) external;

    function removeVotes(address _voter, uint256 _amount) external;

    function addKPRCredit(address _job, uint256 _amount) external;

    function approveLiquidity(address _liquidity) external;

    function revokeLiquidity(address _liquidity) external;

    function pairs() external view returns (address[] memory);

    function addLiquidityToJob(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function applyCreditToJob(
        address _provider,
        address _liquidity,
        address _job
    ) external;

    function unbondLiquidityFromJob(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function removeLiquidityFromJob(address _liquidity, address _job) external;

    function mint(uint256 _amount) external;

    function burn(uint256 _amount) external;

    function worked(address _keeper) external;

    function receipt(
        address _credit,
        address _keeper,
        uint256 _amount
    ) external;

    function receiptETH(address _keeper, uint256 _amount) external;

    function addJob(address _job) external;

    function getJobs() external view returns (address[] memory);

    function removeJob(address _job) external;

    function setKeep3rHelper(address _keep3rHelper) external;

    function setGovernance(address _governance) external;

    function acceptGovernance() external;

    function isKeeper(address _keeper) external returns (bool);

    function isMinKeeper(
        address _keeper,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) external returns (bool);

    function isBondedKeeper(
        address _keeper,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) external returns (bool);

    function bond(address _bonding, uint256 _amount) external;

    function getKeepers() external view returns (address[] memory);

    function activate(address _bonding) external;

    function unbond(address _bonding, uint256 _amount) external;

    function slash(
        address _bonded,
        address _keeper,
        uint256 _amount
    ) external;

    function withdraw(address _bonding) external;

    function dispute(address _keeper) external;

    function revoke(address _keeper) external;

    function resolve(address _keeper) external;

    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobMigration.sol";
import "../../../interfaces/IKeep3rHelper.sol";
import "../../../interfaces/peripherals/IKeep3rJobs.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Keep3rJobWorkable is IKeep3rJobWorkable, Keep3rJobMigration {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 internal _initialGas;

    /// @inheritdoc IKeep3rJobWorkable
    function isKeeper(address _keeper) external override returns (bool _isKeeper) {
        _initialGas = gasleft();
        if (_keepers.contains(_keeper)) {
            emit KeeperValidation(gasleft());
            return true;
        }
    }

    /// @inheritdoc IKeep3rJobWorkable
    function isBondedKeeper(
        address _keeper,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) public override returns (bool _isBondedKeeper) {
        _initialGas = gasleft();
        if (
            _keepers.contains(_keeper) &&
            bonds[_keeper][_bond] >= _minBond &&
            workCompleted[_keeper] >= _earned &&
            block.timestamp - firstSeen[_keeper] >= _age
        ) {
            emit KeeperValidation(gasleft());
            return true;
        }
    }

    /// @inheritdoc IKeep3rJobWorkable
    function worked(address _keeper) external override {
        address _job = msg.sender;
        if (disputes[_job]) revert JobDisputed();
        if (!_jobs.contains(_job)) revert JobUnapproved();

        if (_updateJobCreditsIfNeeded(_job)) {
            emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
        }

        uint256 _gasRecord = gasleft();
        uint256 _boost = IKeep3rHelper(keep3rHelper).getRewardBoostFor(bonds[_keeper][keep3rV1]);

        uint256 _payment = (_quoteLiquidity(_initialGas - _gasRecord, kp3rWethPool) * _boost) / BASE;

        if (_payment > _jobLiquidityCredits[_job]) {
            _rewardJobCredits(_job);
            emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
        }

        uint256 _gasUsed = _initialGas - gasleft();
        _payment = (_gasUsed * _payment) / (_initialGas - _gasRecord);

        _bondedPayment(_job, _keeper, _payment);
        emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
    }

    /// @inheritdoc IKeep3rJobWorkable
    function bondedPayment(address _keeper, uint256 _payment) public override {
        address _job = msg.sender;

        if (disputes[_job]) revert JobDisputed();
        if (!_jobs.contains(_job)) revert JobUnapproved();

        if (_updateJobCreditsIfNeeded(_job)) {
            emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
        }

        if (_payment > _jobLiquidityCredits[_job]) {
            _rewardJobCredits(_job);
            emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
        }

        _bondedPayment(_job, _keeper, _payment);
        emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
    }

    function _bondedPayment(
        address _job,
        address _keeper,
        uint256 _payment
    ) internal {
        if (_payment > _jobLiquidityCredits[_job]) revert InsufficientFunds();

        workedAt[_job] = block.timestamp;
        _jobLiquidityCredits[_job] -= _payment;
        bonds[_keeper][keep3rV1] += _payment;
        workCompleted[_keeper] += _payment;
    }

    /// @inheritdoc IKeep3rJobWorkable
    function directTokenPayment(
        address _token,
        address _keeper,
        uint256 _amount
    ) external override {
        address _job = msg.sender;

        if (disputes[_job]) revert JobDisputed();
        if (disputes[_keeper]) revert Disputed();
        if (!_jobs.contains(_job)) revert JobUnapproved();
        if (jobTokenCredits[_job][_token] < _amount) revert InsufficientFunds();
        jobTokenCredits[_job][_token] -= _amount;
        IERC20(_token).safeTransfer(_keeper, _amount);
        emit KeeperWork(_token, _job, _keeper, _amount, gasleft());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../peripherals/IGovernable.sol";

interface IKeep3rV1Proxy is IGovernable {
    // Structs
    struct Recipient {
        address recipient;
        uint256 caps;
    }

    // Variables
    function keep3rV1() external view returns (address);

    function minter() external view returns (address);

    function next(address) external view returns (uint256);

    function caps(address) external view returns (uint256);

    function recipients() external view returns (address[] memory);

    function recipientsCaps() external view returns (Recipient[] memory);

    // Errors
    error Cooldown();
    error NoDrawableAmount();
    error ZeroAddress();
    error OnlyMinter();

    // Methods
    function addRecipient(address recipient, uint256 amount) external;

    function removeRecipient(address recipient) external;

    function draw() external returns (uint256 _amount);

    function setKeep3rV1(address _keep3rV1) external;

    function setMinter(address _minter) external;

    function mint(uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setKeep3rV1Governance(address _governance) external;

    function acceptKeep3rV1Governance() external;

    function dispute(address _keeper) external;

    function slash(
        address _bonded,
        address _keeper,
        uint256 _amount
    ) external;

    function revoke(address _keeper) external;

    function resolve(address _keeper) external;

    function addJob(address _job) external;

    function removeJob(address _job) external;

    function addKPRCredit(address _job, uint256 _amount) external;

    function approveLiquidity(address _liquidity) external;

    function revokeLiquidity(address _liquidity) external;

    function setKeep3rHelper(address _keep3rHelper) external;

    function addVotes(address _voter, uint256 _amount) external;

    function removeVotes(address _voter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../Keep3rAccountance.sol";
import "../Keep3rParameters.sol";
import "../../../interfaces/peripherals/IKeep3rKeepers.sol";

import "../../../interfaces/external/IKeep3rV1.sol";
import "../../../interfaces/external/IKeep3rV1Proxy.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Keep3rKeeperFundable is IKeep3rKeeperFundable, ReentrancyGuard, Keep3rParameters {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @inheritdoc IKeep3rKeeperFundable
    function bond(address _bonding, uint256 _amount) external override nonReentrant {
        if (disputes[msg.sender]) revert Disputed();
        if (_jobs.contains(msg.sender)) revert AlreadyAJob();
        canActivateAfter[msg.sender][_bonding] = block.timestamp + bondTime;

        uint256 _before = IERC20(_bonding).balanceOf(address(this));
        IERC20(_bonding).safeTransferFrom(msg.sender, address(this), _amount);
        _amount = IERC20(_bonding).balanceOf(address(this)) - _before;

        hasBonded[msg.sender] = true;
        pendingBonds[msg.sender][_bonding] += _amount;

        emit Bonding(msg.sender, _bonding, _amount);
    }

    /// @inheritdoc IKeep3rKeeperFundable
    function activate(address _bonding) external override {
        if (disputes[msg.sender]) revert Disputed();
        if (canActivateAfter[msg.sender][_bonding] == 0) revert BondsUnexistent();
        if (canActivateAfter[msg.sender][_bonding] >= block.timestamp) revert BondsLocked();

        _activate(msg.sender, _bonding);
    }

    /// @inheritdoc IKeep3rKeeperFundable
    function unbond(address _bonding, uint256 _amount) external override {
        canWithdrawAfter[msg.sender][_bonding] = block.timestamp + unbondTime;
        bonds[msg.sender][_bonding] -= _amount;
        pendingUnbonds[msg.sender][_bonding] += _amount;

        emit Unbonding(msg.sender, _bonding, _amount);
    }

    /// @inheritdoc IKeep3rKeeperFundable
    function withdraw(address _bonding) external override nonReentrant {
        if (canWithdrawAfter[msg.sender][_bonding] == 0) revert UnbondsUnexistent();
        if (canWithdrawAfter[msg.sender][_bonding] >= block.timestamp) revert UnbondsLocked();
        if (disputes[msg.sender]) revert Disputed();

        uint256 _amount = pendingUnbonds[msg.sender][_bonding];

        if (_bonding == keep3rV1) {
            IKeep3rV1Proxy(keep3rV1Proxy).mint(_amount);
        }

        pendingUnbonds[msg.sender][_bonding] = 0;
        IERC20(_bonding).safeTransfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _bonding, _amount);
    }

    function _bond(
        address _bonding,
        address _from,
        uint256 _amount
    ) internal {
        bonds[_from][_bonding] += _amount;
        if (_bonding == keep3rV1) {
            IKeep3rV1(keep3rV1).burn(_amount);
        }
    }

    function _activate(address _keeper, address _bonding) internal {
        if (firstSeen[_keeper] == 0) {
            firstSeen[_keeper] = block.timestamp;
        }
        _keepers.add(_keeper);
        uint256 _amount = pendingBonds[_keeper][_bonding];
        pendingBonds[_keeper][_bonding] = 0;
        _bond(_bonding, _keeper, _amount);

        emit Activation(_keeper, _bonding, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rParameters.sol";
import "./Keep3rRoles.sol";
import "../../interfaces/peripherals/IKeep3rDisputable.sol";

abstract contract Keep3rDisputable is IKeep3rDisputable, Keep3rAccountance, Keep3rRoles {
    /// @inheritdoc IKeep3rDisputable
    function dispute(address _jobOrKeeper) external override onlyDisputer {
        if (disputes[_jobOrKeeper]) revert AlreadyDisputed();
        disputes[_jobOrKeeper] = true;
        emit Dispute(_jobOrKeeper, msg.sender);
    }

    /// @inheritdoc IKeep3rDisputable
    function resolve(address _jobOrKeeper) external override onlyDisputer {
        if (!disputes[_jobOrKeeper]) revert NotDisputed();
        disputes[_jobOrKeeper] = false;
        emit Resolve(_jobOrKeeper, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Creates/resolves disputes for jobs or keepers
///         A disputed keeper is slashable and is not able to bond, activate, withdraw or receive direct payments
///         A disputed job is slashable and is not able to pay the keepers, withdraw tokens or to migrate
interface IKeep3rDisputable {
    /// @notice Emitted when a keeper or a job is disputed
    /// @param _jobOrKeeper The address of the disputed keeper/job
    /// @param _disputer The user that called the function and disputed the keeper
    event Dispute(address indexed _jobOrKeeper, address indexed _disputer);

    /// @notice Emitted when a dispute is resolved
    /// @param _jobOrKeeper The address of the disputed keeper/job
    /// @param _resolver The user that called the function and resolved the dispute
    event Resolve(address indexed _jobOrKeeper, address indexed _resolver);

    /// @notice Throws when a job or keeper is already disputed
    error AlreadyDisputed();

    /// @notice Throws when a job or keeper is not disputed and someone tries to resolve the dispute
    error NotDisputed();

    /// @notice Allows governance to create a dispute for a given keeper/job
    /// @param _jobOrKeeper The address in dispute
    function dispute(address _jobOrKeeper) external;

    /// @notice Allows governance to resolve a dispute on a keeper/job
    /// @param _jobOrKeeper The address cleared
    function resolve(address _jobOrKeeper) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rKeeperFundable.sol";
import "../Keep3rDisputable.sol";
import "../../../interfaces/external/IKeep3rV1.sol";
import "../../../interfaces/peripherals/IKeep3rKeepers.sol";

abstract contract Keep3rKeeperDisputable is IKeep3rKeeperDisputable, Keep3rDisputable, Keep3rKeeperFundable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @inheritdoc IKeep3rKeeperDisputable
    function slash(
        address _keeper,
        address _bonded,
        uint256 _amount
    ) public override onlySlasher {
        if (!disputes[_keeper]) revert NotDisputed();
        _slash(_keeper, _bonded, _amount);
        emit KeeperSlash(_keeper, msg.sender, _amount);
    }

    /// @inheritdoc IKeep3rKeeperDisputable
    function revoke(address _keeper) external override onlySlasher {
        if (!disputes[_keeper]) revert NotDisputed();
        _keepers.remove(_keeper);
        _slash(_keeper, keep3rV1, bonds[_keeper][keep3rV1]);
        emit KeeperRevoke(_keeper, msg.sender);
    }

    function _slash(
        address _keeper,
        address _bonded,
        uint256 _amount
    ) internal {
        if (_bonded != keep3rV1) {
            try IERC20(_bonded).transfer(governance, _amount) returns (bool) {} catch (bytes memory) {}
        }
        bonds[_keeper][_bonded] -= _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rKeeperDisputable.sol";

abstract contract Keep3rKeepers is Keep3rKeeperDisputable {}

// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "./peripherals/jobs/Keep3rJobs.sol";
import "./peripherals/keepers/Keep3rKeepers.sol";
import "./peripherals/Keep3rAccountance.sol";
import "./peripherals/Keep3rRoles.sol";
import "./peripherals/Keep3rParameters.sol";
import "./peripherals/DustCollector.sol";

contract Keep3r is DustCollector, Keep3rJobs, Keep3rKeepers {
    constructor(
        address _governance,
        address _keep3rHelper,
        address _keep3rV1,
        address _keep3rV1Proxy,
        address _kp3rWethPool
    )
        Keep3rParameters(_keep3rHelper, _keep3rV1, _keep3rV1Proxy, _kp3rWethPool)
        Keep3rRoles(_governance)
        DustCollector()
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobDisputable.sol";
import "./Keep3rJobWorkable.sol";
import "./Keep3rJobManager.sol";

abstract contract Keep3rJobs is Keep3rJobDisputable, Keep3rJobManager, Keep3rJobWorkable {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJobFundableCredits.sol";
import "./Keep3rJobFundableLiquidity.sol";
import "../Keep3rDisputable.sol";

abstract contract Keep3rJobDisputable is
    IKeep3rJobDisputable,
    Keep3rDisputable,
    Keep3rJobFundableCredits,
    Keep3rJobFundableLiquidity
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @inheritdoc IKeep3rJobDisputable
    function slashTokenFromJob(
        address _job,
        address _token,
        uint256 _amount
    ) external override onlySlasher {
        if (!disputes[_job]) revert NotDisputed();
        if (!_jobTokens[_job].contains(_token)) revert JobTokenUnexistent();
        if (jobTokenCredits[_job][_token] < _amount) revert JobTokenInsufficient();

        try IERC20(_token).transfer(governance, _amount) {} catch {}
        jobTokenCredits[_job][_token] -= _amount;
        if (jobTokenCredits[_job][_token] == 0) {
            _jobTokens[_job].remove(_token);
        }

        // emit event
        emit JobSlashToken(_job, _token, msg.sender, _amount);
    }

    /// @inheritdoc IKeep3rJobDisputable
    function slashLiquidityFromJob(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external override onlySlasher {
        if (!disputes[_job]) revert NotDisputed();

        _unbondLiquidityFromJob(_job, _liquidity, _amount);
        try IERC20(_liquidity).transfer(governance, _amount) {} catch {}
        emit JobSlashLiquidity(_job, _liquidity, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IFeePool.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IIndexFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPhuturePriceOracle.sol";

import "./NameRegistry.sol";

/// @title Index registry
/// @notice Contains core components, addresses and asset market capitalizations
/// @dev After initializing call next methods: setPriceOracle, setOrderer, setFeePool
contract IndexRegistry is IIndexRegistry, NameRegistry {
    using ERC165CheckerUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Responsible for all index related permissions
    bytes32 internal constant INDEX_ADMIN_ROLE = keccak256("INDEX_ADMIN_ROLE");
    /// @notice Responsible for all asset related permissions
    bytes32 internal constant ASSET_ADMIN_ROLE = keccak256("ASSET_ADMIN_ROLE");
    /// @notice Responsible for all ordering related permissions
    bytes32 internal constant ORDERING_ADMIN_ROLE = keccak256("ORDERING_ADMIN_ROLE");
    /// @notice Responsible for all exchange related permissions
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");

    /// @notice Role for index factory
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role for index
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Role allows index creation
    bytes32 internal constant INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    /// @notice Role for asset
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Role for assets which should be skipped during index burning
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Role allows update asset's market caps and vault reserve
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");
    /// @notice Role for orderer contract
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");
    /// @notice Role allows order execution
    bytes32 internal constant ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
    /// @notice Role allows perform validator's work
    bytes32 internal constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    /// @notice Role for keep3r job contract
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Role for UniswapV2Factory contract
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

    /// @inheritdoc IIndexRegistry
    mapping(address => uint) public override marketCapOf;
    /// @inheritdoc IIndexRegistry
    uint public override totalMarketCap;

    /// @inheritdoc IIndexRegistry
    uint public override maxComponents;

    /// @inheritdoc IIndexRegistry
    address public override orderer;
    /// @inheritdoc IIndexRegistry
    address public override priceOracle;
    /// @inheritdoc IIndexRegistry
    address public override feePool;
    /// @inheritdoc IIndexRegistry
    address public override indexLogic;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IIndexRegistry
    function initialize(address _indexLogic, uint _maxComponents) external override initializer {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        __NameRegistry_init();

        indexLogic = _indexLogic;
        maxComponents = _maxComponents;

        _setupRoles();
        _setupRoleAdmins();
    }

    /// @inheritdoc IIndexRegistry
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external override {
        require(!hasRole(INDEX_ROLE, _index), "IndexRegistry: EXISTS");

        grantRole(INDEX_ROLE, _index);
        _setIndexName(_index, _nameDetails.name);
        _setIndexSymbol(_index, _nameDetails.symbol);
    }

    /// @inheritdoc IIndexRegistry
    function setMaxComponents(uint _maxComponents) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        maxComponents = _maxComponents;
        emit SetMaxComponents(msg.sender, _maxComponents);
    }

    /// @inheritdoc IIndexRegistry
    function setIndexLogic(address _indexLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");

        indexLogic = _indexLogic;
        emit SetIndexLogic(msg.sender, _indexLogic);
    }

    /// @inheritdoc IIndexRegistry
    function setPriceOracle(address _priceOracle) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_priceOracle.supportsInterface(type(IPhuturePriceOracle).interfaceId), "IndexRegistry: INTERFACE");

        priceOracle = _priceOracle;
        emit SetPriceOracle(msg.sender, _priceOracle);
    }

    /// @inheritdoc IIndexRegistry
    function setOrderer(address _orderer) external override {
        require(_orderer.supportsInterface(type(IOrderer).interfaceId), "IndexRegistry: INTERFACE");

        if (orderer != address(0)) {
            revokeRole(ORDERER_ROLE, orderer);
        }

        orderer = _orderer;
        grantRole(ORDERER_ROLE, _orderer);
        emit SetOrderer(msg.sender, _orderer);
    }

    /// @inheritdoc IIndexRegistry
    function setFeePool(address _feePool) external override onlyRole(FEE_MANAGER_ROLE) {
        require(_feePool.supportsInterface(type(IFeePool).interfaceId), "IndexRegistry: INTERFACE");

        feePool = _feePool;
        emit SetFeePool(msg.sender, _feePool);
    }

    /// @inheritdoc IIndexRegistry
    function addAsset(address _asset, uint _marketCap) external override {
        require(IPhuturePriceOracle(priceOracle).containsOracleOf(_asset), "IndexRegistry: ORACLE");

        grantRole(ASSET_ROLE, _asset);
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function removeAsset(address _asset) external override {
        _updateMarketCap(_asset, 0);
        revokeRole(ASSET_ROLE, _asset);
    }

    /// @inheritdoc IIndexRegistry
    function updateAssetMarketCap(address _asset, uint _marketCap) external override onlyRole(ORACLE_ROLE) {
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IIndexRegistry
    function marketCapsOf(address[] calldata _assets)
        external
        view
        override
        returns (uint[] memory _marketCaps, uint _totalMarketCap)
    {
        uint assetsCount = _assets.length;
        _marketCaps = new uint[](assetsCount);

        for (uint i; i < assetsCount; ) {
            uint marketCap = marketCapOf[_assets[i]];
            _marketCaps[i] = marketCap;
            _totalMarketCap += marketCap;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Updates market capitalization of the given asset
    /// @dev Emits UpdateAsset event
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateAsset(address _asset, uint _marketCap) internal {
        require(_marketCap > 0, "IndexAssetRegistry: INVALID");

        _updateMarketCap(_asset, _marketCap);
        emit UpdateAsset(_asset, _marketCap);
    }

    /// @notice Setups initial roles
    function _setupRoles() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(INDEX_ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_ADMIN_ROLE, msg.sender);
        _setupRole(ORDERING_ADMIN_ROLE, msg.sender);
        _setupRole(EXCHANGE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Setups initial role admins
    function _setupRoleAdmins() internal {
        _setRoleAdmin(FACTORY_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_CREATOR_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_MANAGER_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(FEE_MANAGER_ROLE, INDEX_ADMIN_ROLE);

        _setRoleAdmin(INDEX_ROLE, FACTORY_ROLE);

        _setRoleAdmin(ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(SKIPPED_ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ASSET_MANAGER_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(RESERVE_MANAGER_ROLE, ASSET_ADMIN_ROLE);

        _setRoleAdmin(ORDERER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDERING_MANAGER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDER_EXECUTOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(KEEPER_JOB_ROLE, ORDERING_ADMIN_ROLE);

        _setRoleAdmin(EXCHANGE_FACTORY_ROLE, EXCHANGE_ADMIN_ROLE);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newImpl.supportsInterface(type(IIndexRegistry).interfaceId), "IndexRegistry: INTERFACE");
        super._authorizeUpgrade(_newImpl);
    }

    /// @notice Updates market capitalization of the given asset
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateMarketCap(address _asset, uint _marketCap) internal {
        require(hasRole(ASSET_ROLE, _asset), "IndexAssetRegistry: NOT_FOUND");

        totalMarketCap = totalMarketCap - marketCapOf[_asset] + _marketCap;
        marketCapOf[_asset] = _marketCap;
    }

    uint256[43] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./libraries/BP.sol";
import "./libraries/IndexLibrary.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IIndexLogic.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IPhuturePriceOracle.sol";

import "./PhutureIndex.sol";

/// @title Index logic
/// @notice Contains common logic for index minting and burning
contract IndexLogic is PhutureIndex, IIndexLogic {
    using FullMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Asset role
    bytes32 internal immutable ASSET_ROLE;
    /// @notice Role granted for asset which should be skipped during burning
    bytes32 internal immutable SKIPPED_ASSET_ROLE;

    constructor() {
        ASSET_ROLE = keccak256("ASSET_ROLE");
        SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    }

    /// @notice Mints index to `_recipient` address
    /// @param _recipient Recipient address
    function mint(address _recipient) external override {
        address feePool = IIndexRegistry(registry).feePool();
        _chargeAUMFee(feePool);

        IPhuturePriceOracle oracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());

        uint lastAssetBalanceInBase;
        uint minAmountInBase = type(uint).max;

        uint assetsCount = assets.length();
        for (uint i; i < assetsCount; ) {
            address asset = assets.at(i);
            require(IAccessControl(registry).hasRole(ASSET_ROLE, asset), "Index: INVALID_ASSET");

            uint8 weight = weightOf[asset];
            if (weight != 0) {
                // amount of asset tokens for one base(stablecoins --> USDC, DAI, etc.) token
                uint assetPerBaseInUQ = oracle.refreshedAssetPerBaseInUQ(asset);
                IvToken vToken = IvToken(IvTokenFactory(vTokenFactory).createdVTokenOf(asset));
                // amount of asset transferred to the vToken prior to executing the mint function
                uint amountInAsset = vToken.totalAssetSupply() - vToken.lastAssetBalance();
                // Q_b * w_i * p_i = Q_i
                // Q_b = Q_i / (w_i * p_i)
                // index worth in base denominated in the amount of asset transferred in relation to its weight
                uint _minAmountInBase = amountInAsset.mulDiv(
                    FixedPoint112.Q112 * IndexLibrary.MAX_WEIGHT,
                    assetPerBaseInUQ * weight
                );
                // all of the assets should be transferred in exact amounts in terms of their base value
                // according to the predefined index weights
                if (_minAmountInBase < minAmountInBase) {
                    minAmountInBase = _minAmountInBase;
                }
                // balance of asset inside vToken in index's ownership
                uint lastBalanceInAsset = vToken.lastAssetBalanceOf(address(this));
                // mints the vToken shares for the asset transferred
                vToken.mint();
                // sum of values of all the assets in index's ownership in base
                lastAssetBalanceInBase += lastBalanceInAsset.mulDiv(FixedPoint112.Q112, assetPerBaseInUQ);
            }

            unchecked {
                i = i + 1;
            }
        }

        uint inactiveAssetsCount = inactiveAssets.length();
        for (uint i; i < inactiveAssetsCount; ) {
            address inactiveAsset = inactiveAssets.at(i);
            if (!IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, inactiveAsset)) {
                // adds the sum of all assets which were remove from the index during a reweigh to the total worth of index in base
                lastAssetBalanceInBase += IvToken(IvTokenFactory(vTokenFactory).createdVTokenOf(inactiveAsset))
                    .lastAssetBalanceOf(address(this))
                    .mulDiv(FixedPoint112.Q112, oracle.refreshedAssetPerBaseInUQ(inactiveAsset));
            }

            unchecked {
                i = i + 1;
            }
        }

        assert(minAmountInBase != type(uint).max);

        uint value;

        // total supply of the index
        uint totalSupply = totalSupply();
        // checks if this is the initial mint event
        if (totalSupply != 0) {
            require(lastAssetBalanceInBase != 0, "Index: INSUFFICIENT_AMOUNT");

            // amount of index to mint
            value =
                (oracle.convertToIndex(minAmountInBase, decimals()) * totalSupply) /
                oracle.convertToIndex(lastAssetBalanceInBase, decimals());
        } else {
            // in case of the initial mint event, a small initial_quantity is sent to address zero.
            value = oracle.convertToIndex(minAmountInBase, decimals()) - IndexLibrary.INITIAL_QUANTITY;
            _mint(address(0xdead), IndexLibrary.INITIAL_QUANTITY);
        }
        // fee is subtracted from the total mint amount
        uint fee = (value * IFeePool(feePool).mintingFeeInBPOf(address(this))) / BP.DECIMAL_FACTOR;
        if (fee != 0) {
            _mint(feePool, fee);
            value -= fee;
        }

        _mint(_recipient, value);
    }

    /// @notice Burns index and transfers assets to `_recipient` address
    /// @param _recipient Recipient address
    function burn(address _recipient) external override {
        // amount of index tokens transferred to the index itself (meant to be redeemed for the underlying assets)
        uint value = balanceOf(address(this));
        require(value != 0, "Index: INSUFFICIENT_AMOUNT");

        bool containsBlacklistedAssets;
        // check if the index contains an asset which was blacklisted
        uint assetsCount = assets.length();
        for (uint i; i < assetsCount; ) {
            if (!IAccessControl(registry).hasRole(ASSET_ROLE, assets.at(i))) {
                containsBlacklistedAssets = true;
                break;
            }

            unchecked {
                i = i + 1;
            }
        }

        if (!containsBlacklistedAssets) {
            address feePool = IIndexRegistry(registry).feePool();

            uint fee = (value * IFeePool(feePool).burningFeeInBPOf(address(this))) / BP.DECIMAL_FACTOR;

            if (fee != 0) {
                // AUM charged in _transfer method
                _transfer(address(this), feePool, fee);
                value -= fee;
            } else {
                _chargeAUMFee(feePool);
            }
        }

        IOrderer orderer = IOrderer(IIndexRegistry(registry).orderer());
        uint lastOrderId = orderer.lastOrderIdOf(address(this));

        uint totalCount = inactiveAssets.length() + assetsCount;
        for (uint i; i < totalCount; ++i) {
            address asset = i < assetsCount ? assets.at(i) : inactiveAssets.at(i - assetsCount);

            if (containsBlacklistedAssets && IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, asset)) {
                continue;
            }

            IvToken vToken = IvToken(IvTokenFactory(vTokenFactory).vTokenOf(asset));
            // amount of shares in index's ownership
            uint indexBalance = vToken.balanceOf(address(this));

            uint totalSupply = totalSupply();
            // amount of each asset corresponding to the index amount to burn
            uint accountBalance = (value * indexBalance) / totalSupply;
            if (accountBalance != 0) {
                vToken.transfer(address(vToken), accountBalance);
                vToken.burn(_recipient);
                if (lastOrderId != 0) {
                    // checks that asset is active
                    if (i < assetsCount) {
                        orderer.reduceOrderAsset(asset, totalSupply - value, totalSupply);
                    } else {
                        orderer.updateOrderDetails(asset, indexBalance - accountBalance);
                    }
                }
            }
        }

        _burn(address(this), value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../PhutureIndex.sol";

contract IndexLogicV2Test is PhutureIndex {
    function mint(address _recipient) external {
        _mint(_recipient, 1);
    }

    function burn(address _recipient) external {
        _burn(_recipient, 1);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestERC20 is ERC20Permit {
    uint8 internal immutable decimals_;

    constructor(uint8 _decimals, uint _totalSupply) ERC20("Test", "TEST") ERC20Permit("Test") {
        _mint(msg.sender, _totalSupply);

        decimals_ = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20Test is ERC20Permit {
    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        address _totalSupplyRecipient,
        address _pairCreator,
        uint _pairCreatorAmount
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _mint(_totalSupplyRecipient, _totalSupply - _pairCreatorAmount);
        _mint(_pairCreator, _pairCreatorAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../libraries/FullMath.sol";

import "../interfaces/IPhuturePriceOracle.sol";

contract Swap0xTargetMock {
    using SafeERC20 for IERC20;
    using FullMath for uint;

    IPhuturePriceOracle priceOracle;

    constructor(address _priceOracle) {
        priceOracle = IPhuturePriceOracle(_priceOracle);
    }

    function swapExact(
        address inputAsset,
        address outputAsset,
        uint inputAmount
    ) external {
        IERC20(inputAsset).safeTransferFrom(msg.sender, address(this), inputAmount);
        uint outputAmount = inputAmount.mulDiv(
            priceOracle.refreshedAssetPerBaseInUQ(outputAsset),
            priceOracle.refreshedAssetPerBaseInUQ(inputAsset)
        );
        require(
            IERC20(outputAsset).balanceOf(address(this)) >= outputAmount,
            string.concat("Swap0xTargetMock: BALANCE ", Strings.toHexString(uint160(outputAsset), 20))
        );
        IERC20(outputAsset).safeTransfer(msg.sender, outputAmount);
    }

    function swapExactAmount(
        address inputAsset,
        address outputAsset,
        uint inputAmount
    ) external returns (uint) {
        return
            inputAmount.mulDiv(
                priceOracle.refreshedAssetPerBaseInUQ(outputAsset),
                priceOracle.refreshedAssetPerBaseInUQ(inputAsset)
            );
    }

    function swap(
        address inputAsset,
        address outputAsset,
        uint inputAmount,
        uint outputAmount
    ) external {
        IERC20(inputAsset).safeTransferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputAsset).safeTransfer(msg.sender, outputAmount);
    }

    function swapFails() external {
        revert("FAILED");
    }

    function emptyRevert() external {
        revert();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IUniswapPathPriceOracle.sol";

/// @title Uniswap path price oracle
/// @notice Contains logic for price calculation of asset which doesn't have a pair with a base asset
contract UniswapPathPriceOracle is IUniswapPathPriceOracle, ERC165 {
    using FullMath for uint;

    /// @notice List of assets to compose exchange pairs, where first element is input asset
    address[] internal path;
    /// @notice List of corresponding price oracles for provided path
    address[] internal oracles;

    constructor(address[] memory _path, address[] memory _oracles) {
        uint pathsCount = _path.length;
        require(pathsCount >= 2, "UniswapPathPriceOracle: PATH");
        require(_oracles.length == pathsCount - 1, "UniswapPathPriceOracle: ORACLES");

        path = _path;
        oracles = _oracles;
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint currentAssetPerBaseInUQ) {
        require(_asset == path[path.length - 1], "UniswapPathPriceOracle: INVALID");

        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).refreshedAssetPerBaseInUQ(path[i + 1]),
                FixedPoint112.Q112
            );

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IUniswapPathPriceOracle
    function anatomy() external view override returns (address[] memory _path, address[] memory _oracles) {
        _path = path;
        _oracles = oracles;
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint currentAssetPerBaseInUQ) {
        require(_asset == path[path.length - 1], "UniswapPathPriceOracle: INVALID");

        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).lastAssetPerBaseInUQ(path[i + 1]),
                FixedPoint112.Q112
            );

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapPathPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap path price oracle interface
/// @notice Contains logic for price calculation of asset which doesn't have a pair with a base asset
interface IUniswapPathPriceOracle is IPriceOracle {
    /// @notice Returns anatomy data for the current oracle
    /// @return _path List of assets to compose exchange pairs
    /// @return _oracles List of corresponding price oracles for pairs provided by {_path}
    function anatomy() external view returns (address[] calldata _path, address[] calldata _oracles);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./libraries/FixedPoint112.sol";
import "./libraries/FullMath.sol";

import "./interfaces/IIndexHelper.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IvToken.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPriceOracle.sol";

contract IndexHelper is IIndexHelper {
    using FullMath for uint;

    /// @inheritdoc IIndexHelper
    function totalEvaluation(address _index)
        external
        view
        override
        returns (uint _totalEvaluation, uint _indexPriceInBase)
    {
        IIndex index = IIndex(_index);
        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IIndexRegistry registry = IIndexRegistry(index.registry());
        IPriceOracle priceOracle = IPriceOracle(registry.priceOracle());

        (address[] memory assets, ) = index.anatomy();
        address[] memory inactiveAssets = index.inactiveAnatomy();

        for (uint i; i < assets.length + inactiveAssets.length; ++i) {
            address asset = i < assets.length ? assets[i] : inactiveAssets[i - assets.length];
            uint assetValue = IvToken(vTokenFactory.vTokenOf(asset)).assetBalanceOf(_index);
            _totalEvaluation += assetValue.mulDiv(FixedPoint112.Q112, priceOracle.lastAssetPerBaseInUQ(asset));
        }

        _indexPriceInBase = _totalEvaluation.mulDiv(
            10**IERC20Metadata(_index).decimals(),
            IERC20(_index).totalSupply()
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index hepler interface
/// @notice Interface containing index utils methods
interface IIndexHelper {
    /// @notice Returns index related info
    /// @param _index Address of index
    /// @return _valueInBase Index's evaluation in base asset
    /// @return _totalSupply Index's total supply
    function totalEvaluation(address _index) external view returns (uint _valueInBase, uint _totalSupply);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IChainlinkPriceOracle.sol";

/// @title Chainlink price oracle
/// @notice Contains logic for getting asset's price from Chainlink data feed
/// @dev Oracle works through base asset which is set in initialize function
contract ChainlinkPriceOracle is IChainlinkPriceOracle, ERC165 {
    using FullMath for uint;
    using ERC165Checker for address;

    struct AssetInfo {
        address[] aggregators;
        uint8 decimals;
    }

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Infos of added assets
    mapping(address => AssetInfo) internal assetInfoOf;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    /// @notice Chainlink aggregator for the base asset
    AggregatorV2V3Interface internal immutable baseAggregator;

    /// @notice Number of decimals in base asset
    uint8 internal immutable baseDecimals;

    /// @notice Number of decimals in base asset answer
    uint8 internal immutable baseAnswerDecimals;

    /// @notice Number of decimals in answer of aggregator
    mapping(address => uint) internal answerDecimals;

    /// @inheritdoc IChainlinkPriceOracle
    uint public maxUpdateInterval;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(registry.hasRole(_role, msg.sender), "ChainlinkPriceOracle: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address _base,
        address _baseAggregator,
        uint _maxUpdateInterval
    ) {
        require(_base != address(0) && _baseAggregator != address(0), "ChainlinkPriceOracle: ZERO");
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "ChainlinkPriceOracle: INTERFACE");

        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

        registry = IAccessControl(_registry);
        baseAnswerDecimals = AggregatorV2V3Interface(_baseAggregator).decimals();
        baseDecimals = IERC20Metadata(_base).decimals();
        baseAggregator = AggregatorV2V3Interface(_baseAggregator);
        maxUpdateInterval = _maxUpdateInterval;

        emit SetMaxUpdateInterval(msg.sender, _maxUpdateInterval);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function setMaxUpdateInterval(uint _maxUpdateInterval) external override onlyRole(ASSET_MANAGER_ROLE) {
        maxUpdateInterval = _maxUpdateInterval;
        emit SetMaxUpdateInterval(msg.sender, _maxUpdateInterval);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address _assetAggregator) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_asset != address(0), "ChainlinkPriceOracle: ZERO");

        address[] memory aggregators = new address[](1);
        aggregators[0] = _assetAggregator;

        assetInfoOf[_asset] = AssetInfo({ aggregators: aggregators, decimals: IERC20Metadata(_asset).decimals() });
        answerDecimals[_assetAggregator] = AggregatorV2V3Interface(_assetAggregator).decimals();

        emit AssetAdded(_asset, aggregators);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address[] memory _assetAggregators)
        external
        override
        onlyRole(ASSET_MANAGER_ROLE)
    {
        uint aggregatorsCount = _assetAggregators.length;
        require(_asset != address(0) && aggregatorsCount != 0, "ChainlinkPriceOracle: INVALID");

        assetInfoOf[_asset] = AssetInfo({
            aggregators: _assetAggregators,
            decimals: IERC20Metadata(_asset).decimals()
        });

        for (uint i; i < aggregatorsCount; ) {
            address aggregator = _assetAggregators[i];

            answerDecimals[aggregator] = AggregatorV2V3Interface(aggregator).decimals();

            unchecked {
                i = i + 1;
            }
        }

        emit AssetAdded(_asset, _assetAggregators);
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        return _assetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        return _assetPerBaseInUQ(_asset);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IChainlinkPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Returns asset price
    function _assetPerBaseInUQ(address _asset) internal view returns (uint) {
        AssetInfo storage assetInfo = assetInfoOf[_asset];

        uint basePrice = _getPrice(baseAggregator);

        uint assetPerBaseInUQ;

        uint aggregatorsCount = assetInfo.aggregators.length;
        for (uint i; i < aggregatorsCount; ) {
            address aggregator = assetInfo.aggregators[i];
            uint quotePrice = _getPrice(AggregatorV2V3Interface(aggregator));

            if (i == 0) {
                assetPerBaseInUQ =
                    ((10**assetInfo.decimals * basePrice).mulDiv(FixedPoint112.Q112, quotePrice * 10**baseDecimals) *
                        10**answerDecimals[aggregator]) /
                    10**baseAnswerDecimals;
            } else {
                assetPerBaseInUQ = (assetPerBaseInUQ / quotePrice) * 10**answerDecimals[aggregator];
            }

            unchecked {
                i = i + 1;
            }
        }

        return assetPerBaseInUQ;
    }

    /// @notice Returns price from chainlink
    function _getPrice(AggregatorV2V3Interface _aggregator) internal view returns (uint) {
        (uint80 roundID, int price, , uint updatedAt, uint80 answeredInRound) = _aggregator.latestRoundData();
        if (updatedAt == 0 || price < 1 || answeredInRound < roundID) {
            if (roundID != 0) {
                (roundID, price, , updatedAt, answeredInRound) = _aggregator.getRoundData(roundID - 1);
            }

            require(updatedAt != 0 && price > 0 && answeredInRound >= roundID, "ChainlinkPriceOracle: STALE");
        }
        require(maxUpdateInterval > block.timestamp - updatedAt, "ChainlinkPriceOracle: INTERVAL");

        return uint(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Chainlink price oracle interface
/// @notice Extends IPriceOracle interface
interface IChainlinkPriceOracle is IPriceOracle {
    event AssetAdded(address _asset, address[] _aggregators);
    event SetMaxUpdateInterval(address _account, uint _maxUpdateInterval);

    /// @notice Adds `_asset` to the oracle
    /// @param _asset Asset's address
    /// @param _assetAggregator Asset aggregator address
    function addAsset(address _asset, address _assetAggregator) external;

    /// @notice Adds `_asset` to the oracle
    /// @param _asset Asset's address
    /// @param _assetAggregators Asset aggregators addresses
    function addAsset(address _asset, address[] memory _assetAggregators) external;

    /// @notice Sets max update interval
    /// @param _maxUpdateInterval Max update interval
    function setMaxUpdateInterval(uint _maxUpdateInterval) external;

    /// @notice Max update interval
    /// @return Returns max update interval
    function maxUpdateInterval() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../libraries/IndexLibrary.sol";

contract TestIndexLibrary {
    function amountInAsset(
        uint _assetPerBaseInUQ,
        uint8 _weight,
        uint _amountInBase
    ) external pure returns (uint) {
        return IndexLibrary.amountInAsset(_assetPerBaseInUQ, _weight, _amountInBase);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./UniswapV2ERC20.sol";

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "UniswapV2: TRANSFER_FAILED");
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "UniswapV2: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        }
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * 5 + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external override lock {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * (1000**2), "UniswapV2: K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.7;

/// @title UQ library
/// @notice A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
/// @dev range: [0, 2**112 - 1]
/// @dev resolution: 1 / 2**112
library UQ112x112 {
    /// @notice Constant used to encode / decode a number to / from UQ format
    uint224 constant Q112 = 2**112;

    /// @notice Encodes a uint112 as a UQ112x112
    /// @param y Number to encode
    /// @return z UQ encoded value
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    /// @notice Divides a UQ112x112 by a uint112, returning a UQ112x112
    /// @param x Dividend value
    /// @param y Divisor value
    /// @return z Result of `x` divided by `y`
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.7;

/// @title Math library
/// @notice A library for performing various math operations
library Math {
    /// @notice Returns minimum number among two provided arguments
    /// @param x First argument to compare with the second one
    /// @param y Second argument to compare with the first one
    /// @return z Minimum value among `x` and `y`
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    /// @notice Calculates square root for the given argument
    /// @param y A number to calculate square root for
    /// @dev Uses Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    /// @return z Number `z` whose square is `y`
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    string public constant override name = "Uniswap V2";
    string public constant override symbol = "UNI-V2";
    uint8 public constant override decimals = 18;
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./uniswap-v2/interfaces/IUniswapV2Pair.sol";
import "./uniswap-v2/UniswapV2ERC20.sol";

contract TestUniswapV2Pair is UniswapV2ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 internal blockTimestampLast;

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor(
        address _token0,
        address _token1,
        uint112 _reserve0,
        uint112 _reserve1
    ) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    bytes32 public getCreationCode;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getCreationCode = keccak256(bytecode);
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../vToken.sol";

// We assume that in our mock VToken 1 share = 1 amount of asset
contract TestVToken is IvToken {
    address internal constant ZERO_ADDRESS = address(0);

    uint internal constant RETURN_VALUE = 10;

    mapping(address => mapping(uint => uint)) public assetDataForShares;

    function assetDataOf(address _account, uint _shares) external view override returns (AssetData memory) {
        return AssetData({ maxShares: _shares, amountInAsset: _shares });
    }

    function mintableShares(uint _amount) external view override returns (uint) {
        return _amount;
    }

    function assetBalanceForShares(uint _shares) external view returns (uint) {
        return _shares;
    }

    function initialize(address _asset, address _registry) external {}

    function setController(address _vaultController) external {}

    function deposit() external {}

    function withdraw() external {}

    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external {}

    function transferAsset(address _recipient, uint _amount) external {}

    function mint() external returns (uint shares) {
        shares = RETURN_VALUE;
    }

    function burn(address _recipient) external returns (uint amount) {
        return RETURN_VALUE;
    }

    function transfer(address _recipient, uint _amount) external {}

    function sync() external {}

    function mintFor(address _recipient) external returns (uint) {
        return RETURN_VALUE;
    }

    function burnFor(address _recipient) external returns (uint) {
        return RETURN_VALUE;
    }

    function virtualTotalAssetSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function totalAssetSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function deposited() external view returns (uint) {
        return RETURN_VALUE;
    }

    function assetBalanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function lastAssetBalanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function lastAssetBalance() external view returns (uint) {
        return RETURN_VALUE;
    }

    function totalSupply() external view returns (uint) {
        return RETURN_VALUE;
    }

    function balanceOf(address _account) external view returns (uint) {
        return RETURN_VALUE;
    }

    function shareChange(address _account, uint _amountInAsset) external view returns (uint newShares, uint oldShares) {
        newShares = RETURN_VALUE;
        oldShares = RETURN_VALUE;
    }

    function vaultController() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function asset() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function registry() external view returns (address) {
        return ZERO_ADDRESS;
    }

    function currentDepositedPercentageInBP() external view returns (uint) {
        return RETURN_VALUE;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../BaseIndexFactory.sol";

contract TestBaseIndexFactory is BaseIndexFactory {
    event TestIndexCreated(address index);

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
    {}

    function deployIndex(uint randomUint, bytes memory creationCode) external returns (address index) {
        bytes32 salt = keccak256(abi.encodePacked(randomUint));
        index = Create2.computeAddress(salt, keccak256(creationCode));
        Create2.deploy(0, salt, creationCode);
        emit TestIndexCreated(index);
    }

    function setReweightingLogic(address _reweightingLogic) external {}
}