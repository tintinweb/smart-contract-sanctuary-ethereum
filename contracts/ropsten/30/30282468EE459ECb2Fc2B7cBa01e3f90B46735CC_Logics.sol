/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

//SPDX-License-Identifier:MIT
pragma solidity >= 0.5.0 < 0.9.0;

contract Logics{

    address public owner = msg.sender;
    
    event details(string msg, address aderes, uint amount);

    modifier onlyOwner(){
        require(owner == msg.sender, "you are not owner");

        _;
    }

    receive() external payable{}

    mapping(address => uint) public  participants;

    function sendEtherToContract() payable public {
        participants[msg.sender] = msg.value;
    }

    function Balance() public view returns(uint){
        return address(this).balance;
    }

    function getBalanceOwner() view public returns(uint){
        return owner.balance;
    }

    function trnasferBalanceContractToOwner() payable public{
        
       emit details("The contract account and its balance is: ",msg.sender,Balance());
       payable(owner).transfer(Balance());
       emit details("The External Owned Account and its balance is: ",owner ,owner.balance);
    }

    

}