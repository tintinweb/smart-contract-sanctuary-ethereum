/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SpamReports {

    struct Report {
        address reporter;
        string ip;
        string description;
        string evidenceHash;
        uint timestamp;
    }

    struct IP {
        string ip;
        uint score;
        bool isBlocked;
    }

    mapping(string => IP) public ipList;
    mapping(string => Report[]) public reports;
    address[] public reporters;

    event NewReport(address reporter, string ip, string description);
    event ScoreUpdate(string ip, uint score, bool isBlocked);

    function reportSpam(string memory _ip, string memory _description, string memory _evidenceHash) public {
        require(msg.sender != address(0));
        require(keccak256(abi.encodePacked(_ip)) != keccak256(abi.encodePacked("")));

        // check if IP already exists in the list
        IP storage ip = ipList[_ip];
        if (keccak256(abi.encodePacked(ip.ip)) == keccak256(abi.encodePacked(""))) {
            ip.ip = _ip;
            ip.score = 1;
        } else {
            ip.score++;
        }

        // check if IP score exceeds threshold for blocking
        if (ip.score >= 5) {
            ip.isBlocked = true;
        }

        // add report to the list
        Report memory report = Report({
            reporter: msg.sender,
            ip: _ip,
            description: _description,
            evidenceHash: _evidenceHash,
            timestamp: block.timestamp
        });
        reports[_ip].push(report);
        reporters.push(msg.sender);

        emit NewReport(msg.sender, _ip, _description);
        emit ScoreUpdate(_ip, ip.score, ip.isBlocked);
    }

    function appeal(string memory _ip, string memory _description) public {
        require(keccak256(abi.encodePacked(_ip)) != keccak256(abi.encodePacked("")));
        IP storage ip = ipList[_ip];

        if (ip.score == 0) {
            revert("IP not found in the list");
        }

        // decrease the score
        ip.score--;

        if (ip.score < 5) {
            ip.isBlocked = false;
        }

        Report memory report = Report({
            reporter: msg.sender,
            ip: _ip,
            description: _description,
            evidenceHash: "",
            timestamp: block.timestamp
        });
        reports[_ip].push(report);
        reporters.push(msg.sender);

        emit ScoreUpdate(_ip, ip.score, ip.isBlocked);
    }

    function getIpScore(string memory _ip) public view returns (uint, bool) {
        IP storage ip = ipList[_ip];
        return (ip.score, ip.isBlocked);
    }

    function getReporters() public view returns (address[] memory) {
        return reporters;
    }

    function getReports(string memory _ip) public view returns (Report[] memory) {
        return reports[_ip];
    }

}