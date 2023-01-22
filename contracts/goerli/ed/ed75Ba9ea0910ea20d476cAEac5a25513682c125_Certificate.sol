// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
contract Certificate
{   
   
    address public manager;
  
    constructor(){
        manager=msg.sender;
    }
    mapping(string=>certificate_details) public certificate;
        struct certificate_details{
            string file_name;
            address hash_of_file;
            // string file_description;
            // string file_type;
            // uint file_size; 
            uint timestamp_of_upload;
        }
        

    function addCertificate(string memory certificate_id,string memory _file_name, address _hash_of_file, uint _timestamp_of_upload) public
    {
        require(msg.sender==manager,"Only manager can add contract");
        require(certificate[certificate_id].hash_of_file==address(0),"certificate already stored");
        certificate[certificate_id]=certificate_details(_file_name,_hash_of_file,_timestamp_of_upload);
    }
   
    // function retriveCertificate() view public returns(string memory _file_name, address _hash_of_file, uint _timestamp_of_upload)
    function retriveCertificate() pure public returns(uint )

    {
        uint x=12;
        // return (certificate[certificate_id].file_name,
        //         certificate[certificate_id].hash_of_file,
        //         certificate[certificate_id].timestamp_of_upload);
        return (x);
    }


}