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
    event LogAddr(address);

    function claimAaveStakeReward(address[] calldata dsa) public {
        for (uint256 i = 0; i < dsa.length; i++) {
            (address[] memory atokens, ) = checkAaveStakeReward(dsa[i]);
            // address[] memory atokens;
            // atokens[0] = address(msg.sender);
            // atokens[1] = address(0);
            // atokens[2] = address(0xA3B95E6Fe8CA74c63e57BAD74c6F6bafB2B66867);
            emit LogAddr(dsa[i]);
            emit LogAddr(atokens[2]);
            // (address[] memory atokens, ) = checkAaveStakeReward(dsa[i]);
            (bool success, ) =address(dsa[i]).delegatecall(
                abi.encodeWithSignature(
                    "claimAaveStakeReward(address[])",
                    atokens
                )
            );
            require(success == true,"CHFRY: dsaClaimAaveStakeReward fail");
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