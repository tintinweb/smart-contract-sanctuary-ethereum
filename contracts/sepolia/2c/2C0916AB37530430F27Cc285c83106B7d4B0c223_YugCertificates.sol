/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAdmin {
    function getIssuer() external view returns (address);
}

contract YugCertificates {

    address _admin;
    
    mapping(string => Info) private _checksum_info_mapping;

    struct Info {
        address owner;
        uint256 issueDate;
        uint256 expiryDate;
        string kind;
    }

    constructor(address admin) {
        // __Ownable_init();
        _admin = admin;
    }

    function addChecksum(string memory checksum, string memory kind, address owner, uint256 issue, uint256 expiry) public {
        require(IAdmin(_admin).getIssuer() == msg.sender, "Unauthorized");
        Info memory info = Info(owner, issue, expiry, kind);
        _checksum_info_mapping[checksum] = info;
    }

    function getInfo(string memory checksum) public view returns (address owner, uint256 issue, uint256 expiry, string memory) {
        return (_checksum_info_mapping[checksum].owner, 
            _checksum_info_mapping[checksum].issueDate, 
            _checksum_info_mapping[checksum].expiryDate, 
            _checksum_info_mapping[checksum].kind);
    }
}