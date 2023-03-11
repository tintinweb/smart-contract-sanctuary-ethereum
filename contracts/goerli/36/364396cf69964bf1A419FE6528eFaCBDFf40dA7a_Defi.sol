// SPDX-License-Identifier: MIT

// USDC Address: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
pragma solidity ^0.8.0;




interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Defi {
    uint256 rateOfEth;
    uint256 totalInterest;
    uint256 totalDepositedEth;

    struct stake {
        uint256 stakingAmount;
        uint256 stakedDate;
        uint256 interestCollected;
    }

    mapping(address => stake) public stakerDetail;
    address[] public stakerAddressArray;

    constructor() {
        rateOfEth = 1500;
        totalInterest = 100;
        totalDepositedEth = 0;
    }

    // Deposit Ethereum
    function depositEth() public payable {
        stake memory stakerData = stake(msg.value, block.timestamp, 0);
        stakerDetail[msg.sender] = stakerData;
        stakerAddressArray.push(msg.sender);
        totalDepositedEth += msg.value;
    }

    // function payInterest() public {
    //     for (uint i = 0; i < stakerAddressArray.length; i++) {
    //     // Get proportion of eth of address
    //     stake storage userStakedDetail = stakerDetail[stakerAddressArray[i]];
    //     uint256 userStakeEth = userStakedDetail.stakingAmount;
    //     fixed128x18 userProportion = userStakeEth/totalDepositedEth;

    //     // Calculate interest with proportion
    //     uint256 userInterest = userProportion * totalInterest;

    //     // Add interest to user
    //     userStakedDetail.interestCollected += userInterest;
    //     }

    //     totalInterest = 0;
    // }

    //Testing
    function checkBalance(address checkInterstOf) view public returns(uint256) {
        return stakerDetail[checkInterstOf].stakingAmount;
    }

    // Testing
    function viewInterest(address checkInterstOf) view public returns(uint256) {
        return stakerDetail[checkInterstOf].interestCollected;
    }

    // Transfer USDC
    function transferUSDC(address recipient, uint256 amount) public {
        IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).transfer(
            recipient,
            amount
        );
    }

    // Get balance of USDC
    function getContractBalance(address checkBalance)
        public
        view
        returns (uint256)
    {
        return
            IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).balanceOf(
                checkBalance
            );
    }

    //Send ETH
    function sendBalance() public {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }
}