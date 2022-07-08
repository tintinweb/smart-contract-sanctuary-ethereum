/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Public CREATE2 deployer by pk910.eth

// Deployer Wallet: 0x0239AA8334702B6b325ec1883152a29a205c210e
// Compiler: 0.8.2+commit.661d1103
// Optimization: yes (200)
// ContractFactory deployed to: 0xd58660caD6E1eeeaFf48647c10Fd49428E6277D9

contract ContractFactory {
    event Deployed(address addr, uint256 salt);
    address private _owner;
    bool private _private = true;

    constructor(address owner) {
        _owner = owner;
    }

    function _selfdestruct(address addr) public {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        selfdestruct(payable(addr));
    }

    function _setprivate(bool priv) public {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _private = priv;
    }

    function _setowner(address owner) public {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _owner = owner;
    }

    function deploy(bytes memory bytecode, uint _salt) public {
        require(!_private || msg.sender == _owner, "Deployments disabled");

        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}