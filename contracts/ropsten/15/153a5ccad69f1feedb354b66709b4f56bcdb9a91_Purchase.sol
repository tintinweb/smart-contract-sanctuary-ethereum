/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity >=0.4.22 <0.7.0;

contract Purchase {

    uint public MD_KSP;
    uint public MD_LBP;
    address public SellerAddr;
    address public KSPAddr;
    enum State { Created, Locked, Inactive }
    State public state;

    mapping(string =>string)private task;
    mapping(string => uint)private price;
    mapping(string =>string)private KEY;
    mapping(string =>string)private URL;

    constructor(uint _MD_LBP,uint _MD_KSP,string id,string _task,uint _price) public payable {
        require(keccak256(id) != keccak256(""));
        require(keccak256(_task) != keccak256(""));
        require(_price != 0);
        
        task[id] = _task;
        price[id] = _price * 1 finney;
        MD_KSP=_MD_KSP * 1 finney;
        MD_LBP=_MD_LBP * 1 finney;
        KSPAddr = msg.sender;
        require(price[id] + MD_KSP== msg.value);
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

    modifier onlyLBP() {
        require(
            msg.sender == SellerAddr,
            "Only the LBP can call this."
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
    event SomeLBPAccepted();
    event ItemReceived();

    function abort()
        public
        onlyLBP
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        SellerAddr.transfer(address(this).balance);
    }

    function ()
        public
        inState(State.Created)
        condition(msg.value == (MD_LBP))
        payable
    {
        emit SomeLBPAccepted();
        SellerAddr = msg.sender;
        state = State.Locked;
    }

    function getTaskPricePair(string id)view public returns(string,uint){
        return (task[id],price[id]);
    }

    function SendMsg(string id,string _URL,string _KEY) onlyLBP public{
        URL[id]=_URL;
        KEY[id]=_KEY;
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
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;
        SellerAddr.transfer(price[id]+MD_LBP);
        KSPAddr.transfer(MD_KSP);
    }
}