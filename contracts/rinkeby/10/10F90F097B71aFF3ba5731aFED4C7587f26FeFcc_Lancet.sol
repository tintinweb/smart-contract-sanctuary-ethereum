pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Lancet {
    struct Job {
        address payable provider;
        address buyer;
        uint256 amount;
        bool complete;
    }

    uint256 public s_jobID;
    uint256 public runningJobs;
    uint256 public contractBalance;
    uint256 public s_platformFee;

    address owner;

    mapping(uint256=>Job) public jobs;

    event jobCreated(Job job,uint256 jobID);
    event jobComplete(Job job,uint256 jobID);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function initialize(uint256 s_platformFee_) external {
        s_platformFee = s_platformFee_;
        owner = msg.sender;
    }

    function createJob(address payable provider_, address buyer_, uint256 amount_) payable public{
        require(msg.value == amount_, "Please send the correct amount");
        require(msg.sender == buyer_, "You cannot do this on someone elses behalf");
        s_jobID++;
        runningJobs++;
        uint id = s_jobID;
        jobs[id] = Job(provider_, buyer_,amount_,false);
        
        emit jobCreated(jobs[id], id);
    }

    function cancelJob(uint256 jobID_) public {
        require(jobs[jobID_].buyer == msg.sender || jobs[jobID_].provider == msg.sender, "You do not have access to release these funds");
        require(jobs[jobID_].complete == false, "This job has already been complete and funds have been dispersed");
        jobs[jobID_].complete == true;
        runningJobs--;
    }

    function releaseFunds(uint256 jobID_) public {
        require(jobs[jobID_].buyer == msg.sender, "You do not have access to release these funds");
        require(jobs[jobID_].complete == false, "This job has already been complete and funds have been dispersed");
        jobs[jobID_].complete == true;
        uint256 fee = jobs[jobID_].amount * s_platformFee/100;
        contractBalance+=fee;
        jobs[jobID_].provider.transfer(jobs[jobID_].amount - fee);
        runningJobs--;
        emit jobComplete(jobs[jobID_], jobID_);
    }

    //++++++++
    // Owner Only Functions
    //++++++++

    function setPlatformFee(uint256 platformFee_) public onlyOwner {
        s_platformFee = platformFee_;
    }

    function emergancyRelease(uint256 jobID_, address payable emergancyReceiver_) public onlyOwner {
        jobs[jobID_].complete == true;
        emergancyReceiver_.transfer(jobs[jobID_].amount);
    }

    function withdraw(address payable to) external onlyOwner {
        require(to != address(0), "Cannot recover tokens to the 0 address");
        require(contractBalance>0, "Theres no balance for you to withdraw");
        to.transfer(contractBalance);
        contractBalance = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}