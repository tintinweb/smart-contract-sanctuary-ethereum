// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./ERC721.sol";

contract Stake {
    ERC20 erc20;
    ERC721 erc721;

    address public owner;
    uint256 public rewardAmount;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public startTime;
    uint256 public endTime;

    mapping (address => uint256) internal  erc20Amount;
    //array for storing staked nft ids of an address
    mapping (address => uint256 []) internal  erc721Tokens;
     
    constructor(address _erc20, address _erc721, uint256 _rewardRate) {
        owner = msg.sender;
        erc20 = ERC20(_erc20);
        erc721 = ERC721(_erc721);
        rewardRate = _rewardRate;
    }

    function addRewardAmount(uint256 _amount) external {
        require(msg.sender == owner, "not the contract owner");
        erc20.transferFrom(owner, address(this), _amount);
        rewardAmount += _amount;
    }

    function stakeERC20(uint256 _noTokens, uint256) external {
        require(block.timestamp < startTime, "stake already started");
        require(_noTokens > 0 && _noTokens <= erc20.balance(msg.sender), "tokens amount invalid");
        require(_noTokens <= erc20.allowance(msg.sender, address(this)), "Not enough tokens allowed to this contract ");
        //checks if contract has enough erc20 tokens to send reward after time up
        require((totalStaked + _noTokens) * rewardRate <= rewardAmount, "Staking Full! cannot stake more tokens");
        erc20.transferFrom(msg.sender, address(this), _noTokens);
        erc20Amount[msg.sender] += _noTokens;
        totalStaked += _noTokens;
    }

    function stakeERC721(uint256 _tokenId) external {
        require(block.timestamp < startTime, "stake already started");
        require(erc721.ownerOf(_tokenId) == msg.sender || 
            erc721.isApprovedForAll(erc721.ownerOf(_tokenId), msg.sender), "invalid token");
        require(erc721.getApproved(_tokenId) == address(this), "NFT not allowed to this contract");
        //checks if contract has enough erc20 tokens to send reward after time up
        require((totalStaked + 1) * rewardRate <= rewardAmount, "Staking Full! cannot stake more tokens");
        erc721.transferFrom(erc721.ownerOf(_tokenId), address(this), _tokenId);
        erc721Tokens[msg.sender].push(_tokenId);
        totalStaked += 1;
    }

    function getERC20Reward() external {
        require(block.timestamp > endTime, "Stake time not finished yet");
        require(erc20Amount[msg.sender] > 0 , "not staked any tokens");
        totalStaked -= erc20Amount[msg.sender];
        erc20Amount[msg.sender] = 0;
        erc20.transfer(msg.sender, erc20Amount[msg.sender] * rewardRate);
    }

    function getERC721Reward() external {
        require(block.timestamp > endTime, "Stake time not finished yet");
        require(erc721Tokens[msg.sender].length > 0 , "not staked any NFTs");
        totalStaked -= erc721Tokens[msg.sender].length;
        while (erc721Tokens[msg.sender].length > 0) {
            uint256 lastItem = erc721Tokens[msg.sender][erc721Tokens[msg.sender].length - 1];
            //transfering NFTs ownership back to owner;
            erc721.transferFrom(address(this), msg.sender, lastItem);
            delete erc721Tokens[msg.sender][erc721Tokens[msg.sender].length - 1];
        }
        erc20.transfer(msg.sender, erc20Amount[msg.sender] * rewardRate);
    }

}