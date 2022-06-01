/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;// solhint-disable-line


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
contract Ownable is Context {
    address internal _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Vegetable is Ownable{
   
    using SafeMath for uint256;
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    //main
    // uint256 public EGGS_TO_HATCH_1MINERS=864000;//for final version should be seconds in a day
     //test
     uint256 public EGGS_TO_HATCH_1MINERS=86400;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable public  ceoAddress;
    address public cake = 0xBACE1b27a22f84a6BBed1eBf5B100EDD400fb485;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping(address => uint256) public referAward;
    uint256 public marketEggs = 0;
    bool public automaticHatching  =  true;
    uint256 public totalUser = 0;
    mapping(uint256=>address) public registeredUser;
    mapping(address => bool) public    whitelist;
    mapping(address => uint256) public investmentAmount;

    uint[5] public  rebate = [7,3,2,2,1];

    event referralAwardLog(address indexed user,address indexed referrer,uint256 userEggValue,uint i);
    event buyEggsLog(address indexed user,uint256 investmentAmount,uint256 eggValue);
    event hatchEggsLog(address indexed user,uint256 eggsvalue,uint256 eggUsed,uint256 newMiner);
    event sellEggsLog(address indexed user,uint256 eggsValue,uint256 gain);
    event updateHatchingSpeedLog(address indexed owner,uint256 s);
    constructor() public{
        ceoAddress=msg.sender;
        _owner = msg.sender;
        registeredUser[totalUser] = ceoAddress;
        totalUser++;
        
    }

    function setAutomaticHatching() public  onlyOwner{
        if(automaticHatching ){
            automaticHatching =  false;
        }else{
             automaticHatching =  true;
        }

    }

    function setWhilteAddress(address _addr) public onlyOwner{
        if(whitelist[_addr]){
            whitelist[_addr] = false;
        }else{
            whitelist[_addr] = true;
        }
    }

    function directNumber()public view returns(uint ){
         uint count = 0;
         for(uint256 i=1;i< totalUser;i++){
            address reg =  registeredUser[i];
            if(referrals[reg] == msg.sender){
               count++;
            }
        }  
        return count; 
    }

    function setHatchingSpeed(uint256 _s) public onlyOwner{
        EGGS_TO_HATCH_1MINERS = _s;
        emit updateHatchingSpeedLog(msg.sender,_s);
    }

    function hatchEggs() public{
        require(initialized);  
        uint256 eggsUsed=getMyEggs();
        require(eggsUsed > 0,"buy eggs first");
        
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        
        require(newMiners> 0,"buy more eggs");

        // uint256 notHatchedEggs =  SafeMath.mod(eggsUsed,EGGS_TO_HATCH_1MINERS);
        uint256 realEggsUsed = SafeMath.mul(newMiners,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        // claimedEggs[msg.sender]= notHatchedEggs;
        claimedEggs[msg.sender]= 0;
        lastHatch[msg.sender]=now;

        address refer = referrals[msg.sender];
        for(uint i=0;i<5;i++){
            if(refer == address(0)) break;
            claimedEggs[refer]=SafeMath.add(claimedEggs[refer],SafeMath.div(SafeMath.mul(realEggsUsed,rebate[i]),100));
            emit referralAwardLog(msg.sender,refer,SafeMath.div(SafeMath.mul(realEggsUsed,rebate[i]),100),i);
            refer = referrals[refer];
        }

        emit hatchEggsLog(msg.sender,eggsUsed,realEggsUsed,newMiners);
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(realEggsUsed,5));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        TransferHelper.safeTransfer(cake,ceoAddress,fee);
        TransferHelper.safeTransfer(cake,msg.sender,SafeMath.sub(eggValue,fee));
        emit sellEggsLog(msg.sender,hasEggs,eggValue);

        
    }
    function buyEggs(uint256 amount , address ref) public{
        require(initialized);
        require(investmentAmount[msg.sender]+amount<=buyCap());
        
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
            registeredUser[totalUser] = ceoAddress;
            totalUser++;
            
        }
        TransferHelper.safeTransferFrom(cake,msg.sender,address(this),amount);
        investmentAmount[msg.sender] += amount;
        uint256 eggsBought=calculateEggBuy(amount,SafeMath.sub(cakeBalance(address(this)),amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        TransferHelper.safeTransfer(cake,ceoAddress,fee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);



        emit buyEggsLog(msg.sender,amount,eggsBought);


        address refer = referrals[msg.sender];
        for(uint i=0;i<5;i++){
            if(refer == address(0)) break;
            // claimedEggs[refer]=SafeMath.add(claimedEggs[refer],SafeMath.div(SafeMath.mul(eggsBought,rebate[i]),100));
            // referAward[refer]= referAward[refer]+SafeMath.div(SafeMath.mul(eggsBought,rebate[i]),100);
             uint256 referAmount = SafeMath.div(SafeMath.mul(investmentAmount[refer],rebate[i]),100); 


            uint256 userAmunt = SafeMath.div(SafeMath.mul(amount,rebate[i]),100);

            TransferHelper.safeTransfer(cake,refer,referAmount<=userAmunt?referAmount:userAmunt);
            emit referralAwardLog(msg.sender,refer,referAmount<=userAmunt?referAmount:userAmunt,i);
            refer = referrals[refer];

        }



        if(automaticHatching){
            hatchEggs_();
        }
    }


// 介于同类型项目出现的一些问题，我们需要修改需求方案如下：
// 1，项目名称：Super Cake
// 2，重新设计UI（可参考PanCake的配色）
// 3，设置100个白名单，写入合约，每个白名单允许投资上限50Cake
// 4，设置散户投资梯度：0-300账号，上限10Cake；300-500账户，上限20Cake；500-1000账户，上限40Cake；1000以上账户，不限额。
// 5，调整推荐奖励代数：1代7%，2代3%，3代2%，4代2%，5代1%，总计15%。投资直接到账，复投只按比例增加上家算力。

    function buyCap() public view returns(uint256){
        if(whitelist[msg.sender]){
            return 50e18;
        }
        if(totalUser<=300 ){
            return 10e18;
        }else if(totalUser<=500){
            return 20e18;
        }else if(totalUser<=1000){
            return 40e18;
        }else{
            return uint(-1);
        }


    }

    function setTotalUser(uint256 _t) public onlyOwner{
        totalUser = _t;
    }

    function hatchEggs_() private{

        uint256 eggsUsed=getMyEggs();

        if(eggsUsed >= EGGS_TO_HATCH_1MINERS){
            uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
            uint256 notHatchedEggs =  SafeMath.mod(eggsUsed,EGGS_TO_HATCH_1MINERS);
            uint256 realEggsUsed = SafeMath.mul(newMiners,EGGS_TO_HATCH_1MINERS);
            hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
            claimedEggs[msg.sender]= notHatchedEggs;
            lastHatch[msg.sender]=now;
            //boost market to nerf miners hoarding
            marketEggs=SafeMath.add(marketEggs,SafeMath.div(realEggsUsed,5));
            emit hatchEggsLog(msg.sender,eggsUsed,realEggsUsed,newMiners);
        }
        
    }



    function cakeBalance(address _addr) public view returns (uint256){
        return IERC20(cake).balanceOf(_addr);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));  bs*rt/(rs+rt)
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,cakeBalance(address(this)));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,cakeBalance(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket() public payable onlyOwner{
        require(marketEggs==0);
        initialized=true;
        marketEggs=86400000000;
    }
    function getBalance() public view returns(uint256){
        return cakeBalance(address(this));
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }


}


 
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
    
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
 
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
 
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
 
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}