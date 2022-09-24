// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/BlogAppStorage.sol";

contract BlogFacet {
    AppStorage internal b;

    // event TestEvent(address something);
    function writeBlog(string memory _title, string memory _description, string memory _imageURI) external {

        address _owner = msg.sender;
        require(_owner != address(0), "Address(0) cannot write blog!");

        /// @notice add all element into array
        b.allBlogs.push(BlogAppStorage(_owner, _title, _description, _imageURI, block.timestamp, 0));


        /// @notice to blog to mapping so that, it will return
        BlogAppStorage storage blogger = b.singleBlog[b.ID];
        blogger.blogOwner = _owner;
        blogger.title = _title;
        blogger.description = _description;
        blogger.imageURI = _imageURI;
        blogger.createdTime = block.timestamp;
        blogger.updatedTime = 0;


        /// @notice to blog to mapping so that, it will return
        b.personalBlog[_owner].push(BlogAppStorage(_owner, _title, _description, _imageURI, block.timestamp, 0));

        b.ID++; // increment the ID
    }


    function returnAllBlog() external view returns(BlogAppStorage[] memory s) {
        s = b.allBlogs;
    }

    function allPersonalBlog(address _address) external view returns(BlogAppStorage[] memory s) {
        s = b.personalBlog[_address];
    }

    function returnSingleBlog(uint _id) external view returns(BlogAppStorage memory s) {
        s = b.singleBlog[_id];
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct BlogAppStorage {
    address blogOwner;
    string title;
    string description;
    string imageURI;
    uint createdTime;
    uint updatedTime;
}


struct AppStorage {
    uint ID;
    mapping(uint => BlogAppStorage) singleBlog;
    mapping(address => BlogAppStorage[]) personalBlog;
    BlogAppStorage[] allBlogs;
}