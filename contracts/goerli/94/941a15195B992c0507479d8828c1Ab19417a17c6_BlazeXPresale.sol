//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlazeXPresale {
    address public owner;
    address public ownershipWallet;
    address public taxWallet;
    bool public isPresaleActive;
    bool public isPresaleFinished;
    mapping(address => uint256) public purchases;
    mapping(address => bool) public bought;
    uint256 public taxRate;
    uint256 public totalBNB;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public presaleStartDate;
    uint256 public presaleEndDate;

    constructor(uint256 _softCap, uint256 _hardCap, uint256 _presaleStartDate, uint256 _presaleEndDate) {
        require(_hardCap > _softCap, "Hard cap must be greater than soft cap.");
        require(_presaleStartDate < _presaleEndDate, "Presale start date must be before presale end date.");
        owner = msg.sender;
        ownershipWallet = msg.sender;
        taxWallet = address(0); // Initialize tax wallet to address(0) for no initial tax collection
        taxRate = 1; // Default tax rate is 1%
        isPresaleActive = false; // Presale is initially inactive
        isPresaleFinished = false; // Presale is initially not finished
        softCap = _softCap;
        hardCap = _hardCap;
        presaleStartDate = _presaleStartDate;
        presaleEndDate = _presaleEndDate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    modifier onlyOwnershipWallet() {
        require(msg.sender == ownershipWallet, "Only the ownership wallet can call this function.");
        _;
    }
    
    modifier presaleActive() {
        require(isPresaleActive, "Presale is not active.");
        require(block.timestamp >= presaleStartDate && block.timestamp <= presaleEndDate, "Presale is not currently active.");
        _;
    }
    
    modifier presaleFinished() {
        require(isPresaleFinished, "Presale is not finished yet.");
        _;
    }

    function setOwnershipWallet(address _ownershipWallet) external onlyOwner {
        ownershipWallet = _ownershipWallet;
    }
    
    function setTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = _taxWallet;
    }
    
    function startPresale() external onlyOwnershipWallet {
        require(!isPresaleFinished, "Presale is already finished.");
        isPresaleActive = true;
    }
    
    function stopPresale() external onlyOwnershipWallet {
        require(!isPresaleFinished, "Presale is already finished.");
        isPresaleActive = false;
    }
    
    function finishPresale() external onlyOwnershipWallet {
        require(!isPresaleFinished, "Presale is already finished.");
        isPresaleFinished = true;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 100, "Tax rate must be between 0 and 100.");
        taxRate = _taxRate;
    }
    
    function setSoftCap(uint256 _softCap) external onlyOwner {
        require(_softCap < hardCap, "Soft cap must be less than hard cap.");
        softCap = _softCap;
    }
    
    function setHardCap(uint256 _hardCap) external onlyOwner {
        require(_hardCap > softCap, "Hard cap must be greater than soft cap.");
        hardCap = _hardCap;
    }
    
    function setPresaleDates(uint256 _presaleStartDate, uint256 _presaleEndDate) external onlyOwner {
        require(_presaleStartDate < _presaleEndDate, "Presale start date must be before presale end date.");
        presaleStartDate = _presaleStartDate;
        presaleEndDate = _presaleEndDate;
    }

    function getAddressPurchase(address _address) external view returns (uint256) {
        return purchases[_address];
    }

    function hasAddressBought(address _address) external view returns (bool) {
        return bought[_address];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getContractBNBBalance() external view returns (uint256) {
        return totalBNB;
    }
    
    function getContractEthBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawFunds() external onlyOwner presaleFinished {
        require(address(this).balance > 0, "No funds available to withdraw.");
        
        // Transfer the entire contract balance to the contract owner
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }
    
    function checkSoftCapReached() external view returns (bool) {
        return totalBNB >= softCap;
    }
    
    function checkHardCapReached() external view returns (bool) {
        return totalBNB >= hardCap;
    }

    receive() external payable presaleActive {
        require(!bought[msg.sender], "Address has already purchased.");
        require(msg.value > 0, "No BNB sent with the transaction.");

        uint256 amount = msg.value;
        uint256 taxAmount = amount * taxRate / 100;
        uint256 purchaseAmount = amount - taxAmount;

        purchases[msg.sender] += purchaseAmount;
        bought[msg.sender] = true;

        totalBNB += purchaseAmount;

        // Transfer the tax amount to the tax wallet
        (bool success, ) = taxWallet.call{value: taxAmount}("");
        require(success, "Tax transfer failed.");
    }

    

    function receiveETH() external payable presaleActive {
        require(!bought[msg.sender], "Address has already purchased.");
        require(msg.value > 0, "No ETH sent with the transaction.");

        uint256 amount = msg.value;
        uint256 taxAmount = amount * taxRate / 100;
        uint256 purchaseAmount = amount - taxAmount;

        purchases[msg.sender] += purchaseAmount;
        bought[msg.sender] = true;

        totalBNB += purchaseAmount;

        // Transfer the tax amount to the tax wallet
        (bool success, ) = taxWallet.call{value: taxAmount}("");
        require(success, "Tax transfer failed.");
    }
}