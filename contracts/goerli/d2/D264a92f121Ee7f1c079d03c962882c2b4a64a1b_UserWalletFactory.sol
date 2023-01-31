// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract UserWalletFactory {
    error OutOfAmount();

    event NewWalletAddress(address[] indexed addr);

    address public userWalletImplementation;

    constructor(address _userWalletImplementation) {
        userWalletImplementation = _userWalletImplementation;
    }

    function setImplementation(address _userWalletImplementation) external {
        userWalletImplementation = _userWalletImplementation;
    }

    function createUserWallet(uint256 amount) external returns (address[] memory) {
        if (amount > 50) {
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