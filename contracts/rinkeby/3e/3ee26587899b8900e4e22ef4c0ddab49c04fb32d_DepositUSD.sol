/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUSD {
    function owner() external view returns (address);

    function minerTo() external view returns (address);

    function stakeTo() external view returns (address);

    function rewardTo() external view returns (address);

    function inviter(address account_) external view returns (address);
}

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

    function stakeOf(address account_) external view returns (uint256);

    function takeReward(
        address token_,
        string memory usefor,
        address account_,
        uint256 amount_
    ) external;

    function getReward(address token_, string memory usefor)
        external
        view
        returns (uint256);
}

// 存储合约只支持钱,不支持主动存钱
// 为了用户的安全性,在每次升级使用合约后,用户需重新授权
// 在使用合约里面收取token并发送到存储合约-无手续费
contract DepositUSD {
    address public usdAddress; // usd合约

    uint256 public totalStaked; //总质押
    mapping(address => uint256) public stakedOf; // 质押数量

    uint256 public totalFees; //总手续费
    uint256 public totalUsedFees; //已支付手续费

    mapping(address => mapping(string => uint256)) public totalReward; //总奖励 reward[奖励token]
    //奖励使用情况 reward[奖励token][usefor] =》 支付奖励
    // usefor(string) invite(邀请奖励),,,,
    mapping(address => mapping(string => uint256)) public useforReward; //已支付奖励

    constructor(address usd_) {
        usdAddress = usd_;
    }

    modifier onlyUseFor() {
        require(
            msg.sender == minerTo() ||
                msg.sender == stakeTo() ||
                msg.sender == owner(),
            "caller can not be allowed"
        );
        _;
    }

    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) public onlyUseFor {
        TransferHelper.safeTransfer(token_, to_, amount_);
    }

    function stakeUsd(address account_, uint256 amount_) public onlyUseFor {
        totalStaked += amount_;
        stakedOf[account_] += amount_;
    }

    function unstakeUsd(address account_, uint256 amount_) public onlyUseFor {
        totalStaked -= amount_;
        stakedOf[account_] -= amount_;
        TransferHelper.safeTransfer(usdAddress, account_, amount_);
    }

    // 获取可使用的奖励
    function getReward(address token_, string memory usefor)
        public
        view
        returns (uint256)
    {
        return totalReward[token_][usefor] - useforReward[token_][usefor];
    }

    // 请将存储合约加入奖励token白名单使用,以免除手续费溢出
    function depositReward(
        address token_,
        string memory usefor,
        uint256 amount_
    ) public {
        totalReward[token_][usefor] += amount_;
        TransferHelper.safeTransferFrom(
            token_,
            msg.sender,
            address(this),
            amount_
        );
    }

    // 使用奖励
    function takeReward(
        address token_,
        string memory usefor,
        address account_,
        uint256 amount_
    ) public onlyUseFor {
        require(getReward(token_, usefor) >= amount_, "not enough fee");
        useforReward[token_][usefor] += amount_;
        TransferHelper.safeTransfer(token_, account_, amount_);
    }

    function getFee() public view returns (uint256) {
        return totalFees - totalUsedFees;
    }

    function depositFee(uint256 amount_) public {
        require(msg.sender == usdAddress, "only usd can deposit fee");
        totalFees += amount_;
    }

    function takeFee(address account_, uint256 amount_) public onlyUseFor {
        require(getFee() >= amount_, "not enough fee");
        totalUsedFees += amount_;
        TransferHelper.safeTransfer(usdAddress, account_, amount_);
    }

    function owner() public view returns (address) {
        return IUSD(usdAddress).owner();
    }

    function minerTo() public view returns (address) {
        return IUSD(usdAddress).minerTo();
    }

    function stakeTo() public view returns (address) {
        return IUSD(usdAddress).stakeTo();
    }
}