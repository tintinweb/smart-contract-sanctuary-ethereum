/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.16 <0.9.0;

contract JobPortal {
    struct jobData {
        string companyName;
        string companyWeb;
        string jobTitle;
        string jobCategory;
        string jobType;
        string jobLocation;
        uint256 jobSalary;
        string jobExperience;
        string jobQualification;
        string applicaionLink;
        address payable creator;
        uint256 deposit;
    }
    
    jobData[] internal jobDatas;
    address payable owner ;

  constructor (address _data) {
      owner = payable (_data);   
   }

    function setter(
        uint256 _jobSalary,
        string memory _companyName,
        string memory _companyWeb,
        string memory _jobTitle,
        string memory _jobCategory,
        string memory _jobType,
        string memory _jobLocation,
        string memory _jobExperience,
        string memory _jobQualification,
        string memory _applicaionLink
    ) external payable {
        for (uint8 i = 0; i < jobDatas.length; i++) {
            require(
                jobDatas[i].deposit != msg.value,
                "For Every job the deposit amount should be diffrent"
            );
        }
        jobDatas.push(
            jobData({
                companyName: _companyName,
                companyWeb: _companyWeb,
                jobTitle: _jobTitle,
                jobCategory: _jobCategory,
                jobType: _jobType,
                jobLocation: _jobLocation,
                jobSalary: _jobSalary,
                jobExperience: _jobExperience,
                jobQualification: _jobQualification,
                applicaionLink: _applicaionLink,
                creator: payable(msg.sender),
                deposit: msg.value
            })
        );
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getRefund(uint256 _deposit) external {
        for (uint256 i = 0; i < jobDatas.length; i++) {
            if (
                jobDatas[i].creator == msg.sender &&
                jobDatas[i].deposit == _deposit
            ) {
                owner.transfer((jobDatas[i].deposit * 5) / 100);
                jobDatas[i].creator.transfer(
                    jobDatas[i].deposit - (jobDatas[i].deposit * 5) / 100
                );
                jobDatas[i] = jobDatas[jobDatas.length - 1];
                jobDatas.pop();
            }
        }
    }

    function getAllJobs() external view returns (jobData[] memory) {
        return jobDatas;
    }
}