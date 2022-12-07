// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract GaugeV2Interface {
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);

    function _ve() external view returns (address) {}

    function balanceOf(address) external view returns (uint256) {}

    function batchEarned(
        address token,
        address account,
        uint256 runs
    ) external returns (uint256) {}

    function batchRewardPerToken(address token, uint256 maxEndIndex) external {}

    function bribe() external view returns (address) {}

    function checkpoints(address, uint256)
        external
        view
        returns (uint256 timestamp, uint256 balanceOf)
    {}

    function claimFees()
        external
        returns (uint256 claimed0, uint256 claimed1)
    {}

    function deposit(uint256 amount, uint256 tokenId) external {}

    function depositAll(uint256 tokenId) external {}

    function derivedBalance(address account) external view returns (uint256) {}

    function derivedBalances(address) external view returns (uint256) {}

    function derivedSupply() external view returns (uint256) {}

    function earned(address token, address account)
        external
        view
        returns (uint256)
    {}

    function factoryAddress() external view returns (address _factory) {}

    function fees0() external view returns (uint256) {}

    function fees1() external view returns (uint256) {}

    function getPriorBalanceIndex(address account, uint256 timestamp)
        external
        view
        returns (uint256)
    {}

    function getPriorRewardPerToken(address token, uint256 timestamp)
        external
        view
        returns (uint256, uint256)
    {}

    function getPriorSupplyIndex(uint256 timestamp)
        external
        view
        returns (uint256)
    {}

    function getReward(address account, address[] memory tokens) external {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(
        address _stake,
        address _bribe,
        address __ve,
        address _voter
    ) external {}

    function isReward(address) external view returns (bool) {}

    function lastEarn(address, address) external view returns (uint256) {}

    function lastTimeRewardApplicable(address token)
        external
        view
        returns (uint256)
    {}

    function lastUpdateTime(address) external view returns (uint256) {}

    function left(address token) external view returns (uint256) {}

    function notifyRewardAmount(address token, uint256 amount) external {}

    function numCheckpoints(address) external view returns (uint256) {}

    function periodFinish(address) external view returns (uint256) {}

    function rewardPerToken(address token) external view returns (uint256) {}

    function rewardPerTokenCheckpoints(address, uint256)
        external
        view
        returns (uint256 timestamp, uint256 rewardPerToken)
    {}

    function rewardPerTokenNumCheckpoints(address)
        external
        view
        returns (uint256)
    {}

    function rewardPerTokenStored(address) external view returns (uint256) {}

    function rewardRate(address) external view returns (uint256) {}

    function rewards(uint256) external view returns (address) {}

    function rewardsListLength() external view returns (uint256) {}

    function stake() external view returns (address) {}

    function supplyCheckpoints(uint256)
        external
        view
        returns (uint256 timestamp, uint256 supply)
    {}

    function supplyNumCheckpoints() external view returns (uint256) {}

    function tokenIds(address) external view returns (uint256) {}

    function totalSupply() external view returns (uint256) {}

    function userEarnedStored(address, address)
        external
        view
        returns (uint256)
    {}

    function userRewardPerTokenStored(address, address)
        external
        view
        returns (uint256)
    {}

    function voter() external view returns (address) {}

    function withdraw(uint256 amount) external {}

    function withdrawAll() external {}

    function withdrawToken(uint256 amount, uint256 tokenId) external {}
}