/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract ERC20 {
    // creo una referencia de las funciones que usare en contrato del token
    function transfer(address to, uint256 amount) external  returns (bool){}
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool){}
}
contract RefWine {
    // una
    function withdraw(uint256 amount) public {}
    function balanceOf(address account) public view returns(uint256){}
}

contract Pool {
    address[] public accounts;

    mapping(ERC20 => mapping(address => uint256)) private balance;

    constructor (address[] memory _accounts){
        accounts = _accounts;
    }

    function addToken(ERC20 token, uint256 amount) public{
        //add token
        token.transferFrom(msg.sender, address(this), amount);
        uint256 middle = amount/accounts.length;
        for(uint8 i; i<accounts.length;i++){
            balance[token][accounts[i]] += middle;
        }
    }

    function isAccounts(address account)internal view returns(bool){
        for(uint8 i;i<accounts.length;i++){
            if(accounts[i]==account){
                return true;
            }
        }
        return false;
    }

    function _balanceOf(ERC20 token, address account)public view returns(uint256){
        return balance[token][account];
    }

    function subToken(ERC20 token, uint256 amount) public {
        require(isAccounts(msg.sender),"La cuenta no es valida");
        require(balance[token][msg.sender]>amount,"No tiene suficiente dinero para retirar");
        token.transfer(msg.sender, amount);
        balance[token][msg.sender] -= amount;
    }

    function getFunds(RefWine account)public{
        require(isAccounts(msg.sender),"La cuenta no es valida");
        account.withdraw(account.balanceOf(address(this)));
    }
}