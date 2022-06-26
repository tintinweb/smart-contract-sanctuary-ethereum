//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";

contract DAO {

    struct VotingProcess {
        bool finished;
        uint256 disagreeVotes;
        uint256 agreeVotes;
        uint256 finishTime;
        address receiver;
        bytes signature;

        mapping(address => bool) voted;  // address => is voted
        mapping(address => uint256) allocated;  // address => amount
        mapping(address => mapping(address => uint256)) delegated;  // from => to => amount
    }
    
    address public owner;
    uint256 public minimumQuorum;
    uint256 public debatingDuration;
    mapping(address => bool) public chairPersons;
    VotingProcess[] public vp;
    IStaking public staking;

    constructor(
        uint256 _minimumQuorum,
        uint256 _debatingDuration
    ) {
        owner = msg.sender;
        minimumQuorum = _minimumQuorum;
        debatingDuration = _debatingDuration;
        changePersonRights(msg.sender);
    }

    modifier notThis() {
        require(msg.sender != address(this), "Cant run it from this address");
        _;
    }

    modifier canChange() {
        require(msg.sender == owner || msg.sender == address(this), "Have no rights");
        _;
    }

    function setStaking(address _staking) external {
        require(msg.sender == owner, "Only owner");
        staking = IStaking(_staking);
    }

    function addProposal(address _receiver, bytes calldata _signature) external notThis {
        require(chairPersons[msg.sender], "You are not chairperson");
        require(_receiver != address(0), "Receiver address cant be null");

        bytes4 selector;
        assembly {
            selector := calldataload(_signature.offset)
        }
        require(selector != bytes4(0), "Incorrect function selector");

        VotingProcess storage _vp = vp.push();
        _vp.finishTime = block.timestamp + debatingDuration;
        _vp.receiver = _receiver;
        _vp.signature = _signature;
    }

    function vote(uint256 _index, bool _agreement) external notThis {
        require(_index < vp.length, "Cant find voting");
        require(vp[_index].finishTime > block.timestamp, "Time is over");
        
        address _sender = msg.sender;
        uint256 totalAmount = vp[_index].allocated[_sender] + staking.staked(_sender);
        require(totalAmount > 0, "Have no tokens to vote");
        require(!vp[_index].voted[_sender], "Cant vote again");

        staking.updateFreezing(_sender, vp[_index].finishTime);
        vp[_index].voted[_sender] = true;

        if (_agreement) vp[_index].agreeVotes += totalAmount;
        else vp[_index].disagreeVotes += totalAmount;
    }   

    function finish(uint256 _index) external notThis {
        require(vp[_index].finishTime <= block.timestamp, "Cant finish voting yet");
        require(!vp[_index].finished, "Already finished");

        vp[_index].finished = true;
        if ((vp[_index].disagreeVotes + vp[_index].agreeVotes >= minimumQuorum) && (vp[_index].disagreeVotes < vp[_index].agreeVotes)) {

            (bool success, bytes memory data) = vp[_index].receiver.call{value: 0}(vp[_index].signature);
            if (success) return;
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function delegate(uint256 _index, address _to) external notThis {
        require(vp[_index].finishTime > block.timestamp, "Time is over");

        address _sender = msg.sender;
        require(_to != _sender, "Cant delegate to yourself");
        require(staking.staked(_sender) > 0, "Nothing to delegate");
        require(!vp[_index].voted[_sender], "You already voted");
        require(!vp[_index].voted[_to], "This person already voted");

        staking.updateFreezing(_sender, vp[_index].finishTime);

        uint totalAmount = staking.staked(_sender) + vp[_index].allocated[_sender];
        vp[_index].voted[_sender] = true;
        vp[_index].allocated[_to] += totalAmount;
        vp[_index].delegated[_sender][_to] = totalAmount;
    }   

    function getBack(uint256 _index, address _from) external notThis {
        require(vp[_index].finishTime > block.timestamp, "Time is over");
        require(!vp[_index].voted[_from], "This person already voted");

        uint totalAmount = vp[_index].delegated[msg.sender][_from];
        require(totalAmount > 0, "Nothing to getting back");
        
        vp[_index].allocated[_from] -= totalAmount;
        vp[_index].delegated[msg.sender][_from] = 0;
        vp[_index].voted[msg.sender] = false;
    }

    // selector: 0xd2cd96bd
    function changeQuorum(uint256 _minimumQuorum) external canChange { 
        minimumQuorum = _minimumQuorum;
    }

    // selector: 0xb594f086
    function changeDuration(uint256 _duration) external canChange { 
        debatingDuration = _duration;
    }

    // selector: 0x43a0a31f
    function changePersonRights(address _user) public canChange { 
        chairPersons[_user] = !chairPersons[_user];
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function updateFreezing(address _staker, uint256 _unfreeze) external;
    function staked(address _from) external view returns (uint256);
}