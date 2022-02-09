/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
// File: contracts/ShkoobyStaking/V2PairInterface.sol

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
// File: contracts/ShkoobyStaking/ShkoobyStaking.sol



pragma solidity ^0.8.0;


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


contract ShkoobyStaking {
    IERC20 public token;
    address public owner; 
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

    struct Pools{
        uint8 Flexi;
        uint8 ThreeMonths;
        uint8 SixMonths;
    }

    mapping(address => mapping(uint256=>uint256)) public rewardClaimedBeforestaking;
    mapping(address => mapping(uint256=>bool)) public usersPoolIds;


    constructor(address _token, address v2pair, uint256 percent){
        token = IERC20(_token);
        owner = msg.sender;
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

    function staking(uint256 quantity, uint256 _poolType) public {
        require(token.balanceOf(msg.sender)>= quantity,"in suffecient quantity of token");
        require(_poolType <= 3,"pool type can be between 1 to");
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

    function changeTotalReward(uint256 percent) public {
            totalReward = (token.totalSupply() * percent / 100) *20 /100; 
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
       
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalReward * magnitude/  (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 AnnualPersonalReward = numTok * rewardType / magnitude;
        uint256 _rewardSub = AnnualPersonalReward * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType] - ClaimedReward[msg.sender];
        return _reward;
    } 

    function claimReward(uint256 _poolType) public {
        
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

    function transferClaimedToken() public {

        uint256 claimable;
        for(uint i = 0 ; i <= lockRewardArray.length ; i++){
            if(lockRewardArray[i].claimer == msg.sender && (block.timestamp - lockRewardArray[i].timeOut)>=31536000){
                claimable += lockRewardArray[i].reward;
                delete lockRewardArray[i];

            }
        }

        token.transferFrom(address(this),msg.sender,claimable);
        totalAmountDistributed+=claimable;
    }

    function unStaking(uint256 _poolType) public {
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot stake before 90 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=15552000,"You cannot stake before 180 days");}
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
// File: contracts/ShkoobyStaking/ShkoobyLPStaking.sol



pragma solidity ^0.8.0;


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


contract ShkoobyLPStaking {
    IUniswapV2ERC20 public token;
    IERC202 public rewardingToken;
    address public owner; 
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


    struct Pools{
        uint8 Flexi;
        uint8 ThreeMonths;
        uint8 SixMonths;
    }
    mapping(address => mapping(uint256=>uint256)) public rewardClaimedBeforestaking;
    mapping(address => mapping(uint256=>bool)) public usersPoolIds;


    constructor(address _rewardingToken, address _token, uint256 percent){
        token = IUniswapV2ERC20(_token);
        owner = msg.sender;
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

    function staking(uint256 quantity, uint256 _poolType) public {
        require(token.balanceOf(msg.sender)>= quantity,"in suffecient quantity of token");
        require(_poolType <= 3,"pool type can be between 1 to");
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

    function changeTotalReward(uint256 percent) public {
            totalReward = (token.totalSupply() * percent / 100) *80 /100; 
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
       
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalReward * magnitude/  (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 AnnualPersonalReward = numTok * rewardType / magnitude;
        uint256 _rewardSub = AnnualPersonalReward * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType] - ClaimedReward[msg.sender];
        return _reward;
    } 

    function claimReward(uint256 _poolType) public {
        
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

    function transferClaimedToken() public {

        uint256 claimable;
        for(uint i = 0 ; i <= lockRewardArray.length ; i++){
            if(lockRewardArray[i].claimer == msg.sender && (block.timestamp - lockRewardArray[i].timeOut)>=31536000){
                claimable += lockRewardArray[i].reward;
                delete lockRewardArray[i];

            }
        }

        token.transferFrom(address(this),msg.sender,claimable);
        totalAmountDistributed+=claimable;
    }

    function unStaking(uint256 _poolType) public {
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot stake before 90 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=15552000,"You cannot stake before 180 days");}
        token.transferFrom(address(this),msg.sender,tx1);

        if(_poolType == 1){FlexPS -= tx1;}
        if(_poolType == 2){TMPS -= tx1;}
        if(_poolType == 3){SMPS -= tx1;}
        claimReward(_poolType);
        totalAmountStaked -= tx1;
    }

}
// File: contracts/ShkoobyStaking/MasterContract.sol



pragma solidity ^0.8.0;




contract MasterContract {
IERC20 public token;
IUniswapV2Pair public uniswapV2Pair;
IUniswapV2ERC20 public LPtoken;
uint256 rewardPercent = 5;
address owner;
address public ShkoobyStakingAddress;
address public LPstakingAddress;

    constructor(){
        IERC20 _token = IERC20(0x11B75688CE80508151d1022aDFEC86C23Bac2b18);
        IUniswapV2ERC20 _LPtoken = IUniswapV2ERC20(0x360e4ddb59b1E02E7a81bffd3cAc7F1Fe7FeC73A);
        
        token = _token;
        LPtoken = _LPtoken;
        owner = msg.sender;

        ShkoobyStaking staking = new ShkoobyStaking(address(token),address(LPtoken),rewardPercent);
        ShkoobyLPStaking LPstaking = new ShkoobyLPStaking(address(token),address(LPtoken),rewardPercent);
        
        ShkoobyStakingAddress = address(staking);
        LPstakingAddress = address(LPstaking);
    }

}