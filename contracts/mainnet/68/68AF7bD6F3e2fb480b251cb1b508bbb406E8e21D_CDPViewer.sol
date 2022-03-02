// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

import "../interfaces/IVault.sol";
import "../interfaces/IVaultParameters.sol";
import "../interfaces/vault-managers/parameters/IVaultManagerParameters.sol";
import "../interfaces/vault-managers/parameters/IVaultManagerBorrowFeeParameters.sol";
import "../interfaces/IOracleRegistry.sol";
import "../interfaces/wrapped-assets/IWrappedAsset.sol";
import "./IUniswapV2PairFull.sol";
import "./ERC20Like.sol";


/**
 * @notice Views collaterals in one request to save node requests and speed up dapps.
 */
contract CDPViewer {

    IVault public immutable vault;
    IVaultParameters public immutable vaultParameters;
    IVaultManagerParameters public immutable vaultManagerParameters;
    IVaultManagerBorrowFeeParameters public immutable vaultManagerBorrowFeeParameters;
    IOracleRegistry public immutable oracleRegistry;

    struct CDP {

        // Collateral amount
        uint128 collateral;

        // Debt amount
        uint128 debt;

        // Debt + accrued stability fee
        uint totalDebt;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        uint32 lastUpdate;

        // Percentage with 0 decimals
        uint16 liquidationFee;

        uint16 oracleType;
    }

    struct CollateralParameters {

        // USDP mint limit
        uint128 tokenDebtLimit;

        // USDP mint limit
        uint128 tokenDebt;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        // Percentage with 3 decimals
        uint32 liquidationDiscount;

        // Devaluation period in blocks
        uint32 devaluationPeriod;

        // Percentage with 0 decimals
        uint16 liquidationRatio;

        // Percentage with 0 decimals
        uint16 initialCollateralRatio;

        // Percentage with 0 decimals
        uint16 liquidationFee;

        // Oracle types enabled for this asset
        uint16 oracleType;

        // Percentage with 2 decimals (basis points)
        uint16 borrowFee;

        CDP cdp;
    }

    struct TokenDetails {
        address[2] lpUnderlyings;
        uint128 balance;
        uint128 totalSupply;
        uint8 decimals;
        address uniswapV2Factory;

        address underlyingToken;
        uint256 underlyingTokenBalance;
        uint256 underlyingTokenTotalSupply;
        uint8 underlyingTokenDecimals;
        address underlyingTokenUniswapV2Factory;
        address[2] underlyingTokenUnderlyings;

    }


    constructor(address _vaultManagerParameters, address _oracleRegistry, address _vaultManagerBorrowFeeParameters) {
         IVaultManagerParameters vmp = IVaultManagerParameters(_vaultManagerParameters);
         vaultManagerParameters = vmp;
         IVaultParameters vp = IVaultParameters(vmp.vaultParameters());
         vaultParameters = vp;
         vault = IVault(vp.vault());
         oracleRegistry = IOracleRegistry(_oracleRegistry);
         vaultManagerBorrowFeeParameters = IVaultManagerBorrowFeeParameters(_vaultManagerBorrowFeeParameters);
    }

    /**
     * @notice Get parameters of one asset
     * @param asset asset address
     * @param owner owner address
     */
    function getCollateralParameters(address asset, address owner)
        public
        view
        returns (CollateralParameters memory r)
    {
        r.stabilityFee = uint32(vaultParameters.stabilityFee(asset));
        r.liquidationFee = uint16(vaultParameters.liquidationFee(asset));
        r.initialCollateralRatio = uint16(vaultManagerParameters.initialCollateralRatio(asset));
        r.liquidationRatio = uint16(vaultManagerParameters.liquidationRatio(asset));
        r.liquidationDiscount = uint32(vaultManagerParameters.liquidationDiscount(asset));
        r.devaluationPeriod = uint32(vaultManagerParameters.devaluationPeriod(asset));

        r.tokenDebtLimit = uint128(vaultParameters.tokenDebtLimit(asset));
        r.tokenDebt = uint128(vault.tokenDebts(asset));
        r.oracleType = uint16(oracleRegistry.oracleTypeByAsset(asset));

        r.borrowFee = vaultManagerBorrowFeeParameters.getBorrowFee(asset);

        if (owner == address(0)) return r;
        r.cdp.stabilityFee = uint32(vault.stabilityFee(asset, owner));
        r.cdp.liquidationFee = uint16(vault.liquidationFee(asset, owner));
        r.cdp.debt = uint128(vault.debts(asset, owner));
        r.cdp.totalDebt = vault.getTotalDebt(asset, owner);
        r.cdp.collateral = uint128(vault.collaterals(asset, owner));
        r.cdp.lastUpdate = uint32(vault.lastUpdate(asset, owner));
        r.cdp.oracleType = uint16(vault.oracleType(asset, owner));
    }

    /**
     * @notice Get details of one token
     * @param asset token address
     * @param owner owner address
     */
    function getTokenDetails(address asset, address owner)
        public
        view
        returns (TokenDetails memory r)
    {
        address token0;
        address token1;

        (bool success, bytes memory data) = asset.staticcall{gas:20000}(abi.encodeWithSignature("token0()"));
        if (success && data.length == 32) { // check in this way (and not try/catch) since some tokens has fallback functions
            token0 = bytesToAddress(data);

            (success, data) = asset.staticcall{gas:20000}(abi.encodeWithSignature("token1()"));
            if (success && data.length == 32) {
                token1 = bytesToAddress(data);

                (success, data) = asset.staticcall{gas:20000}(abi.encodeWithSignature("factory()"));
                if (success && data.length == 32) {
                    r.lpUnderlyings[0] = token0;
                    r.lpUnderlyings[1] = token1;
                    r.uniswapV2Factory = bytesToAddress(data);
                }
            }
        }

        r.totalSupply = uint128(IUniswapV2PairFull(asset).totalSupply());
        r.decimals = uint8(IUniswapV2PairFull(asset).decimals());
        if (owner != address(0)) {
            r.balance = uint128(ERC20Like(asset).balanceOf(owner));
        }

        (success, data) = asset.staticcall{gas:20000}(abi.encodeWithSignature("isUnitProtocolWrappedAsset()"));
        if (success && data.length == 32 && bytesToBytes32(data) == keccak256("UnitProtocolWrappedAsset")) {
            r.underlyingToken = address(IWrappedAsset(asset).getUnderlyingToken());

            TokenDetails memory underlyingTokenDetails = getTokenDetails(r.underlyingToken, owner);
            r.underlyingTokenTotalSupply = underlyingTokenDetails.totalSupply;
            r.underlyingTokenDecimals = underlyingTokenDetails.decimals;
            r.underlyingTokenBalance = underlyingTokenDetails.balance;
            r.underlyingTokenUniswapV2Factory = underlyingTokenDetails.uniswapV2Factory;
            r.underlyingTokenUnderlyings[0] = underlyingTokenDetails.lpUnderlyings[0];
            r.underlyingTokenUnderlyings[1] = underlyingTokenDetails.lpUnderlyings[1];
        }
    }

    function bytesToAddress(bytes memory _bytes) private pure returns (address addr) {
        assembly {
          addr := mload(add(_bytes, 32))
        }
    }

    function bytesToBytes32(bytes memory _bytes) private pure returns (bytes32 _bytes32) {
        assembly {
          _bytes32 := mload(add(_bytes, 32))
        }
    }

    /**
     * @notice Get parameters of many collaterals
     * @param assets asset addresses
     * @param owner owner address
     */
    function getMultiCollateralParameters(address[] calldata assets, address owner)
        external
        view
        returns (CollateralParameters[] memory r)
    {
        uint length = assets.length;
        r = new CollateralParameters[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getCollateralParameters(assets[i], owner);
        }
    }

    /**
     * @notice Get details of many token
     * @param assets token addresses
     * @param owner owner address
     */
    function getMultiTokenDetails(address[] calldata assets, address owner)
        external
        view
        returns (TokenDetails[] memory r)
    {
        uint length = assets.length;
        r = new TokenDetails[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getTokenDetails(assets[i], owner);
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVault {
    function DENOMINATOR_1E2 (  ) external view returns ( uint256 );
    function DENOMINATOR_1E5 (  ) external view returns ( uint256 );
    function borrow ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function calculateFee ( address asset, address user, uint256 amount ) external view returns ( uint256 );
    function changeOracleType ( address asset, address user, uint256 newOracleType ) external;
    function chargeFee ( address asset, address user, uint256 amount ) external;
    function col (  ) external view returns ( address );
    function colToken ( address, address ) external view returns ( uint256 );
    function collaterals ( address, address ) external view returns ( uint256 );
    function debts ( address, address ) external view returns ( uint256 );
    function depositCol ( address asset, address user, uint256 amount ) external;
    function depositEth ( address user ) external payable;
    function depositMain ( address asset, address user, uint256 amount ) external;
    function destroy ( address asset, address user ) external;
    function getTotalDebt ( address asset, address user ) external view returns ( uint256 );
    function lastUpdate ( address, address ) external view returns ( uint256 );
    function liquidate ( address asset, address positionOwner, uint256 mainAssetToLiquidator, uint256 colToLiquidator, uint256 mainAssetToPositionOwner, uint256 colToPositionOwner, uint256 repayment, uint256 penalty, address liquidator ) external;
    function liquidationBlock ( address, address ) external view returns ( uint256 );
    function liquidationFee ( address, address ) external view returns ( uint256 );
    function liquidationPrice ( address, address ) external view returns ( uint256 );
    function oracleType ( address, address ) external view returns ( uint256 );
    function repay ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function spawn ( address asset, address user, uint256 _oracleType ) external;
    function stabilityFee ( address, address ) external view returns ( uint256 );
    function tokenDebts ( address ) external view returns ( uint256 );
    function triggerLiquidation ( address asset, address positionOwner, uint256 initialPrice ) external;
    function update ( address asset, address user ) external;
    function usdp (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
    function weth (  ) external view returns ( address payable );
    function withdrawCol ( address asset, address user, uint256 amount ) external;
    function withdrawEth ( address user, uint256 amount ) external;
    function withdrawMain ( address asset, address user, uint256 amount ) external;
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultParameters {
    function canModifyVault ( address ) external view returns ( bool );
    function foundation (  ) external view returns ( address );
    function isManager ( address ) external view returns ( bool );
    function isOracleTypeEnabled ( uint256, address ) external view returns ( bool );
    function liquidationFee ( address ) external view returns ( uint256 );
    function setCollateral ( address asset, uint256 stabilityFeeValue, uint256 liquidationFeeValue, uint256 usdpLimit, uint256[] calldata oracles ) external;
    function setFoundation ( address newFoundation ) external;
    function setLiquidationFee ( address asset, uint256 newValue ) external;
    function setManager ( address who, bool permit ) external;
    function setOracleType ( uint256 _type, address asset, bool enabled ) external;
    function setStabilityFee ( address asset, uint256 newValue ) external;
    function setTokenDebtLimit ( address asset, uint256 limit ) external;
    function setVaultAccess ( address who, bool permit ) external;
    function stabilityFee ( address ) external view returns ( uint256 );
    function tokenDebtLimit ( address ) external view returns ( uint256 );
    function vault (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultManagerParameters {
    function devaluationPeriod ( address ) external view returns ( uint256 );
    function initialCollateralRatio ( address ) external view returns ( uint256 );
    function liquidationDiscount ( address ) external view returns ( uint256 );
    function liquidationRatio ( address ) external view returns ( uint256 );
    function maxColPercent ( address ) external view returns ( uint256 );
    function minColPercent ( address ) external view returns ( uint256 );
    function setColPartRange ( address asset, uint256 min, uint256 max ) external;
    function setCollateral (
        address asset,
        uint256 stabilityFeeValue,
        uint256 liquidationFeeValue,
        uint256 initialCollateralRatioValue,
        uint256 liquidationRatioValue,
        uint256 liquidationDiscountValue,
        uint256 devaluationPeriodValue,
        uint256 usdpLimit,
        uint256[] calldata oracles,
        uint256 minColP,
        uint256 maxColP
    ) external;
    function setDevaluationPeriod ( address asset, uint256 newValue ) external;
    function setInitialCollateralRatio ( address asset, uint256 newValue ) external;
    function setLiquidationDiscount ( address asset, uint256 newValue ) external;
    function setLiquidationRatio ( address asset, uint256 newValue ) external;
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface IVaultManagerBorrowFeeParameters {

    /**
     * @notice 1 = 100% = 10000 basis points
     **/
    function BASIS_POINTS_IN_1() external view returns (uint);

    /**
     * @notice Borrow fee receiver
     **/
    function feeReceiver() external view returns (address);

    /**
     * @notice Sets the borrow fee receiver. Only manager is able to call this function
     * @param newFeeReceiver The address of fee receiver
     **/
    function setFeeReceiver(address newFeeReceiver) external;

    /**
     * @notice Sets the base borrow fee in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param newBaseBorrowFeeBasisPoints The borrow fee in basis points
     **/
    function setBaseBorrowFee(uint16 newBaseBorrowFeeBasisPoints) external;

    /**
     * @notice Sets the borrow fee for a particular collateral in basis points (1bp = 0.01% = 0.0001). Only manager is able to call this function
     * @param asset The address of the main collateral token
     * @param newEnabled Is custom fee enabled for asset
     * @param newFeeBasisPoints The borrow fee in basis points
     **/
    function setAssetBorrowFee(address asset, bool newEnabled, uint16 newFeeBasisPoints) external;

    /**
     * @notice Returns borrow fee for particular collateral in basis points (1bp = 0.01% = 0.0001)
     * @param asset The address of the main collateral token
     * @return feeBasisPoints The borrow fee in basis points
     **/
    function getBorrowFee(address asset) external view returns (uint16 feeBasisPoints);

    /**
     * @notice Returns borrow fee for usdp amount for particular collateral
     * @param asset The address of the main collateral token
     * @return The borrow fee
     **/
    function calcBorrowFeeAmount(address asset, uint usdpAmount) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IOracleRegistry {

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    function WETH (  ) external view returns ( address );
    function getKeydonixOracleTypes (  ) external view returns ( uint256[] memory );
    function getOracles (  ) external view returns ( Oracle[] memory foundOracles );
    function keydonixOracleTypes ( uint256 ) external view returns ( uint256 );
    function maxOracleType (  ) external view returns ( uint256 );
    function oracleByAsset ( address asset ) external view returns ( address );
    function oracleByType ( uint256 ) external view returns ( address );
    function oracleTypeByAsset ( address ) external view returns ( uint256 );
    function oracleTypeByOracle ( address ) external view returns ( uint256 );
    function setKeydonixOracleTypes ( uint256[] memory _keydonixOracleTypes ) external;
    function setOracle ( uint256 oracleType, address oracle ) external;
    function setOracleTypeForAsset ( address asset, uint256 oracleType ) external;
    function setOracleTypeForAssets ( address[] memory assets, uint256 oracleType ) external;
    function unsetOracle ( uint256 oracleType ) external;
    function unsetOracleForAsset ( address asset ) external;
    function unsetOracleForAssets ( address[] memory assets ) external;
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedAsset is IERC20 /* IERC20WithOptional */ {

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PositionMoved(address indexed userFrom, address indexed userTo, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TokenWithdraw(address indexed user, address token, uint256 amount);

    event FeeChanged(uint256 newFeePercent);
    event FeeReceiverChanged(address newFeeReceiver);
    event AllowedBoneLockerSelectorAdded(address boneLocker, bytes4 selector);
    event AllowedBoneLockerSelectorRemoved(address boneLocker, bytes4 selector);

    /**
     * @notice Get underlying token
     */
    function getUnderlyingToken() external view returns (IERC20);

    /**
     * @notice deposit underlying token and send wrapped token to user
     * @dev Important! Only user or trusted contracts must be able to call this method
     */
    function deposit(address _userAddr, uint256 _amount) external;

    /**
     * @notice get wrapped token and return underlying
     * @dev Important! Only user or trusted contracts must be able to call this method
     */
    function withdraw(address _userAddr, uint256 _amount) external;

    /**
     * @notice get pending reward amount for user if reward is supported
     */
    function pendingReward(address _userAddr) external view returns (uint256);

    /**
     * @notice claim pending reward for user if reward is supported
     */
    function claimReward(address _userAddr) external;

    /**
     * @notice Manually move position (or its part) to another user (for example in case of liquidation)
     * @dev Important! Only trusted contracts must be able to call this method
     */
    function movePosition(address _userAddrFrom, address _userAddrTo, uint256 _amount) external;

    /**
     * @dev function for checks that asset is unitprotocol wrapped asset.
     * @dev For wrapped assets must return keccak256("UnitProtocolWrappedAsset")
     */
    function isUnitProtocolWrappedAsset() external view returns (bytes32);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2PairFull {
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

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


interface ERC20Like {
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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