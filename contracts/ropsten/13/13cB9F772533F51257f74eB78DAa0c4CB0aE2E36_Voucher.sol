pragma solidity >= 0.7;

contract Voucher {

    mapping (address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 100;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "non hai abbastanza voucher");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }



}