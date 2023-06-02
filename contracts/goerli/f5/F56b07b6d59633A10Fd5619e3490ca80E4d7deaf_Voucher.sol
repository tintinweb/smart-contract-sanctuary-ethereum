/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

pragma solidity >=0.8.2 <0.9.0;


contract Voucher {

    mapping (address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 100;
    }

    function transfer(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "not enough vouchers");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        // aggiungi _amount al saldo del destinatario
    }

}