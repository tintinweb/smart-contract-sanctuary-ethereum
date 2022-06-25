pragma solidity ^0.8.5;
contract DAO_Charity {

    event Log(address indexed sender, string message);
    uint private money_received;
    uint private votes_issued;
    // donation address => time
    mapping(address => uint) private past_projects;
    address[] private voted_doners;

    struct donator {
        uint votes_left;
        uint prop_left;
        bool voted;
    }

    struct project {
        bool isActive; // check project is viable 
        address project_addr;
        uint votes_received;
        uint start_time;
        string description;
    }

    project ongoing_project;
    mapping(address => donator) donator_map;

    function vote() external {
        require(ongoing_project.start_time + 7 days > block.timestamp, "No existing valid proposal.");
        require(ongoing_project.isActive, "No existing valid proposal.");
        require(donator_map[msg.sender].votes_left > 0, "You need to donate to vote.");
        require(!donator_map[msg.sender].voted, "You have already voted.");
        emit Log(msg.sender, "voted");
        donator_map[msg.sender].voted = true;
        ongoing_project.votes_received += donator_map[msg.sender].votes_left;
        voted_doners.push(msg.sender);
        if (2*ongoing_project.votes_received > votes_issued) { // float arithmetic is not supported :(
            liquidation();
        }
    }

    function liquidation() internal {
        emit Log(ongoing_project.project_addr, "liquidating");
        if (payable(ongoing_project.project_addr).send(money_received)) {
            money_received = 0;
            for (uint i = 0; i < voted_doners.length; i++) {
                donator_map[voted_doners[i]].votes_left = 0;
                donator_map[voted_doners[i]].voted = false;
            }
            delete voted_doners;
            emit Log(ongoing_project.project_addr, "liquidated");
        } else {
            ongoing_project.isActive = false;
            emit Log(ongoing_project.project_addr, "liquidation failed");
        }
    }

    function donate() external payable {
        require(msg.value >= 1000000000000000); // 1 finney
        emit Log(msg.sender, "donated");
        money_received += msg.value;
        donator_map[msg.sender].votes_left += msg.value / 1000000000000000;
        donator_map[msg.sender].prop_left += msg.value / 1000000000000000;
    }

    function propose(address proposed_addr, string calldata desc) external {
        require(donator_map[msg.sender].prop_left > 0, "You have to donate first.");
        require(!ongoing_project.isActive || ongoing_project.start_time + 7 days < block.timestamp, "You can propose a new donee, after the current expires.");
        require(proposed_addr != msg.sender && proposed_addr != address(0), "Invalid donee.");
        if (past_projects[proposed_addr] != 0) {
            require(past_projects[proposed_addr] + 10 days < block.timestamp, "A project can't be proposed too often.");
        }
        emit Log(msg.sender, "proposed");
        donator_map[msg.sender].prop_left--;
        past_projects[proposed_addr] = block.timestamp;
        // clear voted list
        for (uint i = 0; i < voted_doners.length; i++) {
            donator_map[voted_doners[i]].voted = false;
        }
        ongoing_project.isActive = true;
        ongoing_project.project_addr = proposed_addr;
        ongoing_project.votes_received = 0;
        ongoing_project.start_time = block.timestamp;
        ongoing_project.description = desc;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) { return "0"; }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function view_project() external view returns (string memory) {
        require(ongoing_project.isActive, "No donee aviliable.");
        return string(abi.encodePacked(
                    "Please always review the donee information before voting. \n Donee address: ", 
                    toAsciiString(ongoing_project.project_addr), 
                    "\n Donee description: ", 
                    ongoing_project.description));
    }
}