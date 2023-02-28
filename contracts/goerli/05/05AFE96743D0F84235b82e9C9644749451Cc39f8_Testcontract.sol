// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testcontract {

    struct TestStruct {
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
    }

    TestStruct[] public list;

    function createListing(uint256 tokenId, uint256 price, address _tokenAddress) public { 

        TestStruct memory listing = TestStruct({
            buyer: address(0),
            tokenAddress: _tokenAddress,
            tokenId: tokenId,
            price: price
        });

        list.push(listing);
    }

   function getList() external view returns (TestStruct[] memory) {
        return list;
    }

}