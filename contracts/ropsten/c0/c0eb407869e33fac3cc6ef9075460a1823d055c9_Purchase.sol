/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity >=0.4.22 <0.7.0;

contract Purchase {

    uint public MD_KSP;
    uint public MD_LKS;
    address public SellerAddr;
    address public KSPAddr;
    uint private effmax;
    uint public eff_currentLKS;
    uint public time_start;
    uint private time_duration;
    uint public time_end;
    uint public time_taskLast;
    uint private time_level;
    uint private num_LKSs;
    uint private eff_level;

    enum State { Created, Locked, Inactive }
    State public state;

    mapping(string =>string)private task;
    mapping(string => uint)private price;
    mapping(string =>string)private KEY;
    mapping(string =>string)private URL;

    constructor(uint _MD_LKS,uint _MD_KSP,string id,string _task,uint _price,
                uint _effmax,uint _time_duration,uint _num_LKSs) public payable {
        require(keccak256(id) != keccak256(""));
        require(keccak256(_task) != keccak256(""));
        require(_price != 0);
        require(_effmax != 0);
        effmax=_effmax;
        num_LKSs=_num_LKSs;
        time_duration=_time_duration;
        time_level=time_duration/num_LKSs;
        task[id] = _task;
        price[id] = _price * 1 finney;
        MD_KSP=_MD_KSP * 1 finney;
        MD_LKS=_MD_LKS * 1 finney;
        KSPAddr = msg.sender;
        require(effmax*price[id] + MD_KSP== msg.value);
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyKSP() {
        require(
            msg.sender == KSPAddr,
            "Only the KSP can call this."
        );
        _;
    }

    modifier onlyLKS() {
        require(
            msg.sender == SellerAddr,
            "Only the LKS can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }

    event Aborted();
    event SomeLKSAccepted();
    event ItemReceived();

    function abort()
        public
        onlyLKS
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        SellerAddr.transfer(address(this).balance);
    }

    function getTaskPricePair(string id)view public returns(string,uint){
        return (task[id],price[id]);
    }

    function SendMsg(string id,string _URL,string _KEY) onlyLKS public{
        URL[id]=_URL;
        KEY[id]=_KEY;
        time_end=now;
        time_taskLast=time_end-time_start;
        eff_level=(time_taskLast+time_level-1)/time_level;
        eff_currentLKS=effmax-eff_level+1;
    }

    function SelCont() public 
        inState(State.Created) 
        condition(msg.value == (MD_LKS))
        payable{
        time_start=now;
        emit SomeLKSAccepted();
        SellerAddr = msg.sender;
        state = State.Locked;
    }

    function GetMsg(string id)view public returns(string,string){
        return (URL[id],KEY[id]);
    }

    function ConfTrade(string id)
        public
        onlyKSP
        inState(State.Locked)
    {
        emit ItemReceived();
        state = State.Inactive;
        SellerAddr.transfer(eff_currentLKS*price[id]+MD_LKS);
        KSPAddr.transfer((effmax-eff_currentLKS)*price[id]+MD_KSP);
    }
}