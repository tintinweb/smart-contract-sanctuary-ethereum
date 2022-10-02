// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IDataTypes.sol";
import "./IStudentRegistrar.sol";

contract Lab3Validator {
    function checkTypes(address contract_, bool withAdditionalTask_) external view returns(bool) {
        IDataTypes lab3Contract_ = IDataTypes(contract_);

        if (lab3Contract_.getInt256() == 0) return false;
        if (lab3Contract_.getUint256() == 0) return false;
        if (lab3Contract_.getInt8() == 0) return false;
        if (lab3Contract_.getUint8() == 0) return false;
        if (!lab3Contract_.getBool()) return false;
        if (lab3Contract_.getAddress() == address(0)) return false;
        if (lab3Contract_.getBytes32() == bytes32(0x0)) return false;

        uint256[5] memory _arrS = lab3Contract_.getArrayUint5();

        for (uint256 i = 0; i < 5; i++) {
            if (_arrS[i] == 0) return false;
        }

        if (lab3Contract_.getArrayUint5().length == 0) return false;

        if ((keccak256(abi.encodePacked((lab3Contract_.getString()))) 
            != keccak256(abi.encodePacked(("Hello World!"))))) return false;

        if (withAdditionalTask_ && lab3Contract_.getBigUint() <= 1000000) return false;

        return true;
    }

    function validateStudentRegistrar(address _toValidate) external returns(bool) {
        IStudentRegistrar studentRegistrar_ = IStudentRegistrar(_toValidate);

        IStudentRegistrar.StudentInfo memory me_ = IStudentRegistrar.StudentInfo("Validator", "CS2022", 0, true);

        studentRegistrar_.setNewStudent(me_);

        IStudentRegistrar.StudentInfo memory toCompare1_ = studentRegistrar_.getStudent(address(this));

        require(
            ((keccak256(abi.encodePacked((toCompare1_.name))) 
            == keccak256(abi.encodePacked((me_.name))))), 
            "Lab3Validator: getStudent invalid name"
        );
        require(
            ((keccak256(abi.encodePacked((toCompare1_.groupName))) 
            == keccak256(abi.encodePacked((me_.groupName))))), 
            "Lab3Validator: getStudent invalid group name"
        );
        require(toCompare1_.numberInGroup == me_.numberInGroup, "Lab3Validator: getStudent invalid number in the group");
        require(toCompare1_.onBudget == me_.onBudget, "Lab3Validator: getStudent invalid on budget field");

        IStudentRegistrar.StudentInfo memory toCompare2_ = studentRegistrar_.getMyInfo();

        require(
            ((keccak256(abi.encodePacked((toCompare2_.name))) 
            == keccak256(abi.encodePacked((me_.name))))), 
            "Lab3Validator: getMyInfo invalid name"
        );
        require(
            ((keccak256(abi.encodePacked((toCompare2_.groupName))) 
            == keccak256(abi.encodePacked((me_.groupName))))), 
            "Lab3Validator: getMyInfo invalid groupName"
        );
        require(toCompare2_.numberInGroup == me_.numberInGroup, "Lab3Validator: getMyInfo invalid number in the group");
        require(toCompare2_.onBudget == me_.onBudget, "Lab3Validator: getMyInfo invalid on budget field");

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDataTypes {
    function getInt256() external view returns(int256);
    function getUint256() external view returns(uint256);
    function getInt8() external view returns(int8);
    function getUint8() external view returns(uint8);
    function getBool() external view returns(bool);
    function getAddress() external view returns(address);
    function getBytes32() external view returns(bytes32);
    function getArrayUint5() external view returns(uint256[5] memory);
    function getArrayUint() external view returns(uint256[] memory);
    function getString() external view returns(string memory);

    function getBigUint() external pure returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStudentRegistrar {
    struct StudentInfo {
        string name;
        string groupName;
        uint256 numberInGroup;
        bool onBudget;
    }

    function setNewStudent(StudentInfo calldata _newStudent) external;
    function getStudent(address _student) external view returns(StudentInfo memory);
    function getMyInfo() external view returns(StudentInfo memory);
}