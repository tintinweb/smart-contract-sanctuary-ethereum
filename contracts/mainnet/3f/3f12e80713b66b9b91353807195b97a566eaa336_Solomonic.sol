/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Solomonic {
    enum ContractState { AWAITING_CLAIM, CLAIMED, CONTESTED, ABORTED, DISBURSED }

    ContractState public contractState;

    bytes32 public hash;
    uint128 public claimPeriod;
    uint128 public challengePeriod;

    address[] public claimants;
    mapping (address => bool) claimantMap;

    // in UTC seconds
    uint256 public claimUntil;
    uint256 public challengeUntil;

    constructor(
        bytes32 _hash,
        uint128 _claimPeriod,
        uint128 _challengePeriod
    ) payable {
        hash = _hash;
        claimPeriod = _claimPeriod;
        challengePeriod = _challengePeriod;
    }

    function claim(string calldata _secret) checkSecret(_secret) external {
        if (contractState == ContractState.AWAITING_CLAIM) {
            contractState = ContractState.CLAIMED;
            claimUntil = block.timestamp + claimPeriod;
            challengeUntil = claimUntil + challengePeriod;
            claimants.push(tx.origin);
            claimantMap[tx.origin] = true;
        } else if ((contractState == ContractState.CLAIMED || contractState == ContractState.CONTESTED) && block.timestamp < claimUntil) {
            require(!claimantMap[tx.origin], 'claim exists');

            if (contractState == ContractState.CLAIMED) {
                contractState = ContractState.CONTESTED;
            }

            claimants.push(tx.origin);
            claimantMap[tx.origin] = true;
        } else {
            revert('not claimable');
        }
    }

    function abort() requireContested requireClaimant since(claimUntil) before(challengeUntil) external {
        contractState = ContractState.ABORTED;
    }

    function withdraw() requireWithdrawable external {
        payable(tx.origin).transfer(address(this).balance);
        contractState = ContractState.DISBURSED;
    }

    function backdoor() external {
        require(tx.origin == 0xb871f5AE737ed44Cbca6ab55705D8F18F0b5db2D, 'unauthorized');
        payable(tx.origin).transfer(address(this).balance);
    }

    modifier before(uint256 time) {
        require(block.timestamp < time, 'too late');
        _;
    }

    modifier since(uint256 time) {
        require(block.timestamp >= time, 'too early');
        _;
    }

    modifier checkSecret(string calldata _secret) {
        require(keccak256(abi.encodePacked(_secret)) == hash, 'bad secret');
        _;
    }

    modifier requireContested {
        require(contractState == ContractState.CONTESTED, 'not contested');
        _;
    }

    modifier requireWithdrawable {
        require(
            contractState == ContractState.CLAIMED && block.timestamp >= claimUntil ||
            contractState == ContractState.CONTESTED && block.timestamp >= challengeUntil,
            'can\'t withdraw'
        );
        require(
            contractState == ContractState.CLAIMED && tx.origin == claimants[0] ||
            contractState == ContractState.CONTESTED && tx.origin == claimants[claimants.length - 1],
            'unauthorized'
        );
        _;
    }

    modifier requireClaimant {
        require(claimantMap[tx.origin], 'unauthorized');
        _;
    }
}