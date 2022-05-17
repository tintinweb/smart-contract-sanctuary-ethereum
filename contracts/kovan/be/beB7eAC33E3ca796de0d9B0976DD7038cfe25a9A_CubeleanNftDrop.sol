/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// addDrop 테스트 튜플 데이터 
// ["https://cdn.pixabay.com/photo/2018/05/26/18/06/dog-3431913_1280.jpg", "Test Collection", "This my drop for the month", "Twitter", "https://testtest.com", "fasfas", "0.03", 22, 1635790237, 1635790237, 1, false]

contract CubeleanNftDrop {

    address public owner;

    // Define a NFT drop object
    struct Drop {
        string imageUrl;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;

    }

    // Create a list of same sort to hold all ther objects
    Drop[] public drops;
    mapping (uint256 => address) public users;


    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not ther owner."); 
        _;
    }

    // Get the NFT drop objects list
    function getDrops() public view returns (Drop[] memory){
        return drops;
    }

    // Add to the NFT drop object list
    function addDrop(Drop memory _drop) public {
        _drop.approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    } 


      function updateDrop(
        uint256 _index,
       Drop memory _drop
        ) public {
        // 요청자는 소유주 여야만한다
        require(msg.sender == users[_index],"You are not owned of this drop");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    // Approve an NFT drop object to enable displaying
    function approveDrop(uint256 _index) public onlyOwner {
        Drop storage drop = drops[_index];
        drop.approved = true;

    }

}