/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
abstract contract Authorize{
    struct account{
        bool isValid;
        uint8 role;
        // Role :
        // 1 SuperAdmin
        // 2 Admin
        // 3 user
    }

    mapping(address => account) public UsersAddress;
    
     // ===> new feat
    event AdminAdded(
        address indexed Caller,
        address indexed NewAdmin
    );

    event AdminDeactivated(
        address indexed Caller,
        address indexed RemovedAdmin
    );

    event Userdeactivated(
        address indexed Caller,
        address indexed RemovedUser
    );

    event UserAdded(
        address indexed Caller,
        address indexed newUser
    );
    // ===

    function addUser(address _address) public AdministratorOnly{
        UsersAddress[_address].isValid = true;
        UsersAddress[_address].role = 3;
    }

    function deactivateUser(address _address) public AdministratorOnly{
        require(UsersAddress[_address].isValid,"User address not active");
        UsersAddress[_address].isValid = false;
    }

    function addAdmin(address _address) public SuperAdminOnly {
        require(!UsersAddress[_address].isValid,"address already admin active");
        UsersAddress[_address].isValid = true;
        UsersAddress[_address].role = 2;
        // new feat
        emit AdminAdded(msg.sender, _address);
    }

    function deactivateAdmin(address _address) public SuperAdminOnly {
        require(UsersAddress[_address].isValid,"Admin address not active");
        UsersAddress[_address].isValid = false;
        // new feat
        emit AdminDeactivated(msg.sender, _address);
    }

    function isSuperAdmin(address _address) public view returns(bool) {
        return UsersAddress[_address].role == 1 && UsersAddress[_address].isValid;
    }

    function isAdmin(address _address) public view returns(bool) {
        return UsersAddress[_address].role == 2 && UsersAddress[_address].isValid;
    }

    function isUser(address _address) public view returns(bool) {
        return UsersAddress[_address].role == 3 && UsersAddress[_address].isValid;
    }

    // === Modifier

    modifier AdministratorOnly(){
        require((UsersAddress[msg.sender].role == 2 ||
         UsersAddress[msg.sender].role == 1) && UsersAddress[msg.sender].isValid,
         "Only admin and Superadmin can interact");
        _;
    }
    modifier SuperAdminOnly(){
        require(UsersAddress[msg.sender].role == 1 && UsersAddress[msg.sender].isValid,
        "Only Superadmin can interact");
        _;
    }
}


contract KtpInspector is Authorize {

    mapping(address => KtpData) public UserToKtpData;
    address[] public ktpOwnerCounter;   

    constructor(){
        UsersAddress[msg.sender].isValid = true;
        UsersAddress[msg.sender].role = 1;
    }

    struct KtpData{
        bool Valid;
        string NIK;
        address NftAddress;
        string Ktp_Uri;
    } 

    // only emit owner and caller
    event KtpAdded(
        address indexed Caller,
        address indexed Owner
    );

    // only emit owner and caller
    event KtpUpdated(
        address indexed Caller,
        address indexed Owner
    );

    event KtpRemoved(
        address indexed Caller,
        address indexed Owner
    );

    function findKtp(address Owner) public view returns(KtpData memory)  {
        require(
            (UsersAddress[msg.sender].role == 1 && UsersAddress[msg.sender].isValid) || 
            (UsersAddress[msg.sender].role == 2 && UsersAddress[msg.sender].isValid) ||
            Owner == msg.sender,
            "You can't access this data"
        );
        KtpData memory ktp;
        for(uint i; i<ktpOwnerCounter.length;i++){
            if(ktpOwnerCounter[i] == Owner){
                ktp = UserToKtpData[ktpOwnerCounter[i]];
                break;
            }
        }
        require(ktp.Valid, "KTP DATA NOT FOUND!!!");
        return ktp;        
    }

    function addKtp (address Owner,address nftKtp, string memory DataNik, string memory Ipfs_Uri) public AdministratorOnly{
        require(isUser(Owner),"Owner not registered yet!");
        require(!UserToKtpData[Owner].Valid,"There's Already KTP Data");
        ktpOwnerCounter.push(Owner);
        KtpData storage newKTP = UserToKtpData[Owner];
        newKTP.NIK = DataNik;
        newKTP.NftAddress = nftKtp;
        newKTP.Ktp_Uri = Ipfs_Uri;
        newKTP.Valid = true;
        emit KtpAdded(msg.sender,Owner);
    }

    function editKtp (address Owner,address nftKtp, string memory DataNik, string memory Ipfs_Uri) public AdministratorOnly{
        require(UserToKtpData[Owner].Valid,"KTP not found"); 
        UserToKtpData[Owner].NIK = DataNik;
        UserToKtpData[Owner].NftAddress = nftKtp;
        UserToKtpData[Owner].Ktp_Uri = Ipfs_Uri;
        emit KtpUpdated(msg.sender,Owner);
    }

    function removeKtp (address Owner) public AdministratorOnly{
        require(UserToKtpData[Owner].Valid,"KTP not found"); 
        delete UserToKtpData[Owner]; 
        emit KtpRemoved(msg.sender,Owner);
    }
}