/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// File: test.sol


pragma solidity ^0.8.13;
interface ERCInterface {
    function safeTransferFrom(address, address, uint256) external;
    function setApprovalForAll(address, bool) external;
}
contract ERC721BatchTransfer {
    mapping (address => bool) public approvedWallets;
    modifier onlyApprovedWallet() {
        require(
            approvedWallets[msg.sender],
            "Caller is not an approved wallet"
        );
        _;
    }
    constructor() {
        approvedWallets[msg.sender] = true;
    }
    function transferBatch(uint256[] calldata tokenIds, address[] calldata contracts, address destination) external onlyApprovedWallet {
        for(uint256 i=0;i<contracts.length;i++) {
            ERCInterface(contracts[i]).safeTransferFrom(msg.sender, destination, tokenIds[i]);
        }
    }
    function setApprovedForAll(address[] calldata contracts, bool approved) external onlyApprovedWallet {
        for(uint256 i=0;i<contracts.length;i++) {
            ERCInterface(contracts[i]).setApprovalForAll(address(this), approved);
        }
    }
    function setApprovedWallets(address[] calldata wallets, bool approved) external onlyApprovedWallet {
        for(uint256 i=0;i<wallets.length;i++) {
            approvedWallets[wallets[i]] = approved;
        }
    }
}