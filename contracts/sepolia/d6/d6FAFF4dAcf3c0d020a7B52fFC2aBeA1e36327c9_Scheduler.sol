//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./SchedulerBase.sol";

contract Scheduler is SchedulerBase {

    modifier Auth (bytes32 _jobID, bool _onlyOwner) {

        require (IDToJob[_jobID].ID == _jobID && IDToJob[_jobID].isActive,
            "Invalid ID or query for inactive job"
        );

        if (_onlyOwner) {

            require (IDToJob[_jobID].owner == msg.sender || IsApproved[_jobID][msg.sender], 
                "Unauthorized"
            );
        }
        _;
    }


    //Getter Functions: -------------------------------------------------------------------

    function getFulfillment (bytes32 _jobID, uint256 _index) external view returns (bool[] memory success, bytes[] memory response, uint256 timestamp) {

        Fulfillment memory f = IDToJob[_jobID].fulfillments[_index]; return (f.success, f.response, f.timestamp); 
    }   

    function getCall (bytes32 _jobID, uint256 _index) external view returns (bytes memory data, address target, uint256 reqfunds) {

        Call memory call = IDToJob[_jobID].calls[_index]; return (call.data, call.target, call.reqfunds);
    } 

    function getJobSchedule (bytes32 _jobID) external view returns (uint256 num, uint256[] memory numArr, string memory str) {
        
        return decodeSchedule(IDToJob[_jobID].schedule, IDToJob[_jobID].jobType);
    }

    function getJobFunding (bytes32 _jobID) public view returns (uint256 reqfunds) {

        for (uint i = 0; i < IDToJob[_jobID].calls.length; i++) {
            reqfunds += IDToJob[_jobID].calls[i].reqfunds;
        }

        return reqfunds;
    }
    
    //Helper Functions: -------------------------------------------------------------------

    function decodeSchedule (bytes memory _schedule, JobTypes _type) internal pure returns (uint256 num, uint256[] memory numArr, string memory str) {
        
        str = _type == JobTypes.Cron ? 
            (string(_schedule)) : ("")
        ;

        numArr = _type == JobTypes.Date || _type == JobTypes.Recurrence ? 
            (abi.decode(_schedule, (uint256[]))) : (new uint256[](0))
        ; 

        num = _type == JobTypes.Blocktime ? 
            (abi.decode(_schedule, (uint256))) : (0)
        ; 

        return (num, numArr, str);
    }


    function verifySchedule (bytes memory _schedule, JobTypes _type) internal view returns (bool verified) {

        (uint256 num, uint256[] memory numArr,) = decodeSchedule(
            _schedule, _type
        );

        if (_type == JobTypes.Cron) {
            verified = _schedule.length >= 5;
        } 

        else if (_type == JobTypes.Blocktime) {
            verified = num > block.timestamp;
        }
        
        else { 

            verified = true;

            for (uint i = 0; i < numArr.length; i++) {

                verified = _type == JobTypes.Date ?
                    (numArr[i] >= DateLB[i] && numArr[i] <= DateUB[i]) :
                    (numArr[i] >= ReccurenceLB[i] && numArr[i] <= ReccurenceUB[i])
                ;

                if (!verified) {
                    break;
                }
            }
        }

        return verified;
    }
    
    //Primary Functions: -------------------------------------------------------------------

    function scheduleJob (Call[] memory _calls, bytes memory _schedule, JobTypes _type, address _validator) external returns (bytes32 ID) {

        require (address(this) != _validator, "Invalid validator");
        require (verifySchedule(_schedule, _type), "Invalid schedule"); 

        ID = keccak256(abi.encodePacked(
            block.timestamp, block.number, block.prevrandao, msg.sender
        ));

        IDToJob[ID].ID = ID;
        IDToJob[ID].owner = msg.sender;
        IDToJob[ID].validator = _validator;
        IDToJob[ID].schedule = _schedule;
        IDToJob[ID].jobType = _type;
        IDToJob[ID].isActive = true;

        if (msg.sender != tx.origin) {
            IsApproved[ID][tx.origin] = true;
        }

        for (uint i = 0; i < _calls.length; i++) {
            addCall(ID, _calls[i]); 
        }

        JobIDs.push(ID);
        emit JobCreated (ID, _validator, _schedule, _type, block.timestamp);
    }   

    function fulfillJob (bytes32 _jobID) external Auth (_jobID, false) {

        require (IDToJob[_jobID].validator == msg.sender,
            "Unauthorized"
        );

        require (Subscription[IDToJob[_jobID].owner] >= getJobFunding(_jobID),
            "Insufficient funds"
        );

        Job memory job = IDToJob[_jobID]; 

        bool[] memory success = new bool[](job.calls.length);
        bytes[] memory response = new bytes[](job.calls.length);

        for (uint i = 0; i < job.calls.length; i++) {

            Call memory call = job.calls[i];

            (bool s, bytes memory r) = payable(call.target).call{
                value: call.reqfunds
            }(call.data);

            if (s && call.reqfunds > 0) {
                Subscription[job.owner] -= call.reqfunds;
            }

            success[i] = s;
            response[i] = r;
        }

        IDToJob[_jobID].fulfillments.push(Fulfillment({
            success: success,
            response: response,
            timestamp: block.timestamp
        })); 

        emit JobFulfilled (_jobID, msg.sender, success, response, block.timestamp);
    }

    //Secondary Functions: -------------------------------------------------------------------

    function addCall (bytes32 _jobID, Call memory _call) public Auth (_jobID, true) {

        require (address(this) != _call.target, 
            "Invalid target address"
        );

        IDToJob[_jobID].calls.push(_call);
    }

    function removeCall (bytes32 _jobID, uint256 _index) external Auth (_jobID, true) {

        uint256 lastIndex = IDToJob[_jobID].calls.length - 1;

        if (_index != lastIndex) {
            IDToJob[_jobID].calls[_index] = IDToJob[_jobID].calls[lastIndex];
        }

        IDToJob[_jobID].calls.pop();
    }

    //Setter Functions: -------------------------------------------------------------------

    function setValidator (bytes32 _jobID, address _validator) external Auth (_jobID, true) {
        
        require (address(this) != _validator, 
            "Invalid validator"
        );

        IDToJob[_jobID].validator = _validator;
    }

    function setApproval (bytes32 _jobID, address _addr) external Auth(_jobID, true) {
        IsApproved[_jobID][_addr] = !IsApproved[_jobID][_addr];
    }

    function deleteJob (bytes32 _jobID) external Auth (_jobID, true) { 

        uint256 counter;
        bytes32[] memory IDs = new bytes32[] (JobIDs.length - 1);

        for (uint i = 0; i < JobIDs.length; i++) {

            if (JobIDs[i] != _jobID) {
                IDs[counter] = JobIDs[i];
                counter++;
            }
        }

        JobIDs = IDs;
        IDToJob[_jobID].isActive = false;
        
        emit JobDeleted (_jobID, IDToJob[_jobID].validator, block.timestamp);
    }

    //Financial Functions: -------------------------------------------------------------------

    function deposit (address _subscriber) external payable {
        Subscription[_subscriber] += msg.value;
    }

    function withdraw (uint256 _amount) external {

        require (Subscription[msg.sender] >= _amount, 
            "Insufficient funds"

        ); Subscription[msg.sender] -= _amount;
  
        (bool s, ) = payable(msg.sender).call{
            value: _amount

        }(""); require (s, "Withdrawl failed");
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SchedulerBase {

    event JobCreated (bytes32 ID, address Validator, 
        bytes Schedule, JobTypes Type, uint256 Timestamp
    );

    event JobFulfilled (bytes32 ID, address Validator, 
        bool[] Success, bytes[] Response, uint256 Timestamp
    ); 

    event JobDeleted (bytes32 ID, address Validator, uint256 Timestamp); 

    enum JobTypes {Cron, Date, Recurrence, Blocktime}

    struct Call {
        bytes data;
        address target;
        uint256 reqfunds;
    }

    struct Fulfillment {
        bool[] success;
        bytes[] response;
        uint256 timestamp;
    }

    struct Job {
        bytes32 ID;
        address owner;
        address validator;
        bytes schedule;

        bool isActive;
        JobTypes jobType;

        Call[] calls;
        Fulfillment[] fulfillments;
    }

    bytes32[] public JobIDs;
    mapping (bytes32 => Job) public IDToJob;
    mapping (address => uint256) public Subscription;
    mapping (bytes32 => mapping (address => bool)) public IsApproved;

    //If you want to skip a value input 9999: ------------------------

    //Year | Month | Date | Hour | Minute | Second
    uint256[] internal DateLB = [2023, 0, 1, 0, 0, 0]; 
    uint256[] internal DateUB = [9999, 11, 31, 23, 59, 59];

    //Year | Month | Date | Day of Week | Hour | Min | Second
    uint256[] internal ReccurenceLB = [2023, 0, 1, 0, 0, 0, 0];
    uint256[] internal ReccurenceUB = [9999, 11, 31, 6, 23, 59, 59];
}