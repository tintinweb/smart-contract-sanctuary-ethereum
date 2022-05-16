pragma solidity ^0.8.13;

contract Lottery {
    uint256 private immutable solution;

    event Win(address indexed player, uint256 answer, uint256 prize);
    event Lose(address indexed player, uint256 submit);

    constructor() {
        solution = 1;
    }

    function bet(uint256 _answer) external payable {
        uint256 stake = msg.value;
        require(stake > 0.01 ether, "too low");
        if(_answer == solution) {
            uint256 prize = address(this).balance;
            msg.sender.call{value : prize}("");
            emit Win(msg.sender, _answer, prize);
        } else {
            emit Lose(msg.sender, _answer);
        }
    }
}