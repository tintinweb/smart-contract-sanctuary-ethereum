/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
 function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnbyContract(uint256 _amount) external;
    function withdrawStakingReward(address _address,uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    function getFreeMintingTime(uint256 tokenId) external view returns(uint256);
    function getDutchMintingTime(uint256 tokenId) external view returns(uint256);
    function getIdType(uint256 tokenId) external view returns(uint256);
    function overridee(uint256 tokenId) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract Berry_Staking_V1{

    using SafeMath for uint256;
    IERC20 public Token;
    IERC721 public NFT;
    constructor (IERC721 NFT_, IERC20 token_){
        NFT = NFT_;
        Token = token_;
    }

///////////////////////////////////////////////////////////////


    uint256 public slotTime = 1 minutes;
    uint256 public rewTime = 1440 minutes;   // 1 day
    
    uint256 public rewPerMinutForFreeMint = 13888888888888900;      // 20 token/day
    uint256 public rewPerMinutForDutchMint = 69444444444444400;     // 100 token/day
    uint256 public RewardPerNFT = 6944444444444400;        // 10 token/day for pre/public sale

    uint256 public finalTimeForFreeMint = 1 days;  // 150 days
    uint256 public finalTimeForDutchMint = 1 days; // 100 days

    // uint256 public maxNoOfdaysForFreeMint = 216000;      // 150 days
    uint256 public maxNoOfdaysForFreeMint = 1440;

    // uint256 public maxNoOfdaysForDutchMint = 144000;     // 100 days
    uint256 public maxNoOfdaysForDutchMint = 1440;

    uint256 public bonusReward = 300000000000000000000;

     struct User
    {
        uint256 TotalWithdrawn;
        uint256 TotalStaked;
    }

    /////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////

    mapping(address => uint256[]) public lockedTokenIds;
    mapping(address => mapping(uint256 => uint256)) public lockedStakingTime;
    mapping(address => User) public UserInfo;
    mapping(address=>uint256) public lockedTotalStakedNft;
    mapping (uint256 => bool) public alreadyAwarded;
    mapping(address => mapping(uint256 => uint256)) public rewardedAmount;

    // =============================================================
    // =============================================================


    function lockedStaking(address _user, uint256 tokenId) public {
        lockedTokenIds[_user].push(tokenId);
        lockedStakingTime[_user][tokenId] = block.timestamp;
        
        UserInfo[_user].TotalStaked += 1;
        lockedTotalStakedNft[_user] += 1;
    }
    /////////////////////////////////////////////////////////////////

    function calcTime(uint256 tokenID) public view returns(uint256) {
        uint256 rewardTime;
        if(NFT.getIdType(tokenID) == 1){
        // if(getType(tokenID) == 1){
            rewardTime += (block.timestamp.sub(NFT.getFreeMintingTime(tokenID))).div(slotTime);
            if(rewardTime >= maxNoOfdaysForFreeMint){
                rewardTime = maxNoOfdaysForFreeMint;
            }
        }

        else if(NFT.getIdType(tokenID) == 2){
            rewardTime += (block.timestamp.sub(NFT.getDutchMintingTime(tokenID))).div(slotTime);
            if(rewardTime >= maxNoOfdaysForDutchMint){
                rewardTime = maxNoOfdaysForDutchMint;
            }
        }
        return rewardTime;
    }

    function lockedReward(uint256 tokenId) public view returns(uint256){
        uint256 reward;
        address _user = msg.sender;
        uint256 noOfDays = calcTime(tokenId);
        
        if(NFT.getIdType(tokenId) == 1){
            reward += (noOfDays).mul(rewPerMinutForFreeMint);
        }
        else if(NFT.getIdType(tokenId) == 2){
            reward += (noOfDays).mul(rewPerMinutForDutchMint);
        }
        return reward - rewardedAmount[_user][tokenId];
    }
    
    function lockedWithdrawReward(uint256 tokenId) public {
        address _user = msg.sender;
        uint256 reward = lockedReward(tokenId);
        rewardedAmount[_user][tokenId] += reward;
        if(NFT.getIdType(tokenId) == 1 || NFT.getIdType(tokenId) == 2){

            if(!alreadyAwarded[NFT.getIdType(tokenId)]){
                reward += bonusReward;
                alreadyAwarded[NFT.getIdType(tokenId)] = true;  // true the tokenId type
            }
        }

        Token.transfer(_user, reward);
        UserInfo[_user].TotalWithdrawn += reward;

    }

    //  this will use in single reward function for presale and public sale mint

    function getTokenIdTime(uint256 tokenId) public view returns(uint256){
        uint256 MintTime;
        if(NFT.getIdType(tokenId) == 1){
            MintTime = NFT.getFreeMintingTime(tokenId);
        }
        else if(NFT.getIdType(tokenId) == 2){
            MintTime = NFT.getDutchMintingTime(tokenId);
        }
        return MintTime; 
    }

    function singleUnStakeLocked(uint256 tokenId) public {
        address _user = msg.sender;
        uint256 _index = findIndex(tokenId);
        require(block.timestamp 
        > (getTokenIdTime(lockedTokenIds[_user][_index])
        +finalTimeForFreeMint),
        "time not reached for Unstake");

        lockedWithdrawReward(tokenId);
        NFT.transferFrom(address(this), address(_user), tokenId);
        // NFT.transferFrom(address(this), address(_user), lockedTokenIds[_user][_index]);
        delete lockedTokenIds[_user][_index];
        lockedTokenIds[_user][_index] = lockedTokenIds[_user][lockedTokenIds[_user].length - 1];
        lockedTokenIds[_user].pop();
        NFT.overridee(tokenId);

        UserInfo[_user].TotalStaked -= 1;
        lockedTotalStakedNft[_user]>0?lockedTotalStakedNft[_user] -= 1 : lockedTotalStakedNft[_user]=0;
    }

    function lockedUnstakeAll() public {
        address _user = msg.sender;
        uint256 _index;
        uint256[] memory tokenIds = getIds(_user);
        require(tokenIds.length > 0, "you have no Id to unstake");
        for(uint256 i; i< tokenIds.length; i++){
            _index = findIndex(tokenIds[i]);
            lockedWithdrawReward(lockedTokenIds[_user][_index]);
            NFT.transferFrom(address(this), address(_user), lockedTokenIds[_user][_index]);
            NFT.overridee(lockedTokenIds[_user][_index]);
            delete lockedTokenIds[_user][_index];
            lockedTokenIds[_user][_index] = lockedTokenIds[_user][lockedTokenIds[_user].length - 1];
            lockedTokenIds[_user].pop();

            UserInfo[_user].TotalStaked -= 1;
            lockedTotalStakedNft[_user]>0?lockedTotalStakedNft[_user] -= 1 : lockedTotalStakedNft[_user]=0;
        }
    }

    function getIds(address _user) public view returns(uint256[] memory){
        uint256[] memory tokenIds = new uint256[](getTotalIds(_user).length);
        for (uint256 i=0; i< getTotalIds(_user).length; i++){
            if(calcTime(lockedTokenIds[_user][i]) == maxNoOfdaysForFreeMint
                || 
                calcTime(lockedTokenIds[_user][i]) == maxNoOfdaysForDutchMint)
            {
                tokenIds[i] = lockedTokenIds[_user][i];
            }
        }
        return tokenIds;
    }


    //  ============================================================
    //  ============================================================

    function setFreeMintReward(uint256 tokenIdReward) public {
        rewPerMinutForFreeMint = ((tokenIdReward).mul(1 ether)).div(rewTime);
    }

    function setDutchMintReward(uint256 tokenIdReward) public {
        rewPerMinutForDutchMint = ((tokenIdReward).mul(1 ether)).div(rewTime);
    }
    function setPrePublicReward(uint256 tokenIdReward) public {
        RewardPerNFT = ((tokenIdReward).mul(1 ether)).div(rewTime);
    }

    function getIDType(uint256 tokenId) public view returns(uint256){
        return NFT.getIdType(tokenId);
    }

    function getTotalIds(address _user) public view returns(uint256[] memory){
        return lockedTokenIds[_user];
    }

    function findIndex(uint256 value) public view returns(uint256){
        uint256 i = 0;
        while(lockedTokenIds[msg.sender][i] != value){
            i++;
        }
        return i;
    }

    //////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////

   
    struct user
    {
        uint256 totlaWithdrawn;
        uint256 myNFT;
        uint256 availableToWithdraw;
    }

    mapping(address => mapping(uint256 => uint256)) public userStakingTime;
    mapping(address => user ) public User_Info;
    mapping(address => uint256[] ) public userTokenIds;
    mapping(address=>uint256) public TotalUserStakedNft;
    mapping(uint256=>bool) public userAlreadyAwarded;
    mapping(address=>mapping(uint256=>uint256)) public normalDepositTime;

    ///////////////////////////////////////////////////////////////////////    
    function Stake(uint256[] memory tokenId) external 
    {
       for(uint256 i=0;i<tokenId.length;i++){
            require(NFT.ownerOf(tokenId[i]) == msg.sender,"nft not found");
            NFT.transferFrom(msg.sender,address(this),tokenId[i]);
            userTokenIds[msg.sender].push(tokenId[i]);
            userStakingTime[msg.sender][tokenId[i]]=block.timestamp;
            if(!userAlreadyAwarded[tokenId[i]])
            {
                normalDepositTime[msg.sender][tokenId[i]]=block.timestamp;
            }
        }
       
       User_Info[msg.sender].myNFT += tokenId.length;
       TotalUserStakedNft[msg.sender]+=tokenId.length;
    }

    function normalCalcTime(uint256 tokenId) public view returns(uint256){
        uint256 timeSlot = ((block.timestamp).sub(userStakingTime[msg.sender][tokenId])).div(slotTime);
        return timeSlot;
    }

    function userSingleReward( address _user,uint256 tokenId) public view returns(uint256){
        uint256 reward;
        uint256 timeSlot = normalCalcTime(tokenId);
        reward += (timeSlot).mul(RewardPerNFT);
        return reward - rewardedAmount[_user][tokenId];
    }
 
    function userTotalReward(address _user) public view returns(uint256) {
        uint256[] memory tokenIds = userStakedNFT(_user);
        uint256 reward;
        for(uint256 i; i< tokenIds.length; i++){
            reward += userSingleReward(_user, tokenIds[i]);
        }
        return reward;
    }

    function WithdrawReward(uint256 TokenId)  public {

       address _user = msg.sender;
       uint256 reward = userSingleReward(_user, TokenId);
       require(reward > 0,"you don't have reward yet!");
       Token.transfer(_user,reward); 
       rewardedAmount[_user][TokenId] += reward;

       User_Info[msg.sender].totlaWithdrawn +=  reward;

       for(uint256 i = 0 ; i < userTokenIds[_user].length ; i++){
        userAlreadyAwarded[userTokenIds[_user][i]]=true;
       }
    }

    function find(uint value) public view returns(uint) {
        uint i = 0;
        while (userTokenIds[msg.sender][i] != value) {
            i++;
        }
        return i;
    }

    function unstake(uint256 _tokenId)  external 
        {
        WithdrawReward(_tokenId);
        uint256 _index=find(_tokenId);
        require(userTokenIds[msg.sender][_index] ==_tokenId ,"NFT with this _tokenId not found");
        NFT.transferFrom(address(this),msg.sender,_tokenId);
        delete userTokenIds[msg.sender][_index];
        userTokenIds[msg.sender][_index]=userTokenIds[msg.sender][userTokenIds[msg.sender].length-1];
        userStakingTime[msg.sender][_tokenId]=0;
        userTokenIds[msg.sender].pop();
        User_Info[msg.sender].myNFT -= 1;
        TotalUserStakedNft[msg.sender] > 0 ? TotalUserStakedNft[msg.sender] -= 1 : TotalUserStakedNft[msg.sender]=0;

        // emit unstakeSingle(msg.sender, _tokenId);
    }

    function unStakeAll(uint256[] memory _tokenIds)  external 
    {
        for(uint256 i=0;i<_tokenIds.length;i++){
        uint256 _index=find(_tokenIds[i]);
        require(userTokenIds[msg.sender][_index] ==_tokenIds[i] ,"NFT with this _tokenId not found");
        WithdrawReward(_tokenIds[i]);
        NFT.transferFrom(address(this), msg.sender, _tokenIds[i]);
        delete userTokenIds[msg.sender][_index];
        userTokenIds[msg.sender][_index ] = userTokenIds[msg.sender][userTokenIds[msg.sender].length-1];
        userTokenIds[msg.sender].pop();
        userStakingTime[msg.sender][_tokenIds[i]]=0;

        }
        User_Info[msg.sender].myNFT -= _tokenIds.length;
        TotalUserStakedNft[msg.sender]>0?TotalUserStakedNft[msg.sender] -= _tokenIds.length:TotalUserStakedNft[msg.sender]=0;
       
    }

    function isNormalStaked(address _stakeHolder)public view returns(bool){
        if(TotalUserStakedNft[_stakeHolder]>0){
        return true;
        }else{
        return false;
        }
    }

    function userStakedNFT(address _staker)public view returns(uint256[] memory) {
       return userTokenIds[_staker];
    }
 
}