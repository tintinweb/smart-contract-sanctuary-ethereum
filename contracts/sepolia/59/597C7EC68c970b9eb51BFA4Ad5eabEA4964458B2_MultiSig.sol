/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract MultiSig {
    // the total number of signers
    uint private constant SIGNERS_COUNT = 3;
    // the number of signers required to approve a withdrawal
    uint private constant APPROVALS_COUNT = SIGNERS_COUNT / 2 + 1;

    // the array of addresses who are allowed to sign withdrawals
    address payable[SIGNERS_COUNT] private signers;
    // the array of hashes of (amount, payee) approved by corresponding signers
    bytes32[SIGNERS_COUNT] private approvals;

    // Merely initializes the contract by populating signers collection with constructor's argument.
    constructor(address payable[SIGNERS_COUNT] memory _signers) {
        require(
            _signers.length == SIGNERS_COUNT,
            "The contract has to be constructed with exactly 3 signers"
        );

        signers = _signers;
    }

    // The contract accepts incoming Ethers and does not ask any questions :)
    receive() external payable {}

    // Records an approval (verifying it is coming from one of the signers) and immediately
    // transfers funds to the payee if 2 approvals exist.
    function withdraw(address _token, uint _amount, address payable _payee) external {
        uint256 index = getSignerIndex();

        require(
            index != type(uint256).max,
            "withdraw() can only be called by one of signers"
        );

        bytes32 hash = keccak256(abi.encodePacked(_token, _amount, _payee));
        approvals[index] = hash;

        if (!checkApprovals(hash)) {
            return;
        }

        resetApprovals();

        if (_token == address(0)) {
            _payee.transfer(_amount);
        } else {
            IERC20(_token).transfer(_payee, _amount);
        }
    }

    // Clears all the approvals as if noone allowed anything.
    function resetApprovals() private {
        for(uint256 i = 0; i < SIGNERS_COUNT; i++) {
            approvals[i] = bytes32(0);
        }
    }

    // Checks that a specific hash (representing a tuple of (amount, payee)) has been
    // recorded by APPROVALS_COUNT signers.
    function checkApprovals(bytes32 hash) private view returns (bool) {
        uint256 matchingApprovals = 0;

        for (uint256 i = 0; i < SIGNERS_COUNT; i++) {
            if (hash == approvals[i]) {
                matchingApprovals++;
            }
        }

        return matchingApprovals >= APPROVALS_COUNT;
    }

    // Finds the index of the transaction's sender in signers array, returning a uint256(-1) if not found.
    function getSignerIndex() private view returns (uint256) {
        for (uint256 i = 0; i < SIGNERS_COUNT; i++) {
            if (signers[i] == msg.sender) {
                return i;
            }
        }

        return type(uint256).max;
    }
}