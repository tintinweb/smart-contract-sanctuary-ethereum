/**
 *Submitted for verification at Etherscan.io on 2022-02-07
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
            claimants.push(msg.sender);
            claimantMap[msg.sender] = true;
        } else if ((contractState == ContractState.CLAIMED || contractState == ContractState.CONTESTED) && block.timestamp < claimUntil) {
            require(!claimantMap[msg.sender], 'claim exists');

            if (contractState == ContractState.CLAIMED) {
                contractState = ContractState.CONTESTED;
            }

            claimants.push(msg.sender);
            claimantMap[msg.sender] = true;
        } else {
            revert('not claimable');
        }
    }

    function abort() requireContested requireClaimant since(claimUntil) before(challengeUntil) external {
        contractState = ContractState.ABORTED;
    }

    function withdraw() requireWithdrawable external {
        payable(msg.sender).transfer(address(this).balance);
        contractState = ContractState.DISBURSED;
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
            contractState == ContractState.CLAIMED && msg.sender == claimants[0] ||
            contractState == ContractState.CONTESTED && msg.sender == claimants[claimants.length - 1],
            'unauthorized'
        );
        _;
    }

    modifier requireClaimant {
        require(claimantMap[msg.sender], 'unauthorized');
        _;
    }
}