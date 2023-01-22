// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface MCAGAggregatorInterface {
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function maxAnswer() external view returns (int256);

    function version() external view returns (uint8);

    function transmit(int256 answer) external;

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {Errors} from "src/libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IMCAGPriceFeed} from "src/interfaces/IMCAGPriceFeed.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";
import {Roles} from "src/libraries/Roles.sol";
import {WadRayMath} from "src/libraries/WadRayMath.sol";

contract MCAGPriceFeed is IMCAGPriceFeed {
    uint256 private constant _MIN_RATE_COUPON = WadRayMath.RAY;
    uint8 private constant _DECIMALS = 27;

    IAccessControl public immutable override accessController;

    mapping(bytes32 => MCAGAggregatorInterface) private _oracles;

    /**
     * @param _accessController KUMA DAO AccessController.
     */
    constructor(IAccessControl _accessController) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        accessController = _accessController;
    }

    /**
     * @notice Set an MCAGAggregator for a specific risk category.
     * @dev There is no need for staleness check as central bank rate is rarely updated.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10  * years
     */
    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle)
        external
        override
    {
        if (!accessController.hasRole(Roles.MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.MANAGER_ROLE);
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        if (address(oracle) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }

        bytes32 riskCategory = keccak256(abi.encode(currency, country, term));
        _oracles[riskCategory] = oracle;

        emit OracleSet(riskCategory, address(oracle));
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return rate Oracle rate in 27 decimals.
     */
    function getRate(bytes32 riskCategory) external view override returns (uint256) {
        MCAGAggregatorInterface oracle = _oracles[riskCategory];
        (, int256 answer,,,) = oracle.latestRoundData();

        if (answer < 0) {
            return _MIN_RATE_COUPON;
        }

        uint256 rate = uint256(answer);
        uint8 oracleDecimal = oracle.decimals();

        if (_DECIMALS < oracleDecimal) {
            rate = uint256(answer) / (10 ** (oracleDecimal - _DECIMALS));
        } else if (_DECIMALS > oracleDecimal) {
            rate = uint256(answer) * 10 ** (_DECIMALS - oracleDecimal);
        }

        if (rate < _MIN_RATE_COUPON) {
            return _MIN_RATE_COUPON;
        }

        return rate;
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return MCAGAggregator for a specific risk category.
     */
    function getOracle(bytes32 riskCategory) external view override returns (MCAGAggregatorInterface) {
        return _oracles[riskCategory];
    }

    /**
     * @return Minimum acceptable rate.
     */
    function minRateCoupon() external pure override returns (uint256) {
        return _MIN_RATE_COUPON;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGPriceFeed {
    event OracleSet(bytes32 indexed riskCategory, address oracle);

    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle) external;

    function minRateCoupon() external view returns (uint256);

    function decimals() external view returns (uint8);

    function accessController() external view returns (IAccessControl);

    function getRate(bytes32 riskCategory) external view returns (uint256);

    function getOracle(bytes32 riskCategory) external view returns (MCAGAggregatorInterface);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Errors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error CANNOT_SET_TO_ZERO();
    error ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
    error ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
    error ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
    error ERC20_MINT_TO_THE_ZERO_ADDRESS();
    error ERC20_BURN_FROM_THE_ZERO_ADDRESS();
    error ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
    error START_TIME_NOT_REACHED();
    error EPOCH_LENGTH_CANNOT_BE_ZERO();
    error ERROR_YIELD_LT_RAY();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLISTABLE_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLISTABLE_ACCOUNT_IS_BLACKLISTED(address account);
    error NEW_YIELD_TOO_HIGH();
    error NEW_EPOCH_LENGTH_TOO_HIGH();
    error WRONG_RISK_CATEGORY();
    error WRONG_RISK_CONFIG();
    error INVALID_RISK_CATEGORY();
    error INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error CALLER_NOT_KUMASWAP();
    error CALLER_NOT_MIMO_BOND_TOKEN();
    error BOND_NOT_AVAILABLE_FOR_CLAIM();
    error CANNOT_SELL_MATURED_BOND();
    error NO_EXPIRED_BOND_IN_RESERVE();
    error MAX_COUPONS_REACHED();
    error COUPON_TOO_LOW();
    error CALLER_IS_NOT_MIB_TOKEN();
    error CALLER_NOT_FEE_COLLECTOR();
    error PAYEE_ALREADY_EXISTS();
    error PAYEE_DOES_NOT_EXIST();
    error PAYEES_AND_SHARES_MISMATCHED(uint256 payeeLength, uint256 shareLength);
    error NO_PAYEES();
    error NO_AVAILABLE_INCOME();
    error SHARE_CANNOT_BE_ZERO();
    error DEPRECATION_MODE_ENABLED();
    error DEPRECATION_MODE_ALREADY_INITIALIZED();
    error DEPRECATION_MODE_NOT_INITIALIZED();
    error DEPRECATION_MODE_NOT_ENABLED();
    error ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(uint256 elapsed, uint256 minElapsedTime);
    error AMOUNT_CANNOT_BE_ZERO();
    error BOND_RESERVE_NOT_EMPTY();
    error BUYER_CANNOT_BE_ADDRESS_ZERO();
    error RISK_CATEGORY_MISMATCH();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Roles {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MIBT_MINT_ROLE = keccak256("MIBT_MINT_ROLE");
    bytes32 public constant MIBT_BURN_ROLE = keccak256("MIBT_BURN_ROLE");
    bytes32 public constant MIBT_SET_EPOCH_LENGTH_ROLE = keccak256("MIBT_SET_EPOCH_LENGTH_ROLE");
    bytes32 public constant MIBT_SWAP_CLAIM_ROLE = keccak256("MIBT_SWAP_CLAIM_ROLE");
    bytes32 public constant MIBT_SWAP_PAUSE_ROLE = keccak256("MIBT_SWAP_PAUSE_ROLE");
    bytes32 public constant MIBT_SWAP_UNPAUSE_ROLE = keccak256("MIBT_SWAP_UNPAUSE_ROLE");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 *
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     *
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     *
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) { revert(0, 0) }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     *
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     *
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) { revert(0, 0) }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     *
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) { b := add(b, 1) }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     *
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) { revert(0, 0) }
        }
    }

    /**
     * @dev calculates base^exp. The code uses the ModExp precompile
     * @return z base^exp, in ray
     *
     */
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}