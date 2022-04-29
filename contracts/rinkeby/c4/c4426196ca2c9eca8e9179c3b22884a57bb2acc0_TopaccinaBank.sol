/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.8;

contract TopaccinaBank{
    //info about contract creator 
    address payable public bankCreator;
    uint public bankCreatorBalance;
    //store client deposits
    mapping(address=>uint) private balances;


    constructor (){
        bankCreator= payable(msg.sender) ;
    }

    function leaveTip(uint amount) external payable{
        bankCreatorBalance+=amount;

    }

    function deposits() external payable{
        balances[msg.sender]+=msg.value;
    }

    function withdraw(uint amount) external payable{
        require(balances[msg.sender]>= amount,"request exceed current balance");
        (bool sent, bytes memory data)=payable(msg.sender).call{value:amount}("");
        require(sent, "withdraw failed");
        balances[msg.sender]-=amount;

    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function getBankCreatorTips() public view returns (uint){
        return bankCreatorBalance;
    }

}