/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

interface ITOKE {
	function mint(address to, uint256 amount) external;

	function burn(address from, uint256 amount) external;

	function updateOriginAccess() external;

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

contract STACRaffle {
    address tokeAddress = 0xDC5cc936595d71C3C40001F96868cdE92C41b21A;
    ITOKE toke;
    uint256 public totalStonedApeTickets = 0;
    uint256 public totalFedApeTickets = 0;
    uint256 public totalBurned = 0;

    mapping(address => uint256) public stonedApeTicketAmounts;
    mapping(address => uint256) public fedApeTicketAmounts;
    
    address[] private stonedApeTicketAddresses;
    address[] private fedApeTicketAddresses;
	address[] private burners;

    address private owner;

    modifier onlyOwner() {
    require(msg.sender == owner, "You are not allowed to use this function");
    _;
	}
	constructor() {
		owner = msg.sender;
        toke = ITOKE(tokeAddress);
	}

    function burn(uint256 amount) external {
        toke.burn(msg.sender, amount);
        if(amount == 50000 ether) {
            stonedApeTicketAmounts[msg.sender] += 1;
            stonedApeTicketAddresses.push(msg.sender);
            totalStonedApeTickets += 1;

            if(stonedApeTicketAmounts[msg.sender] == 1 && fedApeTicketAmounts[msg.sender] == 0) {
                burners.push(msg.sender);
            }
        }

        if(amount == 250000 ether) {
            fedApeTicketAmounts[msg.sender] += 1;
            fedApeTicketAddresses.push(msg.sender);
            totalFedApeTickets += 1;

            if(fedApeTicketAmounts[msg.sender] == 1 && stonedApeTicketAmounts[msg.sender] == 0) {
                burners.push(msg.sender);
            }
        }
        totalBurned += amount;

    }

    function getStonedApeAddresses() public view returns (address [] memory) {
        return stonedApeTicketAddresses;
    }

    function getFedApeAddresses() public view returns (address [] memory) {
        return fedApeTicketAddresses;
    }

    function resetGame() external onlyOwner {

        for(uint256 i = 0; i < burners.length; i++) {
            stonedApeTicketAmounts[burners[i]] = 0;
            fedApeTicketAmounts[burners[i]] = 0;
        }

        totalBurned = 0;
        totalFedApeTickets = 0;
        totalStonedApeTickets = 0;
        delete fedApeTicketAddresses;
        delete stonedApeTicketAddresses;
        delete burners;

    }
}