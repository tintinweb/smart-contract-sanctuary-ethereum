/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract FundingContract {

    struct _Project{
        address owner;
        string  name;
        uint balance;
        bool isEnable;
    }

    uint private _lastProjectId;
    uint[] private _projectIds;
    mapping (uint => _Project) _projectFunding;

    function createProject(string memory name) public {
        _projectFunding[_lastProjectId] = _Project(msg.sender, name, 0, true);
        _projectIds.push(_lastProjectId);
        _lastProjectId++;
    }

    function donate(uint id) projectEnable(id) public payable {
        require(msg.value > 0, "Please Enter Money Greater then 0");
        _projectFunding[id].balance += msg.value;
    }

    function withdraw(uint id, uint amount) public{
        require(msg.sender == _projectFunding[id].owner, "you are not owner");
        require(amount > 0, "Please Enter Money Greater then 0");
        require(_projectFunding[id].isEnable, "Project disable");
        require(_projectFunding[id].balance >= amount, "you not have momney");

        _projectFunding[id].balance -= amount;
        payable(_projectFunding[id].owner).transfer(amount);
    }

    function toggleProjectStatus(uint id) public {
        require(msg.sender == _projectFunding[id].owner, "you are not owner");
        _projectFunding[id].isEnable =  !_projectFunding[id].isEnable;
    }

    function getProject(uint id) public view returns (_Project memory project){
        return _projectFunding[id];
    }

    function getProjectBalance(uint id) public view returns (uint balance){
        return _projectFunding[id].balance;
    }

    function getAllProject() public view returns (uint[] memory projects){
        return _projectIds;
    }

    modifier projectEnable(uint id) {
      require( _projectFunding[id].isEnable, "Project disable");
      _;
   }
}