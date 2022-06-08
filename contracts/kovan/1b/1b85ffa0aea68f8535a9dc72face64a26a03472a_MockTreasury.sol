// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract MockTreasury {

    uint _rvltPrice;

    function updatePrice(uint _newPrice) public {
        _rvltPrice = _newPrice;
    }

    function revoltPriceInUSD(uint amount) public view returns(uint) {
        return _rvltPrice;
    }
}