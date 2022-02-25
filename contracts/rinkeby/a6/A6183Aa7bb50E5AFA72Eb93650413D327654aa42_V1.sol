// SPDX-License-Identifier: Apache-2.0

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

pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./interfaces/IPrice.sol";

contract PriceConsumerV3 is IPrice {
    AggregatorV3Interface internal priceFeed;

    string public name;

    constructor(address _aggregator, string memory _name) public {
        priceFeed = AggregatorV3Interface(_aggregator);
        name = _name;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() external view override returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IPrice {
    function getThePrice() external view returns (int256 price);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../oracle/interfaces/IPrice.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OracleRegistry is AccessControl {
    bytes32 public constant ORACLE_OPERATOR_ROLE =
        keccak256("ORACLE_OPERATOR_ROLE");
    event AggregatorAdded(address asset, address aggregator);
    mapping(address => address) public PriceFeeds;

    constructor() {
        _setupRole(ORACLE_OPERATOR_ROLE, _msgSender());
    }

    function _getPriceOf(address asset_) internal view returns (int256) {
        address aggregator = PriceFeeds[asset_];
        require(
            aggregator != address(0x0),
            "VAULT: Asset not registered"
        );
        int256 result = IPrice(aggregator).getThePrice();
        return result;
    }

    function addOracle(address asset_, address aggregator_) public {
        require(
            hasRole(ORACLE_OPERATOR_ROLE, msg.sender),
            "Meter: Caller is not an Oracle Operator"
        );
        PriceFeeds[asset_] = aggregator_;
        emit AggregatorAdded(asset_, aggregator_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../oracle/OracleRegistry.sol";
import "./Bond.sol";
import "./interfaces/IBondFactory.sol";
import "./interfaces/ISupplyFactory.sol";

contract BondManager is OracleRegistry, IBondManager {
    // CDP configs
    /// key: Collateral address and debt address, value: Liquidation Fee Ratio (LFR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => mapping (address => uint)) internal LFRConfig;
    /// key: Collateral address, value: Minimum Collateralization Ratio (MCR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => mapping (address => uint)) internal MCRConfig;
    /// key: Collateral address, value: Stability Fee Ratio (SFR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => mapping (address => uint)) internal SFRConfig; 
    /// key: Collateral address, value: whether collateral is allowed to borrow
    mapping (address => bool) internal IsOpen;
    /// key: supply token address, value: supply pool which stores debt
    mapping (address => address) internal SupplyPool;
    
    /// Address of Bond Factory
    address public override bondFactory;
    /// Address of Supply Factory
    address public override supplyFactory;
    /// Address of feeTo
    address public override feeTo;
    /// Address of Standard MTR fee pool
    address public override dividend;
    /// Address of Standard Treasury
    address public override treasury;

    constructor() {
        _setupRole(ORACLE_OPERATOR_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initializeCDP(address collateral_, address debt_, uint MCR_, uint LFR_, uint SFR_, bool on) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        LFRConfig[collateral_][debt_] = LFR_;
        MCRConfig[collateral_][debt_] = MCR_;
        SFRConfig[collateral_][debt_] = SFR_; 
        IsOpen[collateral_] = on;
        uint8 cDecimals = IERC20Minimal(collateral_).decimals();
        emit CDPInitialized(collateral_, MCR_, LFR_, SFR_, cDecimals);  
    }

    function setFees(address feeTo_, address dividend_, address treasury_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        feeTo = feeTo_;
        dividend = dividend_;
        treasury = treasury_;
        emit SetFees(feeTo_, dividend_, treasury_);
    }
    
    function initialize(address bondFactory_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        bondFactory = bondFactory_;
    }

    function createCDP(address collateral_, address debt_, uint cAmount_, uint dAmount_) external override returns (bool success) {
        // check if collateral is open
        require(IsOpen[collateral_], "BondManager: NOT OPEN");
        // check position
        require(isValidCDP(collateral_, debt_, cAmount_, dAmount_)
        , "IP"); // Invalid Position
        // create bond
        (address vlt, uint256 id) = IBondFactory(bondFactory).createBond(collateral_, debt_, dAmount_, _msgSender());
        require(vlt != address(0), "BondManager: FE"); // Factory error
        // transfer collateral to the bond, manage collateral from there
        TransferHelper.safeTransferFrom(collateral_, _msgSender(), vlt, cAmount_);
        // send debt to the borrower
        ISupplyPool(debt_).sendDebt(_msgSender(), dAmount_);
        emit BondCreated(id, collateral_, debt_, msg.sender, vlt, cAmount_, dAmount_);
        return true;
    }

    function createCDPNative(address debt_, uint dAmount_) payable public returns(bool success) {
        address WETH = IBondFactory(bondFactory).WETH();
        // check if collateral is open
        require(IsOpen[WETH], "BondManager: NOT OPEN");
        // check position
        require(isValidCDP(WETH, debt_, msg.value, dAmount_)
        , "IP"); // Invalid Position
        // create bond
        (address vlt, uint256 id) = IBondFactory(bondFactory).createBond(WETH, debt_, dAmount_, _msgSender());
        require(vlt != address(0), "BondManager: FE"); // Factory error
        // wrap native currency
        IWETH(WETH).deposit{value: address(this).balance}();
        uint256 weth = IERC20Minimal(WETH).balanceOf(address(this));
        // then transfer collateral native currency to the bond, manage collateral from there.
        require(IWETH(WETH).transfer(vlt, weth)); 
        // send debt to the sender
        ISupplyPool(debt_).sendDebt(_msgSender(), dAmount_);
        emit BondCreated(id, WETH, debt_, msg.sender, vlt, msg.value, dAmount_);
        return true;
    }

    function createSupply(address debt_) public {
        (address supply, uint256 supplyId) = ISupplyFactory(supplyFactory).createSupply(debt_);
        SupplyPool[debt_] = supply;
        emit SupplyCreated(debt_, supply);
    }
    
    function getCDPConfig(address collateral_, address debt_) external view override returns (uint MCR, uint LFR, uint SFR, uint cDecimals, bool isOpen) {
        uint8 cDecimals = IERC20Minimal(collateral_).decimals();
        return (MCRConfig[collateral_][debt_], LFRConfig[collateral_][debt_], SFRConfig[collateral_][debt_], cDecimals, IsOpen[collateral_]);
    }

    function getMCR(address collateral_, address debt_) public view override returns (uint) {
        return MCRConfig[collateral_][debt_];
    }

    function getLFR(address collateral_, address debt_) external view override returns (uint) {
        return LFRConfig[collateral_][debt_];
    }

    function getSFR(address collateral_, address debt_) public view override returns (uint) {
        return SFRConfig[collateral_][debt_];
    } 

    function getOpen(address collateral_, address debt_) public view override returns (bool) {
        return IsOpen[collateral_];
    }

    function getSupplyPool(address debt_) public view override returns (address) {
        return SupplyPool[debt_];
    } 
    

    function isValidCDP(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) public view override returns (bool) {
        (uint256 collateralValueTimes100Point00000, uint256 debtValue) = _calculateValues(collateral_, debt_, cAmount_, dAmount_);

        uint mcr = getMCR(collateral_, debt_);
        uint cDecimals = IERC20Minimal(collateral_).decimals();

        uint256 debtValueAdjusted = debtValue / (10 ** cDecimals);

        // if the debt become obsolete
        return debtValueAdjusted == 0 ? true : collateralValueTimes100Point00000 / debtValueAdjusted >= mcr;
    }

    function _calculateValues(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) internal view returns (uint256, uint256) {
        uint256 collateralValue = getAssetValue(collateral_, cAmount_);
        uint256 debtValue = getAssetValue(debt_, dAmount_);
        uint256 collateralValueTimes100Point00000 = collateralValue * 10000000;
        require(collateralValueTimes100Point00000 >= collateralValue); // overflow check
        return (collateralValueTimes100Point00000, debtValue);        
    }

    function getAssetPrice(address asset_) public view override returns (uint) {
        address aggregator = PriceFeeds[asset_];
        require(
            aggregator != address(0x0),
            "VAULT: Asset not registered"
        );
        int256 result = IPrice(aggregator).getThePrice();
        return uint(result);
    }

    function getAssetValue(address asset_, uint256 amount_) public view override returns (uint256) {
        uint price = getAssetPrice(asset_);
        uint256 value = price * amount_;
        require(value >= amount_); // overflow
        return value;
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IBond.sol";
import "./interfaces/IBondManager.sol";
import "./interfaces/IERC721Minimal.sol";
import "./interfaces/IB1.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2FactoryMinimal.sol";
import "./interfaces/ISupplyPool.sol";

contract Bond is IBond {
  /// Uniswap v2 factory interface
  address public override v2Factory;
  /// Address of a manager
  address public override manager;
  /// Address of a factory
  address public override factory;
  /// Address of debt;
  address public override debt;
  /// Address of bond ownership registry
  address public override b1;
  /// Address of a collateral
  address public override collateral;
  /// Bond global identifier
  uint256 public override bondId;
  /// Borrowed amount
  uint256 public override borrow;
  /// Created block timestamp
  uint256 public override createdAt;
  /// Address of wrapped eth
  address public override WETH;

  constructor() public {
    factory = msg.sender;
    createdAt = block.timestamp;
  }

  modifier onlyBondOwner() {
    require(
      IERC721Minimal(b1).ownerOf(bondId) == msg.sender,
      "Bond: Bond is not owned by you"
    );
    _;
  }

  // called once by the factory at time of deployment
  function initialize(
    address manager_,
    uint256 bondId_,
    address collateral_,
    address debt_,
    address b1_,
    uint256 amount_,
    address v2Factory_,
    address weth_
  ) external {
    require(msg.sender == factory, "Bond: FORBIDDEN"); // sufficient check
    bondId = bondId_;
    collateral = collateral_;
    debt = debt_;
    b1 = b1_;
    borrow = amount_;
    v2Factory = v2Factory_;
    WETH = weth_;
    manager = manager_;
  }

  function getStatus()
    external
    view
    override
    returns (
      address collateral,
      uint256 cBalance,
      address debt,
      uint256 dBalance
    )
  {
    return (
      collateral,
      IERC20Minimal(collateral).balanceOf(address(this)),
      debt,
      IERC20Minimal(debt).balanceOf(address(this))
    );
  }

  function liquidate() external override {
    require(
      !IBondManager(manager).isValidCDP(
        collateral,
        debt,
        IERC20Minimal(collateral).balanceOf(address(this)),
        IERC20Minimal(debt).balanceOf(address(this))
      ),
      "Bond: Position is still safe"
    );
    // check the pair if it exists
    address pair = IUniswapV2FactoryMinimal(v2Factory).getPair(
      collateral,
      debt
    );
    require(pair != address(0), "Bond: Liquidating pair not supported");
    uint256 balance = IERC20Minimal(collateral).balanceOf(address(this));
    uint256 lfr = IBondManager(manager).getLFR(collateral, debt);
    uint256 liquidationFee = (lfr * balance) / 100;
    uint256 left = _sendFee(collateral, balance, liquidationFee);
    // Distribute collaterals to supply pool
    address supplyPool = IBondManager(manager).getSupplyPool(collateral);
    TransferHelper.safeTransfer(collateral, supplyPool, left);
    // burn bond nft
    _burnV1FromBond();
    emit Liquidated(bondId, collateral, balance);
    // self destruct the contract, send remaining balance if collateral is native currency
    selfdestruct(payable(msg.sender));
  }

  function depositCollateralNative() external payable override onlyBondOwner {
    require(collateral == WETH, "Bond: collateral is not a native asset");
    // wrap deposit
    IWETH(WETH).deposit{ value: msg.value }();
    emit DepositCollateral(bondId, msg.value);
  }

  function depositCollateral(uint256 amount_) external override onlyBondOwner {
    TransferHelper.safeTransferFrom(
      collateral,
      msg.sender,
      address(this),
      amount_
    );
    emit DepositCollateral(bondId, amount_);
  }

  /// Withdraw collateral as native currency
  function withdrawCollateralNative(uint256 amount_)
    external
    payable
    override
    onlyBondOwner
  {
    require(collateral == WETH, "Bond: collateral is not a native asset");
    if (borrow != 0) {
      require(
        IBondManager(manager).isValidCDP(
          collateral,
          debt,
          IERC20Minimal(collateral).balanceOf(address(this)) - amount_,
          borrow
        ),
        "Bond: below MCR"
      );
    }
    // unwrap collateral
    IWETH(WETH).withdraw(amount_);
    // send withdrawn native currency
    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    emit WithdrawCollateral(bondId, amount_);
  }

  function withdrawCollateral(uint256 amount_)
    external
    override
    onlyBondOwner
  {
    require(
      IERC20Minimal(collateral).balanceOf(address(this)) >= amount_,
      "Bond: Not enough collateral"
    );
    if (borrow != 0) {
      uint256 test = IERC20Minimal(collateral).balanceOf(address(this)) - amount_;
      require(
        IBondManager(manager).isValidCDP(collateral,debt,test,borrow) == true,
        "Bond: below MCR"
      );
      
    }
    TransferHelper.safeTransfer(collateral, msg.sender, amount_);
    emit WithdrawCollateral(bondId, amount_);
  }

  function borrowMore(
    uint256 cAmount_,
    uint256 dAmount_
  ) external override onlyBondOwner {
    // get bond balance
    uint256 deposits = IERC20Minimal(collateral).balanceOf(address(this));
    // check position
    require(IBondManager(manager).isValidCDP(collateral, debt, cAmount_+ deposits, dAmount_), "IP"); // Invalid Position
    // transfer collateral to the bond, manage collateral from there
    TransferHelper.safeTransferFrom(collateral, msg.sender, address(this), cAmount_);
    // send debt to sender
    address supplyPool = IBondManager(manager).getSupplyPool(debt);
    ISupplyPool(supplyPool).sendDebtFromBond(factory, bondId, msg.sender, dAmount_);
  }

  function borrowMoreNative(
    uint256 dAmount_
  ) external payable onlyBondOwner {
    // get bond balance
    uint256 deposits = IERC20Minimal(WETH).balanceOf(address(this));
    // check position
    require(IBondManager(manager).isValidCDP(collateral, debt, msg.value + deposits, dAmount_), "IP"); // Invalid Position
    // wrap native currency
    IWETH(WETH).deposit{value: address(this).balance}();
    // send debt to sender
    address supplyPool = IBondManager(manager).getSupplyPool(debt);
    ISupplyPool(supplyPool).sendDebtFromBond(factory, bondId, msg.sender, dAmount_);
  }

  function payDebt(uint256 amount_) external override onlyBondOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    require(amount_ != 0, "Bond: amount is zero");
    // send MTR to the bond
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    uint256 left = _sendFee(debt, amount_, fee);
    _sendBackDebtToSupply(left);
    borrow -= left;
    emit PayBack(bondId, borrow, fee, amount_);
  }

  function closeBond(uint256 amount_) external override onlyBondOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    require(fee + borrow == amount_, "Bond: not enough balance to payback");
    // send MTR to the bond
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    // send fee to the pool
    uint256 left = _sendFee(debt, amount_, fee);
    // send debt to supply pool with interest
    _sendBackDebtToSupply(left);
    // burn bond nft
    _burnV1FromBond();
    emit CloseBond(bondId, amount_, fee);
    // self destruct the contract, send remaining balance if collateral is native currency
    selfdestruct(payable(msg.sender));
  }

  function _burnV1FromBond() internal {
    IB1(b1).burnFromBond(bondId);
  }

  function _sendBackDebtToSupply(uint256 amount_) internal {
    address supplyPool = IBondManager(manager).getSupplyPool(debt);
    TransferHelper.safeTransfer(debt, supplyPool, amount_);
  }

  function _calculateFee() internal returns (uint256) {
    uint256 assetValue = IBondManager(manager).getAssetValue(debt, borrow);
    uint256 sfr = IBondManager(manager).getSFR(collateral, debt);
    /// (sfr * assetValue/100) * (duration in months)
    uint256 sfrTimesV = sfr * assetValue;
    // get duration in months
    uint256 duration = (block.timestamp - createdAt) / 60 / 60 / 24 / 30;
    require(sfrTimesV >= assetValue); // overflow check
    return (sfrTimesV / 100) * duration;
  }

  function getDebt() external override returns (uint256) {
    return _calculateFee() + borrow;
  }

  function _sendFee(
    address asset_,
    uint256 amount_,
    uint256 fee_
  ) internal returns (uint256 left) {
    address dividend = IBondManager(manager).dividend();
    address feeTo = IBondManager(manager).feeTo();
    address treasury = IBondManager(manager).treasury();
    bool feeOn = feeTo != address(0);
    bool treasuryOn = treasury != address(0);
    bool dividendOn = dividend != address(0);
    // send fee to the pool
    if (feeOn) {
      if (dividendOn) {
        uint256 half = fee_ / 2;
        TransferHelper.safeTransfer(asset_, dividend, half);
        TransferHelper.safeTransfer(asset_, feeTo, half);
      } else if (dividendOn && treasuryOn) {
        uint256 third = fee_ / 3;
        TransferHelper.safeTransfer(asset_, dividend, third);
        TransferHelper.safeTransfer(asset_, feeTo, third);
        TransferHelper.safeTransfer(asset_, treasury, third);
      } else {
        TransferHelper.safeTransfer(asset_, feeTo, fee_);
      }
    }
    return amount_ - fee_;
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IBondFactory {

    /// View funcs
    /// NFT token address
    function b1() external view returns (address);
    /// UniswapV2Factory address
    function v2Factory() external view returns (address);
    /// Address of wrapped eth
    function WETH() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);

    /// Getters
    /// Get Config of CDP
    function bondCodeHash() external pure returns (bytes32);
    function createBond(address collateral_, address debt_, uint256 amount_, address recipient) external returns (address bond, uint256 id);
    function getBond(uint bondId_) external view returns (address);

    /// Event
    event BondCreated(uint256 bondId, address collateral, address debt, address creator, address bond, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ISupplyFactory {
    function  manager() external view returns (address);
    function  factory() external view returns (address);
    function supplyCodeHash() external pure returns (bytes32);
    function createSupply(address debt_) external returns (address supply, uint256 id); 
    function getSupply(uint bondId_) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IERC20Minimal {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AF");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TFF");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "ETF");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IBond {
    event DepositCollateral(uint256 bondID, uint256 amount);
    event WithdrawCollateral(uint256 bondID, uint256 amount);
    event Borrow(uint256 bondID, uint256 amount);
    event PayBack(uint256 bondID, uint256 borrow, uint256 paybackFee, uint256 amount);
    event CloseBond(uint256 bondID, uint256 amount, uint256 closingFee);
    event Liquidated(uint256 bondID, address collateral, uint256 amount);
    /// Getters
    /// Address of a manager
    function  factory() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);
    /// Address of debt;
    function  debt() external view returns (address);
    /// Address of bond ownership registry
    function  b1() external view returns (address);
    /// address of a collateral
    function  collateral() external view returns (address);
    /// Bond global identifier
    function bondId() external view returns (uint);
    /// borrowed amount 
    function borrow() external view returns (uint256);
    /// created block timestamp
    function createdAt() external view returns (uint256);
    /// address of wrapped eth
    function  WETH() external view returns (address);
    /// Total debt amount with interest
    function getDebt() external returns (uint256);
    /// V2 factory address for liquidation
    function v2Factory() external view returns (address);
    /// Bond status
    function getStatus() external view returns (address collateral, uint256 cBalance, address debt, uint256 dBalance);

    /// Functions
    function liquidate() external;
    function depositCollateralNative() payable external;
    function depositCollateral(uint256 amount_) external;
    function withdrawCollateralNative(uint256 amount_) payable external;
    function withdrawCollateral(uint256 amount_) external;
    function borrowMore(uint256 cAmount_, uint256 dAmount_) external;
    function payDebt(uint256 amount_) external;
    function closeBond(uint256 amount_) external;

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IBondManager {

    /// View funcs
    /// BondFactory address
    function bondFactory() external view returns (address);
    /// SupplyFactory address
    function supplyFactory() external view returns (address);
    /// Address of feeTo
    function feeTo() external view returns (address);
    /// Address of the dividend pool
    function dividend() external view returns (address);
    /// Address of Standard treasury
    function treasury() external view returns (address);
    
    /// Getters
    /// Get Config of CDP
    function getCDPConfig(address collateral, address debt) external view returns (uint, uint, uint, uint, bool);
    function getMCR(address collateral, address debt) external view returns(uint);
    function getLFR(address collateral, address debt) external view returns(uint);
    function getSFR(address collateral, address debt) external view returns(uint);
    function getOpen(address collateral, address debt) external view returns (bool);
    function getSupplyPool(address debt_) external view returns (address);
    function getAssetPrice(address asset) external returns (uint);
    function getAssetValue(address asset, uint256 amount) external returns (uint256);
    function isValidCDP(address collateral, address debt, uint256 cAmount, uint256 dAmount) external returns (bool);
    function createCDP(address collateral_, address debt_, uint cAmount_, uint dAmount_) external returns (bool success);

    /// Event
    event BondCreated(uint256 bondId, address collateral, address debt, address creator, address bond, uint256 cAmount, uint256 dAmount);
    event SupplyCreated(address debt, address supplyPool);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0


pragma solidity ^0.8.0;

interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IB1 {
    function mint(address to, uint256 tokenId_) external;
    function burn(uint256 tokenId_) external;
    function burnFromBond(uint bondId_) external;
    function exists(uint256 tokenId_) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IUniswapV2FactoryMinimal {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface ISupplyPool {
    function sendDebt(address borrower_, uint256 amount_) external;
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function sendDebtFromBond(address factory, uint256 bondId_, address to_, uint256 amount_) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./SupplyPool.sol";
import "./interfaces/ISupplyFactory.sol";

contract SupplyFactory is AccessControl, ISupplyFactory {

    // Supplys
    address[] public allSupplies;
    /// Address of bond manager
    address public override manager;
    /// Address of bond factory;
    address public override factory;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// Supply cannot issue stablecoin, it just manages the position
    function createSupply(address debt_) external override returns (address supply, uint256 id) {
        uint256 gIndex = allSuppliesLength();
        bytes memory bytecode = type(SupplyPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(gIndex));
        assembly {
            supply := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SupplyPool(supply).initialize(debt_, manager, factory);
        allSupplies.push(supply);
        return (supply, gIndex);
    }
    

    function initialize(address manager_, address factory_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        manager = manager_;
        factory = factory_;
    }

    function getSupply(uint supplyId_) external view override returns (address) {
        return allSupplies[supplyId_];
    }


    function supplyCodeHash() external pure override returns (bytes32 supplyCode) {
        return keccak256(type(SupplyPool).creationCode);
    }

    function allSuppliesLength() public view returns (uint) {
        return allSupplies.length;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./libraries/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/ISupplyPool.sol";
import "./interfaces/IBondFactory.sol";

contract SupplyPool is AccessControl, ISupplyPool {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    address private manager; // bond manager address
    address private factory; // bond factory address
    address private input;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initialize(address input_, address manager_, address factory_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SupplyPool: Caller is not a minter");
        input = input_;
        manager = manager_;
        factory = factory_;
        string memory name_ = IERC20Minimal(input_).name();
        string memory symbol_ = IERC20Minimal(input_).symbol(); 
        string memory supplyName = string(abi.encodePacked("Standard", " ", "Supply", " ", name_));
        string memory supplySymbol = string(abi.encodePacked("ss",symbol_));
        name = supplyName;
        symbol = supplySymbol;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != 2**256 - 1) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function enter(uint256 _amount) public {
        uint256 totalSTND = IERC20Minimal(input).balanceOf(address(this));
        uint256 totalShares = totalSupply;
        if (totalShares == 0 || totalSTND == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalSTND);
            _mint(msg.sender, what);
        }
        TransferHelper.safeTransferFrom(input, msg.sender, address(this), _amount);
    }

    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply;
        uint256 what = _share.mul(IERC20Minimal(input).balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        TransferHelper.safeTransfer(input, msg.sender, what);
    }

    function sendDebt(address borrower_, uint256 amount_) public override {
        require(msg.sender == manager, "SupplyPool: Caller is not the manager");
        TransferHelper.safeTransfer(input, borrower_, amount_);
    }

    function sendDebtFromBond(address factory_, uint256 bondId_, address to_, uint256 amount_) external override {
        require(factory == factory_, "IA"); // confirm bond factory contract is the known factory contract from the system, this prevents hackers making fake contracts that has the same interface
        require(IBondFactory(factory).getBond(bondId_)  == _msgSender(), "Meter: Not from Vault");
        TransferHelper.safeTransfer(input, to_, amount_);
    }
}

// SPDX-License-Identifier: Apache-2.0

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Bond.sol";
import "./interfaces/IBondFactory.sol";

contract BondFactory is AccessControl, IBondFactory {

    // Bonds
    address[] public allBonds;
    /// Address of uniswapv2 factory
    address public override v2Factory;
    /// Address of cdp nft registry
    address public override b1;
    /// Address of Wrapped Ether
    address public override WETH;
    /// Address of manager
    address public override manager;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// Bond cannot issue stablecoin, it just manages the position
    function createBond(address collateral_, address debt_, uint256 amount_, address recipient) external override returns (address bond, uint256 id) {
        require(msg.sender == manager, "IA");
        uint256 gIndex = allBondsLength();
        IB1(b1).mint(recipient, gIndex);
        bytes memory bytecode = type(Bond).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(gIndex));
        assembly {
            bond := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Bond(bond).initialize(manager, gIndex, collateral_, debt_, b1, amount_, v2Factory, WETH);
        allBonds.push(bond);
        return (bond, gIndex);
    }

    function initialize(address b1_, address v2Factory_, address weth_, address manager_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        b1 = b1_;
        v2Factory = v2Factory_;
        WETH = weth_;
        manager = manager_;
    }

    function getBond(uint bondId_) external view override returns (address) {
        return allBonds[bondId_];
    }


    function bondCodeHash() external pure override returns (bytes32 bondCode) {
        return keccak256(type(Bond).creationCode);
    }

    function allBondsLength() public view returns (uint) {
        return allBonds.length;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0;

import "../interfaces/IB1.sol";
/*
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library NFTHelper {
    /// @notice Checks owner of the NFT
    /// @dev Calls owner on NFT contract, errors with NO if address is not owner
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function ownerOf(
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IV1.ownerOf.selector, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IBondFactory.sol";
import "./interfaces/IB1.sol";
import "./interfaces/IBond.sol";

contract B1 is ERC721Enumerable, AccessControl, IB1  {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // Bond factory address
    address public factory;
    // URIs for V1
    mapping (address => string) URIs;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setURI(address collateral_, string memory uri_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MTRV1: Caller is not a default admin");
        URIs[collateral_] = uri_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address vault = IBondFactory(factory).getBond(tokenId);
        address collateral = IBond(vault).collateral();
        string memory URI = URIs[collateral];
        if(bytes(URI).length == 0) {
            // return placeholder URL
            return URIs[address(0)];
        } else {
            return URI;
        }
    }

    constructor(address factory_)
    ERC721("StandardB1", "B1") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        factory = factory_;
    }
    
    function setFactory(address factory_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MTRV1: Caller is not a default admin");
        factory = factory_;
    }

    function mint(address to, uint256 tokenId_) external override {
        // Check that the calling account has the minter role
        require(_msgSender() == factory, "MTRV1: Caller is not factory");
        _mint(to, tokenId_);
    }

    function burn(uint256 tokenId_) external override {
        require(hasRole(BURNER_ROLE, _msgSender()), "MTRV1: must have burner role to burn");
        _burn(tokenId_);
    }

    function burnFromBond(uint vaultId_) external override {
        require(IBondFactory(factory).getBond(vaultId_)  == _msgSender(), "MTRV1: Caller is not vault");
        _burn(vaultId_);
    }

    function exists(uint256 tokenId_) external view override returns (bool) {
        return _exists(tokenId_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Vault.sol";
import "./libraries/MinimalProxy.sol";
import "./interfaces/IVaultFactory.sol";

contract VaultFactory is AccessControl, IVaultFactory {
  // Vaults
  address[] public allVaults;
  /// Address of uniswapv2 factory
  address public override v2Factory;
  /// Address of cdp nft registry
  address public override v1;
  /// Address of Wrapped Ether
  address public override WETH;
  /// Address of manager
  address public override manager;
  /// version number of impl
  uint32 version;
  /// address of vault impl
  address public impl;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _createImpl();
  }

  /// Vault can issue stablecoin, it just manages the position
  function createVault(
    address collateral_,
    address debt_,
    uint256 amount_,
    address recipient
  ) external override returns (address vault, uint256 id) {
    require(msg.sender == manager, "VaultFactory: IA");
    uint256 gIndex = allVaultsLength();
    IV1(v1).mint(recipient);
    address proxy = MinimalProxy._createClone(impl);
    IVault(proxy).initialize(
      manager,
      gIndex,
      collateral_,
      debt_,
      v1,
      amount_,
      v2Factory,
      WETH
    );
    allVaults.push(proxy);
    return (proxy, gIndex);
  }

  // Set immutable, consistent, one rule for vault implementation
  function _createImpl() internal {
    address addr;
    bytes memory bytecode = type(Vault).creationCode;
    bytes32 salt = keccak256(abi.encodePacked("vault", version));
    assembly {
      addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
    impl = addr;
  }

  function initialize(
    address v1_,
    address v2Factory_,
    address weth_,
    address manager_
  ) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
    v1 = v1_;
    v2Factory = v2Factory_;
    WETH = weth_;
    manager = manager_;
  } 

  function getVault(uint256 vaultId_) external view override returns (address) {
    return allVaults[vaultId_];
  }

  function vaultCodeHash() external pure override returns (bytes32 vaultCode) {
    return
      keccak256(hex"3d602d80600a3d3981f3");
  }

  function allVaultsLength() public view returns (uint256) {
    return allVaults.length;
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20Minimal.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FeeHelper.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IERC721Minimal.sol";
import "./interfaces/IV1.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2FactoryMinimal.sol";
import "./interfaces/IStablecoin.sol";
import "./libraries/Initializable.sol";

contract Vault is IVault, Initializable {
  /// Uniswap v2 factory interface
  address public override v2Factory;
  /// Address of a manager
  address public override manager;
  /// Address of a factory
  address public override factory;
  /// Address of debt;
  address public override debt;
  /// Address of vault ownership registry
  address public override v1;
  /// Address of a collateral
  address public override collateral;
  /// Vault global identifier
  uint256 public override vaultId;
  /// Borrowed amount
  uint256 public override borrow;
  /// Created block timestamp
  uint256 public override lastUpdated;
  /// Address of wrapped eth
  address public override WETH;
  /// Interest rate until expiary
  uint256 ex_sfr;

  modifier onlyVaultOwner() {
    require(
      IERC721Minimal(v1).ownerOf(vaultId) == msg.sender,
      "Vault: Vault is not owned by you"
    );
    _;
  }

  // called once by the factory at time of deployment
  function initialize(
    address manager_,
    uint256 vaultId_,
    address collateral_,
    address debt_,
    address v1_,
    uint256 amount_,
    address v2Factory_,
    address weth_
  ) external override initializer {
    vaultId = vaultId_;
    collateral = collateral_;
    debt = debt_;
    v1 = v1_;
    borrow = amount_;
    v2Factory = v2Factory_;
    WETH = weth_;
    manager = manager_;
    factory = msg.sender;
    lastUpdated = block.timestamp;
    ex_sfr = IVaultManager(manager).getSFR(collateral_);
  }

  function liquidate() external override {
    require(
      !IVaultManager(manager).isValidCDP(
        collateral,
        debt,
        IERC20Minimal(collateral).balanceOf(address(this)),
        borrow
      ),
      "Vault: Position is still safe"
    );
    uint256 balance = IERC20Minimal(collateral).balanceOf(address(this));
    uint256 lfr = IVaultManager(manager).getLFR(collateral);
    uint256 liquidationFee = (lfr * balance) / 10000000; // 100 in 5 decimal
    uint256 left = FeeHelper._sendFee(manager, collateral, balance, liquidationFee);
    // Distribute collaterals
    address liquidator = IVaultManager(manager).liquidator();
    if (liquidator == address(0)) {
      address pair = IUniswapV2FactoryMinimal(v2Factory).getPair(
        collateral,
        debt
      );
      require(pair != address(0), "Vault: Liquidating pair not supported");
      // Distribute collaterals
      TransferHelper.safeTransfer(
        collateral,
        pair,
        IERC20Minimal(collateral).balanceOf(address(this))
      );
    } else {
      TransferHelper.safeTransfer(collateral, liquidator, left);
    }
    // burn vault nft
    _burnV1FromVault();
    emit Liquidated(vaultId, collateral, balance, left);
    // self destruct the contract, send remaining balance if collateral is native currency
    selfdestruct(payable(msg.sender));
  }

  function depositCollateralNative() external payable override onlyVaultOwner {
    require(collateral == WETH, "Vault: collateral is not a native asset");
    // wrap deposit
    IWETH(WETH).deposit{ value: msg.value }();
    emit DepositCollateral(vaultId, msg.value);
  }

  function depositCollateral(uint256 amount_) external override onlyVaultOwner {
    TransferHelper.safeTransferFrom(
      collateral,
      msg.sender,
      address(this),
      amount_
    );
    emit DepositCollateral(vaultId, amount_);
  }

  /// Withdraw collateral as native currency
  function withdrawCollateralNative(uint256 amount_) external virtual override onlyVaultOwner {
    require(collateral == WETH, "Vault: collateral is not a native asset");
    if (borrow != 0) {
      uint256 result = IERC20Minimal(collateral).balanceOf(address(this)) -
        amount_;
      require(
        IVaultManager(manager).isValidCDP(collateral, debt, result, borrow),
        "Vault: below MCR"
      );
    }
    // unwrap collateral
    IWETH(WETH).withdraw(amount_);
    // send withdrawn native currency
    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    emit WithdrawCollateral(vaultId, amount_);
  }

  function withdrawCollateral(uint256 amount_)
    external
    override
    onlyVaultOwner
  {
    require(
      IERC20Minimal(collateral).balanceOf(address(this)) >= amount_,
      "Vault: Not enough collateral"
    );
    if (borrow != 0) {
      uint256 test = IERC20Minimal(collateral).balanceOf(address(this)) -
        amount_;
      require(
        IVaultManager(manager).isValidCDP(collateral, debt, test, borrow) ==
          true,
        "Vault: below MCR"
      );
    }
    TransferHelper.safeTransfer(collateral, msg.sender, amount_);
    emit WithdrawCollateral(vaultId, amount_);
  }

  function borrowMore(uint256 cAmount_, uint256 dAmount_)
    external
    override
    onlyVaultOwner
  {
    // get vault balance
    uint256 deposits = IERC20Minimal(collateral).balanceOf(address(this));
    // check position
    require(
      IVaultManager(manager).isValidCDP(
        collateral,
        debt,
        cAmount_ + deposits,
        borrow + dAmount_
      ),
      "IP"
    ); // Invalid Position
    // check rebased supply of stablecoin
    require(IVaultManager(manager).isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
    // transfer collateral to the vault, manage collateral from there
    TransferHelper.safeTransferFrom(
      collateral,
      msg.sender,
      address(this),
      cAmount_
    );
    // mint mtr to the sender
    IStablecoin(debt).mintFromVault(factory, vaultId, msg.sender, dAmount_);
    // set new borrow amount
    borrow += dAmount_;
    emit BorrowMore(vaultId, cAmount_, dAmount_, borrow);
  }

  function borrowMoreNative(uint256 dAmount_) external payable onlyVaultOwner {
    // get vault balance
    uint256 deposits = IERC20Minimal(WETH).balanceOf(address(this));
    // check position
    require(
      IVaultManager(manager).isValidCDP(
        collateral,
        debt,
        msg.value + deposits,
        borrow + dAmount_
      ),
      "IP"
    ); // Invalid Position
    // check rebased supply of stablecoin
    require(IVaultManager(manager).isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
    // wrap native currency
    IWETH(WETH).deposit{ value: address(this).balance }();
    // mint mtr to the sender
    IStablecoin(debt).mintFromVault(factory, vaultId, msg.sender, dAmount_);
    // set new borrow amount
    borrow += dAmount_;
    emit BorrowMore(vaultId, msg.value, dAmount_, borrow);
  }

  function payDebt(uint256 amount_) external override onlyVaultOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    require(amount_ != 0, "Vault: amount is zero");
    // send MTR to the vault
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    uint256 left = FeeHelper._sendFee(manager, debt, amount_, fee);
    _burnMTRFromVault(left);
    // set new borrow amount
    borrow -= left;
    // reset last updated timestamp
    lastUpdated = block.timestamp;
    emit PayBack(vaultId, borrow, fee, amount_);
  }

  function closeVault(uint256 amount_) external override onlyVaultOwner {
    // calculate debt with interest
    uint256 fee = _calculateFee();
    // send MTR to the vault
    TransferHelper.safeTransferFrom(debt, msg.sender, address(this), amount_);
    // Check the amount if it satisfies to close the vault, otherwise revert
    require(
      fee + borrow <= amount_ + IERC20Minimal(debt).balanceOf(address(this)),
      "Vault: not enough balance to payback"
    );
    // send fee to the pool
    uint256 left = FeeHelper._sendFee(manager, debt, amount_, fee);
    // burn mtr debt with interest
    _burnMTRFromVault(left);
    // burn vault nft
    _burnV1FromVault();
    // send remainder back to sender
    uint256 remainderD = IERC20Minimal(debt).balanceOf(address(this));
    uint256 remainderC = IERC20Minimal(collateral).balanceOf(address(this));
    TransferHelper.safeTransfer(debt, msg.sender, remainderD);
    TransferHelper.safeTransfer(collateral, msg.sender, remainderC);
    emit CloseVault(vaultId, amount_, remainderC, remainderD, fee);
    // self destruct the contract, send remaining balance if collateral is native currency
    selfdestruct(payable(msg.sender));
  }

  function _burnV1FromVault() internal {
    IV1(v1).burnFromVault(vaultId);
  }

  function _burnMTRFromVault(uint256 amount_) internal {
    IStablecoin(debt).burn(amount_);
  }

  function _calculateFee() internal view returns (uint256) {
    uint256 assetValue = IVaultManager(manager).getAssetValue(debt, borrow);
    uint256 expiary =  IVaultManager(manager).getExpiary(collateral);
    // Check if interest is retroactive or not
    uint256 sfr = block.timestamp > expiary ? IVaultManager(manager).getSFR(collateral) : ex_sfr;
    /// (duration in months with 18 precision) * (sfr * assetValue/100(with 5decimals)) 
    // get duration in months with decimal 
    uint256 duration = (block.timestamp - lastUpdated) * 1e18 / 2592000;
    // remove precision then apply sfr with decimals
    uint256 durationV = duration*assetValue / 1e18;
    // divide with decimals in price
    return durationV * sfr / 10000000;
  }

  function outstandingPayment() external view override returns (uint256) {
    return _calculateFee() + borrow;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }
}

// SPDX-License-Identifier: Apache-2.0

library MinimalProxy {
    function _createClone(address target) internal returns (address result) {
    // convert address to 20 bytes
    bytes20 targetBytes = bytes20(target);

    // actual code //
    // 3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3

    // creation code //
    // copy runtime code into memory and return it
    // 3d602d80600a3d3981f3

    // runtime code //
    // code to delegatecall to address
    // 363d3d373d3d3d363d73 address 5af43d82803e903d91602b57fd5bf3

    assembly {
      /*
            reads the 32 bytes of memory starting at pointer stored in 0x40

            In solidity, the 0x40 slot in memory is special: it contains the "free memory pointer"
            which points to the end of the currently allocated memory.
            */
      let clone := mload(0x40)
      // store 32 bytes to memory starting at "clone"
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )

      /*
              |              20 bytes                |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
                                                      ^
                                                      pointer
            */
      // store 32 bytes to memory starting at "clone" + 20 bytes
      // 0x14 = 20
      mstore(add(clone, 0x14), targetBytes)

      /*
              |               20 bytes               |                 20 bytes              |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe
                                                                                              ^
                                                                                              pointer
            */
      // store 32 bytes to memory starting at "clone" + 40 bytes
      // 0x28 = 40
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )

      /*
              |               20 bytes               |                 20 bytes              |           15 bytes          |
            0x3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3
            */
      // create new contract
      // send 0 Ether
      // code starts at pointer stored in "clone"
      // code size 0x37 (55 bytes)
      result := create(0, clone, 0x37)
    }
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVaultFactory {

    /// View funcs
    /// NFT token address
    function v1() external view returns (address);
    /// UniswapV2Factory address
    function v2Factory() external view returns (address);
    /// Address of wrapped eth
    function WETH() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);

    /// Getters
    /// Get Config of CDP
    function vaultCodeHash() external pure returns (bytes32);
    function createVault(address collateral_, address debt_, uint256 amount_, address recipient) external returns (address vault, uint256 id);
    function getVault(uint vaultId_) external view returns (address);

    /// Event
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, uint8 cDecimals);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IERC20Minimal {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AF");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TFF");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "ETF");
    }
}

// SPDX-License-Identifier: Apache-2.0

import "../interfaces/IVaultManager.sol";
import "./TransferHelper.sol";

library FeeHelper {
  function _sendFee(
    address manager,
    address asset_,
    uint256 amount_,
    uint256 fee_
  ) internal returns (uint256 left) {
    address dividend = IVaultManager(manager).dividend();
    address feeTo = IVaultManager(manager).feeTo();
    address treasury = IVaultManager(manager).treasury();
    bool feeOn = feeTo != address(0);
    bool treasuryOn = treasury != address(0);
    bool dividendOn = dividend != address(0);
    // send fee to the pool
    if (feeOn) {
      if (dividendOn) {
        uint256 half = fee_ / 2;
        TransferHelper.safeTransfer(asset_, dividend, half);
        TransferHelper.safeTransfer(asset_, feeTo, half);
      } else if (dividendOn && treasuryOn) {
        uint256 third = fee_ / 3;
        TransferHelper.safeTransfer(asset_, dividend, third);
        TransferHelper.safeTransfer(asset_, feeTo, third);
        TransferHelper.safeTransfer(asset_, treasury, third);
      } else {
        TransferHelper.safeTransfer(asset_, feeTo, fee_);
      }
    }
    return amount_ - fee_;
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVault {
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event Borrow(uint256 vaultID, uint256 amount);
    event BorrowMore(uint256 vaultID, uint256 cAmount, uint256 dAmount, uint256 borrow);
    event PayBack(uint256 vaultID, uint256 borrow, uint256 paybackFee, uint256 amount);
    event CloseVault(uint256 vaultID, uint256 amount, uint256 remainderC, uint256 remainderD, uint256 closingFee);
    event Liquidated(uint256 vaultID, address collateral, uint256 amount, uint256 pairSentAmount);
    /// Getters
    /// Address of a manager
    function  factory() external view returns (address);
    /// Address of a manager
    function  manager() external view returns (address);
    /// Address of debt;
    function  debt() external view returns (address);
    /// Address of vault ownership registry
    function  v1() external view returns (address);
    /// address of a collateral
    function  collateral() external view returns (address);
    /// Vault global identifier
    function vaultId() external view returns (uint);
    /// borrowed amount 
    function borrow() external view returns (uint256);
    /// created block timestamp
    function lastUpdated() external view returns (uint256);
    /// address of wrapped eth
    function  WETH() external view returns (address);
    /// Total debt amount with interest
    function outstandingPayment() external returns (uint256);
    /// V2 factory address for liquidation
    function v2Factory() external view returns (address);

    /// Functions
    function initialize(address manager_,
    uint256 vaultId_,
    address collateral_,
    address debt_,
    address v1_,
    uint256 amount_,
    address v2Factory_,
    address weth_
    ) external;
    function liquidate() external;
    function depositCollateralNative() payable external;
    function depositCollateral(uint256 amount_) external;
    function withdrawCollateralNative(uint256 amount_) external;
    function withdrawCollateral(uint256 amount_) external;
    function borrowMore(uint256 cAmount_, uint256 dAmount_) external;
    function payDebt(uint256 amount_) external;
    function closeVault(uint256 amount_) external;

}

// SPDX-License-Identifier: Apache-2.0


pragma solidity ^0.8.0;

interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IV1 {
    function mint(address to) external;
    function burn(uint256 tokenId_) external;
    function burnFromVault(uint vaultId_) external;
    function exists(uint256 tokenId_) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IUniswapV2FactoryMinimal {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IStablecoin {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mintFromVault(address factory, uint256 vaultId_, address to, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

contract Initializable {
    bool private _initialized = false;

    modifier initializer() {
        // solhint-disable-next-line reason-string
        require(!_initialized);
        _;
        _initialized = true;
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVaultManager {

    /// View funcs
    /// Last rebase
    function lastRebase() external view returns (uint256);
    /// Stablecoin address
    function stablecoin() external view returns (address);
    /// VaultFactory address
    function factory() external view returns (address);
    /// Address of feeTo
    function feeTo() external view returns (address);
    /// Address of the dividend pool
    function dividend() external view returns (address);
    /// Address of Standard treasury
    function treasury() external view returns (address);
    /// Address of liquidator
    function liquidator() external view returns (address);
    /// Desired of supply of stablecoin to be minted
    function desiredSupply() external view returns (uint256);
    /// Switch to on/off rebase
    function rebaseActive() external view returns (bool);

    /// Getters
    /// Get Config of CDP
    function getCDPConfig(address collateral) external view returns (uint, uint, uint, uint, bool);
    function getCDecimal(address collateral) external view returns(uint);
    function getMCR(address collateral) external view returns(uint);
    function getLFR(address collateral) external view returns(uint);
    function getSFR(address collateral) external view returns(uint);
    function getExpiary(address collateral) external view returns(uint256);
    function getOpen(address collateral_) external view returns (bool);
    function getAssetPrice(address asset) external view returns (uint);
    function getAssetValue(address asset, uint256 amount) external view returns (uint256);
    function isValidCDP(address collateral, address debt, uint256 cAmount, uint256 dAmount) external returns (bool);
    function isValidSupply(uint256 issueAmount_) external returns (bool);
    function createCDP(address collateral_, uint cAmount_, uint dAmount_) external returns (bool success);

    /// Event
    event VaultCreated(uint256 vaultId, address collateral, address debt, address creator, address vault, uint256 cAmount, uint256 dAmount);
    event CDPInitialized(address collateral, uint mcr, uint lfr, uint sfr, bool isOpen);
    event RebaseActive(bool set);
    event SetFees(address feeTo, address treasury, address dividend);
    event Rebase(uint256 totalSupply, uint256 desiredSupply);
    event SetDesiredSupply(uint desiredSupply);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../oracle/OracleRegistry.sol";
import "./Vault.sol";
import "./interfaces/IVaultFactory.sol";

contract VaultManager is OracleRegistry, IVaultManager {
    
    /// Desirable supply of stablecoin 
    uint256 public override desiredSupply;
    /// Switch to on/off rebase;
    bool public override rebaseActive;
    /// Last rebase
    uint256 public override lastRebase;

    // CDP configs
    /// key: Collateral address, value: Liquidation Fee Ratio (LFR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => uint) internal LFRConfig;
    /// key: Collateral address, value: Minimum Collateralization Ratio (MCR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => uint) internal MCRConfig;
    /// key: Collateral address, value: Stability Fee Ratio (SFR) in percent(%) with 5 decimal precision(100.00000%)
    mapping (address => uint) internal SFRConfig;
    /// key: Collateral address, value: Expiaries of a debt for interest rate fixation
    mapping (address => uint256) internal Expiaries;  
    /// key: Collateral address, value: whether collateral is allowed to borrow
    mapping (address => bool) internal IsOpen;
    /// key: Collateral address, value: whether collateral is allowed to borrow
    mapping (address => uint8) internal cDecimals;
    
    /// Address of stablecoin oracle  standard dex
    address public override stablecoin;
    /// Address of Vault factory
    address public override factory;
    /// Address of feeTo
    address public override feeTo;
    /// Address of Standard MTR fee pool
    address public override dividend;
    /// Address of Standard Treasury
    address public override treasury;
    /// Address of liquidator
    address public override liquidator;

    constructor() {
        _setupRole(ORACLE_OPERATOR_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initializeCDP(address collateral_, uint MCR_, uint LFR_, uint SFR_, uint256 expiary_, bool on) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        LFRConfig[collateral_] = LFR_;
        MCRConfig[collateral_] = MCR_;
        SFRConfig[collateral_] = SFR_; 
        Expiaries[collateral_] = expiary_;
        IsOpen[collateral_] = on;
        cDecimals[collateral_] = IERC20Minimal(collateral_).decimals();
        emit CDPInitialized(collateral_, MCR_, LFR_, SFR_, on);  
    }

    function setRebaseActive(bool set_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        rebaseActive = set_;
        emit RebaseActive(set_);
    }

    function setFees(address feeTo_, address dividend_, address treasury_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        feeTo = feeTo_;
        dividend = dividend_;
        treasury = treasury_;
        emit SetFees(feeTo_, dividend_, treasury_);
    }
    
    function initialize(address stablecoin_, address factory_, address liquidator_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        stablecoin = stablecoin_;
        factory = factory_;
        liquidator = liquidator_;
    }

    function createCDP(address collateral_, uint cAmount_, uint dAmount_) external override returns(bool success) {
        // check if collateral is open
        require(IsOpen[collateral_], "VAULTMANAGER: NOT OPEN");
        // check position
        require(isValidCDP(collateral_, stablecoin, cAmount_, dAmount_)
        , "IP"); // Invalid Position
        // check rebased supply of stablecoin
        require(isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
        // create vault
        (address vlt, uint256 id) = IVaultFactory(factory).createVault(collateral_, stablecoin, dAmount_, _msgSender());
        require(vlt != address(0), "VAULTMANAGER: FE"); // Factory error
        // transfer collateral to the vault, manage collateral from there
        TransferHelper.safeTransferFrom(collateral_, _msgSender(), vlt, cAmount_);
        // mint mtr to the sender
        IStablecoin(stablecoin).mint(_msgSender(), dAmount_);
        emit VaultCreated(id, collateral_, stablecoin, msg.sender, vlt, cAmount_, dAmount_);
        return true;
    }

    function createCDPNative(uint dAmount_) payable public returns(bool success) {
        address WETH = IVaultFactory(factory).WETH();
        // check if collateral is open
        require(IsOpen[WETH], "VAULTMANAGER: NOT OPEN");
        // check position
        require(isValidCDP(WETH, stablecoin, msg.value, dAmount_)
        , "IP"); // Invalid Position
        // check rebased supply of stablecoin
        require(isValidSupply(dAmount_), "RB"); // Rebase limited mtr borrow
        // create vault
        (address vlt, uint256 id) = IVaultFactory(factory).createVault(WETH, stablecoin, dAmount_, _msgSender());
        require(vlt != address(0), "VAULTMANAGER: FE"); // Factory error
        // wrap native currency
        IWETH(WETH).deposit{value: address(this).balance}();
        uint256 weth = IERC20Minimal(WETH).balanceOf(address(this));
        // then transfer collateral native currency to the vault, manage collateral from there.
        require(IWETH(WETH).transfer(vlt, weth)); 
        // mint mtr to the sender
        IStablecoin(stablecoin).mint(_msgSender(), dAmount_);
        emit VaultCreated(id, WETH, stablecoin, msg.sender, vlt, msg.value, dAmount_);
        return true;
    }
    

    function getCDPConfig(address collateral_) external view override returns (uint MCR, uint LFR, uint SFR, uint cDecimals, bool isOpen) {
        uint8 cDecimals = IERC20Minimal(collateral_).decimals();
        return (MCRConfig[collateral_], LFRConfig[collateral_], SFRConfig[collateral_], cDecimals, IsOpen[collateral_]);
    }

    function getMCR(address collateral_) public view override returns (uint) {
        return MCRConfig[collateral_];
    }

    function getLFR(address collateral_) external view override returns (uint) {
        return LFRConfig[collateral_];
    }

    function getSFR(address collateral_) public view override returns (uint) {
        return SFRConfig[collateral_];
    }

    function getExpiary(address collateral_) public view override returns (uint256) {
        return Expiaries[collateral_];
    } 

    function getOpen(address collateral_) public view override returns (bool) {
        return IsOpen[collateral_];
    } 
    
    function getCDecimal(address collateral_) public view override returns (uint) {
        return IERC20Minimal(collateral_).decimals();
    }     

    // Set desired supply for initial setting
    function setDesiredSupply(uint256 desiredSupply_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        desiredSupply = desiredSupply_;
        emit SetDesiredSupply(desiredSupply_);
    }

    // Set desirable supply of issuing stablecoin
    function rebase() public {
        require(rebaseActive, "VaultManager: RB inactive");
        require(block.timestamp - lastRebase >= 3600, "VaultManager: PY");
        uint256 totalSupply = IERC20Minimal(stablecoin).totalSupply(); 
        if ( totalSupply == 0 ) {
            return;
        }
        uint overallPrice = uint(_getPriceOf(address(0x0))); // set 0x0 oracle as overall oracle price of stablecoin in all exchanges
        // get desired supply and update 
        // solve equation where sigma{all dex pair value with MTR} / MTR total supply = 1 with decimal
        desiredSupply = totalSupply * overallPrice / 1e8; 
        lastRebase = block.timestamp;
        emit Rebase(totalSupply, desiredSupply);
    }

    function isValidCDP(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) public view override returns (bool) {
        (uint256 collateralValueTimes100Point00000, uint256 debtValue) = _calculateValues(collateral_, debt_, cAmount_, dAmount_);
        uint mcr = getMCR(collateral_);
        // if the debt become obsolete
        // Calculation: https://www.desmos.com/calculator/cfh64zb0di
        // Valid amounts should be a point inside the boundary with mcr in percentage(%)
        return debtValue == 0 ? true : collateralValueTimes100Point00000 * 10**(18-cDecimals[collateral_]) / debtValue  >= mcr;
    }

    function isValidSupply(uint256 issueAmount_) public view override returns (bool) {
        if (rebaseActive) {
            return IERC20Minimal(stablecoin).totalSupply() + issueAmount_ <= desiredSupply;
        } else {
            return true;
        }
    }

    function _calculateValues(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) internal view returns (uint256, uint256) {
        uint256 collateralValue = getAssetValue(collateral_, cAmount_);
        uint256 debtValue = getAssetValue(debt_, dAmount_);
        uint256 collateralValueTimes100Point00000 = collateralValue * 10000000;
        require(collateralValueTimes100Point00000 >= collateralValue); // overflow check
        return (collateralValueTimes100Point00000, debtValue);        
    }

    function getAssetPrice(address asset_) public view override returns (uint) {
        address aggregator = PriceFeeds[asset_];
        require(
            aggregator != address(0x0),
            "VAULT: Asset not registered"
        );
        int256 result = IPrice(aggregator).getThePrice();
        return uint(result);
    }

    function getAssetValue(address asset_, uint256 amount_) public view override returns (uint256) {
        uint price = getAssetPrice(asset_);
        uint256 value = price * amount_;
        require(value >= amount_); // overflow
        return value / 1e8;
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IStablecoin.sol";
import "./interfaces/IVaultFactory.sol";

/**
 * @title MeterToken
 * @dev This contract is template for MTR stablecoins
 */
contract MeterToken is AccessControl, IStablecoin, Ownable, ERC20 {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    /**
     * @dev Creates an instance of `MeterToken` where `name` and `symbol` is initialized.
     * Names and symbols can vary from the pegging currency
     */
    constructor(
        string memory name,
        string memory symbol,
        address manager
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, manager);
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }


    function mint(address to, uint256 amount) external override {
        // Check that the calling account has the minter role
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Meter: Caller is not a minter"
        );
        _mint(to, amount);
    }

    function mintFromVault(address factory, uint256 vaultId_, address to, uint256 amount) external override {
        require(hasRole(FACTORY_ROLE, factory), "IA"); // confirm factory contract is the known factory contract from the system, this prevents hackers making fake contracts that has the same interface
        require(IVaultFactory(factory).getVault(vaultId_)  == _msgSender(), "Meter: Not from Vault"); // check interface exists
        _mint(to, amount);
    }

    function burn(uint256 amount) external override {
        // Check that the calling account has the burner role
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external override {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Meter: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WSBY0 is AccessControl, ERC20 {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Wrapped Shibuya", "WSBY") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
    }

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(super.balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function mint(address to, uint256 amount) external {
        // Check that the calling account has the minter role
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Wrapped Shibuya: Caller is not a minter"
        );
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

// Creators: locationtba.eth, 2pmflow.eth

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;
  address private burned = address(1);

  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }
  
  function _safeBurn(uint256 tokenId) internal {
    _safeBurn(tokenId, "");
  }

  /**
   * @dev Burns a certain token from id.
   *
   * Emits a {Transfer} event.
   */
  function _safeBurn(
    uint256 tokenId,
    bytes memory _data
  ) internal {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);
    _addressData[prevOwnership.addr].balance -= 1;
    _ownerships[tokenId] = TokenOwnership(burned, uint64(block.timestamp));
    emit Transfer(prevOwnership.addr, burned, tokenId);
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Burns `tokenId` token and transfers them to `0x0`.
   *
   * Requirements:
   *
   * - `tokenId` cannot be out of the bound.
   * - `tokenId` sender must own the token.
   *
   * Emits a {Transfer} event.
   */

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    require(!Address.isContract(to), "ERC721A: recipient is contract");
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > currentIndex - 1) {
      endIndex = currentIndex - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IV1.sol";
import "./interfaces/IVault.sol";
import "./svg/interfaces/INFTSVG.sol";

contract V1 is ERC721A, AccessControl, IV1  {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // Vault factory address
    address public factory;
    // SVG for V1
    address public SVG;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setSVG(address svg_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "V1: Caller is not a default admin");
        SVG = svg_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory tokenURI) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        tokenURI = INFTSVG(SVG).tokenURI(tokenId);
    }

    constructor(address factory_)
    ERC721A("VaultOne", "V1", 1) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        factory = factory_;
    }
    
    function setFactory(address factory_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "V1: Caller is not a default admin");
        factory = factory_;
    }

    function mint(address to) external override {
        // Check that the calling account has the minter role
        require(_msgSender() == factory, "V1: Caller is not factory");
        _safeMint(to, 1); 
    }

    function burn(uint256 tokenId_) external override {
        require(hasRole(BURNER_ROLE, _msgSender()), "V1: must have burner role to burn");
        _safeBurn(tokenId_);
    }

    function burnFromVault(uint vaultId_) external override {
        require(IVaultFactory(factory).getVault(vaultId_)  == _msgSender(), "V1: Caller is not vault");
        _safeBurn(vaultId_);
    }

    function exists(uint256 tokenId_) external view override returns (bool) {
        return _exists(tokenId_);
    }
}

// SPDX-License-Identifier: Apache-2.0


pragma solidity ^0.8.0;

interface INFTSVG {
   function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "./libraries/NFTSVG.sol";
import "./interfaces/INFTSVG.sol";
import "./interfaces/INFTConstructor.sol";

contract NFTDescriptor is INFTSVG {
  address NFTConstructor;

  constructor(address constructor_) {
    NFTConstructor = constructor_;
  }

  // You could also just upload the raw SVG and have solildity convert it!
  function svgToImageURI(
    NFTSVG.ChainParams memory cParams,
    NFTSVG.BlParams memory blParams,
    NFTSVG.HealthParams memory hParams,
    NFTSVG.CltParams memory cltParams
  ) public pure returns (string memory imageURI) {
    // example:
    // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
    // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=

    string memory svgBase64Encoded = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            NFTSVG.generateSVG(cParams, blParams, hParams, cltParams)
          )
        )
      )
    );
    imageURI = string(
      abi.encodePacked("data:image/svg+xml;base64,", svgBase64Encoded)
    );
  }

  // You could also just upload the raw SVG and have solildity convert it!
  function svgToImageURITest(uint256 tokenId_)
    public
    view
    returns (string memory imageURI)
  {
    (
      NFTSVG.ChainParams memory cParams,
      NFTSVG.BlParams memory blParams,
      NFTSVG.HealthParams memory hParams,
      NFTSVG.CltParams memory cltParams
    ) = INFTConstructor(NFTConstructor).generateParams(tokenId_);
    imageURI = svgToImageURI(cParams, blParams, hParams, cltParams);
  }

  function formatTokenURI(
    string memory imageURI,
    NFTSVG.ChainParams memory cParam,
    NFTSVG.BlParams memory blParam
  ) internal pure returns (string memory) {
    bytes memory image = abi.encodePacked(
      '{"name":"',
      'VaultOne",',
      '"description":"VaultOne represents the ownership of',
      " one's financial rights written in an immutable smart contract. ",
      "Only the holder can manage and interact with the funds connected to its immutable smart contract",
      '",',
      '"image":"',
      imageURI,
      '",'
    );
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                image,
                '"chainId":"',
                cParam.chainId,
                '",',
                '"vault":"',
                blParam.vault,
                '",',
                '"collateral":"',
                cParam.collateral,
                '",',
                '"debt":"',
                cParam.debt,
                '"',
                "}"
              )
            )
          )
        )
      );
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    (
      NFTSVG.ChainParams memory cParams,
      NFTSVG.BlParams memory blParams,
      NFTSVG.HealthParams memory hParams,
      NFTSVG.CltParams memory cltParams
    ) = INFTConstructor(NFTConstructor).generateParams(tokenId);
    string memory imageURI = svgToImageURI(
      cParams,
      blParams,
      hParams,
      cltParams
    );
    return formatTokenURI(imageURI, cParams, blParams);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

library NFTSVG {
  struct ChainParams {
    string chainId;
    string chainName;
    string collateral;
    string debt;
  }

  struct BlParams {
    string vault;
    string cBlStr;
    string dBlStr;
    string symbol;
  }

  struct CltParams {
    string MCR;
    string LFR;
    string SFR;
  }

  struct HealthParams {
    string HP;
    string HPBarColor1;
    string HPBarColor2;
    string HPStatus;
    string HPGauge;
  }

  function generateSVGDefs(ChainParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<svg width="400" height="250" viewBox="0 0 400 250" fill="none" xmlns="http://www.w3.org/2000/svg"',
        ' xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<rect width="400" height="250" fill="url(#pattern0)" />',
        "<defs>",
        '<pattern id="pattern0" patternContentUnits="objectBoundingBox" width="1" height="1">',
        '<use xlink:href="#image0_18_24" transform="scale(0.0025 0.004)" />',
        "</pattern>",
        '<image id="image0_18_24" width="400" height="250" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/backgrounds/",
        params.chainId,
        ".png",
        '"',
        " />",
        "</defs>",
        '<rect x="10" y="12" width="380" height="226" rx="20" ry="20" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.8)" />'
      )
    );
  }

  function generateBalances(BlParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text y="60" x="32" fill="white"',
        ' font-family="Poppins" font-weight="400" font-size="24px">WETH Vault #2</text>',
        '<text y="85px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Collateral: ',
        params.cBlStr,
        " ",
        params.symbol,
        "</text>"
        '<text y="110px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">IOU: ',
        params.dBlStr,
        " ",
        "USM"
        "</text>"
      )
    );
  }

  function generateHealth(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text y="135px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Health: ',
        params.HP,
        "% ",
        params.HPStatus,
        "</text>"
      )
    );
  }

  function generateBitmap() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        "<g>",
        '<svg class="healthbar" xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 38 9" shape-rendering="crispEdges"',
        ' x="-113px" y="138px" width="400px" height="30px">',
        '<path stroke="#222034"',
        ' d="M2 2h1M3 2h32M3  3h1M2 3h1M35 3h1M3 4h1M2 4h1M35 4h1M3  5h1M2 5h1M35 5h1M3 6h32M3" />',
        '<path stroke="#323c39" d="M3 3h32" />',
        '<path stroke="#494d4c" d="M3 4h32M3 5h32" />',
        "<g>"
      )
    );
  }

  function generateStop(string memory color1, string memory color2)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<stop offset="5.99%">',
        '<animate attributeName="stop-color" values="',
        color1,
        "; ",
        color2,
        "; ",
        color1,
        '" dur="3s" repeatCount="indefinite"></animate>',
        "</stop>"
      )
    );
  }

  function generateLinearGradient(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<linearGradient id="myGradient" gradientTransform="rotate(270.47)" >',
        generateStop(params.HPBarColor1, params.HPBarColor2),
        generateStop(params.HPBarColor2, params.HPBarColor1),
        "</linearGradient>"
      )
    );
  }

  function generateHealthBar(HealthParams memory params)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        generateLinearGradient(params),
        '<svg x="3" y="2.5" width="32" height="10">',
        '<rect fill="',
        "url(",
        "'#myGradient'",
        ')"',
        ' height="3">',
        ' <animate attributeName="width" from="0" to="',
        params.HPGauge,
        '" dur="0.5s" fill="freeze" />',
        "</rect>",
        "</svg>",
        "</g>",
        "</svg>",
        "</g>"
      )
    );
  }

  function generateCltParam(
    string memory y,
    string memory width,
    string memory desc,
    string memory percent
  ) internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(30px, ',
        y,
        ')">',
        '<rect width="',
        width,
        '" height="12px" rx="3px" ry="3px" fill="rgba(0,0,0,0.6)" /><text x="6px" y="9px"',
        ' font-family="Poppins" font-size="8px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">',
        desc,
        ": </tspan>",
        percent,
        "% </text>"
        "</g>"
      )
    );
  }

  function generateTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-a" transform="translate(1,1)" d="M369.133 1.20364L28.9171 1.44856C13.4688 1.45969 0.948236 13.9804 0.937268 29.4287L0.80321 218.243C0.792219 233.723 13.3437 246.274 28.8233 246.263L369.04 246.018C384.488 246.007 397.008 233.486 397.019 218.038L397.153 29.2235C397.164 13.7439 384.613 1.1925 369.133 1.20364Z" fill="none" stroke="none" />'
      )
    );
  }

  function generateText1(string memory a, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text text-rendering="optimizeSpeed">',
        '<textPath startOffset="-100%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
        '</textPath> <textPath startOffset="0%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>'
      )
    );
  }

  function generateText2(string memory b, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<textPath startOffset="50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
        ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
      )
    );
  }

  function generateNetwork(ChainParams memory cParams)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<image  x="285" y="50" width="60" height="60" xlink:href="'
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/networks/",
        cParams.chainId,
        ".png",
        '" />',
        generateTokenLogos(cParams)
      )
    );
  }

  function generateNetTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-b" transform="translate(269,35)" d="M1 46C1 70.8528 21.1472 91 46 91C70.8528 91 91 70.8528 91 46C91 21.1472 70.8528 1 46 1C21.1472 1 1 21.1472 1 46Z" stroke="none"/>'
      )
    );
  }

  function generateTokenLogos(ChainParams memory cParam)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(265px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        '<image x="4" y="4" width="40" height="40" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/tokens/",
        cParam.chainId,
        "/",
        cParam.collateral,
        ".png",
        '" />'
        "</g>"
        '<g style="transform:translate(325px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        '<image x="4" y="4" width="40" height="40" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/tokens/",
        cParam.chainId,
        "/",
        cParam.debt,
        ".png",
        '" />'
        "</g>"
      )
    );
  }

  function generateSVG(
    ChainParams memory cParams,
    BlParams memory blParams,
    HealthParams memory hParams,
    CltParams memory cltParams
  ) internal pure returns (string memory svg) {
    string memory a = string(
      abi.encodePacked(blParams.vault, unicode" • ", "Vault")
    );
    string memory b = string(
      abi.encodePacked(unicode" • ", cParams.chainName, unicode" • ")
    );
    string memory first = string(
      abi.encodePacked(
        generateSVGDefs(cParams),
        generateBalances(blParams),
        generateHealth(hParams),
        generateBitmap(),
        generateHealthBar(hParams)
      )
    );
    string memory second = string(
      abi.encodePacked(
        first,
        generateCltParam(
          "180px",
          "130px",
          "Min. Collateral Ratio",
          cltParams.MCR
        ),
        generateCltParam("195px", "110px", "Liquidation Fee", cltParams.LFR),
        generateCltParam("210px", "90px", "Stability Fee", cltParams.SFR),
        generateTextPath()
      )
    );
    svg = string(
      abi.encodePacked(
        second,
        generateText1(a, "a"),
        generateText2(a, "a"),
        generateNetwork(cParams),
        generateNetTextPath(),
        generateText1(b, "b"),
        generateText2(b, "b"),
        "</svg>"
      )
    );
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/NFTSVG.sol";

interface INFTConstructor {
    function generateParams(uint256 tokenId_)
    external
    view
    returns (
      NFTSVG.ChainParams memory cParam,
      NFTSVG.BlParams memory blParam,
      NFTSVG.HealthParams memory hParam,
      NFTSVG.CltParams memory cltParam
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "../interfaces/IVaultManager.sol";
import "../interfaces/IERC20Minimal.sol";
import "./libraries/NFTSVG.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Symbol {
  function symbol() external view returns (string memory);
}

contract NFTConstructor {
  using Strings for uint256;

  address factory;
  address manager;
  string chainName;

  constructor(
    address factory_,
    address manager_,
    string memory chainName_
  ) {
    factory = factory_;
    manager = manager_;
    chainName = chainName_;
  }

  function generateParams(uint256 tokenId_)
    external
    view
    returns (
      NFTSVG.ChainParams memory cParam,
      NFTSVG.BlParams memory blParam,
      NFTSVG.HealthParams memory hParam,
      NFTSVG.CltParams memory cltParam
    )
  {
    address vault = IVaultFactory(factory).getVault(tokenId_);
    address debt = IVault(vault).debt();
    address collateral = IVault(vault).collateral();
    uint256 cDecimal = IVaultManager(manager).getCDecimal(collateral);
    uint256 cBalance = IERC20Minimal(collateral).balanceOf(vault);
    uint256 dBalance = IVault(vault).borrow();
    string memory symbol = IERC20Symbol(collateral).symbol();
    uint256 HP = _getHP(collateral, debt, cBalance, dBalance);
    return (
      _generateChainParams(collateral, debt),
      _generateBlParams(vault, cDecimal, cBalance, dBalance, symbol),
      _generateHealthParams(HP),
      _generateCltParams(collateral)
    );
  }

  function _generateChainParams(address collateral, address debt)
    internal
    view
    returns (NFTSVG.ChainParams memory cParam)
  {
    cParam = NFTSVG.ChainParams({
      chainId: block.chainid.toString(),
      chainName: chainName,
      collateral: addressToString(collateral),
      debt: addressToString(debt)
    });
  }

  function addressToString(address addr) internal pure returns (string memory) {
    return (uint256(uint160(addr))).toHexString(20);
  }

  function _generateBlParams(
    address vault,
    uint256 cDecimal,
    uint256 cBalance,
    uint256 dBalance,
    string memory symbol
  ) internal pure returns (NFTSVG.BlParams memory blParam) {
    blParam = NFTSVG.BlParams({
      vault: addressToString(vault),
      cBlStr: _generateDecimalString(cDecimal, cBalance),
      dBlStr: _generateDecimalString(18, dBalance),
      symbol: symbol
    });
  }

  function _generateHealthParams(uint256 HP)
    internal
    pure
    returns (NFTSVG.HealthParams memory hParam)
  {
    hParam = NFTSVG.HealthParams({
      HP: _formatHP(HP),
      HPBarColor1: _getHPBarColor1(HP),
      HPBarColor2: _getHPBarColor2(HP),
      HPStatus: _getHPStatus(HP),
      HPGauge: _formatGauge(HP)
    });
  }

  function _generateCltParams(address collateral)
    internal
    view
    returns (NFTSVG.CltParams memory cltParam)
  {
    cltParam = NFTSVG.CltParams({
      MCR: _formatRatio(IVaultManager(manager).getMCR(collateral)),
      LFR: _formatRatio(IVaultManager(manager).getLFR(collateral)),
      SFR: _formatRatio(IVaultManager(manager).getSFR(collateral))
    });
  }

  function _formatRatio(uint256 ratio) internal pure returns (string memory str) {
    uint256 integer = ratio / 100000;
    uint256 secondPrecision = ratio / 1000 - (integer * 100);
    if (secondPrecision > 0) {
      str = string(
        abi.encodePacked(integer.toString(), ".", secondPrecision.toString())
      );
    } else {
      str = string(abi.encodePacked(integer.toString()));
    }
  }

  function _generateDecimalString(uint256 decimals, uint256 balance)
    internal
    pure
    returns (string memory str)
  {
    uint256 integer = balance / 10**decimals;
    if (integer >= 100000000000) {
      str = "99999999999+";
    }
    uint256 secondPrecision = balance / 10**(decimals - 2) - (integer * 10**2);
    if (secondPrecision > 0) {
      str = string(
        abi.encodePacked(integer.toString(), ".", secondPrecision.toString())
      );
    } else {
      str = string(abi.encodePacked(integer.toString()));
    }
  }

  function _getHP(
    address collateral,
    address debt,
    uint256 cBalance,
    uint256 dBalance
  ) internal view returns (uint256 HP) {
    uint256 cValue = IVaultManager(manager).getAssetPrice(collateral) *
      cBalance;
    uint256 dPrice = IVaultManager(manager).getAssetPrice(debt);
    uint256 mcr = IVaultManager(manager).getMCR(collateral);
    HP = _calculateHP(cValue, dPrice, dBalance, mcr);
  }

  function _calculateHP(
    uint256 cValue,
    uint256 dPrice,
    uint256 dBalance,
    uint256 mcr
  ) internal pure returns (uint256 HP) {
    uint256 cdpRatioPercent = (cValue / dPrice) * dBalance * 100;
    HP = (100 * (cdpRatioPercent - mcr / 100000)) / 50;
  }

  function _formatHP(
    uint256 HP
  ) internal pure returns (string memory HPString) {
    if (HP > 200) {
      HPString = "200+";
    } else {
      HPString = HP.toString();
    }
  }

  function _formatGauge(
    uint256 HP
  ) internal pure returns (string memory HPGauge) {
    if (HP > 100) {
      HPGauge = '32';
    } else {
      HPGauge = (HP*32/100).toString();
    }
  }

  function _getHPBarColor1(uint256 HP)
    internal
    pure
    returns (string memory color)
  {
    if (HP <= 30) {
      color = "#F5B1A6";
    }
    if (HP <= 50) {
      color = "#E8ECCA";
    }
    if (HP < 100) {
      color = "#C9FBAD";
    }
    if (HP >= 100) {
      color = "#C4F2FE";
    }
  }

  function _getHPBarColor2(uint256 HP)
    internal
    pure
    returns (string memory color)
  {
    if (HP <= 30) {
      color = "#EC290A";
    }
    if (HP <= 50) {
      color = "#D6ED20";
    }
    if (HP < 100) {
      color = "#57E705";
    }
    if (HP >= 100) {
      color = "#6FA4FB";
    }
  }

  function _getHPStatus(uint256 HP)
    internal
    pure
    returns (string memory status)
  {
    if (HP <= 10) {
      status = unicode"💀";
    }
    if (HP <= 30) {
      status = unicode"🚑";
    }
    if (HP < 50) {
      status = unicode"💛";
    }
    if (HP <= 80) {
      status = unicode"❤️";
    }
    if (HP <= 100) {
      status = unicode"💖";
    }
    if (HP > 100) {
      status = unicode"💎";
    }
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PureSVG {
  using Strings for uint256;

  function generateSVGDefs() private pure returns (string memory svg) {
    string memory url = "https://i.imgur.com/YESHC62.png";
    svg = string(
      abi.encodePacked(
        '<svg width="400" height="250" viewBox="0 0 400 250" fill="none" xmlns="http://www.w3.org/2000/svg"',
        ' xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<rect width="400" height="250" fill="url(#pattern0)" />',
        "<defs>",
        '<pattern id="pattern0" patternContentUnits="objectBoundingBox" width="1" height="1">',
        '<use xlink:href="#image0_18_24" transform="scale(0.0025 0.004)" />',
        "</pattern>",
        '<image id="image0_18_24" width="400" height="250" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/backgrounds/",
        '1088',
        ".png",
        '"',
        " />",
        "</defs>",
        '<rect x="10" y="12" width="380" height="226" rx="20" ry="20" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.8)" />'
      )
    );
  }

  function generateBalances() private pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<text y="60" x="32" fill="white"',
        ' font-family="Poppins" font-weight="400" font-size="24px">WETH Vault #2</text>',
        '<text y="85px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Collateral: ',
        "1000",
        " ",
        "WETH",
        "</text>"
        '<text y="110px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">IOU: ',
        "1500",
        " ",
        "USM"
        "</text>"
      )
    );
  }

  function generateHealth() internal pure returns (string memory svg) {
    string memory heart = unicode"❤️";
    svg = string(
      abi.encodePacked(
        '<text y="135px" x="32px" fill="white" font-family="Poppins" font-weight="350" font-size="14px">Health: ',
        "80",
        "% ",
        heart,
        "</text>"
      )
    );
  }

  function generateBitmap() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        "<g>",
        '<svg class="healthbar" xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 38 9" shape-rendering="crispEdges"',
        ' x="-113px" y="138px" width="400px" height="30px">',
        '<path stroke="#222034"',
        ' d="M2 2h1M3 2h32M3  3h1M2 3h1M35 3h1M3 4h1M2 4h1M35 4h1M3  5h1M2 5h1M35 5h1M3 6h32M3" />',
        '<path stroke="#323c39" d="M3 3h32" />',
        '<path stroke="#494d4c" d="M3 4h32M3 5h32" />',
        "<g>"
      )
    );
  }

  function generateHealthBar() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<svg x="3" y="2.5" width="32" height="10">',
        '<rect fill="',
        "#57e705",
        '" height="3">',
        ' <animate attributeName="width" from="0" to="20" dur="0.5s" fill="freeze" />',
        "</rect>",
        "</svg>",
        "</g>",
        "</svg>",
        "</g>"
      )
    );
  }

  function generateCltParams() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(30px, 180px)">',
        '<rect width="120px" height="12px" rx="3px" ry="3px" fill="rgba(0,0,0,0.6)" /><text x="6px" y="9px"'
        ' font-family="Poppins" font-size="8px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">Min. Collateral Ratio: </tspan>',
        "150",
        "% </text>"
        "</g>",
        '<g style="transform:translate(30px, 195px)">',
        '<rect width="110px" height="12px" rx="3px" ry="3px" fill="rgba(0,0,0,0.6)" /><text x="6px" y="9px"'
        ' font-family="Poppins" font-size="8px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">Liq. Penalty Ratio: </tspan>',
        "150",
        "% </text>"
        "</g>",
        '<g style="transform:translate(30px, 210px)">',
        '<rect width="80px" height="12px" rx="3px" ry="3px" fill="rgba(0,0,0,0.6)" /><text x="6px" y="9px"'
        ' font-family="Poppins" font-size="8px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">Stability Fee: </tspan>',
        "150",
        "% </text>"
        "</g>"
      )
    );
  }

  function generateTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-a" transform="translate(1,1)" d="M369.133 1.20364L28.9171 1.44856C13.4688 1.45969 0.948236 13.9804 0.937268 29.4287L0.80321 218.243C0.792219 233.723 13.3437 246.274 28.8233 246.263L369.04 246.018C384.488 246.007 397.008 233.486 397.019 218.038L397.153 29.2235C397.164 13.7439 384.613 1.1925 369.133 1.20364Z" fill="none" stroke="none" />'
      )
    );
  }

  function generateText1(string memory a, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<text text-rendering="optimizeSpeed">',
        '<textPath startOffset="-100%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
        '</textPath> <textPath startOffset="0%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        a,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>'
      )
    );
  }

  function generateText2(string memory b, string memory path)
    internal
    pure
    returns (string memory svg)
  {
    svg = string(
      abi.encodePacked(
        '<textPath startOffset="50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
        ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="Poppins" font-size="10px" xlink:href="#text-path-',
        path,
        '">',
        b,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
      )
    );
  }

  function generateNetwork() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<image  x="285" y="50" width="60" height="60" xlink:href="'
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/networks/",
        '1088',
        ".png",
        '" />'      
        )
    );
  }

  function generateNetTextPath() internal pure returns (string memory svg) {
    svg = string(
      // text path has to be one liner, concatenating separate texts causes encoding error
      abi.encodePacked(
        '<path id="text-path-b" transform="translate(269,35)" d="M1 46C1 70.8528 21.1472 91 46 91C70.8528 91 91 70.8528 91 46C91 21.1472 70.8528 1 46 1C21.1472 1 1 21.1472 1 46Z" stroke="none"/>'
      )
    );
  }

  function generateTokenLogos() internal pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(265px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        '<image x="4" y="4" width="40" height="40" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/tokens/",
        '4',
        '/'
        '0xc778417E063141139Fce010982780140Aa0cD5Ab',
        ".png",
        '" />'
        "</g>"
        '<g style="transform:translate(325px, 180px)">'
        '<rect width="48px" height="48px" rx="10px" ry="10px" fill="none" stroke="rgba(255,255,255,0.6)" />'
        '<image x="4" y="4" width="40" height="40" xlink:href="',
        "https://raw.githubusercontent.com/digitalnativeinc/nft-arts/main/V1/tokens/",
        '4',
        '/'
        '0x6388e0cC745b3c5ED23c6D569A01A4D27eDa3E14',
        ".png",
        '" />'
        "</g>"
      )
    );
  }

  function generateSVG() internal pure returns (string memory svg) {
    string memory a = string(
      abi.encodePacked(
        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        unicode" • ",
        "Vault"
      )
    );
    string memory b = string(
      abi.encodePacked(unicode" • ", "Ethereum", unicode" • ")
    );
    string memory first = string(
      abi.encodePacked(
        generateSVGDefs(),
        generateBalances(),
        generateHealth(),
        generateBitmap(),
        generateHealthBar(),
        generateCltParams(),
        generateTextPath(),
        generateText1(a, "a"),
        generateText2(a, "a")
      )
    );
    svg = string(
      abi.encodePacked(
        first,
        generateNetwork(),
        generateNetTextPath(),
        generateText1(b, "b"),
        generateText2(b, "b"),
        generateTokenLogos(),
        "</svg>"
      )
    );
  }

  // You could also just upload the raw SVG and have solildity convert it!
  function svgToImageURI() public pure returns (string memory) {
    // example:
    // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
    // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
    string memory baseURL = "data:image/svg+xml;base64,";
    string memory svgBase64Encoded = Base64.encode(
      bytes(string(abi.encodePacked(generateSVG())))
    );
    return string(abi.encodePacked(baseURL, svgBase64Encoded));
  }

  function formatTokenURI(string memory imageURI)
    public
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                "VaultOne", // You can add whatever name here
                '", "description":"An NFT based on SVG!", "attributes":"", "image":"',
                imageURI,
                '"}'
              )
            )
          )
        )
      );
  }

  // remove later:
  function bytes32ToString(bytes32 _bytes32)
    public
    pure
    returns (string memory)
  {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../vaults/meter/interfaces/IERC20Minimal.sol";

import "./interfaces/IPrice.sol";

contract DexOracle is IPrice {
    address public pair;
    string public name;
    address public operator;
    uint256 public lastAskedBlock;
    address public from;
    address public to;
    int256 public prevPrice;
    
    constructor(address pair_, address from_, address to_, string memory name_) {
        pair = pair_;
        operator = msg.sender;
        name = name_;
    }

    function setPair(address pair_, address from_, address to_) public {
        require(msg.sender == operator, "IA");
        pair = pair_;
        from = from_;
        to = to_;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() external view override returns (int256) {
        int256 fromP = int256(IERC20Minimal(from).balanceOf(pair) / 10 ** IERC20Minimal(from).decimals());
        int256 toP = int256(IERC20Minimal(to).balanceOf(pair) / 10 ** IERC20Minimal(to).decimals());
        int256 price = fromP == 0 ? int256(0) : 10**8 * toP / fromP;
        // Flashswap guard: if current block equals last asked block, return previous price, otherwise set prevPrice as the current price, set lastAskedBlock in current block
        require(lastAskedBlock < block.number, "DexOracle: FlashSwap detected"); 
        return price;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0;

import "../interfaces/IV1.sol";
/*
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library NFTHelper {
    /// @notice Checks owner of the NFT
    /// @dev Calls owner on NFT contract, errors with NO if address is not owner
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function ownerOf(
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IV1.ownerOf.selector, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lpt;

    uint256 private _totalInput;
    mapping(address => uint256) private _balances;

    function totalInput() public view returns (uint256) {
        return _totalInput;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalInput = _totalInput.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalInput = _totalInput.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpt.safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IMetaERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address to, uint256 amount) external;
    function meta() external view returns (address meta);
    function assetId() external view returns (uint256 assetId);
    function data() external view returns (bytes memory data);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./MetaERC20.sol";
import "./interfaces/IMetaERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


library MetaLibrary {
    // calculates the CREATE2 address for a vault without making any external calls
    function verifyUnwrap(address claim, address wrapper, uint256 assetId, bytes32 code) internal pure returns (bool success) {
        address wrapped = address(uint160(uint(keccak256(abi.encodePacked(
                hex"ff",
                wrapper,
                keccak256(abi.encodePacked(claim, assetId)),
                code // init code hash
            )))));
        return wrapped == claim;
    } 
}

contract WrappedMeta {

    mapping(address => address[]) wraps;
    event WrapCreated(address metaverse, uint256 assetId, address wrapped);
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function createWrap(string memory name, string memory symbol, address meta, uint256 assetId, bytes memory data) public returns (address wrapped) {
        // require sender to be ERC1155 default admin
        require(IAccessControl(meta).hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WrappedMeta: ACCESS INVALID");
        bytes memory bytecode = type(MetaERC20).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, meta, assetId, data));
        assembly {
            wrapped := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        wraps[meta][assetId] = wrapped;
        emit WrapCreated(meta, assetId, wrapped);
        return wrapped;
    }

    function wrappedCodeHash() public pure returns (bytes32) {
        return keccak256(type(MetaERC20).creationCode);
    }

    function deposit(address meta, uint256 id, uint256 amount, bytes memory data) public {
        // require wrapped token to be created by metaverse admin
        address wrapped = wraps[meta][id];
        require(wrapped != address(0x0), "WrappedMeta: WRAPPED NOT CREATED");
        // Get ERC1155
        IERC1155(meta).safeTransferFrom(msg.sender, address(this), id, amount, data);
        // if it is, mint wrapped erc20 to the sender
        IMetaERC20(wrapped).mint(msg.sender, amount);
    }

    function withdraw(address wrapped, uint256 amount) public {
        // Get metacoin's metaverse address
        address meta = IMetaERC20(wrapped).meta();
        // Get wrapped asset's id
        uint256 assetId = IMetaERC20(wrapped).assetId();
        // Get wrapped asset's data
        bytes memory data = IMetaERC20(wrapped).data();
        // Verify unwrapped
        bool verify = MetaLibrary.verifyUnwrap(meta, address(this), assetId, wrappedCodeHash());
        require(verify, "WrappedMeta: NOT WRAPPED FROM THIS");
        // Get Wrapped token
        IMetaERC20(wrapped).burn(msg.sender, amount);
        // Give back the erc1155
        IERC1155(meta).safeTransferFrom(address(this), msg.sender, assetId, amount, data);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IMetaERC20.sol";


contract MetaERC20 is ERC20PresetMinterPauser, IMetaERC20 {
    address public override meta;
    uint256 public override assetId;
    bytes public override data;
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    constructor(string memory name, string memory symbol, address meta, uint256 assetId, bytes memory data) ERC20PresetMinterPauser(name, symbol) public {
        _setupRole(MINTER_ROLE, msg.sender);
        meta = meta;
        assetId = assetId;
        data = data;
    }
    function mint(address to, uint256 amount) public virtual override(ERC20PresetMinterPauser, IMetaERC20) {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public virtual override(IMetaERC20) {
        require(hasRole(BURNER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have burner role to burn");
        _burn(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../security/DurationGuard.sol";
import "../interfaces/IBondedStrategy.sol";

contract BondedStrategy is DurationGuard, IBondedStrategy {

    address public override stnd;
    uint256 public override totalSupply;
    mapping(address => uint256) public override bonded;
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");
    
    constructor(
        address stnd_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        setDuration(BOND_ROLE, 14 days);
        setDuration(CLAIM_ROLE, 14 days);
        stnd = stnd_;
    }

    function claim(address token) external override onlyPerDuration(CLAIM_ROLE, token) returns (bool success) {
        require(token != stnd, "BondedStrategy: Invalid Claim");
        require(block.timestamp - lastTx[_msgSender()][stnd] >= _durations[CLAIM_ROLE]);
        uint256 proRataBonded = bonded[msg.sender] * IERC20(token).balanceOf(address(this)) / totalSupply;
        require(IERC20(token).transfer(msg.sender, proRataBonded), "BondedStrategy: fee transfer failed");
        emit DividendClaimed(msg.sender, token, proRataBonded);
        return true;
    }

    function bond(uint256 amount_) external {
        require(IERC20(stnd).transferFrom(msg.sender, address(this), amount_), "BondedStrategy: Not enough allowance to move with given amount");
        bonded[msg.sender] += amount_;
        totalSupply += amount_;
        lastTx[_msgSender()][stnd] = block.timestamp;
        emit Bonded(msg.sender, amount_);
    }

    function unbond(uint256 amount_) external onlyPerDuration(BOND_ROLE, stnd) {
        require(bonded[msg.sender] >= amount_, "BondedStrategy: Not enough bonded STND");
        require(
            block.timestamp - lastTx[msg.sender][stnd] >= _durations[BOND_ROLE],
            "BondedGuard: A month has not passed from the last bonded tx"
        );
        bonded[msg.sender] -= amount_;
        totalSupply -= amount_;
        IERC20(stnd).transfer(msg.sender, amount_);
        emit UnBonded(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DurationGuard is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => mapping(address => uint256)) public lastTx;
    mapping(bytes32 => uint256) public _durations;

    modifier onlyPerDuration(bytes32 role, address token) {
        require(
            block.timestamp - getLastClaimed(token) >= _durations[role],
            "DurationGuard: A duration has not passed from the last request"
        );
        _;

        lastTx[msg.sender][token] = block.timestamp;
    }

    function getLastClaimed(address token) public view returns (uint256) {
        return lastTx[msg.sender][token];
    }

    function setDuration(bytes32 _role, uint256 _duration) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "DurationGuard: ACCESS INVALID"
        );
        _durations[_role] = _duration;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IBondedStrategy {
    function stnd() external view returns (address);
    function totalSupply() external view returns (uint256);
    function bonded(address holder) external view returns (uint256);
    function claim(address token) external returns (bool success);

    event DividendClaimed(address claimer, address claimingWith, uint256 amount);
    event Bonded(address holder, uint256 amount);
    event UnBonded(address holder, uint256 amount);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IBondedStrategy.sol";


contract ClaimAll {
    address[] public allClaims;
    address public dividend;

    constructor(address dividend_) {
        dividend = dividend_;
    }

    function claimAll() external {
        uint256 len = allClaims.length;
        for (uint256 i = 0; i < len; ++i) {
            require(IBondedStrategy(dividend).claim(allClaims[i]), "ClaimAll: claim failed");
        }  
    } 

    function massClaim(address[] memory claims) external {
        uint256 len = claims.length;
        for (uint256 i = 0; i < len; ++i) {
            require(IBondedStrategy(dividend).claim(claims[i]), "ClaimAll: claim failed");
        }  
    }

    function addClaim(address claim) external {
        allClaims.push(claim);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: STNDRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/utils/math/Math.sol

import "@openzeppelin/contracts/utils/math/Math.sol";

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// File: @openzeppelin/contracts/utils/Address.sol

import "@openzeppelin/contracts/utils/Address.sol";

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// File: contracts/pools/IRewardDistributionRecipient.sol

import "./IRewardDistributionRecipient.sol";

// File: contracts/pools/LPTokenWrapper.sol

import "./LPTokenWrapper.sol";

contract WETHSTNDLPTokenSharePool is
    LPTokenWrapper,
    IRewardDistributionRecipient
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public stnd;
    address private operator;
    uint256 public constant DURATION = 60 days;

    uint256 public initreward = 300000 * 10**18;
    uint256 public starttime; // starttime TBD
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address stnd_,
        address lptoken_,
        uint256 starttime_
    ) {
        stnd = IERC20(stnd_);
        lpt = IERC20(lptoken_);
        starttime = starttime_;
        operator = msg.sender;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalInput() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalInput())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            stnd.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function emergencyWithdraw(uint256 amount) public {
        require(msg.sender == operator, "Not the operator of the pool");
        stnd.safeTransfer(msg.sender, amount);
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, "not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = initreward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            require(rewardRate <= balanceOf(address(this)).div(DURATION));
            emit RewardAdded(initreward);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bond is AccessControl {

    // address for token to burn
    address public burn;
    // address of core token
    address public core;
    // conversion denominator
    uint256 public convDen;
    // converstion numerator
    uint256 public convNum;
    
    constructor(
        address burn_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        burn = burn_;
    }

    // burn tokens with core to get liquidation prorata
    function liquidate(uint256 amount, address collateral) external {
        
    }
}

// SPDX-License-Identifier: Apache-2.0

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 10000000e18);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BridgeToken is AccessControl, ERC20 {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    
    constructor(string memory name, string memory symbol)
    ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    // Chainbridge functions
    function mint(address to, uint256 amount) external  {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Meter: Caller is not a minter");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
    
    // Polygon functions
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
    {
        require(hasRole(DEPOSITOR_ROLE, msg.sender), "Meter: Caller is not a minter");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }
    
    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user"s tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
import "../Vault.sol";

contract CallHash {
    // calculates the CREATE2 address for a vault without making any external calls
    function vaultFor(address manager, uint256 vaultId, bytes32 code) internal pure returns (address vault) {
        vault = address(uint160(uint(keccak256(abi.encodePacked(
                hex"ff",
                manager,
                keccak256(abi.encodePacked(vaultId)),
                code // init code hash
            )))));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/dSTNDV1.sol

pragma solidity ^0.8.0;

// Staking in sSpell inspired by Chef Nomi's SushiBar - MIT license (originally WTFPL)
// Modified for multichain bridge capabilities for Standard

contract dSTNDV1 is ERC20("StandardDividend", "dSTND"), AccessControl {
    using SafeMath for uint256;
    IERC20 public stnd;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(IERC20 _stnd) public {
        stnd = _stnd;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalSTND = stnd.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalSTND == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalSTND);
            _mint(msg.sender, what);
        }
        stnd.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(stnd.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        stnd.transfer(msg.sender, what);
    }

    // Chainbridge functions
    function mint(address to, uint256 amount) external  {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "dSTNDV1: Caller is not a minter");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    // Anyswap functions
    function burn(address account, uint256 amount) external  {
        // Check that the calling account has the minter role
        require(hasRole(BURNER_ROLE, msg.sender), "dSTNDV1: Caller is not a burner");
        _burn(account, amount);
    }
    
    // Polygon functions
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
    {
        require(hasRole(DEPOSITOR_ROLE, msg.sender), "dSTNDV1: Caller is not a depositor");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }
    
    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user"s tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IUniswapV2FactoryMinimal.sol";
import "./interfaces/IERC20Minimal.sol";
import "./TransferHelper.sol";

contract Liquidator is AccessControl {

  address v2Factory;
  address debt;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function initialize(address v2Factory_, address debt_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
    v2Factory = v2Factory_;
    debt = debt_;
  }

  function distribute(address collateral) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
    // check the pair if it exists
    address pair = IUniswapV2FactoryMinimal(v2Factory).getPair(
      collateral,
      debt
    );
    require(pair != address(0), "Vault: Liquidating pair not supported");
    // Distribute collaterals
    TransferHelper.safeTransfer(collateral, pair, IERC20Minimal(collateral).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IUniswapV2FactoryMinimal {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0;

interface IERC20Minimal {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AF");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TFF");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "ETF");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IPrice.sol";

contract MockOracle is IPrice {
    int256 price;
    string public name;
    address operator;

    constructor(int256 price_, string memory name_) {
        price = price_;
        operator = msg.sender;
        name = name_;
    }

    function setPrice(int256 price_) public {
        require(msg.sender == operator, "IA");
        price = price_;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() external view override returns (int256) {
        return price;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./DiaKeyValueInterface.sol";
import "./interfaces/IPrice.sol";

contract DiaKeyValue is IPrice {
    DiaKeyValueInterface internal priceFeed;

    string public key;

    constructor(address _aggregator, string memory _key) public {
        priceFeed = DiaKeyValueInterface(_aggregator);
        key = _key;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() external view override returns (int256) {
        (
            uint256 price,
            uint256 lastUpdateTimeStamp
        ) = priceFeed.getValue(key);
        return int256(price);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface DiaKeyValueInterface {
    function getValue(string memory key)
        external
        view
        returns (uint128, uint128);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./DiaCoinInfoInterface.sol";
import "./interfaces/IPrice.sol";

contract DiaCoinInfo is IPrice {
    DiaCoinInfoInterface internal priceFeed;

    string public name;

    constructor(address _aggregator, string memory _name) public {
        priceFeed = DiaCoinInfoInterface(_aggregator);
        name = _name;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() external view override returns (int256) {
        (
            uint256 price,
            uint256 supply,
            uint256 lastUpdateTimeStamp,
            string memory symbol
        ) = priceFeed.getCoinInfo(name);
        return int256(price);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface DiaCoinInfoInterface {
    function getCoinInfo(string memory name) external view returns (uint256, uint256, uint256, string memory);
}