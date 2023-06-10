/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

//Tax Router.
//
//We Do It For Teh PPL.
//
// SPDX-License-Identifier: Unlicensed
//


pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract TaxRouter {

    using SafeMath for uint256;

    event Received(address from, uint256 amount);
    address public owner;
    address payable public recipient1 = payable(0x9057f172Ab83e4A8B9037DDA511233136a707eC3);
    address payable public recipient2 = payable(0x9057f172Ab83e4A8B9037DDA511233136a707eC3);
    uint256 public threshold = 3 * 10**17; // 0.3 ether in wei
    
    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        checkBalanceAndSendFunds();
    }

    function checkBalanceAndSendFunds() internal {
        if(address(this).balance >= threshold){
            sendFunds();
        }
    }

        
function sendFunds() internal {
    uint256 amountToSend = address(this).balance - 1e17;
    uint256 amount1 = (amountToSend * 50) / 100;
    uint256 amount2 = (amountToSend * 50) / 100;
    (bool success1, ) = recipient1.call{value: amount1}("");
    require(success1, "Failed to send ETH to marketing address");
    (bool success2, ) = recipient2.call{value: amount2}("");
    require(success2, "Failed to send ETH to marketing address");
}

function manualSend(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance - 2e16, "Insufficient balance.");
    require(amount > 0, "Amount must be greater than 0.");
    uint256 amount1 = (amount * 50) / 100;
    uint256 amount2 = (amount * 50) / 100;
    (bool success1, ) = recipient1.call{value: amount1}("");
    require(success1, "Failed to send ETH to marketing address");
    (bool success2, ) = recipient2.call{value: amount2}("");
    require(success2, "Failed to send ETH to marketing address");
}
    
    function setRecipient1(address payable _recipient1) external onlyOwner {
        recipient1 = _recipient1;
    }
    
    function setRecipient2(address payable _recipient2) external onlyOwner {
        recipient2 = _recipient2;
    }
    
    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

}