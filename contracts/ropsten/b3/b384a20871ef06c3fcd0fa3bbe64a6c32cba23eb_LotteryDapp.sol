/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity =0.8.14;
contract LotteryDapp {
    address public admin;
    address payable [] public players;
    
    function Lottery() public {
        admin = msg.sender;
    }
    
    function register() public payable {
        require(msg.value >= 1 ether);
        players.push(payable(msg.sender));
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }
    
    modifier restricted() {
        require(msg.sender == admin);
        _;
    }
    
    function getPlayers() public view returns (address[] memory) {
        address [] memory playerList;
        for(uint i=0; i < players.length; i++) {
           playerList[i] = players[i];
        }
        return playerList;
    }
}