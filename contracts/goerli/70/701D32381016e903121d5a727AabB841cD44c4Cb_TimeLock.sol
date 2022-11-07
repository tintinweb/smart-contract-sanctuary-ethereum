pragma solidity ^0.8.17;

contract TimeLock {
    mapping(address => uint) public locks;
    mapping(address => uint) public balances;
    uint256 public transactionValue;


    event Deposit(address from, uint current_block, uint until_block, uint value);
    event Withdraw(address to, uint current_block, uint value);

    error DepositUnavailable(uint current_block);
    error WithdrawUnavailable(uint current_block, uint available_at);

    function deposit(uint64 timelock) external payable {
        if (balances[msg.sender] > 0 && locks[msg.sender] > 0)
            revert DepositUnavailable({current_block: block.number});
        balances[msg.sender] += msg.value;
        locks[msg.sender] = (block.number + timelock);
        emit Deposit(msg.sender, block.number, locks[msg.sender], balances[msg.sender]);
    }

    function withdraw() external {
        if (block.number < locks[msg.sender])
            revert WithdrawUnavailable({current_block: block.number, available_at: locks[msg.sender]});
        transactionValue = balances[msg.sender];
        balances[msg.sender] = 0;
        locks[msg.sender] = 0;
        (bool sent,bytes memory data) = msg.sender.call{value: transactionValue}("");
        require(sent, "Failure During Withdraw");
        emit Withdraw(msg.sender, block.number, transactionValue);
    }
}