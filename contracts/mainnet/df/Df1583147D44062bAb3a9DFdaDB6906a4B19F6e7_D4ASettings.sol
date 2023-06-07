// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/access/access_control/AccessControlStorage.sol";

import "./ID4ASettings.sol";
import "./D4ASettingsBaseStorage.sol";
import "./D4ASettingsReadable.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721Factory.sol";

contract D4ASettings is ID4ASettings, AccessControl, D4ASettingsReadable {
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    function initializeD4ASettings() public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(!l.initialized, "already initialized");
        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DAO_ROLE, OPERATION_ROLE);
        _setRoleAdmin(SIGNER_ROLE, OPERATION_ROLE);
        //some default value here
        l.ratio_base = 10000;
        l.create_project_fee = 0.1 ether;
        l.create_canvas_fee = 0.01 ether;
        l.mint_d4a_fee_ratio = 250;
        l.trade_d4a_fee_ratio = 250;
        l.mint_project_fee_ratio = 3000;
        l.mint_project_fee_ratio_flat_price = 3500;
        l.rf_lower_bound = 500;
        l.rf_upper_bound = 1000;

        l.project_erc20_ratio = 300;
        l.d4a_erc20_ratio = 200;
        l.canvas_erc20_ratio = 9500;
        l.project_max_rounds = 366;
        l.reserved_slots = 110;

        l.defaultNftPriceMultiplyFactor = 20_000;
        l.initialized = true;
    }

    event ChangeCreateFee(uint256 create_project_fee, uint256 create_canvas_fee);

    function changeCreateFee(uint256 _create_project_fee, uint256 _create_canvas_fee) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.create_project_fee = _create_project_fee;
        l.create_canvas_fee = _create_canvas_fee;
        emit ChangeCreateFee(_create_project_fee, _create_canvas_fee);
    }

    event ChangeProtocolFeePool(address addr);

    function changeProtocolFeePool(address addr) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.protocol_fee_pool = addr;
        emit ChangeProtocolFeePool(addr);
    }

    event ChangeMintFeeRatio(uint256 d4a_ratio, uint256 project_ratio, uint256 project_fee_ratio_flat_price);

    function changeMintFeeRatio(
        uint256 _d4a_fee_ratio,
        uint256 _project_fee_ratio,
        uint256 _project_fee_ratio_flat_price
    ) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.mint_d4a_fee_ratio = _d4a_fee_ratio;
        l.mint_project_fee_ratio = _project_fee_ratio;
        l.mint_project_fee_ratio_flat_price = _project_fee_ratio_flat_price;
        emit ChangeMintFeeRatio(_d4a_fee_ratio, _project_fee_ratio, _project_fee_ratio_flat_price);
    }

    event ChangeTradeFeeRatio(uint256 trade_d4a_fee_ratio);

    function changeTradeFeeRatio(uint256 _trade_d4a_fee_ratio) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.trade_d4a_fee_ratio = _trade_d4a_fee_ratio;
        emit ChangeTradeFeeRatio(_trade_d4a_fee_ratio);
    }

    event ChangeERC20TotalSupply(uint256 total_supply);

    function changeERC20TotalSupply(uint256 _total_supply) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.erc20_total_supply = _total_supply;
        emit ChangeERC20TotalSupply(_total_supply);
    }

    event ChangeERC20Ratio(uint256 d4a_ratio, uint256 project_ratio, uint256 canvas_ratio);

    function changeERC20Ratio(uint256 _d4a_ratio, uint256 _project_ratio, uint256 _canvas_ratio)
        public
        onlyRole(PROTOCOL_ROLE)
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.d4a_erc20_ratio = _d4a_ratio;
        l.project_erc20_ratio = _project_ratio;
        l.canvas_erc20_ratio = _canvas_ratio;
        require(_d4a_ratio + _project_ratio + _canvas_ratio == l.ratio_base, "invalid ratio");

        emit ChangeERC20Ratio(_d4a_ratio, _project_ratio, _canvas_ratio);
    }

    event ChangeMaxMintableRounds(uint256 old_rounds, uint256 new_rounds);

    function changeMaxMintableRounds(uint256 _rounds) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        emit ChangeMaxMintableRounds(l.project_max_rounds, _rounds);
        l.project_max_rounds = _rounds;
    }

    event ChangeAddress(
        address PRB,
        address erc20_factory,
        address erc721_factory,
        address feepool_factory,
        address owner_proxy,
        address project_proxy,
        address permission_control
    );

    function changeAddress(
        address _prb,
        address _erc20_factory,
        address _erc721_factory,
        address _feepool_factory,
        address _owner_proxy,
        address _project_proxy,
        address _permission_control
    ) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.drb = ID4ADrb(_prb);
        l.erc20_factory = ID4AERC20Factory(_erc20_factory);
        l.erc721_factory = ID4AERC721Factory(_erc721_factory);
        l.feepool_factory = ID4AFeePoolFactory(_feepool_factory);
        l.owner_proxy = ID4AOwnerProxy(_owner_proxy);
        l.project_proxy = _project_proxy;
        l.permission_control = IPermissionControl(_permission_control);
        emit ChangeAddress(
            _prb, _erc20_factory, _erc721_factory, _feepool_factory, _owner_proxy, _project_proxy, _permission_control
        );
    }

    event ChangeAssetPoolOwner(address new_owner);

    function changeAssetPoolOwner(address _owner) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.asset_pool_owner = _owner;
        emit ChangeAssetPoolOwner(_owner);
    }

    event ChangeFloorPrices(uint256[] prices);

    function changeFloorPrices(uint256[] memory _prices) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        delete l.floor_prices;
        l.floor_prices = _prices;
        emit ChangeFloorPrices(_prices);
    }

    event ChangeMaxNFTAmounts(uint256[] amounts);

    function changeMaxNFTAmounts(uint256[] memory _amounts) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        delete l.max_nft_amounts;
        l.max_nft_amounts = _amounts;
        emit ChangeMaxNFTAmounts(_amounts);
    }

    event ChangeD4APause(bool is_paused);

    function changeD4APause(bool is_paused) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.d4a_pause = is_paused;
        emit ChangeD4APause(is_paused);
    }

    event D4ASetProjectPaused(bytes32 project_id, bool is_paused);

    function setProjectPause(bytes32 obj_id, bool is_paused) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(
            (_hasRole(DAO_ROLE, msg.sender) && l.owner_proxy.ownerOf(obj_id) == msg.sender)
                || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pause_status[obj_id] = is_paused;
        emit D4ASetProjectPaused(obj_id, is_paused);
    }

    event D4ASetCanvasPaused(bytes32 canvas_id, bool is_paused);

    function setCanvasPause(bytes32 obj_id, bool is_paused) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        require(
            (
                _hasRole(DAO_ROLE, msg.sender)
                    && l.owner_proxy.ownerOf(ID4AProtocolForSetting(address(this)).getCanvasProject(obj_id)) == msg.sender
            ) || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pause_status[obj_id] = is_paused;
        emit D4ASetCanvasPaused(obj_id, is_paused);
    }

    event MembershipTransferred(bytes32 indexed role, address indexed previousMember, address indexed newMember);

    function transferMembership(bytes32 role, address previousMember, address newMember) public {
        require(!_hasRole(role, newMember), "new member already has the role");
        require(_hasRole(role, previousMember), "previous member does not have the role");
        require(newMember != address(0x0) && previousMember != address(0x0), "invalid address");
        _grantRole(role, newMember);
        _revokeRole(role, previousMember);

        emit MembershipTransferred(role, previousMember, newMember);
    }

    event DefaultNftPriceMultiplyFactorChanged(uint256 newDefaultNftPriceMultiplyFactor);

    function changeNftPriceMultiplyFactor(uint256 newDefaultNftPriceMultiplyFactor) public onlyRole(PROTOCOL_ROLE) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        l.defaultNftPriceMultiplyFactor = newDefaultNftPriceMultiplyFactor;
        emit DefaultNftPriceMultiplyFactorChanged(newDefaultNftPriceMultiplyFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ID4ASettings {
    function initializeD4ASettings() external;

    function changeCreateFee(uint256 _create_project_fee, uint256 _create_canvas_fee) external;

    function changeProtocolFeePool(address addr) external;

    function changeMintFeeRatio(
        uint256 _d4a_fee_ratio,
        uint256 _project_fee_ratio,
        uint256 _project_fee_ratio_flat_price
    ) external;

    function changeTradeFeeRatio(uint256 _trade_d4a_fee_ratio) external;

    function changeERC20TotalSupply(uint256 _total_supply) external;

    function changeERC20Ratio(uint256 _d4a_ratio, uint256 _project_ratio, uint256 _canvas_ratio) external;

    function changeMaxMintableRounds(uint256 _rounds) external;

    function changeAddress(
        address _prb,
        address _erc20_factory,
        address _erc721_factory,
        address _feepool_factory,
        address _owner_proxy,
        address _project_proxy,
        address _permission_control
    ) external;

    function changeAssetPoolOwner(address _owner) external;

    function changeFloorPrices(uint256[] memory _prices) external;

    function changeMaxNFTAmounts(uint256[] memory _amounts) external;

    function changeD4APause(bool is_paused) external;

    function setProjectPause(bytes32 obj_id, bool is_paused) external;

    function setCanvasPause(bytes32 obj_id, bool is_paused) external;

    function transferMembership(bytes32 role, address previousMember, address newMember) external;

    function changeNftPriceMultiplyFactor(uint256 newDefaultNftPriceMultiplyFactor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import {ID4ADrb} from "../interface/ID4ADrb.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721.sol";
import "../interface/ID4AERC721Factory.sol";
import "../interface/IPermissionControl.sol";

interface ID4AProtocolForSetting {
    function getCanvasProject(bytes32 _canvas_id) external view returns (bytes32);
}

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library D4ASettingsBaseStorage {
    struct Layout {
        uint256 ratio_base;
        uint256 min_stamp_duty; //TODO
        uint256 max_stamp_duty;
        uint256 create_project_fee;
        address protocol_fee_pool;
        uint256 create_canvas_fee;
        uint256 mint_d4a_fee_ratio;
        uint256 trade_d4a_fee_ratio;
        uint256 mint_project_fee_ratio;
        uint256 mint_project_fee_ratio_flat_price;
        uint256 erc20_total_supply;
        uint256 project_max_rounds; //366
        uint256 project_erc20_ratio;
        uint256 canvas_erc20_ratio;
        uint256 d4a_erc20_ratio;
        uint256 rf_lower_bound;
        uint256 rf_upper_bound;
        uint256[] floor_prices;
        uint256[] max_nft_amounts;
        ID4ADrb drb;
        string erc20_name_prefix;
        string erc20_symbol_prefix;
        ID4AERC721Factory erc721_factory;
        ID4AERC20Factory erc20_factory;
        ID4AFeePoolFactory feepool_factory;
        ID4AOwnerProxy owner_proxy;
        //ID4AProtocolForSetting protocol;
        IPermissionControl permission_control;
        address asset_pool_owner;
        bool d4a_pause;
        mapping(bytes32 => bool) pause_status;
        address project_proxy;
        uint256 reserved_slots;
        uint256 defaultNftPriceMultiplyFactor;
        bool initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4A.contracts.storage.Setting");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4ASettingsBaseStorage.sol";
import "./ID4ASettingsReadable.sol";

contract D4ASettingsReadable is ID4ASettingsReadable {
    function permissionControl() public view returns (IPermissionControl) {
        return D4ASettingsBaseStorage.layout().permission_control;
    }

    function ownerProxy() public view returns (ID4AOwnerProxy) {
        return D4ASettingsBaseStorage.layout().owner_proxy;
    }

    function mintProtocolFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_d4a_fee_ratio;
    }

    function protocolFeePool() public view returns (address) {
        return D4ASettingsBaseStorage.layout().protocol_fee_pool;
    }

    function tradeProtocolFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().trade_d4a_fee_ratio;
    }

    function mintProjectFeeRatio() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_project_fee_ratio;
    }

    function mintProjectFeeRatioFlatPrice() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().mint_project_fee_ratio_flat_price;
    }

    function ratioBase() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().ratio_base;
    }

    function createProjectFee() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().create_project_fee;
    }

    function createCanvasFee() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().create_canvas_fee;
    }

    function defaultNftPriceMultiplyFactor() public view returns (uint256) {
        return D4ASettingsBaseStorage.layout().defaultNftPriceMultiplyFactor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AFeePoolFactory {
    function createD4AFeePool(string memory _name) external returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory {
    function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AOwnerProxy {
    function ownerOf(bytes32 hash) external view returns (address);
    function initOwnerOf(bytes32 hash, address addr) external returns (bool);
    function transferOwnership(bytes32 hash, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory {
    function createD4AERC721(string memory _name, string memory _symbol) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ID4ADrb {
    event CheckpointSet(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbX18);

    function getCheckpointsLength() external view returns (uint256);

    function getStartBlock(uint256 drb) external view returns (uint256);

    function getDrb(uint256 blockNumber) external view returns (uint256);

    function currentRound() external view returns (uint256);

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721 {
    function mintItem(address player, string memory tokenURI) external returns (uint256);

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ID4AOwnerProxy.sol";

interface IPermissionControl {
    struct Blacklist {
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
    }

    struct Whitelist {
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
    }

    event MinterBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorBlacklisted(bytes32 indexed daoId, address indexed account);

    event MinterUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event WhitelistModified(bytes32 indexed daoId, Whitelist whitelist);

    function getWhitelist(bytes32 daoId) external view returns (Whitelist calldata whitelist);

    function addPermissionWithSignature(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        bytes calldata signature
    ) external;

    function addPermission(bytes32 daoId, Whitelist calldata whitelist, Blacklist calldata blacklist) external;

    function modifyPermission(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        Blacklist calldata unblacklist
    ) external;

    function isMinterBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function isCanvasCreatorBlacklisted(bytes32 daoId, address _account) external view returns (bool);

    function inMinterWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function inCanvasCreatorWhitelist(bytes32 daoId, address _account, bytes32[] calldata _proof)
        external
        view
        returns (bool);

    function setOwnerProxy(ID4AOwnerProxy _ownerProxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4ASettingsBaseStorage.sol";

interface ID4ASettingsReadable {
    function permissionControl() external view returns (IPermissionControl);

    function ownerProxy() external view returns (ID4AOwnerProxy);

    function mintProtocolFeeRatio() external view returns (uint256);

    function protocolFeePool() external view returns (address);

    function tradeProtocolFeeRatio() external view returns (uint256);

    function mintProjectFeeRatio() external view returns (uint256);

    function mintProjectFeeRatioFlatPrice() external view returns (uint256);

    function ratioBase() external view returns (uint256);

    function createProjectFee() external view returns (uint256);

    function createCanvasFee() external view returns (uint256);

    function defaultNftPriceMultiplyFactor() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}