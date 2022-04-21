// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract WithdrawTokens {
    struct WithdrawRequest {
        uint256 withdrawRequestID;
        uint256 nftID;
        uint256 chainID;
        address user;
        address token;
        uint256 amount;
        bool isMB1;
    }
    struct WithdrawMultipleRequest {
        uint256 withdrawMultipleRequestID;
        uint256[] nftIDs;
        uint256[] chainIDs;
        address user;
        address[] tokens;
        uint256[] amounts;
        bool isMB1;
    }

    uint256 public withdrawRequestCount;
    mapping(uint256 => WithdrawRequest) public WithdrawRequests;
    uint256 public withdrawMultipleRequestCount;
    mapping(uint256 => WithdrawMultipleRequest) public WithdrawMultipleRequests;

    constructor() {}

    function withdraw(uint256 _nftID, address _token, uint256 _amount, uint256 _chainID, bool _isMB1) external {
        WithdrawRequests[withdrawRequestCount] = WithdrawRequest({ 
            withdrawRequestID: withdrawRequestCount, 
            nftID: _nftID,
            chainID: _chainID,
            user: msg.sender,
            token: _token,
            amount: _amount,
            isMB1: _isMB1
        });
        emit Withdraw(withdrawRequestCount, msg.sender, _nftID, _token, _amount, _chainID, _isMB1);
        withdrawRequestCount++;
    }

    function withdrawMultiple(uint256[] calldata _nftIDs, address[] calldata _tokens, uint256[] calldata _amounts, uint256[] calldata _chainIDs, bool _isMB1) external {
        WithdrawMultipleRequests[withdrawMultipleRequestCount] = WithdrawMultipleRequest({ 
            withdrawMultipleRequestID: withdrawMultipleRequestCount, 
            nftIDs: _nftIDs,
            chainIDs: _chainIDs,
            user: msg.sender,
            tokens: _tokens,
            amounts: _amounts,
            isMB1: _isMB1
        });        
        emit WithdrawMultiple(withdrawRequestCount, msg.sender, _nftIDs, _tokens, _amounts, _chainIDs, _isMB1);
        withdrawRequestCount++;
    }

    event Withdraw(uint256 indexed withdrawRequestID, address indexed user, uint256 indexed nftID, address token, uint256 amount, uint256 chainID, bool isMB1);
    event WithdrawMultiple(uint256 indexed withdrawRequestID, address indexed user, uint256[] indexed nftIDs, address[] tokens, uint256[] amounts, uint256[] chainIDs, bool isMB1);
}