/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract UniVac{
    address EPA;
    constructor() {
    EPA = msg.sender;
    }

    struct StoreValue{
        uint id;
        uint date;
        string Url;
    }

    struct User {
        bool isApproved;
    }

    uint private lastUrlIDs;
    uint [] private UrlIDs;
    mapping(address => User) users;
    mapping(uint => StoreValue) private StoreUrls;
    event UrlAdded(uint id, uint date, string Url);

    modifier IdExist(uint id) {
        require (StoreUrls[id].id != 0);
        _;
    }

    modifier onlyApproved {
        require(users[msg.sender].isApproved, "You are not registered.");
        _;
    }

    modifier OnlyStaff{
        require(msg.sender == EPA, "Only EPA staffs are allowed");
        _;
    }

    function addUrl(string memory _Url) OnlyStaff public {
        lastUrlIDs++;
        StoreUrls[lastUrlIDs] = StoreValue(lastUrlIDs, block.timestamp, _Url);
        UrlIDs.push(lastUrlIDs);
        emit UrlAdded(lastUrlIDs, block.timestamp, _Url);
    }

    function AddUsers(address user, bool isApproved) OnlyStaff public {
        users[user].isApproved = isApproved;
    }

    function getUrlIds() onlyApproved public view returns (uint[] memory) {
        return UrlIDs;
    }

    function getUrl(uint id) onlyApproved IdExist(id) public view returns(uint, uint, string memory) {
        return (id, StoreUrls[id].date, StoreUrls[id].Url);
    }

}