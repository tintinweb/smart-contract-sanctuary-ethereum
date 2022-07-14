// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract Mteam{

    uint penaltyTime;
    uint public totalBalance;

    struct Util{
        uint timeAdded;
        uint timeWhenSafe;                                                              //unnecessary occupation of memory, only here for simplicity
        uint balance;
    } 

    mapping(address => Util) userInfo;

    address[] allUsers;

    /*modifier onlyOwner{
        require(msg.sender==admin, "YOu are not admin");
        _;
    }*/

    constructor(uint penTime){
        penaltyTime = penTime;
        totalBalance = 0;
    }

//__________________________________________________________________________//



    function removeUserFromList(address user) private {                            //maybe could be optimised
        for(uint i=0; i<allUsers.length; i++){
            if(user == allUsers[i]){
                allUsers[i] = allUsers[allUsers.length - 1];
                allUsers.pop();
                break;
            }
        }
    }

    function distributePenaltyFee(uint amount) private{
        for(uint i=0; i<allUsers.length; i++){
            if(allUsers[i] == msg.sender) continue;
            uint percentage = (userInfo[allUsers[i]].balance)*100 / totalBalance;
            userInfo[allUsers[i]].balance += percentage * amount;
        }
    }

    function calculatePenaltyRate() private view returns (uint){                         //returns percentage of tokens that user will be penalised by
        Util memory temp = userInfo[msg.sender];
        if(block.timestamp > temp.timeWhenSafe) return 0;
        return (temp.timeWhenSafe - temp.timeAdded) * 50 / (temp.timeWhenSafe - block.timestamp);
    }

    function newUserDeposit() private {                                                 //maybe should be payable
        allUsers.push(msg.sender);                                                      //msg.value maybe not accessible cause of depth of call stack
        userInfo[msg.sender] = Util({timeAdded:block.timestamp, timeWhenSafe:block.timestamp+penaltyTime, balance:msg.value});
        //call aave
    }

    function existingUserDeposit() private {
        uint currentBalance = userInfo[msg.sender].balance;                                                     //maybe should be payable
        userInfo[msg.sender] = Util({timeAdded:block.timestamp, timeWhenSafe:block.timestamp+penaltyTime, balance:msg.value + currentBalance});   //msg.value maybe not accessible cause of depth of call stack
        //call aave
    }

    function depositTokens() public payable {
        if(userInfo[msg.sender].timeAdded == 0){
            newUserDeposit();
        }
        else{
            existingUserDeposit();
        }
        totalBalance += msg.value;
    }

    function withdrawTokens() public{

        uint balance = userInfo[msg.sender].balance;
        userInfo[msg.sender].balance = 0;
        uint penaltyRate = calculatePenaltyRate();
        address payable receiver = payable(msg.sender);
   
   
        distributePenaltyFee(penaltyRate * balance);

        totalBalance -= balance * ((100 - penaltyRate) / 100);
        receiver.transfer(balance * penaltyRate);
        removeUserFromList(msg.sender);
    }

    function getBalance(address user) public view returns(uint){
        return userInfo[user].balance;
    }

    function getMyBalance() public view returns (uint) {
        return userInfo[msg.sender].balance;
    }

    function screwOverUser() public{
            //
    }

}