/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IApplicant {
    function do_anything_and_repay(address sender, uint256 amount) external;
    function receive_ether() payable external;
}

interface IFreeBorrow {
    function add_liquidity() payable external;
    function borrow_and_repay(address to, uint256 amount) external;
}

interface IProveRich {
    function receive_ether_and_check_rich() payable external;
}



contract ApplicantV6 is IApplicant {
    string public passport = "US: tidunehnoqfsztse";

    address public free_borrow_contract_address;
    address public prove_rich_contract_address;

    constructor(address free_borrow_contract_address_, address prove_rich_contract_address_) {
        free_borrow_contract_address = free_borrow_contract_address_;
        prove_rich_contract_address = prove_rich_contract_address_;
    }

    function do_anything_and_repay(address sender, uint256 amount) public {
        require(address(this).balance >= amount, "nupxyiuxfpoiiezc: Insufficient eth to send.");
        IProveRich(prove_rich_contract_address).receive_ether_and_check_rich{value: amount}();

        require(address(this).balance >= amount, "qahkklucqbkgeqgi: Insufficient eth to send.");
        IFreeBorrow(free_borrow_contract_address).add_liquidity{value: amount}();
    }

    function pretend_rich(uint256 borrow_amount) public {
        IFreeBorrow(free_borrow_contract_address).borrow_and_repay(address(this), borrow_amount);
    }

    function receive_ether() public payable {}

}