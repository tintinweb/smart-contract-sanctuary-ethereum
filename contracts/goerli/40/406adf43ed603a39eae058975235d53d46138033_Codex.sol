/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity ^0.8.4;

interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function lock() external;
}interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

interface IVault {
    function codex() external view returns (ICodex);

    function collybus() external view returns (ICollybus);

    function token() external view returns (address);

    function tokenScale() external view returns (uint256);

    function underlierToken() external view returns (address);

    function underlierScale() external view returns (uint256);

    function vaultType() external view returns (bytes32);

    function live() external view returns (uint256);

    function lock() external;

    function setParam(bytes32 param, address data) external;

    function maturity(uint256 tokenId) external returns (uint256);

    function fairPrice(
        uint256 tokenId,
        bool net,
        bool face
    ) external view returns (uint256);

    function enter(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;

    function exit(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;
}
interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}
/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */
/// @title Codex
/// @notice `Codex` is responsible for the accounting of collateral and debt balances
/// Uses Vat.sol from DSS (MakerDAO) / SafeEngine.sol from GEB (Reflexer Labs) as a blueprint
/// Changes from Vat.sol / SafeEngine.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract Codex is Guarded, ICodex {
    /// ======== Custom Errors ======== ///

    error Codex__init_vaultAlreadyInit();
    error Codex__setParam_notLive();
    error Codex__setParam_unrecognizedParam();
    error Codex__transferBalance_notAllowed();
    error Codex__transferCredit_notAllowed();
    error Codex__modifyCollateralAndDebt_notLive();
    error Codex__modifyCollateralAndDebt_vaultNotInit();
    error Codex__modifyCollateralAndDebt_ceilingExceeded();
    error Codex__modifyCollateralAndDebt_notSafe();
    error Codex__modifyCollateralAndDebt_notAllowedSender();
    error Codex__modifyCollateralAndDebt_notAllowedCollateralizer();
    error Codex__modifyCollateralAndDebt_notAllowedDebtor();
    error Codex__modifyCollateralAndDebt_debtFloor();
    error Codex__transferCollateralAndDebt_notAllowed();
    error Codex__transferCollateralAndDebt_notSafeSrc();
    error Codex__transferCollateralAndDebt_notSafeDst();
    error Codex__transferCollateralAndDebt_debtFloorSrc();
    error Codex__transferCollateralAndDebt_debtFloorDst();
    error Codex__modifyRate_notLive();

    /// ======== Storage ======== ///

    // Vault Data
    struct Vault {
        // Total Normalised Debt in Vault [wad]
        uint256 totalNormalDebt;
        // Vault's Accumulation Rate [wad]
        uint256 rate;
        // Vault's Debt Ceiling [wad]
        uint256 debtCeiling;
        // Debt Floor for Positions corresponding to this Vault [wad]
        uint256 debtFloor;
    }
    // Position Data
    struct Position {
        // Locked Collateral in Position [wad]
        uint256 collateral;
        // Normalised Debt (gross debt before rate is applied) generated by Position [wad]
        uint256 normalDebt;
    }

    /// @notice Map of delegatees who can modify collateral, debt and credit on behalf of a delegator
    /// @dev Delegator => Delegatee => hasDelegate
    mapping(address => mapping(address => uint256)) public override delegates;
    /// @notice Vaults
    /// @dev Vault => Vault Data
    mapping(address => Vault) public override vaults;
    /// @notice Positions
    /// @dev Vault => TokenId => Owner => Position
    mapping(address => mapping(uint256 => mapping(address => Position))) public override positions;
    /// @notice Token balances not put up for collateral in a Position
    /// @dev Vault => TokenId => Owner => Balance [wad]
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override balances;
    /// @notice Credit balances
    /// @dev Account => Credit [wad]
    mapping(address => uint256) public override credit;
    /// @notice Unbacked Debt balances
    /// @dev Account => Unbacked Debt [wad]
    mapping(address => uint256) public override unbackedDebt;

    /// @notice Global Debt (incl. rate) outstanding == Credit Issued [wad]
    uint256 public override globalDebt;
    /// @notice Global Unbacked Debt (incl. rate) oustanding == Total Credit [wad]
    uint256 public override globalUnbackedDebt;
    /// @notice Global Debt Ceiling [wad]
    uint256 public override globalDebtCeiling;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public live;

    /// ======== Events ======== ///
    event Init(address indexed vault);
    event SetParam(address indexed vault, bytes32 indexed param, uint256 data);
    event GrantDelegate(address indexed delegator, address indexed delegatee);
    event RevokeDelegate(address indexed delegator, address indexed delegatee);
    event ModifyBalance(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        int256 amount,
        uint256 balance
    );
    event TransferBalance(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed src,
        address dst,
        uint256 amount,
        uint256 srcBalance,
        uint256 dstBalance
    );
    event TransferCredit(
        address indexed src,
        address indexed dst,
        uint256 amount,
        uint256 srcCredit,
        uint256 dstCredit
    );
    event ModifyCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event TransferCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event ConfiscateCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event SettleUnbackedDebt(address indexed debtor, uint256 debt);
    event CreateUnbackedDebt(address indexed debtor, address indexed creditor, uint256 debt);
    event ModifyRate(address indexed vault, address indexed creditor, int256 deltaRate);
    event Lock();

    constructor() Guarded() {
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Initializes a new Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    function init(address vault) external override checkCaller {
        if (vaults[vault].rate != 0) revert Codex__init_vaultAlreadyInit();
        vaults[vault].rate = WAD;
        emit Init(vault);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (live == 0) revert Codex__setParam_notLive();
        if (param == "globalDebtCeiling") globalDebtCeiling = data;
        else revert Codex__setParam_unrecognizedParam();
        emit SetParam(address(0), param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external override checkCaller {
        if (live == 0) revert Codex__setParam_notLive();
        if (param == "debtCeiling") vaults[vault].debtCeiling = data;
        else if (param == "debtFloor") vaults[vault].debtFloor = data;
        else revert Codex__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// ======== Caller Delegation ======== ///

    /// @notice Grants the delegatee the ability to modify collateral, debt and credit balances on behalf of the caller
    /// @param delegatee Address of the delegatee
    function grantDelegate(address delegatee) external override {
        delegates[msg.sender][delegatee] = 1;
        emit GrantDelegate(msg.sender, delegatee);
    }

    /// @notice Revokes the delegatee's ability to modify collateral, debt and credit balances on behalf of the caller
    /// @param delegatee Address of the delegatee
    function revokeDelegate(address delegatee) external override {
        delegates[msg.sender][delegatee] = 0;
        emit RevokeDelegate(msg.sender, delegatee);
    }

    /// @notice Checks the delegate
    /// @param delegator Address of the delegator
    /// @param delegatee Address of the delegatee
    /// @return True if delegate is granted
    function hasDelegate(address delegator, address delegatee) internal view returns (bool) {
        return delegator == delegatee || delegates[delegator][delegatee] == 1;
    }

    /// ======== Credit and Token Balance Administration ======== ///

    /// @notice Updates the token balance for a `user`
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param amount Amount to add (positive) or subtract (negative) [wad]
    function modifyBalance(
        address vault,
        uint256 tokenId,
        address user,
        int256 amount
    ) external override checkCaller {
        balances[vault][tokenId][user] = add(balances[vault][tokenId][user], amount);
        emit ModifyBalance(vault, tokenId, user, amount, balances[vault][tokenId][user]);
    }

    /// @notice Transfer an `amount` of tokens from `src` to `dst`
    /// @dev Sender has to be delegated by `src`
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param src From address
    /// @param dst To address
    /// @param amount Amount to be transferred [wad]
    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external override {
        if (!hasDelegate(src, msg.sender)) revert Codex__transferBalance_notAllowed();
        balances[vault][tokenId][src] = sub(balances[vault][tokenId][src], amount);
        balances[vault][tokenId][dst] = add(balances[vault][tokenId][dst], amount);
        emit TransferBalance(
            vault,
            tokenId,
            src,
            dst,
            amount,
            balances[vault][tokenId][src],
            balances[vault][tokenId][dst]
        );
    }

    /// @notice Transfer an `amount` of Credit from `src` to `dst`
    /// @dev Sender has to be delegated by `src`
    /// @param src From address
    /// @param dst To address
    /// @param amount Amount to be transferred [wad]
    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external override {
        if (!hasDelegate(src, msg.sender)) revert Codex__transferCredit_notAllowed();
        credit[src] = sub(credit[src], amount);
        credit[dst] = add(credit[dst], amount);
        emit TransferCredit(src, dst, amount, credit[src], credit[dst]);
    }

    /// ======== Position Administration ======== ///

    /// @notice Modifies a Position's collateral and debt balances
    /// @dev Checks that the global debt ceiling and the vault's debt ceiling have not been exceeded,
    /// that the Position is still safe after the modification,
    /// that the sender is delegated by the owner if the collateral-to-debt ratio decreased,
    /// that the sender is delegated by the collateralizer if new collateral is put up,
    /// that the sender is delegated by the creditor if debt is settled,
    /// and that the vault debt floor is exceeded
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param creditor Address of who provides or receives the credit delta for the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override {
        // system is live
        if (live == 0) revert Codex__modifyCollateralAndDebt_notLive();

        Position memory p = positions[vault][tokenId][user];
        Vault memory v = vaults[vault];
        // vault has been initialised
        if (v.rate == 0) revert Codex__modifyCollateralAndDebt_vaultNotInit();

        p.collateral = add(p.collateral, deltaCollateral);
        p.normalDebt = add(p.normalDebt, deltaNormalDebt);
        v.totalNormalDebt = add(v.totalNormalDebt, deltaNormalDebt);

        int256 deltaDebt = wmul(v.rate, deltaNormalDebt);
        uint256 debt = wmul(v.rate, p.normalDebt);
        globalDebt = add(globalDebt, deltaDebt);

        // either debt has decreased, or debt ceilings are not exceeded
        if (deltaNormalDebt > 0 && (wmul(v.totalNormalDebt, v.rate) > v.debtCeiling || globalDebt > globalDebtCeiling))
            revert Codex__modifyCollateralAndDebt_ceilingExceeded();
        // position is either less risky than before, or it is safe
        if (
            (deltaNormalDebt > 0 || deltaCollateral < 0) &&
            debt > wmul(p.collateral, IVault(vault).fairPrice(tokenId, true, false))
        ) revert Codex__modifyCollateralAndDebt_notSafe();

        // position is either more safe, or the owner consents
        if ((deltaNormalDebt > 0 || deltaCollateral < 0) && !hasDelegate(user, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedSender();
        // collateralizer consents if new collateral is put up
        if (deltaCollateral > 0 && !hasDelegate(collateralizer, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedCollateralizer();

        // creditor consents if debt is settled with credit
        if (deltaNormalDebt < 0 && !hasDelegate(creditor, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedDebtor();

        // position has no debt, or a non-dusty amount
        if (p.normalDebt != 0 && debt < v.debtFloor) revert Codex__modifyCollateralAndDebt_debtFloor();

        balances[vault][tokenId][collateralizer] = sub(balances[vault][tokenId][collateralizer], deltaCollateral);
        credit[creditor] = add(credit[creditor], deltaDebt);

        positions[vault][tokenId][user] = p;
        vaults[vault] = v;

        emit ModifyCollateralAndDebt(vault, tokenId, user, collateralizer, creditor, deltaCollateral, deltaNormalDebt);
    }

    /// @notice Transfers a Position's collateral and debt balances to another Position
    /// @dev Checks that the sender is delegated by `src` and `dst` Position owners,
    /// that the `src` and `dst` Positions are still safe after the transfer,
    /// and that the `src` and `dst` Positions' debt exceed the vault's debt floor
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param src Address of the `src` Positions owner
    /// @param dst Address of the `dst` Positions owner
    /// @param deltaCollateral Amount of collateral to send to (+) or from (-) the `src` Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to send to (+) or
    /// from (-) the `dst` Position [wad]
    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override {
        Position storage pSrc = positions[vault][tokenId][src];
        Position storage pDst = positions[vault][tokenId][dst];
        Vault storage v = vaults[vault];

        pSrc.collateral = sub(pSrc.collateral, deltaCollateral);
        pSrc.normalDebt = sub(pSrc.normalDebt, deltaNormalDebt);
        pDst.collateral = add(pDst.collateral, deltaCollateral);
        pDst.normalDebt = add(pDst.normalDebt, deltaNormalDebt);

        uint256 debtSrc = wmul(pSrc.normalDebt, v.rate);
        uint256 debtDst = wmul(pDst.normalDebt, v.rate);

        // both sides consent
        if (!hasDelegate(src, msg.sender) || !hasDelegate(dst, msg.sender))
            revert Codex__transferCollateralAndDebt_notAllowed();

        // both sides safe
        if (debtSrc > wmul(pSrc.collateral, IVault(vault).fairPrice(tokenId, true, false)))
            revert Codex__transferCollateralAndDebt_notSafeSrc();
        if (debtDst > wmul(pDst.collateral, IVault(vault).fairPrice(tokenId, true, false)))
            revert Codex__transferCollateralAndDebt_notSafeDst();

        // both sides non-dusty
        if (pSrc.normalDebt != 0 && debtSrc < v.debtFloor) revert Codex__transferCollateralAndDebt_debtFloorSrc();
        if (pDst.normalDebt != 0 && debtDst < v.debtFloor) revert Codex__transferCollateralAndDebt_debtFloorDst();

        emit TransferCollateralAndDebt(vault, tokenId, src, dst, deltaCollateral, deltaNormalDebt);
    }

    /// @notice Confiscates a Position's collateral and debt balances
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param debtor Address of who provides or receives the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override checkCaller {
        Position storage position = positions[vault][tokenId][user];
        Vault storage v = vaults[vault];

        position.collateral = add(position.collateral, deltaCollateral);
        position.normalDebt = add(position.normalDebt, deltaNormalDebt);
        v.totalNormalDebt = add(v.totalNormalDebt, deltaNormalDebt);

        int256 deltaDebt = wmul(v.rate, deltaNormalDebt);

        balances[vault][tokenId][collateralizer] = sub(balances[vault][tokenId][collateralizer], deltaCollateral);
        unbackedDebt[debtor] = sub(unbackedDebt[debtor], deltaDebt);
        globalUnbackedDebt = sub(globalUnbackedDebt, deltaDebt);

        emit ConfiscateCollateralAndDebt(
            vault,
            tokenId,
            user,
            collateralizer,
            debtor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// ======== Unbacked Debt ======== ///

    /// @notice Settles unbacked debt with the sender's credit
    /// @dev Reverts if the sender does not have sufficient credit available to settle the debt
    /// @param debt Amount of debt to settle [wawd]
    function settleUnbackedDebt(uint256 debt) external override {
        address debtor = msg.sender;
        unbackedDebt[debtor] = sub(unbackedDebt[debtor], debt);
        credit[debtor] = sub(credit[debtor], debt);
        globalUnbackedDebt = sub(globalUnbackedDebt, debt);
        globalDebt = sub(globalDebt, debt);
        emit SettleUnbackedDebt(debtor, debt);
    }

    /// @notice Create unbacked debt / credit
    /// @dev Sender has to be allowed to call this method
    /// @param debtor Address of the account who takes the unbacked debt
    /// @param creditor Address of the account who gets the credit
    /// @param debt Amount of unbacked debt / credit to generate [wad]
    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external override checkCaller {
        unbackedDebt[debtor] = add(unbackedDebt[debtor], debt);
        credit[creditor] = add(credit[creditor], debt);
        globalUnbackedDebt = add(globalUnbackedDebt, debt);
        globalDebt = add(globalDebt, debt);
        emit CreateUnbackedDebt(debtor, creditor, debt);
    }

    /// ======== Debt Interest Rates ======== ///

    /// @notice Updates the rate value and collects the accrued interest for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the vault
    /// @param creditor Address of the account who gets the accrued interest
    /// @param deltaRate Delta to increase (+) or decrease (-) the rate [percentage in wad]
    function modifyRate(
        address vault,
        address creditor,
        int256 deltaRate
    ) external override checkCaller {
        if (live == 0) revert Codex__modifyRate_notLive();
        Vault storage v = vaults[vault];
        v.rate = add(v.rate, deltaRate);
        int256 wad = wmul(v.totalNormalDebt, deltaRate);
        credit[creditor] = add(credit[creditor], wad);
        globalDebt = add(globalDebt, wad);
        emit ModifyRate(vault, creditor, deltaRate);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        emit Lock();
    }
}