/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(address to, uint noOfTokens) external;
    function transferFrom(address from, address to, uint noOfTokens) external;
    function allowance(address owner, address spender) external view returns(uint);
    function balance(address owner) external view returns(uint);
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract Stake {
    event Debug(uint _tokenId, address _addr);

    IERC20 erc20;
    IERC721 erc721;

    address public owner;
    uint256 public rewardAmount;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public startTime = 5 minutes;
    uint256 public endTime = 1 hours;

    mapping (address => uint256) internal  erc20Amount;
    //array for storing staked nft ids of an address
    mapping (address => uint256 []) internal  erc721Tokens;
     
    constructor(address _erc20, address _erc721, uint256 _rewardRate) {
        owner = msg.sender;
        erc20 = IERC20(_erc20);
        erc721 = IERC721(_erc721);
        rewardRate = _rewardRate;
    }

    function addRewardAmount(uint256 _amount) external {
        require(msg.sender == owner, "not the contract owner");
        require(_amount <= erc20.allowance(msg.sender, address(this)), "Not enough tokens allowed to this contract ");
        erc20.transferFrom(owner, address(this), _amount);
        rewardAmount += _amount;
    }

    function stakeERC20(uint256 _noTokens) external {
        require(block.timestamp < startTime, "stake already started");
        require(_noTokens > 0 && _noTokens <= erc20.balance(msg.sender), "tokens amount invalid");
        require(_noTokens <= erc20.allowance(msg.sender, address(this)), "Not enough tokens allowed to this contract ");
        //checks if contract has enough erc20 tokens to send reward after time up
        require(((totalStaked + _noTokens) + totalStaked) * rewardRate <= rewardAmount, "Staking Full! cannot stake more tokens");
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
        require(((totalStaked + 1) + totalStaked) * rewardRate <= rewardAmount, "Staking Full! cannot stake more tokens");
        erc721.transferFrom(erc721.ownerOf(_tokenId), address(this), _tokenId);
        erc721Tokens[msg.sender].push(_tokenId);
        totalStaked += 1;
    }

    function getERC20Reward() external {
        require(block.timestamp > endTime, "Stake time not finished yet");
        require(erc20Amount[msg.sender] > 0 , "not staked any tokens");
        totalStaked -= erc20Amount[msg.sender];
        erc20Amount[msg.sender] = 0;
        erc20.transfer(msg.sender, erc20Amount[msg.sender] + (erc20Amount[msg.sender] * rewardRate));
    }

    function getERC721Reward() external {
        require(block.timestamp > endTime, "Stake time not finished yet");
        require(erc721Tokens[msg.sender].length > 0 , "not staked any NFTs");
        totalStaked -= erc721Tokens[msg.sender].length;
        while (erc721Tokens[msg.sender].length > 0) {
            erc721.transferFrom(address(this), msg.sender, erc721Tokens[msg.sender][erc721Tokens[msg.sender].length - 1]);
            erc721Tokens[msg.sender].pop();
        }
        erc20.transfer(msg.sender, erc20Amount[msg.sender] + (erc20Amount[msg.sender] * rewardRate));
    }
}