pragma solidity 0.4.24;

import {Ownable} from "./Ownable.sol";
import {SafeMath, SafeMath16, SafeMath8} from "./Utils.sol";

contract Polls is Ownable {
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;

    event UpgradePollStarted(address proposal);

    event DocumentPollStarted(bytes32 proposal);

    event UpgradeMajority(address proposal);

    event DocumentMajority(bytes32 proposal);

    struct Poll {
        uint256 start;
        bool[256] voted;
        uint16 yesVotes;
        uint16 noVotes;
        uint256 duration;
        uint256 cooldown;
    }

    uint256 public pollDuration;
    uint256 public pollCooldown;
    uint16 public totalVoters;
    address[] public upgradeProposals;
    mapping(address => Poll) public upgradePolls;
    mapping(address => bool) public upgradeHasAchievedMajority;
    bytes32[] public documentProposals;
    mapping(bytes32 => Poll) public documentPolls;
    mapping(bytes32 => bool) public documentHasAchievedMajority;
    bytes32[] public documentMajorities;

    constructor(uint256 _pollDuration, uint256 _pollCooldown) public {
        reconfigure(_pollDuration, _pollCooldown);
    }

    function reconfigure(uint256 _pollDuration, uint256 _pollCooldown) public onlyOwner {
        require((5 days <= _pollDuration) && (_pollDuration <= 90 days) && (5 days <= _pollCooldown) && (_pollCooldown <= 90 days));
        pollDuration = _pollDuration;
        pollCooldown = _pollCooldown;
    }

    function incrementTotalVoters() external onlyOwner {
        require(totalVoters < 256);
        totalVoters = totalVoters.add(1);
    }

    function getUpgradeProposals() external view returns (address[] proposals) {
        return upgradeProposals;
    }

    function getUpgradeProposalCount() external view returns (uint256 count) {
        return upgradeProposals.length;
    }

    function getDocumentProposals() external view returns (bytes32[] proposals) {
        return documentProposals;
    }

    function getDocumentProposalCount() external view returns (uint256 count) {
        return documentProposals.length;
    }

    function getDocumentMajorities() external view returns (bytes32[] majorities) {
        return documentMajorities;
    }

    function hasVotedOnUpgradePoll(uint8 _galaxy, address _proposal) external view returns (bool result) {
        return upgradePolls[_proposal].voted[_galaxy];
    }

    function hasVotedOnDocumentPoll(uint8 _galaxy, bytes32 _proposal) external view returns (bool result) {
        return documentPolls[_proposal].voted[_galaxy];
    }

    function startUpgradePoll(address _proposal) external onlyOwner {
        require(!upgradeHasAchievedMajority[_proposal]);

        Poll storage poll = upgradePolls[_proposal];

        if (0 == poll.start) {
            upgradeProposals.push(_proposal);
        }

        startPoll(poll);
        emit UpgradePollStarted(_proposal);
    }

    function startDocumentPoll(bytes32 _proposal) external onlyOwner {
        require(!documentHasAchievedMajority[_proposal]);

        Poll storage poll = documentPolls[_proposal];
        if (0 == poll.start) {
            documentProposals.push(_proposal);
        }

        startPoll(poll);
        emit DocumentPollStarted(_proposal);
    }

    function startPoll(Poll storage _poll) internal {
        require(block.timestamp > (_poll.start.add(_poll.duration.add(_poll.cooldown))));
        _poll.start = block.timestamp;
        delete _poll.voted;
        _poll.yesVotes = 0;
        _poll.noVotes = 0;
        _poll.duration = pollDuration;
        _poll.cooldown = pollCooldown;
    }

    function castUpgradeVote(
        uint8 _as,
        address _proposal,
        bool _vote
    ) external onlyOwner returns (bool majority) {
        Poll storage poll = upgradePolls[_proposal];
        processVote(poll, _as, _vote);
        return updateUpgradePoll(_proposal);
    }

    function castDocumentVote(
        uint8 _as,
        bytes32 _proposal,
        bool _vote
    ) external onlyOwner returns (bool majority) {
        Poll storage poll = documentPolls[_proposal];
        processVote(poll, _as, _vote);
        return updateDocumentPoll(_proposal);
    }

    function processVote(
        Poll storage _poll,
        uint8 _as,
        bool _vote
    ) internal {
        assert(block.timestamp >= _poll.start);

        require( //  may only vote once
            //
            !_poll.voted[_as] &&
                //
                //  may only vote when the poll is open
                //
                (block.timestamp < _poll.start.add(_poll.duration))
        );
        _poll.voted[_as] = true;
        if (_vote) {
            _poll.yesVotes = _poll.yesVotes.add(1);
        } else {
            _poll.noVotes = _poll.noVotes.add(1);
        }
    }

    function updateUpgradePoll(address _proposal) public onlyOwner returns (bool majority) {
        require(!upgradeHasAchievedMajority[_proposal]);
        Poll storage poll = upgradePolls[_proposal];
        majority = checkPollMajority(poll);
        if (majority) {
            upgradeHasAchievedMajority[_proposal] = true;
            emit UpgradeMajority(_proposal);
        }
        return majority;
    }

    function updateDocumentPoll(bytes32 _proposal) public returns (bool majority) {
        require(!documentHasAchievedMajority[_proposal]);

        Poll storage poll = documentPolls[_proposal];
        majority = checkPollMajority(poll);
        if (majority) {
            documentHasAchievedMajority[_proposal] = true;
            documentMajorities.push(_proposal);
            emit DocumentMajority(_proposal);
        }
        return majority;
    }

    function checkPollMajority(Poll _poll) internal view returns (bool majority) {
        return ((_poll.yesVotes >= (totalVoters / 4)) &&
            (_poll.yesVotes > _poll.noVotes) &&
            ((block.timestamp > _poll.start.add(_poll.duration)) || (_poll.yesVotes > totalVoters.sub(_poll.yesVotes))));
    }
}

pragma solidity 0.4.24;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

pragma solidity 0.4.24;

library SafeMath8 {
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a / b;
        return c;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }
}

library SafeMath16 {
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a / b;
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

library AddressUtils {
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

interface ERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

contract SupportsInterfaceWithLookup is ERC165 {
    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        _registerInterface(InterfaceId_ERC165);
    }

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }

    function _registerInterface(bytes4 _interfaceId) internal {
        require(_interfaceId != 0xffffffff);
        supportedInterfaces[_interfaceId] = true;
    }
}

interface ITreasuryProxy {
    function upgradeTo(address _impl) external returns (bool);

    function freeze() external returns (bool);
}

contract ERC721Receiver {
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    ) public returns (bytes4);
}