/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LabFaucet {

    struct user_details {
        mapping(address => uint) latest_request;
        mapping(address => bool) request_permission;
    } 

    address public manager;
    mapping(address => user_details) user_token_mapping; 
    mapping(address => uint256) faucet_amount; //Amount of tokens sent by faucet per user per day

    constructor() {
        manager = msg.sender;    
    }

    function set_faucet_amount(address token_address, uint256 value) public {
        require(
            msg.sender == manager,
            "Only manager can register users"
        );
        faucet_amount[token_address]=value;
    }

    function registerUsers(address[] calldata user_list, address token_address) public {
        require(
            msg.sender == manager,
            "Only manager can register users"
        );
        for(uint256 i=0; i< user_list.length; i++)
            user_token_mapping[user_list[i]].request_permission[token_address] = true;
    }

    function deRegisterUsers(address[] calldata user_list, address token_address) public {
        require(
            msg.sender == manager,
            "Only manager can deregister users"
        );
        for(uint256 i=0; i< user_list.length; i++)
            user_token_mapping[user_list[i]].request_permission[token_address] = false;
    }

    function requestTokens(IERC20 token) public {
        require(
            user_token_mapping[msg.sender].request_permission[address(token)] == true,
            "Only registered users can use this airdrop"
        );
        require(
            user_token_mapping[msg.sender].latest_request[address(token)] <= block.timestamp - 86400,
            "Only one request per day" 
        );
        require(
            faucet_amount[address(token)]>0,
            "This faucet does not support the token provided" 
        );
        require(
            token.balanceOf(address(this))>=faucet_amount[address(token)],
            "The faucet has exhaused its tokens, replenish faucet"
        );
        token.transfer(msg.sender,faucet_amount[address(token)]);
        user_token_mapping[msg.sender].latest_request[address(token)] = block.timestamp;
    }

    function retrieveFaucetAmount(IERC20 token) public view returns(uint256){
        return faucet_amount[address(token)];
    }

    function retrieveFaucetBalance(IERC20 token) public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getRegistrationStatus(address user_address, address token_address) public view returns(bool){
        return user_token_mapping[user_address].request_permission[token_address];
    }

    function getLatestRequestTimestamp(address user_address, address token_address) public view returns(uint){
        return user_token_mapping[user_address].latest_request[token_address];
    }

}