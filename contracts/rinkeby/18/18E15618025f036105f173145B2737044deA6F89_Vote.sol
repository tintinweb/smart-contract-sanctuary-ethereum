// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../government/IGovernment.sol";
import "./IVote.sol";

contract Vote is IVote {
    
    mapping(string => VoteInfo) private TheVote;
    string private _name;
    address private _governmentContract;
    uint256 private _supply;

    constructor(address governmentAddress) {
        _name = "2022 Presidential Election";
        _supply = 0;
        _governmentContract = governmentAddress;
    }

    function exist(string memory hashId) public view returns (bool) {
        return TheVote[hashId].voted;
    }

    function vote(string memory hashId, uint256 option) public {
        require(isAllowed(msg.sender), "You're not allowed !!!");
        require(!exist(hashId), "You have already voted !!!");
        TheVote[hashId] = VoteInfo(true, option, block.timestamp);
        _supply++;
    }

    function hashIdOption(string memory hashId) public override view returns (uint256) {
        require(exist(hashId), "You haven't voted yet !!!");
        return TheVote[hashId].option;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function supply() public override view returns (uint256) {
        return _supply;
    }

    function isAllowed(address _address) public view returns (bool) {
        return IGovernment(_governmentContract)._isAllowed(_address);
    }

    function localNameAddress(string memory localName) public view returns (address) {
        return IGovernment(_governmentContract)._localNameAddress(localName);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernment {
    function _isAllowed(address _address) external view returns (bool);

    function _localNameAddress(string memory localName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct VoteInfo {
    bool voted;
    uint256 option;
    uint256 time;
}

interface IVote {
    function hashIdOption(string memory hashId) external view returns (uint256);

    function name() external view returns (string memory);

    function supply() external view returns (uint256);
}