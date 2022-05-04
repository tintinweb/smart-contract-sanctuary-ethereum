// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/vault-interfaces/src/IOracle.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastBytes32Bytes6.sol";

import "./ICurvePool.sol";
import "../chainlink/AggregatorV3Interface.sol";

// Oracle Code Inspiration: https://github.com/Abracadabra-money/magic-internet-money/blob/main/contracts/oracles/3CrvOracle.sol
/**
 *@title  Cvx3CrvOracle
 *@notice Provides current values for Cvx3Crv
 *@dev    Both peek() (view) and get() (transactional) are provided for convenience
 */
contract Cvx3CrvOracle is IOracle, AccessControl {
    using CastBytes32Bytes6 for bytes32;
    ICurvePool public threecrv;
    AggregatorV3Interface public DAI;
    AggregatorV3Interface public USDC;
    AggregatorV3Interface public USDT;

    bytes32 public cvx3CrvId;
    bytes32 public ethId;

    event SourceSet(
        bytes32 cvx3CrvId_,
        bytes32 ethId_,
        ICurvePool threecrv_,
        AggregatorV3Interface DAI_,
        AggregatorV3Interface USDC_,
        AggregatorV3Interface USDT_
    );

    /**
     *@notice Set threecrv pool and the chainlink sources
     *@param  cvx3CrvId_ cvx3crv Id
     *@param  ethId_ ETH ID
     *@param  threecrv_ The 3CRV pool address
     *@param  DAI_ DAI/ETH chainlink price feed address
     *@param  USDC_ USDC/ETH chainlink price feed address
     *@param  USDT_ USDT/ETH chainlink price feed address
     */
    function setSource(
        bytes32 cvx3CrvId_,
        bytes32 ethId_,
        ICurvePool threecrv_,
        AggregatorV3Interface DAI_,
        AggregatorV3Interface USDC_,
        AggregatorV3Interface USDT_
    ) external auth {
        cvx3CrvId = cvx3CrvId_;
        ethId = ethId_;
        threecrv = threecrv_;
        DAI = DAI_;
        USDC = USDC_;
        USDT = USDT_;
        emit SourceSet(cvx3CrvId_, ethId_, threecrv_, DAI_, USDC_, USDT_);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @dev Only cvx3crvid and ethId are accepted as asset identifiers.
     * @param base Id of base token
     * @param quote Id of quoted token
     * @param baseAmount Amount of base token for which to get a quote
     * @return quoteAmount Total amount in terms of quoted token
     * @return updateTime Time quote was last updated
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    ) external view virtual override returns (uint256 quoteAmount, uint256 updateTime) {
        (quoteAmount, updateTime) = _peek(base.b6(), quote.b6(), baseAmount);
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price. Same as `peek` for this oracle.
     * @dev Only cvx3crvid and ethId are accepted as asset identifiers.
     * @param base Id of base token
     * @param quote Id of quoted token
     * @param baseAmount Amount of base token for which to get a quote
     * @return quoteAmount Total amount in terms of quoted token
     * @return updateTime Time quote was last updated
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 baseAmount
    ) external virtual override returns (uint256 quoteAmount, uint256 updateTime) {
        (quoteAmount, updateTime) = _peek(base.b6(), quote.b6(), baseAmount);
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @dev Only cvx3crvid and ethId are accepted as asset identifiers.
     * @param base Id of base token
     * @param quote Id of quoted token
     * @param baseAmount Amount of base token for which to get a quote
     * @return quoteAmount Total amount in terms of quoted token
     * @return updateTime Time quote was last updated
     */
    function _peek(
        bytes6 base,
        bytes6 quote,
        uint256 baseAmount
    ) private view returns (uint256 quoteAmount, uint256 updateTime) {
        bytes32 cvx3CrvId_ = cvx3CrvId;
        bytes32 ethId_ = ethId;
        require(
            (base == ethId_ && quote == cvx3CrvId_) || (base == cvx3CrvId_ && quote == ethId_),
            "Invalid quote or base"
        );

        uint80 roundId;
        uint80 answeredInRound;
        int256 daiPrice;
        int256 usdcPrice;
        int256 usdtPrice;

        // DAI Price
        (roundId, daiPrice, , updateTime, answeredInRound) = DAI.latestRoundData();
        require(daiPrice > 0, "Chainlink DAI price <= 0");
        require(updateTime > 0, "Incomplete round for DAI");
        require(answeredInRound >= roundId, "Stale price for DAI");

        // USDC Price
        (roundId, usdcPrice, , updateTime, answeredInRound) = USDC.latestRoundData();
        require(usdcPrice > 0, "Chainlink USDC price <= 0");
        require(updateTime > 0, "Incomplete round for USDC");
        require(answeredInRound >= roundId, "Stale price for USDC");

        // USDT Price
        (roundId, usdtPrice, , updateTime, answeredInRound) = USDT.latestRoundData();
        require(usdtPrice > 0, "Chainlink USDT price <= 0");
        require(updateTime > 0, "Incomplete round for USDT");
        require(answeredInRound >= roundId, "Stale price for USDT");

        // This won't overflow as the max value for int256 is less than the max value for uint256
        uint256 minStable = min(uint256(daiPrice), min(uint256(usdcPrice), uint256(usdtPrice)));

        uint256 price = (threecrv.get_virtual_price() * minStable) / 1e18;

        if (base == cvx3CrvId_) {
            quoteAmount = (baseAmount * price) / 1e18;
        } else {
            quoteAmount = (baseAmount * 1e18) / price;
        }

        updateTime = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
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
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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