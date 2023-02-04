/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 favNum;
    address favAddress = 0xEbb503B1Ba292aa20f2C2594Ac29eb6CBfF815C1;

    struct People {
        string name;
        string email;
    }

    string[] public traits;

    People public person =
        People({name: "name", email: "[email protected]"});

    function storeFavNum(uint256 _favNum) public {
        favNum = _favNum;
    }

    function retrieveFavNum() public view returns (uint256) {
        return favNum;
    }

    function addTrait(string memory _trait) public {
        traits.push(_trait);
    }
}