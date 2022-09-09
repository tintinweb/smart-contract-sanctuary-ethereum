// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Organization {
    using Strings for uint256;

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);
    event BackupAdminAdded(address indexed account);
    event BackupAdminRemoved(address indexed account);
    event EmployeeAdded(uint256 id, string name);
    event EmployeeRemoved(uint256 id, string name);

    address public admin;
    uint256 initialTime;
    
    struct Attendance {
        string date;
        bool status;
    }

    struct EmployeeDetail {
        address user;
        uint256 id;
        string name;
        uint256 phoneNumber;
        string jobTitle;
        string supervisor;
        string shift;
        bool status;
    }

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    mapping(uint256 => EmployeeDetail) employees;
    mapping(address => bool) backupAdmin;
    mapping(uint256 => mapping(string => Attendance[])) public attendanceData;
    mapping(uint256 => mapping(string => bool)) attendanceStatus;

    modifier onlyAdmin {
        require(admin == msg.sender, "Ownable: caller is not a owner");
        _;
    }

    constructor(uint256 startTime) {
        admin = msg.sender;
        initialTime = startTime;
    }

    function transferOwnership(address newAdmin) external  onlyAdmin returns(bool) {
        require(newAdmin != address(0), "Invalid Address");
        emit OwnershipTransferred(admin, newAdmin); 
        admin = newAdmin;
        return true;
    }

    function addBackupAdmin(address _backupAdmin) external onlyAdmin returns(bool) {
        backupAdmin[_backupAdmin] = true;
        emit BackupAdminAdded(_backupAdmin);
        return true;
    }

    function removeBackupAdmin(address _backupAdmin) external onlyAdmin returns(bool) {
        backupAdmin[_backupAdmin] = false;
        emit BackupAdminRemoved(_backupAdmin);
        return true;
    }

    function addEmployes(EmployeeDetail[] memory employeeDatas) external returns(bool) {
        require(backupAdmin[msg.sender], "Caller is not a BackupAdmin");
        for(uint256 i = 0; i < employeeDatas.length; i++) {
            employees[employeeDatas[i].id] = employeeDatas[i];
            emit EmployeeAdded(employeeDatas[i].id, employeeDatas[i].name);
        }
        return true;
    }

    function removeEmployees(uint256[] memory id) external returns(bool) {
        require(backupAdmin[msg.sender], "Caller is not a BackupAdmin");
        for(uint256 i = 0; i < id.length; i++) {
            emit EmployeeRemoved(id[i], employees[id[i]].name);
            delete employees[id[i]];
        }
        return true;
    }

    function registerAttendance(uint256 id) external returns(string memory) {
        if (initialTime + 28800 <= block.timestamp) {
            initialTime += 1 days;
        }
        require(initialTime <= block.timestamp && initialTime + 28800 >= block.timestamp, "Time exceeds");
        require(employees[id].status, "Invalid Id");
        require(msg.sender == employees[id].user, "Invalid User");
        (string memory date, uint256 year, uint256 month,) = _daysToDate();
        require(!attendanceStatus[id][date], "Already Registered");
        string memory mAndY = string(abi.encodePacked(Strings.toString(month),"-",Strings.toString(year)));
        attendanceData[id][mAndY].push(Attendance(date, true));
        attendanceStatus[id][date] = true;
        return mAndY;
    }

    function isBackupAdmin(address account) external view returns(bool) {
        return backupAdmin[account];
    }

    function getEmployeeDetails(uint256 id) external view returns(EmployeeDetail memory) {
        return employees[id];
    }

    function getAttendance(uint256 id, uint256 month, uint256 year) external view returns(Attendance[] memory) {
        string memory monthAndYear = string(abi.encodePacked(Strings.toString(month),"-",Strings.toString(year)));
        Attendance[] memory data = new Attendance[](attendanceData[id][monthAndYear].length);
        for(uint256 i = 0; i < attendanceData[id][monthAndYear].length; i++) {
            data[i] = attendanceData[id][monthAndYear][i];
        }
        return data;
    }

    function _daysToDate() internal view returns (string memory date, uint256 year, uint256 month, uint256 day) {
        uint __day = block.timestamp / SECONDS_PER_DAY;
        int __days = int(__day);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
        date = string(abi.encodePacked(Strings.toString(day),"-",Strings.toString(month),"-",Strings.toString(year)));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}