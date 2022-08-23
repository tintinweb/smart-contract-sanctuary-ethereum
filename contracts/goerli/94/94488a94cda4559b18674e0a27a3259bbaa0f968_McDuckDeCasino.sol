/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;







contract McDuckDeCasino{

    address payable owner;

     constructor() public {
         owner = payable(msg.sender);
     }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
    

    mapping(address => uint) howMuchPlay;

    uint public totalPlay;

    address[] public players;

    event Score(
        bool victory,
        uint amount,
        uint fee,
        uint8 percentage,
        uint firstNumber,
        uint secondNumber,
        uint thirdNumber
    );

    function getTotalPlay() public view returns(uint256){
        return totalPlay;
    }

    function getPlayersLength() public view returns(uint256){
        return players.length;
    }

    function getPlayers() public view returns(address[] memory){
        return players;
    }

    function getContractBalance() public view returns(uint){
    return address(this).balance;
    }

    function getHowMuchPlay() public view returns(uint){
        return howMuchPlay[msg.sender];
    }

    function getHowMuchPlayByAddress(address _address) public view returns(uint){
        return howMuchPlay[_address];
    }

    function fundContract() external payable{
        
    }

    function getRandom(uint mod) public view returns(uint, uint, uint){
        uint firstNumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % mod;
        uint secondNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % mod;
        uint thirdNumber = uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % mod;
        return (firstNumber, secondNumber, thirdNumber);
        
        
    }

    function getPlayCost() public view returns(uint){
        return (getContractBalance() / 100) * 5;
    }

    function play() public payable returns(uint8, uint, uint, uint){
        uint totalJackpot = getContractBalance();
        if (totalJackpot >= 5800000000000000 && msg.value >= getPlayCost()){
            if(getHowMuchPlayByAddress(msg.sender) == 0){
                players.push(msg.sender);
            }
            howMuchPlay[msg.sender] += 1;
            totalPlay += 1;  
            (uint firstNumber, uint secondNumber, uint thirdNumber) = getRandom(10);
            if (firstNumber == secondNumber && firstNumber == thirdNumber){
                uint8 percentage =  75;
                uint amount = (totalJackpot / 100) * 65;
                uint fee = (totalJackpot / 100) * 10;
                uint usersAndOwnerFee = fee / 2;
                payable(msg.sender).transfer(amount);
                owner.transfer(usersAndOwnerFee);
                emit Score (true, amount, fee, percentage, firstNumber, secondNumber, thirdNumber);
                for(uint256 i=0; i < players.length; i++) {
                    address addr = players[i];
                    uint feeForThisUser = (howMuchPlay[addr] * usersAndOwnerFee) / totalPlay;
                    payable(addr).transfer(feeForThisUser);
                }
                
            }
            else if(firstNumber == secondNumber || firstNumber == thirdNumber || secondNumber == thirdNumber){
                uint8 percentage =  45;
                uint amount = (totalJackpot / 100) * 35;
                uint fee = (totalJackpot / 100) * 10;
                uint usersAndOwnerFee = fee / 2;
                payable(msg.sender).transfer(amount);
                owner.transfer(usersAndOwnerFee);
                emit Score (true, amount, fee, percentage, firstNumber, secondNumber, thirdNumber);
                for(uint256 i=0; i < players.length; i++) {
                    address addr = players[i];
                    uint feeForThisUser = (howMuchPlay[addr] * usersAndOwnerFee) / totalPlay;
                    payable(addr).transfer(feeForThisUser);
                }
            }
            else{
                uint8 percentage =  0;
                emit Score (false, 0, 0, 0, firstNumber, secondNumber, thirdNumber);
            }
        }
        else{
            emit Score (false, 0, 0, 0, 1, 2, 3);
        }
        
        
        
    }

    function withdraw(uint _amount) external payable onlyOwner{
        owner.transfer(_amount);
    }


}