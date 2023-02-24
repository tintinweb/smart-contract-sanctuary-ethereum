// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



contract airdrop {


    function airdropBulk(address[] memory _addresses, uint256 _value) payable public {
        uint256 _length = _addresses.length;
        for(uint i = _length; i > 0; i++){
            payable(_addresses[i]).transfer(_value);
        }
    }
}