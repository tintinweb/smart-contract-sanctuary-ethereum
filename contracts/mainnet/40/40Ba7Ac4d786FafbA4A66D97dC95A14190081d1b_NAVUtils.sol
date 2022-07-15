// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/convex/IConvex.sol";
import "../interfaces/convex/IRewards.sol";
import "../interfaces/IAPContract.sol";

contract NAVUtils {
    mapping(address => address) convexDepositCurve;
    address public convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public cvxRewards = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
    address public cvxCRVRewards = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address public owner;

    constructor() {
        owner = msg.sender;
        convexDepositCurve[
            0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7
        ] = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
        convexDepositCurve[
            0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B
        ] = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
    }

    function addToMapping(address _base, uint256 _poolId) external {
        require(msg.sender == owner);
        (, , , address baseRewards, , ) = IConvex(convexDeposit).poolInfo(
            _poolId
        );
        convexDepositCurve[_base] = baseRewards;
    }

    function addToMappingBatch(
        address[] calldata _base,
        uint256[] calldata _poolId
    ) external {
        require(msg.sender == owner);
        for (uint256 index = 0; index < _base.length; index++) {
            (, , , address baseRewards, , ) = IConvex(convexDeposit).poolInfo(
                _poolId[index]
            );
            convexDepositCurve[_base[index]] = baseRewards;
        }
    }

    function getConvexNAV(address _assetAddress)
        external
        view
        returns (uint256)
    {
        if (convexDepositCurve[_assetAddress] != address(0))
            return
                IRewards(convexDepositCurve[_assetAddress]).balanceOf(
                    msg.sender
                );
        else return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewards{
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    function withdrawAll(bool _claim) external;
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function stakeFor(address _account,uint256 _amount) external returns(bool);
    function earned(address) external view returns (uint256);
    function extraRewardsLength() external view returns (uint256);  //already external function
    function extraRewards(uint256) external view returns(address);  //contract address of extra rewards 
    function rewardToken() external view returns(address);
    function getReward(address,bool) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function getReward(bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IConvex {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    //function to get the pool info array's length
    function poolLength() external view returns (uint256);

    function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
    function minter() external view returns(address);
    function get_virtual_price()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAPContract {
    function getUSDPrice(address) external view returns (uint256);
    function stringUtils() external view returns (address);
    function yieldsterGOD() external view returns (address);
    function emergencyVault() external view returns (address);
    function whitelistModule() external view returns (address);
    function addVault(address,uint256[] calldata) external;
    function setVaultSlippage(uint256) external;
    function setVaultAssets(address[] calldata,address[] calldata,address[] calldata,address[] calldata) external;
    function changeVaultAdmin(address _vaultAdmin) external;
    function yieldsterDAO() external view returns (address);
    function exchangeRegistry() external view returns (address);
    function getVaultSlippage() external view returns (uint256);
    function _isVaultAsset(address) external view returns (bool);
    function yieldsterTreasury() external view returns (address);
    function setVaultStatus(address) external;
    function setVaultSmartStrategy(address, uint256) external;
    function getWithdrawStrategy() external returns (address);
    function getDepositStrategy() external returns (address);
    function isDepositAsset(address) external view returns (bool);
    function isWithdrawalAsset(address) external view returns (bool);
    function getVaultManagementFee() external returns (address[] memory);
    function safeMinter() external returns (address);
    function safeUtils() external returns (address);
    function getStrategyFromMinter(address) external view returns (address);
    function sdkContract() external returns (address);
    function getWETH()external view returns(address);
    function calculateSlippage(address ,address, uint256, uint256)external view returns(uint256);
    function vaultsCount(address) external view returns(uint256);
    function getPlatformFeeStorage() external view returns(address);
    function getManagementFeeStorage() external view returns(address);
    function getPerformanceFeeStorage() external view returns(address);
    function checkWalletAddress(address _walletAddress) external view returns(bool);
    function getNavCalculator() external view returns(address);

}