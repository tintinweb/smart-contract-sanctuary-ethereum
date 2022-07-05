// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC20 {
  
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20 {
    function redeembalance(uint256 amount) external;
    function balances(address _addr) external view returns(uint256);
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract Ownable {
    
    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract ROAD_Staking is Ownable {


    //////////////////////////////////////
    
    using SafeMath for uint256;
    IERC20 public Token;
    IERC20 public LpToken;
    address public NFTcontract;

    //////////////////////////////////////

    modifier onlyNFTContract {
        require(msg.sender == NFTcontract,"Only Call By The NFT Contract");
        _;
    }

    
    constructor(IERC20 _Token,IERC20 _LpToken)
    {
        Token = _Token;
        LpToken = _LpToken;   
    }

    /*                           STRUCTURES                                */

    struct users {

    uint256 Tamount;
    uint256 Deposit_time;
    uint256 withdrawnToken;
    uint256 redeemedRP;
    uint256 mystakedTokens;
    }

    struct usersLP { 

    uint256 Tamount;
    uint256 Deposit_time;
    uint256 withdrawnToken;
    uint256 redeemedRP;

    }

    /*                           MAPPING                                */

    mapping(address => users) public User;
    mapping(address => usersLP) public UserLP;
    mapping (address => uint256) public _balances;

    uint256 public totalStakedTokens;
    uint256 public time = 30 seconds;
    uint256 public LPlocktime = 1 hours;
    uint256 public ROAD_Perecent = 1000000000000000000;
    uint256 public Lppercent = 444444444444000000000;
    uint256 public currentRP;

    // uint256 public maxRPToken=400000000000000000000000000;

    function setTime(uint256 _epoch) public {
    time = _epoch;
    }

    function addStakedTokens(uint256 _amount) public {
        User[msg.sender].mystakedTokens = _amount;
        totalStakedTokens += _amount;
    }
    function removeStakedTokens(uint256 _amount) public {
        User[msg.sender].mystakedTokens -= _amount;
        totalStakedTokens -= _amount;
    }

    function Stake( uint256 _amount) external {   
     
    require(User[msg.sender].Deposit_time == 0," User Already Exists " );
    Token.transferFrom(msg.sender,address(this),_amount);
    User[msg.sender].Tamount += _amount;
    User[msg.sender].Deposit_time = block.timestamp;
    User[msg.sender].redeemedRP=0;
    addStakedTokens(_amount);
    }
  
    function RPcalculator(address addr) public view returns(uint256){

    // require(currentRP<=maxRPToken," Max ROAD Points Limit Exceeded! ");
    uint256 remainingenergy;

    if(User[addr].Deposit_time!=0) {
       uint256 reward = ((block.timestamp.sub(User[addr].Deposit_time)).div(time)).mul(User[addr].Tamount.mul(ROAD_Perecent));
       remainingenergy= (reward.div(1E18)).sub((User[addr].redeemedRP));
       }
       return remainingenergy;
    }


    function redeem() public {

    uint point=RPcalculator(msg.sender);
    currentRP+=point;
    User[msg.sender].redeemedRP +=point ;
    _balances[msg.sender]+=point ;
    
    }
    
    function withdrawtoken () public {

    require(User[msg.sender].Tamount > 0 ,"No Staking Found!" );
    redeem();

    User[msg.sender].withdrawnToken = User[msg.sender].Tamount;
    Token.transfer(msg.sender,User[msg.sender].Tamount); 
    User[msg.sender].Tamount = 0;
    User[msg.sender].Deposit_time = 0 ;
    removeStakedTokens(User[msg.sender].mystakedTokens);
    }
    
    function AddNFTContractAddress(address _add) external onlyOwner {
    NFTcontract=_add;
    }

    function balances(address _addr) external view returns(uint256) {
    return _balances[_addr];
    }


    function redeembalance(uint256 amount) external onlyNFTContract {

    require( _balances[tx.origin]>0," No Energy Found! ");
    _balances[tx.origin]-=amount;
    currentRP-=amount;
        
    }


    ///////            STAKE LP            ///////


    function StakeforLP( uint256 _amount) external {   
     
    require(UserLP[msg.sender].Deposit_time == 0," User Already Exists " );
    LpToken.transferFrom(msg.sender,address(this),_amount);
    UserLP[msg.sender].Tamount += _amount;
    UserLP[msg.sender].Deposit_time = block.timestamp;
    UserLP[msg.sender].redeemedRP=0;
    
    }



    function RPcalculatorforLP(address addr) public view returns(uint256) {
    // require(currentRP<=maxRPToken," Max ROAD Points Limit Exceeded! ");
    uint256 remainingenergy;

    if(UserLP[addr].Deposit_time!=0) {
        uint256 reward = ((block.timestamp.sub(UserLP[addr].Deposit_time)).div(time)).mul((UserLP[addr].Tamount.mul(Lppercent)));
        remainingenergy= (reward.div(1E18)).sub(UserLP[addr].redeemedRP);    
    }
    return remainingenergy;
    }
    
    function redeemforLp() public {

    uint point=RPcalculatorforLP(msg.sender);
    currentRP+=point;
    UserLP[msg.sender].redeemedRP +=point ;
    _balances[msg.sender]+=point ;

    }


    function withdrawLPtoken ()  public  {
        
    require(UserLP[msg.sender].Tamount > 0 ," No Staking Found! " );
    require(block.timestamp>=(UserLP[msg.sender].Deposit_time.add(LPlocktime))," UnLock Time Not Reached");
    redeemforLp();
    UserLP[msg.sender].withdrawnToken = UserLP[msg.sender].Tamount;
    LpToken.transfer(msg.sender,UserLP[msg.sender].Tamount); 
    UserLP[msg.sender].Tamount = 0;
    UserLP[msg.sender].Deposit_time = 0 ;

    }

    function setLPlocktime(uint256 _LPlocktime) external onlyOwner {
    
    LPlocktime=_LPlocktime;

    }


}

//  TOKEN:      0x52db35aC6393aEc5B8572cfde96B38DA4f7D149c
// LP-TOKEN:    0xd52E57a923D42A19Ea0e10C01b29B7509c702E3e