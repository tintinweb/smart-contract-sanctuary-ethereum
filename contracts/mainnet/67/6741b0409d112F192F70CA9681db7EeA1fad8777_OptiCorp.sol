//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOptiSwap {
    function collectFees() external;
    function transferOwnership(address newOwner) external; 
}

contract OptiCorp {
    receive() external payable {}

    IOptiSwap opti = IOptiSwap(0x293be20db3e4110670aFBcAE916393e40BC9B42b);
    address payable constant ops = payable(0x133A5437951EE1D312fD36a74481987Ec4Bf8A96);
    address payable constant __ = payable(0x9Dd3e3e1D58CcE3266362Df315e480a1b0616Ce9);
    address payable constant ___ = payable(0x6cf47bd6977a5F1244E0Ad0f9BF51285ea516a0d);
    address payable constant ____ = payable(0xa302D3E2e71962D014F784820e155a96A1A78d8C);
    address payable constant _____ = payable(0x9567C82724D3BBA0AEcd19CEDBbED1818A5AB65A);
    address payable constant ______ = payable(0x1E9671936D1e61110168B2B6B7f29f6a7Fd433CC);
    address payable constant _______ = payable(0x3e590C6CDbc2697fB8dd53D573C69eF0f3a9bEd5);
    address payable constant ________ = payable(0x03c461d0EEAf6d14aeaaF7CE4c7B0cfa72A4665F);
    address payable constant _________ = payable(0x60d7B7F76eaef9F50AdF983D3AB4e54eCf92c9bC);
    address payable constant __________ = payable(0x20463c06AD26cc7BFA2336412455637eABa9e65e);

    function collectFees() public {
        opti.collectFees();
        ops.transfer(address(this).balance / 2);
        uint percent = address(this).balance / 100;
                 __.transfer(55 * percent);
                ___.transfer(20 * percent);
               ____.transfer(10 * percent);
              _____.transfer(5 * percent);
             ______.transfer(2 * percent);
            _______.transfer(2 * percent);
           ________.transfer(2 * percent);
          _________.transfer(2 * percent);
         __________.transfer(2 * percent);

    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == ops, "Only OptiOps.");
        opti.transferOwnership(newOwner);
    }
}