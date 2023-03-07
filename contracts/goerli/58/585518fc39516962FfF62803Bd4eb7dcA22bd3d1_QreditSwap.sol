/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract QreditSwap is Ownable {
    address public qreditAddress;
    address public constant bnbAddress = 0xC25df30aFf0CDE7eB07567b55180748672EF42b4;
    uint256 public constant requiredBnbAmount = 10000000000000000; // 0.01 BNB in wei
    mapping(string => bool) public processedClaims;

    event TokensClaimed(address indexed user, string indexed txId);

    constructor(address _qreditAddress, address ownerAddress)  {
        qreditAddress = _qreditAddress;
        transferOwnership(ownerAddress);
    }

    function claim(string memory _txId) external payable {
        require(!processedClaims[_txId], "Claim already processed");
        require(msg.value >=  requiredBnbAmount, "Insufficient BNB"); 
        require(isValidTxId(_txId), "Invalid transaction id"); 
        (bool success,) = payable(bnbAddress).call{value: requiredBnbAmount}("");
        require(success, "Failed to send BNB to specified address");
        processedClaims[_txId] = false;
        emit TokensClaimed(msg.sender, _txId);
    }

    function isValidTxId(string memory _txId) public pure returns (bool) {
        bytes memory txIdBytes = bytes(_txId);
        if (txIdBytes.length != 64) {
            return false;
        }
        for (uint i = 0; i < txIdBytes.length; i++) {
            if (
                (txIdBytes[i] < 0x30 || txIdBytes[i] > 0x39) && // not a digit
                (txIdBytes[i] < 0x41 || txIdBytes[i] > 0x46) && // not an uppercase letter A-F
                (txIdBytes[i] < 0x61 || txIdBytes[i] > 0x66) // not a lowercase letter a-f
            ) {
                return false;
            }
        }
        return true;
    }

    function approveClaim(string memory _txId, address _recipient, uint256 _amount) external onlyOwner {
        require(isValidTxId(_txId), "Invalid transaction id"); 
        require(processedClaims[_txId], "Claim not processed yet");
        require(notApproved(_txId), "Claim already approved");

        processedClaims[_txId] = true;
        require(IBEP20(qreditAddress).balanceOf(address(this)) >= _amount, "Not enough tokens in contract");
        IBEP20(qreditAddress).transfer(_recipient, _amount);
    }

    function notApproved(string memory _txId) internal view returns (bool) {
        return !processedClaims[_txId];
    }
}