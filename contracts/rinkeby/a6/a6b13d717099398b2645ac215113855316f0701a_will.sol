/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
// File: contracts/registration.sol



pragma solidity 0.8.0;
//contract to check owner
contract Check_owner {
    
    address  private owner_;
    
    constructor () {
        owner_ = msg.sender;   
    }     
    function getOwner() public view returns (address) {
        return owner_;
    }
    function findAsOwner() public view returns (bool isOwner) {
        if(getOwner() == msg.sender){
        return true;}
    }
}

// contract for registraction
contract Registration is Check_owner {
   
   struct user{
        uint256 aadhar;
        address payable public_address;
        string user_type;
    }

    struct doctor{
        uint256 aadhar;
        uint256 license_number;
        string workplace;        
    }

    struct local_auth
    {
        uint256 id;
        string type_auth;
        address listing_person;
    }

    event register_auth(
        uint256 indexed id,
        string type_auth,
        address listing_person
    );

    event register_user(
        uint256 indexed aadhar,
        address payable public_address,
        string user_type
    );

    event register_doctor(
        uint256 indexed aadhar,
        uint256 license_number,
        string workplace 
    );

    mapping(uint256=>local_auth) public ownerAuth;
    //aadhar with details
    mapping(uint256=>user) public userDetails; 
    //lic with doctor details
    mapping(uint256=>doctor) public doctorDetails;

    function registerLocalAuth(uint256 _id,string memory _type_auth) public {
        require(Check_owner.findAsOwner());
        ownerAuth[_id]=local_auth(_id,_type_auth,Check_owner.getOwner()); 
        emit register_auth(_id,_type_auth,Check_owner.getOwner());     

    }

    function registerUser(uint256 _aahdar,address payable _public_address,string memory _user_type) public{
        userDetails[_aahdar]=user(_aahdar,_public_address,_user_type);
        emit register_user(_aahdar,_public_address,_user_type);
    }

    function registerDoctor(uint256 _aahdar,address payable _public_address, uint256 license_number, string memory workplace) public {
        userDetails[_aahdar]=user(_aahdar,_public_address,"DOCTOR");
        doctorDetails[license_number]=doctor(_aahdar,license_number,workplace);
        emit register_user(_aahdar,_public_address,"DOCTOR");  
        emit register_doctor(_aahdar,license_number,workplace);        
    }

     function getUserTypeByAadhar(uint256 _aahdar) public view returns (user memory) {
        user storage user1 = userDetails[_aahdar];
        return (user1);
        
    }

    function getLocalAuthById (uint256 _id) public view returns (string memory){
        local_auth storage auth = ownerAuth[_id];
        return (auth.type_auth);
    }
    
    function check_Doctor(uint256 _doctor_lic) public view returns (uint256){
        doctor storage doc =doctorDetails[_doctor_lic];
        return(doc.aadhar);
    }
}
// File: contracts/deathCerti.sol


pragma solidity 0.8.0;
//adding verification of type of user is left 


contract death_certificate is Registration {
string public constant Auth_Type="CIVIC";
   struct DeathCertificate{
       uint256 aadhar;
       string cause;
       uint256 doctorLicense;
       uint256 AuthId;
       bool isCertified;        
    }

event issue_certificate(
       uint256 indexed aadhar,
       string  cause,
       uint256 doctorLicense,
       uint256 indexed AuthId,
       bool isCertified
);

event approve_certificate(
    uint256 aadhar,
    uint256 AuthId,
    bool isCertified
);

function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }
// aadhar is mapped with doctor lic
mapping (uint256=>uint256) public aadharDoctor;
// aadhar is maped with auth
mapping (uint256=>uint256) public aadharAuth;

//aadhar with death certi
mapping (uint256=>DeathCertificate) public deaths;

function issueCertificate (uint256 userAadhar,string memory cause,uint256 doctorLicense,uint256 doctorAadhar) public {
    require(Registration.check_Doctor(doctorLicense)==doctorAadhar,"not valid doctor");
    require(userAadhar!=doctorAadhar,"person cannot sign his own death certificate");
    deaths[userAadhar]=DeathCertificate(userAadhar,cause,doctorLicense,0,false);
    emit issue_certificate(userAadhar,cause,doctorLicense,0,false);

}

function approveCertificate(uint256 userAadhar,uint256 AuthId,bool isCertified) public {
    require(strcmp(Registration.getLocalAuthById(AuthId),Auth_Type),"only civic body can approved death certificate");
    require(isCertified,"not approved by civic Body");    
    DeathCertificate storage deathCert = deaths[userAadhar];
    require(deathCert.aadhar==userAadhar,"death certifiate should be issued by the Doctor not civic body");
    deaths[userAadhar].isCertified=true;
    deaths[userAadhar].AuthId=AuthId;
    emit approve_certificate(userAadhar,AuthId,true);
    }

}



// File: contracts/will.sol


pragma solidity 0.8.0;



contract will is Registration,death_certificate {

// function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
//         return (a.length == b.length) && (keccak256(a) == keccak256(b));
//     }
// function strcmp(string memory a, string memory b) internal pure returns(bool){
//         return memcmp(bytes(a), bytes(b));
//     }

struct will_struct{
     uint256 willId;
     uint256 aadhar; 
     bool isCertifiedByDocotor;
     bool isCertifiedByRegistry;
     bool isCertifiedbyEstate;
     bool isCertifiedByBank;      
}

struct assests{
     //hash genrated from details,details can be confirmed with database
     uint256 id;
     uint256 owner;
     bool Assest_type;       
}

struct inheritors{
    uint256 inheritorsAadhar;
    string percentageRecv;  
}
event will_intiated(
        uint256 willId,
        uint256  indexed aadhar 
);

event assests_added(
     uint256  indexed willId,
     uint256[] AssestIds,
     bool[] Assest_type,
     uint256 owner
);
event inheritors_added(
     uint256  indexed willId,
     uint256[]  inheritorsIds,
     string[]  percentageRecv,
     uint256 owner
);
event will_verification(
     uint256 indexed userAadhar,
     uint256 indexed willId,
     string account_type,
     bool isVerified,
     uint256 VerifierId
);


//mapping
mapping(uint256=>uint) public willCount;

mapping(uint256=>mapping(uint256=>will_struct)) public aahdarWill; 

mapping (uint256 => uint256) public willAssestsCount;
//each will have different number of inheritors
mapping (uint256=>uint256) public willInheritorsCount;
// willid=>assestsid=>assets
mapping(uint256 => mapping(uint256=>assests)) public willAssests;

mapping(uint256 => mapping(uint256=>inheritors)) public willInheritors;
mapping(uint256 => uint256) public doctorWill;
mapping(uint256=>uint256) public RegWill;
mapping(uint256=>uint256) public estWill;
mapping(uint256=>uint256) public bankWill;

function getSender() public view returns  (address) {
        return msg.sender;
}

function createWill(
     uint256 willId,
     uint256 userAadhar,
     uint256[] memory AssestIds,
     bool[] memory Assest_type,
     uint256[] memory inheritorsIds,
     string[] memory percentageRecv) public{
            require(Registration.getUserTypeByAadhar(userAadhar).public_address==getSender(),"Owner addres doesnot match with accout which is used for transaction"); 
          require(Assest_type.length==AssestIds.length,"no of assests and assets type do no match");
          require(inheritorsIds.length==percentageRecv.length,"no of assests and assets type do no match");
        
//creating new will
          aahdarWill[userAadhar][willCount[userAadhar]]=will_struct(willId,userAadhar,false,false,false,false);
          willCount[userAadhar]++;
          emit will_intiated(willId,userAadhar);
//link assests with will id
          for (uint i = 0; i < AssestIds.length; i++) {
              willAssests[willId][i]=assests(AssestIds[i],userAadhar,Assest_type[i]);   
               willAssestsCount[willId] = i;  
          }
          emit assests_added(willId,AssestIds,Assest_type,userAadhar);
//link inheritors and the percentage recv in the will
          for (uint i = 0; i < inheritorsIds.length; i++) {
               require(Registration.getUserTypeByAadhar(userAadhar).public_address!=0x0000000000000000000000000000000000000000 && 
               Registration.getUserTypeByAadhar(userAadhar).aadhar!=0,"inheritor is not registered");
               willInheritors[willId][i]=inheritors(inheritorsIds[i],percentageRecv[i]);       
               willInheritorsCount[willId] = i; 
          } 
          emit inheritors_added (willId,inheritorsIds,percentageRecv,userAadhar);

}

function approve_will(uint256 willId,uint256 verifierId,string memory verifierType,bool isCertified,uint256 userAadhar)public{
    //retrive type from the registration sol
//     require(aahdarWill[userAadhar][willCount[userAadhar]].willId==willId,"Only latest will can verified");
 
    if(strcmp(verifierType,'DOCTOR')){
         //check details of veirifier
         require(isCertified,"not Approved by Doctor");
         aahdarWill[userAadhar][willCount[userAadhar]].isCertifiedByDocotor=true;
         doctorWill[willId]=verifierId;
         emit will_verification(userAadhar,willId,verifierType,true,verifierId);
     }
     if(strcmp(verifierType,'REGISTRY')){
         require(isCertified,"not Approved by Registry");
         aahdarWill[userAadhar][willCount[userAadhar]].isCertifiedByRegistry=true;
         RegWill[willId]=verifierId;
         emit will_verification(userAadhar,willId,verifierType,true,verifierId);

     }
     if(strcmp(verifierType,'BANK')){
          require(isCertified,"not Approved by Bank");
          aahdarWill[userAadhar][willCount[userAadhar]].isCertifiedByBank=true;
         bankWill[willId]=verifierId;
         emit will_verification(userAadhar,willId,verifierType,true,verifierId);

     }
     if(strcmp(verifierType,'ESTATE')){
          require(isCertified,"not Approved by Estate");
         aahdarWill[userAadhar][willCount[userAadhar]].isCertifiedbyEstate=true;
         estWill[willId]=verifierId;
         emit will_verification(userAadhar,willId,verifierType,true,verifierId);

     }
}

}