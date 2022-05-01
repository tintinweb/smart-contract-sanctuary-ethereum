// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract Signup {
    uint256 public counter;
    uint16 public platformCut = 10;
    address public owner;

    struct Event {
        uint16 headCount;
        uint16 remainingCount; // remaining head count of the event
        address creator; // creator of the event
        //address tokenAddr; // token for event signup, 0x0000000000000000000000000000000000000000 for ETH
        uint256 createTime;
        uint256 depositRequirement;
        uint256 dueTime;
        uint256 attendantCount;
        uint16 creatorCut;
        bool notSentBack; // already send back or not
        mapping (address => bool) participants; // addresses that signed up, TODO: +1 features
        address[] attendants; // address that showed up on the event
        mapping (address => bool) checkedIn;
        string metadata;
        address[] contractAddresses;
        mapping (string => address) userHandle2Address;
    }

    mapping (uint256 => Event) public allEvents;
    
    mapping (address => uint256) public user2EventCountSignUp;
    mapping (address => mapping(uint256 => uint256)) public user2EventIDsSignUp;

    mapping (address => uint256) public user2EventCountShowUp;
    mapping (address => mapping(uint256 => uint256)) public user2EventIDsShowUp;

    mapping (address => uint256) public user2EventCountCreate;
    mapping (address => mapping(uint256 => uint256)) public user2EventIDsCreate;

    mapping (uint256 => uint256) public eventId2RaffleCount;
    mapping (uint256 => mapping(uint256 => address)) public eventId2RaffleResults;

    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    event CreateEvent(uint256 eventId, uint exprTime);
    
    event SignUp(uint256 eventId, address participant);

    event CheckIn(uint256 eventId, address attendant);

    event Release(uint256 eventId);

    function checkIfUserSignup(uint256 eventId, address user) external view returns (bool) {
        return allEvents[eventId].participants[user];
    }

    function getEventAttendants(uint256 eventId) external view returns (address[] memory) {
        return allEvents[eventId].attendants;
    }

    function getUserAddressFromHandle(uint256 eventId,string calldata handle) external view returns (address) {
        return allEvents[eventId].userHandle2Address[handle];
    }

    function getUserSignUp(address user) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](user2EventCountSignUp[user]);
        for(uint i = 0; i < user2EventCountSignUp[user]; i++){
            result[i] = user2EventIDsSignUp[user][i];
        }
        return result;
    }

    function getUserShowUp(address user) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](user2EventCountShowUp[user]);
        for(uint i = 0; i < user2EventCountShowUp[user]; i++){
            result[i] = user2EventIDsShowUp[user][i];
        }
        return result;
    }

    function getUserCreate(address user) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](user2EventCountCreate[user]);
        for(uint i = 0; i < user2EventCountCreate[user]; i++){
            result[i] = user2EventIDsCreate[user][i];
        }
        return result;
    }

    function getEventUserAddressFromUserHandle(uint256 eventId, string calldata userHandle) external view returns (address) {
        return allEvents[eventId].userHandle2Address[userHandle];
    }

    function getRandom(uint high) private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp + block.difficulty + block.number))) % high;
    }

    function getEventRaffleHistory(uint256 eventId) external view returns (address[] memory){
        address[] memory result = new address[](eventId2RaffleCount[eventId]);
        for(uint i = 0; i < eventId2RaffleCount[eventId]; i++){
            result[i] = eventId2RaffleResults[eventId][i];
        }
        return result;
    }

    function raffleFromAttendants(uint256 eventId) external returns (address) {
        require(allEvents[eventId].creator != address(0), "Invalid ID");
        require(allEvents[eventId].creator == msg.sender, "Not Event Creator");
        address raffled = allEvents[eventId].attendants[getRandom(allEvents[eventId].attendantCount)];
        
        eventId2RaffleResults[eventId][eventId2RaffleCount[eventId]] = raffled;
        eventId2RaffleCount[eventId] += 1;
        return raffled;
    }

    function createEvent(uint256 depositRequirement, uint256 dueTime, uint16 headCount, uint16 creatorCut, string calldata metadata, address[] calldata contractAddresses) external returns (uint256) {
        require(headCount > 0, "Invalid count");
        require(depositRequirement >= 0, "Invalid depositRequirement");
        require(dueTime > 0, "Invalid Due Time");
        require(creatorCut >= 0 && creatorCut < 100, "Invalid Creator Cut Percentage");

        uint256 eventId = counter;
        Event storage e = allEvents[eventId];
        e.headCount = headCount;
        e.remainingCount = headCount;
        e.creator = msg.sender;
        e.createTime = block.timestamp;
        e.depositRequirement = depositRequirement * 1e15; // 1 ether = 1000000000000000000 wei
        e.dueTime = dueTime;
        e.attendantCount = 0;
        e.notSentBack = true;
        e.attendants = new address[](headCount);
        e.metadata = metadata;
        e.creatorCut = creatorCut;
        e.contractAddresses = contractAddresses;
        counter = counter + 1;

        user2EventIDsCreate[msg.sender][user2EventCountCreate[msg.sender]] = eventId;
        user2EventCountCreate[msg.sender] += 1;
    
        emit CreateEvent(eventId, e.createTime+(dueTime*1 days));
        return eventId;
    }

    function signUpEvent(uint256 eventId, string calldata userHandle) external payable returns (bool) {
        require(allEvents[eventId].creator != address(0), "Invalid ID");
	    require(allEvents[eventId].remainingCount > 0, "No Space left");
	    require(block.timestamp < allEvents[eventId].createTime+(allEvents[eventId].dueTime*1 days), "Due Date Passed");
        require(allEvents[eventId].creator != msg.sender, "Creator Cannot Signup");
        require(allEvents[eventId].depositRequirement == msg.value, "ETH Amount Not Correct");
        require(!allEvents[eventId].participants[msg.sender], "User Already Signed Up");
        require(bytes(userHandle).length > 0, "invalid user handle");
        require(allEvents[eventId].userHandle2Address[userHandle] == address(0), "user handle used");
        require(allEvents[eventId].notSentBack, "Event Fund Already Released");
        // TODO: token id already signed up
        if(allEvents[eventId].contractAddresses.length > 0){   
            for(uint i = 0; i < allEvents[eventId].contractAddresses.length; i++){
                IERC721 token = IERC721(allEvents[eventId].contractAddresses[i]);
                uint count = token.balanceOf(msg.sender);
                require(count > 0, "User NFT holdings doen't meet the requirements");
            }
        }

        user2EventIDsSignUp[msg.sender][user2EventCountSignUp[msg.sender]] = eventId;
        user2EventCountSignUp[msg.sender] += 1;
        allEvents[eventId].remainingCount -= 1;
        allEvents[eventId].userHandle2Address[userHandle] = msg.sender;
        allEvents[eventId].participants[msg.sender] = true;
        emit SignUp(eventId, msg.sender);
	    return true;
    }

    function checkInAttendant(uint256 eventId, address attendant) external returns (bool) {
        require(allEvents[eventId].creator != address(0), "Invalid ID");
        require(allEvents[eventId].creator == msg.sender, "Not Event Creator");
        require(allEvents[eventId].participants[attendant], "Not Such Participant");
        require(!allEvents[eventId].checkedIn[attendant], "Already checked in");
        require(allEvents[eventId].notSentBack, "Event Fund Already Released");
        
        allEvents[eventId].attendants[allEvents[eventId].attendantCount] = attendant;
        allEvents[eventId].attendantCount += 1;
        user2EventIDsShowUp[attendant][user2EventCountShowUp[attendant]] = eventId;
        user2EventCountShowUp[attendant] += 1;
        allEvents[eventId].checkedIn[attendant] = true;
        emit CheckIn(eventId, attendant);
        return true;
    }

    function releaseDeposit(uint256 eventId) external returns (uint256){
        require(allEvents[eventId].creator != address(0), "Invalid ID");
        require(allEvents[eventId].creator == msg.sender, "Not Event Creator");
        require(allEvents[eventId].notSentBack, "Event Fund Already Released");
        allEvents[eventId].notSentBack = false;

        uint256 noShowAmount = allEvents[eventId].depositRequirement * (allEvents[eventId].headCount-allEvents[eventId].remainingCount-allEvents[eventId].attendantCount);
        uint256 platformAmount = noShowAmount / 100 * platformCut;
        uint256 creatorAmount = noShowAmount / 100 * allEvents[eventId].creatorCut;
        uint256 attendantsAmount = noShowAmount - platformAmount - creatorAmount;

        uint256 eachAttendantAmount = attendantsAmount / allEvents[eventId].attendantCount + allEvents[eventId].depositRequirement;
        for(uint i = 0; i < allEvents[eventId].attendantCount; i++){
            address attendant = allEvents[eventId].attendants[i];
            require(payable(attendant).send(eachAttendantAmount), "Transfer ETH to attendent failed");
        }

        require(payable(allEvents[eventId].creator).send(creatorAmount), "Transfer ETH to creator failed");
        require(payable(owner).send(platformAmount), "Transfer ETH to platform failed");

        emit Release(eventId);
        return platformAmount;
    }


}