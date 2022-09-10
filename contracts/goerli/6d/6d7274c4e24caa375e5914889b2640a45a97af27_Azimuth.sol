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