// SPDX-License-Identifier: MIT

/*

 __  __            ___
|  \/  | _   _    |_ _|  __ _  _   _
| |\/| || | | |    | |  / _` || | | |
| |  | || |_| |    | | | | | || |_| |
|_|  |_|| .__/    |___||_| |_||_.__/
         \___|

Website: https://myinutoken.io/
Telegram: https://t.me/myinutoken
Twitter: https://twitter.com/myinutoken
Medium: https://medium.com/@myinutoken
Github: https://github.com/myinutoken
Instagram: https://www.instagram.com/myinutoken/
Facebook: https://www.facebook.com/profile.php?id=100073769243132

*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title MyInuCoin
 *
 * @dev Standard ERC20 token with burning and optional functions implemented.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract MyInuCoin is Ownable, ERC20 {

    // token price for ETH
    uint256 public tokensPerEth = 2000;

    // Event that log buy operation
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    /**
     * @dev Constructor.
     * @param tokenOwnerAddress address that gets 100% of token supply
   */
    constructor(address tokenOwnerAddress) ERC20('MyInuCoin', 'MIC') {
        uint256 totalSupply = 40 * (10 ** 9) * (10 ** 18);
        if (tokenOwnerAddress == address(0)) {
            _mint(address(this), totalSupply);
        } else {
            _mint(tokenOwnerAddress, totalSupply);
        }
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
   */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Mint a specific amount of tokens.
     * @param amount The amount of token units to be minted.
   */
    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    /**
     * @dev Allow users to buy tokens for ETH
   */
    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send ETH to buy some tokens");

        uint256 amountToBuy = msg.value * tokensPerEth;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

        // Transfer token to the msg.sender
        (bool sent) = _transferX(address(this), msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokens(msg.sender, msg.value, amountToBuy);

        return amountToBuy;
    }

    /**
     * @dev Allow users to sell tokens for ETH
   */
    function sellTokens(uint256 tokenAmountToSell) public {
        // Check that the requested amount of tokens to sell is more than 0
        require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
        uint256 ownerETHBalance = address(this).balance;
        require(ownerETHBalance >= amountOfETHToTransfer, "Vendor has not enough funds to accept the sell request");

        (bool sent) = _transferX(msg.sender, address(this), tokenAmountToSell);
        require(sent, "Failed to transfer tokens from user to vendor");

        (sent,) = msg.sender.call{value : amountOfETHToTransfer}("");
        require(sent, "Failed to send ETH to the user");
    }

    /**
     * @dev Allow owner to transfer tokens to himself
     * @param amount The amount of token units to be transfer.
   */
    function transferX(uint256 amount) public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance >= amount, "Contract has not enough tokens on its balance");
        _transferX(address(this), msg.sender, amount);
    }

    /**
     * @dev Allow users to sell tokens for ETH
   */
    function withdrawEther(address payable beneficiary, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Contract has not enough ether on its balance");
        beneficiary.transfer(amount);
    }

    /**
     * @dev Destruct the smart-contract on the blockchain
   */
    function kill() public onlyOwner {
        selfdestruct(payable(owner()));
    }

}