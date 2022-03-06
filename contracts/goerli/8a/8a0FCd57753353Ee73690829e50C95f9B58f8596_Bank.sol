pragma solidity ^0.8.11;

contract Bank {
    struct DepositInfo {
        uint256 amount;
        uint256 time;
    }

    mapping(address => DepositInfo[]) public user;
    mapping(address => uint256) public userBalance;

    receive() external payable {
        user[msg.sender].push(DepositInfo({amount : msg.value, time : block.timestamp}));
        userBalance[msg.sender] += msg.value;
    }

    function bankBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function userDepositRecord(address _address) public view returns (DepositInfo[] memory){
        return user[_address];
    }

    function withdrawUser() public {
        require(bankBalance() > 0, "bank empty balance");
        uint256 lastBalance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        (bool succeed,) = msg.sender.call{value : lastBalance}("");
        require(succeed, "withdraw transfer failed");
    }

    function withdrawAll() public {
        require(bankBalance() > 0, "bank empty balance");
        uint256 lastBalance = bankBalance();
        userBalance[msg.sender] = 0;
        (bool succeed,) = msg.sender.call{value : lastBalance}("");
        require(succeed, "withdraw transfer failed");
    }
}