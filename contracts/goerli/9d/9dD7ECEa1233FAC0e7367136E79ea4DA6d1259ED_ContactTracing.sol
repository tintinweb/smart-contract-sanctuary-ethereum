/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract ContactTracing {
    struct Patient {
        string timestamp; // 检测时间
        string deviceId;   // 设备ID
        string report;     // 检测报告,positive(阳性),close(密接)
    }

    //声明一个数组来包含Patient结构体实例
    Patient[] public patients;

    // 在合约构造函数中添加两个初始元素
    // constructor() {
    //     patients.push(Patient("2023-3-2", "deviceA", "positive"));
    //     patients.push(Patient("2023-3-2", "deviceB", "close"));
    // }

    // 添加一个新的Patient到数组中
    function addPatient(string memory timestamp, string memory deviceId, string memory report) public {
        patients.push(Patient(timestamp, deviceId, report));
    }

    //获取数组长度
    function getPatientsCount() public view returns (uint256) {
        return patients.length;
    }

    //获取一个数组内容
    function getPatient(uint256 index) public view returns (string memory,string memory,string memory) {
        return (patients[index].timestamp,patients[index].deviceId,patients[index].report);
    }

    //获取所有数组内容
    function getAllPatients() public view returns (Patient[] memory) {
        uint256 patientCount = getPatientsCount();
        Patient[] memory allPatients = new Patient[](patientCount);
        for (uint256 i = 0; i < patientCount; i++) {
            (string memory timestamp, string memory deviceId, string memory report) = getPatient(i);
            allPatients[i] = Patient(timestamp, deviceId, report);
        }
        return allPatients;
    }

}