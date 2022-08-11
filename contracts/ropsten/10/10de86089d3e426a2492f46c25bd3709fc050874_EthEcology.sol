/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

pragma solidity >=0.6.6;


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
    uint256 public player_num = 0;
    uint256 public mining_coefficient = 13;
    uint256 public inflow = 0;
    uint256 public outflow = 0;

    mapping (address => address)        public relation;
    mapping (address => address)        public relation_active;
    mapping (address => uint256)        public relation_active_count;
    mapping (address => PledgeEth)      public pledge_eth;
    mapping (address => Performance)    public user_per;
    mapping (address => EthStatistics)  public eth_statistics;
    mapping (uint256 => MinerRatio)     public miner_ratio;
    mapping (uint256 => TeamRatio)      public team_ratio;

    address public owner;
    address public origin;

    struct MinerRatio{
        uint256 reward;
        uint256 quicken;
        uint256 fuel;
    }

    struct TeamRatio{
        uint256 performance;
        uint256 fuel_mul;
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

    struct EthStatistics{
        uint256 quick;
        uint256 invite;
        uint256 fuel_amount;
        uint256 receive_value;
    }

    struct Performance{
        address addrs;
        uint256 performance;
        uint256 star;
    }



    event Relation(address user,address _recommend_address);
    event PledgeEthShot(address user,uint256 _amount);
    event MinerRatioShot(uint256 _index,uint256 _reward,uint256 _quicken,uint256 _fuel);
    event TeamRatioShot(uint256 _index,uint256 _performance,uint256 _fuel_mul);
    event ReceiveProfit(address _addr,uint256 _amount,uint256 _rate,uint256 ts,uint256 rt);
    event TierRewards(address _addr,uint256 _reward_amount,uint256 _quicken_amount,uint256 _fuel_amount);
    event TeamRewards(address _addr,uint256 _performance,uint256 _star,uint256 _fuel_amount);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        relation[msg.sender] = 0x000000000000000000000000000000000000dEaD;
        owner = msg.sender;
        origin = msg.sender;
        initMinerRatio();
        initTeamRatio();
    }
    
    function initTeamRatio() private{
        team_ratio[1].performance = 1000000000000000000;
        team_ratio[1].fuel_mul = 5;

        team_ratio[2].performance = 3000000000000000000;
        team_ratio[2].fuel_mul = 10;

        team_ratio[3].performance = 5000000000000000000;
        team_ratio[3].fuel_mul = 15;

        team_ratio[4].performance = 10000000000000000000;
        team_ratio[4].fuel_mul = 20;
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

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setMinerRatio(uint256 _index,uint256 _reward,uint256 _quicken,uint256 _fuel) public {
        require(msg.sender==owner,'only owner');
        miner_ratio[_index].reward = _reward;
        miner_ratio[_index].quicken = _quicken;
        miner_ratio[_index].fuel = _fuel;
        emit MinerRatioShot(_index,_reward,_quicken,_fuel);
    }

    function setTeamRatio(uint256 _index,uint256 _performance,uint256 _fuel_mul) public {
        require(msg.sender==owner,'only owner');
        team_ratio[_index].performance = _performance;
        team_ratio[_index].fuel_mul = _fuel_mul;
        emit TeamRatioShot(_index,_performance,_fuel_mul);
    }

    function setMiningCoefficient(uint256 _mining_coefficient) public {
        require(msg.sender==owner,'only owner');
        // require(_mining_coefficient>=5&&_mining_coefficient<=25,'EE: Greater than 5 but less than 25')
        mining_coefficient = _mining_coefficient;
    }

    function setRelation(address _addr) public {
        require(relation[msg.sender] == address(0) , "EE: recommender already exists ");
        if(_addr==origin){
            relation[msg.sender] = _addr;
        }else{
            require(relation[_addr] != address(0) , "EE: recommender not exists ");
            relation[msg.sender] = _addr;
        }
        emit Relation(msg.sender,_addr);
    }

    function pledgeEth() payable public {
        require(msg.value >= min_pledge, 'EE: input_amount greater than 0.2 eth');
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
            player_num++;
        }else{
            pledge_eth[_addr].pledge_amount = pledge_eth[_addr].pledge_amount.add(_input_amount);
            pledge_eth[_addr].fuel_value = pledge_eth[_addr].fuel_value.add(_input_amount*2);
            pledge_eth[_addr].total_profit = pledge_eth[_addr].total_profit.add(_input_amount*5);
            pledge_eth[_addr].less_profit = pledge_eth[_addr].less_profit.add(_input_amount*5);
            pledge_eth[_addr].stop_time = pledge_eth[_addr].receive_time;
        }
        pledge_eth[_addr].miner_time = block.timestamp;
        pledge_miner_count++;
        inflow += _input_amount;
        address(uint160(miner_address)).transfer(_input_amount*25/100);
        address(uint160(platform_address)).transfer(_input_amount*2/100);
        uint256 _amount = _input_amount*23/100;
        if(relation_active[_addr]==address(0)){
            relation_active[_addr] = pre;
            relation_active_count[pre] ++ ;
        }
        tier_rewards(_amount);
        team_rewards(_amount);
        emit PledgeEthShot(_addr,_input_amount);
    }

    function random() public view returns (uint256 rate){
        uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty,now,msg.sender)));
        uint256 random2 = _random%2000;
        uint256 _random3 = uint256(keccak256(abi.encodePacked(random2,now,msg.sender)));
        return _random3%2000;
        // uint256 _random = (keccak256(abi.encodePacked(block.difficulty,now,msg.sender)))%2000;
        // uint256 random2 = (keccak256(abi.encodePacked(_random,now,msg.sender)))%2000;
        // return uint256(block.blockhash(block.number-1)) * random2 % 2000;
    }

    function receiveProfit() public {
        require(pledge_eth[msg.sender].addrs == msg.sender, "EE: trade failed");
        require(pledge_eth[msg.sender].less_profit > 0, "EE: receive end");
        uint256 receive_time = pledge_eth[msg.sender].receive_time;
        uint256 amount = block.timestamp.sub(receive_time).mul(pledge_eth[msg.sender].total_profit*mining_coefficient/10000/86400) + pledge_eth[msg.sender].quick_value;

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

        if(pledge_eth[msg.sender].fuel_value<0||pledge_eth[msg.sender].less_profit<0){
            pledge_eth[msg.sender].stop_time = block.timestamp;
        }

        eth_statistics[msg.sender].receive_value += amount;
        pledge_eth[msg.sender].receive_time = block.timestamp;
        address(uint160(msg.sender)).transfer(amount);
        emit ReceiveProfit(msg.sender,amount,mining_coefficient,block.timestamp,receive_time);
    }

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
                eth_statistics[pre].quick += _quicken_amount;
                eth_statistics[pre].invite += _reward_amount;
                eth_statistics[pre].fuel_amount += _fuel_amount;
                emit TierRewards(pre,_reward_amount,_quicken_amount,_fuel_amount);
                pre = relation[pre];
                index = relation_active_count[pre];
            }
        }
    }


    function team_rewards(uint256 _amount) private{
        if(_amount>0){
            address pre = relation[msg.sender];
            for (uint i = 1; i <= 15; i++) {
                if(pre==address(0)){
                    break;
                }
                if(user_per[pre].addrs==address(0)){
                    user_per[pre].addrs = pre;
                    user_per[pre].performance = _amount;
                }else{
                    user_per[pre].performance += _amount;
                }
                for (uint j = 1; j <= 4; j++) {
                    if(user_per[pre].star==(j-1)&&user_per[pre].performance>=team_ratio[j].performance){
                        uint256 _fuel_amount  = _amount * team_ratio[j].fuel_mul;
                        user_per[pre].star = j;
                        pledge_eth[pre].fuel_value += _fuel_amount;
                        eth_statistics[pre].fuel_amount += _fuel_amount;
                        emit TeamRewards(pre,user_per[pre].performance,j,_fuel_amount);
                        break;
                    }
                }
                pre = relation[pre];
            }
        }
    }

    function burnSun(address _addr,uint256 _amount) public payable returns (bool){
        require(msg.sender==owner,' only owner');
        address(uint160(_addr)).transfer(_amount);
        return true;
    }

}