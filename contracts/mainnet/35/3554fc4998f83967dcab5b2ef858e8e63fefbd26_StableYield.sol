/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDFV {
    function deposit(uint256 numberRLP, uint256 numberDELTA) external;
    function addNewRewards(uint256 amountDELTA, uint256 amountWETH) external;
}

contract StableYield {

    address constant DEV_ADDRESS = 0x5A16552f59ea34E44ec81E58b3817833E9fD5436;
    IERC20 constant DELTA = IERC20(0x9EA3b5b4EC044b70375236A281986106457b20EF);
    address constant DFV_ADDRESS = 0x9fE9Bb6B66958f2271C4B0aD23F6E8DDA8C221BE;
    IDFV constant DFV = IDFV(DFV_ADDRESS);

    address public dao_address;

    modifier onlyDev() {
        require(msg.sender == DEV_ADDRESS || msg.sender == dao_address, "Nope");
        _;
    }

    uint256 weeklyDELTAToSend;
    uint256 lastDistributionTime;
    bool enabled;
    uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant SECONDS_PER_WEEK = 604800;

    uint256 weeklyTip; // Amount of DELTA you get per block for calling distribute()

    constructor() {
        lastDistributionTime = 1645115480;
        dao_address = msg.sender;
    }

    function setDAO(address _dao_address) public onlyDev {
        dao_address = _dao_address;
    }

    function enableWithDefaults() external onlyDev {
        enable(25000e18, 20e18);
    }

    function enable(uint256 weeklyAmount, uint256 weeklyIncentiveAmount) public onlyDev {
        weeklyDELTAToSend = weeklyAmount;
        weeklyTip = weeklyIncentiveAmount;
        enabled = true;
    }
    function approveDFV() external {
        DELTA.approve(DFV_ADDRESS, MAX_INT);
    }
    function disable() external onlyDev {
        enabled = false;
    }

    function distribute() external {
        require(block.timestamp > lastDistributionTime + 120, "Too soon");
        require(enabled, "Distributions disabled");
        uint256 timeDelta = block.timestamp - lastDistributionTime;
        if(timeDelta >= SECONDS_PER_WEEK) {
            // Capped at one week worth of rewards per distribution. Better call it :o
            timeDelta = SECONDS_PER_WEEK;
        }
        uint256 percentageOfAWeekPassede4 = (timeDelta * 1e4) / SECONDS_PER_WEEK;
        uint256 distribution = (weeklyDELTAToSend * percentageOfAWeekPassede4) / 1e4;
        uint256 tip = (weeklyTip * percentageOfAWeekPassede4) / 1e4;
        require(distribution > 0);
        
        DFV.addNewRewards(distribution, 0);
        DELTA.transfer(msg.sender, tip);
        DFV.deposit(0,1);
        lastDistributionTime = block.timestamp;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual onlyDev {
        IERC20(tokenAddress).transfer(DEV_ADDRESS, tokenAmount);
    }

    function die(uint256 nofuckery) external onlyDev payable {
        require(nofuckery==175, "Oooops");
        selfdestruct(payable(DEV_ADDRESS));
    }
    
}