//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract SocialMedia {
    struct Image {
    string data;
    address author;
    uint256 id;
    }

    event ImageUploaded(
        uint256 id,
        string data,
        address author,
        uint block
    );


    mapping(uint256 => Image) public db;

    uint public count = 0;

    function post(string memory data) public {
        require(bytes(data).length > 0);

        db[count] = Image(data, msg.sender, count);
        emit ImageUploaded(count, data, msg.sender, block.timestamp);

        count ++;
    }
    


}