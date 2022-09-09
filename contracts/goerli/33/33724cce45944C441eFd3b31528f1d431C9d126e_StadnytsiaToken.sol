/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.16;

contract StadnytsiaToken {
    uint256 public totalSupply;
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint)) public allowance;

    address[] private owners;
    address[] private candidates;

    struct VoteForCandidate {
        address owner;
        address candidate;
        bool imAgree;
    }

    VoteForCandidate[] votesForCandidates;

    string public name = "StadnytsiaToken";
    string public symbol = "ST";
    uint8 public decimals = 18;

    uint256 private deployTimeStamp = block.timestamp;
    uint256 private timeToBurn = deployTimeStamp + 5 minutes;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        owners.push(msg.sender);
        totalSupply = 1000 ether;
        balances[msg.sender] = totalSupply;
    }

    modifier canBeBurned() {
        require(block.timestamp >= timeToBurn, "Token cannot be burned yet!");
        _;
    }

    modifier onlyOwner() {
        uint256 ArrayLength = owners.length;
        bool isOwner = false;

        for (uint i = 0; i <= ArrayLength; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "This user is not owner!");
        _;
    }

    modifier onlyCandidate() {
        uint256 ArrayLength = candidates.length;
        bool isCandidate = false;

        for (uint i = 0; i <= ArrayLength; i++) {
            if (candidates[i] == msg.sender) {
                isCandidate = true;
                break;
            }
        }
        require(isCandidate, "This user is not candidate!");
        _;
    }

    modifier onlyDefUser() {
        uint256 ArrayLength = candidates.length;
        bool isDefUser = true;
        for (uint i = 0; i <= ArrayLength; i++) {
            if (candidates[i] == msg.sender) {
                isDefUser = false;
                break;
            }
        }
        if (isDefUser) {
            ArrayLength = owners.length;
            for (uint i = 0; i <= ArrayLength; i++) {
                if (owners[i] == msg.sender) {
                    isDefUser = false;
                    break;
                }
            }
        }
        require(isDefUser, "This user is not DefUser!");
        _;
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function myBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getOneToken() external returns (bool) {
        totalSupply += 1 ether;
        balances[msg.sender] += 1 ether;

        emit Transfer(address(0), msg.sender, 1 ether);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) external canBeBurned {
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function createApplicationToBecameOwner() external onlyDefUser {
        candidates.push(msg.sender);
    }

    function getCandidatesList()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return candidates;
    }

    function getOwnersList()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return owners;
    }

    function getVotesList()
        external
        view
        onlyOwner
        returns (VoteForCandidate[] memory)
    {
        return votesForCandidates;
    }

    function vote(address _candidate, bool _imAgree) external onlyOwner {
        VoteForCandidate memory _vote;
        _vote.owner = msg.sender;
        _vote.candidate = _candidate;
        _vote.imAgree = _imAgree;

        votesForCandidates.push(_vote);
    }

    function checkForMyApplication()
        external
        onlyCandidate
        returns (string memory)
    {
        uint256 _ownersArrayLength = owners.length;

        uint256 _ownersAgreeToConfirm = _ownersArrayLength / 2;

        uint256 _ownersAgree = 0;
        uint256 _ownersDisagree = 0;

        uint256 _votesArrayLength = votesForCandidates.length;

        for (uint i = 0; i < _votesArrayLength; i++) {
            if (
                (votesForCandidates[i].candidate == msg.sender) &&
                (votesForCandidates[i].imAgree)
            ) {
                _ownersAgree += 1;
            } else if (
                (votesForCandidates[i].candidate == msg.sender) &&
                (votesForCandidates[i].imAgree == false)
            ) {
                _ownersDisagree += 1;
            }
        }

        if (_ownersAgree > _ownersAgreeToConfirm) {
            owners.push(msg.sender);

            uint256 candidatesArrayLength = candidates.length;

            for (uint256 i = 0; i < candidatesArrayLength; i++) {
                if (candidates[i] == msg.sender) {
                    delete candidates[i];
                }
            }

            for (uint256 i = 0; i < _votesArrayLength; i++) {
                if (votesForCandidates[i].candidate == msg.sender) {
                    delete votesForCandidates[i];
                }
            }

            return "You became an owner!";
        } else if ((_ownersAgree + _ownersDisagree) == _ownersArrayLength) {
            for (uint256 i = 0; i < _votesArrayLength; i++) {
                if (votesForCandidates[i].candidate == msg.sender) {
                    delete votesForCandidates[i];
                }
            }

            return "You are not owner. Your Application was deleted";
        } else {
            return "Vote in process";
        }
    }
}