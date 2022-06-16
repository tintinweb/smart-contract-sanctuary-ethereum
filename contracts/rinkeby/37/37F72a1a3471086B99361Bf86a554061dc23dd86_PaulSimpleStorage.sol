//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaulSimpleStorage {
    Biscuits[] public biscuit;

    struct Biscuits {
        string buscuitName;
        uint256 biscuitPrice;
    }

    mapping(uint256 => string) public mapBisuitNameAndPrice;

    function storeBiscuits(string memory nameOfBiscuit, uint256 priceOfBiscuit)
        public
    {
        biscuit.push(Biscuits(nameOfBiscuit, priceOfBiscuit));
        mapBisuitNameAndPrice[priceOfBiscuit] = nameOfBiscuit;
    }

    uint256 myNumber;

    function store(uint256 _myNumber) public virtual {
        myNumber = _myNumber;
    }

    function retreive() public view returns (uint256) {
        return myNumber;
    }
}