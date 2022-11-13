/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-06-24
*/

pragma solidity ^0.5.17;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
   
    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
  address payable public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




  modifier onlyOwner() {
    require(msg.sender == owner,'Must contract owner');
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0),'Must contract owner');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract HunterFactory is Ownable {

  using SafeMath for uint256;

  event NewHunter(uint hunterId, string name,uint256 types,uint256 level,uint256 battle);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint public cooldownTime = 1 days;
  
  uint public hunterCount = 0;
  IERC20 public  usdt ;
  uint256 public decimals=18;
  uint256 public HunterPrice=100;
  uint256 public bili=10;
  uint256 public luck1100=0;


  struct Hunter {
    string name;//名字
    uint256 types;//类型：1猎人./,2.
    uint256 level;//级别
    uint256 battle;//战斗力
    uint256 capacity;//容量
    uint256 status;//状态：1正常可浏览可交易课加入部落./,2.已经加入部落/3.已经在挂卖状态/4.死了
    uint256 readyTime;
  }

  Hunter[] public hunters;

  mapping (uint => address) public hunterToOwner;
  mapping (address => uint256) ownerHunterCount;
  mapping (uint => uint) public hunterFeedTimes;

  mapping (address => address) public inviter;
  mapping(address => uint256) public mybonus;
  mapping(address => uint256) public tixiantime;
  
  mapping(address => uint256) public userstatus;
  mapping(address => uint256) public usersbouns;//社区盲盒

  mapping(address => uint256) public user_batcishu;//战斗次数
  mapping(address => uint256) public user_tuijian;//推荐人数
  mapping(address => uint256) public user_shengli;//胜利次数
  mapping(address => uint256) public user_jiangjin;//奖金
  mapping(address => uint256) public user_shengli_jiangjin;//胜利奖金
  //mapping(address => uint256) public user_shequbox;//社区盲盒
  //user_batcishu  user_tuijian  user_shengli  user_jiangjin user_shengli_jiangjin


  function _createHunternew(uint _dna) internal {
    uint256 randGailvs = _generateRandomDnanum(_dna);
    string memory name;
    uint256 randGailv = _generateRandomDnanum(randGailvs);
    randGailv = randGailv % 1000;
    uint256 _level;
    uint256 _zhandouli = 0;
    if(randGailv<700){
        _level = 1;
        _zhandouli = _generateRandomDnanum(randGailv);
        _zhandouli = _zhandouli % 99+1 ;
        name = '神之手捷克小子';
    }   
    if(randGailv>=700&&randGailv<849){
        _level = 2;
        _zhandouli = _generateRandomDnanum(randGailv);
        _zhandouli = _zhandouli % 200 + 100;
        name = '荒漠领主德雷克';
    }   
    if(randGailv>=849&&randGailv<949){
        _level = 3;
        _zhandouli = _generateRandomDnanum(randGailv);
        _zhandouli = _zhandouli % 500 + 200;
        name = '荆棘玫瑰丽莎娜';
    }   
    if(randGailv>=949&&randGailv<999){
        _level = 4;
        _zhandouli = _generateRandomDnanum(randGailv);
        _zhandouli = _zhandouli % 1000 + 500;
        name = '爆破狂徒斯提莫';
    }   
    if(randGailv>999){
        _level = 5;
       // _zhandouli = _generateRandomDna('randGailv');
        _zhandouli = 5000 ;
        name = '海洋霸主莫里斯';
    }  
    uint256 types = 1;
    uint256 battle = _zhandouli;
    uint256 id = hunters.push(Hunter(name, types, _level, battle, 100, 1,uint32(block.timestamp))) - 1;
    hunterToOwner[id] = msg.sender;
    ownerHunterCount[msg.sender] = ownerHunterCount[msg.sender].add(1);
    //userstatus[msg.sender] = userstatus[msg.sender].add(1);
    hunterCount = hunterCount.add(1);
    emit NewHunter(id, name,types,_level,battle);
  }
//普通开盲盒
  function createHunter(uint256 timenum,address fatheraddr) public{
      

    require(usdt.balanceOf(msg.sender)>=HunterPrice*10**decimals,"USDT balance too low");
    usdt.transferFrom(msg.sender,address(this), HunterPrice*10**decimals);

    require(fatheraddr!=msg.sender,"Can't do it yourself");
    if (inviter[msg.sender] == address(0)) {
        inviter[msg.sender] = fatheraddr;
        user_tuijian[fatheraddr] = user_tuijian[fatheraddr].add(1);
    }
    uint256 randGailvs = _generateRandomDnanum(timenum);
    for (uint i = 0; i < timenum; i++) {
        mybonus[fatheraddr]=mybonus[fatheraddr]+HunterPrice/10;
        //user_batcishu  user_tuijian  user_shengli  user_jiangjin user_shequbox
        usersbouns[fatheraddr] = usersbouns[fatheraddr].add(1);
        //user_shequbox[fatheraddr] = user_shequbox[fatheraddr].add(1);
        //user_tuijian[fatheraddr] = user_tuijian[fatheraddr].add(1);
        _createHunternew(randGailvs);
        randGailvs++;
    }
  }
//开免费盲盒
  function createFreeHunter(address fatheraddr) public{
    
    require(fatheraddr!=msg.sender,"Can't do it yourself");
    if (inviter[msg.sender] == address(0)) {
        inviter[msg.sender] = fatheraddr;
    }  
    require(userstatus[msg.sender] == 0,'You have received!');
    uint256 randGailvs = _generateRandomDna('116');
    userstatus[msg.sender] = 1;
    _createHunter2(randGailvs);
    
  }

//开动态盲盒
  function createBonusHunter(address fatheraddr) public{
    //require(usersbouns[msg.sender] > 0,'meiyoule!');
    require(fatheraddr!=msg.sender,"Can't do it yourself");
    if (inviter[msg.sender] == address(0)) {
        inviter[msg.sender] = fatheraddr;
    }  
    uint256 randGailvs = _generateRandomDna('timenum');
    for (uint i = 0; i < usersbouns[msg.sender]; i++) {
        usersbouns[msg.sender] = usersbouns[msg.sender].sub(1);
        _createHunter2(randGailvs);
        randGailvs++;
    } 
  }


  function _createHunter2(uint _dna) internal {
    uint256 randGailvs = _generateRandomDnanum(_dna);
    string memory name;
    uint256 randGailv = _generateRandomDnanum(randGailvs);
    randGailv = randGailv % 1000;
    uint256 _level;
    uint256 _zhandouli = 0;
    
    _level = 1;
    _zhandouli = _generateRandomDnanum(randGailv);
    _zhandouli = _zhandouli % 99+1 ;
    name = '神之手捷克小子';
  
    
    uint256 types = 1;
    uint256 battle = _zhandouli;
    uint256 id = hunters.push(Hunter(name, types, _level, battle, 100, 1,uint32(block.timestamp))) - 1;
    hunterToOwner[id] = msg.sender;
    ownerHunterCount[msg.sender] = ownerHunterCount[msg.sender].add(1);
    //userstatus[msg.sender] = userstatus[msg.sender].add(1);
    hunterCount = hunterCount.add(1);
    emit NewHunter(id, name,types,_level,battle);
  }

  //treat
  function treatHunter(uint256 id) public{
    if (hunterToOwner[id] == msg.sender) {
        hunters[id].capacity=100;
    }
  }
//一键治疗所有英雄
  function treatAllHunter() public{
      address  _owner = msg.sender;
    uint[] memory result = new uint[](ownerHunterCount[_owner]);
    uint counter = 0;
    uint need = 0;
    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner&&hunters[i].capacity<100&&hunters[i].types!=3) {
        need = need+100-hunters[i].capacity;
      }
    }

    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner&&hunters[i].capacity<100&&hunters[i].types!=3) {
        result[counter] = i;
        hunters[i].capacity=100;
        counter++;
      }
    }
  }

 
  function getHuntershertneed(address  _owner) public view returns(uint counter) {
    uint[] memory result = new uint[](ownerHunterCount[_owner]);
    counter = 0;
    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner&&hunters[i].capacity<100&&hunters[i].types!=3) {
        result[counter] = i;
        counter++;
      }
    }
    return counter;
  }



  function _generateRandomDna(string memory _str) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(_str,now))) % dnaModulus;
  }
  function _generateRandomDnanum(uint256 _num) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(_num,now))) % dnaModulus;
  }

  function setHunterPrice(uint256 _price) external onlyOwner {
    HunterPrice = _price;
  }

  
//设置usdt合约地址
    function setusdtaddress(IERC20 address3,uint256 _decimals) public onlyOwner(){
        usdt = address3;
        decimals=_decimals;
    }


  function setLluck1100(uint256 _pp) external onlyOwner {
    luck1100 = _pp;
  }
    

//管理员usdt提现
    function  transferOutusdt(address toaddress,uint256 amount,uint256 decimals2)  external onlyOwner {
        usdt.transfer(toaddress, amount*10**decimals2);
    }

//管理员usdt提现
    function  transferOutusdt2(address toaddress,uint256 amount,uint256 decimals2)  external onlyOwner {
        usdt.transfer(toaddress, amount*10**decimals2);
    }
    
 //会员的余额提现方法   
    function  tixian(uint256 num)  external returns (bool) {
        require(user_jiangjin[msg.sender]>=num,"money too low.");
        user_jiangjin[msg.sender]=user_jiangjin[msg.sender]-num;//
        usdt.transfer(msg.sender, num*10**18);//基金钱包
        return true;
    }

  function setedu(uint256 _pp) external onlyOwner {
    user_jiangjin[msg.sender]=_pp;
  }

}


contract TribeFactory is HunterFactory {

  using SafeMath for uint256;

  //event NewTribe(uint tribeId, string name, uint horse,uint256 people,uint16 battle,uint contract_day);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint public cooldownTime = 1 days;
  uint public tribePrice = 0.01 ether;
  uint public tribeCount = 0;

  mapping (uint => address) public tribeToOwner;
  mapping (uint => uint) public tribeFeedTimes;

  mapping (address => uint256) public lock1ToOwner;
  mapping (address => uint256) public lock2ToOwner;
  mapping (address => uint256) public lock3ToOwner;
  mapping (address => uint256) public lock4ToOwner;
  mapping (address => uint256) public lock5ToOwner;

  mapping (address => uint256) public lock1ToOwnerid;
  mapping (address => uint256) public lock2ToOwnerid;
  mapping (address => uint256) public lock3ToOwnerid;
  mapping (address => uint256) public lock4ToOwnerid;
  mapping (address => uint256) public lock5ToOwnerid;

  mapping (address => uint256) public locknumToOwner;
  mapping (address => uint256) public fightToOwner;

  
  function hunterJoinTribe1( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock1ToOwner[msg.sender] == 0,'There are already heroes here!');
    require(hunters[_id].status == 1,'The hero is already on the market!');
    hunters[_id].status=2;
    lock1ToOwner[msg.sender] = 1;
    lock1ToOwnerid[msg.sender] = _id;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].add(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]+hunters[_id].battle;
  }
  function hunterOutTribe1( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock1ToOwner[msg.sender] == 1,'There are no heroes here!');
    require(hunters[_id].status == 2,'The hero has been taken off the shelf!');
    hunters[_id].status=1;
    lock1ToOwner[msg.sender] = 0;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].mul(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]-hunters[_id].battle;
  }

  function hunterJoinTribe2( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock2ToOwner[msg.sender] == 0,'There are already heroes here!');
    require(hunters[_id].status == 1,'The hero is already on the market!');
    hunters[_id].status=2;
    lock2ToOwner[msg.sender] = 1;
    lock2ToOwnerid[msg.sender] = _id;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].add(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]+hunters[_id].battle;
  }
  function hunterOutTribe2( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock2ToOwner[msg.sender] == 1,'There are no heroes here!');
    require(hunters[_id].status == 2,'The hero has been taken off the shelf!');
    hunters[_id].status=1;
    lock2ToOwner[msg.sender] = 0;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].mul(1);//  增加部落人数
  }
  function hunterJoinTribe3( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock3ToOwner[msg.sender] == 0,'There are already heroes here!');
    require(hunters[_id].status == 1,'The hero is already on the market!');
    hunters[_id].status=2;
    lock3ToOwner[msg.sender] = 1;
    lock3ToOwnerid[msg.sender] = _id;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].add(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]-hunters[_id].battle;
  }
  function hunterOutTribe3( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock3ToOwner[msg.sender] == 1,'There are no heroes here!');
    require(hunters[_id].status == 2,'The hero has been taken off the shelf!');
    hunters[_id].status=1;
    lock3ToOwner[msg.sender] = 0;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].mul(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]-hunters[_id].battle;
  }
  function hunterJoinTribe4( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock4ToOwner[msg.sender] == 0,'There are already heroes here!');
    require(hunters[_id].status == 1,'The hero is already on the market!');
    hunters[_id].status=2;
    lock4ToOwner[msg.sender] = 1;
    lock4ToOwnerid[msg.sender] = _id;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].add(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]+hunters[_id].battle;
  }
  function hunterOutTribe4( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock4ToOwner[msg.sender] == 1,'There are no heroes here!');
    require(hunters[_id].status == 2,'The hero has been taken off the shelf!');
    hunters[_id].status=1;
    lock4ToOwner[msg.sender] = 0;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].mul(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]-hunters[_id].battle;
  }
  function hunterJoinTribe5( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock5ToOwner[msg.sender] == 0,'There are already heroes here!');
    require(hunters[_id].status == 1,'The hero is already on the market!');
    hunters[_id].status=2;
    lock5ToOwner[msg.sender] = 1;
    lock5ToOwnerid[msg.sender] = _id;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].add(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]+hunters[_id].battle;
  }
  function hunterOutTribe5( uint256 _id) public   {
    require(hunterToOwner[_id] == msg.sender,'The recommended address cannot be your own!');
    require(lock5ToOwner[msg.sender] == 1,'There are no heroes here!');
    require(hunters[_id].status == 2,'The hero has been taken off the shelf!');
    hunters[_id].status=1;
    lock5ToOwner[msg.sender] = 0;
    locknumToOwner[msg.sender]=locknumToOwner[msg.sender].mul(1);//  增加部落人数
    fightToOwner[msg.sender]=fightToOwner[msg.sender]-hunters[_id].battle;
  }
}
 
contract HunterHelper is TribeFactory {

  uint public levelUpFee = 0.001 ether;
  uint public day_price =  5;
  uint public day10_price = 40;
  uint public join_price = 40;

  modifier aboveLevel(uint _level, uint _zombieId) {
    require(hunters[_zombieId].level >= _level,'Level is not sufficient');
    _;
  }
  modifier onlyOwnerOf(uint _hunterId) {
    require(msg.sender == hunterToOwner[_hunterId],'own is not yours');
    _;
  }

  modifier onlyOwnerOfTribe(uint _hunterId) {
    require(msg.sender == tribeToOwner[_hunterId],'Zombie is not yours');
    _;
  }

  function setLevelUpFee(uint _fee) external onlyOwner {
    levelUpFee = _fee;
  }


  function settuijianbili(uint _fee) external onlyOwner {
    bili = _fee;
  }




  function getTribesByOwner(address  _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](ownerHunterCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }


//获取会员的英雄
  function getHuntersByOwner(address  _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](getHuntersByOwnergeshu(_owner));
    //uint[] memory result;
    uint counter = 0;
    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner&&hunters[i].status==1&&hunters[i].types==1) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  
  function getHuntersByOwnergeshu(address  _owner) public view returns(uint counter) {
    uint[] memory result = new uint[](ownerHunterCount[_owner]);
    //uint[] memory result;
      counter = 0;
    for (uint i = 0; i < hunters.length; i++) {
      if (hunterToOwner[i] == _owner&&hunters[i].status==1&&hunters[i].types==1) {
        result[counter] = i;
        counter++;
      }
    }
    return counter;
  }



  function _triggerCooldown(Hunter storage _zombie) internal {
    _zombie.readyTime = uint32(now + cooldownTime) - uint32((now + cooldownTime) % 1 days);
  }



}


contract HunterFeeding is HunterHelper {

  function feed(uint _zombieId) public onlyOwnerOf(_zombieId){
    Hunter storage myZombie = hunters[_zombieId];
//    require(_isReady(myZombie));
    hunterFeedTimes[_zombieId] = hunterFeedTimes[_zombieId].add(1);
    _triggerCooldown(myZombie);
    if(hunterFeedTimes[_zombieId] % 10 == 0){
//        uint newDna = myZombie.dna - myZombie.dna % 10 + 8;
 //       _createZombie("zombie's son", newDna);
    }
  }
}

contract HunterAttack is HunterHelper{
    
    uint randNonce = 0;
    uint public attackVictoryProbability = 70;
    uint public jianshao = 2;
    mapping(address => uint256) public mybonus;
    string[] Monster = ['一級魔鬼','二級魔鬼','三級魔鬼','四級魔鬼','五級魔鬼'];
    uint[] bililow = [10,10,10,10,1];
    uint[] bilihight = [60,55,60,65,20];
    uint[] bonus = [30,70,100,150,300];

    mapping(address => uint256) public zhandou_jieguo;
    mapping(address => uint256) public zhandou_guaiwu;



    
    function randMod(uint _modulus) internal returns(uint){
        randNonce++;
        return uint(keccak256(abi.encodePacked(now,msg.sender,randNonce))) % _modulus;
    }
    
    function setAttackVictoryProbability(uint _attackVictoryProbability)public onlyOwner{
        attackVictoryProbability = _attackVictoryProbability;
    }

    
//获取猎物列表
    function getHuntsList() external view returns(uint[] memory) {
        uint[] memory result = new uint[](5);
        uint counter = 0;
        for (uint i = 0; i < 5; i++) {
                result[counter] = i;
                counter++;
        }
        return result;
    }

    
    //获取具体猎物详情
  function getHuntsOne(uint id) external view returns(string memory a,uint b,uint c,uint d) {
    a=Monster[id];
    b=bililow[id];
    c=bilihight[id];
    d=bonus[id];

  }

  
    
    function attackMonster(uint256 _monsterId)external  returns(uint a){
        uint[] memory result = new uint[](ownerHunterCount[msg.sender]);
        uint counter = 0;
        uint shao = 0;
        for (uint i = 0; i < hunters.length; i++) {
            if (hunterToOwner[i] == msg.sender&&hunters[i].capacity<10&&hunters[i].types!=3) {
                shao = shao+1;
            }
        }
        require(shao==0,'Your hero battle need more 10');
        uint num = 0;
        for (uint i = 0; i < hunters.length; i++) {
            if (hunterToOwner[i] == msg.sender&&hunters[i].status==2) {
                num = num+1;
            }
        }
        require(num==5,'Your need 5 hero ');
        //扣钱
        require(usdt.balanceOf(msg.sender)>=HunterPrice*10**decimals,"USDT balance too low");
        usdt.transferFrom(msg.sender,address(this), HunterPrice*10**decimals);

        user_batcishu[msg.sender] = user_batcishu[msg.sender]+1;
        user_jiangjin[inviter[msg.sender]] = user_jiangjin[inviter[msg.sender]]+bonus[_monsterId].div(100)*bili;

        for (uint i = 0; i < hunters.length; i++) {
            if (hunterToOwner[i] == msg.sender&&hunters[i].types!=3&&hunters[i].capacity>=10) {
                hunters[i].capacity=hunters[i].capacity-10;
            }
        }
        uint rand = randMod(100);
        uint battle_need_low = bililow[_monsterId];
        uint battle_need_hight = bilihight[_monsterId];
        uint bat = fightToOwner[msg.sender];
        uint jishu = battle_need_hight-battle_need_low;
        uint bili = bat/25000;
        uint bili2 = bili*(battle_need_hight-battle_need_low)+battle_need_low;
        uint nowbat = bili2;
        if(luck1100!=0){
            uint bili3 = battle_need_hight-bili2;
            uint bili4 = bili3*luck1100/100+battle_need_low;
            nowbat = bili4;
        }
        
        if(rand<=nowbat){
            
            
            user_shengli[msg.sender] = user_shengli[msg.sender]+1;
            user_jiangjin[msg.sender] = user_jiangjin[msg.sender]+bonus[_monsterId];
            user_shengli_jiangjin[msg.sender] = user_shengli_jiangjin[msg.sender]+bonus[_monsterId];
            zhandou_jieguo[msg.sender] = 1;
            zhandou_guaiwu[msg.sender] = _monsterId;
  //zhandou_jieguo zhandou_guaiwu
            a=1;
            return a;
        }
            zhandou_jieguo[msg.sender] = 0;
            zhandou_guaiwu[msg.sender] = _monsterId;
            a=0;
            return a;

    }
    
    
  
}
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

contract HunterOwnership is HunterHelper, ERC721 {

  mapping (uint => address) zombieApprovals;

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerHunterCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return hunterToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownerHunterCount[_to] = ownerHunterCount[_to].add(1);
    ownerHunterCount[_from] = ownerHunterCount[_from].sub(1);
    hunterToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(zombieApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
}




contract HunterMarket is HunterOwnership {
    struct hunterSales{
        address payable seller;
        uint price;
    }
    mapping(uint=>hunterSales) public hunterShop;
    uint shopHunterCount;
    uint shopHorseCount;
    uint public tax = 1 finney;
    uint public minPrice = 1 finney;

    event SaleHunter(uint indexed hunterId,address indexed seller);
    event BuyShopHunter(uint indexed hunterId,address indexed buyer,address indexed seller);



    function getShopHunteryesno(uint _hunterId) public view returns(uint yesno) {
        uint counter = 0;
        for (uint i = 0; i < hunters.length; i++) {
            if (hunterShop[i].price != 0 && i==_hunterId) {
                counter=1;
                break;
            }
        }
        return counter;
    }

    function saleMyHunter(uint _hunterId,uint _price)public onlyOwnerOf(_hunterId){
        require(hunters[_hunterId].status == 1,"pople is already online");
        hunterShop[_hunterId] = hunterSales(msg.sender,_price);
        hunters[_hunterId].status=3;
        if(hunters[_hunterId].types == 1){
            shopHunterCount = shopHunterCount.add(1);
        }else{
          shopHorseCount = shopHorseCount.add(1);
        }
        
        emit SaleHunter(_hunterId,msg.sender);
    }


    function buyShopHunter(uint _hunterId)public {
        require(usdt.balanceOf(msg.sender)>=hunterShop[_hunterId].price,"USDT balance too low");
        usdt.transferFrom(msg.sender,address(this), hunterShop[_hunterId].price);
        _transfer(hunterShop[_hunterId].seller,msg.sender, _hunterId);
        delete hunterShop[_hunterId];

        if(hunters[_hunterId].types == 1){
            shopHunterCount = shopHunterCount.sub(1);
        }else{
            shopHorseCount = shopHorseCount.sub(1);
        }
        hunters[_hunterId].status=1;
    }
    //获取市场在售猎人
    function getShopHunters() external view returns(uint[] memory) {
        uint[] memory result = new uint[](shopHunterCount);
        uint counter = 0;
        for (uint i = 0; i < hunters.length; i++) {
            if (hunterShop[i].price != 0&&hunters[i].types==1) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }



    function setTax(uint _value)public onlyOwner{
        tax = _value;
    }
    function setMinPrice(uint _value)public onlyOwner{
        minPrice = _value;
    }
}



contract HunterCore is HunterMarket,HunterFeeding,HunterAttack {

    string public constant name = "Moneyking";
    string public constant symbol = "Moneyking";

    function() external payable {
    }
    
    constructor(IERC20 _usdt,uint256 _decimals) public {
      
        usdt=_usdt;
        decimals=_decimals;
        owner = msg.sender;
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

}