pragma solidity ^0.8.13;

contract Lottery {
    string private solution;

    event Win(address indexed player, string answer, uint256 prize);
    event Lose(address indexed player, string submit);

    constructor() {
        solution = "answer";
    }

    function bet(string memory _answer) external payable {
        uint256 stake = msg.value;
        require(stake > 0.01 ether, "too low");
        if(keccak256(abi.encodePacked(_answer)) == keccak256(abi.encodePacked(solution))) {
            uint256 prize = address(this).balance;
            msg.sender.call{value : prize}("");
            emit Win(msg.sender, _answer, prize);
        } else {
            emit Lose(msg.sender, _answer);
        }
    }
}