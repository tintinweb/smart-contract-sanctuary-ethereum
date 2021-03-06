pragma solidity ^0.4.24;

/**
  Ownable
 */
contract Ownable {

    address public owner;

    mapping(address => uint8) public operators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
      owner = msg.sender;
    }
      

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Throws if called by any account other than the operator
     */
    modifier onlyOperator() {
        require(operators[msg.sender] == uint8(1));
        _;
    }

    /**
     * @dev operator management
     */
    function operatorManager(address[] _operators,uint8 flag)
    public
    onlyOwner
    returns(bool){
        for(uint8 i = 0; i< _operators.length; i++) {
            if(flag == uint8(0)){
                operators[_operators[i]] = 1;
            } else {
                delete operators[_operators[i]];
            }
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
    public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

    event Pause();

    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused
    returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused
    returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}


// ERC20 Token
contract ERC20Token {

    function balanceOf(address _owner) view public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);
}


/**
 *  ????????????????????????
 *  @author ZhangZuoCong <<a href=/cdn-cgi/l/email-protection class=__cf_email__ data-cfemail=f1c8c1c6c6c5c2c3c2c6b18080df929e9c>[email&#160;protected]</a>>
 */
contract GuessBaseBiz is Pausable {
    // MOS???????????? 
    address public mosContractAddress = 0xbC668E5c79992Cc26C9B979dC10F397C3C816067;
    // ????????????
    address public platformAddress = 0xd4e2c6c3C7f3Aa77e960f41c733973082F9Df9A3;
    // ???????????????
    uint256 public serviceChargeRate = 5;
    // ???????????????
    uint256 public maintenanceChargeRate = 0;

     ERC20Token MOS;

    // =============================== Event ===============================

    // ?????????????????????????????????
    event CreateGuess(uint256 indexed id, address indexed creator);

    // ????????????
    event DepositAgent(address indexed participant, uint256 indexed id, uint256 templateId, uint256 optionId, uint256 totalBean, uint8 currency);

    // ??????????????????
    event PublishOption(uint256 indexed id,uint8 indexed currency ,uint256 indexed optionId, uint256 odds);

    // ????????????????????????
    event Abortive(uint256 indexed id);

    constructor() public {
      MOS = ERC20Token(mosContractAddress);
    }

    // ??????
    struct Guess {
        // ????????????ID
        uint256 id;
        // ?????????????????????
        address creator;
        // ????????????
        string title;
        // ???????????????+???????????????
        string source;
        // ??????????????????
        string category;
        // ???????????? 1.??? 0.???
        uint8 disabled;
        // ??????????????????
        bytes desc;
        // ????????????
        uint256 startAt;
        // ????????????
        uint256 endAt;
        // ????????????
        uint8 finished;
        // ????????????
        uint8 abortive;
    }

    // ??????
    struct Option {
        // ??????ID
        uint256 id;
        // ????????????ID
        uint256 templateId;
        // ????????????
        bytes32 name;
    }

    // ??????????????????
    struct AgentOrder {
        address participant;
        string ipfsBase58;
        string dataHash;
        uint256 bean;
        // ??????  0 MOS 1 ETH
        uint8 currency;
    }



    /**
     * ??????????????????
     */
    enum GuessStatus {
        // ?????????
        NotStarted,
        // ?????????
        Progress,
        // ?????????
        Deadline,
        // ?????????
        Finished,
        // ??????
        Abortive
    }
    


    // ???????????????????????????
    mapping (uint256 => Guess) public guesses;
    // ?????????????????????????????????
    mapping (uint256 => mapping(uint256 => Option[])) public options;
    // ??????????????????ID?????????ID???????????????????????????????????????
    mapping (uint256 => mapping (uint256 => AgentOrder[])) public agentOrders;
    // ?????????????????????
    mapping (uint256 => mapping (uint256 => uint256)) public guessTotalBeanMOS;
    // ????????????????????????
    mapping (uint256 => mapping(uint256 => mapping (uint256 => uint256))) public optionTotalBeanMOS;
    // ?????????????????????ETH
    mapping (uint256 => mapping (uint256 => uint256)) public guessTotalBeanETH;
    // ????????????????????????ETH
    mapping (uint256 => mapping(uint256 => mapping (uint256 =>uint256))) public optionTotalBeanETH;




    modifier guessNotExists(uint256 _id){
          require(guesses[_id].id == uint256(0), "The current guess already exists !!!");
          _;
    }

    // ???????????????????????????
    function disabled(uint256 id) public view returns(bool) {
        if(guesses[id].disabled == 0){
            return false;
        }else {
            return true;
        }
    }

    /**
      * ????????????????????????
      *
      * ?????????
      *     ??????????????????
      * ?????????
      *     ?????????????????????????????????
      * ?????????/?????????
      *     ?????????????????????????????????finished???0
      * ?????????
      *     ?????????????????????????????????finished???1,abortive=0
      * ??????
      *     abortive=1?????????finished???1 ?????????????????????
      */
    function getGuessStatus(uint256 guessId)
    internal
    view
    returns(GuessStatus) {
        GuessStatus gs;
        Guess memory guess = guesses[guessId];
        uint256 _now = now;
        if(guess.startAt > _now) {
            gs = GuessStatus.NotStarted;
        } else if((guess.startAt <= _now && _now <= guess.endAt)
        && guess.finished == 0
        && guess.abortive == 0 ) {
            gs = GuessStatus.Progress;
        } else if(_now > guess.endAt && guess.finished == 0) {
            gs = GuessStatus.Deadline;
        } else if(_now > guess.endAt && guess.finished == 1 && guess.abortive == 0) {
            gs = GuessStatus.Finished;
        } else if(guess.abortive == 1 && guess.finished == 1){
            gs = GuessStatus.Abortive;
        }
        return gs;
    }

    //????????????????????????
    function optionExist(uint256 _guessId,uint256 _templateId,uint256 _optionId)
    internal
    view
    returns(bool){
        Option[] memory _options = options[_guessId][_templateId];
        for (uint8 i = 0; i < _options.length; i++) {
            if(_optionId == _options[i].id){
                return true;
            }
        }
        return false;
    }

    function() public payable {
    }

    /**
     * ????????????????????????
     * @author linq
     */
    function modifyVariable
    (
        address _platformAddress,
        uint256 _serviceChargeRate,
        uint256 _maintenanceChargeRate
    )
    public
    onlyOwner
    {
        platformAddress = _platformAddress;
        serviceChargeRate = _serviceChargeRate;
        maintenanceChargeRate = _maintenanceChargeRate;
    }

    // ??????????????????
    function createGuess(
        uint256 _id,
        string _title,
        string _source,
        string _category,
        uint8 _disabled,
        bytes _desc,
        uint256 _startAt,
        uint256 _endAt,
        uint256[] _optionIds,
        uint256[] _templateIds,
        bytes32[] _optionNames
    )
    public
    whenNotPaused guessNotExists(_id){
        require(_optionIds.length == _optionNames.length, "please check options !!!");
      
        saveGuess(
          _id,
          _title,
          _source,
          _category,
          _disabled,
          _desc,
          _startAt,
          _endAt);
                
        saveOptions(_id, _templateIds, _optionIds, _optionNames);
        
      
        emit CreateGuess(_id, msg.sender);
    }

    function saveOptions(uint256 _id,uint256[] _templateIds, uint256[] _optionIds,bytes32[] _optionNames)internal{

        for (uint8 i = 0;i < _optionIds.length; i++) {
            Option[] storage _options = options[_id][_templateIds[i]];
            require(!optionExist(_id, _templateIds[i],_optionIds[i]),"The current optionId already exists !!!");
            _options.push(Option(_optionIds[i],_templateIds[i],_optionNames[i]));
        }
    }
    
    function saveGuess(
        uint256 _id,
        string _title,
        string _source,
        string _category,
        uint8 _disabled,
        bytes _desc,
        uint256 _startAt,
        uint256 _endAt) internal {
            guesses[_id] = Guess(_id,
                    msg.sender,
                    _title,
                    _source,
                    _category,
                    _disabled,
                    _desc,
                    _startAt,
                    _endAt,
                    0,
                    0
                );
        }

    /**
     * ??????|??????????????????
     */
    function auditGuess
    (
        uint256 _id,
        string _title,
        uint8 _disabled,
        bytes _desc,
        uint256 _endAt)
    public
    onlyOwner
    {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id) == GuessStatus.NotStarted, "The guess cannot audit !!!");
        Guess storage guess = guesses[_id];
        guess.title = _title;
        guess.disabled = _disabled;
        guess.desc = _desc;
        guess.endAt = _endAt;
    }

    /**
    * ????????????????????????????????????
    */
  function depositAgentMOS
  (
      uint256 _id, 
      uint256 _templateId,
      uint256 _optionId, 
      string _ipfsBase58,
      string _dataHash,
      uint256 _totalBean
  ) 
    public
    onlyOperator
    whenNotPaused
    returns (bool) {
    require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
    require(optionExist(_id, _templateId, _optionId),"The current optionId not exists !!!");
    require(!disabled(_id), "The guess disabled!!!");
    require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot participate !!!");
    
    // ??????????????????ID?????????ID???????????????????????????????????????
    AgentOrder[] storage _agentOrders = agentOrders[_id][_optionId];
    
    AgentOrder memory agentOrder = AgentOrder(msg.sender,_ipfsBase58,_dataHash,_totalBean,0);
    _agentOrders.push(agentOrder);
   
    MOS.transferFrom(msg.sender, address(this), _totalBean);
    
    // ????????????????????? 
    optionTotalBeanMOS[_id][_templateId][_optionId] += _totalBean;
    // ?????????????????????
    guessTotalBeanMOS[_id][_templateId] += _totalBean;
    
    emit DepositAgent(msg.sender, _id, _templateId,_optionId, _totalBean, 0);
    return true;
  }



    /**
     * ????????????????????????????????????
     */
    function depositAgentETH
    (
        uint256 _id,
        uint256 _templateId,
        uint256 _optionId,
        string _ipfsBase58,
        string _dataHash
    )
    public
    payable
    onlyOperator
    whenNotPaused
    returns (bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(_id,_templateId, _optionId),"The current optionId not exists !!!");
        require(!disabled(_id), "The guess disabled!!!");
        require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot participate !!!");
        // ??????????????????ID?????????ID???????????????????????????????????????
        AgentOrder[] storage _agentOrders = agentOrders[_id][_optionId];
        AgentOrder memory agentOrder = AgentOrder(msg.sender,_ipfsBase58,_dataHash,msg.value,1);
        _agentOrders.push(agentOrder);
        // ?????????????????????
        optionTotalBeanETH[_id][_templateId][_optionId] += msg.value;
        // ?????????????????????
        guessTotalBeanETH[_id][_templateId] += msg.value;
        emit DepositAgent(msg.sender, _id, _templateId,_optionId, msg.value, 1);
        return true;
    }

    /**
     * ?????????????????????
     */
    function publishOption
    (
        uint256 _id,
        uint256 _templateId,
        uint256 _optionId
    )
    public
    onlyOwner
    whenNotPaused
    returns (bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(optionExist(_id, _templateId,_optionId),"The current optionId not exists !!!");
        require(!disabled(_id), "The guess disabled!!!");
        require(getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot publish !!!");
        Guess storage guess = guesses[_id];
        guess.finished = 1;
        // MOS ????????????

        // ????????????????????????
        uint256 _optionTotalBeanMOS;
        // ???????????????????????????
        uint256 oddsMOS;
        // ????????????????????????
        uint256 totalBeanMOS = guessTotalBeanMOS[_id][_templateId];

        if(totalBeanMOS > 0){
            // ????????????????????????
            _optionTotalBeanMOS = optionTotalBeanMOS[_id][_templateId][_optionId];
            // ???????????????????????????
            oddsMOS = totalBeanMOS * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBeanMOS;
            emit PublishOption(_id,0, _optionId, oddsMOS);
        }
        
        // ETH ????????????
        // ????????????????????????
        uint256 _optionTotalBeanETH;
        // ???????????????????????????
        uint256 oddsETH;
        // ????????????????????????
        uint256 totalBeanETH = guessTotalBeanETH[_id][_templateId];

        if(totalBeanETH > 0){
            // ????????????????????????
            _optionTotalBeanETH = optionTotalBeanETH[_id][_templateId][_optionId];
            // ???????????????????????????
            oddsETH = totalBeanETH * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBeanETH;
            emit PublishOption(_id,1, _optionId, oddsETH);
        }
        
        
        // ????????????
        AgentOrder[] memory _agentOrders = agentOrders[_id][_optionId];
        
        for(uint8 i = 0; i< _agentOrders.length; i++ ){
           
           if(_agentOrders[i].currency == uint8(0)){
               // MOS ??????
                transferMOS(_agentOrders[i],totalBeanMOS,_optionTotalBeanMOS, oddsMOS);
           }else{
               // ETH ??????
               transferETH(_agentOrders[i],totalBeanETH,_optionTotalBeanETH,oddsETH);
           }
            
        }
        
        return true;
    }
    
    
    
    function transferMOS(AgentOrder _order,uint256 totalBean, uint256 _optionTotalBean,uint256 odds) internal {
      if(odds >= uint256(100)){
        // ?????????????????????
        uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
        MOS.transfer(platformAddress, platformFee);
        MOS.transfer(_order.participant, (totalBean - platformFee) * _order.bean  / _optionTotalBean);
      } else {
        // ??????????????????????????????????????????
        MOS.transfer(_order.participant, totalBean * _order.bean / _optionTotalBean);
      }
    }

    function transferETH(AgentOrder _order,uint256 totalBean, uint256 _optionTotalBean,uint256 odds) internal{
        if(odds >= uint256(100)){
          // ?????????????????????
          uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
          platformAddress.transfer(platformFee);
          _order.participant.transfer((totalBean - platformFee) * _order.bean / _optionTotalBean);
        } else {
          // ??????????????????????????????????????????
          _order.participant.transfer(totalBean * _order.bean / _optionTotalBean);
          
        }
    }

    /**
     * ????????????
     */
    function abortive
    (
        uint256 _id,
        uint256[] _templateIds
    )
    public
    onlyOwner
    returns(bool) {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id) == GuessStatus.Progress ||
        getGuessStatus(_id) == GuessStatus.Deadline, "The guess cannot abortive !!!");
        Guess storage guess = guesses[_id];
        guess.abortive = 1;
        guess.finished = 1;
        // ??????
        for( uint8 j = 0; j < _templateIds.length; j++){
            Option[] memory _options = options[_id][_templateIds[j]];
            for(uint8 i = 0; i< _options.length;i ++){
                //????????????
                AgentOrder[] memory _agentOrders = agentOrders[_id][_options[i].id];
                for(uint8 k = 0; k < _agentOrders.length; k++){
                    uint256 _bean = _agentOrders[k].bean;

                    if(_agentOrders[j].currency == uint8(0)){
                        // MOS ??????
                        MOS.transfer(_agentOrders[j].participant, _bean);
                    }else{
                        // ETH ??????
                        _agentOrders[j].participant.transfer(_bean);
                    }

                }
            }
        }
        
        emit Abortive(_id);
        return true;
    }

}

contract SscContract is GuessBaseBiz {


    constructor(address[] _operators) public {
        for(uint8 i = 0; i< _operators.length; i++) {
            operators[_operators[i]] = uint8(1);
        }
    }

    /**
     *  Recovery donated ether
     */
    function collectEtherBack(address collectorAddress) public onlyOwner {
        uint256 b = address(this).balance;
        require(b > 0);
        require(collectorAddress != 0x0);

        collectorAddress.transfer(b);
    }

    /**
    *  Recycle other ERC20 tokens
    */
    function collectOtherTokens(address tokenContract, address collectorAddress) onlyOwner public returns (bool) {
        ERC20Token t = ERC20Token(tokenContract);

        uint256 b = t.balanceOf(address(this));
        return t.transfer(collectorAddress, b);
    }

}