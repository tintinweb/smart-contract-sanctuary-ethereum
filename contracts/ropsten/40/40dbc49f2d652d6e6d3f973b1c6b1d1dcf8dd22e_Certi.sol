/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Certi {
   
    uint256 public certificateCount;

    struct certificate {
        uint256 certificateId;
        string courseName;
        string candidateName;
        string grade;
        string date;
    }

    mapping(uint256 => certificate) public certificateDetails;

    function newCertificate(
        string memory _courseName,
        string memory _candidateName,
        string memory _grade,
        string memory _date
    ) public  {
        certificateCount += 1;
        certificateDetails[certificateCount] = certificate(
            certificateCount,
            _courseName,
            _candidateName,
            _grade,
            _date
        );
    }
}