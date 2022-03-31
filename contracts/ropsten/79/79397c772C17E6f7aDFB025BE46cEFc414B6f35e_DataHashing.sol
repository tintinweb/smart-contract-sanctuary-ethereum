/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity >=0.4.22 <0.9.0;
    contract DataHashing {


        struct datahashes{
            string id;
            bytes32 datahash;
        }
	
    mapping (string=>datahashes) private datahasheslist;
    event EHRRecordsdatahash(string  hash);

    function createehrdatahash(string memory _ehrRecordID, string memory _effDate, string memory _patientID, string memory _doctorID, string memory _disease) public{

        bytes32 hash=keccak256(abi.encodePacked( _ehrRecordID,  _effDate,  _patientID, _doctorID,  _disease));
        datahasheslist[_ehrRecordID].datahash=hash;
      }

    
    function createpatienthash(string memory _patientID, string memory _patientName, string memory _contactNbr, string memory _emailID, string memory _caddress, string memory _city, string memory _county, string memory _postcode, string memory _country) public{
        bytes32 hash=keccak256(abi.encodePacked(  _patientID, _patientName,  _contactNbr,  _emailID,  _caddress,  _city,  _county,  _postcode,  _country));
        datahasheslist[_patientID].datahash=hash;
    }

   function createdoctorhash(string memory _doctorID, string memory _doctorName, string memory _specialization, string memory _contactNbr, string memory _emailID, string memory _caddress, string memory _city, string memory _county, string memory _postcode, string memory _country) public{
        bytes32 hash=keccak256(abi.encodePacked(  _doctorID,  _doctorName,  _specialization,  _contactNbr,  _emailID,  _caddress,  _city,  _county,  _postcode,  _country));
        datahasheslist[_doctorID].datahash=hash;
    }


  function verifydoctor(string memory _doctorID, string memory _doctorName, string memory _specialization, string memory _contactNbr, string memory _emailID, string memory _caddress, string memory _city, string memory _county, string memory _postcode, string memory _country) public view returns (bool) {
      bytes32 hash1=keccak256(abi.encodePacked(  _doctorID,  _doctorName,  _specialization,  _contactNbr,  _emailID,  _caddress,  _city,  _county,  _postcode,  _country));

       bytes32 hash2=datahasheslist[_doctorID].datahash;

       if(hash1==hash2){
           return true;
       }
         else return false;
  }


  function verifypatienthash(string memory _patientID, string memory _patientName, string memory _contactNbr, string memory _emailID, string memory _caddress, string memory _city, string memory _county, string memory _postcode, string memory _country) public view returns (bool) {
      bytes32 hash1=keccak256(abi.encodePacked( _patientID, _patientName,  _contactNbr,  _emailID,  _caddress,  _city,  _county,  _postcode,  _country));

       bytes32 hash2=datahasheslist[_patientID].datahash;

       if(hash1==hash2){
           return true;
       }
         else return false;
  }



 function verifyehrdatahash(string memory _ehrRecordID, string memory _effDate, string memory _patientID, string memory _doctorID, string memory _disease) public view returns (bool) {
      bytes32 hash1=keccak256(abi.encodePacked(_ehrRecordID,  _effDate,  _patientID, _doctorID,  _disease));

       bytes32 hash2=datahasheslist[_ehrRecordID].datahash;

       if(hash1==hash2){
           return true;
       }
         else return false;
  }
      
        
}