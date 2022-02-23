// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Pair.sol";

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
    using SafeMath for uint256;

    IERC20 public token;
  
    uint256 public totalRewardsSupply;

    uint256 public magnitude = 10 ** 18 * 1000000;
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
    mapping(address=> mapping(uint256=> uint256)) public ClaimedBalance;
 
    mapping (address=> mapping(uint256=>LStruct)) public lockReward;
    LStruct[] public lockRewardArray;
    uint256 public lockRewardCounter =0;
    mapping (address => uint256) public ClaimedReward;
    uint256 public FlexPS;
    uint256 public TMPS;
    uint256 public SMPS;
    bool public Emergency = false;
    address public Admin;

    struct Pools{
        uint8 Flexi;
        uint8 ThreeMonths;
        uint8 SixMonths;
    }

    mapping(address => mapping(uint256=>uint256)) public rewardClaimedBeforestaking;
    mapping(address => mapping(uint256=>bool)) public usersPoolIds;

    modifier EmergencyFalse() {
        require(Emergency == false, "Emergency situation, contract is halted");
        _;
    }

    modifier adminOnly() {
        require(msg.sender == Admin, "Admin accessible only");
        _;
    } 

    constructor(address _token, address v2pair, uint256 percent){
        token = IERC20(_token);
 
        totalRewardsSupply = (token.totalSupply() * percent / 100) *20 /100 ;     
        uniswapV2Pair = IUniswapV2Pair(v2pair);
        Admin = msg.sender;
    }
    
    struct DetailsStruct{
        uint256 id;
        uint256 staked;
        uint256 unClaimed;
        uint256 timeIn;
        uint256 Claimed;  
    }

    struct DetailsStructArray{
        DetailsStruct one;
        DetailsStruct two;
        DetailsStruct three;
    }

    function ModifyEmergency(bool emergency) public adminOnly() {
        Emergency = emergency;
    }

    function getUserDetails() public view returns(DetailsStructArray memory){

        uint256 d = StakMapping[msg.sender][1] ==0?0: calculateReward(1);
        uint256 e = StakMapping[msg.sender][2] ==0?0: calculateReward(2);
        uint256 f = StakMapping[msg.sender][3] ==0?0: calculateReward(3);
        DetailsStruct memory flexi = DetailsStruct(1,StakMapping[msg.sender][1],d,timeIn[msg.sender][1],ClaimedBalance[msg.sender][1]);
        DetailsStruct memory ThreeMonths = DetailsStruct(2,StakMapping[msg.sender][2],e,timeIn[msg.sender][2],ClaimedBalance[msg.sender][2]);
        DetailsStruct memory SixMonths = DetailsStruct(3,StakMapping[msg.sender][3],f,timeIn[msg.sender][3],ClaimedBalance[msg.sender][3]);
        DetailsStructArray memory toReturn = DetailsStructArray(flexi,ThreeMonths,SixMonths);
        return toReturn;
    }

    function staking(uint256 quantity, uint256 _poolType) EmergencyFalse() public {
        require(token.balanceOf(msg.sender)>= quantity,"Insufficient quantity of tokens");
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        require(token.allowance(msg.sender,address(this))>=quantity,"Insufficient Allowance, please approve the tokens first");
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

    function changeTotalRewardsSupply(uint256 _newPercentage) public onlyOwner() {
        totalRewardsSupply = (token.totalSupply() * _newPercentage / 100) *20 /100; 
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
        token.transfer(msg.sender,claimable);    
    }

    function unStaking(uint256 _poolType) public  EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot unStake before 90 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=15552000,"You cannot unStake before 180 days");}
        claimReward(_poolType);
        StakMapping[msg.sender][_poolType] =0;            
        timeIn[msg.sender][_poolType] = 0;        
        
        token.transfer(msg.sender,tx1);
        
        if(_poolType == 1){FlexPS -= tx1;}
        if(_poolType == 3){SMPS -= tx1;}
        
        totalAmountStaked -= tx1;
    }

    function claimReward(uint256 _poolType) public EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");        
        uint256 reward = calculateReward(_poolType);
        timeIn[msg.sender][_poolType] = block.timestamp;
        ClaimedReward[msg.sender] += reward;
        LStruct memory tx1 = LStruct(lockRewardCounter, msg.sender,reward,block.timestamp);
        lockReward[msg.sender][lockRewardCounter] = tx1;
        lockRewardArray.push(tx1);
        lockRewardCounter++;
        totalAmountClaimed+= reward;
        rewardClaimedBeforestaking[msg.sender][_poolType] =0;
        ClaimedBalance[msg.sender][_poolType]+=reward;
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
       
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalRewardsSupply * magnitude / (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 RewardRelatedtoSender = numTok * rewardType / magnitude;
        uint256 _rewardSub = RewardRelatedtoSender * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType];
        return _reward;
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
    
    uint256 public totalRewardsSupply;


    uint256 magnitude = 10 ** 18 * 1000000;

    uint256 public totalAmountStaked;
    uint256 public totalAmountClaimed;
    uint256 public totalAmountDistributed;
    address public Admin;
     
    struct LStruct{
        uint256 Index;
        address claimer;
        uint256 reward;
        uint256 timeOut;
    }

    mapping(address=> mapping(uint256=> uint256)) public StakMapping;
    mapping(address=> mapping(uint256=> uint256)) public timeIn;
    mapping(address=> mapping(uint256=> uint256)) public ClaimedBalance;
  
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
        require(Emergency == false, "Emergency situation, contract is halted");
        _;
    }


    modifier adminOnly() {
        require(msg.sender == Admin, "Admin accessible only");
        _;
    } 

    constructor(address _rewardingToken, address _token, uint256 rewardSuppplyPercent){
        token = IUniswapV2ERC20(_token);
    
        IERC202 reward = IERC202(_rewardingToken);
        totalRewardsSupply = (reward.totalSupply() * rewardSuppplyPercent / 100) *80 /100 ;
        Admin = msg.sender;     

    }
    
    struct DetailsStruct{
        uint256 id;
        uint256 staked;
        uint256 unClaimed;
        uint256 timeIn;
        uint256 Claimed;
        
    }

    struct DetailsStructArray{
        DetailsStruct one;
        DetailsStruct two;
        DetailsStruct three;
    }

    function ModifyEmergency(bool emergency) public adminOnly() {
        Emergency = emergency;
    }

    function getUserDetails() public view returns(DetailsStructArray memory){

        uint256 d = StakMapping[msg.sender][1] ==0?0: calculateReward(1);
        uint256 e = StakMapping[msg.sender][2] ==0?0: calculateReward(2);
        uint256 f = StakMapping[msg.sender][3] ==0?0: calculateReward(3);
        DetailsStruct memory flexi = DetailsStruct(1,StakMapping[msg.sender][1],d,timeIn[msg.sender][1],ClaimedBalance[msg.sender][1]);
        DetailsStruct memory ThreeMonths = DetailsStruct(2,StakMapping[msg.sender][2],e,timeIn[msg.sender][2],ClaimedBalance[msg.sender][2]);
        DetailsStruct memory SixMonths = DetailsStruct(3,StakMapping[msg.sender][3],f,timeIn[msg.sender][3],ClaimedBalance[msg.sender][3]);
        DetailsStructArray memory toReturn = DetailsStructArray(flexi,ThreeMonths,SixMonths);
        return toReturn;
    }

    function staking(uint256 quantity, uint256 _poolType) EmergencyFalse() public {
        require(token.balanceOf(msg.sender)>= quantity,"Insufficient quantity of tokens");
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        require(token.allowance(msg.sender,address(this))>=quantity,"Insufficient allowance, please approve the tokens first");
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

    function changeTotalRewardsSupply(uint256 _newPercentage) public onlyOwner() {
        totalRewardsSupply = (token.totalSupply() * _newPercentage / 100) *80 /100; 
    }

    function claimReward(uint256 _poolType) public EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");        
        uint256 reward = calculateReward(_poolType);
        timeIn[msg.sender][_poolType] = block.timestamp;
        ClaimedReward[msg.sender] += reward;
        LStruct memory tx1 = LStruct(lockRewardCounter, msg.sender,reward,block.timestamp);
        lockReward[msg.sender][lockRewardCounter] = tx1;
        lockRewardArray.push(tx1);
        lockRewardCounter++;
        totalAmountClaimed+= reward;
        rewardClaimedBeforestaking[msg.sender][_poolType] =0;
        ClaimedBalance[msg.sender][_poolType]+=reward;
    }

    function calculateReward(uint256 _poolType) public view returns(uint256){
        uint256 numTok = StakMapping[msg.sender][_poolType];
        uint256 _timeIn = timeIn[msg.sender][_poolType];
       
        uint256 BlocksMinted = (block.timestamp -  _timeIn)/15;
        uint256 apy = totalRewardsSupply * magnitude / (FlexPS+(TMPS*15/10)+(SMPS*2));
        uint256 rewardType = _poolType == 1 ? apy : _poolType ==2  ? apy*15/10 : apy*2 ;
        uint256 RewardRelatedtoSender = numTok * rewardType / magnitude;
        uint256 _rewardSub = RewardRelatedtoSender * BlocksMinted / 2102400  ; 
        uint256 _reward = _rewardSub + rewardClaimedBeforestaking[msg.sender][_poolType];
        return _reward;
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
        token.transfer(msg.sender,claimable);
    }

    function unStaking(uint256 _poolType) public  EmergencyFalse() {
        require(_poolType >=1 && _poolType <=3,"Pool type can be between 1 to 3");
        uint256 tx1 = StakMapping[msg.sender][_poolType];
        if(_poolType==2){require(block.timestamp - timeIn[msg.sender][_poolType]>=7776000,"You cannot unStake before 90 days");}
        if(_poolType==3){require(block.timestamp - timeIn[msg.sender][_poolType]>=15552000,"You cannot unStake before 180 days");}
        claimReward(_poolType);
        StakMapping[msg.sender][_poolType] =0;            
        timeIn[msg.sender][_poolType] = 0;        

        token.transfer(msg.sender,tx1);

        if(_poolType == 1){FlexPS -= tx1;}
        if(_poolType == 3){SMPS -= tx1;}

        totalAmountStaked -= tx1;
    }
}

contract MasterContract is Ownable {
    IERC20 public token;
    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2ERC20 public LPtoken;
    uint256 rewardSupplyPercentage = 5;

    address public ShkoobyStakingAddress;
    address public LPstakingAddress;

    constructor(){
        IERC20 _token = IERC20(0x11B75688CE80508151d1022aDFEC86C23Bac2b18);
        IUniswapV2ERC20 _LPtoken = IUniswapV2ERC20(0x360e4ddb59b1E02E7a81bffd3cAc7F1Fe7FeC73A);
        
        token = _token;
        LPtoken = _LPtoken;

        ShkoobyStaking staking = new ShkoobyStaking(address(token),address(LPtoken),rewardSupplyPercentage);
        //ShkoobyLPStaking LPstaking = new ShkoobyLPStaking(address(token),address(LPtoken),rewardSupplyPercentage);
        
        ShkoobyStakingAddress = address(staking);
        //LPstakingAddress = address(LPstaking);
    }

    function changeRewardsSupply(uint256 _newPercentage) external onlyOwner() {
        //ShkoobyStaking shk = ShkoobyStaking(ShkoobyStakingAddress);
        //ShkoobyLPStaking shkLP = ShkoobyLPStaking(LPstakingAddress);
        //shk.changeTotalRewardsSupply(_newPercentage);
        //shkLP.changeTotalRewardsSupply(_newPercentage);
    }

    function tokensToAdd() external view onlyOwner() returns(uint256,uint256,uint256){
        ShkoobyStaking shk = ShkoobyStaking(ShkoobyStakingAddress);
        ShkoobyLPStaking shkLP = ShkoobyLPStaking(LPstakingAddress);
        uint256 allShk = token.allowance(owner(),ShkoobyStakingAddress);
        uint256 allShkLP = LPtoken.allowance(owner(),LPstakingAddress);

        uint256 rewardSupplyShk = shk.totalRewardsSupply();
        uint256 rewardSupplyShkLP = shkLP.totalRewardsSupply();

        uint256 tokenRequiredSHK = rewardSupplyShk - allShk ;
        uint256 tokenRequiredSHKLP = rewardSupplyShkLP - allShkLP;
        uint256 totalRequired = tokenRequiredSHK + tokenRequiredSHKLP;
        return (tokenRequiredSHK,tokenRequiredSHKLP,totalRequired);

    }

    function ModifyEmergency(bool emergency) public onlyOwner() {
        ShkoobyStaking shk = ShkoobyStaking(ShkoobyStakingAddress);
        ShkoobyLPStaking shkLP = ShkoobyLPStaking(LPstakingAddress);

        shk.ModifyEmergency(emergency);
        shkLP.ModifyEmergency(emergency);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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