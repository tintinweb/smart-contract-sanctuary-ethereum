// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract WeatherOracle {
    //mapping from jobId => completion status for smart contract interactions to check;
    //default false for all + non-existent
    mapping(uint => bool) public jobStatus;

    //mapping jobId => temp result. Defaultfor no result is 0.
    //A true jobStatus with a 0 job value implies the result is actually 0
    mapping(uint => uint) public jobResults;

    //current jobId available
    uint jobId;

    //event to trigger Oracle API
    event NewJob(uint lat, uint lon, uint jobId);

    constructor(uint initialId){
        jobId = initialId;
    } 

    function getWeather(uint lat, uint lon) public {
        //emit event to API with data and JobId
        emit NewJob(lat, lon, jobId);
        //increment jobId for next job/function call
        jobId++;
    }

    function updateWeather(uint temp, uint _jobId)public {
        //when update weather is called by node.js upon API results, data is updated
        jobResults[_jobId] = temp;
        jobStatus[_jobId] = true;

        //Users can now check status and result via automatic view function
        //for public vars like these mappings
    }
}