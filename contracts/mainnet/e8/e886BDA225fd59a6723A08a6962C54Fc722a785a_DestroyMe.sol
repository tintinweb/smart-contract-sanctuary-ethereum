// SPDX-License-Identifier: GPL-3.0
    // Contract used for the Solidity Hacking Workshop for the Blockchain Security Summit
    // Sponsored by SANS and Halborn
    // Lab Author: Steven Walbroehl - Co-Founder of Halborn

    pragma solidity 0.8.16;

    contract DestroyMe{
        address public owner;

        modifier onlyowner {
            require(msg.sender==owner);
            _;
        }

        function Unprotected()
        public
        {
            owner = msg.sender;
        }
        // kills the contract sending everything to `_to`.
        function destroy(address payable _to)
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