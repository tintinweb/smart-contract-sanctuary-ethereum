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
    uint256 usdtToLend;

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
        rateOfEth = 1000;
        owner = msg.sender;
        totalStakedAmount = 10000000000000000;
        totalInterest = 10;
    }

    // Function deposit Ethereum and Borrow USDC
    function depositEthBorrowUSDC() public payable {
        require(msg.value > 10, "You can't deposit less than 10 wei");
        uint256 weiAmount = msg.value;
        usdtToLend = (weiAmount * rateOfEth) / 1 ether;
        // Push the borrower address to array, create a struct and push it to mapping of borrower
        // borrowerIDArray.push(msg.sender);
        // borrowerDetail = borrowerStruct(usdtToLend, block.timestamp, 0);
        // borrowerData[msg.sender] = borrowerDetail;
        // require(
        //     usdtToLend < IERC20(usdcTokenAddress).balanceOf(address(this)),
        //     "Contract doesn't have enought USDC."
        // );
        // IERC20(usdcTokenAddress).transfer(msg.sender, usdtToLend);
    }

    function viewUSDTtolend() public view returns (uint256) {
        return usdtToLend;
    }
}