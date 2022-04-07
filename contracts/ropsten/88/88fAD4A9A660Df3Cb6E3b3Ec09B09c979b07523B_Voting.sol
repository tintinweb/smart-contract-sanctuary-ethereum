/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address internal owner1;
    address internal owner2;
    address internal owner3;
    uint256 internal startTime;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3);
		_;
  	}

  	constructor() {
          startTime = block.number;
    }

  	function transferOwnership(address _to) onlyOwner public {
        require(_to != owner1 && _to != owner2 && _to != owner3);
        require(_to != address(0x0));
        if (msg.sender == owner1){
            owner1 = _to;
            emit OwnerTransferPropose(owner1, _to);
        }
        else if (msg.sender == owner2){
            owner2 = _to;
            emit OwnerTransferPropose(owner2, _to);
        }
        else if (msg.sender == owner3){
            owner3 = _to;
            emit OwnerTransferPropose(owner3, _to);
        }
  	}
}

contract Voting is OwnerHelper {
    uint8 private ownerCount;
    uint8 private voteCount;
    uint8 private vote1;
    uint8 private vote2;
    uint8 private vote3;
    uint8 private getVote1;
    uint8 private getVote2;
    uint8 private getVote3;
    address private realOwner;
    uint8 private value;

    modifier checkOwner {
		require(msg.sender == realOwner);
		_;
  	}
    
    constructor() {
        ownerCount = 0;
        voteCount = 0;
        vote1 = 0;
        vote2 = 0;
        vote3 = 0;
        getVote1 = 0;
        getVote2 = 0;
        getVote3 = 0;
        realOwner = address(0x0);
        value = 0;
    }

    struct Status {
        uint8 sownerCount;
        uint8 svoteCount;
        uint8 svote1;
        uint8 svote2;
        uint8 svote3;
        uint8 sgetVote1;
        uint8 sgetVote2;
        uint8 sgetVote3;
        address srealOwner;
        uint8 svalue;
        uint256 time;
    }

    function getStatus() public view returns(Status memory){
        Status memory status;
        status.sownerCount = ownerCount;
        status.svoteCount = voteCount;
        status.svote1 = vote1;
        status.svote2 = vote2;
        status.svote3 = vote3;
        status.sgetVote1 = getVote1;
        status.sgetVote2 = getVote2;
        status.sgetVote3 = getVote3;
        status.srealOwner = realOwner;
        status.svalue = value;
        status.time = block.timestamp;
        return status;
    }

    function becomeOwner(address _person) public returns (bool){
        if (ownerCount == 3){
            return false;
        }
        if (ownerCount == 0){
            owner1 = _person;
            ownerCount++;
            return true;
        }
        else if (ownerCount == 1 && owner1 != _person){
            owner2 = _person;
            ownerCount++;
            return true;
        }
        else if (ownerCount == 2 && owner1 != _person && owner2 != _person){
            owner3 = _person;
            ownerCount++;
            return true;
        }
    }

    function showOwner(uint _order) public view returns (address) {
        if (_order == 1){
            return owner1;
        }
        else if (_order == 2){
            return owner2;
        }
        else if (_order == 3){
            return owner3;
        }
        else {
            return address(0x0);
        }
    }

    function vote(uint _order) onlyOwner public returns(bool) {
        require(_order == 1 || _order == 2 || _order == 3);
        if (msg.sender == owner1 && vote1 == 0){
            if (_order == 1){
                getVote1++;
            }
            else if (_order == 2){
                getVote2++;
            }
            else if (_order == 3){
                getVote3++;
            }
            vote1 = 1;
        }
        if (msg.sender == owner2 && vote2 == 0){
            if (_order == 1){
                getVote1++;
            }
            else if (_order == 2){
                getVote2++;
            }
            else if (_order == 3){
                getVote3++;
            }
            vote2 = 1;
        }
        if (msg.sender == owner3 && vote3 == 0){
            if (_order == 1){
                getVote1++;
            }
            else if (_order == 2){
                getVote2++;
            }
            else if (_order == 3){
                getVote3++;
            }
            vote3 = 1;
        }
        
        if (vote1 == 1 && vote2 == 1 && vote3 == 1 && realOwner == address(0x0)){
            if (getVote1 >= 2){
                realOwner = owner1;
            }
            else if (getVote2 >= 2){
                realOwner = owner2;
            }
            else if (getVote3 >= 2){
                realOwner = owner3;
            }
            vote1 = 0;
            vote2 = 0;
            vote3 = 0;
            getVote1 = 0;
            getVote2 = 0;
            getVote3 = 0;
            if (realOwner == address(0x0)){
                realOwner = owner1;
            }
            return true;
        }
        else {
            return false;
        }
    }

    function showRealOwner(address _person) public view returns (string memory){
        if (realOwner == _person){
            return "realOwner";
        }
        else {
            return "Not realOwner";
        }
    }

    function getValue() public view returns (uint8){
        return value;
    }

    function setValue(uint8 _val) checkOwner public returns (bool){
        value = _val;
        return true;
    }

    function lastMethod(uint8 _order) onlyOwner public returns (bool){
        if (block.number < startTime + 5000){
            return false;
        }
        if (_order == 1 && vote1 == 1){
            realOwner = owner1;
            vote1 = 0;
            vote2 = 0;
            vote3 = 0;
            getVote1 = 0;
            getVote2 = 0;
            getVote3 = 0;
            return true;
        }
        else if (_order == 2 && vote2 == 1){
            realOwner = owner2;
            vote1 = 0;
            vote2 = 0;
            vote3 = 0;
            getVote1 = 0;
            getVote2 = 0;
            getVote3 = 0;
            return true;
        }
        else if (_order == 3 && vote3 == 1){
            realOwner = owner3;
            vote1 = 0;
            vote2 = 0;
            vote3 = 0;
            getVote1 = 0;
            getVote2 = 0;
            getVote3 = 0;
            return true;
        }
        else {
            return false;
        }
    }

}