/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity ^0.8.0;
contract Mycontract_sec2{
    //bool status = false;
   // int amount = 0;
    

    //state = attribute
    string _name;
    uint _balance;

    constructor(string memory n , uint b){
        require(b >= 100,"Please Input balance more than 100!!");
        _name = n;
        _balance = b;
    }

    function getBallance() public view returns(uint balance){
        return _balance;
    }
     function getStacticValuePure() public pure returns(uint x){
        return 50;
    }

    // function deposite(uint amount) public{
    //     _balance += amount;
    // }


}