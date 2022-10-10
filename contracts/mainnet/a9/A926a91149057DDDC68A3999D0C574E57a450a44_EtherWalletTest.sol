// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EtherWalletTest {
    address private immutable _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "You are not an owner!");
        _;
    }
    modifier hasEnougthBalance(uint wantedAmount ) {
        require(wantedAmount <= address(this).balance);
        _;
    }

    event ToppedUp(uint indexed _value, address indexed _from, uint indexed timestamp, uint currentBalance);
    event WithdrawSuccess(uint indexed _value, address indexed _from, uint indexed timestamp, uint currentBalance);
    event WithdrawFailed(address _to, uint indexed timestamp, uint currentBalance);

    constructor () {
        _owner = msg.sender;
    }

    receive() external payable {
        emit ToppedUp(msg.value, msg.sender, block.timestamp,getBalance() );
    }

    function transferTo(uint _amount, address payable _to) external hasEnougthBalance(_amount) onlyOwner{
        (bool success, ) = _to.call { value : _amount }("");
        require(success, "Transaction failed");
        emit WithdrawSuccess(_amount, _to, block.timestamp, getBalance());
    }

    function withdrawAll() external {
        uint availableFunds = address(this).balance;
        require(availableFunds > 0, "Empty balance");
        (bool success, ) = payable(_owner).call{value : availableFunds}("");
        require(success, "Transation fails");
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}