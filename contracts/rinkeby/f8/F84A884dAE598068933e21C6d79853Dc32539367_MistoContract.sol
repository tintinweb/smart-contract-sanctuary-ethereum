/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.14;
interface IMistoToken {
    function transfer(address from, address to, uint256 id, uint256 amount) external;
    function mint(uint256 id, uint256 amount) external;
}

interface IMistoOracle {
    function getWeiPrice() view external returns(uint256);
    function setWeiPrice(uint weiPrice) external;
}


contract MistoContract is Ownable, IMistoToken, IMistoOracle {

    IMistoToken private token;
    IMistoOracle private oracle;
    address private tokenAddr;
    address private oracleAddr;
    string private baseUri;
    mapping (uint256 => Task) private tasks;

    event InvestmentComplete(uint256 taskId);

    struct Task {
        uint256 fundsGoal;
        uint256 fundsCurrent;
        bool isValue;
    }

    function addTaskIntoInvestments(uint256 taskId, uint256 _fundsGoal) public onlyOwner {
        require(tasks[taskId].isValue == false, "Task already exists");
        tasks[taskId].fundsGoal = _fundsGoal;
        tasks[taskId].isValue = true;
        mint(taskId, _fundsGoal);
    }

    function removeTaskFromInvestments(uint256 taskId) public onlyOwner {
        tasks[taskId].isValue = false;
    }

    function invest(uint256 taskId) public payable {
        uint256 possibleInvestmentAmount = tasks[taskId].fundsCurrent + msg.value;
        require(tasks[taskId].isValue == true, "Task is not in investments stage");
        require(tasks[taskId].fundsCurrent <= tasks[taskId].fundsGoal, "Investments are closed for this task");
        require(possibleInvestmentAmount <= tasks[taskId].fundsGoal, "Overinvestment is not allowed");

        tasks[taskId].fundsCurrent += msg.value;
        transfer(tokenAddr, msg.sender, taskId, msg.value);

        if (tasks[taskId].fundsCurrent == tasks[taskId].fundsGoal) {
            emit InvestmentComplete(taskId);
            tasks[taskId].isValue == false;
        }
    }

    function getTaskDetails(uint256 taskId) public view returns(string memory) {
        return string(abi.encodePacked(baseUri, taskId));
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function getTaskGoalFund(uint256 taskId) public view returns(uint256) {
        return tasks[taskId].fundsGoal;
    }

    function getTaskCurrentFund(uint256 taskId) public view returns(uint256) {
        return tasks[taskId].fundsCurrent;
    }

    function getTaskStatus(uint256 taskId) public view returns(string memory) {
        if (tasks[taskId].isValue) {
            return "Funding in progress";
        } else {
            return "Funding is finished or task does not exists";
        }
    }

    function transfer(address from, address to, uint256 id, uint256 amount) public {
        token.transfer(from, to, id, amount);
    }

    function mint(uint256 id, uint256 amount) public {
        token.mint(id, amount);
    }

    function setTokenAddress(address _tokenAddr) public onlyOwner {
        token = IMistoToken(_tokenAddr);
        tokenAddr = _tokenAddr;
    }

    function setOracleAddress(address _oraceleAddr) public onlyOwner {
        oracle = IMistoOracle(_oraceleAddr);
        oracleAddr = _oraceleAddr;
    }

    function getWeiPrice() public view returns(uint256) {
        return oracle.getWeiPrice();
    }

    function setWeiPrice(uint weiPrice) public {
        oracle.setWeiPrice(weiPrice);
    }
}