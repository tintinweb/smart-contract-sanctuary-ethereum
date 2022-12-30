pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

contract StakingFactory {
    address public oneTimeStakingImplAddress;
    address public standardStakingImplAddress;
    address[] public oneTimeStakings;
    address[] public standardStakings;
    mapping (address => bool) admins;
    mapping (address => address[]) public tokenToStandardStakingContracts;
    mapping (address => address[]) public tokenToOneTimeStakingContracts;
    
    event NewStaking(address contractAddress, string indexed _type);

    constructor() {
        admins[msg.sender] = true;
    }


    modifier onlyAdmin {
        require(admins[msg.sender], "only admin allowed.");
        _;
    }

    function isAdmin(address addr) public view returns (bool){
        return admins[addr];
    }

    function setImplAddresses(address _oneTimeImpl, address _standardImpl) public onlyAdmin returns (address, address) {
        require(_oneTimeImpl != address(0) || _standardImpl != address(0), "invalid implementation addresses.");
        if (_oneTimeImpl != address(0)) {
            oneTimeStakingImplAddress = _oneTimeImpl;
        }
        if (_standardImpl != address(0)) {
            standardStakingImplAddress = _standardImpl;
        }
        return (oneTimeStakingImplAddress, standardStakingImplAddress);
    }


    function createStandardStaking(bytes memory data, address tokenAddress) public onlyAdmin returns (address contractAddress, bytes memory returnData) {
        // cloning standard staking contract
        returnData = _call(contractAddress = _clone(standardStakingImplAddress), data);
        standardStakings.push(contractAddress);
        tokenToStandardStakingContracts[tokenAddress].push(contractAddress);
        emit NewStaking(contractAddress,  "standard");
    }


    function createOneTimeStaking(bytes memory data, address tokenAddress) public onlyAdmin returns (address contractAddress, bytes memory returnData) {
        // cloning one-time staking contract
        returnData = _call(contractAddress = _clone(oneTimeStakingImplAddress), data);
        oneTimeStakings.push(contractAddress);
        tokenToOneTimeStakingContracts[tokenAddress].push(contractAddress);
        emit NewStaking(contractAddress, "one-time");
    }

    function _clone(address implementation) private returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }


    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        /// @solidity memory-safe-assembly
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }

    function toggleAdmin(address newAdmin) onlyAdmin public {
        require(newAdmin != msg.sender, "admin cannot toggle himself.");
        admins[newAdmin] = !admins[newAdmin];
    }
}