//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionContract.sol";
import "./interfaces/ISubjectContract.sol";
import "./interfaces/IScholarshipContract.sol";
import "./interfaces/ITuitionContract.sol";
import "./interfaces/IGeneralContract.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IManagerPool.sol";

contract ManagerPool is Ownable, IManagerPool {
    using Counters for Counters.Counter;

    struct Object {
        address objectAddress;
        Type tipe;
    }

    struct ColumnRate {
        uint256 qt;
        uint256 gk;
        uint256 th;
        uint256 ck;
    }

    enum Type {
        Mission,
        Subject,
        Scholarship,
        Tuition
    }

    IFactory public factory;
    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;
    Object[] public pools;
    mapping(address => bool) public existed;
    Counters.Counter public idCountMission;
    Counters.Counter public idCountSubject;
    Counters.Counter public idCountScholarship;
    Counters.Counter public idCountTuition;

    mapping(address => string) public studentInfo;
    mapping(address => string) public lecturerInfo;

    address public UITNFT;

    constructor(
        address _factory,
        address _accessControll,
        address _rewardDistributor,
        address _UITNFT
    ) {
        factory = IFactory(_factory);
        accessControll = IAccessControl(_accessControll);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
        UITNFT = _UITNFT;
    }

    modifier onlyRoleAdmin() {
        require(
            accessControll.hasRole(keccak256("ADMIN"), msg.sender),
            "MP: Only Admin"
        );
        _;
    }

    modifier onlyRoleStudent() {
        require(
            accessControll.hasRole(keccak256("STUDENT"), msg.sender),
            "MC: Only Student"
        );
        _;
    }

    event AddStudentInfo(address studentAddr, string hashInfo);
    event UpdateStudentInfo(address studentAddr, string hashInfo);
    event AddLecturerInfo(address lecturerAddr, string hashInfo);
    event NewMission(address _contractAddress, string _urlMetadata);
    event NewScholarship(address _contractAddress, string _urlMetadata);
    event NewSubject(address _contractAddress, string _urlMetadata);
    event NewTuition(address _contractAddress, string _urlMetadata);
    event TuitionLocked(address[] _listTuitions);
    event SubjectLocked(address[] _listSubjects);
    event MissionLocked(address[] _listMissions);
    event ScholarshipLocked(address[] _listScholarships);
    event StudentRoleRevoked(address[] studentAddrs);
    event LecturerRoleRevoked(address[] lecturerAddrs);

    function setFactory(address _factory) public onlyOwner {
        factory = IFactory(_factory);
    }

    function addStudentInfo(address studentAddr, string memory hashInfo)
        public
        onlyRoleAdmin
    {
        studentInfo[studentAddr] = hashInfo;
        accessControll.grantRole(keccak256("STUDENT"), studentAddr);
        emit AddStudentInfo(studentAddr, hashInfo);
    }

    function revokeStudentRole(address[] memory studentAddrs)
        public
        onlyRoleAdmin
    {
        for (uint i = 0; i < studentAddrs.length; i++) {
            accessControll.revokeRole(keccak256("STUDENT"), studentAddrs[i]);
        }

        emit StudentRoleRevoked(studentAddrs);
    }

    function update(address studentAdress, string memory hash)
        public
        onlyRoleStudent
    {
        require(studentAdress == msg.sender, "You are not allowed");
        require(
            keccak256(abi.encodePacked((studentInfo[msg.sender]))) !=
                keccak256(abi.encodePacked((hash))),
            "You did not edit"
        );
        studentInfo[msg.sender] = hash;
        emit UpdateStudentInfo(studentAdress, hash);
    }

    function addLecturerInfo(address lecturerAddr, string memory hashInfo)
        public
        onlyRoleAdmin
    {
        lecturerInfo[lecturerAddr] = hashInfo;
        accessControll.grantRole(keccak256("LECTURER"), lecturerAddr);
        emit AddLecturerInfo(lecturerAddr, hashInfo);
    }

    function revokeLecturerRole(address[] memory lecturerAddrs)
        public
        onlyRoleAdmin
    {
        for (uint i = 0; i < lecturerAddrs.length; i++) {
            accessControll.revokeRole(keccak256("LECTURER"), lecturerAddrs[i]);
        }

        emit LecturerRoleRevoked(lecturerAddrs);
    }

    function createNewMission(
        string memory _urlMetadata,
        string memory _missionId,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm,
        RewardType _rewardType,
        uint256 _nftId
    ) external onlyRoleAdmin {
        address missionContract = factory.createNewMission(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        IMissionContract(missionContract).setUITNFTAddress(UITNFT);
        pools.push(Object(missionContract, Type.Mission));
        existed[missionContract] = true;
        IMissionContract(missionContract).setBasicForMission(
            _missionId,
            _urlMetadata,
            _award,
            _maxEntrant,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm,
            _rewardType,
            _nftId
        );
        IMissionContract(missionContract).start();
        if (_rewardType == RewardType.Token)
            rewardDistributor.addDistributorsAddress(missionContract);
        emit NewMission(missionContract, _urlMetadata);
    }

    function createNewSubject(
        string memory _urlMetadata,
        string memory _subjectId,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm,
        ColumnRate memory _rate
    ) external onlyRoleAdmin {
        address subjectContract = factory.createNewSubject(
            address(this),
            address(accessControll)
        );
        pools.push(Object(subjectContract, Type.Subject));
        existed[subjectContract] = true;
        ISubjectContract(subjectContract).setBasicForSubject(
            _subjectId,
            _urlMetadata,
            _maxEntrant,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
        ISubjectContract(subjectContract).setScoreColumn(_rate.qt, _rate.gk, _rate.th, _rate.ck);
        ISubjectContract(subjectContract).start();
        // rewardDistributor.addDistributorsAddress(subjectContract);
        emit NewSubject(subjectContract, _urlMetadata);
    }

    function createNewScholarship(
        string memory _urlMetadata,
        string memory _scholarshipId,
        uint256 _award,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external onlyRoleAdmin {
        address scholarshipContract = factory.createNewScholarship(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(scholarshipContract, Type.Scholarship));
        existed[scholarshipContract] = true;
        IScholarshipContract(scholarshipContract).setBasicForScholarship(
            _scholarshipId,
            _urlMetadata,
            _award,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
        IScholarshipContract(scholarshipContract).start();
        rewardDistributor.addDistributorsAddress(scholarshipContract);
        emit NewScholarship(scholarshipContract, _urlMetadata);
    }

    function createNewTuition(
        string memory _urlMetadata,
        string memory _tuitionId,
        uint256 _feeByToken,
        uint256 _feeByCurency,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRoleAdmin {
        address tuitionContract = factory.createNewTuition(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(tuitionContract, Type.Tuition));
        existed[tuitionContract] = true;
        ITuitionContract(tuitionContract).setBasicForTuition(
            _tuitionId,
            _urlMetadata,
            _feeByToken,
            _feeByCurency,
            _startTime,
            _endTime
        );
        ITuitionContract(tuitionContract).start();
        rewardDistributor.addDistributorsAddress(tuitionContract);
        emit NewTuition(tuitionContract, _urlMetadata);
    }

    function close(address pool) external onlyRoleAdmin {
        IGeneralContract(pool).close();
        _removeDistributor(pool);
    }

    function _removeDistributor(address pool) private onlyRoleAdmin {
        require(existed[pool]);
        rewardDistributor.removeDistributorsAddress(pool);
    }

    function lockTuition(address[] memory _listTuitions) external onlyRoleAdmin {
        for (uint i = 0; i < _listTuitions.length; i++) {
            require(existed[_listTuitions[i]]);
            ITuitionContract(_listTuitions[i]).lock();
             _removeDistributor(_listTuitions[i]);
        }
        emit TuitionLocked(_listTuitions);
    }

    function lockSubject(address[] memory _listSubjects) external onlyRoleAdmin {
        for (uint i = 0; i < _listSubjects.length; i++) {
            require(existed[_listSubjects[i]]);
            ISubjectContract(_listSubjects[i]).lock();
        }
        emit SubjectLocked(_listSubjects);
    }

    function lockScholarship(address[] memory _listScholarships) external onlyRoleAdmin {
        for (uint i = 0; i < _listScholarships.length; i++) {
            require(existed[_listScholarships[i]]);
            IScholarshipContract(_listScholarships[i]).lock();
            _removeDistributor(_listScholarships[i]);
        }
        emit ScholarshipLocked(_listScholarships);
    }

    function lockMission(address[] memory _listMissions) external onlyRoleAdmin {
        for (uint i = 0; i < _listMissions.length; i++) {
            require(existed[_listMissions[i]]);
            IMissionContract(_listMissions[i]).lock();
            _removeDistributor(_listMissions[i]);
        }
        emit MissionLocked(_listMissions);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITuitionContract {
    struct Tuition {
        string Id;
        string urlMetadata;
        uint256 feeByToken;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    enum PaymentMethod {
        Token,
        Currency
    }

    event CreatedNewTuition(uint256 indexed id);
    event Payment(address student, uint256 timestamp, PaymentMethod _method);
    event AddStudentToTuition(uint256 studentsAmount, uint256 timestamp);
    event RemoveStudentFromTuition(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForTuition(
        string memory _tuitionId,
        string memory _urlMetadata,
        uint256 feeByToken,
        uint256 _feeByCurency,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function start() external;

    function lock() external;

    function addStudentToTuition(address[] memory _students) external;

    function removeStudentFromTuition(address[] memory _students) external;

    function paymentByToken() external;

    function paymentByCurrency(address _studentAddress) external;

    function close() external;

    function getParticipantList() external view returns (address[] memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ISubjectContract {
    struct Subject {
        string Id;
        string urlMetadata;
        uint256 maxEntrant;
        address personInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
    }

    enum ScoreColumn {
        QT,
        GK,
        TH,
        CK,
        All
    }

    struct Student {
        address studentAddress;
        bool participantToTrue;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForSubject(
        string memory _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function lock() external;

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external;

    function addStudentToSubject(address[] memory _students) external;

    function register() external;

    function cancelRegister() external;

    // function confirmCompletedAddress(
    //     address[] calldata _student,
    //     uint256[] calldata _score,
    //     ScoreColumn _column
    // ) external;

    function unConfirmCompletedAddress(address[] calldata _students) external;

    function close() external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IScholarshipContract {
    struct Scholarship {
        string Id;
        string urlMetadata;
        uint256 award;
        address persionInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewTuition(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event AddStudentToScholarship(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForScholarship(
        string memory _scholarshipId,
        string memory _urlMetadata,
        uint256 _award,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function lock() external;

    function register() external;

    function cancelRegister() external;

    function addStudentToScholarship(address[] memory _students) external;

    function confirmCompletedAddress(address[] memory _students) external;

    function unConfirmCompletedAddress(address[] memory _students) external;

    function close() external;

    function getParticipantListCompleted()
        external
        view
        returns (address[] memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardDistributor {
    function addDistributorsAddress(address distributor) external;

    function removeDistributorsAddress(address distributor) external;

    function distributeReward(address account, uint256 amount) external;

    function getUITTokenAddress()external view returns(address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import "./IManagerPool.sol";

interface IMissionContract is IManagerPool {
    struct Mission {
        string Id;
        string urlMetadata;
        uint256 award;
        uint256 maxEntrant;
        address persionInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
        RewardType rewardType;
        uint256 nftId;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);
    event ItemReceived(
        uint256 indexed itemId,
        address student,
        uint256 amount
    );

    function setBasicForMission(
        string memory _missionId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm,
        RewardType _rewardType,
        uint256 _nftId
    ) external;

    function start() external;
    
    function lock() external;

    function addStudentToMission(address[] memory _students) external;

    function register() external;

    function cancelRegister() external;

    function confirmCompletedAddress(address[] memory _students) external;

    function unConfirmCompletedAddress(address[] memory _students) external;

    function close() external;

    function getParticipantListCompleted()
        external
        view
        returns (address[] memory);

    function setUITNFTAddress(address _UITNFT) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IManagerPool {
    enum RewardType {
        Token,
        Item
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IGeneralContract {
    function close() external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFactory {
    enum Object {
        Mission,
        Subject,
        Scholarship,
        Tuition
    }

    function setObject(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) external;

    function getObject(Object _object) external view returns (address);

    function createNewMission(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);

    function createNewSubject(address owner, address accessControll)
        external
        returns (address);

    function createNewScholarship(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);

    function createNewTuition(
        address _owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 role;
    }
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(bytes32 indexed role, address indexed account);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleExist(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function addNewRoleAdmin(bytes32 role) external;

    function removeNewRoleAdmin(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}