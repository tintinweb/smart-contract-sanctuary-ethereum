/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

contract WalletOne {
    address public owner;
    mapping (address => uint) balances;

    constructor() {
        owner = msg.sender;
    }

    error InsufficientBalance(uint requested, uint balance);

    event SuccessfulTransfer(address sender, address reciever, uint amount);

    function sendAmount(uint amount, address reciever) public payable {
        if(balances[msg.sender] < amount)
            revert InsufficientBalance({requested: amount, balance: balances[msg.sender]});
        
        emit SuccessfulTransfer(msg.sender, reciever, amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[reciever] = balances[reciever] + amount;
    }
}