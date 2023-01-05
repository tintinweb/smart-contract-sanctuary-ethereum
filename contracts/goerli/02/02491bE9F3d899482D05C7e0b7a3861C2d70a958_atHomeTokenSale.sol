// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ERC20 {
    function transferFrom(address _from, address _to, uint256 _amount) public virtual returns (bool success);
    function decimals() public virtual view returns(uint8);
}

contract atHomeTokenSale {
    uint tokenPriceInWei = 1 ether;

    ERC20 public token;
    address public tokenOwner;

    constructor(address _token) {
        tokenOwner = msg.sender;
        token = ERC20(_token);
    }

    function purchase() public payable {
        require(msg.value >= tokenPriceInWei, "Not enough money sent");
        uint tokensToTransfer = msg.value / tokenPriceInWei;
        uint remainder = msg.value - tokensToTransfer * tokenPriceInWei;
        token.transferFrom(tokenOwner, msg.sender, tokensToTransfer * 10 ** token.decimals());
        payable(msg.sender).transfer(remainder); //send the rest back
    }
}