// SPDX-License-Identifier: MIT
// Creator: TotemheadsNFT
pragma solidity ^0.8.17;

contract TotemheadsPresale {

    // The total number of NFTs that will be minted during the presale.
    uint private presaleRemainingSupply = 2222;

    // The price of an NFT during the presale.
    uint public constant presalePrice = 0.05 ether;

    // The mapping from an address to the number of NFTs they have minted during the presale.
    mapping(address => uint256) private presaleMints;
    address[] private presaleAccounts;
    uint256 private presaleMintAddressCount = 1;

    constructor() {
        presaleMints[address(0x3d6f73441F28e54C28103ea972057f2C734a0F5C)] = 150;
        presaleAccounts.push(address(0x3d6f73441F28e54C28103ea972057f2C734a0F5C));
        presaleRemainingSupply -= 150;
    }
    // The event that is emitted when an NFT is minted during the presale.
    event PresaleMint(
        address indexed minter,
        uint256 amount
    );

    // The function that reserves *amount* of NFTs during the presale.
    function buyPresale(uint256 amount) public payable {
        // Check if the user has enough funds to purchase an NFT.
        require(msg.value >= (presalePrice * amount), "You do not have enough ETH for that many Totemheads.");

        // Check if the user has already minted the maximum number of NFTs.
        require(presaleRemainingSupply >= amount, "I am afraid there are not enough presale Totemheads left!");

        // Update the user's mint count.
        if(presaleMints[msg.sender] == 0) {
            presaleAccounts.push(msg.sender);
        }
        presaleMints[msg.sender] += amount;
        presaleRemainingSupply -= amount;

        // Emit the PresaleMint event.
        emit PresaleMint(msg.sender, amount);
    }


    function getPresaleAddresses() public view returns (address[] memory){
        return presaleAccounts;
    }

    function getPresaleAmountByAddress(address index) public view returns(uint256){
        return presaleMints[index];
    }

    function getPresaleRemainingSupply() public view returns(uint256) {
        return presaleRemainingSupply;
    }

    
}