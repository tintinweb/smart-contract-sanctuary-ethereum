/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "https://github.com/orbictdb/ipfs-embedded-api";

contract StoreIPFSAssets {
    //IPFS ipfs;
    address _owner;
    uint256 public fees = 500000000000000 ;
    enum UserType
    {
        ACTIVE,
        INACTIVE
    }
    enum DocType
    {
        ACTIVE,
        EXPIRED
    }

    struct Use {
        address owner;
        bytes32 docHash;
        uint256 ExpiredTime;
        uint256 DocStatus;
        uint256 UserStatus;
        //uint256 currtime;
    }
    mapping(address => Use) public User;

    constructor()  {
        _setOwner(msg.sender);
        //ipfs = new IPFS();
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    

    function UploadDocument(bytes32 _ipfsHash, uint256 time) public payable {
        //require(User[msg.sender].docHash != _ipfsHash,"Can not store same file.");
        require(msg.value==fees,"Enter correct Fees Amount.");
        User[msg.sender].owner = msg.sender;
        User[msg.sender].docHash = _ipfsHash;
        User[msg.sender].ExpiredTime = ( time + block.timestamp ) ;
        User[msg.sender].DocStatus = uint256(DocType.ACTIVE);
        User[msg.sender].UserStatus= uint256(UserType.ACTIVE);
        //User[msg.sender].currtime = block.timestamp;
        // Reload();
    }

    
    function Reload() public {
        if(User[msg.sender].ExpiredTime <= block.timestamp)
        {
            User[msg.sender].DocStatus=uint256(DocType.EXPIRED);
            User[msg.sender].UserStatus=uint256(UserType.INACTIVE);
        }

    }

    modifier checkstatus()
    {
        require(User[msg.sender].docHash!=0,"Please Upload your document first.");
        //require(User[msg.sender].owner==msg.sender,"You are not owner of this doc");
        require(User[msg.sender].ExpiredTime > block.timestamp,"Document Is Expired");
        require(User[msg.sender].ExpiredTime > block.timestamp,"User is INActive");
        _;
    }

    function Download(bytes32 hash) checkstatus public view returns(bytes32)
    {
        require(User[msg.sender].owner==msg.sender,"You are not owner of this doc");
        // require(User[msg.sender].docHash!=0,"Please Upload your document first.");
        // require(User[msg.sender].ExpiredTime > block.timestamp,"Document Is Expired");
        //bytes32 doc=User[msg.sender].docHash;
        return hash;
    }
    
    function viewDocument() checkstatus public view returns(bytes32) {
        return User[msg.sender].docHash;
    }
    // function retrieveAsset() public  {
    //     //return ipfs.cat(_ipfsHash);
    //     Reload();
    //     retrieveDoc();
    // }

    // function retrieveDoc() public view returns (bytes32) {
    //     //return ipfs.cat(_ipfsHash);
    //     //checktime();
    //     return User[msg.sender].docHash;
    // }
    function UserStatus() public view returns(uint256) {
        return User[msg.sender].UserStatus;
    }

    function Fees(uint256 fee) public onlyOwner{
        fees= fee;
    }

    
}