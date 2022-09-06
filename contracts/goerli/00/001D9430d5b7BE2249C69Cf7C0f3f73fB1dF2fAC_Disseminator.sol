// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

import './AdbotProtocol.sol';

// Author: @stargate
contract Disseminator is IDisseminator{
    uint public fee;
    address public feeGetter;
    address public StarGate;

    mapping(address => mapping(uint => uint)) public getAdbot;
    mapping(address=>uint) public getUserAdbotAmount;
    mapping(uint =>RewardRate) public rewardRateInfo;
    mapping(uint => uint) public repentRate;

    struct RewardRate{
        uint minRate;
        uint averageRate;
    }
    struct Adbot{
        address project;
        address adbot;
    }
     
    Adbot[] public allAdbot;
    
    event FeeChanged(uint indexed newFee);
    event FeeGetterChanged(address indexed newFeeGetter);
    event FeeSetterChanged(address indexed newFeeSetter);
    event AdbotCreated(uint indexed reward, address indexed projiect, address indexed adbot,uint fee);

    error FORBIDDEN(string);

    constructor(uint _fee,address _feeGetter){
        require(_fee >=0 && _fee<=100,'StarGate: FEE_INVALID');
        fee = _fee;
        feeGetter = _feeGetter;
        StarGate = msg.sender;
        repentRate[1] = 5;
        repentRate[2] = 8;
        repentRate[3] = 0;
        repentRate[4] = 30;
    }
  
    function createAdbot(uint reward)external payable returns(address adbot ){
        address creater = msg.sender;
        uint adbotID = getUserAdbotAmount[creater];
        require(reward == msg.value,'StarGate: INVALIDReward');
        require(getAdbot[creater][adbotID] == 0,'');
        AdbotProtocol adbotprotocol = new AdbotProtocol{value:reward}(reward,fee,StarGate,creater,rewardRateInfo[reward].minRate,rewardRateInfo[reward].averageRate);
        adbot  = address(adbotprotocol);
        getAdbot[creater][adbotID] == reward;
        Adbot memory _adbot =Adbot(creater,adbot);
        allAdbot.push(_adbot);
        updataUserAdbot(creater);
        emit AdbotCreated(reward, creater, adbot,fee);
    }

    function updateRewardRate(uint _reward, uint _minRate,uint _averageRate)external{
        if(msg.sender !=StarGate){
            revert FORBIDDEN("StarGate: FORBIDDEN");
        }
        rewardRateInfo[_reward].minRate = _minRate;
        rewardRateInfo[_reward].averageRate = _averageRate;
    }

    function allAdbotsLength() external view returns (uint) {
        return allAdbot.length;
    }   

    function updataUserAdbot(address _creater)private {
        getUserAdbotAmount[_creater]+=1;
    }

    function setRepent(uint _rate,uint repentfee)external {
        if(msg.sender!=StarGate){
            revert FORBIDDEN("StarGate: FORBIDDEN");
        }
        repentRate[_rate] = repentfee;

    }

    function setFee(uint _fee) external {
        require(_fee>0&&_fee<1000);
        if(msg.sender!=StarGate){
            revert FORBIDDEN("StarGate: FORBIDDEN");
        }
        fee = _fee;
        emit FeeChanged(fee);
    }

    function setFeeGetter(address _feeGetter) external {
        if(msg.sender!=StarGate){
            revert FORBIDDEN("StarGate: FORBIDDEN");
        }
        feeGetter = _feeGetter;
        emit FeeGetterChanged(feeGetter);
    }

    function setFeeToSetter(address _StarGate) external {
       if(msg.sender!=StarGate){
            revert FORBIDDEN("StarGate: FORBIDDEN");
        }
        StarGate = _StarGate;
        emit FeeSetterChanged(feeGetter);
    }
     
    function gettime()public view returns(uint){
        return block.timestamp;
    }

    
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

import './interfaces/IDisseminator.sol';

contract AdbotProtocol {
    uint public fee;
    uint public constant rate = 100;
    uint public starttime;
    uint public deadline;
    uint public reward;
    bool public isEnd;
    bool public isInit;
    uint public  totalCompletedTask;
    address public disseminator;
    address  public  StarGate;
    address public project;
    address[] public allRole;
    uint public minRewardRate;
    uint public averageRewardRate;
    bool public isSetRewardRate; 

    mapping(address=>bool) public isBind;
    mapping(address=>bool) public isLeaf;
    mapping(address=>uint) public kolIndex;
    mapping(address=>uint) public kolReward;
    mapping(address=>bool) public isKol;

    struct KOL{
        address kolAddress;
        uint kolCompletedTask;
        uint kolReward;
        address[] leaf;
    }

    enum State{
        Creat,
        Checked,
        Fail,
        Up,
        Release,
        Inactive
    }
    State public state;

    KOL[] private kols;

    error FORBIDDEN(string);

    modifier beforeDeadline(){
        require(block.timestamp < deadline,'StarGate: TIME_LATE');
        _;
    }
    modifier afterDeadline(){
        require(block.timestamp > deadline,'StarGate: TIME_EARLY');
        _;
    }
    modifier  onlyStarGate(){
        require(msg.sender == StarGate,'StarGate: OnlyStarGate');
        _;
    }
    
    constructor(uint _reward,uint _fee,address _StarGate,address _project,uint _minRewardRate,uint _averageRewardRate)  payable {
        reward = _reward;
        fee = _fee;
        StarGate = _StarGate;
        project = _project;
        minRewardRate = _minRewardRate;
        averageRewardRate = _averageRewardRate;
        disseminator = msg.sender;
    }

    function initialize(uint _starttime, uint _deadline,address[] memory _roles) external {
       address sender = msg.sender;
       require(sender == project||sender == StarGate,'1');
       require(isInit == false,'StarGate: INITED');
        starttime = _starttime;
        deadline = _deadline;
        (uint _minRewardRate,uint _averageRewardRate) = IDisseminator(disseminator).rewardRateInfo(reward);
        if(_minRewardRate!=0&&_averageRewardRate !=0){
            isSetRewardRate = true;
        }
        minRewardRate = _minRewardRate;
        averageRewardRate = _averageRewardRate;
        allRole = _roles;
        bindRolas(allRole);
        initKOLs();
        isInit = true;
    }

    function updateState(State _state)external onlyStarGate{
        state = _state;
    }

    function repent() external{
        address payable msgsender = payable(msg.sender);
        require( msgsender== project,'NOT projiect');
        uint _state = uint(state);
        require(_state>=1&&_state<=4,'INVALIDSTATE');
        uint _fee = IDisseminator(disseminator).repentRate(_state);
        uint feeuse = reward*_fee/rate;
        msgsender.transfer(reward - feeuse);
        address payable _StarGate = payable(StarGate);
        _StarGate.transfer(feeuse);
        state = State.Inactive;
        reward = 0;

    }

    function setReward(uint _minRewardRate,uint _averageRewardRate)external{
      if(msg.sender!=IDisseminator(disseminator).StarGate()){
          revert FORBIDDEN("StarGate: FORBIDDEN");
      }
      minRewardRate = _minRewardRate;
      averageRewardRate = _averageRewardRate;
      isSetRewardRate = true;
    }

    function getKOLLength() public view returns(uint){
        return allRole.length - 1;
    }

    function bindRolas(address[] memory _kols ) private {
        for(uint i=0;i<_kols.length;i++){
            isBind[_kols[i]]= true;
        }
    }  
    
    function initKOLs() private {
        for(uint i = 0;i<getKOLLength();i++){
            KOL memory kol;
            kol.kolAddress = allRole[i+1];
            kols.push(kol);
            kolIndex[allRole[i+1]] = i;
            isKol[allRole[i+1]] = true;
        }
       
    }  
 
    function updateKOLKPI(address _kol,address _leaf)external  beforeDeadline {
        require(isInit == true,'StarGate: INITED');
        require(isLeaf[_leaf] == false,'Stargate: ALREADY_IN');
        require(isKol[_kol]== true,'StarGate: NOTKOL');
        uint _kolIndex = getKOLIndex(_kol);
        kols[_kolIndex].kolCompletedTask += 1;
        kols[_kolIndex].leaf.push(_leaf);
        totalCompletedTask += 1;
        isLeaf[_leaf] = true;
    }
    
    function grant()external afterDeadline{
        require(isSetRewardRate==true,'StarGate: Wait');
        require(isEnd == false,'Stargate: ISENDED');
        uint _minRewardRate = minRewardRate;
        uint _averageRewardRate = averageRewardRate;
        address[] memory _allRole = allRole;
        uint _reward = reward;
        uint _totalTask = totalCompletedTask;
        uint use;
        uint _kolslen = getKOLLength();
        if(_totalTask<_minRewardRate){
            for(uint i=0;i<_kolslen;i++){
                uint  _kolCompletedTask = kols[i].kolCompletedTask;
                uint _kolReward;    
                if(_kolCompletedTask<_minRewardRate/_kolslen){
                    _kolReward = _reward/_averageRewardRate*70*kols[i].kolCompletedTask/rate;
                }else{
                    _kolReward = _reward/_averageRewardRate*kols[i].kolCompletedTask;
                }
                
                kolReward[_allRole[i+1]]= _kolReward; 
                kols[getKOLIndex(_allRole[i+1])].kolReward = _kolReward;
                use += _kolReward;
            }
        }else {             
            for(uint i=0;i<_kolslen;i++){
                uint  _kolCompletedTask = kols[i].kolCompletedTask;
                uint _kolReward;    
                if(_kolCompletedTask<_minRewardRate/_kolslen){
                    _kolReward = _reward/_totalTask*70*kols[i].kolCompletedTask/rate;    
                }else{
                    _kolReward = _reward/_totalTask*kols[i].kolCompletedTask; 
                }
                kolReward[_allRole[i+1]]= _kolReward; 
                kols[getKOLIndex(_allRole[i+1])].kolReward = _kolReward;
                use += _kolReward;
            }
        }
        kolReward[allRole[0]] = reward - use;
        isEnd =true;
    }

    function withdraw()external afterDeadline{
        require(isEnd == true,'StarGate: NOTGRANT');
        address payable  withdrawer = payable(msg.sender);
        require(isBind[withdrawer]==true,'Stargate: NOT_IN_ADBOT');
        uint _reward = kolReward[withdrawer];
        uint _fee = _reward * fee /rate;
        takeFee(_fee);
        kolReward[withdrawer] = 0;
        withdrawer.transfer(_reward-_fee);
    }

    function takeFee(uint _fee)private {
        address payable feeGetter = payable(IDisseminator(disseminator).feeGetter());
        feeGetter.transfer(_fee);
    }

    function getKOLInfo(address _kol)public view returns(KOL memory kol){
        require(isBind[_kol]==true,'StarGate: NOTBIND');
        return kols[getKOLIndex(_kol)];
    }

    function getKOLIndex(address _kol)public view returns(uint index){
        require(isKol[_kol] == true,'StarGate: NOTKOL');
        index = kolIndex[_kol];
    }

    function balance()public view returns(uint){
        return address(this).balance;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

interface IDisseminator {
    
    function feeGetter() external view returns (address);
    function StarGate() external view returns (address);
    function rewardRateInfo(uint)external view returns(uint,uint);
    function repentRate(uint)external view returns(uint);
}