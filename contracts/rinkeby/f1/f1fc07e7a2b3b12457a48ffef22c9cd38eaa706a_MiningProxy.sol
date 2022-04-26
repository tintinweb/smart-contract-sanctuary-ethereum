//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


import "./ERC20.sol";
import "./ERC918.sol";
import "./ApproveAndCallERC20Token.sol";



contract MiningProxy {
    
    uint256 public previousFarmDonationDate;

    address public immutable seasonalTokenAddress;
    address public immutable farmAddress;
    address public immutable walletAddress;

    event Payout(uint256 quantity);

    constructor (address seasonalTokenAddress_, 
                 address farmAddress_,
                 address walletAddress_) {

        seasonalTokenAddress = seasonalTokenAddress_;
        farmAddress = farmAddress_;
        walletAddress = walletAddress_;

    }

    function mint(uint256 nonce_) public returns (bool) {

        uint256 previousBalance = ERC20Interface(seasonalTokenAddress).balanceOf(address(this));
        require(ERC918(seasonalTokenAddress).mint(nonce_));
        
        uint256 newBalance = ERC20Interface(seasonalTokenAddress).balanceOf(address(this));
        uint256 amountToSendToWallet = ((newBalance - previousBalance) * 91) / 100;
        require(ERC20Interface(seasonalTokenAddress).transfer(walletAddress, amountToSendToWallet));

        newBalance -= amountToSendToWallet;
        
        uint256 date = block.timestamp / (24 * 60 * 60);

        if (date != previousFarmDonationDate) {
            bytes memory data;
            require(ApproveAndCallERC20Token(seasonalTokenAddress).safeApproveAndCall(farmAddress, 0, 
                                                                                      newBalance, 
                                                                                      data));
            previousFarmDonationDate = date;
        }
        emit Payout(amountToSendToWallet);
        return true;
    }

    function getChallengeNumber() public view returns (bytes32) {
        return ERC918(seasonalTokenAddress).getChallengeNumber();
    }

    function getMiningTarget() public view returns (uint256) {
        return ERC918(seasonalTokenAddress).getMiningTarget();
    }

    function getMiningReward() public view returns (uint256) {
        return ERC918(seasonalTokenAddress).getMiningReward();
    }

    function getMiningDifficulty() public view returns (uint256) {
        return ERC918(seasonalTokenAddress).getMiningDifficulty();
    }

    function getNumberOfRewardsAvailable(uint256 time) external view returns (uint256) {
        return ERC918(seasonalTokenAddress).getNumberOfRewardsAvailable(time);
    }



}