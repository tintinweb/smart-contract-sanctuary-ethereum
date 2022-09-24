// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BankStorage } from "../libraries/LibBank.sol";

contract BankUpgarde {

    BankStorage internal s;

    error notEnough();
    error nullAddress();

    function transfer(uint amount, address _addr) external {
        uint balance = s.userBalance[msg.sender];

        if(balance == 0 && _addr != address(0) ){
            revert notEnough();

        }else{
            s.userBalance[msg.sender] -= amount;
            payable(_addr).transfer(amount);
        }

    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct BankStorage{
    mapping(address => uint) userBalance;
}