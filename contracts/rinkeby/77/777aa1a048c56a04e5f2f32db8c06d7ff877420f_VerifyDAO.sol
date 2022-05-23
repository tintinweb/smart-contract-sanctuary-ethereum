/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

/*
Verify DAO is a smart contract/ on-chain implementation of FND's invite system,
with the added capability of flagging wallets that are invited for being sussy
*/

contract VerifyDAO {

    uint public userCount;

    mapping(address => User) public verified;
    address public deployer;
    uint public inviteLimit;
    uint public susTreshold;
    

    constructor (uint _susTreshold, uint _inviteLimit) {
        deployer = msg.sender;
        userCount += 1;
        instantiateUser(deployer, deployer);
        inviteLimit = _inviteLimit;
        susTreshold = _susTreshold;
    }

    // idk if this is stored in the blockchain storage, not memory
    struct User {
        uint userCount;
        address invitee; //address that is verified or is being invited
        bool susflag; //true if sus, false if not sus
        bool isInvited; //for checking if address key is invited
        address invitooor; //parent of the user node who invited the user
        uint susCount; //number of times wallet has been flagged by other verified users
        address[] invitees; //array of addresses that the user invited
        address[] sussed; //array of addresses that the user sussed out
    }

    // contract write functions ----------------------------------------------------------

    //function for inviting a new address to be "verified"
    function invite(address _address) public {
        require(verified[msg.sender].isInvited == true, "You need to be invited/verified to invite another address"); //require that the message sender is already invited
        require(verified[_address].isInvited != true, "You can't invite/verify an address that already is invited/verified" ); //require that the address the message sender is invited is not already invited
        require(verified[msg.sender].invitees.length <= inviteLimit, "You can only invite a certain amount of addresses");
        userCount += 1; //adds to the count of total invited addresses in contract
        instantiateUser(_address, msg.sender); //see function
        verified[msg.sender].invitees.push(_address); //add the address invited to the list of the user who invited
    }

    //function for users to flag a wallet for being sussy
    function flagUser(address _address) public {
        require(verified[msg.sender].isInvited == true, "You need to be invited/verified to flag another address");
        require(verified[_address].isInvited == true, "the wallet you're flagging needs to be invited/verified");
        require(msg.sender != _address, "You can't flag yourself");
        bool flagTheUser = true;
        // check if this the message sender has sussed a wallet address out before
        for (uint i = 0;i < verified[msg.sender].sussed.length; i++){
            if(verified[msg.sender].sussed[i] == _address){
                flagTheUser = false;
            }
        }
        if (flagTheUser){
            verified[msg.sender].sussed.push(_address);
            verified[_address].susCount += 1;
            if (verified[_address].susCount >= susTreshold){
                verified[_address].susflag = true;
            }
        }
    }

    function instantiateUser(address _address, address _invitooor) internal {
        bool flag = false;
        bool isInvited = true;
        uint susCount = 0;
        address[] memory invitees;
        address[] memory sussed;
        verified[_address] = User(
            userCount,
            _address, 
            flag, 
            isInvited, 
            _invitooor, 
            susCount, 
            invitees, 
            sussed
        );
    }

    //read only functions ---------------------------------------
 
    //get individual invitees
    function getInvitees(address _address, uint index) view public returns (address){
        require(verified[_address].invitees.length > 0, "the address has not invited any address yet");
        require(index < verified[_address].invitees.length, "index out of bounds");
        return verified[_address].invitees[index];
    }

    //returns number of addresses invited by the input address
    function getInviteCount(address _address) view public returns(uint){
        return verified[_address].invitees.length;
    }

    //get individual addresses flagged by the input address
    function viewSusList(address _address, uint index) view public returns(address){
        require(verified[_address].sussed.length > 0, "the address has not flagged any address yet");
        require(index < verified[_address].sussed.length, "index out of bounds");
        return verified[_address].sussed[index];
    }

    //returns number of addresses flagged by the input address
    function getSusCount(address _address) view public returns(uint){
        return verified[_address].sussed.length;
    }
}