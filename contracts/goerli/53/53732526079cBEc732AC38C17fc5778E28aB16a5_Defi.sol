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
    uint256 interestRate;
    uint256 rateOfEth;

    struct stake {
        uint256 stakingAmount;
        address stakerAddress;
        uint256 stakedDate;
    }

    stake[] public asdf;

    constructor() {
        interestRate = 2;
        rateOfEth = 1500;
    }

    // Deposit Ethereum
    function depositEth() public payable {}

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