// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IP2PCompetitionContract.sol";
import "./CompetitionContract.sol";

/*
PCC01: Player address invalid
PPC02: Time invalid
PCC03: DistanceTime invalid
PCC04: Time was expired
PCC05: Only Player 2
PCC06: Lack of fee
PCC07: Had accepted
PCC08: Only Player1 or Player2
PCC09: Invalid length
PCC10: Invalid index
PCC11: Not enough Fee or EntryFee
PCC12: Only Player1 or Player2
PCC13: Time ivalid
PCC14: Only Player1 and Player2
PCC15: Confirmed
PCC16: Not votable
PCC17: Had resulted
PCC18: Required Open
PCC19: Required Lock
*/

contract P2PCompetitionContract is
    CompetitionContract,
    IP2PCompetitionContract
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    Competition public competition;

    uint256 public startP2PTime;
    uint256 public endP2PTime;
    uint256 public maximumRefundTime;
    bool public head2head;

    uint256 private distanceAcceptTime;
    uint256 private distanceConfirmTime;
    uint256 private distanceVoteTime;

    TotalBet public totalBet;
    mapping(address => bool) public voteResult;
    TotalBet public totalVoteResult;
    mapping(address => Confirm) public confirms;
    mapping(Player => address[]) public ticketSell;

    function getDistanceTime()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (distanceAcceptTime, distanceConfirmTime, distanceVoteTime);
    }

    function setBasic(
        address _player2,
        address _player1,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        address _sportManager,
        bool _head2head
    ) external override onlyConfigurator onlyLock {
        require(_player1 != address(0) && _player2 != address(0), "PCC01");
        require(_player1 != _player2, "PCC01");
        sportManager = ISportManager(_sportManager);
        competition = Competition(
            _player1,
            _player2,
            _sportTypeAlias,
            Player.NoPlayer,
            0,
            false,
            false
        );
        minEntrant = _minEntrant;
        totalFee = fee;
        head2head = _head2head;
        emit NewP2PCompetition(_player1, _player2, head2head);
    }

    function setEntryFee(uint256 _entryFee) external override onlyConfigurator {
        entryFee = _entryFee;
    }

    function setStartAndEndTimestamp(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _minimumBetime
    ) external override onlyConfigurator {
        require(
            block.timestamp <= _startBetTime &&
                _startBetTime + _minimumBetime <= _endBetTime &&
                _endBetTime < _startP2PTime,
            "PPC02"
        );
        startBetTime = _startBetTime;
        endBetTime = _endBetTime;
        startP2PTime = _startP2PTime;
    }

    function setDistanceTime(
        uint256 _distanceAcceptTime,
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime,
        uint256 _maximumRefundTime
    ) external override onlyConfigurator {
        require(_distanceConfirmTime < _distanceVoteTime, "PCC03");
        distanceAcceptTime = _distanceAcceptTime;
        distanceVoteTime = _distanceVoteTime;
        distanceConfirmTime = _distanceConfirmTime;
        maximumRefundTime = _maximumRefundTime;
    }

    function acceptBetting(address player2)
        external
        override
        onlyLock
        onlyOwner
    {
        require(block.timestamp <= startBetTime + distanceAcceptTime, "PCC04");
        require(player2 == competition.player2, "PCC05");
        require(getTotalToken(tokenAddress) >= 2 * fee, "PCC06");
        require(!competition.isAccept, "PCC07");
        competition.isAccept = true;
        totalFee += fee;
        _start();
        emit Accepted(player2, block.timestamp);
    }

    function _start() private {
        status = Status.Open;
        emit Ready(block.timestamp, startBetTime, endBetTime);
    }

    function placeBet(address user, uint256[] memory betIndexs)
        external
        override
        onlyOpen
        betable(user)
        onlyOwner
    {
        if (head2head) {
            require(
                user == competition.player1 || user == competition.player2,
                "PCC08"
            );
        }
        require(betIndexs.length == 1, "PCC09");
        require(betIndexs[0] < 2, "PCC10");
        uint256 totalToken = getTotalToken(tokenAddress);
        uint256 totalEntryFee = (1 + totalBet.player1 + totalBet.player2) *
            entryFee;
        totalFee += fee;
        require(totalToken >= totalEntryFee + totalFee, "PCC11");
        _placeBet(user, betIndexs[0] == 0, betIndexs[0] == 1);
    }

    function _placeBet(
        address user,
        bool player1,
        bool player2
    ) private {
        if (player1) {
            ticketSell[Player.Player1].push(user);
            totalBet.player1++;
        } else {
            ticketSell[Player.Player2].push(user);
            totalBet.player2++;
        }
        listBuyer.push(user);
        betOrNotYet[user] = true;

        emit PlaceBet(user, player1, player2, entryFee + fee);
    }

    function submitP2PCompetitionTimeOver() external override {
        require(
            msg.sender == competition.player1 ||
                msg.sender == competition.player2,
            "PCC12"
        );

        require(block.timestamp > startP2PTime);

        if (endP2PTime == 0) {
            endP2PTime = block.timestamp;
        }

        emit P2PEndTime(endP2PTime);
    }

    function confirmResult(bool _isWinner) external override {
        require(block.timestamp > endP2PTime, "PCC13");
        require(block.timestamp <= endP2PTime + distanceConfirmTime, "PCC13");

        address _player1 = competition.player1;
        address _player2 = competition.player2;
        require(msg.sender == _player1 || msg.sender == _player2, "PCC14");
        require(!confirms[msg.sender].isConfirm, "PCC15");

        if (msg.sender == _player1) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, Player.Player1);
            } else {
                confirms[msg.sender] = Confirm(true, Player.Player2);
            }
        } else if (msg.sender == _player2) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, Player.Player2);
            } else {
                confirms[msg.sender] = Confirm(true, Player.Player1);
            }
        }

        if (confirms[_player1].isConfirm && confirms[_player2].isConfirm) {
            _setResult(_player1, _player2);
        }
        emit ConfirmResult(msg.sender, _isWinner, block.timestamp);
    }

    function _setResult(address _player1, address _player2)
        private
        returns (bool)
    {
        if (confirms[_player1].playerWon == confirms[_player2].playerWon) {
            competition.playerWon = confirms[_player1].playerWon;
            competition.resulted = true;
            emit SetResult(confirms[_player1].playerWon);
            return true;
        }
        return false;
    }

    function voteable(address user) public view returns (bool) {
        if (competition.resulted || !betOrNotYet[user] || voteResult[user]) {
            return false;
        }

        bool enoughEntrant = _checkEntrantCodition();
        if (!enoughEntrant) return false;

        address _player1 = competition.player1;
        address _player2 = competition.player2;
        if (!confirms[_player1].isConfirm || !confirms[_player2].isConfirm) {
            return
                block.timestamp > endP2PTime + distanceConfirmTime &&
                    block.timestamp < endP2PTime + distanceVoteTime
                    ? true
                    : false;
        } else {
            return
                confirms[_player1].playerWon != confirms[_player2].playerWon &&
                    block.timestamp < endP2PTime + distanceVoteTime
                    ? true
                    : false;
        }
    }

    function vote(
        address user,
        bool _player1Win,
        bool _player2Win
    ) external override onlyOwner {
        require(voteable(user), "PCC16");
        require(_player1Win != _player2Win, "PCC16");

        voteResult[user] = true;
        totalFee += fee;

        if (_player1Win) {
            totalVoteResult.player1++;
        } else {
            totalVoteResult.player2++;
        }
        emit Voted(user, block.timestamp);
        uint256 amountBuyer = listBuyer.length;
        if (amountBuyer > 1) {
            if (totalVoteResult.player1 > (amountBuyer / 2)) {
                _setResultAfterVote(Player.Player1);
            }

            if (totalVoteResult.player2 > (amountBuyer / 2)) {
                _setResultAfterVote(Player.Player2);
            }

            if (
                (totalVoteResult.player1 + totalVoteResult.player2) ==
                amountBuyer &&
                totalVoteResult.player1 == totalVoteResult.player2
            ) {
                _setResultAfterVote(Player.NoPlayer);
            }
        } else {
            if (_player1Win) {
                _setResultAfterVote(Player.Player1);
            } else {
                _setResultAfterVote(Player.Player2);
            }
        }
    }

    function _setResultAfterVote(Player _player) private {
        require(!competition.resulted, "PCC17");
        competition.resulted = true;
        competition.playerWon = _player;
        emit SetResult(_player); //success
    }

    function distributedReward() external override nonReentrant{
        if (!competition.isAccept) {
            require(
                block.timestamp >= startBetTime + distanceAcceptTime,
                "PCC18"
            );
        }
        bool enoughEntrant = _checkEntrantCodition();
        if (enoughEntrant) {
            if (competition.isAccept) {
                require(status == Status.Open, "PCC18");
            } else {
                require(status == Status.Lock, "PCC19");
            }
            if (!competition.resulted) {
                if (endP2PTime != 0) {
                    require(block.timestamp > endP2PTime + distanceVoteTime);
                } else {
                    require(block.timestamp > startP2PTime + maximumRefundTime);
                }
            }
        }

        address[] memory winners;
        uint256 ownerReward;
        uint256 winnerReward;
        uint256 totalEntryFee = (totalBet.player1 + totalBet.player2) *
            entryFee;

        if (!enoughEntrant || !competition.resulted) {
            status = Status.Non_Eligible;
            winners = listBuyer;
            winnerReward = totalEntryFee;
            ownerReward = totalFee;
        }
        if (enoughEntrant && competition.resulted) {
            status = Status.End;
            if (competition.playerWon == Player.Player1) {
                winners = ticketSell[Player.Player1];
            } else if (competition.playerWon == Player.Player2) {
                winners = ticketSell[Player.Player2];
            } else {
                winners = listBuyer;
            }

            if (winners.length > 0) {
                winnerReward = totalEntryFee;
                ownerReward = totalFee;
            } else {
                ownerReward = totalFee + totalEntryFee;
            }
        }
        competition.winnerReward = winnerReward;

        if (ownerReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, ownerReward);
        }
        if (winners.length > 0) {
            _sendRewardToWinner(winners, winnerReward);
        }

        uint256 remaining = getTotalToken(tokenAddress);
        if (remaining > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, remaining);
        }

        emit Close(block.timestamp, competition.winnerReward);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interface/ICompetitionContract.sol";
import "../interface/ISportManager.sol";

/*
CC01: No betable
CC02: Only owner
CC03: Only creator
CC04: Only Configurator
CC05: Required NOT start
CC06: Required Open
*/
abstract contract CompetitionContract is ICompetitionContract, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private configurator;
    address public owner;
    address public creator;
    ISportManager public sportManager;
    address public tokenAddress;

    uint256 public totalFee;
    uint256 public minEntrant;
    uint256 internal entryFee;
    uint256 internal fee;

    uint256 public startBetTime;
    uint256 public endBetTime;

    bool public stopBet;
    Status public status = Status.Lock;

    mapping(address => bool) public betOrNotYet;
    address[] public listBuyer;

    function initialize(
        address _owner,
        address _creator,
        address _tokenAddress,
        address _configurator,
        uint256 _fee
    ) public initializer {
        owner = _owner;
        creator = _creator;
        tokenAddress = _tokenAddress;
        fee = _fee;
        configurator = _configurator;
        __ReentrancyGuard_init();
    }

    modifier betable(address user) {
        require(!betOrNotYet[user], "CC01");
        require(!stopBet, "CC01");
        require(
            block.timestamp >= startBetTime && block.timestamp <= endBetTime,
            "CC01"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "CC02");
        _;
    }

    modifier onlyCreator() {
        require(creator == msg.sender, "CC03");
        _;
    }

    modifier onlyConfigurator() {
        require(configurator == msg.sender, "CC04");
        _;
    }

    modifier onlyLock() {
        require(status == Status.Lock, "CC05");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "CC06");
        _;
    }

    function getEntryFee() external view override returns (uint256) {
        return entryFee;
    }

    function getFee() external view override returns (uint256) {
        return fee;
    }

    function toggleStopBet() external onlyCreator {
        stopBet = !stopBet;
    }

    function getTotalToken(address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function _checkEntrantCodition() internal view returns (bool) {
        if (listBuyer.length >= minEntrant) {
            return true;
        } else {
            return false;
        }
    }

    function _sendRewardToWinner(address[] memory winners, uint256 winnerReward)
        internal
    {
        if (winners.length == 0 || winnerReward == 0) return;

        uint256 reward = winnerReward / winners.length;
        for (uint256 i = 0; i < winners.length - 1; i++) {
            IERC20Upgradeable(tokenAddress).safeTransfer(winners[i], reward);
        }

        uint256 remaining = winnerReward - (winners.length - 1) * reward;
        IERC20Upgradeable(tokenAddress).safeTransfer(
            winners[winners.length - 1],
            remaining
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}