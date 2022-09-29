/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

pragma solidity 0.8.14;

contract MyFirstContract {
    event LogReceive(address _from, uint256 amount);
    event LogWithdraw(address _to, uint256 amount);
    event LogMsg(string message);

    string public storedMsg;
    address public owner;


    constructor() {
        storedMsg = "DeFi For Dummies";
        owner = msg.sender;
        emit LogMsg(storedMsg);
    }

    receive() external payable {
        emit LogReceive(msg.sender, msg.value);
    }

    function withdraw(address payable _to, uint256 amount) public {
        require(msg.sender == owner, "not the owner");
        require(address(this).balance >= amount, "insufficient funds");
        _to.transfer(amount);
        emit LogWithdraw(_to, amount);
    }

    function updateMsg(string memory newMsg) public {
        storedMsg = newMsg;
        emit LogMsg(storedMsg);
    }

}