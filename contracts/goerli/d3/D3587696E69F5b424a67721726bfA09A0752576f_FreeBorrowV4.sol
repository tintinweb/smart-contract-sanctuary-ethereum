/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IApplicant {
    function do_anything_and_repay(address sender, uint256 amount) external;
    function receive_ether() payable external;
}

interface IFreeBorrow {
    function add_liquidity() payable external;
    function borrow_and_repay(address to, uint256 amount) external;
}


contract FreeBorrowV4 is IFreeBorrow {
    address payable public admin_address = payable(0xeE10A22A0542C6948ee8f34A574a57eB163aCaD0);

    function add_liquidity() public payable {}

    function clean_liquidity() public {
        require(msg.sender == admin_address, "Only the admin address can call this function.");
        admin_address.transfer(address(this).balance);
    }


    function borrow_and_repay(address to, uint256 amount) public {
        uint256 balance = address(this).balance;
        emit print_tmp1(address(this).balance);

        require(address(this).balance >= amount, "Insufficient liquidity in contract.");
        IApplicant(to).receive_ether{value: amount}();
        emit print_tmp2(address(this).balance);

        IApplicant(to).do_anything_and_repay(address(this), amount);
        emit print_tmp3(address(this).balance);
        
        require(address(this).balance >= balance, "Liquidity should not decrease.");
        emit print_borrow_and_repay(to, amount);
    }


    event print_borrow_and_repay(address to, uint256 amount);
    event print_tmp1(uint256 amount);
    event print_tmp2(uint256 amount);
    event print_tmp3(uint256 amount);
}