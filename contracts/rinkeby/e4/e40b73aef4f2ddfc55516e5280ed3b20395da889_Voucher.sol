/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity >=0.7;

contract Voucher {

    // tabella con due righe: chi e quanto

    mapping(address => uint256) public balances;

    constructor () {
        balances[msg.sender] = 100;
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Not enogh funds.");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

}