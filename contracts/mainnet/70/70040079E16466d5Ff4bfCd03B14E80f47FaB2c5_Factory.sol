// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "ClonesUpgradeable.sol";
import "Buffer.sol";

contract Factory {
    address public immutable implementation;
    uint256 public withdrawFee; // global variable for withdraw fee
    address public owner;

    error Unauthorized(address caller);

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

    function _checkOwner() internal view virtual {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    event ContractDeployed(
        address indexed owner,
        address indexed group,
        string title
    );

    constructor(uint256 _withdrawFee) {
        implementation = address(new Buffer());
        withdrawFee = _withdrawFee;
        owner = msg.sender;
    }

    function genesis(
        string memory title,
        address _owner,
        address _marketWallet,
        uint256 _montageShare
    ) external returns (address) {
        address payable clone = payable(
            ClonesUpgradeable.clone(implementation)
        );
        Buffer buffer = Buffer(clone);
        buffer.initialize(
            _owner,
            _marketWallet,
            _montageShare
            
        );
        emit ContractDeployed(msg.sender, clone, title);
        return clone;
    }

    function setWithdrawFee(uint256 _newWithdrawFee) external onlyOwner {
        withdrawFee = _newWithdrawFee;
    }

    function getWithdrawFee() external view returns (uint256) {
        return withdrawFee;
    }
}