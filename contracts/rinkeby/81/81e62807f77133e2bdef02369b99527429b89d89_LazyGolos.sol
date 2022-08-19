//SPDX-License-Identifier: MIT

import "./ERC20.sol";

import "./VotingMachine.sol";

pragma solidity ^0.8.0;

contract Golos is ERC20 {
    VotingMachine _votingMachine;

    address public owner;

    struct VotingBalance {
        bool vote;
        uint balance;
    }

    mapping (address => mapping (uint32 => VotingBalance)) _votings;

    modifier onlyOwner() {
        require(msg.sender == owner, "illegal address");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        owner = msg.sender;
    }

    function transferOwnership(VotingMachine vm) external onlyOwner {
        owner = address(vm);
        _votingMachine = vm;
    }

    function _balanceOfVoting(uint32 id, address account) internal view returns (uint256) {
        VotingBalance memory accountBalance = _votings[account][id];
        return accountBalance.vote ? accountBalance.balance : balanceOf(account);
    }

    function balanceOfVoting(uint32 id, address account) external view returns (uint256) {
        return _votingMachine.findIndex(id) == 0 ? 0 : _balanceOfVoting(id, account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        uint32[] memory actual = _votingMachine.actualVotings();
        for(uint i = 1; i < actual.length; ++i) {
            uint32 id = actual[i];
            require(_balanceOfVoting(id, from) >= amount || from == address(0), "ERC20: transfer amount exceeds votings balance");
            if (_votings[from][id].vote) {
                unchecked {
                    _votings[from][id].balance -= amount;
                }
            }
            if (_votings[to][id].vote) {
                _votings[to][id].balance += amount;
            }
        }
    }

    function burnVotes(uint32 id, address from) external onlyOwner returns(uint votes) {
        require(!_votings[from][id].vote, "already voted!");
        votes = balanceOf(from);
        require(votes > 0, "no vote!");
        _votings[from][id].vote = true;
    }
}


contract LazyGolos is Golos {
    uint constant ACCURACY =  1000000000000000000;

    struct Claimer {
        uint lazySupply;
        uint startTokens;
        uint lastClaim;
        uint step;
    }

    mapping (address => Claimer) claimers;

    function _newMember(uint max, uint start, uint time) internal returns (Claimer memory) {
        return Claimer({
            lazySupply: max,
            startTokens: start,
            lastClaim: block.timestamp,
            step: (max - start) * ACCURACY / time
        });
    }

    constructor(address member_1, address member_2) Golos("GolosDAO", "GOLD") {
        claimers[member_1] = _newMember(50000, 10000, 1 weeks);
        claimers[member_2] = _newMember(50000, 20000, 2 weeks);
    }
    // constructor(address member_1, address member_2, address member_3) Golos("GolosDAO", "GOLD") {
    //     claimers[member_1] = _newMember(50000, 10000, 1 weeks);
    //     claimers[member_2] = _newMember(50000, 20000, 2 weeks);
    //     claimers[member_3] = _newMember(50000, 10000, 1 weeks);
    // }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function claim() external {
        Claimer memory claimer = claimers[msg.sender];

        require(claimer.step > 0, "illegal address");
        require(claimer.lazySupply > 0, "no more tokens 4 u");

        uint currentSupply;
        if (claimer.startTokens > 0) {
            currentSupply += claimer.startTokens;
            claimer.startTokens = 0;
        }

        currentSupply += claimer.step * (block.timestamp - claimer.lastClaim) / ACCURACY;
        if (currentSupply > claimer.lazySupply) {
            currentSupply = claimer.lazySupply;
        }
        claimer.lazySupply -= currentSupply;
        claimer.lastClaim = block.timestamp;
        claimers[msg.sender] = claimer;

        _mint(msg.sender, currentSupply);
    }
}

// "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"

// "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"
// "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"
// "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"