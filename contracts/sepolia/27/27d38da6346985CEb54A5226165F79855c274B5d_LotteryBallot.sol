/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LotteryBallot
{
    address public owner;
    address private deadAddr=0x000000000000000000000000000000000000dEaD;

    address[] item0;
    address[] item1;
    address[] item2;

    address[3] public winners;

    uint[3] public counter;
    enum Stage {Bidding,Ended}  
    Stage public stage;
    
    struct Item
    {
        string name;
        string imgurl;
    }

    Item[3] public items;

    constructor(string memory name_1, string memory url_1, string memory name_2, string memory url_2, string memory name_3, string memory url_3) payable
    {
        owner = msg.sender;
        items[0]=(Item(name_1,url_1));
        items[1]=(Item(name_2,url_2));
        items[2]=(Item(name_3,url_3));
        stage=Stage.Bidding;

        for(uint i=0; i<3; i++)
        {
            counter[i]=0;
        }
    }

    modifier onlyOwner() 
    {
       require(msg.sender == owner, "This can only be called by the contract owner");
       _;
    }

    modifier alreadyDeclared() 
    {
       require(stage != Stage.Ended, "The winners have already been declared");
       _;
    }   

    modifier restrictOwner()
    {
        require(msg.sender!=owner, "Owner is not allowed to register"); 
        _;
    }

    modifier ethRestriction()
    {
        require(msg.value == 0.01 ether, "Bidding requires exactly 0.01 ether");   
        _;
    }

    modifier currentStage (Stage _stage) 
    {
       require(stage==_stage, "Not ready, wait for the correct contract stage");
       _;
    }
   

    event bidevnt(uint itemid, address bidder);

    function bid(uint itemid) public payable restrictOwner currentStage(Stage.Bidding) ethRestriction 
    {    
        if(itemid==0)
        {
            counter[0]++;
            item0.push(msg.sender); 
        }
        else if(itemid==1)
        {
            counter[1]++;
            item1.push(msg.sender); 
        }
        else
        {
            counter[2]++;
            item2.push(msg.sender); 
        }    

        emit bidevnt(itemid, msg.sender);    
    }

    function getRandomNumber() private view returns (uint) 
    {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }


    function declareWinner() public payable alreadyDeclared onlyOwner 
    {
        stage=Stage.Ended;
        if(item0.length>0)
        {
            uint index0 = getRandomNumber() % item0.length;
            winners[0] = item0[index0];
        }
        else
        {
            winners[0]=deadAddr;
        }

        if(item1.length>0)
        {
            uint index1 = getRandomNumber() % item1.length;
            winners[1] = item1[index1];
        }
        else
        {
            winners[1]=deadAddr;
        }

        if(item2.length>0)
        {
            uint index2 = getRandomNumber() % item2.length;
            winners[2] = item2[index2];
            
        }
        else
        {
            winners[2]=deadAddr;
        }                
            
    }

    function amIWinner() public view returns (bool[3] memory) 
    {
        require(stage==Stage.Ended, "The winners have not been declared yet"); 

        bool[3] memory temp;

        for(uint i=0; i<3; i++)
        {
            if(msg.sender==winners[i])
            {
                temp[i]=true;
            }
        }
        return temp;     
    }

    function reset(string memory name_1, string memory url_1, string memory name_2, string memory url_2, string memory name_3, string memory url_3) public payable onlyOwner
    {
        items[0]=(Item(name_1,url_1));
        items[1]=(Item(name_2,url_2));
        items[2]=(Item(name_3,url_3));
        stage=Stage.Bidding;

        for(uint i=0; i<3; i++)
        {
            counter[i]=0;
        }
   
        delete winners;
        delete item0;
        delete item1;
        delete item2;
       
    }

    function withdraw() public onlyOwner
    {
        require(address(this).balance > 0 ether,"0 balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function renounce(address addr) public payable onlyOwner
    {
        owner=addr;
    }

    function destroy() public payable onlyOwner currentStage(Stage.Ended)
    {
        owner=deadAddr;
    }


    }