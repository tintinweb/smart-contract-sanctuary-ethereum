pragma solidity ^0.8.7;

contract IterableMapping{

    mapping(address => uint) public balances;
    mapping(address => bool) public inserted;
    address[] public wallets;

    function setWallet(address _address,uint _balances) public{
        balances[_address]=_balances;
        if (!inserted[_address]){
            inserted[_address]=true;
            wallets.push(_address);
        }

    }
    
    function getWalletLen() view public returns(uint) {
       return  wallets.length;
    }

    function getFirstBalances() view public returns(uint) {
        return balances[wallets[0]];
    }
     function getLastBalances() view public returns(uint) {
        return balances[wallets[wallets.length-1]];
    }

    function getBalances(uint _id) view public returns(uint){
        return balances[wallets[_id]];
    }


}