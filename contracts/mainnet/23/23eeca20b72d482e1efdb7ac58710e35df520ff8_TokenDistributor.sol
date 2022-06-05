//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";

contract TokenDistributor is Ownable {

    // Token
    address public immutable token;

    // Recipients Of Tokens
    address public receiverWallet;

    /**
        Minimum Amount Of Tokens In Contract To Trigger `trigger` Unless `approved`
            If Set To A Very High Number, Only Approved May Call Trigger Function
            If Set To A Very Low Number, Anybody May Call At Their Leasure
     */
    uint256 public minimumTokensRequiredToTrigger;

    // Address => Can Call Trigger
    mapping ( address => bool ) public approved;

    // Events
    event Approved(address caller, bool isApproved);

    constructor(address token_, address receiverWallet_) {
        require(
            token_ != address(0) &&
            receiverWallet_ != address(0),
            'Zero Address'
        );

        // Initialize Addresses
        token = token_;
        receiverWallet = receiverWallet_;

        minimumTokensRequiredToTrigger = 3000000000 ether;

        // set initial approved
        approved[msg.sender] = true;
    }

    function trigger() external {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance < minimumTokensRequiredToTrigger && !approved[msg.sender]) {
            return;
        }

        if (balance > 0) {
            IERC20(token).transfer(receiverWallet, balance);
        }
    }

    function setReceiverWallet(address receiverWallet_) external onlyOwner {
        require(receiverWallet_ != address(0));
        receiverWallet = receiverWallet_;
    }

    function setApproved(address caller, bool isApproved) external onlyOwner {
        approved[caller] = isApproved;
        emit Approved(caller, isApproved);
    }
    function setMinTriggerAmount(uint256 minTriggerAmount) external onlyOwner {
        minimumTokensRequiredToTrigger = minTriggerAmount;
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    function withdrawERC20(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}