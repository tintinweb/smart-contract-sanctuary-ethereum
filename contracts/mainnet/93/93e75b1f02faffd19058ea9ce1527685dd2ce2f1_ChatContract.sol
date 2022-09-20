// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract ChatContract is Context, Ownable {
    
    uint256 private fee;
    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor () {
        fee = 80;
    }

    function sendTip(address tokenAddress, uint256 amount, address to) external payable {
        require(tokenAddress!=address(0));
        require(amount>0);
        require(to!=address(0));
        if (tokenAddress == ethAddress) {
            require(msg.value >= amount, "Insuffcient Fund");
            payable(to).transfer( amount * (100 - fee) / 100 );
        } else {
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transferFrom(msg.sender, address(this), amount);
            require(success);
            token.transfer(to, amount * (100 - fee) / 100);
        }
    }

    function withdraw(address tokenAddress, address receiverAddress, uint256 amount) external onlyOwner {
        require(tokenAddress!=address(0));
        require(amount>0);
        
        if (tokenAddress==ethAddress) {
            if (address(this).balance < amount)
                amount = address(this).balance;
            payable(receiverAddress).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            if (token.balanceOf(address(this)) < amount)
                amount = token.balanceOf(address(this));
            token.transfer(receiverAddress, amount);
        }
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    receive() external payable {}
}