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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {Errors} from "src/libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";
import {IKIBToken} from "src/interfaces/IKIBToken.sol";
import {IKIBTFeeCollector} from "src/interfaces/IKIBTFeeCollector.sol";
import {IKUMASwap} from "src/interfaces/IKUMASwap.sol";
import {Roles} from "src/libraries/Roles.sol";

contract KIBTAddressProvider is IKIBTAddressProvider {
    IAccessControl public immutable override accessController;

    address private _KBCToken;
    address private _priceFeed;
    address private _KUMABondToken;

    mapping(bytes32 => address) private _KIBToken;
    mapping(bytes32 => address) private _KUMASwap;
    mapping(bytes32 => address) private _KIBTfeeCollector;

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _;
    }

    modifier onlyManager() {
        if (!accessController.hasRole(Roles.MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.MANAGER_ROLE);
        }
        _;
    }

    constructor(IAccessControl _accessController) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        accessController = _accessController;
    }

    function setKBCToken(address KBCToken) external override onlyManager onlyValidAddress(KBCToken) {
        _KBCToken = KBCToken;
    }

    function setRateFeed(address priceFeed) external override onlyManager onlyValidAddress(priceFeed) {
        _priceFeed = priceFeed;
    }

    function setKUMABondToken(address KUMABondToken) external override onlyManager onlyValidAddress(KUMABondToken) {
        _KUMABondToken = KUMABondToken;
    }

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken)
        external
        override
        onlyManager
        onlyValidAddress(KIBToken)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKIBToken(KIBToken).riskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KIBToken[riskCategory] = KIBToken;
    }

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap)
        external
        override
        onlyManager
        onlyValidAddress(KUMASwap)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKUMASwap(KUMASwap).riskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KUMASwap[riskCategory] = KUMASwap;
    }

    function setKIBTFeeCollector(bytes4 currency, bytes4 country, uint64 term, address feeCollector)
        external
        override
        onlyManager
        onlyValidAddress(feeCollector)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKIBTFeeCollector(feeCollector).riskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KIBTfeeCollector[riskCategory] = feeCollector;
    }

    function getKBCToken() external view override returns (address) {
        return _KBCToken;
    }

    function getRateFeed() external view override returns (address) {
        return _priceFeed;
    }

    function getKUMABondToken() external view override returns (address) {
        return _KUMABondToken;
    }

    function getKIBToken(bytes32 riskCategory) external view override returns (address) {
        return _KIBToken[riskCategory];
    }

    function getKUMASwap(bytes32 riskCategory) external view override returns (address) {
        return _KUMASwap[riskCategory];
    }

    function getKIBTFeeCollector(bytes32 riskCategory) external view override returns (address) {
        return _KIBTfeeCollector[riskCategory];
    }

    function _checkRiskCategory(bytes4 currency, bytes4 country, uint64 term) internal pure returns (bytes32) {
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.INVALID_RISK_CATEGORY();
        }
        return keccak256(abi.encode(currency, country, term));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IKIBTAddressProvider {
    event KIBTokenSet(address KIBToken);

    event KUMABondTokenSet(address KUMABondToken);

    event KBCTokenSet(address KBCToken);

    event KUMASwapSet(address KUMASwap);

    function setKUMABondToken(address KUMABondToken) external;

    function setKBCToken(address KBCToken) external;

    function setRateFeed(address priceFeed) external;

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken) external;

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap) external;

    function setKIBTFeeCollector(bytes4 currency, bytes4 country, uint64 term, address feeCollector) external;

    function accessController() external view returns (IAccessControl);

    function getKUMABondToken() external view returns (address);

    function getRateFeed() external view returns (address);

    function getKBCToken() external view returns (address);

    function getKIBToken(bytes32 riskCategory) external view returns (address);

    function getKUMASwap(bytes32 riskCategory) external view returns (address);

    function getKIBTFeeCollector(bytes32 riskCategory) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";

interface IKIBTFeeCollector {
    event PayeeAdded(address indexed payee, uint256 share);
    event PayeeRemoved(address indexed payee);
    event FeeReleased(uint256 income);
    event ShareUpdated(address indexed payee, uint256 newShare);

    function KIBTAddressProvider() external returns (IKIBTAddressProvider);

    function riskCategory() external returns (bytes32);

    function release() external;

    function addPayee(address payee, uint256 share) external;

    function removePayee(address payee) external;

    function updatePayeeShare(address payee, uint256 share) external;

    function changePayees(address[] calldata newPayees, uint256[] calldata newShares) external;

    function getPayees() external view returns (address[] memory);

    function getTotalShares() external view returns (uint256);

    function getShare(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";
import {IMCAGRateFeed} from "src/interfaces/IMCAGRateFeed.sol";

interface IKIBToken is IERC20Metadata {
    event YieldUpdated(uint256 oldYield, uint256 newYield);

    event CumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);

    event EpochLengthSet(uint256 previousEpochLength, uint256 newEpochLength);

    function setEpochLength(uint256 epochLength) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function refreshYield() external;

    function KIBTAddressProvider() external returns (IKIBTAddressProvider);

    function riskCategory() external view returns (bytes32);

    function getYield() external view returns (uint256);

    function getTotalBaseSupply() external view returns (uint256);

    function getBaseBalance(address account) external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getLastRefresh() external view returns (uint256);

    function getCumulativeYield() external view returns (uint256);

    function getUpdatedCumulativeYield() external view returns (uint256);

    function getPreviousEpochTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";

interface IKUMASwap is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 ghostTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event GhostCouponSet(uint256 tokenId, uint256 ghostCoupon);
    event IncomeClaimed(uint256 claimedIncome);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event MinGasSet(uint256 oldMinGas, uint256 newMinGas);
    event ReferenceRateSet(uint256 referenceRate);
    event MIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);

    function sellBond(uint256 tokenId) external;

    function buyBond(uint256 tokenId) external;

    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimBond(uint256 tokenId) external;

    function redeemMIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function updateCloneBondCoupons() external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setMinGas(uint256 minGas) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function setReferenceRate(uint256 referenceRate) external;

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint56);

    function isDeprecated() external view returns (bool);

    function maxCoupons() external view returns (uint16);

    function riskCategory() external view returns (bytes32);

    function KIBTAddressProvider() external view returns (IKIBTAddressProvider);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinGas() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getReferenceRate() external view returns (uint256);

    function getGhostCouponUpdateTracker() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getCouponIndex(uint256 coupon) external view returns (uint256);

    function getBondReserve() external view returns (uint256[] memory);

    function getBondIndex(uint256 tokenId) external view returns (uint256);

    function getGhostBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getCloneCoupon(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGRateFeed {
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