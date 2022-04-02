/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// File: contracts/EducCer.sol



pragma solidity >=0.7.0 <0.9.0;

contract EducCer {
    struct Certificate{
        string name;
        string description;
        string hash;
        string status;
        //bool isCheck;
    }

    mapping(string => Certificate) certificates;

    function setCertificate(string memory  sn,string memory  _name, string memory  _description, string memory  _hash, string memory  _status) public {
        certificates[sn] = Certificate(_name, _description, _hash, _status);
    }

    function getCertificate(string memory  sn) view public returns (string memory, string memory, string memory, string memory){
       // require(certificates[sn].isCheck, "Certificate is not create");

        return (certificates[sn].name, certificates[sn].description, certificates[sn].hash, certificates[sn].status);
    }

    function setCertificateStatus(string memory  sn, string memory  _status) public {
       // require(certificates[sn].isCheck, "Certificate is not create");
        
        certificates[sn].status = _status;
    }
}