pragma solidity ^0.4.26; // solhint-disable-line

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
}

contract Rainbow{
    address public RainbowTokenAddr;
    uint256 public EGGS_TO_HATCH_1MINERS=864000;
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 public minBuyValue=50000000000000000;
    address public marketingAddress;

    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) public numRealRef;
    mapping (address => uint256) public BNBvalRef;
    mapping (address => address[]) public reflist;

    uint256 public marketEggs;
    uint256 public fomoTime;
    address public fomoAddress;
    uint256 public fomoNeededTime = 28800;
    uint256 public fomoRewards;
    bool public isFomoFinished = false;
    constructor() public{
        ceoAddress = msg.sender;
        marketingAddress = msg.sender;
        RainbowTokenAddr = address(new RainbowDAOToken(msg.sender));
    }

    function getrefsumV(address  _add)view public returns(uint256){
        uint256 sum;
        for(uint256 i = 0; i < reflist[_add].length;i++){
            if(reflist[reflist[_add][i]].length > 0 && reflist[_add][i] != _add){
                sum += getrefsumV(reflist[_add][i]);
            }
            sum +=BNBvalRef[reflist[_add][i]];
        }
        return sum;
    }

    function hatchEggs(address ref) public{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;

        // uplingAddress
        address upline1reward = referrals[msg.sender];
        address upline2reward = referrals[upline1reward];
        address upline3reward = referrals[upline2reward];
        address upline4reward = referrals[upline3reward];
        address upline5reward = referrals[upline4reward];


      if (upline1reward != address(0)) {
            claimedEggs[upline1reward] = SafeMath.add(
                claimedEggs[upline1reward],
                SafeMath.div((eggsUsed * 10), 100)
            );
        }

        if (upline2reward != address(0)) {
            claimedEggs[upline2reward] = SafeMath.add(
                claimedEggs[upline2reward],
                SafeMath.div((eggsUsed * 4), 100)
            );
        }

        if (upline3reward != address(0)) {
            claimedEggs[upline3reward] = SafeMath.add(
                claimedEggs[upline3reward],
                SafeMath.div((eggsUsed * 3), 100)
            );
        }

        if (upline4reward != address(0)) {
            claimedEggs[upline4reward] = SafeMath.add(
                claimedEggs[upline4reward],
                SafeMath.div((eggsUsed * 2), 100)
            );
        }

        if (upline5reward != address(0)) {
            claimedEggs[upline5reward] = SafeMath.add(
                claimedEggs[upline5reward],
                SafeMath.div((eggsUsed * 1), 100)
            );
        }

        if(getIsQualified(msg.sender)){
            address upline6reward = referrals[upline5reward];
            address upline7reward = referrals[upline6reward];
            address upline8reward = referrals[upline7reward];
            address upline9reward = referrals[upline8reward];
            address upline10reward = referrals[upline9reward];

            if (upline6reward != address(0)) {
                claimedEggs[upline6reward] = SafeMath.add(
                claimedEggs[upline6reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline7reward != address(0)) {
                claimedEggs[upline7reward] = SafeMath.add(
                claimedEggs[upline7reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline8reward != address(0)) {
                claimedEggs[upline8reward] = SafeMath.add(
                claimedEggs[upline8reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline9reward != address(0)) {
                claimedEggs[upline9reward] = SafeMath.add(
                claimedEggs[upline9reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline10reward != address(0)) {
                claimedEggs[upline10reward] = SafeMath.add(
                claimedEggs[upline10reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
        }

        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        marketingAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
        
    }
    function updateFomoFinished() private returns(bool){
        uint256 realTime = SafeMath.add(fomoNeededTime, fomoTime);
        if(!isFomoFinished){
            if(block.timestamp > realTime){
                isFomoFinished=true;
            }
        }
    }

    function buyEggs(address ref) public payable{
        require(msg.value >= minBuyValue, "Not Enough BNB");
        updateFomoFinished();
        
        if(!isFomoFinished){
            fomoAddress = msg.sender;
            fomoTime = block.timestamp;
            uint256 fomoPlusRewards = SafeMath.div(msg.value, 20);
            fomoRewards = SafeMath.add(fomoRewards,fomoPlusRewards);
        }

        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(msg.value);
        address(RainbowTokenAddr).transfer(fee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);

        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
            reflist[ref].push(msg.sender);
        }
        if (msg.value >= 100000000000000000){
            numRealRef[referrals[msg.sender]] += 1;
        }
        BNBvalRef[msg.sender] += msg.value;
        hatchEggs(ref);
    }

    bool public isFomoRewards;

    function getFomoRewards() public  {
        require(msg.sender == fomoAddress);
        require(isFomoFinished);
        require(!isFomoRewards);
        isFomoRewards = true;
        msg.sender.transfer(fomoRewards);
    }

    function getIsQualified(address _addr) public view returns(bool){
        if (numRealRef[_addr]>=30){
            return true;
        }else{
            return false;
        }
    }   

    function getNumRealRef(address _addr) public view returns(uint256){
        return numRealRef[_addr];
    }

    function setNewFomoRound( ) public{
        require(msg.sender == ceoAddress);
        require(isFomoFinished);
        isFomoFinished = false;
        fomoAddress = address(0);
        fomoRewards = 0;
        fomoTime = SafeMath.add(block.timestamp,3600);
        isFomoRewards = false;
    }


    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketEggs==0);
        require(!initialized);
        initialized=true;
        marketEggs=86400000000;
        fomoTime = SafeMath.add(block.timestamp,3600);
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}



contract RainbowDAOToken{
    using SafeMath for uint256;
    string public name = "Rainbow DAO Token";
    string public symbol = "Rainbow";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000 * 10 ** 18;
    uint256 public inittotalSupply = 10000 * 10 ** 18;
    address public CEO;
    uint256 public initAdvance = 2500 * 10 ** 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(address _CEO)public{
        balanceOf[_CEO] = inittotalSupply - initAdvance;
        balanceOf[this] = initAdvance;
        emit Transfer(address(0), _CEO, inittotalSupply - initAdvance);
        emit Transfer(address(0), this, initAdvance);
    }
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
    function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != address(0x0));
		require(_value > 0);
        require(balanceOf[_from]>= _value);  
        require(balanceOf[_to].add(_value)  > balanceOf[_to]); 

        balanceOf[_from] = balanceOf[_from].sub( _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
     }
    
    
    function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]); 
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public returns (bool success) {
        _approve(address(msg.sender),_spender,_value);
        return true;
    }
    
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function()external payable {
        
    }
    
    event ActiveBurn(address indexed,uint256,uint256);
    
    function activeBurn(uint256 _value)external returns(bool){
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        uint256 ContractBNBBalance = address(this).balance;
        uint256 BNB_amount = _value.mul(ContractBNBBalance).div(totalSupply);
        balanceOf[msg.sender]=balanceOf[msg.sender].sub(_value);
        totalSupply=totalSupply.sub(_value);
        msg.sender.transfer(BNB_amount);
        emit ActiveBurn(msg.sender,_value,BNB_amount);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
    
    function getUnderpinningPrice()public view returns(uint256){
        uint256 ContractBNBBalance = address(this).balance;
        return ContractBNBBalance.mul(10 ** uint256(decimals)).div(totalSupply);
    }
    
    function BurnAmount()external view returns(uint256){
        return inittotalSupply.sub(totalSupply);
    }

    event Destroy(address,uint256);

    function destroy(uint256 _value)external returns(bool){
        require(_value >0 && balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Destroy(msg.sender,_value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    uint256 public minAdvance = 10 ** 17;
    event Advance(address,address,uint256);

    function advance()public payable{
        require(msg.value >= minAdvance);
        require(msg.value % minAdvance == 0);
        uint256 _value = msg.value / minAdvance;
        CEO.transfer(msg.value);
        _transfer(address(this),msg.sender,_value * 10 ** uint256(decimals));
        emit Advance(address(this),msg.sender,_value * 10 ** uint256(decimals));
    }

}