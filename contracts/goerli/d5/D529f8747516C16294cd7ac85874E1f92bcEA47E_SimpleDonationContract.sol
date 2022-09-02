/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Simple Royalty Profit Sharing Contract
contract SimpleDonationContract is Ownable {
    // using SafeMath for uint256;
    
    address creatorWallet;
    address donationWallet;
    
    string donatingTo;
    string donationInfoUrl;

    uint256 creatorPercentage = 50;

    uint256 creatorBalance = 0;
    uint256 donationBalance = 0;

    uint256 dustCheck = 0;
    uint256 dustCollectedAt = 50;

    constructor(){
        
    }

    event Received(address, uint);
    event Claimed(address, uint, address, uint);
    event PayoutInfoUnlocked();
    event PayoutInfoChanged(address, address, string, string);

    receive() external payable {
        split(msg.value);
    }

    fallback() external payable {
        split(msg.value);
    }

    function split(uint256 _amount) private {
        uint256 forCreator = (_amount * creatorPercentage) / 100;
        uint256 forDonation = _amount - forCreator;
        creatorBalance = forCreator;
        donationBalance = forDonation;
        dustCheck = dustCheck + 1;

        emit Received(msg.sender, msg.value);

    }

    function claim() external{
        uint256 creatorAmount = creatorBalance;
        require(creatorAmount > 0, 'Nothing To Claim');
        (bool creatorSent, bytes memory creatorData) = creatorWallet.call{value: creatorAmount}("");
        require(creatorSent, "Failed to send Ether");

        uint256 donationAmount = donationBalance;
        require(donationAmount > 0, 'Nothing To Claim');
        (bool donationSent, bytes memory donationData) = donationWallet.call{value: donationAmount}("");
        require(donationSent, "Failed to send Ether");

        creatorBalance = creatorBalance - creatorAmount;
        donationBalance = donationBalance - donationAmount;

        // Prep Dust to be claimed on next claim call
        if (dustCheck > dustCollectedAt){
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0 ){
                split(contractBalance);
            }
            dustCheck = 0;
        }

        emit Claimed(creatorWallet, creatorAmount, donationWallet, donationAmount);
    }

    function setPayoutInfo(address _creatorWallet, address _donationWallet, string memory _donatingTo, string memory _donationInfoUrl) external onlyOwner{
        creatorWallet = _creatorWallet;
        donationWallet = _donationWallet;
        donatingTo = _donatingTo;
        donationInfoUrl = _donationInfoUrl;

        emit PayoutInfoChanged(_creatorWallet, _donationWallet, _donatingTo, _donationInfoUrl);

    }

    function checkBalances() external view returns (uint256, uint256){  
        return(creatorBalance, donationBalance);

    }

    function getInfo() external view returns (address, address, string memory, string memory){  
        return(creatorWallet, donationWallet, donatingTo, donationInfoUrl);

    }


}