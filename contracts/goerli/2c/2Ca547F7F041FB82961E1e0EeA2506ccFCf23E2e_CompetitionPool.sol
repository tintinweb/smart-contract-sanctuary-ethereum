// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/ICompetitionFactory.sol";
import "./interface/IRegularCompetitionContract.sol";
import "./interface/IGuaranteedCompetitionContract.sol";
import "./interface/IChainLinkOracleSportData.sol";
import "./interface/IP2PCompetitionContract.sol";
import "./interface/ICompetitionContract.sol";
import "./interface/ICompetitionPool.sol";
import "./metadata/Metadata.sol";

/*
CP01: Pool not found
CP02: Only P2P
CP03: Address 0x00
CP04: Payment token is not exist or supported

*/

contract CompetitionPool is
    Ownable,
    ReentrancyGuard,
    Metadata,
    ICompetitionPool
{
    using SafeERC20 for IERC20;

    address[] public paymentTokenAddresses;
    mapping(address => PaymentToken) public paymentToken;
    ICompetitionFactory public competitionFactory;

    address[] public pools;
    mapping(address => address) public creator;
    mapping(address => Pool) public existed;

    uint256 private maxTimeWaitForRefunding = 24 hours;

    constructor(
        address _competitionFactory,
        address[] memory _paymentTokenAddresses,
        uint256[] memory _fee
    ) {
        require(_competitionFactory != address(0), "CP03");
        competitionFactory = ICompetitionFactory(_competitionFactory);
        paymentTokenAddresses = _paymentTokenAddresses;
        for(uint256 i = 0; i<_paymentTokenAddresses.length; i++){
            address _paymentTokenAddress = _paymentTokenAddresses[i];
            require(_paymentTokenAddress != address(0), "CP03");
            paymentToken[_paymentTokenAddress] = PaymentToken(_paymentTokenAddress, _fee[i], true);
        }
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool].existed, "CP01");
        _;
    }

    modifier onlyP2P(address _p2pCompetition) {
        require(existed[_p2pCompetition].competitonType == Type.P2P, "CP02");
        _;
    }

    // <Admin features>
    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "CP03");
        competitionFactory = ICompetitionFactory(_factory);
        emit Factory(_factory);
    }

    function addPaymentToken(address[] memory _tokenAddresses, uint256[] memory _fee) external onlyOwner {
        for(uint256 i=0; i<_tokenAddresses.length; i++){
            address _tokenAddress = _tokenAddresses[i];
            PaymentToken storage _paymentToken = paymentToken[_tokenAddress];
            require(
                _tokenAddress != address(0) && 
                !_paymentToken.isActive &&
                _paymentToken.tokenAddress == address(0), 
                "CP03 & CP04"
            );
            paymentTokenAddresses.push(_tokenAddress);
            _paymentToken.tokenAddress = _tokenAddress;
            _paymentToken.fee = _fee[i];
            _paymentToken.isActive = true;
            emit AddPaymentToken(_tokenAddress, _fee[i]);
        }
    }

    function updatePaymentToken(address _tokenAddress, uint256 _fee, bool _isActive) external onlyOwner {
        PaymentToken storage _paymentToken = paymentToken[_tokenAddress];
        require(
            _paymentToken.tokenAddress != address(0), 
            "CP04"
        );
        _paymentToken.tokenAddress = _tokenAddress;
        _paymentToken.fee = _fee;
        _paymentToken.isActive = _isActive;
        emit UpdatePaymentToken(_tokenAddress, _fee, _isActive);
    }

    function setMaxTimeWaitForRefunding(uint256 _time) external onlyOwner {
        emit MaxTimeWaitFulfill(maxTimeWaitForRefunding, _time);
        maxTimeWaitForRefunding = _time;
    }

    function withdrawToken(
        address _token_address,
        address _receiver,
        uint256 _value
    ) external onlyOwner nonReentrant {
        IERC20(_token_address).safeTransfer(_receiver, _value);
    }

    // </Admin features>

    // <Bettor features>
    function betSlip(Bet[] memory _betSlipList) external nonReentrant {
        for (uint256 i = 0; i < _betSlipList.length; i++) {
            _placeBet(
                msg.sender,
                _betSlipList[i].competionContract,
                _betSlipList[i].betIndexs
            );
        }
    }

    function acceptP2P(address _p2pCompetition)
        external
        onlyP2P(_p2pCompetition)
        nonReentrant
    {
        address _paymentTokenAddress = ICompetitionContract(_p2pCompetition).tokenAddress();
        uint256 fee = getFee(_paymentTokenAddress);
        IERC20(_paymentTokenAddress).safeTransferFrom(msg.sender, _p2pCompetition, fee);
        IP2PCompetitionContract(_p2pCompetition).acceptBetting(msg.sender);
    }

    function voteP2P(
        address _p2pCompetition,
        bool _player1Win,
        bool _player2Win
    ) external onlyP2P(_p2pCompetition) nonReentrant {
        address _paymentTokenAddress = ICompetitionContract(_p2pCompetition).tokenAddress();
        uint256 fee = getFee(_paymentTokenAddress);
        IERC20(_paymentTokenAddress).safeTransferFrom(msg.sender, _p2pCompetition, fee);
        IP2PCompetitionContract(_p2pCompetition).vote(
            msg.sender,
            _player1Win,
            _player2Win
        );
    }

    // </Bettor features>

    // <Creator features>
    function createNewRegularCompetition(
        ICompetitionFactory.Competition memory _competitionInfo,
        ICompetitionFactory.Time memory _time,
        uint256 _entryFee,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions,
        address _paymentTokenAddress
    ) external nonReentrant {
        PaymentToken memory _paymentToken = paymentToken[_paymentTokenAddress];
        require(_paymentToken.isActive, "CP04");
        address competitionContract = competitionFactory
            .createRegularCompetitionContract(
                msg.sender,
                _competitionInfo,
                _time,
                _entryFee,
                _minEntrant,
                _sportTypeAlias,
                _betOptions,
                _paymentTokenAddress
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.Regular, true);
        creator[competitionContract] = msg.sender;
        uint256 fee = getFee(_paymentTokenAddress);
        emit CreatedNewRegularCompetition(msg.sender, competitionContract, fee);
        IERC20(_paymentTokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee
        );
        IRegularCompetitionContract(competitionContract).start();
    }

    function createNewGuaranteedCompetition(
        ICompetitionFactory.Competition memory _competitionInfo,
        ICompetitionFactory.Time memory _time,
        uint256 _entryFee,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        ICompetitionFactory.Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions,
        address _paymentTokenAddress
    ) external nonReentrant {
        PaymentToken memory _paymentToken = paymentToken[_paymentTokenAddress];
        require(_paymentToken.isActive, "CP04");
        address competitionContract = competitionFactory
            .createNewGuaranteedCompetitionContract(
                msg.sender,
                _competitionInfo,
                _time,
                _entryFee,
                _sportTypeAlias,
                _guaranteedFee,
                _entrant,
                _betOptions,
                _paymentTokenAddress
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.Guarantee, true);
        creator[competitionContract] = msg.sender;
        uint256 fee = getFee(_paymentTokenAddress);
        IERC20(_paymentTokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee + _guaranteedFee
        );
        IGuaranteedCompetitionContract(competitionContract).start();
        emit CreatedNewGuaranteedCompetition(
            msg.sender,
            competitionContract,
            fee + _guaranteedFee
        );
    }

    function createNewP2PCompetition(
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head,
        address _paymentTokenAddress
    ) external nonReentrant {
        PaymentToken memory _paymentToken = paymentToken[_paymentTokenAddress];
        require(_paymentToken.isActive, "CP04");
        address competitionContract = competitionFactory
            .createP2PCompetitionContract(
                msg.sender,
                _player2,
                _entryFee,
                _startBetTime,
                _startP2PTime,
                _sportTypeAlias,
                _head2head,
                _paymentTokenAddress
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.P2P, true);
        creator[competitionContract] = msg.sender;
        uint256 fee = getFee(_paymentTokenAddress);
        IERC20(_paymentTokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee
        );
        emit CreatedNewP2PCompetition(msg.sender, competitionContract, fee);
    }

    // </Creator features>

    // <View functions>
    function refundable(address _regular)
        external
        view
        override
        returns (bool)
    {
        IRegularCompetitionContract betting = IRegularCompetitionContract(
            _regular
        );
        (bytes32 _resultId, uint256 _priceValidationTimestamp) = betting
            .getDataToCheckRefund();
        if (
            block.timestamp >
            (_priceValidationTimestamp + maxTimeWaitForRefunding) &&
            !IChainLinkOracleSportData(betting.oracle()).checkFulfill(_resultId)
        ) return true; //refund

        return false; //don't refund
    }

    function isCompetitionExisted(address _pool)
        external
        view
        override
        returns (bool)
    {
        return existed[_pool].existed;
    }

    function getMaxTimeWaitForRefunding()
        external
        view
        override
        returns (uint256)
    {
        return maxTimeWaitForRefunding;
    }

    function getFee(address _tokenAddress) public override view returns(uint256){
        PaymentToken memory _paymentToken = paymentToken[_tokenAddress];
        require(
            _tokenAddress != address(0) &&
            _paymentToken.tokenAddress != address(0),
            "CP03"
        );
        return _paymentToken.fee;
    }

    function getPaymentTokenAddresses() external override view returns(PaymentToken[] memory _paymentTokenList, uint256 _size){
        _paymentTokenList = new PaymentToken[](paymentTokenAddresses.length);
        _size=0;
        for(uint256 i = 0; i< paymentTokenAddresses.length; i++){
            address paymentTokenAddress = paymentTokenAddresses[i];
            PaymentToken memory _paymentToken = paymentToken[paymentTokenAddress];
            if (_paymentToken.isActive) {
                _paymentTokenList[_size] = _paymentToken;
                _size++;
            }
        }
        return (_paymentTokenList, _size);
    }

    // </View functions>

    // <Internal function>
    function _placeBet(
        address _user,
        address _competitionContract,
        uint256[] memory betIndexs
    ) private onlyExistedPool(_competitionContract) {
        ICompetitionContract competitionContract = ICompetitionContract(
            _competitionContract
        );
        uint256 totalFee = competitionContract.getEntryFee() +
            competitionContract.getFee();
        address _paymentTokenAddress = ICompetitionContract(_competitionContract).tokenAddress();
        IERC20(_paymentTokenAddress).safeTransferFrom(
            _user,
            _competitionContract,
            totalFee
        );
        competitionContract.placeBet(_user, betIndexs);
    }
    // </Internal function>
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

interface ICompetitionPool {
    struct Bet {
        address competionContract;
        uint256[] betIndexs;
    }

    struct Pool {
        Type competitonType;
        bool existed;
    }

    struct PaymentToken{
        address tokenAddress;
        uint256 fee;
        bool isActive;
    }

    enum Type {
        Regular,
        P2P,
        Guarantee
    }

    event CreatedNewRegularCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event CreatedNewP2PCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event CreatedNewGuaranteedCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event Factory(address _factory);
    event UpdatePaymentToken(address _paymentTokenAddress, uint256 _fee, bool _isActive);
    event AddPaymentToken(address _paymentTokenAddress, uint256 _fee);
    event MaxTimeWaitFulfill(uint256 _old, uint256 _new);

    function getFee(address _tokenAddress) external view returns(uint256);

    function getPaymentTokenAddresses() external view returns(PaymentToken[] memory _paymentTokenList, uint256 _size);

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

    struct Competition{
        string competitionId;
        string team1;
        string team2;
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
        ICompetitionFactory.Competition memory _competitionInfo,
        Time memory _time,
        uint256 _entryFee,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions,
        address _paymentTokenAddress
    ) external returns (address);

    function createP2PCompetitionContract(
        address _creator,
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head,
        address _paymentTokenAddress
    ) external returns (address);

    function createNewGuaranteedCompetitionContract(
        address _creator,
        Competition memory _competitionInfo,
        Time memory _time,
        uint256 _entryFee,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions,
        address _paymentTokenAddress
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

    function tokenAddress() external view returns(address);

    function getEntryFee() external view returns (uint256);

    function getFee() external view returns (uint256);

    function placeBet(
        address user,
        uint256[] memory betIndexs
    ) external;

    function distributedReward() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../metadata/Metadata.sol";
import "../interface/IRegularCompetitionContract.sol";

interface IChainLinkOracleSportData {
    function getPayment() external returns (uint256);

    function requestData(
        string memory _matchId,
        uint256 sportId,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external returns (bytes32);

    function getData(bytes32 _id)
        external
        view
        returns (uint256[] memory, address);

    function checkFulfill(bytes32 _requestId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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