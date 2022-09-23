// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;
import "./WhiteList.sol";

contract SimpleStorage is WhiteList {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        require(isMember(msg.sender), "Access Denied!");
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber)
        public
        payable
    {
        require(isMember(msg.sender), "Access Denied!");

        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    receive() external payable {
        
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract WhiteList {
    address private immutable _iOwner;
    // define a mapping of members

    mapping(address => bool) members;

    constructor() {
        _iOwner = msg.sender;
        members[msg.sender] = true;
    }

    // method to check memebership
    function isMember(address _userAddress) public view returns (bool) {
        return members[_userAddress];
    }

    // a method to add member
    function addMember(address _userAddress) public onlyOwner {
        require(!isMember(_userAddress), "User is already a member");

        members[_userAddress] = true;
    }

    // a method to remove member
    function removeMember(address _userAddress) public onlyOwner {
        require(isMember(_userAddress), "User not found");

        delete members[_userAddress];
    }

    modifier onlyOwner() {
        require(msg.sender == _iOwner, "Caller is not the owner");
        _;
    }
}