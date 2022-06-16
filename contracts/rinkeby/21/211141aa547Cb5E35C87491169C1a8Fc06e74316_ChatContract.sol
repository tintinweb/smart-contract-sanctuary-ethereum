// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract ChatContract is Context, Ownable {
    
    uint256 private fee;
    address private primaryWallet;
    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor () {
        primaryWallet = 0xa5CAf4a2cB0ef82C2a0214A83F811EdA4C236b9A;
        fee = 50;
    }

    function sendTip(address tokenAddress, uint256 amount, address to) external payable {
        require(tokenAddress!=address(0));
        require(amount>0);
        require(to!=address(0));
        if (tokenAddress == ethAddress) {
            require(msg.value >= amount, "Insuffcient Fund");
            payable(to).transfer(amount / 2);
        } else {
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transferFrom(msg.sender, address(this), amount);
            require(success);
            token.transfer(to, amount / 2);
        }
    }

     function extendTime(address tokenAddress, uint256 amount) external payable {
        require(tokenAddress!=address(0));
        require(amount>0);
        
        if (tokenAddress != ethAddress) {
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transferFrom(msg.sender, address(this), amount);
            require(success);
        } else {
            require(msg.value >= amount, "Insuffcient Fund");
        }
     }

    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress!=address(0));
        require(amount>0);
        
        if (tokenAddress==ethAddress) {
            if (address(this).balance < amount)
                amount = address(this).balance;
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            if (token.balanceOf(address(this)) < amount)
                amount = token.balanceOf(address(this));
            token.transfer(msg.sender, amount);
        }
    }
    
    function setPrimaryWallet(address _primary) external onlyOwner {
        primaryWallet = _primary;
    }

    receive() external payable {}
}