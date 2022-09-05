/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
contract CCF {


    mapping (address => uint) balance;
    address[30] PlayerOneAddress; 
    uint[30] PriceOfTable;  
    uint[30] CoinTypePlaced;
    uint[30] Winner;
    bool[30] GameStarted;

    uint private Interaction = 0;
    uint private Tax =6;
    bool public VsBotsActive=false;

    address constant ContractOwner = 0xa4087A999288B7866f31E8b5537721c92584dE97;



    modifier onlyOwner {
        require(msg.sender == ContractOwner, "Ownable: You are not the owner");  //Require Contract Owner to have same  address to use function
        _;
    }

    function QueryInteraction() public view returns(uint)
    {
        return Interaction;
    }


    function SetBotActive(bool Active) public onlyOwner {
        VsBotsActive=Active;
    }


    function SetTax(uint NewTax) public onlyOwner {
        Tax=NewTax;
    }

    function QueryPlayerOneAddress(uint GameID) public view returns(address)
    {
        return PlayerOneAddress[GameID];
    }
    
    function QueryPriceOfGame(uint GameID) public view returns(uint)
    {
        return PriceOfTable[GameID];
    }
    
    function QueryCheckGameStarted(uint GameID) public view returns(bool)
    {
        return GameStarted[GameID];
    }



    function QueryBalance(address CheckAddress) public view returns(uint)
    {
        return balance[CheckAddress];
    }

    //Deposit fund to contract
    function deposit() public payable {
        require(msg.value>0);
        balance[msg.sender] += msg.value;
    }



    //Withdraw funds from contract
    function withdraw(uint amount) public {
        if (amount > balance[msg.sender]) {
            amount = balance[msg.sender];
        }
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        }


    function PlayVsBot(uint GameID) public {
    require(VsBotsActive==true);
    require(balance[ContractOwner]>PriceOfTable[GameID]);
            //play Game        
            //Pick random number
            Interaction++;
            Winner[GameID]  = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  Interaction))) % 2;
            
            //Pay Tax   
            //Tax  // =6
            uint TaxToPay = PriceOfTable[GameID] / 100 * Tax;

            //if random number is the player
            if(Winner[GameID] == CoinTypePlaced[GameID])
            {
                balance[ContractOwner] -= PriceOfTable[GameID];  //remove winning amount from contract
                balance[PlayerOneAddress[GameID]]+= PriceOfTable[GameID]-TaxToPay; 
            }
            else {        //otherwise pay out player 2 (player that joined)
                balance[ContractOwner] += PriceOfTable[GameID]-TaxToPay;
            }

            balance[ContractOwner] += TaxToPay;

            //Reset Game
            GameStarted[GameID] = false;
    }


    //Withdraw fudns from contract
    function JoinGame(uint GameID) public {
        if (balance[msg.sender] >= PriceOfTable[GameID]) {
            //play Game        
            //Pick random number
            Interaction++;
            Winner[GameID] = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  Interaction))) % 2;


            //Pay Tax   
            //Tax  // =6
            uint TaxToPay = PriceOfTable[GameID] / 100 * Tax;

            //if random number is the same as the coin selection of player 1, pay out to player 1
            if(Winner[GameID] == CoinTypePlaced[GameID])
            {
                balance[msg.sender] -= PriceOfTable[GameID];
                balance[PlayerOneAddress[GameID]]+= PriceOfTable[GameID]-TaxToPay; 
            }
            else {        //otherwise pay out player 2 (player that joined)
                balance[msg.sender] += PriceOfTable[GameID]-TaxToPay;
            }

            balance[ContractOwner] += TaxToPay;

            //Reset Game
            GameStarted[GameID] = false;

        }
    }

    function CancelGame(uint GameID) public{
        require(GameStarted[GameID]==true);
        require(msg.sender == PlayerOneAddress[GameID]);
        
        balance[msg.sender] += PriceOfTable[GameID];  //Return Money
        GameStarted[GameID] = false;
        Interaction++;
        
    }


    function CreateGame(uint amount, uint CoinType) public {
        require(balance[msg.sender] >= amount);
        require(amount > 0);

        for (uint i = 0; i < 30; i++) {
            if(GameStarted[i]==false)
            {
                balance[msg.sender] -= amount;
                GameStarted[i]=true;
                PlayerOneAddress[i]=msg.sender;
                CoinTypePlaced[i] = CoinType;
                PriceOfTable[i]=amount;
                Interaction++;
                Winner[i]=3;
                break;
            }
            
        }

    }
}