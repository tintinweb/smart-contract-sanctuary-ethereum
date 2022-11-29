/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// This is the main building block for smart contracts.
contract Bet {
    address payable public admin;
    bool public paused;
    string public result;
    mapping(address => string) internal _GUESSES_;
    mapping(string => address[]) internal _GUESSES_TO_ACCOUNTS_;

    constructor(address payable _admin) {
        admin = _admin;
    }

    function pauseBetting(bool _paused) external {
        require(msg.sender == admin, "PAUSE_NO_PERMISSION");
        paused = _paused;
    }

    function declareResult(string calldata _result) external {
        require(msg.sender == admin, "PAUSE_NO_PERMISSION");
        result = _result;
    }

    function distributeWinnings() external payable {
        require(msg.sender == admin, "PAUSE_NO_PERMISSION");
        require(bytes(result).length > 0, "RESULT_NOT_SET");

        // save 0.1ETH to pay gas.
        uint256 balance = address(this).balance - 10**17;

        // add admin as a winner.
        addAdminAsWinnerIfNecessary();

        // evenly distribute the money to all winners.
        uint winnerCount = _GUESSES_TO_ACCOUNTS_[result].length;
        uint256 balancePerWinner = balance / winnerCount;
        for (uint i = 0; i < winnerCount; i++) {
            payable(_GUESSES_TO_ACCOUNTS_[result][i]).transfer(balancePerWinner);
        }
    }

    function placeBet(string calldata guess)
        external payable {
        require(bytes(guess).length > 0, "BETTING_EMPTY");
        require(msg.value >= 2 * 10**16, "BETTING_FEE_NOT_ENOUGH");
        require(!paused, "BETTING_PAUSED");
        require(sameString(_GUESSES_[msg.sender], ""), "BETTING_PLACED_ALREADY");
        _GUESSES_[msg.sender] = guess;
        _GUESSES_TO_ACCOUNTS_[guess].push(msg.sender);
    }

    function sameString(string memory s1, string memory s2)
        private pure returns(bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function addAdminAsWinnerIfNecessary() private {
        for (uint i = 0; i < _GUESSES_TO_ACCOUNTS_[result].length; i++) {
            if (_GUESSES_TO_ACCOUNTS_[result][i] == admin) {
                return;
            }
        }

        _GUESSES_TO_ACCOUNTS_[result].push(admin);
    }
}