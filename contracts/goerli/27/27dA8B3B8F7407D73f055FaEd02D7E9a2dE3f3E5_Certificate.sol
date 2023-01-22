// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
contract Certificate
{   
   
    address public manager;
  
    constructor(){
        manager=msg.sender;
    }
   
    // mapping(string=>certificate_details) public certificate;
    //     struct certificate_details{
    //         string file_name;
    //         string hash_of_file;
    //         // string file_description;
    //         // string file_type;
    //         // uint file_size; 
    //         uint timestamp_of_upload;
    //     }
        

    // function addCertificate(string memory certificate_id,string memory _file_name, string memory _hash_of_file, uint _timestamp_of_upload) public
    // {
    //     require(msg.sender==manager,"Only manager can add contract");
    //     // require(certificate[certificate_id].hash_of_file=="","certificate already stored");
    //     certificate[certificate_id]=certificate_details(_file_name,_hash_of_file,_timestamp_of_upload);
    // }
   
    // function retriveCertificate(string memory certificate_id) view public returns(string memory _file_name, string memory _hash_of_file, uint _timestamp_of_upload)
    // // function retriveCertificate() pure public returns(uint )

    // {
    //     // uint x=12;
    //     return (certificate[certificate_id].file_name,
    //             certificate[certificate_id].hash_of_file,
    //             certificate[certificate_id].timestamp_of_upload);
    //     // return (x);
    // }
     string certificate_id;
    string file_name;
            string hash_of_file;
           
            uint timestamp_of_upload;
    function addCertificate(string memory _certificate_id,string memory _file_name, string memory _hash_of_file, uint _timestamp_of_upload) public
    {   
        require(msg.sender==manager,"Only manager can add contract");
        certificate_id=_certificate_id;
        file_name=_file_name;
        hash_of_file=_hash_of_file;
        timestamp_of_upload=_timestamp_of_upload;
    }   
    function getCertificate() public view returns(string memory _certificate_id,string memory _file_name, string memory _hash_of_file, uint _timestamp_of_upload) 
    {
        return(certificate_id,file_name,hash_of_file,timestamp_of_upload);
    }

}