/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity 0.8.0;
contract token{
    string name;
    string symbol;
    uint total_supply;
   constructor(string memory _name,string memory _symbol,uint _total_supply){
        name = _name;
        symbol = _symbol;
        total_supply=_total_supply;
    } 
    function tokenname() public view returns(string memory){
        return name;
    }
    function symbolname() public view returns(string memory){
        return symbol;
    }
    function totalsupply() public view returns(uint){
        return total_supply;
    }
}