/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

//SPDX-License-Identifier: MIT

pragma solidity = 0.7.0;

contract GoFundMe {


    // function:
    // function name(<param>) <type> <visibility> returns <dataype> { }

    // datatype:
    // - int, uint, uint256, uint8,
    // - string --> arr[], bool, address, bytes

    // type:
    //     - pure: No state is changed, no read/write, return 2+2
    //     - view: Only reads data, cannot change state
    //     - payable: Allows transactions 

    // visibility: 
    // - public: Everyone can exe
    // - private: Only run withing the contract
    // - internal: within the contract + derived contract
    // - external: nobody can run but 3rd (external)

    address Bob = 0x5d231A2fcD30e3a5494662d07E47Fe883BDB5413;
    uint256 MinWei = 10000000000000000; //0.01E

    function getBalance() view public returns (uint256) {
        //this: instance of the Contract
        return address(this).balance;
    }

    function fund() payable external { 
        require(msg.sender != Bob, "Ok, Bob...");
        require(msg.value >= MinWei, "Try sending more ETH.");
    }

    function withdraw() payable external {
        //msg.sender: whoever is interacting with the contract.
        require(msg.sender == Bob, "This is only for Bob!");
        msg.sender.transfer(address(this).balance);
    }

}