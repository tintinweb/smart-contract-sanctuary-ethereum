/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

contract TokenFlip{
    //Setup game table
    uint constant MAXGAMETABLES = 50;

    bool[MAXGAMETABLES] GameActive; //Game Active
    uint[MAXGAMETABLES] public PriceGame;  //$$$$ gambled
    string Vault = "0xa4087A999288B7866f31E8b5537721c92584dE97";
    string  public PlayerOne = "";
    string  public PlayerTwo = "";


    mapping(address => uint)public balances;

    
    //create game
    function CreateGame() public payable {
        uint8 FoundTable = 0;
        for(uint8 i = 0; i < MAXGAMETABLES; i++) 
        {
            if(GameActive[i]==false)
            {
                FoundTable = i;
                break;
            }
        }

        PriceGame[FoundTable] = 10000000000000000; // 0.01 eth
        //Sent money to contract
        balances[msg.sender] += PriceGame[FoundTable];


  
        string memory senderAddress = bytes20ToLiteralString(bytes20(msg.sender));

        PlayerOne = senderAddress;

        // sent money to vault with game table ID
    }

/*
    function JoinGame(uint8 GameTableID) public{
    //send money to vault
    //
    uint RandomNumber = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % 2;
    if(RandomNumber==1)
    {
         //PayOut Player1
    }
    else
    {
        //PayOut Player 2
    }

    //work out winner

    //pop game off table
    //TotalGames.pop(i)
    }
*/

    function () external payable {}



function bytes20ToLiteralString(bytes20 data) 
        private
        pure
        returns (string memory result)
    {
        bytes memory temp = new bytes(41);
        uint256 count;

        for (uint256 i = 0; i < 20; i++) {
            bytes1 currentByte = bytes1(data << (i * 8));
            
            uint8 c1 = uint8(
                bytes1((currentByte << 4) >> 4)
            );
            
            uint8 c2 = uint8(
                bytes1((currentByte >> 4))
            );
        
            if (c2 >= 0 && c2 <= 9) temp[++count] = bytes1(c2 + 48);
            else temp[++count] = bytes1(c2 + 87);
            
            if (c1 >= 0 && c1 <= 9) temp[++count] = bytes1(c1 + 48);
            else temp[++count] = bytes1(c1 + 87);
        }
        
        result = string(temp);
    }
    
}