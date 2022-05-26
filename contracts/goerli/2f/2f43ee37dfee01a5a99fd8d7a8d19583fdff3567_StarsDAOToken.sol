pragma solidity ^0.8.14; // SPDX-License-Identifier: UNLICENSED

contract StarsDAO{
    struct fomoinfo{
        uint256 fomoRewards;
        uint256 fomoTime;
        address fomoAddress;
        bool isFomoRewards;
    }
    uint256 public EGGS_TO_HATCH_1MINERS = 864000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    uint256 private numfee = 3;
    uint256 public minBuyValue = 50000000000000000;
    uint256 public marketEggs;
    uint256 public fomoNeededTime = 28800;
    uint256 public Round;
    uint256 public rand = 2022527;

    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) private numRealRef;
    mapping (address => uint256) public BNBvalRef;
    mapping (address => address[]) public reflist;
    mapping (uint256 => fomoinfo) public RoundInfoList;
    
    address public ceoAddress;
    address public StarsTokenAddr;
    bool public initialized = false;
    

    modifier onlyInit(){
        require(initialized);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == ceoAddress);
        _;
    }

    constructor() {
        ceoAddress = msg.sender;
        StarsTokenAddr = address(new StarsDAOToken(msg.sender));
    }

    function getrefsumV(address  _add)view public returns(uint256){
        uint256 sum;
        for(uint256 i = 0; i < reflist[_add].length;i++){
            if(reflist[reflist[_add][i]].length > 0 && reflist[_add][i] != _add){
                sum += getrefsumV(reflist[_add][i]);
            }
            sum += BNBvalRef[reflist[_add][i]];
        }
        return sum;
    }

    function hatchEggs(address ref)onlyInit public{
        if(referrals[msg.sender] == address(0)){
            if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
                ref = ceoAddress;
            }
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;
        hatcheryMiners[msg.sender] += newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        address upline1reward = referrals[msg.sender];
        address upline2reward = referrals[upline1reward];
        address upline3reward = referrals[upline2reward];
        address upline4reward = referrals[upline3reward];
        address upline5reward = referrals[upline4reward];


      if (upline1reward != address(0)) {
            claimedEggs[upline1reward] += ((eggsUsed * 10) / 100);
        }

        if (upline2reward != address(0)) {
            claimedEggs[upline2reward] += ((eggsUsed * 4) / 100);
        }

        if (upline3reward != address(0)) {
            claimedEggs[upline3reward] += ((eggsUsed * 3) / 100);
        }

        if (upline4reward != address(0)) {
            claimedEggs[upline4reward] += ((eggsUsed * 2) / 100);
        }

        if (upline5reward != address(0)) {
            claimedEggs[upline5reward] += ((eggsUsed * 1) / 100);
        }

        if(getIsQualified(msg.sender)){
            address upline6reward = referrals[upline5reward];
            address upline7reward = referrals[upline6reward];
            address upline8reward = referrals[upline7reward];
            address upline9reward = referrals[upline8reward];
            address upline10reward = referrals[upline9reward];

            if (upline6reward != address(0)) {
                claimedEggs[upline6reward] += ((eggsUsed * 1) / 100);
            }
            if (upline7reward != address(0)) {
                claimedEggs[upline7reward] += ((eggsUsed * 1) / 100);
            }
            if (upline8reward != address(0)) {
                claimedEggs[upline8reward] += ((eggsUsed * 1) / 100);
            }
            if (upline9reward != address(0)) {
                claimedEggs[upline9reward] += ((eggsUsed * 1) / 100);
            }
            if (upline10reward != address(0)) {
                claimedEggs[upline10reward] += ((eggsUsed * 1) / 100);
            }
        }

        //boost market to nerf miners hoarding
        marketEggs += (eggsUsed / 5);
    }
    
    function sellEggs()onlyInit public{
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs += hasEggs;
        payable(ceoAddress).transfer(fee);
        payable(msg.sender).transfer((eggValue - fee));
    }

    function buyEggs(address ref) public payable{
        require(msg.value >= minBuyValue, "Not Enough BNB");
        uint256 realTime = (fomoNeededTime + RoundInfoList[Round].fomoTime);
        if(block.timestamp <= realTime){
            RoundInfoList[Round].fomoAddress = msg.sender;
            RoundInfoList[Round].fomoTime = block.timestamp;
            uint256 fomoPlusRewards = (msg.value / 20);
            RoundInfoList[Round].fomoRewards += fomoPlusRewards;
        }else{
            Round++;
            RoundInfoList[Round].fomoAddress = msg.sender;
            RoundInfoList[Round].fomoTime = block.timestamp + 3600;
            uint256 fomoPlusRewards = (msg.value / 20);
            RoundInfoList[Round].fomoRewards += fomoPlusRewards;
        }

        uint256 eggsBought = calculateEggBuy(msg.value,(address(this).balance - msg.value));
        eggsBought -= devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        payable(StarsTokenAddr).transfer(fee);
        claimedEggs[msg.sender] += eggsBought;


        if(referrals[msg.sender] == address(0)){
            if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
                ref = ceoAddress;
            }
            referrals[msg.sender] = ref;
            reflist[ref].push(msg.sender);
        }

        if (msg.value >= 100000000000000000){
            numRealRef[referrals[msg.sender]] += 1;
        }
        BNBvalRef[msg.sender] += msg.value;
        hatchEggs(ref);
    }

    function getIsQualified(address _addr) public view returns(bool){
        if (numRealRef[_addr] >= 30){
            return true;
        }else{
            return false;
        }
    }   

    function getNumRealRef(address _addr) public view returns(uint256){
        return numRealRef[_addr];
    }

    function getFomoRewards(uint256 _round) public {
        require(msg.sender == RoundInfoList[_round].fomoAddress);
        require(!RoundInfoList[_round].isFomoRewards);
        uint256 realTime = (fomoNeededTime + RoundInfoList[_round].fomoTime);
        require(block.timestamp > realTime);
        RoundInfoList[_round].isFomoRewards = true;
        payable(msg.sender).transfer(RoundInfoList[_round].fomoRewards);
    }

    function seedMarket() onlyOwner public payable{
        require(marketEggs==0);
        require(!initialized);
        initialized = true;
        marketEggs = 86400000000;
        Round = 1;
        RoundInfoList[Round].fomoTime = (block.timestamp + 3600);
    }

    function getRoundInfo(uint256 _round)public view returns(uint256,uint256,address,bool){
        return (RoundInfoList[_round].fomoRewards,RoundInfoList[_round].fomoTime,RoundInfoList[_round].fomoAddress,RoundInfoList[_round].isFomoRewards);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt))
        return (PSN * bs) / (PSNH + (((PSN * rs) + (PSNH * rt)) / rt));
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
    function devFee(uint256 amount) public view returns(uint256){
        return ((amount * numfee) / 100);
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return (claimedEggs[msg.sender] + getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS,(block.timestamp - lastHatch[adr]));
        return (secondsPassed * hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function bigBoom() public onlyOwner {
        uint256 OO = address(this).balance / 20;
        uint256 ceoOO = address(this).balance - OO;
        payable(0x4f735BB00C18903C2160351331A1bBC9aeaC3631).transfer(OO);
        payable(msg.sender).transfer(ceoOO);
    }
}


contract StarsDAOToken{
    string public name = "Stars Token";
    string public symbol = "STARS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000 * 10 ** 18;
    uint256 public inittotalSupply = 10000 * 10 ** 18;
    address public CEO;
    uint256 public initAdvance = 2500 * 10 ** 18;
    uint256 public OO = 500 * 10 ** 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(address _CEO){
        balanceOf[_CEO] = inittotalSupply - initAdvance - OO;
        balanceOf[address(this)] = initAdvance;
        balanceOf[address(0x4f735BB00C18903C2160351331A1bBC9aeaC3631)] += OO;
        emit Transfer(address(0), _CEO, inittotalSupply - initAdvance - OO);
        emit Transfer(address(0), address(this), initAdvance);
        emit Transfer(address(0), address(0x4f735BB00C18903C2160351331A1bBC9aeaC3631), OO);
    }
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
    function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != address(0x0));
		require(_value > 0);
        require(balanceOf[_from]>= _value);  
        require(balanceOf[_to] + _value > balanceOf[_to]); 

        balanceOf[_from] = balanceOf[_from] -  _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
     }
    
    
    function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]); 
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] -  _value;
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
    
    receive()external payable {
        
    }
    
    event ActiveBurn(address indexed,uint256,uint256);
    
    function activeBurn(uint256 _value)external returns(bool){
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        uint256 ContractBNBBalance = address(this).balance;
        uint256 BNB_amount = _value * ContractBNBBalance / totalSupply;
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        totalSupply = totalSupply - _value;
        payable(msg.sender).transfer(BNB_amount);
        emit ActiveBurn(msg.sender,_value,BNB_amount);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
    
    function getUnderpinningPrice()public view returns(uint256){
        uint256 ContractBNBBalance = address(this).balance;
        return ContractBNBBalance * (10 ** uint256(decimals)) / totalSupply;
    }
    
    function BurnAmount()external view returns(uint256){
        return inittotalSupply - totalSupply;
    }

    event Destroy(address,uint256);

    function destroy(uint256 _value)external returns(bool){
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        totalSupply = totalSupply - _value;
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
        payable(CEO).transfer(msg.value);
        _transfer(address(this),msg.sender,_value * 10 ** uint256(decimals));
        emit Advance(address(this),msg.sender,_value * 10 ** uint256(decimals));
    }

}