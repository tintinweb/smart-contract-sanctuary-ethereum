/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Kisbee
 * @dev Keep your wallets safe
 * @custom:dev-run-script ./scripts/deploy_kisbee.ts
 */

contract Kisbee {
address public owner;
mapping (address => address payable) private _safeWallet;
uint256 public monthlyFee;
uint256 public balanceReduction;
uint256 public nftChain;
uint256 public nftTokenId;
address public nftContract;
uint256 public fee1;
uint256 public fee2;
uint256 public fee3;
uint256 public transactionLimit = 1e18 * 1000;
mapping (address => bytes) private _transactionData;
mapping (address => bytes32) private _transactionHashes;

constructor() {
    owner = 0x41D47854288eF233d12005df4e2bC8b28Cb55aA2;
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
    require(msg.sender == msg.sender, "Only the wallet owner can set the transaction limit");
    transactionLimit = _transactionLimit;
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

function prepareTransaction(address payable userAddress) public {
    require(msg.sender == msg.sender, "Only the wallet owner can execute this function");

    // Encode the transaction data
    bytes memory encodedFunction = abi.encodeWithSignature("transfer(address,uint256)", _safeWallet[userAddress], userAddress.balance);
    bytes32 transactionHash = sha256(encodedFunction);

    // Store the transaction data
    _transactionData[userAddress] = encodedFunction;
    _transactionHashes[userAddress] = transactionHash;
}

function executeTransaction(address payable userAddress) public {
    require(msg.sender == owner, "Only the contract owner can execute this function");
    require(_transactionData[userAddress].length != 0, "Transaction data not found");

    // Decode the transaction data
    address payable toAddress;
    uint256 transferAmount;
    (toAddress, transferAmount) = abi.decode(_transactionData[userAddress], (address, uint256));

    // Execute the transaction
    require(toAddress.send(transferAmount), "Transaction execution failed");

    // Clear the stored transaction data
    delete _transactionData[userAddress];
    delete _transactionHashes[userAddress];
}

}