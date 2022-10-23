/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract XTELP is  KeeperCompatibleInterface {

    enum XTELPState {
        OPEN,
        CLOSED
    }

    uint public counter;    
    // Use an i_interval in seconds and a timestamp to slow execution of Upkeep
    uint private i_interval;
    uint public s_lastTimeStamp;


    string userType = "User";
    string hostType = "Host";

    mapping(address => profile) public UserProfile;

    mapping(address => meeting[]) public Meeting;

    mapping(address => uint256) public meetingIndex;
   
    mapping(address => campaign[]) public Campaign;

    mapping(address => uint256) public campaignIndex;

    mapping(address => XTELPState) private s_xtelpState;
    mapping(address => XTELPState) private volunState;
    
    address [] public AllHost;
    
    address [] public AllUser;


    struct profile {
        address addr;
        string name;
        string role;
        uint256 rating;
        string bio;
        string profilePic;
        bool avaliable;
    }
    
    struct meeting {
        address host;
        address user;
        uint256 time;
        uint256 fee;
        bool completed;
    }

    struct campaign {
        address volunteer;
        address user;
        uint256 time;
        uint256 fee;
        bool completed;
    }
   
    modifier onlyHost  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("Host")), "NOT A HOST");
        _;
    }

    modifier onlyUser  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("User")), "NOT A USER");
        _;
    }
    
    modifier onlyVolun  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("Host")) && UserProfile[msg.sender].avaliable == true , "NOT A USER");
        _;
    }

    
    constructor() {
        s_lastTimeStamp = block.timestamp;
        s_xtelpState[msg.sender] = XTELPState.OPEN;
        volunState[msg.sender] = XTELPState.OPEN;
    }

    function createHost(uint256 _rating, string memory _name, string memory _pic, string memory _bio) public {
        AllHost.push(msg.sender);
        s_xtelpState[msg.sender] = XTELPState.OPEN;

        UserProfile[msg.sender].addr = msg.sender;
        UserProfile[msg.sender].name = _name;
        UserProfile[msg.sender].rating = _rating;
        UserProfile[msg.sender].role = hostType;
        UserProfile[msg.sender].profilePic = _pic;
        UserProfile[msg.sender].bio = _bio;
    }

    function createUser(uint256 _rating, string memory _name, string memory _pic, string memory _bio, bool _volun) public {
        AllUser.push(msg.sender);
        UserProfile[msg.sender].addr = msg.sender;
        UserProfile[msg.sender].name = _name;
        UserProfile[msg.sender].rating = _rating;
        UserProfile[msg.sender].role = userType;
        UserProfile[msg.sender].profilePic = _pic;
        UserProfile[msg.sender].bio = _bio;
        UserProfile[msg.sender].avaliable = _volun;
    }

    // Schedule a meeting
    function createSchedule(uint256 _time, uint256 _fee) public onlyHost {
        meeting memory NewMeeting;
        NewMeeting.host = msg.sender;
        NewMeeting.time = _time;
        NewMeeting.fee = _fee;

        i_interval = _time;
        s_xtelpState[msg.sender] = XTELPState.OPEN;

        Meeting[msg.sender].push(NewMeeting);
      
    }

    // Join Meeting
    function joinMeeting(address _host, uint256 _id) public onlyUser {
        Meeting[_host][_id].user = msg.sender;
    } 

    // Create Campaign
    function createCampaign(uint256 _time, uint256 _fee) public onlyUser {
        campaign memory NewCampaign;
        NewCampaign.user = msg.sender;
        NewCampaign.time = _time;
        NewCampaign.fee = _fee;

        i_interval = _time;
        volunState[msg.sender] = XTELPState.OPEN;

        Campaign[msg.sender].push(NewCampaign);
      
    }

    // Volunteer for a campaign
    function joinCampaign(address _volun, uint256 _id) public onlyVolun {
        Campaign[_volun][_id].volunteer = msg.sender;
    }    


   function checkUpkeep(bytes memory /* checkData */) public view override returns ( bool upkeepNeeded,
    bytes memory /* performData */  ) {
        
        for (uint i = 0; i < AllHost.length; i++) {
            for (uint j = 0; j < Meeting[AllHost[i]].length; j++) {
                if(Meeting[AllHost[i]][j].time > 0 && Meeting[AllHost[i]][j].completed == false){
                    bool isOpen = XTELPState.OPEN == s_xtelpState[msg.sender];
                    bool timePassed = ((block.timestamp - s_lastTimeStamp) >  Meeting[AllHost[i]][j].time);
                    upkeepNeeded = (isOpen && timePassed);
                }
                
            }
        }

        for (uint i = 0; i < AllUser.length; i++) {
            for (uint j = 0; j < Campaign[AllUser[i]].length; j++) {
                if(Campaign[AllUser[i]][j].time > 0 && Campaign[AllUser[i]][j].completed == false){
                    bool isOpen = XTELPState.OPEN == s_xtelpState[msg.sender];
                    bool timePassed = ((block.timestamp - s_lastTimeStamp) >  Campaign[AllUser[i]][j].time);
                    upkeepNeeded = (isOpen && timePassed);
                }
                
            }
        }
       
    }

    function performUpkeep(bytes calldata /*performData*/) external override {

        for (uint i = 0; i < AllHost.length; i++) {
            for (uint j = 0; j < Meeting[AllHost[i]].length; j++) {
               (bool upkeepNeeded, ) = checkUpkeep("");
                require(upkeepNeeded, "Doesn't meet requirement for UpKeep");
                Meeting[AllHost[i]][j].completed = true;
                s_xtelpState[AllHost[i]] = XTELPState.CLOSED;
            }
        }  

        for (uint i = 0; i < AllUser.length; i++) {
            for (uint j = 0; j < Meeting[AllUser[i]].length; j++) {
               (bool upkeepNeeded, ) = checkUpkeep("");
                require(upkeepNeeded, "Doesn't meet requirement for UpKeep");
                Meeting[AllUser[i]][j].completed = true;
                volunState[AllUser[i]] = XTELPState.CLOSED;
            }
        }  
        
    }

   
}