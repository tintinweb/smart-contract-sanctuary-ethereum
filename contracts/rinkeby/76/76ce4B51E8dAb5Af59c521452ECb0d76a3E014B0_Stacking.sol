// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.4 and less than 0.9.0
pragma solidity ^0.8.4;

import "./uniswap/IERC20.sol";
import "./uniswap/IUniswapV2ERC20.sol";

contract Stacking {
    uint64 rewardPercentage = 10;
    uint64 timeToReward = 10 minutes;
    uint64 timeToUnstake = 20 minutes;
    address private owner;

    IERC20 erc20Token;
    IUniswapV2ERC20 lpToken;

    mapping (address => UserStakings) userStakings;

    struct Staking {
        uint256 balance;
        uint256 reward;
        uint256 rewardAfter;
        uint256 unstakeAfter;
    }

    struct UserStakings {
        uint256 count;
        mapping (uint256 => Staking) stakings;
    }

    event Stack(address indexed user, uint256 indexed amount);
    event Claim(address indexed user, uint256 indexed reward);
    event Unstake(address indexed user, uint256 indexed amount);

    constructor(address erc20Address, address lpTokenaddress) {
        owner = msg.sender;
        erc20Token = IERC20(erc20Address);
        lpToken = IUniswapV2ERC20(lpTokenaddress);
    }

    function stake(uint256 _amount) external {
        lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 count = userStakings[msg.sender].count;
        userStakings[msg.sender].stakings[count].balance = _amount;
        userStakings[msg.sender].stakings[count].reward = _amount * rewardPercentage / 100;
        userStakings[msg.sender].stakings[count].rewardAfter = block.timestamp + timeToReward;
        userStakings[msg.sender].stakings[count].unstakeAfter = block.timestamp + timeToUnstake;
        userStakings[msg.sender].count++;
        emit Stack(msg.sender, _amount);
    }

    function claim() external {
        uint256 count = userStakings[msg.sender].count;
        uint256 totalReward;
        for (uint i = 0; i < count; i++) {
            if (userStakings[msg.sender].stakings[i].reward > 0) {
                if (userStakings[msg.sender].stakings[i].rewardAfter < block.timestamp ) {
                    erc20Token.transfer(msg.sender, userStakings[msg.sender].stakings[i].reward);
                    totalReward += userStakings[msg.sender].stakings[i].reward;
                    userStakings[msg.sender].stakings[i].reward = 0;
                }
            }
        }
        emit Claim(msg.sender, totalReward);
    }

    function unstake() external {
        uint256 count = userStakings[msg.sender].count;
        uint256 totalAmount;
        for (uint i = 0; i < count; i++) {
            if (userStakings[msg.sender].stakings[i].balance > 0) {
                if (userStakings[msg.sender].stakings[i].unstakeAfter < block.timestamp ) {
                    lpToken.transfer(msg.sender, userStakings[msg.sender].stakings[i].balance);
                    totalAmount += userStakings[msg.sender].stakings[i].balance;
                    userStakings[msg.sender].stakings[i].balance = 0;
                }
            }
        }
        emit Unstake(msg.sender, totalAmount);
    }

    function changeRewardPercentage(uint64 _rewardPercentage) external onlyOwner {
        rewardPercentage = _rewardPercentage;
    }

    function changetimeToReward(uint64 _timeToReward) external onlyOwner {
        timeToReward = _timeToReward;
    }

    function changetimeToUnstake(uint64 _timeToUnstake) external onlyOwner {
        timeToUnstake = _timeToUnstake;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}