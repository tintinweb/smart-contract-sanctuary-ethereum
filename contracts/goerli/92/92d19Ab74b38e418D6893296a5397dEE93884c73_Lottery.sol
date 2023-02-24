//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract Lottery{

    uint256 totalParticipants;
    address payable public Winner;
    uint256 priceMoney;

    struct WinnerDetails{
        address _address;
        uint256 _total;
    }

    mapping(address => uint256) funders;
    address[]players;

    function addCustomers()public payable{
        funders[msg.sender] += msg.value;
        players.push(msg.sender);
    }

    function getTotalParticipants()public view returns(uint256){
        return players.length;
    }

    function generateWinner() public payable{
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty)));
        uint256 range = players.length;
        uint256 randomNumber = (random % range); 

        Winner = payable(players[randomNumber]);
        Winner.transfer(address(this).balance);


        for(uint256 i=0; i<players.length; i++){
            address a1 = players[i];
            priceMoney += funders[a1];
            funders[a1] = 0;
        }
        players = new address [](0);
        

        (bool success,) = payable(msg.sender).call{value:address(this).balance}("");       
        require(success, "Call failed");
    }

    // function showWinner()public view returns(WinnerDetails memory){
    //     return WinnerDetails(Winner,priceMoney);
    // }
}