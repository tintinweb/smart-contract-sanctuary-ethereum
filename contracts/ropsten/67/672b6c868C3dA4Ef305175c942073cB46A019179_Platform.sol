/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.8.13;

interface Patenter {
    function verified() external returns (bool);
    function id() external returns (uint);
    function counter() external;
}

contract Platform {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        msg.sender == owner;
        _;
    }

    mapping(address => Patent) public patents;
    struct Patent {
        uint patentID;
        string namePatent;
        string description;
        uint patentingTime;
        bool verify;
    }

    function PatentRegister(
        string memory name,
        string memory desc,
        address patentAddress
    ) public {

        patents[msg.sender].patentID = Patenter(patentAddress).id();
        patents[msg.sender].namePatent = name;
        patents[msg.sender].description = desc;
        patents[msg.sender].patentingTime = block.timestamp;

        patents[msg.sender].verify = Patenter(patentAddress).verified();

        Patenter(patentAddress).counter();
    }
}