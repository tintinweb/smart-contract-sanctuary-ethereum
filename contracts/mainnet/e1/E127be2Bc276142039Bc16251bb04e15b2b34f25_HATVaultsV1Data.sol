// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/IHATVaultsV1.sol";
import "./interfaces/IHATVaultsData.sol";

contract HATVaultsV1Data is IHATVaultsData {
    IHATVaultsV1 public hatVaults;

    constructor(IHATVaultsV1 _hatVaults) {
        hatVaults = _hatVaults;
    }

    function getTotalShares(uint256 _pid) external view returns (uint256) {
        return hatVaults.poolInfo(_pid).totalUsersAmount;
    }

    function getShares(uint256 _pid, address _user) external view returns (uint256) {
        return hatVaults.userInfo(_pid, _user).amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IHATVaultsV1 {

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        uint256 totalUsersAmount;
        uint256 lastProcessedTotalAllocPoint;
        uint256 balance;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo calldata poolInfo);

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo calldata userInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IHATVaultsData {
    
    function getTotalShares(uint256 _pid) external view returns (uint256 totalShares);

    function getShares(uint256 _pid, address _user) external view returns (uint256 shares);
}