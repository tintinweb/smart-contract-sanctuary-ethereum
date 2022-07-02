/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddImage {


    struct Image {
        string title;
       string hash;
    }

    Image[] public images;


    function _createimage (string memory _title , string memory _hash) public{
       images.push(Image(_title, _hash));
    }

    function _readimage () public view returns (string memory, string memory){
        return (images[0].title, images[0].hash);
    }


}