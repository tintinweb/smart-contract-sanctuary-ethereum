/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ChatApplication {
    struct user {
        string name;
        string profileHash;
        address userAddress;
        uint256[] fileIdList;
        string emailId;
        string phoneNumber;
        uint256 userId;
        uint256[] jobDutyIdList;
    }

    struct JobDuty {
        uint256 currentTimestamp;
        uint256 scheduledTimestamp;
        string fileName;
        string fileHash;
        string description;

    }
    JobDuty[] jobDuty;

    struct message {
        address sender;
        uint256 timestamp;
        string msgs;
    }

    struct FileStoage {
        address sender;
        address reciever;
        string fileName;
        string fileHash;
        string comment;
        bool recieverConfirmation;
        bool senderConfirmation;
        bool startChat;
        uint256 timestamp;
    }

    FileStoage[] storeFile;
    uint256 public lastUserID = 1;

    mapping(address => user) private userList;
    mapping(bytes32 => message[]) allMessage;
    mapping(uint256 => address) public IdToAddress;

    //check user exist

    function checkUserexists(address pubkey) public view returns (bool) {
        return userList[pubkey].userAddress != address(0);
    }
    function getuserDetails(address _address) view public returns(user memory) {
        require(checkUserexists(_address),"User not exist");
        return userList[_address];
    }
    //create accout

    function createAccount() external {
        require(checkUserexists(msg.sender) == false, "User already exist");
        userList[msg.sender].userAddress = msg.sender;
        userList[msg.sender].emailId = "";
        userList[msg.sender].phoneNumber = "";
        userList[msg.sender].userId = lastUserID;
        IdToAddress[lastUserID] = msg.sender;
        lastUserID++;
    }

    /** set user details */
    function setUserDetails(
        string memory name,
        string memory profileHash,
        string memory emailId,
        string memory phoneNumber
    ) external {
        require(checkUserexists(msg.sender) == true, "User not exist");
        userList[msg.sender].name = name;
        userList[msg.sender].profileHash = profileHash;
        userList[msg.sender].emailId = emailId;
        userList[msg.sender].phoneNumber = phoneNumber;
    }

    function getLength() public view returns (uint256) {
        return storeFile.length;
    }

    function shareFileAndUploadFile(
        address reciever,
        string memory fileHash,
        string memory fileName,
        string memory comment
    ) external {
        require(
            checkUserexists(msg.sender) == true,
            "User Not exist,Login First"
        );
        if (reciever != address(0)) {
            require(
                checkUserexists(reciever) == true,
                "Reciever Not exist, Make Reciever Login"
            );
        }
    
        uint256 fileId = uint256(storeFile.length);
        storeFile.push(
            FileStoage(
                msg.sender,
                reciever,
                fileHash,
                fileName,
                comment,
                false,
                false,
                true,
                block.timestamp
            )
        );
        
        userList[msg.sender].fileIdList.push(fileId);
        if (reciever != address(0)) {
            userList[reciever].fileIdList.push(fileId);
        }       
    }

function createJobDutyById(
    uint256 id,
    uint256 scheduledTimestamp,
    string memory description
    ) external {
        require(
            checkUserexists(msg.sender) == true,
            "User Not exist,Login First"
        );
        require(
            storeFile[id].sender == msg.sender,
            "File not belongs to user"
        );
        string memory _fileName=storeFile[id].fileName;
        string memory _fileHash=storeFile[id].fileHash;

    
        uint256 fileId = uint256(jobDuty.length);
        jobDuty.push(
            JobDuty(
               block.timestamp,
                scheduledTimestamp,
                _fileName,
                _fileHash,
                description
            )
        );
        
            userList[msg.sender].jobDutyIdList.push(fileId);
              
    }

    function createJobDuty(
    uint256 scheduledTimestamp,
    string memory description
    ) external {
        require(
            checkUserexists(msg.sender) == true,
            "User Not exist,Login First"
        );
        string memory _fileName="";
        string memory _fileHash="";

    
        uint256 fileId = uint256(jobDuty.length);
        jobDuty.push(
            JobDuty(
               block.timestamp,
                scheduledTimestamp,
                _fileName,
                _fileHash,
                description
            )
        );
        
            userList[msg.sender].jobDutyIdList.push(fileId);
              
    }



    function getFileId() external view returns (uint256[] memory) {
        return userList[msg.sender].fileIdList;
    }

function getJobDutyFileId() external view returns (uint256[] memory) {
        return userList[msg.sender].jobDutyIdList;
    }
    function getFileDetailById(uint256 id,address _address)
        external
        view
        returns (FileStoage memory)
    {
        require(storeFile[id].sender ==_address || storeFile[id].reciever ==_address,"Unautheraized");

        string memory hash;
if((storeFile[id].reciever ==_address && storeFile[id].senderConfirmation) || storeFile[id].sender ==_address){
            hash = storeFile[id].fileHash;
}else{
                hash = "Not permited";
}

       
            FileStoage memory display = FileStoage(
                storeFile[id].sender,
                storeFile[id].reciever,
                hash,
                storeFile[id].fileName,
                storeFile[id].comment,
                storeFile[id].recieverConfirmation,
                storeFile[id].senderConfirmation,
                storeFile[id].startChat,
                storeFile[id].timestamp
            );
            return display;
       
    }

    function getJobDutyFileDetailById(uint256 id,address _address)
        external
        view
        returns (
            JobDuty memory
            )
    {
        require(checkUserexists(_address),"User not exist");
        require(userList[_address].jobDutyIdList.length>0,"User did not create any job duty");
          bool check =false;
        for(uint i=userList[_address].jobDutyIdList.length;i>0;i--){

            uint ii = i-1;
            if(userList[_address].jobDutyIdList[ii]==id){
                check=true;
            }
        }
 

         require(check,"This is not your job id");
       
             return  jobDuty[id];
       
    }




    function _getChatCode(
        address pubkey1,
        address pubkey2,
        uint256 fileId
    ) internal pure returns (bytes32) {
        if (pubkey1 < pubkey2) {
            return keccak256(abi.encodePacked(pubkey1, pubkey2, fileId));
        } else {
            return keccak256(abi.encodePacked(pubkey2, pubkey1, fileId));
        }
    }

    function sendMessage(string calldata _msg, uint256 fileId) external {
        
        require(
            storeFile[fileId].sender == msg.sender ||
                storeFile[fileId].reciever == msg.sender,
            "Unauthorized"
        );
        address reciever;

        if (storeFile[fileId].sender == msg.sender) {
            reciever = storeFile[fileId].reciever;
        } else {
            reciever = storeFile[fileId].sender;
        }
        bytes32 chatCode = _getChatCode(msg.sender, reciever, fileId);
        message memory newMsg = message(msg.sender, block.timestamp, _msg);
        allMessage[chatCode].push(newMsg);
    }

    function readMessage(uint256 fileId,address _address)
        external
        view
        returns (message[] memory)
    {
        require(
            storeFile[fileId].sender == _address ||
                storeFile[fileId].reciever == _address,
            "Unauthorized"
        );
        address reciever;

        if (storeFile[fileId].sender == _address) {
            reciever = storeFile[fileId].reciever;
        } else {
            reciever = storeFile[fileId].sender;
        }
        bytes32 chatCode = _getChatCode(_address, reciever, fileId);
        require(allMessage[chatCode].length>0,"Nothing in chat");
        return allMessage[chatCode];
    }

    function setRecieverConfirmation(uint256 fileId) external {
        require(storeFile[fileId].reciever == msg.sender, "Unauthorized");
        require(
            storeFile[fileId].recieverConfirmation == false,
            "Already paid"
        );

        storeFile[fileId].recieverConfirmation = true;
    }

    function setSenderConfirmation(uint256 fileId) external {
        require(storeFile[fileId].sender == msg.sender, "Unauthorized");
        require(
            storeFile[fileId].recieverConfirmation == true,
            "Reciever not paid yet"
        );
        require(
            storeFile[fileId].senderConfirmation == false,
            "Sender Already confirm"
        );

        storeFile[fileId].senderConfirmation = true;
    }
}