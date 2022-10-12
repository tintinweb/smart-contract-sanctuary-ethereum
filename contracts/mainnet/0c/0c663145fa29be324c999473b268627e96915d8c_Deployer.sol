//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Ownable {

    error Unauthorized();

    event OwnerSet(address indexed newOwner_);
    event PendingOwnerSet(address indexed pendingOwner_);

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    function setPendingOwner(address pendingOwner_) external onlyOwner {
        _setPendingOwner(pendingOwner_);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Unauthorized();

        _setPendingOwner(address(0));
        _setOwner(msg.sender);
    }

    function _setOwner(address owner_) internal {
        emit OwnerSet(owner = owner_);
    }

    function _setPendingOwner(address pendingOwner_) internal {
        emit PendingOwnerSet(pendingOwner = pendingOwner_);
    }

}

contract Deployer is Ownable {

    error InitializationFailed();

    event ContractDeployed(address indexed contractAddress);

    constructor() {
        _setOwner(msg.sender);
    }

    function deployContract(bytes memory code_, bytes calldata initializationData_, uint256 salt_) external payable onlyOwner returns (address contractAddress_) {
        assembly {
            contractAddress_ := create2(0, add(code_, 32), mload(code_), salt_)
            if iszero(extcodesize(contractAddress_)) { revert(0, 0) }
        }

        ( bool success, ) = contractAddress_.call(initializationData_);
        if (!success) revert InitializationFailed();

        emit ContractDeployed(contractAddress_);
    }

}