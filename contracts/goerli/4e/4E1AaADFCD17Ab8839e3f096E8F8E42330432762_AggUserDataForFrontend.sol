// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * The core function is to aggregate trove datas of user for front-end page
 */


interface IERC20 {
    function symbol() external view returns (string memory);
    function balanceOf(address _owner) external view returns (uint);
}

interface ITrove {
    function userCollateralShare(address _borrower) external view returns (uint);
    function userBorrowPart(address _borrower) external view returns (uint);
    // function getPositionHealth(address _borrower) external view returns (uint);
    function exchangeRate() external view returns (uint);
    function APR() external view returns (uint);
    function LIQUIDATION_RATIO() external view returns (uint);
    function collateral() external view returns (address);
}

interface IRewrdPool {
    function earned(address _account) external view returns (uint);
}

// orcale
interface IOracle {
    function get() external view returns (bool, uint);
    function get(bytes calldata _input) external view returns (bool, uint);
}

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}


struct UserInfo {
    uint256 shares;
    uint256 lastDepositedTime;
    uint256 tokenAtLastUserAction;
    uint256 lastUserActionTime;
    uint256 lockStartTime;
    uint256 lockEndTime;
    uint256 userBoostedShare;
    bool locked;
    uint256 lockedAmount;
}

interface IStakePool {
    function userInfo(address _user) external view returns (UserInfo memory);
}


contract AggUserDataForFrontend {
    struct StakeInfo {
        uint price;
        uint stakedAmount;
        uint stakedValues;
        uint unlockTime;
        string tokenSymbol;
        address tokenAddr;
    }

    struct BorrowInfo {
        uint price;
        uint collValue;
        uint debtValue;
        // uint posHealth;
        // uint liquidatePrice;
        uint APY;
        string tokenSymbol;
        address tokenAddr;
        uint sysLiquidaRatio;
    }

    struct EarnInfo {
        uint price;
        uint amount;
        uint value;
        string tokenSymbol;
        address tokenAddr;
    }

    uint256 private constant DECIMAL = 1e18;
    
    IOracle public ARCOracle;
    IChainlinkOracle public BTCOracle;

    function setBTCOracle(address _aggregator) external {
        BTCOracle = IChainlinkOracle(_aggregator);
    }

    function setARCOracle(address _priceAddr) external {
        ARCOracle = IOracle(_priceAddr);
    }

    function getUserAllInfos(
        address[3] memory _stakesAddr,
        address[2] memory _rewardsAddr,
        address[10] memory _trovesAddr,
        address _account
    ) external view returns (
        StakeInfo[3] memory staking, 
        uint totalStakedValue,
        EarnInfo[2] memory earning,
        uint totalRewardsValue,
        BorrowInfo[10] memory borrowing, 
        uint totalDebtValue,
        uint totalCollsValue
    ) {
        (staking, totalStakedValue) = _getUserStakeInfos(_stakesAddr, _account);
        (earning, totalRewardsValue) = _getUserRewardInfos(_rewardsAddr, _account);
        (borrowing, totalDebtValue, totalCollsValue) = _getUserBorrowInfos(_trovesAddr, _account);
    }

    function _getUserStakeInfos(address[3] memory _stakesAddr, address _account) internal view returns (
        StakeInfo[3] memory staking, 
        uint totalStakedValue
    ) {
        // for staking 
        for (uint i; i < _stakesAddr.length; ++i) {
            StakeInfo memory stakeInfo;

            if (_stakesAddr[i] != address(0)) {
                if (i == 0) {
                stakeInfo.tokenSymbol = 'ARC';
                (, stakeInfo.price) = ARCOracle.get();
                } else if (i == 1) {
                    stakeInfo.tokenSymbol = 'USDA';
                    stakeInfo.price = 1e18;
                } else {
                    stakeInfo.tokenSymbol = 'wBTC';
                    int last = BTCOracle.latestAnswer();
                    uint decimal = BTCOracle.decimals();
                    stakeInfo.price = 1e18 * uint(last) / (10**decimal);
                }
                UserInfo memory userInfo =  IStakePool(_stakesAddr[i]).userInfo(_account);

                stakeInfo.stakedAmount = userInfo.shares;
                stakeInfo.stakedValues = stakeInfo.price * stakeInfo.stakedAmount / DECIMAL;
                stakeInfo.unlockTime = userInfo.lockEndTime;
            }
            
            stakeInfo.tokenAddr = _stakesAddr[i];
            staking[i] = stakeInfo;

            totalStakedValue = totalStakedValue + stakeInfo.stakedValues;
        }
    }

    function _getUserRewardInfos(address[2] memory _rewardsAddr, address _account) internal view returns (
        EarnInfo[2] memory earning,
        uint totalRewardsValue
    ) {
        // for reward
        for (uint i; i < _rewardsAddr.length; ++i) {
            EarnInfo memory earnInfo;

            if (_rewardsAddr[i] != address(0)) {
                if (i == 0) {
                    earnInfo.tokenSymbol = 'ARC';
                    (, earnInfo.price) = ARCOracle.get();
                } else {
                    earnInfo.tokenSymbol = 'wBTC';
                    int last = BTCOracle.latestAnswer();
                    uint decimal = BTCOracle.decimals();
                    earnInfo.price = 1e18 * uint(last) / (10**decimal); 
                }
                earnInfo.amount = IRewrdPool(_rewardsAddr[i]).earned(_account);
                earnInfo.value = earnInfo.amount * earnInfo.price / DECIMAL;
            }
            
            earnInfo.tokenAddr = _rewardsAddr[i];
            earning[i] = earnInfo;
            
            totalRewardsValue = totalRewardsValue + earnInfo.value;
        }
    }

    function _getUserBorrowInfos(address[10] memory _trovesAddr, address _account) internal view returns (
        BorrowInfo[10] memory borrowing, 
        uint totalDebtValue,
        uint totalCollsValue
    ) {
        // for borrow
        for (uint i; i < _trovesAddr.length; ++i) {
            BorrowInfo memory borrowInfo;
            address troveAddr = _trovesAddr[i];
            if (troveAddr != address(0)) {
                uint exchangeRate = ITrove(troveAddr).exchangeRate();
                borrowInfo.price = DECIMAL * DECIMAL / exchangeRate;
                borrowInfo.collValue = ITrove(troveAddr).userCollateralShare(_account) * borrowInfo.price / DECIMAL;
                borrowInfo.debtValue = ITrove(troveAddr).userBorrowPart(_account);
                // borrowInfo.posHealth = ITrove(troveAddr).getPositionHealth(_account);
                // borrowInfo.liquidatePrice = 6e17;
                borrowInfo.APY = ITrove(troveAddr).APR();
                borrowInfo.sysLiquidaRatio = ITrove(troveAddr).LIQUIDATION_RATIO();
                borrowInfo.tokenSymbol = IERC20(ITrove(troveAddr).collateral()).symbol();
            }
            borrowInfo.tokenAddr = troveAddr;
            borrowing[i] = borrowInfo;
            totalDebtValue = totalDebtValue + borrowInfo.debtValue;
            totalCollsValue = totalCollsValue + borrowInfo.collValue;
        }
    }

}