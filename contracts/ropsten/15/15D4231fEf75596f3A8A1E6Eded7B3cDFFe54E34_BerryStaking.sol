/**
 *Submitted for verification at Etherscan.io on 2022-08-23
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
    function forMintingTimeZero(uint256 tokenID) external;
    function setTokenIdType(uint256 tokenId) external;
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

contract BerryStaking is Ownable{

    using SafeMath for uint256;
    IERC20 public Token;
    IERC721 public NFT;
    constructor (IERC721 NFT_, IERC20 token_){
        NFT = NFT_;
        Token = token_;
    }

    uint256 public slotTime = 1 minutes;
    uint256 public rewTime = 1440;        
    uint256 public rewardFreeMint = 20;
    uint256 public rewardDutchMint = 20;
    uint256 public genesisRewarad = 100;
    uint256 public boosterRewarad = 150;
    uint256 public commonReward = 10;                     
    uint256 public finalTimeForFreeMint = 150 days;       
    uint256 public finalTimeForDutchMint = 100 days;      
    uint256 public maxNoOfdaysForFreeMint = 216000;             
    uint256 public maxNoOfdaysForDutchMint = 144000;           

    uint256 public bonusReward = 300 ether;  

    ///////////////////////  lockedStruct  ///////////////////////

    struct lockedUser
    {
        uint256 TotalWithdrawn;
        uint256 TotalStaked;
    }

    ///////////////////////  normalStruct  ///////////////////////

    struct user
    {
        uint256 totlaWithdrawn;
        uint256 myNFT;
        uint256 availableToWithdraw;
    }

    ///////////////////  lockedStaking Mappings  ///////////////////
    mapping(address => uint256[]) public lockedTokenIds;
    mapping(address => mapping(uint256 => uint256)) public lockedStakingTime;
    mapping(address => lockedUser) public UserInfo;
    mapping(address=>uint256) public lockedTotalStakedNft;
    mapping (address => bool) public alreadyAwarded;
    mapping(address => mapping(uint256 => uint256)) public rewardedAmount;

    //////////////////  nomralStaking Mappings /////////////////////
    mapping(address => mapping(uint256 => uint256)) public userStakingTime;
    mapping(address => user ) public User_Info;
    mapping(address => uint256[] ) public userTokenIds;
    mapping(address=>uint256) public TotalUserStakedNft;

    //////////////////  lockedStaking Events /////////////////////
    event lockedStake(address indexed from, address indexed to, uint256 indexed _count);
    event lockedWithDraw(address indexed from, address indexed to, uint256 indexed reward);
    event lockedSingleUnstake(address indexed from, address indexed to, uint256 indexed tokenId);
    event lockedUnStakeAll(address indexed from, address indexed to, uint256 indexed _count);

    //////////////////////  normalStakin Events  /////////////////////
    event normalStake(address indexed from, address indexed to, uint256 indexed _count);
    event normalWithDraw(address indexed from, address indexed to, uint256 indexed _reward);
    event normalSingleUnstake(address indexed from, address indexed to, uint256 indexed tokenId);
    event normalUnstakeAll(address indexed from, address indexed to, uint256 indexed _count);

    modifier onlyMinter(){
        require(address(NFT) == msg.sender, "caller is not the minter");
        _;
    }
    /*
    * this function store ID directly from minting contract and store for spacific time,
    * only minter can call this fucntion.
    */
    function lockedStaking(address _user, uint256 tokenId) external 
    onlyMinter 
    {
        lockedTokenIds[_user].push(tokenId);
        lockedStakingTime[_user][tokenId] = block.timestamp;
        
        UserInfo[_user].TotalStaked += 1;
        lockedTotalStakedNft[_user] += 1;

        emit lockedStake(_user, address(this), tokenId);
    }
    
    function calcTime(uint256 tokenID) public view returns(uint256) {
        uint256 rewardTime;
        if(NFT.getIdType(tokenID) == 1){
            if(NFT.getFreeMintingTime(tokenID) > 0){
                rewardTime += (block.timestamp.sub(NFT.getFreeMintingTime(tokenID))).div(slotTime);
                if(rewardTime >= maxNoOfdaysForFreeMint){
                    rewardTime = maxNoOfdaysForFreeMint;
                }
            }
        }

        else if(NFT.getIdType(tokenID) == 2){
            if(NFT.getDutchMintingTime(tokenID) > 0){
                    rewardTime += (block.timestamp.sub(NFT.getDutchMintingTime(tokenID))).div(slotTime);
                    if(rewardTime >= maxNoOfdaysForDutchMint){
                    rewardTime = maxNoOfdaysForDutchMint;
                }
            }
        }
        return rewardTime;
    }

    /*
    *   reward will be generated as pre requierements (for locked tokenIds)
    *   20 tokens reward will be generated for freeMint Ids till 150 days and
    *   also for dutch minted for 100 days
    */ 

    function lockedReward(address _user, uint256 tokenId) public view returns(uint256 idReward_){
        uint256 reward =0;
        uint256 noOfDays = calcTime(tokenId);
        
        if(NFT.getIdType(tokenId) == 1){
            reward += (((noOfDays).mul(rewardFreeMint).mul(1 ether))).div(rewTime);
        }
        else if(NFT.getIdType(tokenId) == 2){
            reward += (((noOfDays).mul(rewardDutchMint)).mul(1 ether)).div(rewTime);  
        }
        return (reward - rewardedAmount[_user][tokenId]);
    }

    /*
    *   this function will call to withdraw reward of locked TokenIds 
    *   A bonus reward will also be given to user only 
    *   when he gets the reward for the first time
    */
    
    function lockedWithdrawReward(uint256 tokenId) public {
        require(Token.balanceOf(address(this)) > 0);
        address _user = msg.sender;
        uint256 TotalReward;
        uint256 reward = lockedReward(_user, tokenId);
        rewardedAmount[_user][tokenId] += reward;

        if(!alreadyAwarded[_user]){
            alreadyAwarded[_user] = true;  // true the tokenId type
        }
        TotalReward = (reward+getBonus(_user));      
        Token.transfer(_user, reward);
        UserInfo[_user].TotalWithdrawn += reward;
        emit lockedWithDraw(address(this), _user, reward);
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

    /*
    *   this function will unstake the single locked Id when its lockedTime will complete
    *   tokenId will move to owner's address in minted contract
    */

    function lockedSingleUnStake(uint256 tokenId) public {
        address _user = msg.sender;
        uint256 _index = findIndex(tokenId);
  
        lockedWithdrawReward(tokenId);
        NFT.transferFrom(address(this), _user, tokenId);
        delete lockedTokenIds[_user][_index];
        lockedTokenIds[_user][_index] = lockedTokenIds[_user][lockedTokenIds[_user].length - 1];
        lockedTokenIds[_user].pop();
        rewardedAmount[_user][tokenId] = 0;
        NFT.forMintingTimeZero(tokenId);
        NFT.setTokenIdType(tokenId);

        UserInfo[_user].TotalStaked -= 1;
        lockedTotalStakedNft[_user]>0?lockedTotalStakedNft[_user] -= 1 : lockedTotalStakedNft[_user]=0;
        emit lockedSingleUnstake(address(this), _user, tokenId);
    }

    /*
    *   this function will call only wahen all Ids' time will complete 
    *   all Ids will directly move to owner's address in minting contract 
    */

    function lockedUnstakeAll() public {
        address _user = msg.sender;
        uint256 _index;
        uint256[] memory tokenIds = getIds(_user);
        require(tokenIds.length > 0, "you have no Id to unstake");
        for(uint256 i; i< tokenIds.length; i++){
            _index = findIndex(tokenIds[i]);
            lockedWithdrawReward(lockedTokenIds[_user][_index]);
            NFT.transferFrom(address(this), address(_user), lockedTokenIds[_user][_index]);
            NFT.forMintingTimeZero(lockedTokenIds[_user][_index]);
            NFT.setTokenIdType(lockedTokenIds[_user][_index]);
            delete lockedTokenIds[_user][_index];
            lockedTokenIds[_user][_index] = lockedTokenIds[_user][lockedTokenIds[_user].length - 1];
            rewardedAmount[_user][tokenIds[i]] = 0;
            lockedTokenIds[_user].pop();

            UserInfo[_user].TotalStaked -= 1;
            lockedTotalStakedNft[_user]>0?lockedTotalStakedNft[_user] -= 1 : lockedTotalStakedNft[_user]=0;
        }
        emit lockedUnStakeAll(address(this), _user, tokenIds.length);
    }

    // this function will show the Ids with completed Ids 

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

    // this function will show the tokenId type 
    function getIDType(uint256 tokenId) public view returns(uint256){
        return NFT.getIdType(tokenId);
    }

    // this function will show the total locked Ids against any user

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

    // this function will show the remaining time of locked TokenId
    function remainingTime(uint256 tokenId) public view returns(uint256){
        uint256 _remainingTime;
        if(NFT.getIdType(tokenId) == 1){
            if(block.timestamp >= (NFT.getFreeMintingTime(tokenId)).add(finalTimeForFreeMint)){
                _remainingTime = 0;
            }
            else{
                _remainingTime += (((NFT.getFreeMintingTime(tokenId)).add(finalTimeForFreeMint)).sub(block.timestamp)).div(slotTime);

            }
        }
        else if(NFT.getIdType(tokenId) == 2){
            if(block.timestamp >= (NFT.getDutchMintingTime(tokenId)).add(finalTimeForDutchMint)){
                _remainingTime = 0;
            }
            else{
                _remainingTime += (((NFT.getDutchMintingTime(tokenId)).add(finalTimeForDutchMint)).sub(block.timestamp)).div(slotTime);

            } 
        }
        
        return _remainingTime.mul(60);
    }

    /*
    *   This function will stake Ids manually that are minted in public, genesis, uncommon or booster
    */
    function Stake(uint256[] memory tokenId) external 
    {
       for(uint256 i=0;i<tokenId.length;i++){
            require(NFT.ownerOf(tokenId[i]) == msg.sender,"nft not found");
            NFT.transferFrom(msg.sender,address(this),tokenId[i]);
            userTokenIds[msg.sender].push(tokenId[i]);
            userStakingTime[msg.sender][tokenId[i]]=block.timestamp;
        }
       
       User_Info[msg.sender].myNFT += tokenId.length;
       TotalUserStakedNft[msg.sender]+=tokenId.length;
       emit normalStake(msg.sender, address(this), tokenId.length);
    }

    /*
    *   this function will generate reward of single staked TokenId
    *   genesis Id will get 100 tokens per day as reward
    *   booster Id will get 150 tokens per day as reward
    *   All other Ids will get 10 tokens per day as reward
    */

    function userSingleReward( address _user,uint256 tokenId) public view returns(uint256 tokenIdReward){
        uint256 reward = 0;
        uint256 timeSlot = ((block.timestamp).sub(getTime(_user, tokenId))).div(slotTime);
        if(NFT.getIdType(tokenId) == 6){
            if(getTime(_user, tokenId) > 0){
                reward += ((timeSlot).mul(genesisRewarad).mul(1 ether)).div(rewTime);
            }
        }
        else if(NFT.getIdType(tokenId) == 7){
            if(getTime(_user, tokenId) > 0){
                reward += ((timeSlot).mul(boosterRewarad).mul(1 ether)).div(rewTime);
            }
        }
        else {
            if(getTime(_user, tokenId) > 0){
                reward += ((timeSlot).mul(commonReward).mul(1 ether)).div(rewTime);
            }
        }
        return (reward - rewardedAmount[_user][tokenId]);
    }

    /*
    *   this function will call to withdraw reward of any tokenId staked in this contact
    *   user must have reward to call this function
    *   a bonus reward will also be given to user when he calls this function for first time 
    */
 
    function withDrawReward(uint256 TokenId)  public {

       address _user = msg.sender;
       uint256 TotalReward;
       uint256 reward = userSingleReward(_user, TokenId);
       require(reward > 0,"you don't have reward yet!");

        if(!alreadyAwarded[_user]){
            alreadyAwarded[_user] = true;  // true the tokenId type
        }
       TotalReward = (reward+getBonus(_user));      
       Token.transfer(_user, TotalReward); 
       rewardedAmount[_user][TokenId] += reward;

       User_Info[msg.sender].totlaWithdrawn +=  reward;
       emit normalWithDraw(address(this), _user, reward);
    }

    // this function will show the indexed of staked tokenId in an array

    function find(uint value) public view returns(uint) {
        uint i = 0;
        while (userTokenIds[msg.sender][i] != value) {
            i++;
        }
        return i;
    }

    /*
    *   this function will unstake single staked tokenId 
    *   tokenId will directly move to caller's address in minted contract
    */
    function unstake(uint256 _tokenId)  external 
    {
        address _user = msg.sender;

        if(userSingleReward(_user, _tokenId) > 0){
            withDrawReward(_tokenId);
        }
        uint256 _index=find(_tokenId);
        require(userTokenIds[msg.sender][_index] ==_tokenId ,"NFT with this _tokenId not found");
        NFT.transferFrom(address(this),msg.sender,_tokenId);
        delete userTokenIds[msg.sender][_index];
        userTokenIds[msg.sender][_index]=userTokenIds[msg.sender][userTokenIds[msg.sender].length-1];
        userStakingTime[msg.sender][_tokenId]=0;
        rewardedAmount[_user][_tokenId] = 0;
        userTokenIds[msg.sender].pop();
        User_Info[msg.sender].myNFT -= 1;
        TotalUserStakedNft[msg.sender] > 0 ? TotalUserStakedNft[msg.sender] -= 1 : TotalUserStakedNft[msg.sender]=0;

        emit normalSingleUnstake(address(this), msg.sender, _tokenId);
    }

    /*
    *   User can unstake tokenIds all at once
    *   these tokenIds will directly move to caller's address in minted contract
    */
    function unStakeAll(uint256[] memory _tokenIds)  external 
    {
        address _user = msg.sender;
        for(uint256 i=0;i<_tokenIds.length;i++){
        uint256 _index=find(_tokenIds[i]);
        require(userTokenIds[msg.sender][_index] ==_tokenIds[i] ,"NFT with this _tokenId not found");
        if(userSingleReward(_user, userTokenIds[msg.sender][_index]) > 0){
            withDrawReward(userTokenIds[msg.sender][_index]);
        }

        NFT.transferFrom(address(this), msg.sender, _tokenIds[i]);
        delete userTokenIds[msg.sender][_index];
        userTokenIds[msg.sender][_index ] = userTokenIds[msg.sender][userTokenIds[msg.sender].length-1];
        rewardedAmount[_user][_tokenIds[i]] = 0;
        userTokenIds[msg.sender].pop();
        userStakingTime[msg.sender][_tokenIds[i]]=0;

        }
        User_Info[msg.sender].myNFT -= _tokenIds.length;
        TotalUserStakedNft[msg.sender]>0?TotalUserStakedNft[msg.sender] -= _tokenIds.length:TotalUserStakedNft[msg.sender]=0;
        
        emit normalUnstakeAll(address(this), msg.sender, _tokenIds.length);
    }

    // this function will show whether the caller is stake holder or not 

    function isNormalStaked(address _stakeHolder)public view returns(bool){
        if(TotalUserStakedNft[_stakeHolder]>0){
        return true;
        }else{
        return false;
        }
    }

    //  this function will return the staked Ids against a single user
    function userStakedNFT(address _staker)public view returns(uint256[] memory) {
       return userTokenIds[_staker];
    }

    //  this function will return the staked time of any tokenId
    function getTime(address _user, uint256 tokenId) public view returns(uint256){
        uint256 _time;
        uint256 _type = getIDType(tokenId);
        if(_type == 1){
            _time = NFT.getFreeMintingTime(tokenId);
        }
        else if(_type == 2){
            _time = NFT.getDutchMintingTime(tokenId);
        }
        else{
            _time = userStakingTime[_user][tokenId];
        }
        return _time;
    }


    // this function will return the reward of tokenId 
    function getReward(address _user, uint256 tokenId) public view returns(uint256){
        uint256 _reward;
        if(NFT.getIdType(tokenId) == 1 || NFT.getIdType(tokenId) == 2){
        _reward = lockedReward(_user, tokenId);
        }
        else{
            _reward = userSingleReward(_user, tokenId);
        }
        return _reward;
    }

    // this function will return the bonus if user is not rewarded for the very fisrt time 
    function getBonus(address _user) public view returns(uint256){
        if(!alreadyAwarded[_user]){
            return bonusReward;
        }
        else{
            return 0;
        }
    }
    
    //  ===========================================================
    //  ========================= ADMIN ===========================

    /*
    *   this function will set freeMint reward 
    *    this function will be call only by ownerMint
    */

    function setFreeMintReward(uint256 tokenIdReward) public onlyOwner{
        rewardDutchMint = tokenIdReward;
    }

    /*
    *   this function will set DutchMint reward
    *   this function will also be called only by owner
    */

    function setDutchMintReward(uint256 tokenIdReward) public onlyOwner{
        rewardDutchMint = tokenIdReward;
    }

    /*
    *   this function will call to set common Id reward
    */
    function setPublicReward(uint256 tokenIdReward) public onlyOwner{
        commonReward = tokenIdReward;
    }

    /*
    *   this function will call to set genesis reward
    */
    function setGenesisReward(uint256 tokenIdReward) public onlyOwner{
        genesisRewarad = tokenIdReward;
    }

    /*
    *   this function will call to set booster reward
    */
    function setBoosterReward(uint256 tokenIdReward) public onlyOwner{
        boosterRewarad = tokenIdReward;
    }

    /*
    *   this function will call to set freeMint lockedTime 
    */
    function setFreeMintTime(uint256 _time) public onlyOwner{
        finalTimeForFreeMint = _time.mul(1 days);
        maxNoOfdaysForFreeMint = finalTimeForFreeMint.div(60);
    }

    /*
    *   this function will call to set dutchMint lockedTime 
    */
    function setDutchMintTime(uint256 _time) public onlyOwner{
        finalTimeForDutchMint = _time.mul(1 days);
        maxNoOfdaysForDutchMint = finalTimeForDutchMint.div(60);
    }

    // this function wil retrun stakingTime of any tokenId
    function getStakingTime(address _user, uint256 tokenId) public view returns(uint256){
        return userStakingTime[_user][tokenId];
    }

    function WithdrawBCB() public onlyOwner{
        Token.transfer(msg.sender,Token.balanceOf(address(this)));
    }
    

}