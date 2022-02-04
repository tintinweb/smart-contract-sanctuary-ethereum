/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract ROI{

    constructor(){
        totalUsers = 0;
    }
    // User Details
    struct User{
        string name;
        uint256 balance;
        uint256 reward;
        uint256 lastTransactionTime;
    }


    uint liquifyLimit = 1000000000000000000;
    uint256 totalUsers;
    address [] Users ;
    mapping(address=>User) public registeredUsers;      // Registered Users
    mapping(address=>bool) public isRegistered;        

    // check if user is registered or not
    modifier onlyUser(){
        require(
            isRegistered[msg.sender]==true,
            "User Not Registered"
        );
        _;
    }

    //@param _name name of the user 
    //@dev  Registers a new user with a registration fee of 0.0169 ether 
    function register(string memory _name) public payable{
        require(isRegistered[msg.sender]==false,"User/Account Already Registered");

        require(msg.value==16900000000000000,"Invalid Registration Fee");

        registeredUsers[msg.sender] = User({
            name : _name,
            balance : 0,
            reward : 0,
            lastTransactionTime:block.timestamp
        });
        isRegistered[msg.sender]= true;
        Users.push(msg.sender);
        totalUsers++;
        if(address(this).balance>=liquifyLimit){
            distribute();
        }
    }

    //@param _ammount Ammount of ether to be deposited
    //@dev User can deposit the ether if registered 
    function deposit(uint256 _ammount) public payable onlyUser returns(uint256){

        require(msg.value == _ammount);

        require(_ammount>0,"Ammount cannot be 0");

        updateReward(msg.sender);
        registeredUsers[msg.sender].balance +=_ammount;
        registeredUsers[msg.sender].lastTransactionTime =block.timestamp;

        if(address(this).balance>=liquifyLimit){
            distribute();
        }

        return registeredUsers[msg.sender].balance;
    }

    //@dev Distribute some ammount when contract balance reaches liquifyLimit
    function distribute() internal {
        uint256 contractBalance = getContractBalance();
        uint256 distAmmount = (contractBalance/100)*67;
        uint256 indAmmount = distAmmount/totalUsers;
        for(uint256 i= 0;i<totalUsers;i++){
            registeredUsers[Users[i]].balance += indAmmount;
        }
    }

    //@dev Calculates the difference of days from the last transaction by the user and accordingly adds the interest on the principal(SIMPLE INTEREST)
    function updateReward(address userAddress) internal {
        uint diffDays = ((block.timestamp-registeredUsers[userAddress].lastTransactionTime)/60/60/24);
        uint principal = registeredUsers[userAddress].balance+registeredUsers[userAddress].reward;
        registeredUsers[msg.sender].reward += ((principal/1000)*171*diffDays);
    }

    //@dev called by User to withdraw certain ammount of funds 
    function withdrawAmmount(address payable userAddress,uint256 _ammount) public onlyUser{
        require(msg.sender==userAddress,"Caller is not the Owner");
        updateReward(msg.sender);

        registeredUsers[msg.sender].lastTransactionTime =block.timestamp;

        require(_ammount<=registeredUsers[msg.sender].balance,"Withdrawal ammount greater than the balance ");

        registeredUsers[msg.sender].balance -=_ammount;
        userAddress.transfer(_ammount);
    } 

    //@dev Called by user to withdraw all his rewards
    function withdrawReward(address payable userAddress) public onlyUser{
        require(msg.sender==userAddress,"Caller is not the Owner");

        uint256 reward = registeredUsers[userAddress].reward; 

        userAddress.transfer(reward);
        registeredUsers[userAddress].reward = 0;

    }
    // get User Balance
    function getUserBalance(address userAddress) public view returns(uint256){
        return registeredUsers[userAddress].balance;
    }
    // get the balance of the Contract
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

}