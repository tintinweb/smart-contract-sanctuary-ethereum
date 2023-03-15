// SPDX-License-Identifier: MIT

// USDC Address: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F

// Doployed contract: 0xaF0C7d727444b73feAfbf5215e9fE2bf4180F685
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Defi {
    uint256 interestRate;
    uint256 rateOfEth;
    address owner;
    uint256 totalStakedAmount;
    uint256 totalCollectedInterest;
    address usdcTokenAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    uint256 usdtToLend = 1;

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
        uint256 collateralAmount;
        uint256 borrowedDate;
        uint256 interestToPay;
        uint256 rateOfEthWhenBorrowed;
    }

    borrowerStruct public borrowerDetail;
    mapping(address => borrowerStruct) public borrowerData;
    address[] public borrowerIDArray;

    constructor() {
        interestRate = 2;
        rateOfEth = 1000000000;
        owner = msg.sender;
        totalStakedAmount = 0;
        totalCollectedInterest = 0;
    }

    // Functions deposit Ethereum and Borrow USDC
    function depositEthBorrowUSDC() public payable {
        require(
            msg.value > 1000000000000000,
            "You can't deposit less than 0.001 ether"
        );
        uint256 weiAmount = msg.value;
        usdtToLend = weiAmount / rateOfEth;
        // Push the borrower address to array, create a struct and push it to mapping of borrower
        borrowerIDArray.push(msg.sender);
        borrowerDetail = borrowerStruct(
            usdtToLend,
            msg.value,
            block.timestamp,
            0,
            rateOfEth
        );
        borrowerData[msg.sender] = borrowerDetail;
        require(
            usdtToLend < IERC20(usdcTokenAddress).balanceOf(address(this)),
            "Contract doesn't have enought USDC."
        );
        IERC20(usdcTokenAddress).transfer(msg.sender, usdtToLend);
    }

    // Function to calculate interest amount
    function calculateInterestAmount() public {
        borrowerData[msg.sender].interestToPay +=
            borrowerData[msg.sender].borrowedAmount /
            100;
    }

    // Function to pay interest
    function payInterest(uint256 amount) public {
        uint256 interestToPay = borrowerData[msg.sender].interestToPay;
        IERC20(usdcTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(
            interestToPay - amount > 0,
            "You can't pay more interest than total interest to pay."
        );
        borrowerData[msg.sender].interestToPay = interestToPay - amount;
        totalCollectedInterest = totalCollectedInterest + amount;
    }

    // Function to liquidate
    function liquidate() public {
        for (uint256 i = 0; i < borrowerIDArray.length; i++) {
            if (
                borrowerData[borrowerIDArray[i]].interestToPay >=
                borrowerData[borrowerIDArray[i]].borrowedAmount / 2
            ) {
                borrowerData[borrowerIDArray[i]].collateralAmount = 0;
                borrowerData[borrowerIDArray[i]].interestToPay = 0;
                borrowerData[borrowerIDArray[i]].borrowedAmount = 0;
            }
        }
    }

    function repayUSDC(uint256 amount) public {
        bool success = IERC20(usdcTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Transfer not successful.");
        require(
            amount ==
                borrowerData[msg.sender].borrowedAmount +
                    borrowerData[msg.sender].interestToPay,
            "Repayment amount is not equal to borrowed amount."
        );

        // Check if price of ETH is less than 30% when borrowed
        require(
            rateOfEth >
                (borrowerData[msg.sender].rateOfEthWhenBorrowed * 2) / 3,
            "Price of collateral is too low, please wait until the price is higher."
        );

        // Pay collateral amount
        address payable recipient = payable(msg.sender);
        recipient.transfer(borrowerData[msg.sender].collateralAmount);

        // Deduct from mapping
        borrowerData[msg.sender].collateralAmount = 0;
        borrowerData[msg.sender].interestToPay = 0;
        borrowerData[msg.sender].borrowedAmount = 0;
    }

    // -------------------Functions to deposit USDC and earn interest---------------------------

    //Deposit USDC
    function depositUSDCEarnInterest(uint256 amount) public {
        // Send USDC to contract
        require(amount > 0, "Deposit more than 0 usdc");
        IERC20(usdcTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        stake storage userStake = stakerData[msg.sender];
        totalStakedAmount += amount;
        if (userStake.stakingAmount > 0) {
            userStake.stakingAmount += amount;
        } else {
            stakerDetail = stake(amount, block.timestamp, 0);
            stakerData[msg.sender] = stakerDetail;
            stakerId.push(msg.sender);
        }
    }

    // Function to withdraw deposited USDC
    function withdrawUSDC() public {
        require(
            stakerData[msg.sender].stakingAmount > 0,
            "You either didn't staked or have been liquidated for not paying interest on time."
        );
        uint256 usdcToReturn = stakerData[msg.sender].stakingAmount +
            stakerData[msg.sender].collectedInterest;
        stakerData[msg.sender].stakingAmount = 0;
        stakerData[msg.sender].collectedInterest = 0;
        IERC20(usdcTokenAddress).transfer(msg.sender, usdcToReturn);
    }

    // Function to distributed interest
    function distributeInterest() public {
        for (uint256 i = 0; i < stakerId.length; i++) {
            uint256 calculateProportion = (stakerData[stakerId[i]]
                .stakingAmount * 1000000) / totalStakedAmount;
            stakerData[stakerId[i]].collectedInterest +=
                (calculateProportion * totalCollectedInterest) /
                1000000;
        }
        totalCollectedInterest = 0;
    }

    // Function to claim interest
    function claimInterest() public {
        bool success = IERC20(usdcTokenAddress).transfer(
            msg.sender,
            stakerData[msg.sender].collectedInterest
        );
        require(success, "Transfer unsuccessful");
        stakerData[msg.sender].collectedInterest = 0;
    }

    // Some test functions to view
    // Get data of given address
    function depositedUSDCOfAddress(
        address addressReceipient
    ) public view returns (uint256) {
        return stakerData[addressReceipient].stakingAmount;
    }

    function viewTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }

    function viewTotalCollectedInterest() public view returns (uint256) {
        return totalCollectedInterest;
    }
}