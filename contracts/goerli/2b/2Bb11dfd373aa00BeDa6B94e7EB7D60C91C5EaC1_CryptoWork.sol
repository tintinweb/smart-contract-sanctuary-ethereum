// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
error YouAlreadyRegistered();

contract CryptoWork {
    struct Worker {
        string Name;
        address Address;
        uint256 Rank;
        string Image;
        bool Status;
    }
    uint256 private currentWorkerNumber;
    Worker[] public workerList;
    mapping(address => uint256) private addressToWorkerNumber;

    function register(string memory _name, string memory _imageUrl) public {
        if (addressToWorkerNumber[msg.sender] != 0)
            revert YouAlreadyRegistered();
        workerList.push(
            Worker(_name, msg.sender, currentWorkerNumber, _imageUrl, true)
        );
        addressToWorkerNumber[msg.sender] = currentWorkerNumber;
        currentWorkerNumber++;
    }

    function updateInformation(string memory _name, string memory _imageUrl)
        public
    {
        Worker storage worker = workerList[addressToWorkerNumber[msg.sender]];
        worker.Name = _name;
        worker.Image = _imageUrl;
    }

    function changeStatus(bool _status) public {
        Worker storage worker = workerList[addressToWorkerNumber[msg.sender]];
        worker.Status = _status;
    }

    function getWorker() public view returns (Worker[] memory) {
        return workerList;
    }
}