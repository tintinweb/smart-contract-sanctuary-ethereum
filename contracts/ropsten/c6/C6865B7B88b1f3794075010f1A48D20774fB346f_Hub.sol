//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../interface/IHub.sol";

contract Hub is IHub {
    // Storage maps
    mapping(bytes32 => address) private contractStorage;
    mapping(address => bool) private existContractStorage;
    address private owner;
    bool private initialiazed = false;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyLatestGovernanceContract() {
        if (initialiazed) {
            string memory contractName = "governance";
            require(__getContract(contractName) == msg.sender, "Invalid caller address.");
        } else {
            require(owner == msg.sender, "Caller is not owner.");
        }
        _;
    }

    function completeContractInit() external {
        require(owner == msg.sender, "Must be called by owner.");
        owner = address(0);
        initialiazed = true;
    }

    function upgradeContract(string calldata _name, address _address) external override onlyLatestGovernanceContract {
        address oldAddress = _getContract(_name);
        require(oldAddress != address(0), "Invalid contract address.");
        require(_address != address(0), "Invalid address.");
        require(oldAddress != _address, "Address must be different.");

        _deleteExistContract(oldAddress);
        _setExistContract(_address);
        _setContract(_name, _address);
    }

    function addContract(string calldata _name, address _address) external override onlyLatestGovernanceContract {
        require(_getContract(_name) == address(0), "Contract name already exist.");
        require(_address != address(0), "Invalid contract address.");
        require(!_getExistContract(_address), "Invalid duplicate address.");

        _setContract(_name, _address);
        _setExistContract(_address);
    }

    function getContract(string calldata _name) external view override returns (address) {
        return contractStorage[keccak256(abi.encodePacked(_name))];
    }

    function _getContract(string calldata _name) private view returns (address) {
        return contractStorage[keccak256(abi.encodePacked(_name))];
    }

    // by duplicating the function we can save some gas on later invocations
    function __getContract(string memory _name) private view returns (address) {
        return contractStorage[keccak256(abi.encodePacked(_name))];
    }

    function _setContract(string calldata _name, address _address) private {
        contractStorage[keccak256(abi.encodePacked(_name))] = _address;
    }

    function _setExistContract(address _address) private {
        existContractStorage[_address] = true;
    }

    function _deleteExistContract(address _address) private {
        delete existContractStorage[_address];
    }

    function _getExistContract(address _address) private view returns (bool) {
        return existContractStorage[_address];
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IHub {
    function upgradeContract(string memory name, address addr) external;

    function addContract(string memory name, address addr) external;

    function getContract(string memory name) external view returns (address);
}