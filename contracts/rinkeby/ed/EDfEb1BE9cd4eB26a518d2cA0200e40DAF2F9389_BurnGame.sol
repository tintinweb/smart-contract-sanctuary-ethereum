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

contract BurnGame {
    address tokeAddress = 0xDC5cc936595d71C3C40001F96868cdE92C41b21A;
    ITOKE toke;
    uint256 public totalBurned = 0;
    uint256 private highestBurnedAmount = 0;
    address public highestBurner = address(0x0);

    mapping(address => uint256) amountBurned;
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
        amountBurned[msg.sender] += amount;
        totalBurned += amount;
		burners.push(msg.sender);

        if(amountBurned[msg.sender] > highestBurnedAmount) {
            highestBurner = msg.sender;
			highestBurnedAmount = amountBurned[msg.sender];
        }
    }

    function resetGame() external onlyOwner {
        totalBurned = 0;
		highestBurnedAmount = 0;
        highestBurner = address(0x0);

        for(uint256 i = 0; i < burners.length; i++) {
            amountBurned[burners[i]] = 0;
        }

    }
}