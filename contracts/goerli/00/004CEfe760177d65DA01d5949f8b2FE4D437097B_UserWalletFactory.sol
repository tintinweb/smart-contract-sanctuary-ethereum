// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract UserWalletFactory {
    error CallerIsNotSamoi(); 
    error OutOfAmount();

    event NewWalletAddress(address[]);

    address public userWalletImplementation;
    address public owner;

    constructor(address _userWalletImplementation) {
        userWalletImplementation = _userWalletImplementation;
        owner = msg.sender;
    }

    function setImplementation(address _userWalletImplementation) external {
        if (msg.sender != owner) {
            revert CallerIsNotSamoi();
        }
        userWalletImplementation = _userWalletImplementation;
    }

    function createUserWallet(uint amount) external returns (address[] memory) {
        if (amount > 20) {
            revert OutOfAmount();
        }

        address[] memory addr = new address[](amount);
        for (uint i; i < amount;) {
            addr[i] = _createUserWallet(userWalletImplementation);
            unchecked {
                ++i;
            }
        }

        emit NewWalletAddress(addr);
        return addr;
    }

    function _createUserWallet(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}