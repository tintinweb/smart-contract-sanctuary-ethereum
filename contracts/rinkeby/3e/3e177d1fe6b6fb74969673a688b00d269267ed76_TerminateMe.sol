/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
    // Contract used for Red Alert Labs Workshop
    // Smart Contract Hacking
    // Lab Author: Paul Gedeon

    pragma solidity 0.8.16;

    contract TerminateMe{
        address public owner;

        modifier onlyowner {
            require(msg.sender==owner);
            _;
        }

        function Notprotected()
        public
        {
            owner = msg.sender;
        }
        // kills the contract sending everything to `_to`.
        function terminate(address payable _to)
        external
        {
            selfdestruct(_to);
        }

        // This function should be protected
        function changeOwner(address _newOwner)
        public
        {
            owner = _newOwner;
        }

        function changeOwner_fixed(address _newOwner)
        public
        onlyowner
        {
            owner = _newOwner;
        }

        function checkOwner() public pure returns (address _owner) {}

        event Received(address, uint);
        receive() external payable {
            emit Received(msg.sender, msg.value);
            }

        fallback() external payable {}
    }