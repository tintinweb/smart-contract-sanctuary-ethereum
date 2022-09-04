/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract SimplePaymentSplitter {
    address payable owner1 =
        payable(0x8742f2258DAc8E695e1706d8a70bF3E2AB57a594);
    address payable owner2 =
        payable(0xF679124a6d86bB6c2c7B86d476341AB7468D3AE6);
    address payable owner3 =
        payable(0x991D3F3310B82BA2CCAA4200F996D4b9877E2E95);
    address payable owner4 = payable(address(0));

    function setOwner4(address newAddress) public {
        owner4 = payable(newAddress);
    }

    function distribute() public {
        uint256 amount = address(this).balance / 4;

        owner1.transfer(amount);
        owner2.transfer(amount);
        owner3.transfer(amount);
        owner4.transfer(amount);
    }

    // Receive any ether sent to the contract.
    receive() external payable {}
}