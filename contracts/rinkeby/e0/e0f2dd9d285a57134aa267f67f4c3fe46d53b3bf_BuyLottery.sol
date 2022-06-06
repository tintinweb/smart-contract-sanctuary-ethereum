/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

pragma solidity ^0.4.24;
contract BuyLottery {
    
    address public owner; // gets set somewhere
    
    address[] public investors; // array of investors
   
    mapping(address => uint) public buynumber;

    event setNumber(address _from , uint _num);
    
    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {
        
        require( buynumber[msg.sender]<1);

        investors.push(msg.sender);
        
        buynumber[msg.sender]=1;
      
    }

    function lookNum() public view 
    {
       emit setNumber(msg.sender,buynumber[msg.sender]);

    }

    function backNumber(address _from) public  returns( uint _reslut) 
    {

        return  buynumber[msg.sender];
    }

}