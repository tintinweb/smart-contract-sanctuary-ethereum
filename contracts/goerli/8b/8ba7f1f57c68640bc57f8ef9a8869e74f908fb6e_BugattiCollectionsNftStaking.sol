// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC721A.sol";



contract BugattiCollectionsNftStaking is Ownable, ReentrancyGuard, Pausable{
    IERC721A public Collection;

    uint256 public minStakeDuration = 90 days; // 3 Months

    event UpdateUserCount(address indexed user, uint256 count);

    mapping(address => Staker) public stakers;
    mapping(uint256 => Token) public stakerAddress;

    struct Token {
        address user;
        uint256 tokenId;
        uint256 timeAdded;
    }

    struct Staker {
        uint256 totalStakedTokens;
        Token[] stakedTokens;
    }

    constructor(IERC721A tokenAddress) {
        Collection = tokenAddress;
        pause();
    }


    modifier stakedTimeCheck(address user, uint256 _tokenId){
        require(stakerAddress[_tokenId].timeAdded+minStakeDuration<block.timestamp,"Token can't be claimed yet.");
        _;
    }

    modifier userOwnsTheStakedToken(address user, uint256 _tokenId){
        require(stakerAddress[_tokenId].user==user,"You don't own this token.");
        _;
    }

    modifier hasUserStaked(address user){
        require(stakers[user].totalStakedTokens>0,"You have no tokens to withdraw.");
        _;
    }


    modifier ownerVerify(address owner, uint256 tokenId){
        require(Collection.ownerOf(tokenId)==owner,"You don't own this token.");
        _;
    }

    function stake(uint256 _tokenId) external nonReentrant
    whenNotPaused
    ownerVerify(msg.sender,_tokenId)
    {
        Collection.transferFrom(msg.sender, address(this), _tokenId);

        Token memory stakedToken = Token(msg.sender, _tokenId, block.timestamp);
        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].totalStakedTokens++;
        emit UpdateUserCount(msg.sender,stakers[msg.sender].totalStakedTokens);
        stakerAddress[_tokenId] = stakedToken;
    }

    function unstake(uint256 _tokenId) external nonReentrant
    whenNotPaused
    hasUserStaked(msg.sender)
    userOwnsTheStakedToken(msg.sender, _tokenId)
    stakedTimeCheck(msg.sender, _tokenId)
    {
        
         uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].user != address(0)
            ) {
                index = i;
                break;
            }
        }
        stakers[msg.sender].totalStakedTokens--;
        emit UpdateUserCount(msg.sender,stakers[msg.sender].totalStakedTokens);
        delete stakerAddress[_tokenId];
        delete stakers[msg.sender].stakedTokens[index];
        Collection.transferFrom(address(this), msg.sender, _tokenId);

    }

    function getStakedTokens(address _user) public view returns (Token[] memory) {
        if (stakers[_user].totalStakedTokens > 0) {
            Token[] memory _stakedTokens = new Token[](stakers[_user].totalStakedTokens);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].user != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        else {
            return new Token[](0);
        }
    }




    // ADMIN FUNCTIONS
    function updateStakingDuration(uint256 duration) public onlyOwner{
        minStakeDuration = duration;
    }

    function adminUnStake(address user, uint256 tokenId) public onlyOwner
    hasUserStaked(user)
    userOwnsTheStakedToken(user, tokenId)
    {
         uint256 index = 0;
        for (uint256 i = 0; i < stakers[user].stakedTokens.length; i++) {
            if (
                stakers[user].stakedTokens[i].tokenId == tokenId 
                && 
                stakers[user].stakedTokens[i].user != address(0)
            ) {
                index = i;
                break;
            }
        }
        stakers[user].totalStakedTokens--;
        emit UpdateUserCount(user,stakers[user].totalStakedTokens);
        delete stakerAddress[tokenId];
        delete stakers[user].stakedTokens[index];
        Collection.transferFrom(address(this), user, tokenId);
    }

    function pause() public whenNotPaused onlyOwner{
        _pause();
    }
    
    function unpause() public whenPaused onlyOwner{
        _unpause();
    }


    function updateNftContract(IERC721A NftAddress) public onlyOwner{
        Collection=NftAddress;
    }

}