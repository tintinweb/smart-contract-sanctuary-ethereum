// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../interfaces/IGlobalConfig.sol";

library Utils {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);

    function _isETH(address _token) public pure returns (bool) {
        return ETH_ADDR == _token;
    }

    function getDivisor(IGlobalConfig globalConfig, address _token) public view returns (uint256) {
        if (_isETH(_token)) return INT_UNIT;
        return 10**uint256(globalConfig.tokenRegistry().getTokenDecimals(_token));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ITokenRegistry.sol";
import "./IBank.sol";
import "./ISavingAccount.sol";
import "./IAccounts.sol";
import "./IConstant.sol";

interface IGlobalConfig {
    function initialize(
        address _gemGlobalConfig,
        address _bank,
        address _savingAccount,
        address _tokenRegistry,
        address _accounts,
        address _poolRegistry
    ) external;

    function tokenRegistry() external view returns (ITokenRegistry);

    function chainLink() external view returns (address);

    function bank() external view returns (IBank);

    function savingAccount() external view returns (ISavingAccount);

    function accounts() external view returns (IAccounts);

    function maxReserveRatio() external view returns (uint256);

    function midReserveRatio() external view returns (uint256);

    function minReserveRatio() external view returns (uint256);

    function rateCurveConstant() external view returns (uint256);

    function compoundSupplyRateWeights() external view returns (uint256);

    function compoundBorrowRateWeights() external view returns (uint256);

    function deFinerRate() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    function liquidationDiscountRatio() external view returns (uint256);

    function governor() external view returns (address);

    function updateMinMaxBorrowAPR(uint256 _minBorrowAPRInPercent, uint256 _maxBorrowAPRInPercent) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ITokenRegistry {
    function initialize(
        address _gemGlobalConfig,
        address _poolRegistry,
        address _globalConfig
    ) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool enabled,
            bool _isSupportedOnCompound, // compiler warning
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function addTokenByPoolRegistry(
        address _token,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle,
        uint256 _borrowLTV
    ) external;

    function getTokenDecimals(address) external view returns (uint8);

    function getCToken(address) external view returns (address);

    function getCTokens() external view returns (address[] calldata);

    function depositeMiningSpeeds(address _token) external view returns (uint256);

    function borrowMiningSpeeds(address _token) external view returns (uint256);

    function isSupportedOnCompound(address) external view returns (bool);

    function getTokens() external view returns (address[] calldata);

    function getTokenInfoFromAddress(address _token)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        );

    function getTokenInfoFromIndex(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function getTokenIndex(address _token) external view returns (uint8);

    function addressFromIndex(uint256 index) external view returns (address);

    function isTokenExist(address _token) external view returns (bool isExist);

    function isTokenEnabled(address _token) external view returns (bool);

    function priceFromAddress(address _token) external view returns (uint256);

    function updateMiningSpeed(
        address _token,
        uint256 _depositeMiningSpeed,
        uint256 _borrowMiningSpeed
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { ActionType } from "../config/Constant.sol";

interface IBank {
    /* solhint-disable func-name-mixedcase */
    function BLOCKS_PER_YEAR() external view returns (uint256);

    function initialize(address _globalConfig, address _poolRegistry) external;

    function newRateIndexCheckpoint(address) external;

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external;

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256);

    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256);

    function depositeRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function borrowRateIndex(address _token, uint256 _blockNum) external view returns (uint256);

    function depositeRateIndexNow(address _token) external view returns (uint256);

    function borrowRateIndexNow(address _token) external view returns (uint256);

    function updateMining(address _token) external;

    function updateDepositFINIndex(address _token) external;

    function updateBorrowFINIndex(address _token) external;

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) external returns (uint256 compoundAmount);

    function depositFINRateIndex(address, uint256) external view returns (uint256);

    function borrowFINRateIndex(address, uint256) external view returns (uint256);

    function getTotalDepositStore(address _token) external view returns (uint256);

    function totalLoans(address _token) external view returns (uint256);

    function totalReserve(address _token) external view returns (uint256);

    function totalCompound(address _token) external view returns (uint256);

    function getBorrowRatePerBlock(address _token) external view returns (uint256);

    function getDepositRatePerBlock(address _token) external view returns (uint256);

    function getTokenState(address _token)
        external
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        );

    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ISavingAccount {
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        address _globalConfig,
        address _poolRegistry,
        uint256 _poolId
    ) external;

    function configure(
        address _baseToken,
        address _miningToken,
        uint256 _maturesOn
    ) external;

    function toCompound(address, uint256) external;

    function fromCompound(address, uint256) external;

    function approveAll(address _token) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IAccounts {
    function initialize(address _globalConfig, address _gemGlobalConfig) external;

    function deposit(
        address,
        address,
        uint256
    ) external;

    function borrow(
        address,
        address,
        uint256
    ) external;

    function getBorrowPrincipal(address, address) external view returns (uint256);

    function withdraw(
        address,
        address,
        uint256
    ) external returns (uint256);

    function repay(
        address,
        address,
        uint256
    ) external returns (uint256);

    function getDepositPrincipal(address _accountAddr, address _token) external view returns (uint256);

    function getDepositBalanceCurrent(address _token, address _accountAddr) external view returns (uint256);

    function getDepositInterest(address _account, address _token) external view returns (uint256);

    function getBorrowInterest(address _accountAddr, address _token) external view returns (uint256);

    function getBorrowBalanceCurrent(address _token, address _accountAddr)
        external
        view
        returns (uint256 borrowBalance);

    function getBorrowETH(address _accountAddr) external view returns (uint256 borrowETH);

    function getDepositETH(address _accountAddr) external view returns (uint256 depositETH);

    function getBorrowPower(address _borrower) external view returns (uint256 power);

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) external returns (uint256, uint256);

    function claim(address _account) external returns (uint256);

    function claimForToken(address _account, address _token) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/* solhint-disable */
interface IConstant {
    function ETH_ADDR() external view returns (address);

    function INT_UNIT() external view returns (uint256);

    function ACCURACY() external view returns (uint256);

    function BLOCKS_PER_YEAR() external view returns (uint256);
}
/* solhint-enable */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

enum ActionType {
    DepositAction,
    WithdrawAction,
    BorrowAction,
    RepayAction,
    LiquidateRepayAction
}

abstract contract Constant {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);
    uint256 public constant ACCURACY = 10**uint256(18);
}

/**
 * @dev Only some of the contracts uses BLOCKS_PER_YEAR in their code.
 * Hence, only those contracts would have to inherit from BPYConstant.
 * This is done to minimize the argument passing from other contracts.
 */
abstract contract BPYConstant is Constant {
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BLOCKS_PER_YEAR;

    constructor(uint256 _blocksPerYear) {
        BLOCKS_PER_YEAR = _blocksPerYear;
    }
}