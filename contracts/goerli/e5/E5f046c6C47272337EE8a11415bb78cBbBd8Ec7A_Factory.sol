pragma solidity ^0.8.17;

import "./multisigwallet.sol";

contract Factory {
    mapping(address => address payable[]) safes;

    function createNewSafe(string memory _safeName, address[] memory _owners)
        public
        returns (address payable)
    {
        MultiSigWallet safe = new MultiSigWallet(_safeName, _owners);
        for (uint256 i = 0; i < _owners.length; ++i) {
            safes[_owners[i]].push(payable(address(safe)));
        }
        return payable(address(safe));
    }

    // Explicitly make a getter method so users can only access the safes they
    // own.
    function getSafes() public view returns (address payable[] memory) {
        return safes[msg.sender];
    }

    function voteTransaction(
        address payable safeAddr,
        uint256 id,
        bool approve
    ) public {
        MultiSigWallet(safeAddr).voteTransaction(msg.sender, id, approve);
    }

    function addTransaction(
        address payable safeAddr,
        address payable destination,
        uint256 amount,
        uint256 duration,
        uint256 minVotes
    ) public {
        MultiSigWallet(safeAddr).addTransaction(
            msg.sender,
            destination,
            amount,
            duration,
            minVotes
        );
    }

    function executeTransaction(address payable safeAddr, uint256 id) public {
        MultiSigWallet(safeAddr).executeTransaction(msg.sender, id);
    }

    // Might as well take money if its sent
    receive() external payable {}

    fallback() external payable {}
}