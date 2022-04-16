/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// File: contracts/INFWBookmark.sol



pragma solidity 0.8.0;

interface INFWBookmark {

    function bookmark(address nfwebsiteAddress) external;

    function bookmarked() external view returns (address[] memory);
}

// File: contracts/NFWBookmark.sol



pragma solidity 0.8.0;


contract NFWBookmark is INFWBookmark {

    mapping(address => Bookmark) _bookmarked;

    struct Bookmark{
        bool exists;
        address [] addresses; 
    }

    function bookmark(address nfwebsiteAddress) external override {
        Bookmark storage b = _bookmarked[msg.sender];
        if(!b.exists){
            b.addresses = new address[](0); 
            b.exists = true;
        }
        b.addresses.push(nfwebsiteAddress);
        _bookmarked[msg.sender] = b;
    }

    function bookmarked() external view virtual override returns (address[] memory){
        if(_bookmarked[msg.sender].exists){
            return _bookmarked[msg.sender].addresses; 
        }
        return new address[](0);
    }
}