//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

contract imds {
    address private owner;

    struct details {
        uint256 registrationNumber;
        string metadata; //CID of the object containing description, certificate hash
        bool revoked;
    }

    constructor() {
        owner = msg.sender;
    }

    uint256 internal ids = 1;
 
    mapping(uint256 => details) public Details;

    mapping(string => uint256) public certs;

    // event certificate(uint256 indexed _id, uint256 indexed _rid, string indexed _data);
    event Certificate(uint256 indexed id, uint256 indexed rid, string data);

    function addCertificate(
        uint256 rid,
        string memory cId,
        string memory Mdata
    ) public onlyOwner {
        require(certs[cId] == 0, "File already assigned");
        certs[cId] = 1;

        details storage _detail = Details[ids];

        
        _detail.registrationNumber = rid;
        _detail.metadata = Mdata;
        _detail.revoked = false;

         emit Certificate(ids, rid, Mdata);

          ids++;
        }
        
    //Incase uploaded accidentaly or found malicious later, 
    //revoke can be called so that the certificate can be marked as "Not recognised by university",
    //but the details are still available,
    function revoke(uint256 _id, string memory _cId) external onlyOwner { 
        certs[_cId] = 0;
        Details[_id].revoked = true;
    }

     function ratify(uint256 _id) external onlyOwner { 
        Details[_id].revoked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorised");
        _;
    }

    //Emit an event
}