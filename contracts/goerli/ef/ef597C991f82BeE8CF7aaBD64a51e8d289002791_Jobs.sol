// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

///@title A simple job dapp
///@author Flavia Gallois
contract Jobs {
    struct Job {
        address author;
        address worker;
        string description;
        uint256 price;
        bool isFinished;
    }
    Job[] jobs;

    event jobAdded(
        address indexed author,
        string description,
        uint256 price,
        uint256 id,
        bool isFinished
    );
    event jobTaken(address indexed worker, uint256 id);
    event jobIsFinishedAndPaid(
        address indexed author,
        address indexed worker,
        uint256 id,
        uint256 pricePaid
    );

    ///@notice Allows to add a new job
    ///@param _description is a detailed description of the job to add
    function addJob(string calldata _description) external payable {
        jobs.push(Job(msg.sender, address(0), _description, msg.value, false));
        emit jobAdded(
            msg.sender,
            _description,
            msg.value,
            jobs.length - 1,
            false
        );
        //(bool success, ) = address(this).call{value: msg.value}("");
        //require(success, "The ETH payment storing failed");
    }

    ///@notice Allows to take a job
    ///@param _id is the index of the job in the jobs Array
    function takeJob(uint256 _id) external {
        require(jobs[_id].worker == address(0), "The job is already booked");
        require(
            msg.sender != jobs[_id].author,
            "The author cannot be the worker"
        );
        jobs[_id].worker = msg.sender;
        emit jobTaken(msg.sender, _id);
    }

    ///@notice Allows to end the job and pay the worker
    ///@param _id is the index of the job in the jobs Array
    function setIsFinishedAndPaid(uint256 _id) external {
        require(
            msg.sender == jobs[_id].author,
            "Only the author can close the job"
        );
        require(
            jobs[_id].worker != address(0) && jobs[_id].isFinished == false,
            "The job is already closed"
        );
        emit jobIsFinishedAndPaid(
            msg.sender,
            jobs[_id].worker,
            _id,
            jobs[_id].price
        );
        jobs[_id].isFinished = true;
        (bool success, ) = jobs[_id].worker.call{value: jobs[_id].price}("");
        require(success, "The ETH worker payment failed");
    }
}