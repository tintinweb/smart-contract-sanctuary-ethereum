// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Certificate {
    address public owner;

    struct cert {
        address recipient;
        bool confirmed;
    }
    mapping(string => cert) certs;

    constructor() {
        owner = msg.sender;
    }

    function isCertAvailable(string memory cert) public view returns(bool) {
        if (certs[cert].recipient != msg.sender) return false;
        return certs[cert].confirmed == true;
    }

    function createCert(string memory cert) public {
        require(!isCertAvailable(cert), "Certificate is already available");
        certs[cert].recipient = msg.sender;
        certs[cert].confirmed = true;
    }

    function deleteCert(string memory cert) public {
        require(isCertAvailable(cert), "Certificate does not exist");
        certs[cert].recipient = address(0);
        certs[cert].confirmed = false;
    }
}