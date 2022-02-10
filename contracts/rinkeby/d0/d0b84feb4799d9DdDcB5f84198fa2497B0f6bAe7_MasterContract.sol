/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}




/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}






/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ShkoobyStaking is Ownable{

    IERC20 public token;
  
    uint256 public totalReward;

    uint256 public price = 15000000000;
    uint256 magnitude = 10 ** 18 * 1000000;
    IUniswapV2Pair public uniswapV2Pair;
    uint256 public totalAmountStaked;
    uint256 public totalAmountClaimed;
    uint256 public totalAmountDistributed;
    
    
    struct LStruct{
        uint256 Index;
        address claimer;
        uint256 reward;
        uint256 timeOut;
    }
 
    mapping(address=> mapping(uint256=> uint256)) public StakMapping;
    mapping(address=> mapping(uint256=> uint256)) public timeIn;
 
    
    mapping (address=> mapping(uint256=>LStruct)) public lockReward;
    LStruct[] public lockRewardArray;
    uint256 public lockRewardCounter =0;
    mapping (address => uint256) public ClaimedReward;
    uint256 public FlexPS;
    uint256 public TMPS;
    uint256 public SMPS;
    bool public Emergency = false;


    struct Pools{
        uint8 Flexi;
        uint8 ThreeMonths;
        uint8 SixMonths;
    }

    mapping(address => mapping(uint256=>uint256)) public rewardClaimedBeforestaking;
    mapping(address => mapping(uint256=>bool)) public usersPoolIds;

    modifier EmergencyFalse() {
        require(Emergency == false, "Emergency situation is there");
        _;
    }

    constructor(address _token, address v2pair, uint256 percent){
        token = IERC20(_token);
 
        totalReward = (token.totalSupply() * percent / 100) *20 /100 ;     
        uniswapV2Pair = IUniswapV2Pair(v2pair);
    }
    
    struct DetailsStruct{
        uint256 id;
        uint256 staked;
        uint256 unClaimed;
        
    }

    struct DetailsStructArray{
        DetailsStruct one;
        DetailsStruct two;
        DetailsStruct three;
    }

    function ModifyEmergency(bool emergency) public onlyOwner() {
        Emergency = emergency;
    }

    function getUserDetails() public view returns(DetailsStructArray memory){

        uint256 d = StakMapping[msg.sender][1] ==0?0: calculateReward(1);
        uint256 e = StakMapping[msg.sender][2] ==0?0: calculateReward(2);
        uint256 f = StakMapping[msg.sender][3] ==0?0: calculateReward(3);
        DetailsStruct memory flexi = DetailsStruct(1,StakMapping[msg.sender][1],d);
        DetailsStruct memory ThreeMonths = DetailsStruct(2,StakMapping[msg.sender][2],e);
        DetailsStruct memory SixMonths = DetailsStruct(3,StakMapping[msg.sender][3],f);
        DetailsStructArray memory toReturn = DetailsStructArray(flexi,ThreeMonths,SixMonths);
        return toReturn;
    }

    function staking(uint256 quantity, uint256 _poolType) EmergencyFalse() public {
        require(token.balanceOf(msg.sender)>= quantity,"in suffecient quantity of token");
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        require(token.allowance(msg.sender,address(this))>=quantity,"Please approve the contract first");
        token.transferFrom(msg.sender,address(this),quantity);
        uint256 _calculatedReward = StakMapping[msg.sender][_poolType] ==0? 0 : calculateReward(_poolType);
        rewardClaimedBeforestaking[msg.sender][_poolType] = _calculatedReward;
        usersPoolIds[msg.sender][_poolType] = true;
        StakMapping[msg.sender][_poolType] += quantity;            
        timeIn[msg.sender][_poolType] = block.timestamp;        
        totalAmountStaked += quantity;
 
        if(_poolType == 1){FlexPS += quantity;}
        if(_poolType == 2){TMPS += quantity;}
        if(_poolType == 3){SMPS += quantity;}

    }

    function changeTotalReward(uint256 percent) public onlyOwner() {
        totalReward = (token.totalSupply() * percent / 100) *20 /100; 
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
       
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalReward * magnitude/  (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 RewardRelatedtoSender = numTok * rewardType / magnitude;
        uint256 _rewardSub = RewardRelatedtoSender * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType] - ClaimedReward[msg.sender];
        return _reward;
    } 

    function claimReward(uint256 _poolType) public EmergencyFalse() {
       require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");        
        uint256 reward = calculateReward(_poolType);
        ClaimedReward[msg.sender] += reward;
        LStruct memory tx1 = LStruct(lockRewardCounter, msg.sender,reward,block.timestamp);
        lockReward[msg.sender][lockRewardCounter] = tx1;
        lockRewardArray.push(tx1);
        lockRewardCounter++;
        totalAmountClaimed+= reward;
    }

    function getLockReward() public view returns(LStruct[] memory){
        return lockRewardArray;
    }

    function transferClaimedToken() public EmergencyFalse() {

        uint256 claimable;
        for(uint i = 0 ; i <= lockRewardArray.length ; i++){
            if(lockRewardArray[i].claimer == msg.sender && (block.timestamp - lockRewardArray[i].timeOut)>=31536000){
                claimable += lockRewardArray[i].reward;
                delete lockRewardArray[i];

            }
        }
        totalAmountDistributed+=claimable;
        token.transferFrom(address(this),msg.sender,claimable);
        
    }

    function unStaking(uint256 _poolType) public EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=2592000,"You cannot stake before 30 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot stake before 90 days");}
        token.transferFrom(address(this),msg.sender,tx1);
        if(_poolType == 1){FlexPS -= tx1;}
        if(_poolType == 2){TMPS -= tx1;}
        if(_poolType == 3){SMPS -= tx1;}
        claimReward(_poolType);
        totalAmountStaked -= tx1;
    }

    function getPrice(uint amountIn) public view returns(uint256){
        uint256 AmountinWithFee = amountIn*997;
        (uint112 _reserve0, uint112 _reserve1,) = uniswapV2Pair.getReserves();
        uint256 numerator = _reserve0 * AmountinWithFee;
        uint256 denominator = (_reserve1*1000)+AmountinWithFee;
        uint256 amountOut = numerator / denominator;
        return amountOut;
        
    }

}



interface IERC202 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


contract ShkoobyLPStaking is Ownable{

    IUniswapV2ERC20 public token;
    IERC202 public rewardingToken;
    
    uint256 public totalReward;

    uint256 public price = 15000000000;
    uint256 magnitude = 10 ** 18 * 1000000;

    uint256 public totalAmountStaked;
    uint256 public totalAmountClaimed;
    uint256 public totalAmountDistributed;
     
    struct LStruct{
        uint256 Index;
        address claimer;
        uint256 reward;
        uint256 timeOut;
    }

    mapping(address=> mapping(uint256=> uint256)) public StakMapping;
    mapping(address=> mapping(uint256=> uint256)) public timeIn;
  
    mapping (address=> mapping(uint256=>LStruct)) public lockReward;
    LStruct[] public lockRewardArray;
    uint256 public lockRewardCounter =0;
    mapping (address => uint256) public ClaimedReward;
    uint256 public FlexPS;
    uint256 public TMPS;
    uint256 public SMPS;
    bool Emergency = false;
    struct Pools{
        uint8 Flexi;
        uint8 ThreeMonths;
        uint8 SixMonths;
    }

    mapping(address => mapping(uint256=>uint256)) public rewardClaimedBeforestaking;
    mapping(address => mapping(uint256=>bool)) public usersPoolIds;

    modifier EmergencyFalse() {
        require(Emergency == false, "Emergency situation is there");
        _;
    } 

    constructor(address _rewardingToken, address _token, uint256 percent){
        token = IUniswapV2ERC20(_token);
    
        IERC202 reward = IERC202(_rewardingToken);
        totalReward = (reward.totalSupply() * percent / 100) *80 /100 ;     

    }
    
    struct DetailsStruct{
        uint256 id;
        uint256 staked;
        uint256 unClaimed;
        
    }

    struct DetailsStructArray{
        DetailsStruct one;
        DetailsStruct two;
        DetailsStruct three;
    }

    function ModifyEmergency(bool emergency) public onlyOwner() {
        Emergency = emergency;
    }

    function getUserDetails() public view returns(DetailsStructArray memory){
           
        uint256 d = StakMapping[msg.sender][1] ==0?0: calculateReward(1);
        uint256 e = StakMapping[msg.sender][2] ==0?0: calculateReward(2);
        uint256 f = StakMapping[msg.sender][3] ==0?0: calculateReward(3);
        DetailsStruct memory flexi = DetailsStruct(1,StakMapping[msg.sender][1],d);
        DetailsStruct memory ThreeMonths = DetailsStruct(2,StakMapping[msg.sender][2],e);
        DetailsStruct memory SixMonths = DetailsStruct(3,StakMapping[msg.sender][3],f);
        DetailsStructArray memory toReturn = DetailsStructArray(flexi,ThreeMonths,SixMonths);
        return toReturn;
    }

    function staking(uint256 quantity, uint256 _poolType) public EmergencyFalse() {
        require(token.balanceOf(msg.sender)>= quantity,"In-suffecient quantity of token");
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        require(token.allowance(msg.sender,address(this))>=quantity,"Please approve the contract first");
        token.transferFrom(msg.sender,address(this),quantity);
        uint256 _calculatedReward = StakMapping[msg.sender][_poolType] ==0? 0 : calculateReward(_poolType);
        rewardClaimedBeforestaking[msg.sender][_poolType] = _calculatedReward;
        usersPoolIds[msg.sender][_poolType] = true;
        StakMapping[msg.sender][_poolType] += quantity;            
        timeIn[msg.sender][_poolType] = block.timestamp;        
        totalAmountStaked += quantity;
   
        if(_poolType == 1){FlexPS += quantity;}
        if(_poolType == 2){TMPS += quantity;}
        if(_poolType == 3){SMPS += quantity;}

    }

    function changeTotalReward(uint256 percent) public onlyOwner() {
        totalReward = (token.totalSupply() * percent / 100) *80 /100; 
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalReward * magnitude/  (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 RewardRelatedtoSender = numTok * rewardType / magnitude;
        uint256 _rewardSub = RewardRelatedtoSender * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType] - ClaimedReward[msg.sender];
        return _reward;
    } 

    function claimReward(uint256 _poolType) public EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        uint256 reward = calculateReward(_poolType);
        ClaimedReward[msg.sender] += reward;
        LStruct memory tx1 = LStruct(lockRewardCounter, msg.sender,reward,block.timestamp);
        lockReward[msg.sender][lockRewardCounter] = tx1;
        lockRewardArray.push(tx1);
        lockRewardCounter++;
        totalAmountClaimed+= reward;
    }

    function getLockReward() public view returns(LStruct[] memory){
        return lockRewardArray;
    }

    function transferClaimedToken() public EmergencyFalse() {

        uint256 claimable;
        for(uint i = 0 ; i <= lockRewardArray.length ; i++){
            if(lockRewardArray[i].claimer == msg.sender && (block.timestamp - lockRewardArray[i].timeOut)>=31536000){
                claimable += lockRewardArray[i].reward;
                delete lockRewardArray[i];

            }
        }
        totalAmountDistributed+=claimable;
        token.transferFrom(address(this),msg.sender,claimable);

    }

    function unStaking(uint256 _poolType) public  EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=2592000,"You cannot stake before 30 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot stake before 90 days");}
        token.transferFrom(address(this),msg.sender,tx1);

        if(_poolType == 1){FlexPS -= tx1;}
        if(_poolType == 2){TMPS -= tx1;}
        if(_poolType == 3){SMPS -= tx1;}
        claimReward(_poolType);
        totalAmountStaked -= tx1;
    }

}

// File: MasterContract.sol

pragma solidity ^0.8.0;

contract MasterContract is Ownable {
    IERC20 public token;
    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2ERC20 public LPtoken;
    uint256 rewardPercent = 5;

    address public ShkoobyStakingAddress;
    address public LPstakingAddress;

    constructor(){
        IERC20 _token = IERC20(0x11B75688CE80508151d1022aDFEC86C23Bac2b18);
        IUniswapV2ERC20 _LPtoken = IUniswapV2ERC20(0x360e4ddb59b1E02E7a81bffd3cAc7F1Fe7FeC73A);
        
        token = _token;
        LPtoken = _LPtoken;

        ShkoobyStaking staking = new ShkoobyStaking(address(token),address(LPtoken),rewardPercent);
        ShkoobyLPStaking LPstaking = new ShkoobyLPStaking(address(token),address(LPtoken),rewardPercent);
        
        ShkoobyStakingAddress = address(staking);
        LPstakingAddress = address(LPstaking);
    }

    function changeRewardSupply(uint256 rew) external onlyOwner() {
        ShkoobyStaking shk = ShkoobyStaking(ShkoobyStakingAddress);
        ShkoobyLPStaking shkLP = ShkoobyLPStaking(LPstakingAddress);
        shk.changeTotalReward(rew);
        shkLP.changeTotalReward(rew);
    }



    function tokentoAdd() external view onlyOwner() returns(uint256,uint256,uint256){
        ShkoobyStaking shk = ShkoobyStaking(ShkoobyStakingAddress);
        ShkoobyLPStaking shkLP = ShkoobyLPStaking(LPstakingAddress);
        uint256 allShk = token.allowance(owner(),ShkoobyStakingAddress);
        uint256 allShkLP = LPtoken.allowance(owner(),LPstakingAddress);

        uint256 rewardSupplyShk = shk.totalReward();
        uint256 rewardSupplyShkLP = shkLP.totalReward();

        uint256 tokenRequiredSHK = rewardSupplyShk - allShk ;
        uint256 tokenRequiredSHKLP = rewardSupplyShkLP - allShkLP;
        uint256 totalRequired = tokenRequiredSHK + tokenRequiredSHKLP;
        return (tokenRequiredSHK,tokenRequiredSHKLP,totalRequired);

    }
}