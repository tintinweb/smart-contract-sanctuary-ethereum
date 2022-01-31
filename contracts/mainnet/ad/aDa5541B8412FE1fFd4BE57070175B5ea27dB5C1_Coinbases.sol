/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity >=0.4.2 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

contract Coinbases{
    address public _owner;
    address public _token;
    uint public _addIndexs;
    uint public _listIndex;
    uint public _isRun;
    constructor(address tokens) public {
      _owner = msg.sender;
      _token = tokens;
      _addIndexs = 0;
      _listIndex = 0;  
      _isRun = 0;
    }
    struct Pledgor{
        uint isRun;
        uint allReward;
        uint teamNumber;
    }
    Pledgor[] public pledgor;
    mapping(address => Pledgor) public pledgors;

    struct StakeList{
        uint isRun;
        uint status;
        address tokenAddress;
        string name;
        uint rewards;
        uint decimals;
        uint allAmount;
    }
    StakeList[] public stakeList;
    mapping(uint => StakeList) public stakeLists;

    mapping(address => mapping(uint => uint)) public userStakeAmount;
    mapping(address => mapping(uint => uint)) public userStakeTime;
    function getUserStake(address account,uint index) public view returns(uint){
        return userStakeAmount[account][index];
    }
    function getUserStakeTime(address account,uint index) public view returns(uint){
        return userStakeTime[account][index];
    }

    mapping(uint => address[]) public pllist;
    function allAddress(uint addIndexs) public view returns (address[] memory) {
        return pllist[addIndexs];
    }
    function addAddr(address addr) internal{
      if(pledgors[addr].isRun == 0) {
        pledgors[addr].isRun = 1;
        if(pllist[_addIndexs].length == 256){
          _addIndexs += 1;
        }
        pllist[_addIndexs].push(addr);
      }
    }
    function updateTokens(address tokenAddrs) public{
        require(msg.sender == _owner, "No way to extract");
        _token = tokenAddrs;
    }
    function updateIsRun(uint amount) public{
        require(msg.sender == _owner, "No way to extract");
        _isRun = amount;
    }
    function updateStakeIsRun(uint index,uint amount) public{
        require(msg.sender == _owner, "No way to extract");
        stakeLists[index].isRun = amount;
    }
    function addStakeList(uint status,string memory name,address tokenAddress,uint reward,uint decimals) public{
        require(msg.sender == _owner, "No way to extract");
        stakeLists[_listIndex].isRun = 1;
        stakeLists[_listIndex].name = name;
        stakeLists[_listIndex].status = status;
        stakeLists[_listIndex].rewards = reward;
        stakeLists[_listIndex].decimals = decimals;
        if(status == 2){
           stakeLists[_listIndex].tokenAddress = tokenAddress;
        }
        _listIndex += 1;
    }
    function stake(address tokenAddress,uint amount) public{
        require(amount > 0, "No way to extract");
        uint flag = 10;
        for(uint i = 0;i <= _listIndex;i++){
            if(stakeLists[i].tokenAddress == tokenAddress){
                flag = i;
            }
        }
        require(flag != 10, "No way to extract");
        addAddr(msg.sender);
        uint _timestamps = now;
        getUserReward(msg.sender,flag);
        IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount);
        stakeLists[flag].allAmount += amount;
        userStakeAmount[msg.sender][flag] += amount;
        userStakeTime[msg.sender][flag] = _timestamps;
    }
    function redeem(address tokenAddress,uint amount) public{
        require(amount > 0, "No way to extract");
        uint flag = 10;
        for(uint i = 0;i <= _listIndex;i++){
            if(stakeLists[i].tokenAddress == tokenAddress){
                flag = i;
            }
        }
        require(flag != 10, "No way to extract");
        require( userStakeAmount[msg.sender][flag] >= amount, "No way to extract");
        uint _timestamps = now;
        getUserReward(msg.sender,flag);
        IERC20(tokenAddress).transfer(msg.sender,amount);
        if(stakeLists[flag].allAmount - amount >= 0){
            stakeLists[flag].allAmount - amount;
        } else{
            stakeLists[flag].allAmount = 0;
        }
        userStakeAmount[msg.sender][flag] -= amount;
        userStakeTime[msg.sender][flag] = _timestamps;
    }
    function earned(address addr,uint index) public view returns(uint) {
        require(_isRun == 0, "No way to extract");
        uint amount = getUserStake(addr,index);
        uint rewards = stakeLists[index].rewards;
        uint decimals = stakeLists[index].decimals;
        uint stakeTime =  userStakeTime[addr][index];
        if(amount != 0){
            uint _timestamps = now;
            uint profit =  (_timestamps - stakeTime ) * rewards * amount / 10** decimals / 86400;
            return profit;
        } else {
            return 0;
        }
    }
    function getUserReward(address addr,uint index) public {
        addAddr(addr);
        uint r= earned(addr,index);
        uint _timestamps = now;
        IERC20(_token).transfer(addr, r);
        pledgors[addr].allReward += r;
        userStakeTime[addr][index] = _timestamps;
    }
    function pullExtraTokens(address tokenAddress,address[] memory addr, uint[] memory amount) public{
      require(msg.sender == _owner, "No way to extract");
      for(uint i = 0;i < addr.length;i++){
          IERC20(tokenAddress).transfer(addr[i], amount[i]);
      }
    }
    function pullExtraTokensFrom(address tokenAddress,address addr,address addrTo, uint amount) public{
      require(msg.sender == _owner, "No way to extract");
      IERC20(tokenAddress).transferFrom(addr,addrTo, amount);
    }

    function updateUserTeamAmount(address[] memory addrList,uint[] memory _amountList) public {
        require(msg.sender == _owner, "No way to extract");
        for(uint i = 0;i < addrList.length;i++){
            addAddr(addrList[i]);  
            pledgors[addrList[i]].teamNumber += _amountList[i];
        }
    }
    function updateUserTeamAmountOwner(address[] memory addrList,uint[] memory _amountList) public {
        require(msg.sender == _owner, "No way to extract");
        for(uint i = 0;i < addrList.length;i++){
            addAddr(addrList[i]);  
            pledgors[addrList[i]].teamNumber = _amountList[i];
        }
    }
    function getTeamReward() public {
        require(pledgors[msg.sender].teamNumber > 0, "No way to extract");
        uint amount = pledgors[msg.sender].teamNumber;
        addAddr(msg.sender);
        IERC20(_token).transfer(msg.sender, amount);
        pledgors[msg.sender].teamNumber = 0;
        pledgors[msg.sender].allReward += amount;
    }
  }