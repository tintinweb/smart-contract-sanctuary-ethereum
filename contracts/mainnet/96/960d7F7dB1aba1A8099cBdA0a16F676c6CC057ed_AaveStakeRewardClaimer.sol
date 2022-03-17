// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {AccountCenterInterface} from "./interfaces/IAccountCenter.sol";

struct AaveUserData {
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 availableBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
    uint256 ethPriceInUsd;
    uint256 pendingRewards;
}

contract AaveStakeRewardClaimer {
    address public aaveResolver;
    address public aaveIncentivesAddress;
    address public aaveDataProvider;
    address public accountCenter;
    uint256 public _accountTypeCount = 2;

    constructor(
        address _accountCenter,
        address _aaveDataProvider,
        address _aaveResolver,
        address _aaveIncentivesAddress
    ) {
        accountCenter = _accountCenter;
        aaveResolver = _aaveResolver;
        aaveDataProvider = _aaveDataProvider;
        aaveIncentivesAddress = _aaveIncentivesAddress;
    }

    function claimAaveStakeReward(address[] calldata dsa) public {
        for (uint256 i = 0; i < dsa.length; i++) {
            (address[] memory atokens, ) = checkAaveStakeReward(dsa[i]);
            IDsaProxy(dsa[i]).claimDsaAaveStakeReward(atokens);
        }
    }

    function claimAllAaveStakeReward(address[] calldata dsa,uint256 thereshold) public {
        for (uint256 i = 0; i < dsa.length; i++) {
            (address[] memory atokens, ) = getAllRewardBlanece(dsa[i], thereshold);
            IDsaProxy(dsa[i]).claimDsaAaveStakeReward(atokens);
        }
    }

    function checkAaveStakeReward(address aaveAccount)
        public
        view
   returns (address[] memory atokens, uint256 rewards)
    {
        uint256 assetsCount;

        (bool[] memory collateral, ) = IAaveV2Resolver(aaveResolver)
            .getConfiguration(aaveAccount);

        address[] memory reservesList = IAaveV2Resolver(aaveResolver)
            .getReservesList();

        for (uint256 i = 0; i < reservesList.length; i++) {
            if (collateral[i] == true) {
                assetsCount = assetsCount + 1;
            }
        }

        address[] memory assets = new address[](assetsCount);

        uint256 j;

        for (uint256 i = 0; i < reservesList.length; i++) {
            if (collateral[i] == true) {
                assets[j] = reservesList[i];
                j = j + 1;
            }
        }

        uint256 arrLength = 2 * assets.length;

        address[] memory _atokens = new address[](arrLength);

        AaveProtocolDataProvider aaveData = AaveProtocolDataProvider(
            aaveDataProvider
        );

        for (uint256 i = 0; i < assets.length; i++) {
            (_atokens[2 * i], , _atokens[2 * i + 1]) = aaveData
                .getReserveTokensAddresses(assets[i]);
        }

        uint256 _rewards = AaveStakedTokenIncentivesController(
            aaveIncentivesAddress
        ).getRewardsBalance(_atokens, aaveAccount);

        return (_atokens, _rewards);
    }


    function getAllRewardBlanece(address aaveAccount, uint256 threshold)
        public
        view
        returns (address[] memory atokens, uint256 totalReward)
    {
        uint256 rewardTokenCount;
        uint256 _totalReward;

        address[] memory reservesList = IAaveV2Resolver(aaveResolver)
            .getReservesList();

        uint256 i;
        uint256[] memory _rewards;
        address[] memory _wToken;

        for (i = 0; i < reservesList.length; i++) {
            (_wToken, _rewards) = getReservesReward(
                reservesList[i],
                aaveAccount
            );
            if (_rewards[0] > threshold) {
                rewardTokenCount++;
            }
            if (_rewards[1] > threshold) {
                rewardTokenCount++;
            }
        }

        address[] memory _atokens = new address[](rewardTokenCount);

        uint256 j;

        for (i = 0; i < reservesList.length; i++) {
            (_wToken, _rewards) = getReservesReward(
                reservesList[i],
                aaveAccount
            );
            if (_rewards[0] > threshold) {
                _atokens[j] = _wToken[0];
                _totalReward = _totalReward + _rewards[0];
                j++;
            }
            if (_rewards[1] > threshold) {
                _atokens[j] = _wToken[1];
                _totalReward = _totalReward + _rewards[1];
                j++;
            }
        }
        return(_atokens,_totalReward);
    }

    function getReservesReward(address reserves, address aaveAccount)
        public
        view
        returns (address[] memory xTokens, uint256[] memory rewards)
    {
        address[] memory _xToken = new address[](2);
        address[] memory _wToken = new address[](1);
        uint256[] memory _rewards = new uint256[](2);

        AaveProtocolDataProvider aaveData = AaveProtocolDataProvider(
            aaveDataProvider
        );

        (_xToken[0],  ,_xToken[1]) = aaveData
            .getReserveTokensAddresses(reserves);
        for (uint256 i = 0; i < 2; i++) {
            _wToken[0] = _xToken[i];
            _rewards[i] = AaveStakedTokenIncentivesController(
                aaveIncentivesAddress
            ).getRewardsBalance(_wToken, aaveAccount);
        }

        return (_xToken, _rewards);
    }
}

interface AaveStakedTokenIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IAaveV2Resolver {
    function getConfiguration(address user)
        external
        view
        returns (bool[] memory collateral, bool[] memory borrowed);

    function getReservesList() external view returns (address[] memory data);
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

interface IDsaProxy {
    function claimDsaAaveStakeReward(address[] memory atokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account)
        external
        view
        returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}