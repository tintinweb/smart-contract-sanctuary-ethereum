// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStudent} from "./interface/IStudent.sol";
import {ITeacher} from "./interface/ITeacher.sol";
import {TeacherErrors} from "./interface/TeacherErrors.sol";

contract Teacher is ITeacher, TeacherErrors {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function setScore(address student, uint256 score) public onlyOwner {
        if (score > 100) {
            revert ScoreTooHigh();
        }
        IStudent(student).setScore(score);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStudent {
    function score() external view returns (uint256);

    function teacher() external view returns (address);

    function setScore(uint256 _score) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStudent} from "./IStudent.sol";

interface ITeacher {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function setScore(address student, uint256 score) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface TeacherErrors {
    error NotOwner();

    error ScoreTooHigh();
}