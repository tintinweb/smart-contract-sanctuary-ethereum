/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


interface IApplicant {
    function do_anything_and_repay(address sender, uint256 amount) external;
}

interface IFreeBorrow {
    function borrow_and_repay(address to, uint256 amount) external;
}

contract ApplicantV1 is IApplicant {
    string public passport = "US: qduojheddvdetrss";

    address public free_borrow_contract_address = 0x2ab2E93291d2d2EE03e30652aDc33f049c4fda18;
    address public prove_rich_contract_address = 0x3d3a47382c0c5eED05820f1a9BD0A9DA872Af641;

    function do_anything_and_repay(address sender, uint256 amount) public {
        payable(prove_rich_contract_address).transfer(amount);
        payable(sender).transfer(amount);
    }

    function main(uint256 borrow_amount) public {
        IFreeBorrow(free_borrow_contract_address).borrow_and_repay(free_borrow_contract_address, borrow_amount);
    }

    receive() external payable {}
}