/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address internal owner1;
    address internal owner2;
    address internal owner3;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3);
		_;
  	}

  	constructor() {}

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
                voteCount++;
                return false;
            }
            return true;
        }
        else {
            return false;
        }
    }

    function proveRealOwner() checkOwner public view returns (string memory){
        return "The voting is over";
    }

}