/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract PiggyBank {
    address public owner;
    bool public isOver;
    string public desc;

    constructor(address _owner, string memory _desc) {
        owner = _owner;
        desc = _desc;
    }

    function deposit() public payable {
        require(!isOver, "This piggy bank in over!");
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not an owner!");
        require(isWithdrawAvailable(), "You can't do withdraw yet");
        payable(owner).transfer(address(this).balance);
        isOver = true;
    }

    function isWithdrawAvailable() public view virtual returns (bool) {}
}

contract ApprovePiggyBank is PiggyBank {
    address public approver;
    bool public isApproved;

    constructor(
        address _owner,
        string memory _desc,
        address _approver
    ) PiggyBank(_owner, _desc) {
        approver = _approver;
    }

    function isWithdrawAvailable() public view override returns (bool) {
        return isApproved;
    }

    function setApproved() public {
        require(msg.sender == approver, "You are not approver!");
        isApproved = true;
    }

    function setApprover() public {
        approver = msg.sender;
    }
}