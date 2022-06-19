/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity ^0.4.23;

contract Lottery {
    address[3] cormorants;
    uint8 Count = 0;
    uint nonce = 0;
    uint participantsCount = 0;

    function draw() public payable {
        require(msg.value == 0.01 ether);
        require(participantsCount < 3);
        require(drawSituation(msg.sender) == false);
        cormorants[Count] = msg.sender;
        Count++;
        if (Count == 3) {
            produceWinner();
        }
    }

    function drawSituation(address _cormorant) private view returns(bool) {
        bool contains = false;
        for(uint i = 0; i < 3; i++) {
            if (cormorants[i] == _cormorant) {
                contains = true;
            }
        }
        return contains;
    }
    
    function produceWinner() private returns(address) {
        require(Count == 3);
        address winner = cormorants[winnerNumber()];
        winner.transfer(address(this).balance);
        delete cormorants;
        Count = 0;
        return winner;
    }
    
    function winnerNumber() private returns(uint) {
        uint winner = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 3;
        nonce++;
        return winner;
    }
}