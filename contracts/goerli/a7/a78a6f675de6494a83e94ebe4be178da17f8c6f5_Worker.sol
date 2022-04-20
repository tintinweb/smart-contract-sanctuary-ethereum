//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Greeter.sol";

contract Worker {
    struct Job {
        string name;
        uint salary;
    }

    Job private job;
    Greeter private greeter;

    event JobDone(string indexed jobName, string indexed greet);

    constructor(Job memory _job, address _greeter) {
        job = _job;
        greeter = Greeter(_greeter);
    }

    function checkJob() public view returns (Job memory) {
        return job;
    }

    function doJob() external payable {
        require (msg.value >= job.salary, "Not enough pay");
        string memory greeting = greeter.greet();

        emit JobDone(job.name, greeting);
    }

    function setJob(Job memory _job) public {
        job = _job;
    }
}