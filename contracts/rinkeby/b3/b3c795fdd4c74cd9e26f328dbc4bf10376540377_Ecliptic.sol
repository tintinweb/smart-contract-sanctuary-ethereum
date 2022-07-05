pragma solidity 0.4.24;

import {Azimuth} from "./Azimuth.sol";
import {Claims} from "./Claims.sol";
import {Polls} from "./Polls.sol";
import {EclipticBase} from "./EclipticBase.sol";
import {AddressUtils} from "./AddressUtils.sol";
import {ERC721Receiver} from "./ERC721Receiver.sol";
import {SafeMath} from "./SafeMath.sol";
import {SupportsInterfaceWithLookup} from "./SupportsInterfaceWithLookup.sol";
import {ITreasuryProxy} from "./ITreasuryProxy.sol";
// import {AddressUtils, ERC721Receiver, SafeMath, SupportsInterfaceWithLookup, ITreasuryProxy} from "./Utils.sol";
import {ERC721Metadata} from "./ERC721Metadata.sol";

contract Ecliptic is EclipticBase, SupportsInterfaceWithLookup, ERC721Metadata {
    using SafeMath for uint256;
    using AddressUtils for address;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 constant erc721Received = 0x150b7a02;

    address public constant depositAddress = 0x1111111111111111111111111111111111111111;

    ITreasuryProxy public treasuryProxy;

    bytes32 public constant treasuryUpgradeHash = hex"26f3eae628fa1a4d23e34b91a4d412526a47620ced37c80928906f9fa07c0774";

    bool public treasuryUpgraded = false;

    Claims public claims;

    constructor(
        address _previous,
        Azimuth _azimuth,
        Polls _polls,
        Claims _claims,
        ITreasuryProxy _treasuryProxy
    ) public EclipticBase(_previous, _azimuth, _polls) {
        claims = _claims;
        treasuryProxy = _treasuryProxy;

        _registerInterface(0x80ac58cd); // ERC721
        _registerInterface(0x5b5e139f); // ERC721Metadata
        _registerInterface(0x7f5828d0); // ERC173 (ownership)
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        require(0x0 != _owner);
        return azimuth.getOwnedPointCount(_owner);
    }

    function ownerOf(uint256 _tokenId) public view validPointId(_tokenId) returns (address owner) {
        uint32 id = uint32(_tokenId);

        require(azimuth.isActive(id));

        return azimuth.getOwner(id);
    }

    function exists(uint256 _tokenId) public view returns (bool doesExist) {
        return ((_tokenId < 0x100000000) && azimuth.isActive(uint32(_tokenId)));
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public {
        transferFrom(_from, _to, _tokenId);
        if (_to.isContract()) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == erc721Received);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public validPointId(_tokenId) {
        uint32 id = uint32(_tokenId);
        require(azimuth.isOwner(id, _from));
        transferPoint(id, _to, true);
    }

    function approve(address _approved, uint256 _tokenId) public validPointId(_tokenId) {
        setTransferProxy(uint32(_tokenId), _approved);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(0x0 != _operator);
        azimuth.setOperator(msg.sender, _operator, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view validPointId(_tokenId) returns (address approved) {
        require(azimuth.isActive(uint32(_tokenId)));
        return azimuth.getTransferProxy(uint32(_tokenId));
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool result) {
        return azimuth.isOperator(_owner, _operator);
    }

    function name() external view returns (string) {
        return "Azimuth Points";
    }

    function symbol() external view returns (string) {
        return "AZP";
    }

    function tokenURI(uint256 _tokenId) public view validPointId(_tokenId) returns (string _tokenURI) {
        _tokenURI = "https://azimuth.network/erc721/0000000000.json";
        bytes memory _tokenURIBytes = bytes(_tokenURI);
        _tokenURIBytes[31] = bytes1(48 + ((_tokenId / 1000000000) % 10));
        _tokenURIBytes[32] = bytes1(48 + ((_tokenId / 100000000) % 10));
        _tokenURIBytes[33] = bytes1(48 + ((_tokenId / 10000000) % 10));
        _tokenURIBytes[34] = bytes1(48 + ((_tokenId / 1000000) % 10));
        _tokenURIBytes[35] = bytes1(48 + ((_tokenId / 100000) % 10));
        _tokenURIBytes[36] = bytes1(48 + ((_tokenId / 10000) % 10));
        _tokenURIBytes[37] = bytes1(48 + ((_tokenId / 1000) % 10));
        _tokenURIBytes[38] = bytes1(48 + ((_tokenId / 100) % 10));
        _tokenURIBytes[39] = bytes1(48 + ((_tokenId / 10) % 10));
        _tokenURIBytes[40] = bytes1(48 + ((_tokenId / 1) % 10));
    }

    function configureKeys(
        uint32 _point,
        bytes32 _encryptionKey,
        bytes32 _authenticationKey,
        uint32 _cryptoSuiteVersion,
        bool _discontinuous
    ) external activePointManager(_point) onL1(_point) {
        if (_discontinuous) {
            azimuth.incrementContinuityNumber(_point);
        }
        azimuth.setKeys(_point, _encryptionKey, _authenticationKey, _cryptoSuiteVersion);
    }

    function spawn(uint32 _point, address _target) external {
        require(azimuth.isOwner(_point, 0x0));

        uint16 prefix = azimuth.getPrefix(_point);

        require(depositAddress != azimuth.getOwner(prefix));
        require(depositAddress != azimuth.getSpawnProxy(prefix));

        require((uint8(azimuth.getPointSize(prefix)) + 1) == uint8(azimuth.getPointSize(_point)));

        require((azimuth.hasBeenLinked(prefix)) && (azimuth.getSpawnCount(prefix) < getSpawnLimit(prefix, block.timestamp)));

        require(azimuth.canSpawnAs(prefix, msg.sender));

        if (msg.sender == _target) {
            doSpawn(_point, _target, true, 0x0);
        } else {
            doSpawn(_point, _target, false, azimuth.getOwner(prefix));
        }
    }

    function doSpawn(
        uint32 _point,
        address _target,
        bool _direct,
        address _holder
    ) internal {
        azimuth.registerSpawned(_point);

        if (_direct) {
            azimuth.activatePoint(_point);
            azimuth.setOwner(_point, _target);

            emit Transfer(0x0, _target, uint256(_point));
        } else {
            azimuth.setOwner(_point, _holder);
            azimuth.setTransferProxy(_point, _target);

            emit Transfer(0x0, _holder, uint256(_point));
            emit Approval(_holder, _target, uint256(_point));
        }
    }

    function transferPoint(
        uint32 _point,
        address _target,
        bool _reset
    ) public {
        require(azimuth.canTransfer(_point, msg.sender));

        require(depositAddress != _target || (azimuth.getPointSize(_point) != Azimuth.Size.Galaxy && !azimuth.getOwner(_point).isContract()));

        if (!azimuth.isActive(_point)) {
            azimuth.activatePoint(_point);
        }

        if (!azimuth.isOwner(_point, _target)) {
            address old = azimuth.getOwner(_point);

            azimuth.setOwner(_point, _target);

            azimuth.setTransferProxy(_point, 0);

            emit Transfer(old, _target, uint256(_point));
        }
        if (depositAddress == _target) {
            azimuth.setKeys(_point, 0, 0, 0);
            azimuth.setManagementProxy(_point, 0);
            azimuth.setVotingProxy(_point, 0);
            azimuth.setTransferProxy(_point, 0);
            azimuth.setSpawnProxy(_point, 0);
            claims.clearClaims(_point);
            azimuth.cancelEscape(_point);
        } else if (_reset) {
            if (azimuth.hasBeenLinked(_point)) {
                azimuth.incrementContinuityNumber(_point);
                azimuth.setKeys(_point, 0, 0, 0);
            }
            azimuth.setManagementProxy(_point, 0);
            azimuth.setVotingProxy(_point, 0);
            azimuth.setTransferProxy(_point, 0);
            if (depositAddress != azimuth.getSpawnProxy(_point)) {
                azimuth.setSpawnProxy(_point, 0);
            }
            claims.clearClaims(_point);
        }
    }

    function escape(uint32 _point, uint32 _sponsor) external activePointManager(_point) onL1(_point) {
        require(depositAddress != azimuth.getOwner(_sponsor));

        require(canEscapeTo(_point, _sponsor));
        azimuth.setEscapeRequest(_point, _sponsor);
    }

    function cancelEscape(uint32 _point) external activePointManager(_point) {
        azimuth.cancelEscape(_point);
    }

    function adopt(uint32 _point) external onL1(_point) {
        uint32 request = azimuth.getEscapeRequest(_point);
        require(azimuth.isEscaping(_point) && azimuth.canManage(request, msg.sender));
        require(depositAddress != azimuth.getOwner(request));

        azimuth.doEscape(_point);
    }

    function reject(uint32 _point) external {
        uint32 request = azimuth.getEscapeRequest(_point);
        require(azimuth.isEscaping(_point) && azimuth.canManage(request, msg.sender));
        require(depositAddress != azimuth.getOwner(request));
        azimuth.cancelEscape(_point);
    }

    function detach(uint32 _point) external {
        uint32 sponsor = azimuth.getSponsor(_point);
        require(azimuth.hasSponsor(_point) && azimuth.canManage(sponsor, msg.sender));
        require(depositAddress != azimuth.getOwner(sponsor));

        azimuth.loseSponsor(_point);
    }

    function getSpawnLimit(uint32 _point, uint256 _time) public view returns (uint32 limit) {
        Azimuth.Size size = azimuth.getPointSize(_point);

        if (size == Azimuth.Size.Galaxy) {
            return 255;
        } else if (size == Azimuth.Size.Star) {
            uint256 yearsSince2019 = (_time - 1546300800) / 365 days;
            if (yearsSince2019 < 6) {
                limit = uint32(1024 * (2**yearsSince2019));
            } else {
                limit = 65535;
            }
            return limit;
        } else {
            return 0;
        }
    }

    function canEscapeTo(uint32 _point, uint32 _sponsor) public view returns (bool canEscape) {
        if (!azimuth.hasBeenLinked(_sponsor)) return false;
        Azimuth.Size pointSize = azimuth.getPointSize(_point);
        Azimuth.Size sponsorSize = azimuth.getPointSize(_sponsor);
        return (((uint8(sponsorSize) + 1) == uint8(pointSize)) || ((sponsorSize == pointSize) && !azimuth.hasBeenLinked(_point)));
    }

    function setManagementProxy(uint32 _point, address _manager) external activePointManager(_point) onL1(_point) {
        azimuth.setManagementProxy(_point, _manager);
    }

    function setSpawnProxy(uint16 _prefix, address _spawnProxy) external activePointSpawner(_prefix) onL1(_prefix) {
        require(depositAddress != azimuth.getSpawnProxy(_prefix));

        azimuth.setSpawnProxy(_prefix, _spawnProxy);
    }

    function setVotingProxy(uint8 _galaxy, address _voter) external activePointVoter(_galaxy) {
        azimuth.setVotingProxy(_galaxy, _voter);
    }

    function setTransferProxy(uint32 _point, address _transferProxy) public onL1(_point) {
        address owner = azimuth.getOwner(_point);
        require((owner == msg.sender) || azimuth.isOperator(owner, msg.sender));
        azimuth.setTransferProxy(_point, _transferProxy);
        emit Approval(owner, _transferProxy, uint256(_point));
    }

    function startUpgradePoll(uint8 _galaxy, EclipticBase _proposal) external activePointVoter(_galaxy) {
        require(_proposal.previousEcliptic() == address(this));
        polls.startUpgradePoll(_proposal);
    }

    function startDocumentPoll(uint8 _galaxy, bytes32 _proposal) external activePointVoter(_galaxy) {
        polls.startDocumentPoll(_proposal);
    }

    function castUpgradeVote(
        uint8 _galaxy,
        EclipticBase _proposal,
        bool _vote
    ) external activePointVoter(_galaxy) {
        bool majority = polls.castUpgradeVote(_galaxy, _proposal, _vote);
        if (majority) {
            upgrade(_proposal);
        }
    }

    function castDocumentVote(
        uint8 _galaxy,
        bytes32 _proposal,
        bool _vote
    ) external activePointVoter(_galaxy) {
        polls.castDocumentVote(_galaxy, _proposal, _vote);
    }

    function updateUpgradePoll(EclipticBase _proposal) external {
        bool majority = polls.updateUpgradePoll(_proposal);

        if (majority) {
            upgrade(_proposal);
        }
    }

    function updateDocumentPoll(bytes32 _proposal) external {
        polls.updateDocumentPoll(_proposal);
    }

    function upgradeTreasury(address _treasuryImpl) external {
        require(!treasuryUpgraded);
        require(keccak256(_treasuryImpl) == treasuryUpgradeHash);
        treasuryProxy.upgradeTo(_treasuryImpl);
        treasuryUpgraded = true;
    }

    function createGalaxy(uint8 _galaxy, address _target) external onlyOwner {
        require(azimuth.isOwner(_galaxy, 0x0) && 0x0 != _target);

        polls.incrementTotalVoters();

        if (msg.sender == _target) {
            doSpawn(_galaxy, _target, true, 0x0);
        } else {
            doSpawn(_galaxy, _target, false, msg.sender);
        }
    }

    function setDnsDomains(
        string _primary,
        string _secondary,
        string _tertiary
    ) external onlyOwner {
        azimuth.setDnsDomains(_primary, _secondary, _tertiary);
    }

    modifier validPointId(uint256 _id) {
        require(_id < 0x100000000);
        _;
    }
    modifier onL1(uint32 _point) {
        require(depositAddress != azimuth.getOwner(_point));
        _;
    }
}

pragma solidity 0.4.24;

import {Ownable} from "./Ownable.sol";

contract Azimuth is Ownable {
    event OwnerChanged(uint32 indexed point, address indexed owner);

    event Activated(uint32 indexed point);

    event Spawned(uint32 indexed prefix, uint32 indexed child);

    event EscapeRequested(uint32 indexed point, uint32 indexed sponsor);

    event EscapeCanceled(uint32 indexed point, uint32 indexed sponsor);

    event EscapeAccepted(uint32 indexed point, uint32 indexed sponsor);

    event LostSponsor(uint32 indexed point, uint32 indexed sponsor);

    event ChangedKeys(uint32 indexed point, bytes32 encryptionKey, bytes32 authenticationKey, uint32 cryptoSuiteVersion, uint32 keyRevisionNumber);

    event BrokeContinuity(uint32 indexed point, uint32 number);

    event ChangedSpawnProxy(uint32 indexed point, address indexed spawnProxy);

    event ChangedTransferProxy(uint32 indexed point, address indexed transferProxy);

    event ChangedManagementProxy(uint32 indexed point, address indexed managementProxy);

    event ChangedVotingProxy(uint32 indexed point, address indexed votingProxy);

    event ChangedDns(string primary, string secondary, string tertiary);

    enum Size {
        Galaxy, // = 0
        Star, // = 1
        Planet // = 2
    }

    struct Point {
        bytes32 encryptionKey;
        bytes32 authenticationKey;
        uint32[] spawned;
        bool hasSponsor;
        bool active;
        bool escapeRequested;
        uint32 sponsor;
        uint32 escapeRequestedTo;
        uint32 cryptoSuiteVersion;
        uint32 keyRevisionNumber;
        uint32 continuityNumber;
    }

    struct Deed {
        address owner;
        address managementProxy;
        address spawnProxy;
        address votingProxy;
        address transferProxy;
    }

    mapping(uint32 => Point) public points;
    mapping(uint32 => Deed) public rights;
    mapping(address => mapping(address => bool)) public operators;
    string[3] public dnsDomains;
    mapping(uint32 => uint32[]) public sponsoring;
    mapping(uint32 => mapping(uint32 => uint256)) public sponsoringIndexes;
    mapping(uint32 => uint32[]) public escapeRequests;
    mapping(uint32 => mapping(uint32 => uint256)) public escapeRequestsIndexes;
    mapping(address => uint32[]) public pointsOwnedBy;
    mapping(address => mapping(uint32 => uint256)) public pointOwnerIndexes;
    mapping(address => uint32[]) public managerFor;
    mapping(address => mapping(uint32 => uint256)) public managerForIndexes;
    mapping(address => uint32[]) public spawningFor;
    mapping(address => mapping(uint32 => uint256)) public spawningForIndexes;
    mapping(address => uint32[]) public votingFor;
    mapping(address => mapping(uint32 => uint256)) public votingForIndexes;
    mapping(address => uint32[]) public transferringFor;
    mapping(address => mapping(uint32 => uint256)) public transferringForIndexes;

    constructor() public {
        setDnsDomains("example.com", "example.com", "example.com");
    }

    function setDnsDomains(
        string _primary,
        string _secondary,
        string _tertiary
    ) public onlyOwner {
        dnsDomains[0] = _primary;
        dnsDomains[1] = _secondary;
        dnsDomains[2] = _tertiary;
        emit ChangedDns(_primary, _secondary, _tertiary);
    }

    function isActive(uint32 _point) external view returns (bool equals) {
        return points[_point].active;
    }

    function getKeys(uint32 _point)
        external
        view
        returns (
            bytes32 crypt,
            bytes32 auth,
            uint32 suite,
            uint32 revision
        )
    {
        Point storage point = points[_point];
        return (point.encryptionKey, point.authenticationKey, point.cryptoSuiteVersion, point.keyRevisionNumber);
    }

    function getKeyRevisionNumber(uint32 _point) external view returns (uint32 revision) {
        return points[_point].keyRevisionNumber;
    }

    function hasBeenLinked(uint32 _point) external view returns (bool result) {
        return (points[_point].keyRevisionNumber > 0);
    }

    function isLive(uint32 _point) external view returns (bool result) {
        Point storage point = points[_point];
        return (point.encryptionKey != 0 && point.authenticationKey != 0 && point.cryptoSuiteVersion != 0);
    }

    function getContinuityNumber(uint32 _point) external view returns (uint32 continuityNumber) {
        return points[_point].continuityNumber;
    }

    function getSpawnCount(uint32 _point) external view returns (uint32 spawnCount) {
        uint256 len = points[_point].spawned.length;
        assert(len < 2**32);
        return uint32(len);
    }

    function getSpawned(uint32 _point) external view returns (uint32[] spawned) {
        return points[_point].spawned;
    }

    function hasSponsor(uint32 _point) external view returns (bool has) {
        return points[_point].hasSponsor;
    }

    function getSponsor(uint32 _point) external view returns (uint32 sponsor) {
        return points[_point].sponsor;
    }

    function isSponsor(uint32 _point, uint32 _sponsor) external view returns (bool result) {
        Point storage point = points[_point];
        return (point.hasSponsor && (point.sponsor == _sponsor));
    }

    function getSponsoringCount(uint32 _sponsor) external view returns (uint256 count) {
        return sponsoring[_sponsor].length;
    }

    function getSponsoring(uint32 _sponsor) external view returns (uint32[] sponsees) {
        return sponsoring[_sponsor];
    }

    function isEscaping(uint32 _point) external view returns (bool escaping) {
        return points[_point].escapeRequested;
    }

    function getEscapeRequest(uint32 _point) external view returns (uint32 escape) {
        return points[_point].escapeRequestedTo;
    }

    function isRequestingEscapeTo(uint32 _point, uint32 _sponsor) public view returns (bool equals) {
        Point storage point = points[_point];
        return (point.escapeRequested && (point.escapeRequestedTo == _sponsor));
    }

    function getEscapeRequestsCount(uint32 _sponsor) external view returns (uint256 count) {
        return escapeRequests[_sponsor].length;
    }

    function getEscapeRequests(uint32 _sponsor) external view returns (uint32[] requests) {
        return escapeRequests[_sponsor];
    }

    function activatePoint(uint32 _point) external onlyOwner {
        Point storage point = points[_point];
        require(!point.active);
        point.active = true;
        registerSponsor(_point, true, getPrefix(_point));
        emit Activated(_point);
    }

    function setKeys(
        uint32 _point,
        bytes32 _encryptionKey,
        bytes32 _authenticationKey,
        uint32 _cryptoSuiteVersion
    ) external onlyOwner {
        Point storage point = points[_point];
        if (
            point.encryptionKey == _encryptionKey && point.authenticationKey == _authenticationKey && point.cryptoSuiteVersion == _cryptoSuiteVersion
        ) {
            return;
        }

        point.encryptionKey = _encryptionKey;
        point.authenticationKey = _authenticationKey;
        point.cryptoSuiteVersion = _cryptoSuiteVersion;
        point.keyRevisionNumber++;

        emit ChangedKeys(_point, _encryptionKey, _authenticationKey, _cryptoSuiteVersion, point.keyRevisionNumber);
    }

    function incrementContinuityNumber(uint32 _point) external onlyOwner {
        Point storage point = points[_point];
        point.continuityNumber++;
        emit BrokeContinuity(_point, point.continuityNumber);
    }

    function registerSpawned(uint32 _point) external onlyOwner {
        uint32 prefix = getPrefix(_point);
        if (prefix == _point) {
            return;
        }

        points[prefix].spawned.push(_point);
        emit Spawned(prefix, _point);
    }

    function loseSponsor(uint32 _point) external onlyOwner {
        Point storage point = points[_point];
        if (!point.hasSponsor) {
            return;
        }
        registerSponsor(_point, false, point.sponsor);
        emit LostSponsor(_point, point.sponsor);
    }

    function setEscapeRequest(uint32 _point, uint32 _sponsor) external onlyOwner {
        if (isRequestingEscapeTo(_point, _sponsor)) {
            return;
        }
        registerEscapeRequest(_point, true, _sponsor);
        emit EscapeRequested(_point, _sponsor);
    }

    function cancelEscape(uint32 _point) external onlyOwner {
        Point storage point = points[_point];
        if (!point.escapeRequested) {
            return;
        }
        uint32 request = point.escapeRequestedTo;
        registerEscapeRequest(_point, false, 0);
        emit EscapeCanceled(_point, request);
    }

    function doEscape(uint32 _point) external onlyOwner {
        Point storage point = points[_point];
        require(point.escapeRequested);
        registerSponsor(_point, true, point.escapeRequestedTo);
        registerEscapeRequest(_point, false, 0);
        emit EscapeAccepted(_point, point.sponsor);
    }

    function getPrefix(uint32 _point) public pure returns (uint16 prefix) {
        if (_point < 0x10000) {
            return uint16(_point % 0x100);
        }
        return uint16(_point % 0x10000);
    }

    function getPointSize(uint32 _point) external pure returns (Size _size) {
        if (_point < 0x100) return Size.Galaxy;
        if (_point < 0x10000) return Size.Star;
        return Size.Planet;
    }

    function registerSponsor(
        uint32 _point,
        bool _hasSponsor,
        uint32 _sponsor
    ) internal {
        Point storage point = points[_point];
        bool had = point.hasSponsor;
        uint32 prev = point.sponsor;

        if ((!had && !_hasSponsor) || (had && _hasSponsor && prev == _sponsor)) {
            return;
        }

        if (had) {
            uint256 i = sponsoringIndexes[prev][_point];

            assert(i > 0);
            i--;

            uint32[] storage prevSponsoring = sponsoring[prev];
            uint256 last = prevSponsoring.length - 1;
            uint32 moved = prevSponsoring[last];
            prevSponsoring[i] = moved;
            sponsoringIndexes[prev][moved] = i + 1;

            delete (prevSponsoring[last]);
            prevSponsoring.length = last;
            sponsoringIndexes[prev][_point] = 0;
        }

        if (_hasSponsor) {
            uint32[] storage newSponsoring = sponsoring[_sponsor];
            newSponsoring.push(_point);
            sponsoringIndexes[_sponsor][_point] = newSponsoring.length;
        }

        point.sponsor = _sponsor;
        point.hasSponsor = _hasSponsor;
    }

    function registerEscapeRequest(
        uint32 _point,
        bool _isEscaping,
        uint32 _sponsor
    ) internal {
        Point storage point = points[_point];
        bool was = point.escapeRequested;
        uint32 prev = point.escapeRequestedTo;

        if ((!was && !_isEscaping) || (was && _isEscaping && prev == _sponsor)) {
            return;
        }

        if (was) {
            uint256 i = escapeRequestsIndexes[prev][_point];
            assert(i > 0);
            i--;

            uint32[] storage prevRequests = escapeRequests[prev];
            uint256 last = prevRequests.length - 1;
            uint32 moved = prevRequests[last];
            prevRequests[i] = moved;
            escapeRequestsIndexes[prev][moved] = i + 1;

            delete (prevRequests[last]);
            prevRequests.length = last;
            escapeRequestsIndexes[prev][_point] = 0;
        }

        if (_isEscaping) {
            uint32[] storage newRequests = escapeRequests[_sponsor];
            newRequests.push(_point);
            escapeRequestsIndexes[_sponsor][_point] = newRequests.length;
        }

        point.escapeRequestedTo = _sponsor;
        point.escapeRequested = _isEscaping;
    }

    function getOwner(uint32 _point) external view returns (address owner) {
        return rights[_point].owner;
    }

    function isOwner(uint32 _point, address _address) external view returns (bool result) {
        return (rights[_point].owner == _address);
    }

    function getOwnedPointCount(address _whose) external view returns (uint256 count) {
        return pointsOwnedBy[_whose].length;
    }

    function getOwnedPoints(address _whose) external view returns (uint32[] ownedPoints) {
        return pointsOwnedBy[_whose];
    }

    function getOwnedPointAtIndex(address _whose, uint256 _index) external view returns (uint32 point) {
        uint32[] storage owned = pointsOwnedBy[_whose];
        require(_index < owned.length);
        return owned[_index];
    }

    function getManagementProxy(uint32 _point) external view returns (address manager) {
        return rights[_point].managementProxy;
    }

    function isManagementProxy(uint32 _point, address _proxy) external view returns (bool result) {
        return (rights[_point].managementProxy == _proxy);
    }

    function canManage(uint32 _point, address _who) external view returns (bool result) {
        Deed storage deed = rights[_point];
        return ((0x0 != _who) && ((_who == deed.owner) || (_who == deed.managementProxy)));
    }

    function getManagerForCount(address _proxy) external view returns (uint256 count) {
        return managerFor[_proxy].length;
    }

    function getManagerFor(address _proxy) external view returns (uint32[] mfor) {
        return managerFor[_proxy];
    }

    function getSpawnProxy(uint32 _point) external view returns (address spawnProxy) {
        return rights[_point].spawnProxy;
    }

    function isSpawnProxy(uint32 _point, address _proxy) external view returns (bool result) {
        return (rights[_point].spawnProxy == _proxy);
    }

    function canSpawnAs(uint32 _point, address _who) external view returns (bool result) {
        Deed storage deed = rights[_point];
        return ((0x0 != _who) && ((_who == deed.owner) || (_who == deed.spawnProxy)));
    }

    function getSpawningForCount(address _proxy) external view returns (uint256 count) {
        return spawningFor[_proxy].length;
    }

    function getSpawningFor(address _proxy) external view returns (uint32[] sfor) {
        return spawningFor[_proxy];
    }

    function getVotingProxy(uint32 _point) external view returns (address voter) {
        return rights[_point].votingProxy;
    }

    function isVotingProxy(uint32 _point, address _proxy) external view returns (bool result) {
        return (rights[_point].votingProxy == _proxy);
    }

    function canVoteAs(uint32 _point, address _who) external view returns (bool result) {
        Deed storage deed = rights[_point];
        return ((0x0 != _who) && ((_who == deed.owner) || (_who == deed.votingProxy)));
    }

    function getVotingForCount(address _proxy) external view returns (uint256 count) {
        return votingFor[_proxy].length;
    }

    function getVotingFor(address _proxy) external view returns (uint32[] vfor) {
        return votingFor[_proxy];
    }

    function getTransferProxy(uint32 _point) external view returns (address transferProxy) {
        return rights[_point].transferProxy;
    }

    function isTransferProxy(uint32 _point, address _proxy) external view returns (bool result) {
        return (rights[_point].transferProxy == _proxy);
    }

    function canTransfer(uint32 _point, address _who) external view returns (bool result) {
        Deed storage deed = rights[_point];
        return ((0x0 != _who) && ((_who == deed.owner) || (_who == deed.transferProxy) || operators[deed.owner][_who]));
    }

    function getTransferringForCount(address _proxy) external view returns (uint256 count) {
        return transferringFor[_proxy].length;
    }

    function getTransferringFor(address _proxy) external view returns (uint32[] tfor) {
        return transferringFor[_proxy];
    }

    function isOperator(address _owner, address _operator) external view returns (bool result) {
        return operators[_owner][_operator];
    }

    function setOwner(uint32 _point, address _owner) external onlyOwner {
        require(0x0 != _owner);

        address prev = rights[_point].owner;

        if (prev == _owner) {
            return;
        }

        if (0x0 != prev) {
            uint256 i = pointOwnerIndexes[prev][_point];

            assert(i > 0);
            i--;

            uint32[] storage owner = pointsOwnedBy[prev];
            uint256 last = owner.length - 1;
            uint32 moved = owner[last];
            owner[i] = moved;
            pointOwnerIndexes[prev][moved] = i + 1;

            delete (owner[last]);
            owner.length = last;
            pointOwnerIndexes[prev][_point] = 0;
        }

        rights[_point].owner = _owner;
        pointsOwnedBy[_owner].push(_point);
        pointOwnerIndexes[_owner][_point] = pointsOwnedBy[_owner].length;
        emit OwnerChanged(_point, _owner);
    }

    function setManagementProxy(uint32 _point, address _proxy) external onlyOwner {
        Deed storage deed = rights[_point];
        address prev = deed.managementProxy;
        if (prev == _proxy) {
            return;
        }

        if (0x0 != prev) {
            uint256 i = managerForIndexes[prev][_point];
            assert(i > 0);
            i--;

            uint32[] storage prevMfor = managerFor[prev];
            uint256 last = prevMfor.length - 1;
            uint32 moved = prevMfor[last];
            prevMfor[i] = moved;
            managerForIndexes[prev][moved] = i + 1;

            delete (prevMfor[last]);
            prevMfor.length = last;
            managerForIndexes[prev][_point] = 0;
        }

        if (0x0 != _proxy) {
            uint32[] storage mfor = managerFor[_proxy];
            mfor.push(_point);
            managerForIndexes[_proxy][_point] = mfor.length;
        }

        deed.managementProxy = _proxy;
        emit ChangedManagementProxy(_point, _proxy);
    }

    function setSpawnProxy(uint32 _point, address _proxy) external onlyOwner {
        Deed storage deed = rights[_point];
        address prev = deed.spawnProxy;
        if (prev == _proxy) {
            return;
        }

        if (0x0 != prev) {
            uint256 i = spawningForIndexes[prev][_point];
            assert(i > 0);
            i--;

            uint32[] storage prevSfor = spawningFor[prev];
            uint256 last = prevSfor.length - 1;
            uint32 moved = prevSfor[last];
            prevSfor[i] = moved;
            spawningForIndexes[prev][moved] = i + 1;

            delete (prevSfor[last]);
            prevSfor.length = last;
            spawningForIndexes[prev][_point] = 0;
        }

        if (0x0 != _proxy) {
            uint32[] storage sfor = spawningFor[_proxy];
            sfor.push(_point);
            spawningForIndexes[_proxy][_point] = sfor.length;
        }

        deed.spawnProxy = _proxy;
        emit ChangedSpawnProxy(_point, _proxy);
    }

    function setVotingProxy(uint32 _point, address _proxy) external onlyOwner {
        Deed storage deed = rights[_point];
        address prev = deed.votingProxy;
        if (prev == _proxy) {
            return;
        }

        if (0x0 != prev) {
            uint256 i = votingForIndexes[prev][_point];

            assert(i > 0);
            i--;

            uint32[] storage prevVfor = votingFor[prev];
            uint256 last = prevVfor.length - 1;
            uint32 moved = prevVfor[last];
            prevVfor[i] = moved;
            votingForIndexes[prev][moved] = i + 1;

            delete (prevVfor[last]);
            prevVfor.length = last;
            votingForIndexes[prev][_point] = 0;
        }

        if (0x0 != _proxy) {
            uint32[] storage vfor = votingFor[_proxy];
            vfor.push(_point);
            votingForIndexes[_proxy][_point] = vfor.length;
        }

        deed.votingProxy = _proxy;
        emit ChangedVotingProxy(_point, _proxy);
    }

    function setTransferProxy(uint32 _point, address _proxy) external onlyOwner {
        Deed storage deed = rights[_point];
        address prev = deed.transferProxy;
        if (prev == _proxy) {
            return;
        }

        if (0x0 != prev) {
            uint256 i = transferringForIndexes[prev][_point];
            assert(i > 0);
            i--;

            uint32[] storage prevTfor = transferringFor[prev];
            uint256 last = prevTfor.length - 1;
            uint32 moved = prevTfor[last];
            prevTfor[i] = moved;
            transferringForIndexes[prev][moved] = i + 1;

            delete (prevTfor[last]);
            prevTfor.length = last;
            transferringForIndexes[prev][_point] = 0;
        }

        if (0x0 != _proxy) {
            uint32[] storage tfor = transferringFor[_proxy];
            tfor.push(_point);
            transferringForIndexes[_proxy][_point] = tfor.length;
        }

        deed.transferProxy = _proxy;
        emit ChangedTransferProxy(_point, _proxy);
    }

    function setOperator(
        address _owner,
        address _operator,
        bool _approved
    ) external onlyOwner {
        operators[_owner][_operator] = _approved;
    }
}

pragma solidity 0.4.24;

import {Azimuth} from "./Azimuth.sol";
import {ReadsAzimuth} from "./ReadsAzimuth.sol";

contract Claims is ReadsAzimuth {
    event ClaimAdded(uint32 indexed by, string _protocol, string _claim, bytes _dossier);
    event ClaimRemoved(uint32 indexed by, string _protocol, string _claim);
    uint8 constant maxClaims = 16;
    struct Claim {
        string protocol;
        string claim;
        bytes dossier;
    }

    mapping(uint32 => Claim[maxClaims]) public claims;

    constructor(Azimuth _azimuth) public ReadsAzimuth(_azimuth) {}

    function addClaim(
        uint32 _point,
        string _protocol,
        string _claim,
        bytes _dossier
    ) external activePointManager(_point) {
        require((0 < bytes(_protocol).length) && (0 < bytes(_claim).length));
        uint8 cur = findClaim(_point, _protocol, _claim);
        if (cur == 0) {
            uint8 empty = findEmptySlot(_point);
            claims[_point][empty] = Claim(_protocol, _claim, _dossier);
        } else {
            claims[_point][cur - 1] = Claim(_protocol, _claim, _dossier);
        }
        emit ClaimAdded(_point, _protocol, _claim, _dossier);
    }

    function removeClaim(
        uint32 _point,
        string _protocol,
        string _claim
    ) external activePointManager(_point) {
        uint256 i = findClaim(_point, _protocol, _claim);

        require(i > 0);
        i--;

        delete claims[_point][i];

        emit ClaimRemoved(_point, _protocol, _claim);
    }

    function clearClaims(uint32 _point) external {
        require(azimuth.canManage(_point, msg.sender) || (msg.sender == azimuth.owner()));

        Claim[maxClaims] storage currClaims = claims[_point];

        for (uint8 i = 0; i < maxClaims; i++) {
            if (0 < bytes(currClaims[i].claim).length) {
                emit ClaimRemoved(_point, currClaims[i].protocol, currClaims[i].claim);
            }

            delete currClaims[i];
        }
    }

    function findClaim(
        uint32 _whose,
        string _protocol,
        string _claim
    ) public view returns (uint8 index) {
        bytes32 protocolHash = keccak256(bytes(_protocol));
        bytes32 claimHash = keccak256(bytes(_claim));
        Claim[maxClaims] storage theirClaims = claims[_whose];
        for (uint8 i = 0; i < maxClaims; i++) {
            Claim storage thisClaim = theirClaims[i];
            if ((protocolHash == keccak256(bytes(thisClaim.protocol))) && (claimHash == keccak256(bytes(thisClaim.claim)))) {
                return i + 1;
            }
        }
        return 0;
    }

    function findEmptySlot(uint32 _whose) internal view returns (uint8 index) {
        Claim[maxClaims] storage theirClaims = claims[_whose];
        for (uint8 i = 0; i < maxClaims; i++) {
            Claim storage thisClaim = theirClaims[i];
            if ((0 == bytes(thisClaim.claim).length)) {
                return i;
            }
        }
        revert();
    }
}

pragma solidity 0.4.24;

import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {SafeMath16} from "./SafeMath16.sol";
import {SafeMath8} from "./SafeMath8.sol";

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

import {Azimuth} from "./Azimuth.sol";
import {Ownable} from "./Ownable.sol";
import {Polls} from "./Polls.sol";
import {ReadsAzimuth} from "./ReadsAzimuth.sol";

contract EclipticBase is Ownable, ReadsAzimuth {
    event Upgraded(address to);

    Polls public polls;

    address public previousEcliptic;

    constructor(
        address _previous,
        Azimuth _azimuth,
        Polls _polls
    ) internal ReadsAzimuth(_azimuth) {
        previousEcliptic = _previous;
        polls = _polls;
    }

    function onUpgrade() external {
        require(msg.sender == previousEcliptic && this == azimuth.owner() && this == polls.owner());
    }

    function upgrade(EclipticBase _new) internal {
        azimuth.transferOwnership(_new);
        polls.transferOwnership(_new);

        _new.onUpgrade();

        emit Upgraded(_new);
        selfdestruct(_new);
    }
}

pragma solidity 0.4.24;

library AddressUtils {
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

pragma solidity 0.4.24;

contract ERC721Receiver {
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    ) public returns (bytes4);
}

pragma solidity 0.4.24;

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

pragma solidity 0.4.24;

import {ERC165} from "./ERC165.sol";

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

pragma solidity 0.4.24;

interface ITreasuryProxy {
    function upgradeTo(address _impl) external returns (bool);

    function freeze() external returns (bool);
}

pragma solidity 0.4.24;

import {ERC165} from "./ERC165.sol";

contract ERC721Basic is ERC165 {
    bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;

    bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;

    bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;

    bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;

    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;

    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public;
}

contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) public view returns (uint256);
}

contract ERC721Metadata is ERC721Basic {
    function name() external view returns (string _name);

    function symbol() external view returns (string _symbol);

    function tokenURI(uint256 _tokenId) public view returns (string);
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

import {Azimuth} from "./Azimuth.sol";

contract ReadsAzimuth {
    Azimuth public azimuth;

    constructor(Azimuth _azimuth) public {
        azimuth = _azimuth;
    }

    modifier activePointOwner(uint32 _point) {
        require(azimuth.isOwner(_point, msg.sender) && azimuth.isActive(_point));
        _;
    }

    modifier activePointManager(uint32 _point) {
        require(azimuth.canManage(_point, msg.sender) && azimuth.isActive(_point));
        _;
    }

    modifier activePointSpawner(uint32 _point) {
        require(azimuth.canSpawnAs(_point, msg.sender) && azimuth.isActive(_point));
        _;
    }

    modifier activePointVoter(uint32 _point) {
        require(azimuth.canVoteAs(_point, msg.sender) && azimuth.isActive(_point));
        _;
    }
}

pragma solidity 0.4.24;

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

pragma solidity 0.4.24;

interface ERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}