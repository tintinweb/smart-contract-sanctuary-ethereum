// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract ImageBox {

    struct Image {
        address author;
        string url;
        // uint256 upvotes;
        // uint256 downvotes;
    }

    Image[] public images;
    mapping(address => uint256) public addressToAttributeCount;

    function addImage(string memory _url) public {
        images.push(Image(msg.sender, _url));
        addressToAttributeCount[ msg.sender ] += 1;
    }
}