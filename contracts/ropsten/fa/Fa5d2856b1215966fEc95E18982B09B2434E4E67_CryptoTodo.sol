/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CryptoTodo {
    struct Task {
        address owner;
        string text;
        uint32 expDate;
        uint32 doneDate;
        bool isRemoved;
    }

    uint256 private totalTasks;
    address[] private _owners;

    mapping(uint256 => Task) private _tasks;

    event TaskCreated(uint256 id, string text, uint32 expDate);
    event TaskToggled(uint256 id, bool isCompleted);
    event TaskRemoved(uint256 id);
    event TaskRestored(uint256 id);

    constructor() {}

    modifier onlyTaskOwner(uint256 _id) {
        require(_tasks[_id].owner == msg.sender, "CryptoTodo: caller is not the owner of the task");
        _;
    }

    modifier existTask(uint256 _id) {
        require(_exists(_id), "CryptoTodo: there is no task with this id");
        _;
    }

    function task(uint256 _id) external view existTask(_id) returns (Task memory, bool) {
        Task storage t = _tasks[_id];
        return (t, _isExpired(t));
    }

    function personTasks(bool _withExpired, bool _withRemoved) external view returns (Task[] memory, uint[] memory, bool[] memory) {
        uint256 counter = 0;

        for (uint256 i = 0; i < totalTasks; i++) {
            Task storage t = _tasks[i];
            if (t.owner == msg.sender && (_withRemoved || !t.isRemoved) && (_withExpired || !_isExpired(t))) {
                counter++;
            }
        }

        Task[] memory ts = new Task[](counter);
        uint[] memory ids = new uint[](counter);
        bool[] memory isExpiredArr = new bool[](counter);
        counter = 0;

        for (uint256 i = 0; i < totalTasks; i++) {
            Task storage t = _tasks[i];
            if (t.owner == msg.sender && (_withRemoved || !t.isRemoved) && (_withExpired || !_isExpired(t))) {
                ts[counter] = t;
                ids[counter] = i;
                isExpiredArr[counter] = _isExpired(t);
                counter++;
            }
        }

        return (ts, ids, isExpiredArr);
    }

    function onTimeTaskPercents() external view returns (address[] memory, uint256[] memory) {
        address[] memory tOwners = new address[](totalTasks);
        uint256 counter = 0;

        for (uint256 i = 0; i < totalTasks; i++) {
            address owner = _tasks[i].owner;
            bool isUniq = true;
            for (uint256 j = 0; j < counter; j++) {
                if (owner == tOwners[j]) {
                    isUniq = false;
                    break;
                }
            }
            if (isUniq) {
                tOwners[counter] = owner;
                counter++;
            }
        }

        address[] memory owners = new address[](counter);
        uint256[] memory compTasks = new uint256[](counter);
        uint256[] memory ownerTasks = new uint256[](counter);
        uint256[] memory perc = new uint256[](counter);

        if (counter == 0) {
            return (owners, perc);
        }

        for (uint256 i = 0; i < counter; i++) {
            owners[i] = tOwners[i];
        }

        for (uint256 i = 0; i < totalTasks; i++) {
            Task storage t = _tasks[i];
            address owner = t.owner;
            for (uint256 j = 0; j < counter; j++) {
                if (owner == owners[j]) {
                    ownerTasks[j]++;
                    if (t.doneDate != 0 && t.doneDate <= t.expDate) {
                        compTasks[j]++;
                    }
                    break;
                }
            }
        }

        for (uint256 i = 0; i < counter; i++) {
            perc[i] = (compTasks[i] * 100) / ownerTasks[i];
        }

        return (owners, perc);
    }

    function create(string memory _text, uint32 _expDate) external returns (uint256) {
        require(bytes(_text).length != 0, "CryptoTodo: the text of task is empty");
        require(_expDate > block.timestamp, "CryptoTodo: the exp date of task is not in the future");
        address owner = msg.sender;
        uint256 newId = totalTasks;
        _tasks[newId] = Task(owner, _text, _expDate, 0, false);
        totalTasks++;

        emit TaskCreated(newId, _text, _expDate);
        return newId;
    }

    function toggle(uint256 _id) external existTask(_id) onlyTaskOwner(_id) {
        Task storage t = _tasks[_id];
        bool isCompleted = false;
        if (t.doneDate == 0) {
            isCompleted = true;
            t.doneDate = uint32(block.timestamp);
        } else {
            t.doneDate = 0;
        }

        emit TaskToggled(_id, isCompleted);
    }

    function softRemove(uint256 _id) external existTask(_id) onlyTaskOwner(_id) {
        Task storage t = _tasks[_id];
        require(!t.isRemoved, "CryptoTodo: the task has already been removed");
        t.isRemoved = true;

        emit TaskRemoved(_id);
    }

    function restore(uint256 _id) external existTask(_id) onlyTaskOwner(_id) {
        Task storage t = _tasks[_id];
        require(t.isRemoved, "CryptoTodo: the task was not deleted");
        t.isRemoved = false;

        emit TaskRestored(_id);
    }

    function _exists(uint256 _id) private view returns (bool) {
        if (_tasks[_id].expDate == 0) {
            return false;
        }
        return true;
    }

    function _isExpired(Task storage _t) private view returns (bool) {
        return _t.doneDate > _t.expDate || (_t.doneDate == 0 && _t.expDate < block.timestamp);
    }
}