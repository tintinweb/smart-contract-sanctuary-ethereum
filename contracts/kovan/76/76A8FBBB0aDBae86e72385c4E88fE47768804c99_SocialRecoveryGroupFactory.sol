/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity 0.8.4;

interface IGuardianHolder {
    struct Guardian {
        address guardianAddress;
        string publicKey;
    }
}

interface ISocialRecoveryGroup is IGuardianHolder {
    struct Vote {
        address voterAddress;
        bytes32 voteHash;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function owner() external view returns (address);
    function getGuardians() external view returns (Guardian[] calldata);
    function getOwnerPublicKey() external view returns (string calldata);
    function getQuorum() external view returns (uint8);
    function getModulo() external view returns (uint256);
    function getName() external view returns (string calldata);
    function addGuardian(Guardian calldata) external;
    function nonceUsed(uint256) external view returns (bool);
    function getOwnerHistory() external view returns (address[] calldata);
    function changeOwner(
        string calldata newOwnerPK,
        uint256 nonce,
        Vote[] calldata votes
    ) external;

    event VoteSuccess(address newOwner, string newPublicKey);
    event VoteFail(address newOwner, string newPublicKey);
}

interface ISocialRecoveryGroupFactory is IGuardianHolder {
    function getGroup(address owner, string calldata groupName) external returns(address);
    function createGroup(
        address owner,
        string calldata groupName,
        string calldata ownerPK,
        uint8 quorum,
        Guardian[] calldata initGuardians
    ) external returns(address);

    event GroupCreated(address owner, address group);
}

interface ISocialRecoveryGroupOwnerChangeCallback {
    function ownerChangeCallback(
        address oldOwner,
        string calldata groupName,
        address newOwner
    ) external returns (bool);
}

contract SocialRecoveryGroup is ISocialRecoveryGroup {
    uint256 private modulo = 688846502588399;
    string private ownerPK;
    uint8 private quorum;
    Guardian[] private guardians;
    mapping(address => bool) private guardiansMap;

    mapping(uint256 => bool) private usedNonces;
    mapping(uint256 => mapping(address => bool)) private voteHistory;

    address private _owner;
    address[] private ownerHistory;
    address public factory;
    string private name;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(
        address groupOwner,
        string memory _name,
        string memory _ownerPK,
        uint8 _quorum,
        Guardian[] memory initGuardians,
        ISocialRecoveryGroupOwnerChangeCallback _factory
    ) {
        _owner = groupOwner;
        name = _name;
        ownerPK = _ownerPK;
        quorum = _quorum;
        for (uint i = 0; i < initGuardians.length; i++) {
            guardians.push(initGuardians[i]);
            guardiansMap[initGuardians[i].guardianAddress] = true;
        }
        ownerHistory.push(groupOwner);
        factory = address(_factory);
    }

    function _verifySigner(
        address voter,
        bytes32 targetHash,
        uint8 v, bytes32 r, bytes32 s
    ) private pure returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", targetHash));
        return voter == ecrecover(digest, v, r, s);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    function getName() external view override returns (string memory) {
        return name;
    }

    function getOwnerPublicKey() external view override returns (string memory) {
        return ownerPK;
    }

    function getGuardians() external view override returns (Guardian[] memory) {
        return guardians;
    }

    function getQuorum() external view override returns (uint8) {
        return quorum;
    }

    function getModulo() external view override returns (uint256) {
        return modulo;
    }

    function addGuardian(Guardian calldata guardian) external override onlyOwner {
        guardians.push(guardian);
        guardiansMap[guardian.guardianAddress] = true;
    }

    function getOwnerHistory() external view override returns (address[] memory) {
        return ownerHistory;
    }

    function nonceUsed(uint256 nonce) external view override returns (bool) {
        return usedNonces[nonce];
    }

    function changeOwner(
        string memory newOwnerPK,
        uint256 nonce,
        Vote[] calldata votes
    ) external override {
        require(!usedNonces[nonce], "Nonce already used");
        usedNonces[nonce] = true;
        bytes32 correcthash = keccak256(abi.encodePacked(msg.sender, nonce, address(this), newOwnerPK));

        uint8 validVotes;
        for (uint8 i; i < votes.length; i++) {
            if (
                (votes[i].voterAddress != address(0))
                && guardiansMap[votes[i].voterAddress]
                && (voteHistory[nonce][votes[i].voterAddress] == false)
                && (correcthash == votes[i].voteHash)
                && _verifySigner(votes[i].voterAddress, votes[i].voteHash, votes[i].v, votes[i].r, votes[i].s)
            ) {
                validVotes++;
                voteHistory[nonce][votes[i].voterAddress] = true;
            }
        }

        if (validVotes < quorum) {
            emit VoteFail(msg.sender, newOwnerPK);
        } else {
            address oldOwner = _owner;
            _owner = msg.sender;

            if (
                ISocialRecoveryGroupOwnerChangeCallback(factory)
                    .ownerChangeCallback(oldOwner, name, msg.sender)
            ) {
                ownerHistory.push(msg.sender);
                ownerPK = newOwnerPK;
                emit VoteSuccess(msg.sender, newOwnerPK);
            } else {
                _owner = oldOwner;
                emit VoteFail(msg.sender, newOwnerPK);
            }
        }
    }
}

contract SocialRecoveryGroupFactory is ISocialRecoveryGroupFactory, ISocialRecoveryGroupOwnerChangeCallback {
    mapping(address => mapping(string => address)) private srGroups; //key: secret owner address

    function createGroup(
        address owner,
        string calldata groupName,
        string memory ownerPK,
        uint8 quorum,
        Guardian[] calldata initGuardians
    ) external override returns(address) {
        require(
            srGroups[owner][groupName] == address(0),
            "Group already exists"
        );
        SocialRecoveryGroup group = new SocialRecoveryGroup(
            owner,
            groupName,
            ownerPK,
            quorum,
            initGuardians,
            ISocialRecoveryGroupOwnerChangeCallback(address(this))
        );
        srGroups[owner][groupName] = address(group);
        emit GroupCreated(owner, address(group));
        return address(group);
    }

    function getGroup(address owner, string calldata groupName) external view override returns(address) {
        return srGroups[owner][groupName];
    }

    function ownerChangeCallback(
        address oldOwner,
        string calldata groupName,
        address newOwner
    ) public override returns (bool) {
        address groupAddr = srGroups[oldOwner][groupName];
        if (
            (msg.sender == groupAddr)
            && (SocialRecoveryGroup(groupAddr).owner() == newOwner)
        ) {
            srGroups[newOwner][groupName] = srGroups[oldOwner][groupName];
            srGroups[oldOwner][groupName] = address(0);
            return true;
        } else {
            return false;
        }
    }
}