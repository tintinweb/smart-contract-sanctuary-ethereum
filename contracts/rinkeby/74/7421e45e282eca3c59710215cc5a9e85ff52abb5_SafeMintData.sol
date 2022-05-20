pragma solidity ^0.8.11;

contract SafeMintData {
    mapping (bytes32 => bool) private _projectName;
    mapping (address => bool) public user;

    function saveProjectName(string calldata name) public {
        require(!user[msg.sender], "user aleardy saved");
        require(!projectName(name), "name aleardy used");
        _projectName[keccak256(abi.encodePacked(name))] = true;
    }

    function projectName(string calldata name) public view returns(bool){
        return _projectName[keccak256(abi.encodePacked(name))];
    }
}