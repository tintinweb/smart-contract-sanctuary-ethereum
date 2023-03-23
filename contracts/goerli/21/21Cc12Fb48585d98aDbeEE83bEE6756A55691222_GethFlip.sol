// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract GethFlip {
    using SafeMath for uint256;

    address public owner;
    uint public constant MAX_BET = 200 ether;
    uint public constant MIN_BET = 1 ether;
    uint256 public betFee = 3; // 3%
    uint256 public constant PERCENTS_DIVIDER = 100;
    mapping(address => uint256) public betting;
    bool public playGame = true;

    constructor() {
        owner = msg.sender;
    }

    event FLIPCOIN(address from, uint256 amount, uint result, uint40 tm);
    event WITHDRAWFUND(address from, uint256 amount, uint40 tm);

    function flipCoin(uint _prediction) public payable {
        require(playGame, "Users could bet only when game state is true");
        require(msg.value >= MIN_BET && msg.value <= MAX_BET, "You need to input proper bet amount");
        require(_prediction == 0 || _prediction == 1, "bet value should be 0 or 1");
        uint256 balance = address(this).balance;
        require(2 * msg.value <= balance, "Contract balance is not enough to play game");
        require(betting[msg.sender] == 0, "You can bet only once per round");
        betting[msg.sender] = msg.value;

        // Use blockhash of the previous block as random seed
        bytes32 blockHash = blockhash(block.number - 1);
        require(blockHash != 0, "Random number not available yet");
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockHash, msg.sender)));
        uint result = randomNumber % 2;

        if (result == _prediction) { // Win
            uint payout = msg.value.mul(SafeMath.sub(PERCENTS_DIVIDER, betFee)).div(PERCENTS_DIVIDER).mul(2);
            payout = balance > payout ? payout : balance;
            payable(msg.sender).transfer(payout);
        }

        betting[msg.sender] = 0;

        emit FLIPCOIN(msg.sender, msg.value, result, uint40(block.timestamp));
    }

    function withdrawFund() public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint amount = address(this).balance;
        payable(owner).transfer(amount);

        emit WITHDRAWFUND(msg.sender, amount, uint40(block.timestamp));
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner, "Only owner can transfer ownership");
        owner = _newOwner;
    }

    function fundContract() public payable {
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function setBetFee(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set bett fee value");
        require(_fee >= 0 && _fee <=10, "Fee value could be between 0 and 10");
        betFee = _fee;
    }
    
    function playAndPause() public {
        require(msg.sender == owner, "Only owner can play or pause game");
        playGame = !playGame;
    }

    fallback() external {
        revert("Invalid transaction");
    }
}