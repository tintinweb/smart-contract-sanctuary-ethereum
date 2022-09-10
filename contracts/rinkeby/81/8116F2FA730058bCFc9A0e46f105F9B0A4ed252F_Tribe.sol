/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Tribe {
    uint public imagecounter = 0;
    string public name = "Tribe";

    //store images
    mapping (uint => Image) public images;

    struct Image {
        uint id;
        string hash;
        string description;
        uint tipAmount;
        uint likes;
        address payable author;
    }

    event imageUploaded(
        uint id,
        string hash,
        string description,
        uint tipAmount,
        address payable author
    );
  
    event tipSent(
        uint id,
        string hash,
        string description,
        uint tipAmount,
        address payable author
    );
    event  imageLiked(
        uint id,
        string hash,
        string description,
        uint tipAmount,
        uint likes
    );

    //create images
    function uploadImage(string memory _imghash, string memory _description) public {
        require(bytes(_description).length > 0);
        require(bytes(_imghash).length > 0);
        require(msg.sender != address(0x00));
        imagecounter = imagecounter + 1;
        images[imagecounter] = Image(imagecounter, _imghash, _description, 0, 0, payable(msg.sender));

        emit imageUploaded(imagecounter, _imghash, _description, 0, payable(msg.sender));
    }
    //Tip images

    function tipImageOwner(uint _id) public payable {
        require(_id > 0 && _id <= imagecounter);
        Image memory _image = images[_id];
        address payable _author = _image.author;
        _author.transfer(msg.value);
        _image.tipAmount = _image.tipAmount + msg.value;
        images[_id] = _image;

        emit tipSent(_id, _image.hash, _image.description, _image.tipAmount, _author);
    }

    //like image

        function likeImage(uint _id) public payable {
        require(_id > 0 && _id <= imagecounter);
        Image memory _image = images[_id];
        _image.likes = _image.likes + 1;
        images[_id] = _image;

        emit imageLiked(_id, _image.hash, _image.description, _image.tipAmount, _image.likes);
    }

    //comment on image

    
}