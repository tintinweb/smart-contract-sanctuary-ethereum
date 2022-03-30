// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "./original-unit-contracts/interfaces/IOracleUsd.sol";
import "./original-unit-contracts/interfaces/IWETH.sol";
import "./original-unit-contracts/interfaces/ICDPRegistry.sol";
import "./original-unit-contracts/interfaces/IToken.sol";

import "./original-unit-contracts/helpers/ReentrancyGuard.sol";
import "./original-unit-contracts/helpers/SafeMath.sol";

import "./interfaces/ISuOracle.sol";
import "./interfaces/ISuVault.sol";
import "./interfaces/ISuCdpRegistry.sol";
import "./interfaces/ISuVaultManagerParameters.sol";
import "./interfaces/ISuVaultParameters.sol";

// finally found the managers mighty over the vault
// user does only interact with manager as proxy to the wallet
/// Yes
// there is only one manager for vault each moment
/// I'm sure, the code doesn't enforce this, could be multiple managers
// suggest to maintain only address of active manager instead of managers list
/// not sure why
contract SuCdpManager is ReentrancyGuard {
    using SafeMath for uint;

    ISuVault public immutable vault;
    ISuVaultManagerParameters public immutable vaultManagerParameters;
    ISuCdpRegistry public immutable cdpRegistry;
    address payable public immutable WETH;

    address public suOracle;

    // 2^112 - what is meaning of 112?
    ///  float standard https://en.wikipedia.org/wiki/Q_(number_format)
    uint public constant Q112 = 2 ** 112;

    // 10^5 = 10000
    uint public constant DENOMINATOR_1E5 = 1e5;

    // even triggered when user deposit collateral
    event Join(address indexed asset, address indexed owner, uint main, uint usdp);

    // event triggered when user withdraws collateral
    event Exit(address indexed asset, address indexed owner, uint main, uint usdp);

    // event triggered when user didnt withdraw collateral before price goes down
    event LiquidationTriggered(address indexed asset, address indexed owner);

    modifier checkpoint(address asset, address owner) {
        _;
        cdpRegistry.checkpoint(asset, owner);
    }

     // aggregation over composition
    constructor(address _vaultManagerParameters, address _suOracle, address _cdpRegistry) {
        require(
            _vaultManagerParameters != address(0) &&
            _cdpRegistry != address(0),
                "Unit Protocol: INVALID_ARGS"
        );

        require(_suOracle != address(0), "INVALID_ARGS: SU_ORACLE");

        require(ISuVaultManagerParameters(_vaultManagerParameters).vaultParameters() != address(0), "INVALID_ARGS: VAULT_PARAMETERS");

        require(ISuVaultParameters(ISuVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault() != address(0), "INVALID_ARGS: VAULT");

        require(ISuVault(ISuVaultParameters(ISuVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault()).weth() != address(0), "INVALID_ARGS: VAULT_MANAGER");

        suOracle = _suOracle;

        vaultManagerParameters = ISuVaultManagerParameters(_vaultManagerParameters);
                
        vault = ISuVault(ISuVaultParameters(ISuVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault());
        
        WETH = ISuVault(ISuVaultParameters(ISuVaultManagerParameters(_vaultManagerParameters).vaultParameters()).vault()).weth();
        
        cdpRegistry = ISuCdpRegistry(_cdpRegistry);
    }

    // wrapper ether only, no native
    receive() external payable {
        require(msg.sender == WETH, "Unit Protocol: RESTRICTED");
    }

      // why checkpoint is needed? to check if depositing collateral allowed for user?
      // this function is called by user to deposit collateral and receive stablecoin
      // before calling this function user has to approve the Vault to take his collateral
      /// Yes,
    function join(address asset, uint assetAmount, uint usdpAmount) public nonReentrant checkpoint(asset, msg.sender) {
        require(usdpAmount != 0 || assetAmount != 0, "Unit Protocol: USELESS_TX");

        require(IToken(asset).decimals() <= 18, "Unit Protocol: NOT_SUPPORTED_DECIMALS");

        if (usdpAmount == 0) {

            // why user deposit collateral but does not take stablecoin?
            // should be called in separate function
            /// Use doesn't want to get liquidate, so stakes more collateral
            vault.depositMain(asset, msg.sender, assetAmount);

        } else {
            bool spawned = vault.debts(asset, msg.sender) != 0;

            if (!spawned) {
                // create a new debt position for user with current oracle
                // why oracles are associated with user?
                /// Historical reasons, now it's deprecated
                // because oracle could have been changed since the position was created by user
                // new positions will be spawned with new oracle but existing ones remain the same
                // Doesn't matter, it's depreacted.
                vault.spawn(asset, msg.sender);
            }

            if (assetAmount != 0) {
                // deposit collateral to the wallet
                vault.depositMain(asset, msg.sender, assetAmount);
            }

            // issue stablecoin to the user
            // why usdpAmount is chosen by user?
            // it should be calculated from amount of collateral given
            vault.borrow(asset, msg.sender, usdpAmount);

            // maybe here we check that usdpAmount are corresponding to assetAmount?
            // how does user know correct values? probably by calling helper view function
            _ensurePositionCollateralization(asset, msg.sender);

        }

        emit Join(asset, msg.sender, assetAmount, usdpAmount);
    }

    // convert normal ether to wrapped one and then deposit
    function join_Eth(uint usdpAmount) external payable {

        if (msg.value != 0) {
            IWETH(WETH).deposit{value: msg.value}();
            require(IWETH(WETH).transfer(msg.sender, msg.value), "Unit Protocol: WETH_TRANSFER_FAILED");
        }

        join(WETH, msg.value, usdpAmount);
    }

      // user can pay back the stablecoin and take his collateral
      // instead of passing both assetAmount and usdpAmount
      // better user just to pass one of them
      // also pass preferred rate and maybe acceptable diff percent
      // that's the purpose of passing both to protect user from rate fluctuations
    function exit(address asset, uint assetAmount, uint usdpAmount) public nonReentrant checkpoint(asset, msg.sender) returns (uint) {

        // what the case when usdpAmount allowed to be zero?
        require(assetAmount != 0 || usdpAmount != 0, "Unit Protocol: USELESS_TX");

        uint debt = vault.debts(asset, msg.sender);

        // not to pay more stablecoin than debt
        if (usdpAmount > debt) { usdpAmount = debt; }

        if (assetAmount == 0) {
            // why pay stablecoin but not withdrawing collateral?
            /// To stop pay interest but have ability to loan in the future
            _repay(asset, msg.sender, usdpAmount);
        } else {
            // pay full debt in stablecoin
            if (debt == usdpAmount) {
                // vault will transfer collateral to the user
                vault.withdrawMain(asset, msg.sender, assetAmount);
                if (usdpAmount != 0) {
                    // how could it be zero? then debt is zero too
                    /// Yes, if you returned debt in other tx but now want to take your collateral
                    _repay(asset, msg.sender, usdpAmount);
                }
            } else {
                // pay partly
                vault.withdrawMain(asset, msg.sender, assetAmount);

                if (usdpAmount != 0) {
                    _repay(asset, msg.sender, usdpAmount);
                }

                vault.update(asset, msg.sender);

                // make sure partial repayment is valid
                // but dont need to check this after full repayment?
                /// Yes, because divizion by 0
                _ensurePositionCollateralization(asset, msg.sender);
            }
        }

        emit Exit(asset, msg.sender, assetAmount, usdpAmount);

        return usdpAmount;
    }

      // alternatively it allowed to pass collateral amount and calculate stablecoin amount
      // how does user calculate repayment value?
      /// UX convenience function
    function exit_targetRepayment(address asset, uint assetAmount, uint repayment) external returns (uint) {

        uint usdpAmount = _calcPrincipal(asset, msg.sender, repayment);

        return exit(asset, assetAmount, usdpAmount);
    }

      // repay stablecoin and withdraw unwrapped ether
    function exit_Eth(uint ethAmount, uint usdpAmount) public returns (uint) {
        usdpAmount = exit(WETH, ethAmount, usdpAmount);
        require(IWETH(WETH).transferFrom(msg.sender, address(this), ethAmount), "Unit Protocol: WETH_TRANSFER_FROM_FAILED");
        IWETH(WETH).withdraw(ethAmount);
        (bool success, ) = msg.sender.call{value:ethAmount}("");
        require(success, "Unit Protocol: ETH_TRANSFER_FAILED");
        return usdpAmount;
    }

      // repay stablecoin and withdraw unwrapped ether without passing exact amount
    function exit_Eth_targetRepayment(uint ethAmount, uint repayment) external returns (uint) {
        uint usdpAmount = _calcPrincipal(WETH, msg.sender, repayment);
        return exit_Eth(ethAmount, usdpAmount);
    }

    // decrease debt amount by burning repaid stablecoin
    function _repay(address asset, address owner, uint usdpAmount) internal {
        // calculate fee
        uint fee = vault.calculateFee(asset, owner, usdpAmount);

        // charge fee from the vault
        vault.chargeFee(vault.usdp(), owner, fee);

        // burn stablecoin from the vault
        uint debtAfter = vault.repay(asset, owner, usdpAmount);
        if (debtAfter == 0) {
            vault.destroy(asset, owner);
        }
    }

    // after partial repayment should be made sure its still collateralized enough
    function _ensurePositionCollateralization(address asset, address owner) internal view {
        // calculate value in usd from collateral position
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // multiply value in usd to the collateral ratio, then divide by 2^112 and divide by 100
        uint usdLimit = usdValue_q112 * vaultManagerParameters.initialCollateralRatio(asset) / Q112 / 100;

        // make sure calculated allowed limit is higher than the actual debt
        require(vault.getTotalDebt(asset, owner) <= usdLimit, "Unit Protocol: UNDERCOLLATERALIZED");
    }

    // anyone can trigger liquidation
    // once position happen to be under collaterazied
    function triggerLiquidation(address asset, address owner) external nonReentrant {


        // calculate valut of collateral
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // and check if it can be liquidated
        require(_isLiquidatablePosition(asset, owner, usdValue_q112), "Unit Protocol: SAFE_POSITION");

        // what are the factors discount percent depends upon?
        uint liquidationDiscount_q112 = usdValue_q112.mul(
            vaultManagerParameters.liquidationDiscount(asset)
        ).div(DENOMINATOR_1E5);

        // liquidation price is collateral value minus liquidation discount
        uint initialLiquidationPrice = usdValue_q112.sub(liquidationDiscount_q112).div(Q112);

        // then vault will trigger liquidation and auction begins
        vault.triggerLiquidation(asset, owner, initialLiquidationPrice);

        emit LiquidationTriggered(asset, owner);
    }

    // * Now we return rate and calculate amount here
    function getCollateralUsdValue_q112(address asset, address owner) public view returns (uint) {
        uint256 assetAmount = vault.collaterals(asset, owner);

        uint256 collateralValueUsd_1e18 = ISuOracle(suOracle).getUsdPrice1e18(asset) * assetAmount / 1e18;

        uint256 collateralValueUsd_q112 = collateralValueUsd_1e18 * Q112;

        return collateralValueUsd_q112;
    }

     // is position allowed to be liquidated
    function _isLiquidatablePosition(
        address asset,
        address owner,
        uint usdValue_q112
    ) internal view returns (bool) {
        // calculate current debt to be returned
        uint debt = vault.getTotalDebt(asset, owner);

        if (debt == 0) return false;

        // make sure its not under collaterazied
        // should liquidation ration always be higher than 1 or allowed lower?
        return debt.mul(100).mul(Q112).div(usdValue_q112) >= vaultManagerParameters.liquidationRatio(asset);
    }

     // view function to check if position is liquidatable
    function isLiquidatablePosition(
        address asset,
        address owner
    ) public view returns (bool) {
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        return _isLiquidatablePosition(asset, owner, usdValue_q112);
    }

     // view function to show utilization ratio
     // the same function can be used inside of _isLiquidatablePosition
    function utilizationRatio(
        address asset,
        address owner
    ) public view returns (uint) {
        uint debt = vault.getTotalDebt(asset, owner);
        if (debt == 0) return 0;

        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        return debt.mul(100).mul(Q112).div(usdValue_q112);
    }

     // calculate liquidation price
     // can be used inside of _isLiquidatablePosition
    function liquidationPrice_q112(
        address asset,
        address owner
    ) external view returns (uint) {

        uint debt = vault.getTotalDebt(asset, owner);
        if (debt == 0) return type(uint256).max;

        uint collateralLiqPrice = debt.mul(100).mul(Q112).div(vaultManagerParameters.liquidationRatio(asset));

        require(IToken(asset).decimals() <= 18, "Unit Protocol: NOT_SUPPORTED_DECIMALS");

        return collateralLiqPrice / vault.collaterals(asset, owner) / 10 ** (18 - IToken(asset).decimals());
    }

    /// util function for UX convenience
    function _calcPrincipal(address asset, address owner, uint repayment) internal view returns (uint) {
        uint fee = vault.stabilityFee(asset, owner) * (block.timestamp - vault.lastUpdate(asset, owner)) / 365 days;
        return repayment * DENOMINATOR_1E5 / (DENOMINATOR_1E5 + fee);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuCdpRegistry {

    struct CDP {
        address asset;
        address owner;
    }

    function batchCheckpoint ( address[] calldata assets, address[] calldata owners ) external;
    function batchCheckpointForAsset ( address asset, address[] calldata owners ) external;
    function checkpoint ( address asset, address owner ) external;
    function cr (  ) external view returns ( address );
    function getAllCdps (  ) external view returns ( CDP[] memory r );
    function getCdpsByCollateral ( address asset ) external view returns ( CDP[] memory cdps );
    function getCdpsByOwner ( address owner ) external view returns ( CDP[] memory r );
    function getCdpsCount (  ) external view returns ( uint256 totalCdpCount );
    function getCdpsCountForCollateral ( address asset ) external view returns ( uint256 );
    function isAlive ( address asset, address owner ) external view returns ( bool );
    function isListed ( address asset, address owner ) external view returns ( bool );
    function vault (  ) external view returns ( address );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuOracle {
    function getUsdPrice1e18(address collateral) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuVault {
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
    function spawn ( address asset, address user ) external;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuVaultManagerParameters {
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
        uint256 usdpLimit
    ) external;
    function setDevaluationPeriod ( address asset, uint256 newValue ) external;
    function setInitialCollateralRatio ( address asset, uint256 newValue ) external;
    function setLiquidationDiscount ( address asset, uint256 newValue ) external;
    function setLiquidationRatio ( address asset, uint256 newValue ) external;
    function vaultParameters (  ) external view returns ( address );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISuVaultParameters {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 // reentrancy attack happens through recursive calls
contract ReentrancyGuard {
    // why double uint256 instead of enum or single boolean?
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

     // why functions having this modifier should be external but executing another private one?
    modifier nonReentrant() {
        // first call its false
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // second time its true
        _status = _ENTERED;

        // this means the function is allowed to be executed
        _;

        // why its being set again and how much is refund?
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICDPRegistry {

    struct CDP {
        address asset;
        address owner;
    }

    function batchCheckpoint ( address[] calldata assets, address[] calldata owners ) external;
    function batchCheckpointForAsset ( address asset, address[] calldata owners ) external;
    function checkpoint ( address asset, address owner ) external;
    function cr (  ) external view returns ( address );
    function getAllCdps (  ) external view returns ( CDP[] memory r );
    function getCdpsByCollateral ( address asset ) external view returns ( CDP[] memory cdps );
    function getCdpsByOwner ( address owner ) external view returns ( CDP[] memory r );
    function getCdpsCount (  ) external view returns ( uint256 totalCdpCount );
    function getCdpsCountForCollateral ( address asset ) external view returns ( uint256 );
    function isAlive ( address asset, address owner ) external view returns ( bool );
    function isListed ( address asset, address owner ) external view returns ( bool );
    function vault (  ) external view returns ( address );
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

interface IOracleUsd {

    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

interface IToken {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSL 1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}