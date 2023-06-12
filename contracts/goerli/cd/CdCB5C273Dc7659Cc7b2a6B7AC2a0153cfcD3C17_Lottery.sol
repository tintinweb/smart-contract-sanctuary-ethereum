// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Lottery is Ownable, Pausable {
    uint256 public currentRound;
    mapping(uint256 => uint256) public totalDepositPerRound;
    mapping(uint256 => bool) public prizeClaimed;
    mapping(address => uint256) public balances;
    mapping(uint256 => bool) public winnerSelected;
    mapping(uint256 => address[]) public roundParticipants;
    uint8 public prizePercentage;
    uint256 public maxParticipant;
    uint256 public minDeposit;
    uint256 public ticketPrice;
    uint256 public countdownDuration;
    uint256 public countdownEnd;
    uint256 public totalTickets;
    address payable public teamAddress;
    address[] public participants;
    address public selectWinnerAddress;

    struct RoundResult {
        uint256 round;
        address winner;
        uint256 prize;
    }

    mapping(uint256 => RoundResult) public roundResults;

    event Deposit(address indexed depositor, uint256 amount, uint256 tickets, uint256 round);
    event WinnerSelected(address winner, uint256 round, uint256 prize);
    event PrizeClaimed(address claimer, uint256 round, uint256 prize);
    event CountdownStarted(uint256 round, uint256 countdownEnd);

    constructor(
        uint256 _maxParticipant,
        uint256 _countdownDuration,
        uint8 _prizePercentage,
        address payable _teamAddress,
        address payable _selectWinnerAddress,
        uint256 _minDeposit,
        uint256 _ticketPrice
    ) {
        require(_prizePercentage <= 100, "Total percentage should not exceed 100");
        maxParticipant = _maxParticipant;
        countdownDuration = _countdownDuration;
        prizePercentage = _prizePercentage;
        teamAddress = _teamAddress;
        selectWinnerAddress = _selectWinnerAddress;
        minDeposit = _minDeposit;
        ticketPrice = _ticketPrice;
        currentRound = 1;
    }

    modifier onlyOwnerOrSelectWinnerAddress() {
        require(msg.sender == owner() || msg.sender == selectWinnerAddress, "Caller is not the owner or the selectWinnerAddress");
        _;
    }

    function _startCountdown() private {
        require(countdownDuration != 0, "Please set the countdown duration first");
        countdownEnd = block.timestamp + countdownDuration;
        emit CountdownStarted(currentRound, countdownEnd);
    }

    function startCountdown() public onlyOwner whenNotPaused {
        _startCountdown();
    }

    function deposit() public payable whenNotPaused {
        require(!paused(), "Contract is paused.");
        require(msg.value >= minDeposit, "The sent amount is less than the minimum deposit");

        bool isFirstDeposit = totalDepositPerRound[currentRound] == 0;

        uint256 previousCountdownEnd = countdownEnd;

        uint256 tickets = msg.value / ticketPrice;
        balances[msg.sender] += tickets;
        totalTickets += tickets;

        totalDepositPerRound[currentRound] += msg.value;

        emit Deposit(msg.sender, msg.value, tickets, currentRound);

        if (participants.length == maxParticipant && previousCountdownEnd > block.timestamp) {
            revert("The maximum number of participants has been reached. Cannot deposit anymore.");
        }

        if (isFirstDeposit) {
            _startCountdown();
        } else if (previousCountdownEnd > 0) {
            require(block.timestamp <= countdownEnd, "The countdown has ended");
        }

        participants.push(msg.sender);
        roundParticipants[currentRound].push(msg.sender);

        if (participants.length == maxParticipant) {
            _selectWinner();
        }
    }

    function _selectWinner() private whenNotPaused {
        require(msg.sender == owner() || participants.length >= maxParticipant || block.timestamp >= countdownEnd, "The owner or the countdown has to trigger this");
        require(participants.length > 0, "There are no participants in the lottery yet");

        uint256 randomTicket = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))) % totalTickets;
        address winner;
        uint256 count = 0;
        for(uint i=0; i<participants.length; i++){
            count += balances[participants[i]];
            if(count >= randomTicket){
                winner = participants[i];
                break;
            }
        }

        uint256 prize = totalDepositPerRound[currentRound] * prizePercentage / 100;
        uint256 teamPrize = totalDepositPerRound[currentRound] - prize;

        // Send the team prize immediately
        (bool success, ) = payable(teamAddress).call{value: teamPrize}("");
        require(success, "Team prize transfer failed.");

        roundResults[currentRound] = RoundResult({
            round: currentRound,
            winner: winner,
            prize: prize
        });

        emit WinnerSelected(winner, currentRound, prize);

        for (uint i = 0; i < participants.length; i++) {
            delete balances[participants[i]];
        }

        delete participants;
        totalTickets = 0;
        countdownEnd = 0;
        winnerSelected[currentRound] = true;
        currentRound++;
    }

    function selectWinner() public onlyOwnerOrSelectWinnerAddress whenNotPaused {
        _selectWinner();
    }

    function claimPrizes(uint256 round) public {
        require(roundResults[round].prize > 0, "No unclaimed prize for this round");
        require(msg.sender == roundResults[round].winner, "You are not the winner of this round");
        require(!prizeClaimed[round], "Prize for this round has already been claimed");

        uint256 prize = roundResults[round].prize;
        roundResults[round].prize = 0;
        prizeClaimed[round] = true;

        (bool success, ) = payable(msg.sender).call{value: prize}("");
        require(success, "Prize transfer failed.");

        emit PrizeClaimed(msg.sender, round, prize);
    }

    function getParticipantsCount() public view returns (uint256) {
        return participants.length;
    }

    function getParticipants(uint256 round) public view returns (address[] memory) {
        return roundParticipants[round];
    }

    function getTimeLeft() public view returns (uint256) {
        if (block.timestamp > countdownEnd) {
            return 0; // Countdown has ended
        }
        return countdownEnd - block.timestamp;
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function resumeContract() public onlyOwner {
        _unpause();
    }

    function setMaxParticipant(uint256 _maxParticipant) public onlyOwner {
        maxParticipant = _maxParticipant;
    }

    function setCountdownDuration(uint256 _countdownDuration) public onlyOwner {
        countdownDuration = _countdownDuration;
    }

    function setPrizePercentage(uint8 _prizePercentage) public onlyOwner {
        prizePercentage = _prizePercentage;
    }

    function setTeamAddress(address payable _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }

    function setSelectWinnerAddress(address _selectWinnerAddress) public onlyOwner {
        selectWinnerAddress = _selectWinnerAddress;
    }

    function setMinDeposit(uint256 _minDeposit) public onlyOwner {
        minDeposit = _minDeposit;
    }

    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function updateRoundData(uint256 _round, uint256 _totalDeposit, bool _prizeClaimed, bool _winnerSelected, uint256 _totalTickets, address[] memory _participants, uint256 _countdownEnd) public onlyOwner {
        totalDepositPerRound[_round] = _totalDeposit;
        prizeClaimed[_round] = _prizeClaimed;
        winnerSelected[_round] = _winnerSelected;
        totalTickets = _totalTickets;
        participants = _participants;
        countdownEnd = _countdownEnd;
    }

    function emergencyWithdraw() public onlyOwner whenPaused {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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