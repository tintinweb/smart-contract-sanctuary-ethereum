/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

  
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
  
    function totalSupply() external view returns (uint256);

 
    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;



contract Staking_Pool is Ownable {

    bool public paused = false;

    uint256 private token_decimal = 1 * 10 ** 18;

    uint256 public _Daily_Reward;
    uint256 public _30Days_Reward;
    uint256 public _60Days_Reward; 
    uint256 public _deduction;
    uint256 public perHourReward;    
    bool public isRewardset = false;

    struct dataBase {
        address person;
        uint256 duration;
        uint256 stake_time;
        uint256 amount;
        uint256 id;  // 1 = daily , 2 = 30 days , 3 = 60 days
    }

    dataBase[] public _userdata;

    mapping(address=>uint256) public user_rtime;

    IERC20 private Stake_Token;
    IERC20 private Reward_Token;

    function Token_Modifier(IERC20 _Stake, IERC20 _Reward) public onlyOwner{
        Stake_Token = _Stake;
        Reward_Token = _Reward;
    }

    function set_reward(uint _daily, uint _30Days, uint _60Days, uint _per_deduction, uint _perHour) public onlyOwner {
        isRewardset = true; 
        _Daily_Reward = _daily * token_decimal;
        _30Days_Reward = _30Days * token_decimal;
        _60Days_Reward = _60Days * token_decimal;
        _deduction = _per_deduction;
        perHourReward = _perHour * token_decimal;
    }

    function Stake(uint _pid,uint256 _amount) public { //1=daily, 2=30days, 3=60days

        require(isRewardset,"Reward not decided yet!!");
        
        address _person = msg.sender;
        require(!paused,"Staking Pool is Paused!!");
        require(user_rtime[_person] == 0, "Already Invested!!");

        require(Stake_Token.allowance(msg.sender,address(this)) >= _amount,"Check your Allowance");
        Stake_Token.transferFrom(msg.sender,address(this),_amount);
        
        if(_pid == 1) {           
            uint256 time = block.timestamp + 1 minutes;   //make it to 1 days
            user_rtime[_person] = time;

            dataBase memory newdata = dataBase(_person,time,block.timestamp,_amount,_pid);  /// order must be same
           _userdata.push(newdata);   
        }

        if(_pid == 2) {
            uint256 time = block.timestamp + 3 minutes; //30 days;
            user_rtime[_person] = time;

            dataBase memory newdata = dataBase(_person,time,block.timestamp,_amount,_pid);  /// order must be same
           _userdata.push(newdata);   
        }

        if(_pid == 3) {
            uint256 time = block.timestamp +  5 minutes; //60 days;
            user_rtime[_person] = time;

            dataBase memory newdata = dataBase(_person,time,block.timestamp,_amount,_pid);  /// order must be same
           _userdata.push(newdata);   
        }
    }


    function get_Reward() public {

        require(!paused,"Staking Pool is Paused!!");

        for(uint i = 0 ; i < _userdata.length ; i++) {
            
            if(_userdata[i].person == msg.sender){

                if(_userdata[i].id == 1) {  //daily
                    require(block.timestamp >= _userdata[i].duration,"You can't get reward Now!");
                    
                    Reward_Token.transfer(msg.sender,_Daily_Reward);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }
                if(_userdata[i].id == 2) { //30 days
                    require(block.timestamp >= _userdata[i].duration,"You can't get reward Now!");
                    
                    Reward_Token.transfer(msg.sender,_30Days_Reward);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }
                if(_userdata[i].id == 3) { //60 days
                    require(block.timestamp >= _userdata[i].duration,"You can't get reward Now!");
                    
                    Reward_Token.transfer(msg.sender,_60Days_Reward);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }
            }
        }
    }

    function check_index() public view returns (uint index){
        for(uint i = 0 ; i < _userdata.length ; i++) {
            if(_userdata[i].person == msg.sender){
                return i;
            }
        }
    }


    function Universal_Reward() public {

        require(!paused,"Staking Pool is Paused!!");

        for(uint i = 0 ; i < _userdata.length ; i++) {
            
            if(_userdata[i].person == msg.sender){

                if(_userdata[i].id == 1) {  //daily
                    
                    uint deduction =  ( _Daily_Reward * _deduction ) / 100;  

                    Reward_Token.transfer(msg.sender,deduction);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }

                if(_userdata[i].id == 2) {  //30daily

                    uint deduction =  ( _30Days_Reward * _deduction ) / 100;   

                    Reward_Token.transfer(msg.sender,deduction);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }

                if(_userdata[i].id == 3) { //60 days

                    uint deduction =  ( _60Days_Reward * _deduction ) / 100;   
                    
                    Reward_Token.transfer(msg.sender,deduction);
                    Stake_Token.transfer(msg.sender,_userdata[i].amount);
                    
                    remove_data(i);
                    user_rtime[msg.sender] = 0;
                    break;
                }

            }
        }
    }

    function Open_Reward() public {
        
        for(uint i = 0 ; i < _userdata.length ; i++) {
            
            if(_userdata[i].person == msg.sender){

                uint256 usertime = _userdata[i].stake_time;

                uint _now = block.timestamp - usertime;

                uint256 newtime = _now / 60;        // 3600 <- 1 hour

                require(newtime != 0, "Wait for atleast 1 hour!!");

                uint tReward = newtime * perHourReward;

                Reward_Token.transfer(msg.sender,tReward);
                Stake_Token.transfer(msg.sender,_userdata[i].amount);

                remove_data(i);
                user_rtime[msg.sender] = 0;
                break;
            }
        }

    }

    function remove_data(uint _pid) private {
        _userdata[_pid].person = address(0);
        _userdata[_pid].duration = 0;
        _userdata[_pid].amount = 0;
        _userdata[_pid].id = 0;
    }

    function Check_Allowance() public view returns (uint) {
        return Stake_Token.allowance(msg.sender,address(this));
    }

    function Pool_Balance(uint _pid) public view returns (uint) {
        if(_pid == 1) { return Stake_Token.balanceOf(address(this)); }
        if(_pid == 2) { return Reward_Token.balanceOf(address(this)); }
        else { revert("Wrong Option!!"); }
    }

    function Token_Balance(uint _pid) public view returns (uint) {
        if(_pid == 1) { return Stake_Token.balanceOf(msg.sender); }
        if(_pid == 2) { return Reward_Token.balanceOf(msg.sender); }
        else { revert("Wrong Option!!"); }
    }

    function EmergencyPause() public onlyOwner {
        Stake_Token.transfer(msg.sender,address(this).balance);
        Reward_Token.transfer(msg.sender,address(this).balance);
    }

    function Pause_Pool(bool _bool) public onlyOwner {
        paused = _bool;
    }

}