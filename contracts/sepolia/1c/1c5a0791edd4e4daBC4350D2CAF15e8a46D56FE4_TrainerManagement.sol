// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IAdminControl.sol";

contract TrainerManagement{
    struct TrainerDetail {
        uint256 sessionId;
        bool isActive;
    }
    mapping(address => bool) private _blocklist;
    mapping(address => bool) private _allowlist;
    mapping(address => TrainerDetail) public trainers;
    // event
    event trainerAddedToBlocklist(address indexed trainer);
    event trainerAddedToAllowlist(address indexed trainer);
    event trainerRemovedFromBlocklist(address indexed trainer);
    event trainerRemovedFromAllowlist(address indexed trainer);

    IAdminControl private _adminControl;
    address public _febl;

    modifier onlyAdmin(address account) {
        require(_adminControl.isAdmin(account) == true, "You are not admin");
        _;
    }
    modifier onlyFebl(address sender) {
        require(_febl == sender, "You are not Febl");
        _;
    }
    constructor(address adminControl) {
        _adminControl = IAdminControl(adminControl);
    }
    function setFebl(address febl) external onlyAdmin(msg.sender){
        _febl = febl;
    }
    function addToBlocklist(address trainer) external onlyAdmin(msg.sender) {
        require(!_blocklist[trainer], "trainer is already in blocklist");
        _blocklist[trainer] = true;
        emit trainerAddedToBlocklist(trainer);
    }

    function removeFromBlocklist(
        address trainer
    ) external onlyAdmin(msg.sender) {
        require(_blocklist[trainer], "trainer is not blocked");
        _blocklist[trainer] = false;
        emit trainerRemovedFromBlocklist(trainer);
    }

    function addToAllowlist(
        address trainer,
        uint256 sessionId
    ) external onlyAdmin(msg.sender) {
        require(!_allowlist[trainer], "trainer is already in allowlist");
        _allowlist[trainer] = true;
        trainers[trainer].sessionId = sessionId;
        trainers[trainer].isActive = true;
        emit trainerAddedToAllowlist(trainer);
    }

    function removeFromAllowlist(
        address candidate
    ) external onlyAdmin(msg.sender) {
        require(_allowlist[candidate], "candidate is not allowed in allowlist");
        _allowlist[candidate] = false;
        emit trainerRemovedFromAllowlist(candidate);
    }

    function isAllowed(
        address trainer,
        uint256 sessionId
    ) external view returns (bool) {
        return
            _allowlist[trainer] &&
            trainers[trainer].sessionId == sessionId &&
            trainers[trainer].isActive;
    }

    function isBlocked(address trainer) external view returns (bool) {
        return _blocklist[trainer];
    }
    function getTrainerDetail(address trainer) external view returns(uint256, bool){
        return (trainers[trainer].sessionId, trainers[trainer].isActive);
    }
    function reset(address trainer) external onlyFebl(msg.sender){
        trainers[trainer].isActive = false;
        trainers[trainer].sessionId = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAdminControl {
    function isAdmin(address account) external view returns (bool);
}