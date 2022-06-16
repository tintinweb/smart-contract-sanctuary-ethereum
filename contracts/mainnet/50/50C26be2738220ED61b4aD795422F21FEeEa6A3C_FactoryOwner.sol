//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract FactoryOwner {
    receive() external payable {}

    address payable constant contract_dev = payable(0x3b558B92B2B00cDeA8dFadd39818A9EfE67409dA);
    address payable constant designer = payable(0xa302D3E2e71962D014F784820e155a96A1A78d8C);
    address payable constant frontend_dev = payable(0x339E29D563E4983701FAcACba5997DEbBc8AC05F);

    function harvest() public {
        uint bal = address(this).balance;
        contract_dev.transfer(bal * 60 / 100);
        designer.transfer(bal * 20 / 100);
        frontend_dev.transfer(bal * 20 / 100);
    }
}