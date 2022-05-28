/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity >=0.5.6;

interface IERC20{

    // total amount of ERC20 token
    function totalSupply() external view returns (uint); 
    
    // returns amount of ERC20 token
    function balanceOf(address account) external view returns (uint);
    
    // to transfer owner's token to the recipient
    function transfer(address recipient, uint amount) external returns (bool);
    
    // the spender allowed by the owner will spend a restricted amount with this function
    function allowance(address owner, address spender) external view returns (uint);

    //if the owner wants to allow some other spender to transfer amount on his behalf
    function approve(address spender, uint amount) external returns (bool);

    /** 
    when the owner approves another spender to transfer the amount on his behalf 
    then the owner can call this function
    **/
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20{

    /**
        implements IERC20 contract 
    **/

    uint public supply;
    address public owner;

    // storing particpants' addresses and their amounts
    mapping(address => uint) public balances;

    // owner approves a spender to spend a certain amount
    mapping(address => mapping(address => uint)) public allowances;

    string public name = "Saba";
    string public symbol = "ERC";
    uint8 public decimals = 5;

    constructor() {
        supply=10000000;
        owner= msg.sender;
        balances[owner]=supply;
    }

    function totalSupply() public view override returns (uint){
        return supply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowances[tokenOwner][spender];
    } 

    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount
    ) public virtual override returns (bool) {
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

}

contract ICO is ERC20{

    address public admin;
    address payable public participant;
    uint public tokenPrice = 0.001 ether;
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800;
    uint public coinTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.00000000001 ether;

    enum State{Start, Running, End, Stopped}
    State public icoState;

    modifier onlyAdmin{
        require(msg.sender==admin);
        _;
    }

    event Invest(address investor,uint value,uint tokens);
    
    constructor(address payable _participant){
        participant =_participant;
        admin = msg.sender;
        icoState = State.Start;
    }

    // to stop the ICO investment process
    function stopped() public onlyAdmin{
        icoState=State.Stopped;
    }
    
    // to run the investment process
    function running() public onlyAdmin{
        icoState=State.Running;
    }

    // to end the investment process
    function end() public onlyAdmin{
        icoState=State.End;
    }

    function invest() payable public returns(bool){
        
        // we will check whether the user is in running state
        require(icoState==State.Running);  

        // we will compare the the amount by sender with min investment and max inestment
        require(msg.value >= minInvestment && msg.value<=maxInvestment);  

        // total tokens a participant can have given the amount he deposited per tokenPrice
        uint tokens=msg.value/tokenPrice;

        // we will check if we reached the limit(cap) of all the amounts collected
        require(raisedAmount+msg.value<=hardCap);

        // if it's less than the cap we will add it to the raised amount
        raisedAmount+=msg.value;

        // the invester will recieve the amount
        balances[msg.sender]+=tokens;

        // the amount will deduct from admin's account
        balances[owner]-=tokens;

        // a deposit will be made
        participant.transfer(msg.value);
        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }

    function transfer(address sender, uint amount) public override returns(bool){

        // transferring can only be done when investors have invested
        require(block.timestamp > coinTradeStart);
        super.transfer(sender, amount);
        return true;
    }
    
    function transferFrom(address recipient, address sender, uint amount) public override returns(bool){

        // transferring on someone's behalf can only be done when investors have invested
        require(block.timestamp > coinTradeStart);
        super.transferFrom(sender, recipient, amount);
        return true;
    }
    
    function burn() onlyAdmin public{

        // when ICO ends all the amount from admin's account will be zero
        require(icoState == State.End);
        balances[owner] = 0;
    }
}