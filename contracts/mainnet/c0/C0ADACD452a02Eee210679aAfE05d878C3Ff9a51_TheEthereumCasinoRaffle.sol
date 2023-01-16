// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;
 
contract TheEthereumCasinoRaffle
{
	uint public MemberCurrentID;
    mapping (address => uint) public Members;
    mapping (uint => address) public MembersID;
    mapping (address => uint) public MembersNonce;

    uint16[8] public TicketCurrent;
	
    uint16[8] public TicketPicked;
	
    uint[8] public GamesPlayed;
	
    uint[8] public TicketsSoldTotal;
	
    uint[8][1024] public Tickets;
	
	uint[8] public BalanceOwner;
	uint[8] public BalancePlayer;
	uint[8] public BalanceTithe;
	
    address[2] public Owner;
	bytes32[2] public OwnerPass;
	
	bytes32 public CasinoAddress;
	
    mapping (string => string[]) public Thread;
	
	uint public SeedRandom;
	
    uint256[8] public TicketPrice = [
        0.00001 ether,
        0.0001 ether,
        0.001 ether,
        0.01 ether,
        0.1 ether,
        1.0 ether,
        10.0 ether,
        100.0 ether
    ];
	
	
	constructor() {
        Owner[0] = msg.sender; 
        Owner[1] = msg.sender; 
		
        OwnerPass[0] = 0xe5ad26b8f15e44c555f2332424d321156885a19b2c512713f52899bcead0a58e;
        OwnerPass[1] = 0x1722045401a97fefbee7f13ef6ae0d6145e2defdfb882752bffd966ef10da6e2;
		
		Thread["EthereumCasino"].push("Write anything");
		MemberCurrentID = 1;
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]);  } 
		MembersNonce[msg.sender]++;
	}

	
	function buyTicket(uint8 _Game, uint32 _TicketCount) external payable {
		require (Members[msg.sender] != 0);
        require (msg.value == (TicketPrice[_Game] * _TicketCount), "Not correct ETH amount");
		
		for (uint24 cou=0;cou<_TicketCount;cou++){
			MembersNonce[msg.sender]++;
			unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]);  } 
			
			if (TicketCurrent[_Game] == 1024){
				GamesPlayed[_Game]++;
					
				TicketPicked[_Game] = uint16(uint(keccak256(abi.encodePacked(msg.sender, SeedRandom))) % 1024);
				
				payable(MembersID[Tickets[TicketPicked[_Game]][_Game]]).transfer(BalancePlayer[_Game]);
				payable(msg.sender).transfer(BalanceTithe[_Game]);
				
				BalancePlayer[_Game] = 0;
				BalanceTithe[_Game] = 0;
				
				TicketCurrent[_Game] = 0;
			}
			
			Tickets[TicketCurrent[_Game]][_Game] = Members[msg.sender];
			
			uint tempBalanceBase = TicketPrice[_Game] / 100;
			
			
			BalancePlayer[_Game] += tempBalanceBase * 80;
			BalanceTithe[_Game] += tempBalanceBase * 1;
			BalanceOwner[_Game] += tempBalanceBase * 19;
			
			TicketsSoldTotal[_Game]++;
			TicketCurrent[_Game]++;
		}
	}
	
    function withdraw() external {
		uint tempBalanceOwner = 0;
		uint tempBalanceOwnerHalf = 0;
		
		for (uint8 iterGame=0;iterGame<8;iterGame++){
			tempBalanceOwner += BalanceOwner[iterGame];
			BalanceOwner[iterGame] = 0;
		}
		
		tempBalanceOwnerHalf = tempBalanceOwner / 2;
		
        payable(Owner[0]).transfer(tempBalanceOwnerHalf);
		tempBalanceOwner -= tempBalanceOwnerHalf;
        payable(Owner[1]).transfer(tempBalanceOwner);
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]);  } 
		MembersNonce[msg.sender]++;
    }
	
    function setOwnerWallet(uint8 _ID, string memory _Pass, bytes32 _New_Pass, address payable _Wallet) external{
        if ((keccak256(abi.encodePacked(_Pass)) == OwnerPass[_ID])){ 
            Owner[_ID] = _Wallet;
			OwnerPass[_ID] = _New_Pass;
        }
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]);  } 
		MembersNonce[msg.sender]++;
    }
	
    function registerMember() external{
		require (Members[msg.sender] == 0);
		
		Members[msg.sender] = MemberCurrentID;
		MembersID[MemberCurrentID] = msg.sender;
		
		MemberCurrentID++;
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]);  } 
		MembersNonce[msg.sender]++;
    }
	
    function post(string memory _Thread, string memory _Post) external{
        Thread[_Thread].push(_Post);
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]); }
		MembersNonce[msg.sender]++;
    }
	
	function setEtherCasino(uint8 _ID, bytes32 _EtherCasino) external {
        require(msg.sender == Owner[_ID]);
		CasinoAddress = _EtherCasino;
		
		unchecked { SeedRandom += uint(block.timestamp + MembersNonce[msg.sender]); } 
		MembersNonce[msg.sender]++;
	}
}