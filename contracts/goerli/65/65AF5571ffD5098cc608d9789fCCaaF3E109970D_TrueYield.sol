// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./IWeth.sol";

// interface IaToken {
//     function balanceOf(address _user) external view returns (uint256);
//     function redeem(uint256 _amount) external;
// }

// interface IAaveLendingPool {
//     function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
// }

contract TrueYield {

    // IWeth public iWeth = IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // IaToken public aToken = IaToken(0x22404B0e2a7067068AcdaDd8f9D586F834cCe2c5);
    // IAaveLendingPool public aaveLendingPool = IAaveLendingPool();

    address public owner;

    //Position is just amount of Ether staked by an address at a specific time for some duration
    struct Position {
        uint positionId;
        address walletAddress; //That created the position
        uint createdDate;
        uint unlockDate; //When funds can be withdrawn without penalty
        uint percentInterest;
        uint weiStaked;
        uint weiInterest; //Interest that the user will earn
        bool open;
    }

    Position private position;

    //It will increment after each new position is created
    uint256 public currentPositionId;

    //Every newly created position will be added to this mapping
    mapping (uint => Position) public positions;

    //For user to query all the positions that he has created
    mapping (address => uint[]) public positionIdsByAddress;
    
    //Data for number of days and interest rates
    mapping (uint => uint) public tiers;

    //Array that contains integers for lock periods (30 days, 90 days, 365 days)
    uint256[] public lockPeriods;

    //Payable to allow the deployer of the contract to send Ether to it when its being deployed
    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        tiers[30] = 700; //700 basis points which is 7% APY
        tiers[90] = 1000; //10% APY
        tiers[365] = 1200; //12% APY

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(365);
    }

    function stakeEther(uint numDays) external payable {
        //To make sure that the number of Days belong to one of the tiers
        require(tiers[numDays] > 0, "Mapping not found");

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp, //creation date
            block.timestamp + (numDays * 1 days), //unlock date
            tiers[numDays], //interest rate
            msg.value, //Ether to be staked
            calculateInterest(tiers[numDays], numDays, msg.value), //function to calculate the interest
            true //position status is set to open until user closes it
        );

        //To get the Ids of the positions a user owns
        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
    }

    function calculateInterest(uint basisPoints, uint numDays, uint weiAmount) public pure returns (uint) {
        return basisPoints * weiAmount / 10000;
    }

    function changeLockPeriods(uint numDays, uint basisPoints) external {
        require(owner == msg.sender, "Only owner can modify the staking periods");

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    //Owner can change unlock date for a specific position
    function changeUnlockDate(uint positionId, uint newUnlockDate) external {
        require(owner == msg.sender, "Only owner can change Unlock date");

        positions[positionId].unlockDate = newUnlockDate;
    }

    //Allows the user to un-stake their Ether
    function closePosition(uint positionId) external {
        require(positions[positionId].walletAddress == msg.sender, "Only the creator can modify the position");
        require(positions[positionId].open == true, "Position is closed");

        positions[positionId].open = false;

        //If the user is un-staking before the Unlock period, they won't gain any interest
        if(block.timestamp > positions[positionId].unlockDate) {
            uint amount = positions[positionId].weiStaked + positions[positionId].weiInterest;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Transaction failed");
        } else {
            (bool success, ) = payable(msg.sender).call{value: positions[positionId].weiStaked}("");
            require(success, "Transaction failed");
        }

    }

    /* Getter Functions */

    function getLockPeriods() external view returns(uint[] memory) {
        return lockPeriods;
    }

    function getInterestRates(uint numDays) external view returns(uint) {
        return tiers[numDays];
    }

    function getPositionById(uint positionId) external view returns(Position memory) {
        return positions[positionId];
    }

    function getAllPositionIdsByAddress(address walletAddress) external view returns(uint[] memory) {
        return positionIdsByAddress[walletAddress];
    }

    
}