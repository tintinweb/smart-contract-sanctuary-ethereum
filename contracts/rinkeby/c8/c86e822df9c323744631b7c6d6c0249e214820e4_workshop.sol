/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT
// this contract was create for educate 
// by KUBCS Developer Team 1
contract workshop{
    mapping(address=>uint256) private balances;
    mapping(address=>string) private walletName;
    string private name;
    string private symbol;
    uint256 private totalSupply;

    constructor(string memory _name, string memory _symbol, uint256 _tokenSupply ){
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = _tokenSupply;
        totalSupply = _tokenSupply;
    }
    function getName() public view returns(string memory){
      return name;
    }
    function getSymbol() public view returns(string memory){
      return symbol;
    }
    function balanceOf(address account)public view returns(uint256){
       return balances[account];
    }
    function getTotalSupply()public view returns(uint256){
      return totalSupply;
    }

    function transfer(address _to, uint256 amount) public{
        address owner = msg.sender;
        uint256 ownerBalance = balances[owner];
        require(ownerBalance >= amount, "transfer amount exceeds balance");
        require(_to !=  owner, "can't transfer amount with the same account");
        balances[owner] = ownerBalance - amount;
        balances[_to] += amount;
    }
    function setMyWalletName(string memory _name) public {
        walletName[msg.sender] = _name;
    }

    function getWalletName(address _wallet) public view returns(string memory) {
        if(bytes(walletName[_wallet]).length != 0){
            return walletName[_wallet];
        }
        return "No username";
    } 

}