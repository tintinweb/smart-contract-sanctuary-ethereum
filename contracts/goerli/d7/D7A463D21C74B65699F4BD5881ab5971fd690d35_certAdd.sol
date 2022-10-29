/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract certAdd {
    uint256 public certCount = 0;

    struct college {
        string colname;
        bool value;
    }

    struct cert_details {
        uint256 id;
        string name;
        string studentid;
        string email;
        string course;
        string date;
        string collegeIn;
        string term;
    }

    mapping(address => cert_details) certificates;
    mapping(address => college) colleges;

    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }

    event coll_added(string name); //event when college is added

    event certadded(string name,
        string studentid,
        string email,
        string course,
        string date,
        string collegeIn,
        string term);

    function addCollege(address coladd, string memory name) public ownerOnly {
        colleges[coladd] = college(name, true);
        string memory s = "this is how we do";
        emit coll_added(s); //calling event
    }

    function checkcoll(address col) public view returns (bool) {
        return colleges[col].value;
    }


    function addCertificate(
        string memory name,
        string memory studentid,
        string memory email,
        string memory course,
        string memory date,
        string memory collegeIn,
        string memory term
    ) public {
        certCount++;
        if (checkcoll(msg.sender)==true) {
            certificates[msg.sender] = cert_details(
                certCount,
                name,
                studentid,
                email,
                course,
                date,
                collegeIn,
                term
            );
            // emit certadded(fname,lname,course,colleges[msg.sender].colname);
        }
    }
}