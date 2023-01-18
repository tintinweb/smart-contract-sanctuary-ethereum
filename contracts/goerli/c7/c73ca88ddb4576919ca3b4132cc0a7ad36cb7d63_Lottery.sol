/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// Lottery Contract where 3 winners are chosen and prize is sent to them in the 
// percentages of 70, 20 , 10 % respectively
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/** 
 * @notice A contract for buying lottery tickets
 * winners gets prize at 70%, 20% 10% respectively
 */
contract Lottery {
    address owner;
    uint256 public ticketPrice;
    address[] public participants;

    event Participated(address participant);
    event Won(address winner, uint256 prize);

    /// @notice Constructor of the contract
    /// @param _ticketPrice Price of buying one ticket
    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Caller is not the Owner");
        _;
    }

    /// @notice A function to buy ticket, must send ticketPrice in msg.value
    function buyTicket() external payable {
        require(msg.value == ticketPrice, "Please send the ticket price");
        participants.push(msg.sender);
        emit Participated(msg.sender);
    }

    /// @notice Function to closeLottery and distribute the prizes
    /// @param _seed[] Array of random string to generate randomness (first three strings will be considered)
    /// example _seed[] = ['first', 'second', 'third']
    function closeLottery(string[] calldata _seed) external onlyOwner {
        uint256 prize = address(this).balance;
        uint8 length = uint8(participants.length);
        for(uint8 i = 0; i <3; i++) {
            uint256 random = _random(length, _seed[i]);
            address _winner = participants[random];
            uint256 amount;
            if(i == 0) amount = prize * 70 / 100;
            else if(i == 1) amount = prize * 20 / 100;
                else if(i == 2) amount = prize * 10 / 100;
            payable(_winner).transfer(amount);
            emit Won(_winner, amount);
        }
        participants = new address[](0);
    }

    /// @notice internal helper function to generate randomness
    /// @param _length to ensure the random number is less than max required
    /// @param _seed random string to generate a random number
    /// @return It returns a random number less than _length
    function _random(uint8 _length, string calldata _seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _seed))) % _length;
    }

}