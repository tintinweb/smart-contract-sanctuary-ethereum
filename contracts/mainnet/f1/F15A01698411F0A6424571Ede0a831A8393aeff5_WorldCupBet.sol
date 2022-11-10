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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WorldCupBet {
    // Amount of tokens used for each bet
    uint public immutable FIX_BET_AMOUNT;
    // This timestamp corresponds to 2022-12-03 00:00 UTC
    uint256 constant TOURNAMENT_START = 1670025600;

    struct Bet {
        // Team chosen for the bet
        uint team;
        // True if we already paid the prize to this address
        bool paid;
    }

    IERC20 public immutable token;
    address public owner;

    mapping (address => Bet) public bets; // address => (Team, Paid)
    mapping (uint => uint) betsPerTeam; // Team => Quantity

    bool public winnerTeamDecided = false;
    uint public winnerTeam;
    uint public prizeAmountPerWinner;

    event Betted(address user, uint team);

    // Receives the token address as a parameter
    constructor (IERC20 wDogeAddress, uint betAmount) {
        token = wDogeAddress;
        owner = msg.sender;
        FIX_BET_AMOUNT = betAmount;
    }

    // Modifier to use in functions that only owner can call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function betsAreOpen() public view returns (bool) {
        return block.timestamp < TOURNAMENT_START;
    }

    function assertTeamIsValid(uint256 team) internal pure {
        require(0 < team && team < 33, "Team must be a number between 1 and 32");
    }

    // This function is called to make a bet. The amount is fixed
    function bet(uint team) public {
        assertTeamIsValid(team);
        require(bets[msg.sender].team==0, "You cannot participate twice");
        require(betsAreOpen(), "Bets are closed");

        bets[msg.sender].team = team;
        betsPerTeam[team]++;

        token.transferFrom(msg.sender, address(this), FIX_BET_AMOUNT);

        emit Betted(msg.sender, team);
    }

    // This function can only be called by the owner and sets the winner of the world cup
    function setWinnerTeam(uint team) public onlyOwner {
        assertTeamIsValid(team);
        require(!betsAreOpen(), "Bets must be closed");

        winnerTeamDecided = true;
        winnerTeam = team;
        uint countWinners = betsPerTeam[team];
        if (countWinners!=0) {
            prizeAmountPerWinner = token.balanceOf(address(this)) / countWinners;
        } else {
            prizeAmountPerWinner = 0;
        }
    }

    // This function must be called by each winner to collect their prize
    function collectPrize() public {
        require(winnerTeamDecided, "Winner of the world cup has not been decided yet");
        require(bets[msg.sender].team == winnerTeam, "Unfortunately you have not betted to the winner team");
        require(!bets[msg.sender].paid, "Already paid to you!");
        bets[msg.sender].paid = true;
        token.transfer(msg.sender, prizeAmountPerWinner);
    }

    function getBetsOfAllTeams() external view returns (uint256[32] memory) {
        uint256[32] memory betsOfallTeams;
        for (uint256 i = 1; i <= 32; i++) {
            betsOfallTeams[i - 1] = betsPerTeam[i];
        }
        return betsOfallTeams;
    }
}