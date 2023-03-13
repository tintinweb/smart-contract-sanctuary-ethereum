// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

contract MyContract {
    // only for taking input for function uploadAttendance
    struct uploadAttendanceHelper {
        string subject_id;
        string student_id;
        bool status;
        string remark;
        string date;
        string timestamp;
    }

    // Struct to store the attendance data
    struct AttendanceData {
        string date;
        string timestamp;
        bool status;
        string remark;
        uint256 record_id;
    }

    // Struct to store the attendance details
    struct AttendanceDetail {
        uint256 total_classes;
        uint256 classes_attended;
        //This is intended to keep count of total number of entries inside the student_attendance_data, which is used as the primary key for entries. This primary keys are used to update remarks.
        uint256 entry_count;
        AttendanceData[] student_attendance_data;
    }

    //subject_id => student_id => AttendanceDetail.
    mapping(string => mapping(string => AttendanceDetail))
        public attendanceRecord;

    //function to upload the attendance details into the block chain.
    function uploadAttendance(uploadAttendanceHelper[] memory _data) public {
        for (uint256 i; i < _data.length; i++) {
            uploadAttendanceHelper memory record = _data[i];

            AttendanceDetail storage tmp = attendanceRecord[record.subject_id][
                record.student_id
            ];

            //incrimenting total classes
            tmp.total_classes = tmp.total_classes + 1;
            //only incrimenting the classes attended if and only if record.status = true
            if (record.status == true) {
                tmp.classes_attended = tmp.classes_attended + 1;
            }

            //incrimenting the entry_count
            tmp.entry_count = tmp.entry_count + 1;

            tmp.student_attendance_data.push(
                AttendanceData(
                    record.date,
                    record.timestamp,
                    record.status,
                    record.remark,
                    tmp.entry_count
                )
            );
        }
    }

    // to fetch the student attendance details.
    function getStudentAttendanceDetail(
        string memory subject_id,
        string memory student_id
    ) public view returns (AttendanceDetail memory) {
        return attendanceRecord[subject_id][student_id];
    }

    // to update the remark.
    function updateRemark(
        string memory subject_id,
        string memory student_id,
        string memory _remark,
        uint256 _record_id
    ) public {
        AttendanceData[] storage records = attendanceRecord[subject_id][
            student_id
        ].student_attendance_data;
        for (uint256 i = 0; i < records.length; i++) {
            AttendanceData storage record = records[i];
            if (record.record_id == _record_id) {
                record.remark = _remark;
            }
        }
    }

    // to calculate and return attendance percentage.
    function getAttendancePercentage(
        string memory subject_id,
        string memory student_id
    ) public view returns (uint256) {
        uint256 totalNumberOfClasses = attendanceRecord[subject_id][student_id]
            .total_classes;
        uint256 numberOfClassesAttended = attendanceRecord[subject_id][
            student_id
        ].classes_attended;
        return (numberOfClassesAttended / totalNumberOfClasses) * 100;
    }

    // Struct to store the leave records
    struct LeaveRecords {
        // url of the document uploaded in google drive or somewhere
        string url;
        string date;
        string timestamp;
    }

    // student_id => LeaveRecords[]
    mapping(string => LeaveRecords[]) public leaveRecordsMap;

    // function to add/update the leave records
    function updateLeaveRecords(
        string memory url,
        string memory date,
        string memory timestamp,
        string memory student_id
    ) public {
        LeaveRecords[] storage tmp = leaveRecordsMap[student_id];
        tmp.push(LeaveRecords(url, date, timestamp));
    }

    // function to retrieve leave records
    function getLeaveRecords(
        string memory student_id
    ) public view returns (LeaveRecords[] memory) {
        return leaveRecordsMap[student_id];
    }
}