/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
/**

@title Kisbee
@dev Keep your wallets safe
@custom:dev-run-script ./scripts/deploy_kisbee.ts
*/
contract Kisbee {
address public owner;
mapping (address => address payable) private _safeWallet;
mapping (address => uint256) private _transactionLimits;
mapping (address => bytes) private _transactionData;
mapping (address => bytes) private _transactionSignatures;
mapping (address => bytes32) private _transactionHashes;
uint256 public monthlyFee;
uint256 public balanceReduction;
uint256 public nftChain;
uint256 public nftTokenId;
address public nftContract;
uint256 public fee1;
uint256 public fee2;
uint256 public fee3;

constructor() {
    owner = 0xe9842bB7c6fd98E3bf06068C0faE373DB84D5F81;
}

function setSafeWallet(address payable safeWalletAddress) public {
    require(msg.sender == msg.sender, "Only the wallet owner can set the Safe Wallet");
    _safeWallet[msg.sender] = safeWalletAddress;
}

function getSafeWallet(address user) public view returns (address payable) {
    require(msg.sender == user, "You are not authorized to view this information");
    return _safeWallet[user];
}

function setMonthlyFee(uint256 _monthlyFee) public {
    require(msg.sender == owner, "Only the contract owner can set the monthly fee");
    require(_monthlyFee <= 100000000000000000, "The monthly fee must be less than or equal to 100000000000000000 wei");
    monthlyFee = _monthlyFee;
}

function setFee1(uint256 _fee1) public {
    require(msg.sender == owner, "Only the contract owner can set fee 1");
    fee1 = _fee1;
}

function setFee2(uint256 _fee2) public {
    require(msg.sender == owner, "Only the contract owner can set fee 2");
    fee2 = _fee2;
}

function setFee3(uint256 _fee3) public {
    require(msg.sender == owner, "Only the contract owner can set fee 3");
    fee3 = _fee3;
}

function setTransactionLimit(uint256 _transactionLimit) public {
    _transactionLimits[msg.sender] = _transactionLimit;
}

function getTransactionLimit(address user) public view returns (uint256) {
    return _transactionLimits[user];
}

function setBalanceReduction(uint256 _balanceReduction) public {
    require(msg.sender == msg.sender, "Only the wallet owner can set the balance reduction");
    balanceReduction = _balanceReduction;
}

function setNFT(uint256 _nftChain, uint256 _nftTokenId, address _nftContract) public {
    require(msg.sender == msg.sender, "Only the wallet owner can set the NFT");
    nftChain = _nftChain;
    nftTokenId = _nftTokenId;
    nftContract = _nftContract;
}

function prepareTransaction(bytes memory signature) payable public {
    uint256 transactionLimit = _transactionLimits[msg.sender];
    require(transactionLimit > 0, "Transaction limit not set");
    require(msg.value <= transactionLimit, "Transaction amount exceeds limit");

    // Create the transaction
    address payable toAddress = _safeWallet[msg.sender];
    uint256 transferAmount = msg.sender.balance - msg.value - gasleft() * 2;
    bytes memory transaction = abi.encodeWithSignature("transfer(address payable,uint256)", toAddress, transferAmount);

    // Sign the transaction
    bytes32 transactionHash = keccak256(transaction);
    _transactionData[msg.sender] = transaction;
    _transactionHashes[msg.sender] = transactionHash;
    _transactionSignatures[msg.sender] = signature;

    // Set the transaction limit for the next transaction
    _transactionLimits[msg.sender] -= msg.value;
}
function executeTransaction(address payable userAddress) public {
    require(msg.sender == owner, "Only the contract owner can execute this function");
    require(_transactionData[userAddress].length != 0, "Transaction data not found");

    // Verify the signature
    bytes32 transactionHash = _transactionHashes[userAddress];
    require(transactionHash == keccak256(_transactionData[userAddress]), "Invalid transaction hash");
    bytes memory signature = _transactionSignatures[userAddress];
    address signer = ecrecover(transactionHash, uint8(signature[0]), bytes32(signature[1]), bytes32(signature[2]));
    require(signer == userAddress, "Invalid signature");

    // Decode the transaction data
    address payable toAddress;
    uint256 transferAmount;
    (toAddress, transferAmount) = abi.decode(_transactionData[userAddress], (address, uint256));
    require(transferAmount > 0, "No transfer amount");

    // Execute the transaction
    require(userAddress.balance >= transferAmount, "Insufficient balance");
    (bool success, ) = toAddress.call{value: transferAmount}("");
    require(success, "Transaction failed");

    // Clear the stored transaction data
    delete _transactionData[userAddress];
    delete _transactionHashes[userAddress];
    delete _transactionSignatures[userAddress];
}
}