/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Staking {
    address public owner;

    struct Position { //Position-amount of ethers stake by  specific address at a period of time for some length 

        uint positionId;   //1
        address walletAddress; //2
        uint createdDate; //3
        uint unlockDate;   // 4 date at which funds can be withdrawn without incurring a penalty 
        uint percentInterest; //5
        uint weiStaked; //6
        uint weiInterest; //7 interst the user will earn when the position is unlocked 
        bool open;//8
    }

    Position position;
    uint public currentPositionId; //which will increment after each new position created 

    mapping (uint=>Position) public positions; //every newly created position will be added to this mapping & each posiotion will be queriable by the uint id 
    mapping (address=>uint [] )public positionIdsByAddress; //users can query all the position that they have created  
    mapping(uint=> uint) public tiers; //contains data about the number of days and interest rates that user can stake ether at 
    uint[]public lockPeriods; //30 -7%,90-10%,180-12% days 

constructor () payable {
    owner=msg.sender;
    currentPositionId=0;
    tiers[90]=1000;   
    tiers[120]=10500;
    tiers[180]=20000;

    lockPeriods.push(90);
    lockPeriods.push(120);
    lockPeriods.push(180);
} 

function stakeEther(uint numDays) external payable {
    require(tiers[numDays] >0, "Mapping not found"); //number of days an token can be put to staking days has to pre-approved 

    positions [currentPositionId] = Position  /*create a position if passing no.of days,pass the instance of Position struct*/(currentPositionId,  //1
    msg.sender,   //2
    block.timestamp, //3
    block.timestamp + (numDays * 1 days),// 4 to get unlock date 
    tiers[numDays],  //5 interest rate 
    msg.value,   //6 ether staked 
    calculateInterest(tiers[numDays],numDays,msg.value),  //7 
    true   //8
    );

    positionIdsByAddress[msg.sender].push(currentPositionId); //positionIdsByAddress allows the user to pass in address and get the position they owns 
    currentPositionId +=1;
}


function calculateInterest (uint basisPoints, uint numDays ,uint weiAmount) private pure returns (uint) {
    return basisPoints* weiAmount/10000; //e.g 700/10000=0.07%  interest arned in wei 
} 
// function to change lock period for the original deployer 
function modifyLockPeriods(uint numDays, uint basisPoints) external {
    require (owner ==msg.sender, "Only owner can modify staking periods");

tiers[numDays] =basisPoints;  //new tier for corresponding interest days apart from 30,90 & 180 
lockPeriods.push(numDays);
}

function getLockPeriods ()external view returns(uint[] memory) {
    return lockPeriods;
}

function getInterestRate (uint numDays) external view returns(uint) {
  return tiers[numDays];
}

function getPositionById(uint positionId) external view returns (Position memory){
    return positions[positionId];
}

function getPositionIdsForAddress(address walletAddress) external view returns (uint []memory) {
return positionIdsByAddress[walletAddress];
}

//allow owner to changeUnlockDate for a postion
function changeUnlockDate (uint positionId,uint newUnlockDate) external {
    require (owner ==msg.sender, "Only owner can modify unlock dates");

    positions[positionId].unlockDate=newUnlockDate;
}

//allows user to unstake ethers 
function closePosition (uint positionId) external {
    require (positions[positionId].walletAddress ==msg.sender, "Only position creator can modify position");
    require (positions[positionId].open ==true, "Position is closed");

    positions[positionId].open =false;         //position is set to closed 

}

}