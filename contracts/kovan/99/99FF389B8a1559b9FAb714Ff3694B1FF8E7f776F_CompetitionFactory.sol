// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IFactory.sol";
import "../interface/ICompetitionFactory.sol";
import "../interface/IRegularCompetitionContract.sol";
import "../interface/IGuaranteedCompetitionContract.sol";
import "../interface/IP2PCompetitionContract.sol";
import "../interface/ICompetitionPool.sol";
import "../interface/ISportManager.sol";

/* ERROR MESSAGE */

// CF01: Game is not supported
// CF02: Exceed limit
// CF03: Address 0x00

contract CompetitionFactory is Ownable, ICompetitionFactory {
    ISportManager public sportManager;
    address public oracle;
    mapping(CompetitionType => address) public typeToAddress;

    uint256 public limitOption = 10;
    uint256 public p2pDistanceAcceptTime = 15 minutes;
    uint256 public p2pDistanceConfirmTime = 15 minutes;
    uint256 public p2pdistanceVoteTime = 45 minutes;
    uint256 public p2pMaximumRefundTime = 24 hours;
    uint256 public regularGapValidatitionTime = 6 hours;
    uint256 public minimumBetime = 1 hours;

    constructor(
        address _p2p,
        address _regular,
        address _guarantee,
        address _sportManager,
        address _chainlinkOracleSportData
    ) {
        require(
            _p2p != address(0) &&
                _regular != address(0) &&
                _guarantee != address(0) &&
                _sportManager != address(0) &&
                _chainlinkOracleSportData != address(0),
            "CF03"
        );
        typeToAddress[CompetitionType.P2PCompetition] = _p2p;
        typeToAddress[CompetitionType.RegularCompetition] = _regular;
        typeToAddress[CompetitionType.GuaranteedCompetition] = _guarantee;
        sportManager = ISportManager(_sportManager);
        oracle = _chainlinkOracleSportData;
    }

    function setCompetitionFactory(
        address _p2p,
        address _regular,
        address _guarantee
    ) external onlyOwner {
        require(
            _p2p != address(0) &&
                _regular != address(0) &&
                _guarantee != address(0),
            "CF03"
        );
        typeToAddress[CompetitionType.P2PCompetition] = _p2p;
        typeToAddress[CompetitionType.RegularCompetition] = _regular;
        typeToAddress[CompetitionType.GuaranteedCompetition] = _guarantee;
        emit UpdateCompetitionFactory(_p2p, _regular, _guarantee);
    }

    function setTypeToAddress(CompetitionType _type, address _newAddr)
        external
        onlyOwner
    {
        require(_newAddr != address(0), "CF03");
        typeToAddress[_type] = _newAddr;
        emit UpdateTypeToAddress(_type, _newAddr);
    }

    function setSportManager(address _sportManager) external onlyOwner {
        require(_sportManager != address(0), "CF03");
        emit UpdateSportManager(address(sportManager), _sportManager);
        sportManager = ISportManager(_sportManager);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "CF03");
        emit UpdateOracle(oracle, _oracle);
        oracle = _oracle;
    }

    function setLimitOption(uint256 _limit) external onlyOwner {
        limitOption = _limit;
    }

    function setGapvalidationTime(uint256 _gapTime) external onlyOwner {
        regularGapValidatitionTime = _gapTime;
    }

    function setMinimumBetTime(uint256 _minimumBetime) external onlyOwner {
        minimumBetime = _minimumBetime;
    }

    function setP2PDistanceTime(
        uint256 _p2pDistanceAcceptTime,
        uint256 _p2pDistanceConfirmTime,
        uint256 _p2pdistanceVoteTime,
        uint256 _p2pMaximumRefundTime
    ) external onlyOwner {
        p2pDistanceAcceptTime = _p2pDistanceAcceptTime;
        p2pDistanceConfirmTime = _p2pDistanceConfirmTime;
        p2pdistanceVoteTime = _p2pdistanceVoteTime;
        p2pMaximumRefundTime = _p2pMaximumRefundTime;
    }

    function createRegularCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external override returns (address) {
        require(_creator != address(0), "CF03");
        require(sportManager.checkSupportedGame(_sportTypeAlias), "CF01");
        require(_betOptions.length <= limitOption, "CF02");
        address contractAddress = IFactory(
            typeToAddress[CompetitionType.RegularCompetition]
        ).createCompetitionContract(
                msg.sender,
                _creator,
                ICompetitionPool(msg.sender).tokenAddress(),
                ICompetitionPool(msg.sender).fee()
            );

        if (_time.startBetTime < block.timestamp) {
            _time.startBetTime = block.timestamp;
        }

        IRegularCompetitionContract competition = IRegularCompetitionContract(
            contractAddress
        );
        competition.setBasic(
            _time.startBetTime,
            _time.endBetTime,
            _entryFee,
            _minEntrant,
            _time.scheduledStartMatchTime,
            minimumBetime
        );

        competition.setCompetition(
            _competitionId,
            _team1,
            _team2,
            _sportTypeAlias,
            address(sportManager)
        );
        competition.setOracle(oracle);
        competition.setBetOptions(_betOptions);
        competition.setGapvalidationTime(regularGapValidatitionTime);
        return contractAddress;
    }

    function createP2PCompetitionContract(
        address _creator,
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head
    ) external override returns (address) {
        require(_creator != address(0) && _player2 != address(0), "CF03");
        if (block.timestamp > _startBetTime) {
            _startBetTime = block.timestamp;
        }
        IFactory factory = IFactory(
            typeToAddress[CompetitionType.P2PCompetition]
        );
        ICompetitionPool pool = ICompetitionPool(msg.sender);
        address contractAddress = factory.createCompetitionContract(
            address(pool),
            _creator,
            pool.tokenAddress(),
            pool.fee()
        );

        IP2PCompetitionContract competition = IP2PCompetitionContract(
            contractAddress
        );
        if (_startBetTime < block.timestamp) {
            _startBetTime = block.timestamp;
        }
        competition.setStartAndEndTimestamp(
            _startBetTime,
            _startP2PTime - 1,
            _startP2PTime,
            minimumBetime
        );
        uint256 _minEntrant = _head2head ? 0 : 2;
        competition.setBasic(
            _player2,
            _creator,
            _minEntrant,
            _sportTypeAlias,
            address(sportManager),
            _head2head
        );

        competition.setEntryFee(_entryFee);

        competition.setDistanceTime(
            p2pDistanceAcceptTime,
            p2pDistanceConfirmTime,
            p2pdistanceVoteTime,
            p2pMaximumRefundTime
        );
        return contractAddress;
    }

    function createNewGuaranteedCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external override returns (address) {
        require(_creator != address(0), "CF03");
        require(sportManager.checkSupportedGame(_sportTypeAlias), "CF01");

        address contractAddress = IFactory(
            typeToAddress[CompetitionType.GuaranteedCompetition]
        ).createCompetitionContract(
                msg.sender,
                _creator,
                ICompetitionPool(msg.sender).tokenAddress(),
                ICompetitionPool(msg.sender).fee()
            );

        if (_time.startBetTime < block.timestamp) {
            _time.startBetTime = block.timestamp;
        }

        IGuaranteedCompetitionContract(contractAddress).setBasic(
            _time.startBetTime,
            _time.endBetTime,
            _entryFee,
            _entrant.minEntrant,
            _time.scheduledStartMatchTime,
            minimumBetime
        );

        IGuaranteedCompetitionContract(contractAddress)
            .setMaxEntrantAndGuaranteedFee(_guaranteedFee, _entrant.maxEntrant);

        IGuaranteedCompetitionContract(contractAddress).setCompetition(
            _competitionId,
            _team1,
            _team2,
            _sportTypeAlias,
            address(sportManager)
        );
        IGuaranteedCompetitionContract(contractAddress).setOracle(oracle);
        IGuaranteedCompetitionContract(contractAddress).setBetOptions(
            _betOptions
        );
        IGuaranteedCompetitionContract(contractAddress).setGapvalidationTime(
            regularGapValidatitionTime
        );
        return contractAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface Metadata {
    enum Status {
        Lock,
        Open,
        End,
        Refund,
        Non_Eligible
    }
    enum Player {
        NoPlayer,
        Player1,
        Player2
    }

    enum Mode {
        Team,
        Player
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISportManager {
    struct Game {
        uint256 id;
        bool active;
        string name;
        ProviderGameData provider;
    }

    struct Attribute {
        uint256 id;
        bool teamOption;
        AttributeSupportFor attributeSupportFor;
        string name;
    }

    enum ProviderGameData {
        GameScoreKeeper,
        SportRadar
    }

    enum AttributeSupportFor {
        None,
        Team,
        Player,
        All
    }

    event AddNewGame(uint256 indexed gameId, string name);
    event DeactiveGame(uint256 indexed gameId);
    event ActiveGame(uint256 indexed gameId);
    event AddNewAttribute(uint256 indexed attributeId, string name);

    function getGameById(uint256 id) external view returns (Game memory);

    function addNewGame(
        string memory name,
        bool active,
        ProviderGameData provider
    ) external returns (uint256 gameId);

    function deactiveGame(uint256 gameId) external;

    function activeGame(uint256 gameId) external;

    function addNewAttribute(Attribute[] calldata attribute) external;

    function setSupportedAttribute(
        uint256 gameId,
        uint256[] memory attributeIds,
        bool isSupported
    ) external;

    function checkSupportedGame(uint256 gameId) external view returns (bool);

    function checkSupportedAttribute(uint256 gameId, uint256 attributeId)
        external
        view
        returns (bool);

    function checkTeamOption(uint256 attributeId) external view returns (bool);

    function getAttributeById(uint256 attributeId)
        external
        view
        returns (Attribute calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../metadata/Metadata.sol";
import "./ICompetitionContract.sol";

interface IRegularCompetitionContract is Metadata {
    struct Competition {
        string competitionId;
        string team1;
        string team2;
        uint256 sportTypeAlias;
        uint256 winnerReward;
        bool resulted;
    }

    struct BetOption {
        Mode mode;
        uint256 attribute;
        string id;
        uint256[] brackets;
    }

    event PlaceBet(address indexed buyer, uint256[] brackets, uint256 fee);
    event RequestData(
        bytes32 indexed _requestId,
        string _competitionId,
        string _queryString
    );

    function oracle() external view returns (address);

    function setBasic(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee,
        uint256 _minEntrant,
        uint256 _scheduledStartTime,
        uint256 _minimumBetime
    ) external returns (bool);

    function start() external;

    function setOracle(address _oracle) external;

    function setCompetition(
        string memory _competitionId,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        address _sportManager
    ) external;

    function setGapvalidationTime(uint256 _gapTime) external;

    function getDataToCheckRefund() external view returns (bytes32, uint256);

    function getTicketSell(uint256[] memory _brackets)
        external
        view
        returns (address[] memory);

    function setBetOptions(BetOption[] memory _betOptions) external;

    function setIsResult() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../metadata/Metadata.sol";
import "./ICompetitionContract.sol";

interface IP2PCompetitionContract is Metadata {
    struct Competition {
        address player1;
        address player2;
        uint256 sportTypeAlias;
        Player playerWon;
        uint256 winnerReward;
        bool isAccept;
        bool resulted;
    }

    struct TotalBet {
        uint256 player1;
        uint256 player2;
    }

    struct Confirm {
        bool isConfirm;
        Player playerWon;
    }

    event NewP2PCompetition(
        address indexed player1,
        address indexed player2,
        bool isHead2Head
    );
    event PlaceBet(
        address indexed buyer,
        bool player1,
        bool player2,
        uint256 amount
    );
    event Accepted(address _player2, uint256 _timestamp);
    event P2PEndTime(uint256 endP2PTime);
    event ConfirmResult(address _player, bool _isWinner, uint256 _timestamp);
    event Voted(address bettor, uint256 timestamp);
    event SetResult(Player _player);

    function setBasic(
        address _player2,
        address _player1,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        address _sportManager,
        bool _head2head
    ) external;

    function setEntryFee(uint256 _entryFee) external;

    function setStartAndEndTimestamp(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _minimumBetime
    ) external;

    function setDistanceTime(
        uint256 _p2pDistanceAcceptTime,
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime,
        uint256 _maximumRefundTime
    ) external;

    function acceptBetting(address user) external;

    function submitP2PCompetitionTimeOver() external;

    function confirmResult(bool _isWinner) external;

    function vote(
        address user,
        bool _player1Win,
        bool _player2Win
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../metadata/Metadata.sol";
import "./IRegularCompetitionContract.sol";

interface IGuaranteedCompetitionContract is IRegularCompetitionContract {
    function setMaxEntrantAndGuaranteedFee(
        uint256 _guaranteedFee,
        uint256 _maxEntrant
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFactory {
    function createCompetitionContract(
        address _owner,
        address _creator,
        address _tokenPool,
        uint256 _fee
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICompetitionPool {
    struct Bet {
        address competionContract;
        uint256[] betIndexs;
    }

    struct Pool {
        Type competitonType;
        bool existed;
    }

    enum Type {
        Regular,
        P2P,
        Guarantee
    }

    function fee() external view returns(uint256);

    function tokenAddress() external view returns(address);

    function refundable(address _betting) external view returns (bool);

    function isCompetitionExisted(address _pool) external returns (bool);

    function getMaxTimeWaitForRefunding() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IRegularCompetitionContract.sol";

interface ICompetitionFactory {
    enum CompetitionType {
        P2PCompetition,
        RegularCompetition,
        GuaranteedCompetition
    }

    struct Entrant {
        uint256 minEntrant;
        uint256 maxEntrant;
    }

    struct Time {
        uint256 startBetTime;
        uint256 endBetTime;
        uint256 scheduledStartMatchTime;
    }

    event UpdateSportManager(address _old, address _new);
    event UpdateOracle(address _old, address _new);
    event UpdateCompetitionFactory(
        address _p2p,
        address _regular,
        address _guarantee
    );
    event UpdateTypeToAddress(CompetitionType _type, address _newAddr);

    function createRegularCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (address);

    function createP2PCompetitionContract(
        address _creator,
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head
    ) external returns (address);

    function createNewGuaranteedCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../metadata/Metadata.sol";

interface ICompetitionContract is Metadata {
    event Ready(
        uint256 timestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event Close(uint256 timestamp, uint256 winnerReward);

    function getEntryFee() external view returns (uint256);

    function getFee() external view returns (uint256);

    function placeBet(
        address user,
        uint256[] memory betIndexs
    ) external;

    function distributedReward() external;
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