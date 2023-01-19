// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

error CoinFlip__Unauthorized();
error CoinFlip__BetSize();
error CoinFlip__BetWithYourself();
error CoinFlip__SendBetPrize();
error CoinFlip__Withdrawal();
error CoinFlip__UnauthorizedBetOwner();

/**
 * @notice flip a coin
 */
contract CoinFlip {
    // state variables
    address private immutable i_owner;
    uint256 private s_collectedProtocolFee = 0;
    uint8 private constant PROTOCOL_FEE_PERCENTAGE = 5;
    uint16[7] public ALLOWED_BETS = [1, 5, 10, 50, 100];
    mapping(uint256 => address) private s_lobby;

    // events
    event WaitingInLobby(uint256 _bet);
    event WinnerPicked(address indexed _playerAddress, uint256 _prize);
    event PlayerWithdrewBet(uint256 _bet);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert CoinFlip__Unauthorized();
        }
        _;
    }

    modifier onlyBetOwner(uint256 _bet) {
        if (msg.sender != s_lobby[_bet]) {
            revert CoinFlip__UnauthorizedBetOwner();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @notice players deposit bets to flip a coin
     * @return true if found a player and flipped, false then wait in the lobby
     */
    function flip() public payable returns (bool) {
        uint256 bet = msg.value;
        address lobbyPlayer = s_lobby[bet];
        address currentPlayer = msg.sender;

        if (lobbyPlayer == currentPlayer) {
            revert CoinFlip__BetWithYourself();
        }

        // check for valid bet size
        bool betSizeAllowed = false;
        for (uint256 i = 0; i < ALLOWED_BETS.length; i++) {
            if (uint256(ALLOWED_BETS[i]) * (10 ** 17) == bet) {
                betSizeAllowed = true;
                break;
            }
        }
        if (!betSizeAllowed) {
            revert CoinFlip__BetSize();
        }

        // if already in lobby, bet with existing person in lobby
        if (lobbyPlayer != address(0)) {
            // determine winner of winning flip
            address winnerAddress = headsOrTails(lobbyPlayer)
                ? lobbyPlayer
                : currentPlayer;

            // update collected fee
            uint256 fee = ((bet * 2) * PROTOCOL_FEE_PERCENTAGE) / 100;
            s_collectedProtocolFee += fee;

            // calculate prize pool deducted by fee
            uint256 prize = bet * 2 - fee;

            // send funds to winner
            (bool sent, ) = payable(winnerAddress).call{value: prize}("");
            if (!sent) {
                revert CoinFlip__SendBetPrize();
            }

            // notify winner
            emit WinnerPicked(winnerAddress, prize);

            // reset lobby
            s_lobby[bet] = address(0);
            return true;
        } else {
            // notify waiting in lobby
            emit WaitingInLobby(bet);

            // store player address in lobby
            s_lobby[bet] = currentPlayer;
            return false;
        }
    }

    /**
     * @notice generates random head or tail
     * @return 0 for head, 1 for tail
     */
    function headsOrTails(address _playerAddress) private view returns (bool) {
        uint256 val = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    _playerAddress
                )
            )
        ) % 2;
        return val == 0;
    }

    /**
     * @notice withdraws contract balance
     */
    function withdraw() public payable onlyOwner {
        (bool sent, ) = payable(i_owner).call{value: address(this).balance}("");
        if (!sent) {
            revert CoinFlip__Withdrawal();
        }
    }

    /**
     * @notice withdraws contract fee balance
     */
    function withdrawProtocolFee() public payable onlyOwner {
        (bool sent, ) = payable(i_owner).call{value: s_collectedProtocolFee}(
            ""
        );
        if (!sent) {
            revert CoinFlip__Withdrawal();
        }
        s_collectedProtocolFee = 0;
    }

    /**
     * @notice withdraws bet for bet owners
     */
    function withdrawBet(uint256 _bet) public payable onlyBetOwner(_bet) {
        (bool sent, ) = payable(msg.sender).call{value: _bet}("");
        if (!sent) {
            revert CoinFlip__Withdrawal();
        }
        s_lobby[_bet] = address(0);
        emit PlayerWithdrewBet(_bet);
    }

    receive() external payable {}

    fallback() external payable {}

    // getters
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getCollectedProtocolFee() public view returns (uint256) {
        return s_collectedProtocolFee;
    }

    function getProtocolFee() public pure returns (uint8) {
        return PROTOCOL_FEE_PERCENTAGE;
    }

    function getAddressByBet(uint256 _bet) public view returns (address) {
        return s_lobby[_bet];
    }
}