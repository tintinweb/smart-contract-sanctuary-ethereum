/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

pragma solidity ^0.8.0;

contract Mox {
    // INSECURE
    mapping (address => uint) public userBalances;
    event  Deposit(address indexed dst, uint wad);

    fallback() external payable {
        deposit();
    }
    function deposit() public payable {
        userBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawBalance() public {
        uint amountToWithdraw = userBalances[msg.sender];
        (bool success, ) = address(msg.sender).call{value: amountToWithdraw}(""); // At this point, the caller's code is executed, and can call withdrawBalance again
        require(success);
        userBalances[msg.sender] = 0;
        }
}