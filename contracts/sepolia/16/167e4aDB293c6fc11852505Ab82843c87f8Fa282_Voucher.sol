/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

pragma solidity ^0.8.0;

contract Voucher{

    mapping(address => uint256) balances;

    //we want a "close system" only some account can have our token
   // mapping (address => bool) whitelist;

    //we have to distribute some initial voucher
    constructor(){
        //the sender of a constructor is the creator of the contract (io)
        balances[msg.sender] = 100;
    }

    function transfer(address _to, uint256 _amount) external {
        //require(whitelist[_to]);
        require(balances[msg.sender] >= _amount, "not enough funds");
        // decrease sender's balance by _amount
        // non ha senso controllare se il sender ha abbastanza soldi perche uint256 non puo essere negativo
        balances[msg.sender] -= _amount;
        // increase receiver's balance
        balances[_to] += _amount;
    }


}