/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC721 {
    function ownerOf(uint tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

/**
 * @title DirectTransfer
 * @dev Allow users to transfer nfts and acknowledge them
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract DirectTransfer {

    struct TransferRequest {
        address currentOwner;
        bool hasValue;
    }

    // Three mappings to connect the following: new_owner_address -> smart_contract_address -> token_id -> transfer_request
    mapping (address => mapping (address => mapping (uint => TransferRequest))) private transferRequests;

    /**
     * @dev Initiate a transfer from current owner, but wait for new owner to confirm
     * @param newOwner the new address that the token will be transfered to
     * @param smartContractAddress the address of the ERC720 contract 
     * @param tokenId the tokenId of the token to be transfered
     */
    function initiateTransfer(address newOwner, address smartContractAddress, uint tokenId) public {
        if(IERC721(smartContractAddress).ownerOf(tokenId) != msg.sender) revert("Request can only be made by token owner");
        if(transferRequests[newOwner][smartContractAddress][tokenId].hasValue) revert("Transfer request already exists");

        transferRequests[newOwner][smartContractAddress][tokenId] = TransferRequest({
            currentOwner: msg.sender,
            hasValue: true
        });
    }

    /**
     * @dev Approve a transfer from current owner to new owner
     * @param smartContractAddress the address of the ERC720 contract
     * @param tokenId the tokenId of the token to be transfered
     */
    function approveTransfer(address smartContractAddress, uint tokenId) public {
        TransferRequest memory request = transferRequests[msg.sender][smartContractAddress][tokenId];
        if(request.hasValue != true) revert("Transfer request can only be approved after request is initiated");
        
        IERC721(smartContractAddress).safeTransferFrom(request.currentOwner, msg.sender, tokenId);

        request.hasValue = false;
        request.currentOwner = address(0);

        transferRequests[msg.sender][smartContractAddress][tokenId] = request;
    }
}