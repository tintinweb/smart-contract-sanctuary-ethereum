/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.8.7;
contract destrctor{
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    
    function getMoney()public payable{
    }

    function withdrawMoney(address payable _to)public{
        _to.transfer(address(this).balance);
    }
    
    
    function getbalance()public view returns(uint){
        return address(this).balance;
    }


    function selfDestructor(address payable _to)public{
        selfdestruct(_to);
    }
    

}