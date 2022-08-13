// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Crud {
    address creator;

    struct Post {
        string title;
        string post;
    }

    Post[] public post;

    function createForm(string memory _title, string memory _post) public {
        post.push(Post({title: _title, post: _post}));
    }

    // function deleteForm() public {
    //     delete Post[];
    // }

    // function getForm()
    //     public
    //     view
    //     returns (
    //         uint256,
    //         string memory,
    //         string memory,
    //         address
    //     )
    // {
    //     return  creator;
    // }
}