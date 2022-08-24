// SPDX-License-Identifier: UNLICENSED
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "../interfaces/IRandomNumberGenerator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BIXCIPLottery {
    address payable[] public players;
    mapping(address => uint256[]) playerBets;
    mapping(address => uint256[]) playerWins;
    uint256 public lotteryId;
    mapping(uint256 => address) public lotteryHistory;
    IRandomNumberGenerator randomNumberGenerator;
    uint256[] public s_randomWords;
    address s_owner;
    uint256 public ticketFee = 0.01 ether;
    address payable[] public winners;
    enum LotteryState {
        OPEN,
        CLOSED
    }
    uint256 public prizeMoney;

    LotteryState lotteryState;

    constructor(address _randomNumberGeneratorAddress, uint256 _prizeMoney) {
        s_owner = msg.sender;
        prizeMoney = _prizeMoney;
        lotteryId = 1;
        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );
        randomNumberGenerator.requestRandomWords();
        startLottery();
    }

    function getWinnerByLottery(uint256 lottery) public view returns (address) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getRandomNumbers() public view returns (uint256[] memory) {
        return s_randomWords;
    }

    function enter(uint256[] memory _bets) public payable {
        uint256 totalTickets = _bets.length;
        require(
            msg.value >= (0.01 ether * totalTickets),
            "Insufficient amount"
        );

        require(lotteryState == LotteryState.OPEN, "The lottery is closed");

        uint256[] storage previousBets = playerBets[msg.sender];

        while (totalTickets > 0) {
            uint256 value = _bets[totalTickets - 1];
            previousBets.push(value);
            players.push(payable(msg.sender));
            totalTickets--;
        }
        playerBets[msg.sender] = previousBets;
    }

    function getPlayerBets(address _player)
        public
        view
        returns (uint256[] memory)
    {
        return playerBets[_player];
    }

    function getPlayerWins(address _player)
        public
        view
        returns (uint256[] memory)
    {
        return playerWins[_player];
    }

    function getTicketFee() public view returns (uint256) {
        return ticketFee;
    }

    function setTicketFee(uint256 _ticketFee) public onlyOwner {
        ticketFee = _ticketFee;
    }

    function pickWinners() public onlyOwner {
        s_randomWords = randomNumberGenerator.getRandomWords();
        require(
            s_randomWords.length > 0,
            "Random numbers have not yet been generated"
        );
        for (uint96 i = 0; i < s_randomWords.length; i++) {
            uint256 randomResult = s_randomWords[i];
            uint256 index = randomResult % players.length;
            winners.push(players[index]);

            uint256[] memory previousWins = playerWins[players[index]];
            uint256[] storage newWins = playerBets[players[index]];

            for (uint256 j = 0; j < previousWins.length; j++) {
                newWins.push(previousWins[j]);
            }
            playerWins[players[index]] = newWins;
        }
        payWinners();
    }

    function payWinners() internal {
        require(
            s_randomWords.length > 0,
            "BIXCIPLottery: The random number has not yet been generated"
        );

        for (uint96 i = 0; i < winners.length; i++) {
            uint256 amount = prizeMoney / winners.length;
            winners[i].transfer(amount);
            lotteryHistory[lotteryId] = winners[i];
            lotteryId++;
        }

        // reset the state of the contract
        for (uint96 i = 0; i < players.length; i++) {
            delete playerBets[players[i]];
        }
        players = new address payable[](0);
        winners = new address payable[](0);
        s_randomWords = new uint256[](0);
        closeLottery();
    }

    function startLottery() public onlyOwner {
        lotteryState = LotteryState.OPEN;
    }

    function closeLottery() public onlyOwner {
        lotteryState = LotteryState.CLOSED;
    }

    function getLotteryState() public view returns (LotteryState) {
        return lotteryState;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IRandomNumberGenerator {
    function requestRandomWords() external;

    function getRandomWords() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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