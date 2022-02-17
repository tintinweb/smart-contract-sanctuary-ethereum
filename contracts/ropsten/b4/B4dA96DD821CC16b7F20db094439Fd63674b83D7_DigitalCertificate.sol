/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

struct Certificate{
    uint index;
    string certificateNumber;
    string certificateName;
    string certificateHash;
    string receiverName;
    uint dateOfAchievement;
    address issuerAddress;
    bool isValue;
}

contract DigitalCertificate {

    mapping(string => Certificate) private certificateMap;
    uint8 public countCertificateArray=0;
    Certificate [] public certificateArray;

    event AddNewCertificate(string  certificateNumber,string  certificateName,string  certificateHash,string  receiverName,uint dateOfAchievement,address issuerAddress);

    function addCertificate(address _contract,string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchievement)public {
        WalletAuthentication walletCon = WalletAuthentication(_contract);
        require(walletCon.authenWallet(msg.sender),"Please Authen Wallet First");
        require(!certificateMap[certificateNumber].isValue,"current certificateNumber is already exists.");
        certificateArray.push(Certificate(countCertificateArray,certificateNumber,certificateName,certificateHash,receiverName,dateOfAchievement,msg.sender,true));
        certificateMap[certificateNumber]=certificateArray[countCertificateArray];
        countCertificateArray++;
        emit AddNewCertificate(certificateNumber,certificateName,certificateHash,receiverName,dateOfAchievement,msg.sender);
    }

    function infoCertificate(string memory certificateNumber)public view returns(string memory ,string memory,string memory,string memory,uint,address){
        if(!certificateMap[certificateNumber].isValue) return ("Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number",0,0x0000000000000000000000000000000000000000); 
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        return (thisCertificate.certificateNumber,thisCertificate.certificateName,thisCertificate.certificateHash,thisCertificate.receiverName,thisCertificate.dateOfAchievement,thisCertificate.issuerAddress);
    }


    function isValid(string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchievement)public view returns(bool) {
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        if(thisCertificate.isValue!=true) return false;
        else if(keccak256(bytes(thisCertificate.certificateName))!=keccak256(bytes(certificateName))) return false;
        else if(keccak256(bytes(thisCertificate.certificateHash))!=keccak256(bytes(certificateHash))) return false;
        else if(keccak256(bytes(thisCertificate.receiverName))!=keccak256(bytes(receiverName))) return false;
        else if(thisCertificate.dateOfAchievement!=dateOfAchievement) return false;
        else return true;
    }

    function hashIsValid(address _contract,address _wallet,string memory _certificateNumber,string memory _certificateHash)public view returns(string memory,bool){
    WalletAuthentication walletCon = WalletAuthentication(_contract);
    if (walletCon.authenWallet(_wallet)){
       Certificate storage thisCertificate= certificateMap[_certificateNumber];
        if(keccak256(bytes(thisCertificate.certificateHash))!=keccak256(bytes(_certificateHash))) return ("NOT VERTIFIED",false);
        else return ("VERTIFIED",true);
    }else return ("Please Auten Wallet",false);
    
    }
    function Authen(address _contract)public view returns(bool){
    WalletAuthentication walletCon = WalletAuthentication(_contract);
    return walletCon.authenWallet(msg.sender);
    }
    
}

struct User {
    string name;
    address wallet;
    string publicKey; 
    bool isActive;
}
contract WalletAuthentication {

    mapping(address => User) private UserMap;
    uint8 public countUserArray=0;
    User [] public UserArray;

    function createUser(string memory _name,string memory _publicKey)public{
    require(UserMap[msg.sender].isActive==false,"Your wallet address is registered.");
    UserArray.push(User(_name,msg.sender,_publicKey,true));
    UserMap[msg.sender]=UserArray[countUserArray];
    countUserArray++;
    }

    function createUserByAddress(string memory _name,address _wallet,string memory _publicKey)public{
    require(UserMap[_wallet].isActive==false,"Your wallet address is registered.");
    UserArray.push(User(_name,_wallet,_publicKey,true));
    UserMap[_wallet]=UserArray[countUserArray];
    countUserArray++;
    }

    function userInfo(address _wallet)public view returns(string memory,string memory){
        User storage thisUser= UserMap[_wallet];
        if (thisUser.isActive) return (thisUser.name,thisUser.publicKey);
        else return ("null","null");
    }

    function authenWallet(address _wallet)public view returns(bool){
        return UserMap[_wallet].isActive;
    }
}