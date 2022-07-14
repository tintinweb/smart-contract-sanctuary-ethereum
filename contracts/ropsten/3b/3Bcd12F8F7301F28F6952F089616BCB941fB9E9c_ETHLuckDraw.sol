/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function decimals() external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ETHLuckDraw{
    using SafeMath for uint256;
    address private _owner;
    //游戏轮次
    uint256 private _gameCount = 0;
    //游戏map
    mapping(uint256 => Game) private _gameMap;
    //合约奖池接收90%
    uint256 private _poolFee = 90;
    //平台接收10%
    address payable private _receiveEth = 0x80726ff457551fe0FD4966750ecDC61a7BB84f75;
    //参与时间
    mapping(uint256 => mapping(address => uint256)) private _shareTimeMap;
    //参与地址对应的游戏回合 
    mapping(address => mapping(uint256 => Session)) private _sessionMap;
    //参与事件(用户,模式id,场次id,金额,参与时间)
    event Share(address account,uint256 gameId,uint256 time);
    //时间间隔
    uint256 private interval = 259200;

    modifier isOwner(){
        require(msg.sender == _owner);
        _;
    }

    function setReceiveEth(address payable account) public isOwner{
        _receiveEth = account;
    }

    //获取地址余额
    function getBalance(address addr)  public view returns (uint){
        return addr.balance;
    }

    //hash对应的随机数
    struct Session{
        bytes32 hash;
        uint256[] randomNum;
    }

    //规则
    struct Game {
        //eth单价
        uint256 price;
        //随机数个数
        uint256 randomNum;
        //总奖池
        uint256 poolCount;
        address payable poolAddress;
        //周期时长
        uint256 duration;
    }

    constructor() public {
        _owner = msg.sender;
        init();
    }

    function init() internal {
        _gameMap[++_gameCount] = Game(1 * 10 ** 16,1,0,address(0x2E0fbF7d42e687555f6b4dbb1a9C662b08204899),interval);
        _gameMap[++_gameCount] = Game(5 * 10 ** 16,5,0,address(0x8DbCC0D6239A40b1DCF5b670A65Ff86A2F482F53),interval);
        _gameMap[++_gameCount] = Game(1 * 10 ** 17,8,0,address(0xf3c422F99402Db37d1ad5F19d1cE71b30046BB1a),interval);
    }

    function setShareTime(address account,uint256 gameId,uint256 time) public isOwner{
        _shareTimeMap[gameId][account] = time;
    }

    function share(uint256 gameId) external payable {
        (uint256 price,uint256 randomNum,uint256 poolCount,address payable poolAddress,uint256 duration) = getGameRuleById(gameId);
        require(msg.value >= price,"eth Insufficient expenses");
        require(now - _shareTimeMap[gameId][msg.sender] > duration,"Come back after the lottery");
        uint256 eth = calculateReward(msg.value,_poolFee);
        poolAddress.transfer(eth);
        _receiveEth.transfer(msg.value.sub(eth));
        _shareTimeMap[gameId][msg.sender] = now;
        Game memory game = _gameMap[gameId];
        game.poolCount = poolCount.add(eth);
        _gameMap[gameId] = game;
        delete _sessionMap[msg.sender][gameId];
        Session storage session = _sessionMap[msg.sender][gameId];
        uint256[] storage number = session.randomNum;
        for(uint i = 0;i < randomNum;i++){
            uint256 x = getRandomNum(i);
            number.push(x);
        }
        _sessionMap[msg.sender][gameId] = session;
        emit Share(msg.sender,gameId,now);
    }
    
    function addHash(address account,uint256 gameId,bytes32 hash) public isOwner{
        require(isShare(gameId,account),"User not participating");
        Session memory session = _sessionMap[account][gameId];
        require(session.hash == bytes32(0),"Hash already exists");
        session.hash = hash;
        _sessionMap[account][gameId] = session;
    }

  
    function drawPrize(uint256 gameId) external view returns(bytes32) {
        require(isShare(gameId,msg.sender),"Not participating in the game");
        (,,,,uint256 duration) = getGameRuleById(gameId);
        uint256 shareTime = shareTimeMap(gameId,msg.sender);
        require(now - shareTime >= duration,"It's not time for the lottery");
        Session memory session = _sessionMap[msg.sender][gameId];
        uint256 hashNumber = getHashLastNumber(session.hash);
        uint256[] memory number = session.randomNum;
        for(uint i = 0;i < number.length;i++){
            if(hashNumber == number[i]) return session.hash;
        }
        return bytes32(0);
    }

    function shareTimeMap(uint256 gameId,address account) public view returns(uint256){
        return _shareTimeMap[gameId][account];
    }
    
    function getSession(uint256 gameId,address account) public view returns(bytes32,uint256[] memory){
         Session memory session = _sessionMap[account][gameId];
        return (session.hash,session.randomNum);
    }

    function isShare(uint256 gameId,address account) public view returns(bool){
        return _shareTimeMap[gameId][account] != uint256(0); 
    }

    function getRandomNum(uint256 index) private view returns(uint256){
        uint256[] memory random = new uint256[](8);
        random[0] = now;
        random[1] = uint256(block.difficulty);
        random[2] = uint256(uint160(block.coinbase));
        random[3] = uint256(~uint256(0) + now);
        random[4] = uint256(uint160(msg.sender));
        random[5] = uint256(~uint160(msg.sender));
        random[6] = uint256(uint160(address(this)));
        random[7] = uint256(now + now);
        return random[index] % 10; 
    }

    function calculateReward(uint256 amount,uint256 fee) private pure returns (uint256){
         return amount.mul(fee).div(10 ** 2);
    }
    

    function getGameRuleById(uint256 gameId) public view returns(uint256,uint256,uint256,address payable,uint256){
        Game memory game = _gameMap[gameId];
        return(game.price,game.randomNum,game.poolCount,game.poolAddress,game.duration);
    }
  
    function getHashLastNumber(bytes32 hash) public pure returns(uint8) {
        for(uint8 i = hash.length - 1;i >= 0;i--){
            uint8 b = uint8(hash[i]) % 16;
            if(b>=0 && b<10) return b;
        }
        return 0;
    }
}