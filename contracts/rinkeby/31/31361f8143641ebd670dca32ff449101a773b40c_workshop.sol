/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract workshop {
    mapping(address=>uint) private balnces;
    mapping(address=>string) private walletName;
    string private name;
    string private symbol;
    uint256 private totalSupply;
    constructor(string memory _name,string memory _symbol ,uint256 _tokenSupply)public{
        name = _name;
        symbol = _symbol;
        balnces[msg.sender] = _tokenSupply;
        totalSupply = _tokenSupply;
    }
    function getname()public view returns(string memory){
        return name;   
    }
    function getsymbol()public view returns(string memory){
        return symbol;
    }
    function getTotalSupply()public view returns(uint){
        return totalSupply;
    }
    function Balnces(address account)public view returns(uint){
        return balnces[account];
    }
    function transfer(address _to,uint amount)public{
        address owner = msg.sender;
        require(balnces[owner] >= amount,"can not tranfer!!!");
        require(owner != _to,"con not tranfer with the same account!!!");
        balnces[owner] -= amount;
        balnces[_to] += amount;
    }
    function setMyWalletName(string memory _name)public{
        walletName[msg.sender] = _name;
    }
    function getWalletName(address _add)public view returns(string memory){
        if(bytes(walletName[_add]).length != 0 ){
            return walletName[_add];
        }
        else{
            return "no username";
        }
    }
}