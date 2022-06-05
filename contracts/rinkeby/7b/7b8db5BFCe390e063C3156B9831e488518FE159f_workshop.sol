/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract workshop {
    mapping(address=>uint) private balnces;
    mapping(address=>string) private walletname;
    string private name;
    string private Symbol;
    uint private totalSupply;
    constructor(string memory _name,string memory _Symbol ,uint _totalSupply)public{
        name = _name;
        Symbol = _Symbol;
        balnces[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
    }
    function getname()public view returns(string memory){
        return name;   
    }
    function getsymbol()public view returns(string memory){
        return Symbol;
    }
    function getTotalSupply()public view returns(uint){
        return totalSupply;
    }
    function Balnces(address acc)public view returns(uint){
        return balnces[acc];
    }
    function transfer(address _to,uint amount)public{
        address owner = msg.sender;
        require(balnces[owner] >= amount,"can not tranfer!!!");
        require(owner != _to,"con not tranfer with the same account!!!");
        balnces[owner] -= amount;
        balnces[_to] += amount;
    }
    function setWalletname(string memory _name)public{
        walletname[msg.sender] = _name;
    }
    function getwalletname(address _add)public view returns(string memory){
        if(bytes(walletname[_add]).length != 0 ){
            return walletname[_add];
        }
        else{
            return "no name";
        }
    }
}