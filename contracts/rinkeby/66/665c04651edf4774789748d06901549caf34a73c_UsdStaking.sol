/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IDepositUSD {
    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external;

    function stakeUsd(address account_, uint256 amount_) external;

    function unstakeUsd(address account_, uint256 amount_) external;

    function depositFee(uint256 amount_) external;

    function takeFee(address account_, uint256 amount_) external;

    function getFee() external view returns (uint256);
}

interface IUSDReward {
    function inviteReward(address account, uint256 amount) external;
}

interface IUSD {
    function rewardTo() external view returns (address);
}

contract UsdStaking {
    address public usdAddress; // USD合约地址
    address public depositAddress; // 存款合约地址

    // 每个用户的信息。
    struct UserInfo {
        uint256 stakedOf; // 用户提供了多少 LP 代币。
        uint256 rewardOf; // 用户已经获取的奖励
        uint256 duration; //质押周期
        uint256 lastDepositAt; //最后质押时间
        uint256 lastRewardAt; //最后领奖时间
        uint256 userReward; //用户奖励
    }

    mapping(address => UserInfo) public userInfo; // 用户信息
    uint256 public totalStaked; //总质押
    uint256 public totalReward; //总奖励
    uint256 public accRewardPerShare; //全局每股分红

    uint256 public DEPOSIT_DURATION_1 = 2592000; //30d
    uint256 public DEPOSIT_DURATION_2 = 5184000; //60d
    uint256 public DEPOSIT_DURATION_3 = 7776000; //90d

    uint256 public lastBounsEpoch; //上一次分红时间
    uint256 public pendingToken; //待分红的USD

    constructor(address usd_, address deposit_) {
        usdAddress = usd_;
        depositAddress = deposit_;
    }

    // 质押事件
    event Staked(address indexed from, uint256 amount);
    // 取消质押事件
    event Unstaked(address indexed from, uint256 amount);
    // 领取奖励事件
    event Reward(address indexed to, uint256 amount);

    // 更新分红奖励
    function bonusReward() public {
        uint256 _epoch_day = block.timestamp / 86400;
        require(totalStaked > 0, "totalStaked must be greater than 0");
        require(_epoch_day > lastBounsEpoch, "Error: lastBounsEpoch");

        lastBounsEpoch = _epoch_day;

        //将待分红奖励划入分红余额，分红池按n天分红，分红更线性
        uint256 totalFee = IDepositUSD(depositAddress).getFee();

        //每次发放当前手续费余额的20分之一
        pendingToken = totalFee / 20;
        totalReward += pendingToken; //记录总分红

        accRewardPerShare += (pendingToken * 1e12) / totalStaked;
    }

    function getDuration(uint256 _duration) private view returns (uint256) {
        uint256 _duration_day = _duration / 86400;
        if (_duration_day >= DEPOSIT_DURATION_3) {
            return DEPOSIT_DURATION_3;
        } else if (_duration_day >= DEPOSIT_DURATION_2) {
            return DEPOSIT_DURATION_2;
        } else if (_duration_day >= DEPOSIT_DURATION_1) {
            return DEPOSIT_DURATION_1;
        } else {
            return 0;
        }
    }

    // 质押
    function stake(uint256 amount, uint256 _duration) public returns (bool) {
        // 数量必须是1 USD的整数倍
        require(amount > 0, "stake must be integer multiple of 1 USD.");

        UserInfo storage user = userInfo[msg.sender];
        if (user.stakedOf > 0) {
            require(_duration == user.duration, "Error: User Duration");
            // 领取之前的奖励
            uint256 pending = rewardAmount(msg.sender);
            _takeReward(msg.sender, pending);
        }

        //转入质押
        TransferHelper.safeTransferFrom(
            usdAddress,
            msg.sender,
            depositAddress,
            amount
        );

        //记录质押数量
        IDepositUSD(depositAddress).stakeUsd(msg.sender, amount);

        user.duration = getDuration(_duration);
        user.lastDepositAt = block.timestamp;
        // 更新用户质押的数量
        user.stakedOf += amount;
        // 更新已经领取的奖励
        user.rewardOf = (user.stakedOf * accRewardPerShare) / 1e12;
        // 更新池子总票数
        totalStaked += amount;
        // emit event
        emit Staked(msg.sender, amount);

        return true;
    }

    /**
     * 提取质押物
     */
    function unstake(uint256 _amount) public virtual returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedOf >= _amount, "Staking: out of staked");
        require(_amount > 0, "votes must be gt 0.");
        require(
            block.timestamp - user.lastDepositAt >= user.duration,
            "Error: User Duration"
        );

        // 领取之前的奖励
        uint256 pending = rewardAmount(msg.sender);
        _takeReward(msg.sender, pending);

        totalStaked -= _amount;
        // 更新用户质押的数量
        user.stakedOf -= _amount;
        // 更新已经领取的奖励
        user.rewardOf = (user.stakedOf * accRewardPerShare) / 1e12;

        // 提取质押物
        IDepositUSD(depositAddress).unstakeUsd(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
        return true;
    }

    function rewardAmount(address _account) public view returns (uint256) {
        uint256 pending;
        UserInfo memory _user = userInfo[_account];
        if (_user.stakedOf > 0) {
            pending =
                ((_user.stakedOf * accRewardPerShare) / 1e12) -
                _user.rewardOf;
        }
        return pending;
    }

    // 直接领取收益
    function takeReward() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedOf > 0, "Staking: out of staked");
        uint256 pending = rewardAmount(msg.sender);
        require(pending > 0, "Staking: no pending reward");

        _takeReward(msg.sender, pending);
    }

    function _takeReward(address _account, uint256 pending) private {
        if (pending > 0) {
            UserInfo storage user = userInfo[msg.sender];
            user.rewardOf = (user.stakedOf * accRewardPerShare) / 1e12;
            safeTransfer(_account, pending);
        }
    }

    // 安全的转账功能，以防万一如果舍入错误导致池没有足够的奖励。
    function safeTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            address _rewardAddr = IUSD(usdAddress).rewardTo();
            if (_rewardAddr != address(0)) {
                IUSDReward(_rewardAddr).inviteReward(_to, _amount);
            }

            uint256 _reward = IDepositUSD(depositAddress).getFee();
            if (_amount > _reward) {
                _amount = _reward;
            }
            UserInfo storage user = userInfo[msg.sender];
            user.userReward += _amount;
            IDepositUSD(depositAddress).takeFee(_to, _amount);
            emit Reward(_to, _amount);
        }
    }
}