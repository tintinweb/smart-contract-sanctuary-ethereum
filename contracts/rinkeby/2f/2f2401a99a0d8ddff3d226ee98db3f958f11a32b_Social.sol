/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Social {
    
    address public owner;
    
    // creating stuck to manage post Detials;
    struct postForm {
        string imageUri;
        string title;
        string descriton;
        bool approved;
    }
    // creating constructor 
    constructor () {
        owner = msg.sender;
    }
    // modifier
    modifier onlyOwner() {
        require (msg.sender == owner, " you are not the Owner");
        _;
    }
    // storing postForm into a arry;
    postForm[] public postForms;
    // creating mapping for listing users
    mapping (uint256 => address) public users;
    // creating function to addPost
    function addPost (string memory _image, string memory _title, string memory _description) public {
        
        postForms.push(postForm(_image, _title, _description, true));
        uint id = postForms.length - 1;
        users[id] = msg.sender;
    }
    // creating function to publish postForms
    function publishPost () public view returns (postForm[] memory) {
        return postForms;
    }
    // creating function to update pOst;
    function updatePost ( postForm memory _post, uint256 _index) public {
       require (msg.sender == users[_index], "you are not the Owner");
        _post.approved = false;
        postForms[_index] = _post;
        
    }
    // creating function to approved postForms
    function approvedPost (uint256 _index) onlyOwner public {
        postForm storage post = postForms[_index];
        post.approved = true;
    }
}