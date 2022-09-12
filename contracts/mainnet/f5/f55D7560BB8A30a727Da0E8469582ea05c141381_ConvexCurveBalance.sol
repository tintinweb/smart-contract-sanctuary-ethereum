// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/convex/ICVXToken.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/convex/IRewards.sol";
import "../interfaces/convex/IConvex.sol";

//TODO make upgradeable
contract ConvexCurveBalance {
    address public owner;
    address public APContract;
    address internal convexBoosterDeposit =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address[] public extraRewards;
    uint256 public extraRewardsLength;
    uint256[] public supportedConvexCurvePools;

    constructor() {
        owner = msg.sender;
        APContract = address(0x8C1c01a074f8C321d568fd083AFf84Fd020c033D);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /// @dev Function to set address of Owner.
    /// @param _owner Address of new owner.
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function getCVXBalance(address _vault) public view returns (uint256) {
        //use current supply to gauge cliff
        //this will cause a bit of overflow into the next cliff range
        //but should be within reasonable levels.
        //requires a max supply check though

        uint256 _amount = getCRVBalance(_vault);
        ICVXToken cvx = ICVXToken(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
        uint256 supply = cvx.totalSupply();
        uint256 reductionPerCliff = cvx.reductionPerCliff();
        uint256 totalCliffs = cvx.totalCliffs();
        uint256 maxSupply = cvx.maxSupply();
        uint256 cliff = supply / reductionPerCliff;
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            _amount = (_amount * reduction) / totalCliffs;
            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
        }

        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
            0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B
        );
        uint256 totalCVXPrice = (tokenUSD * _amount) / (1e18);
        return totalCVXPrice;
    }

    function getCRVBalance(address _vault) public view returns (uint256) {
        uint256 crvEarned;

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 rewardsEarned = IRewards(baseRewards).earned(_vault);
            crvEarned = crvEarned + rewardsEarned;
        }
        return crvEarned;
    }

    function getConvexStakeBalance(address _vault)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 counter;

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 balance = IRewards(baseRewards).balanceOf(_vault);
            if (balance > 0) {
                counter++;
            }
        }

        address[] memory assets = new address[](counter);
        uint256[] memory balances = new uint256[](counter);

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            uint256 counter2;
            (, address token, , address baseRewards, , ) = IConvex(
                convexBoosterDeposit
            ).poolInfo(supportedConvexCurvePools[index]);

            uint256 balance = IRewards(baseRewards).balanceOf(_vault);
            if (balance > 0) {
                assets[counter2] = token;
                balances[counter2] = balance;
                counter2++;
            }
        }
        return (assets, balances);
    }

    function setSupportedConvexCurvePool(uint256 _poolid) public onlyOwner {
        supportedConvexCurvePools.push(_poolid);
    }

    function setSupportedConvexCurvePoolsBatch(uint256[] calldata _poolids)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _poolids.length; index++) {
            setSupportedConvexCurvePool(_poolids[index]);
        }
    }

    function removeSupportedConvexCurvePool(uint256 _index) public onlyOwner {
        supportedConvexCurvePools[_index] = supportedConvexCurvePools[supportedConvexCurvePools.length];
        supportedConvexCurvePools.pop();
    }

    function removeSupportedConvexCurvePoolsBatch(uint256[] calldata _indices)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _indices.length; index++) {
            removeSupportedConvexCurvePool(_indices[index]);
        }
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
    function rewards(address) external view returns (uint256);

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

interface ICVXToken {
    function reductionPerCliff() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IHexUtils {
    function fromHex(bytes calldata) external pure returns (bytes memory);

    function toDecimals(address, uint256) external view returns (uint256);

    function fromDecimals(address, uint256) external view returns (uint256);
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