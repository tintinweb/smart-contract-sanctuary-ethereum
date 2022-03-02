/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract UserWallet {
    function kill() public {
        selfdestruct(payable(address(0)));
    }
}

contract Factory {
    function makeWallet(uint256 salt) public {
        bytes memory bytecode = type(UserWallet).creationCode;
        assembly {
            let codeSize:= mload(bytecode)
            let walletAddr:= create2(
                0,
                add(bytecode,32),
                codeSize,
                salt
            )
        }
    }

    function makeWallet(bytes32 _salt) public {
        new UserWallet{salt: _salt}();
    }

    function getUserAddress(uint256 salt) external view returns(address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(type(UserWallet).creationCode)) // init code hash
            )))));
    }
    
    function getUserAddress(bytes32 salt) external view returns(address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(type(UserWallet).creationCode)) // init code hash
            )))));
    }
}