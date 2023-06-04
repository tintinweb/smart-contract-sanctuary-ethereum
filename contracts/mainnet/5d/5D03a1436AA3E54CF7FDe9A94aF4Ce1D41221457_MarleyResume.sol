/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract MarleyResume {

    address private deployer;

    struct WorkExperience {
        string employer;
        string title;
        bool currentJob;
        string dateRange;
    }

    struct SchoolExperience {
        string school;
        string degree;
        string major;
        string dateRange;
    }

WorkExperience private _willkie;

WorkExperience private _drinker;

WorkExperience private _marleykwon;

WorkExperience private _hoganlovells;

SchoolExperience private _saintjoes;

SchoolExperience private _penn;

WorkExperience[] public listOfJobs;

SchoolExperience[] public listOfSchools;
 
 constructor() {
        deployer = msg.sender;
        
        _willkie = WorkExperience({
            employer: " Willkie Farr & Gallagher LLP",
            title: " Corporate Associate",
            currentJob: false,
            dateRange: " November 2011 - January 2014, October 2018 - May 2019 "
        });
        listOfJobs.push(_willkie);

        _drinker = WorkExperience({
            employer: " Drinker Biddle & Reath LLP",
            title: " Associate",
            currentJob: false,
            dateRange: " March 2014 - June 2015, March 2016 - October 2018 "
        });
        listOfJobs.push(_drinker);

        _marleykwon = WorkExperience({
            employer: " MarleyKwon LLP",
            title: " Co-Founder",
            currentJob: false,
            dateRange: " June 2015 - March 2016 "
        });
        listOfJobs.push(_marleykwon);

        _hoganlovells = WorkExperience({
            employer: " Hogan Lovells US LLP",
            title: " Senior Associate",
            currentJob: true,
            dateRange: " May 2019 - present "
        });
        listOfJobs.push(_hoganlovells);

        _saintjoes = SchoolExperience({
            school: "Saint Joseph's University",
            degree: " Bachelor of Arts",
            major: " Philosophy and History",
            dateRange: " 2004 - 2008 "
        });
        _penn = SchoolExperience({
            school: "University of Pennsylvania Law School",
            degree: " Juris Doctor",
            major: " not applicable",
            dateRange: " 2009 - 2011 "
        });
    }

    function getCurrentJob () public view returns (WorkExperience memory){
        return _hoganlovells;
    }

    function getLawSchool () public view returns (SchoolExperience memory){
        return _penn;
    }

    function getUndergrad () public view returns (SchoolExperience memory){
        return _saintjoes;
    }

    function getAllJobs () public view returns (WorkExperience[] memory){
        return listOfJobs;
    }

    function destroyContract() public {
        require(msg.sender == deployer, "error");
        selfdestruct(payable(msg.sender));
    }

}