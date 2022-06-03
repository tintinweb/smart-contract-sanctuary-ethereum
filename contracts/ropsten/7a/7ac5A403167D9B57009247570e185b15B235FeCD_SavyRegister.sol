/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// File: contracts/Registration.sol

pragma solidity ^0.8.7;

contract Registration {

    mapping (address => bool) public registered;

    function register() public {
        require(!isContract(msg.sender), "Contracts are disallowed!");
        registered[msg.sender] = true;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// File: contracts/SavyRegister.sol

pragma solidity ^0.8.7;


contract SavyRegister {

    Registration private target;

    constructor(address _target) {
        target = Registration(_target);
        target.register();
    }
}