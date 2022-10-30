/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract certAdd {
    uint256 public certCount = 0;



    struct cert_details {
        uint256 id;
        string name;
        string studentid;
        string email;
        string course;
        string date;
        string college;
        string term;
    }

    mapping(address => cert_details) certificates;

    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }

    event coll_added(string name); //event when college is added

    event certadded(
        string name,
        string studentid,
        string email,
        string course,
        string date,
        string college,
        string term
    );


//this array will store all addressWallet for manager who can use and add certificate
struct manager{
    string name;
    address wallet;
    bool value; 
    }


mapping (address => manager) managers;

//this function will add manager
function addManager(address wallet, string memory name) public ownerOnly{
    managers[wallet] = manager(name, wallet, true);
}

//this function will check if manager is present or not
function checkManager(address wallet) public view returns (bool){
    return managers[wallet].value;
}

//this function will add certificate with true manager if not is present then it will not add certificate show error message

function addCertificate(
        address wallet,
        string memory name,
        string memory studentid,
        string memory email,
        string memory course,
        string memory date,
        string memory college,
        string memory term
    ) public {
        if (managers[wallet].value == true) {
            require(managers[wallet].value == true);
            certCount++;
            certificates[msg.sender] = cert_details(
                certCount,
                name,
                studentid,
                email,
                course,
                date,
                college,
                term
            );
            emit certadded(
                name,
                studentid,
                email,
                course,
                date,
                college,
                term
            );
        }else{
            revert("You are not Manager");
        }
    }

}