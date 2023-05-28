pragma solidity ^0.8.9;

contract ReportRegister {
    event UploadReportEvent();
    event ShareReportEvent();

    struct Report {
        string CID; // CID
        // string patientName;     // 病人名
        string description; //
        uint256 uploadedOn; // Uploaded timestamp
    }

    // Maps owner to their reports
    mapping(address => Report[]) public ownerToReports;



    function uploadReport(
        string memory _CID,
        string memory _description
    ) public {
        require(bytes(_CID).length == 46);
        require(bytes(_description).length < 1024);

        //上传时间戳
        uint256 uploadedOn = block.timestamp;
        Report memory report = Report(_CID, _description, uploadedOn);

        ownerToReports[msg.sender].push(report);

        emit UploadReportEvent();
    }

    function shareReport(
        uint8 _index,
        address _targetAddress
    )public{
        require(_index >= 0 && _index <= 2 ** 8 - 1);
        // require(bytes(_CID).length == 46);
        require(_targetAddress != address(0));

        Report memory report = ownerToReports[msg.sender][_index];
        ownerToReports[_targetAddress].push(report);

        emit ShareReportEvent();
    }

    /**
     * Returns the number of reports associated with the given address
     */
    function getReportCount(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownerToReports[_owner].length;
    }

    /**
     * Returns the report at index in the ownership array
     */
    function getReport(
        uint256 _index
        ) public view returns (
            string memory _CID,
            string memory _description,
            uint256 _uploadedOn
        ) {

        Report memory report = ownerToReports[msg.sender][_index];
        return (report.CID, report.description, report.uploadedOn);
    }



    function getAllReports(
        ) public view returns (Report[] memory) {
        Report[] memory reportsList = new Report[](ownerToReports[msg.sender].length);
            
        for (uint256 i = 0; i < reportsList.length; i++) {
            (
                string memory CID,
                string memory description,
                uint256 uploadedOn
            ) = getReport(i);
            reportsList[i] = Report(CID,description,uploadedOn);
        }
        return reportsList;
    }


    function deleteAllReports() public {
        for (uint256 i = 0; i < ownerToReports[msg.sender].length; i++) {
            ownerToReports[msg.sender].pop();
        }
    }
}