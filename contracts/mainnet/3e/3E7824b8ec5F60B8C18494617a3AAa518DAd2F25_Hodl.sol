//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Hodl {
    uint256 id;
    struct Details {
        uint256 id;
        uint256 unlockTime;
        uint256 lockedTime;
        address owner;
        uint256 amount;
        bool withdrawn;
    }
    mapping(uint256 => Details) public lockups;
    mapping(address => uint256[]) public depositIds;
    event Deposited(
        uint256 id,
        uint256 unlockTime,
        uint256 lockedTime,
        address owner,
        uint256 amount,
        bool withdrawn
    );
    event Withdrawn(uint256 id, uint256 amount);

    /**
     *@dev function deposit in contract
     *@param _duration {uint256} time duration for token should be locked
     */

    function deposit(uint256 _duration) public payable {
        uint256 _amount = msg.value;
        require(_amount != 0, "Deposit some ethers");
        uint256 _unlockTime = block.timestamp + _duration;
        address _owner = msg.sender;
        lockups[++id] = Details({
            id: id,
            lockedTime: block.timestamp,
            unlockTime: _unlockTime,
            owner: _owner,
            amount: _amount,
            withdrawn: false
        });
        depositIds[msg.sender].push(id);
        emit Deposited(
            id,
            _unlockTime,
            block.timestamp,
            _owner,
            _amount,
            lockups[id].withdrawn
        );
    }

    /**
     *@dev function withdraw in contract
     *@param _id {uint256} lockup id which points to particular lockup
     */
    function withdraw(uint256 _id) public {
        Details memory _lockups = lockups[_id];
        require(!_lockups.withdrawn, "Already Withdrawn");
        require(msg.sender == _lockups.owner, "Unauthorized Access");
        require(
            block.timestamp >= _lockups.unlockTime,
            "You can't withdraw ethers before unlocktime"
        );
        lockups[_id].withdrawn = true;
        payable(msg.sender).transfer(_lockups.amount);
        emit Withdrawn(_id, _lockups.amount);
    }
}