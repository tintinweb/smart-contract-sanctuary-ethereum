pragma solidity >=0.7.0 <0.9.0;

contract Deposit {
    event BalanceChanged(address indexed _from, uint _value);

    uint totalContractBalance = 0;

    function getContractBalance() public view returns(uint) {
        return totalContractBalance;
    }

    mapping(address => uint) balances;

    function addBalance() public payable {
        balances[msg.sender] += msg.value;
        totalContractBalance += msg.value;
        emit BalanceChanged(msg.sender, balances[msg.sender]);
    }

    function getBalance() public view returns(uint) {
        return balances[msg.sender];
    }

    function withdrawAll() public {
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = balances[msg.sender];

        withdrawTo.transfer(amountToTransfer);

        totalContractBalance -= amountToTransfer;
        balances[msg.sender] = 0;
        emit BalanceChanged(msg.sender, balances[msg.sender]);
    }
}