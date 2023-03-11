// SPDX-License-Identifier: MIT

// USDC Address: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
pragma solidity >=0.8.0 <0.9.0;

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
    address owner;
    uint256 totalStakedAmount;
    uint256 totalInterest;
    address usdcTokenAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;

    // Store stakers data
    struct stake {
        uint256 stakingAmount;
        uint256 stakedDate;
        uint256 collectedInterest;
    }
    stake public stakerDetail;
    mapping(address => stake) public stakerData;
    address[] public stakerId;

    // Store borrowers data
    struct borrowerStruct {
        uint256 borrowedAmount;
        uint256 borrowedDate;
        uint256 interestToPay;
    }

    borrowerStruct public borrowerDetail;
    mapping(address => borrowerStruct) public borrowerData;
    address[] public borrowerIDArray;

    constructor() {
        interestRate = 2;
        rateOfEth = 1500;
        owner = msg.sender;
        totalStakedAmount = 10000000000000000;
        totalInterest = 10;
    }

    // Function deposit Ethereum and Borrow USDC
    function depositEthBorrowUSDC() public payable returns (uint256) {
        uint256 collateralETHValue = msg.value / 1 ether;
        uint256 usdtToLend = collateralETHValue * rateOfEth;

        return usdtToLend;
    }
}