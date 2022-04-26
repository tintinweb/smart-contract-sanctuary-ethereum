// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.0 <0.9.0;

import "./MP10Interface.sol";


contract MP10 is MP10Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    uint constant private userLimitTimes = 3;   //每个用户参与次数限制
    uint constant private winTime = 10;         //获取本金+利息时间（单位：秒）
    uint256 constant private eachMinedCount = 1000e18; //单轮最大eth
    uint constant private rate = 107;             //利率，例：107，表示7%
    uint constant private per = 10;             //消耗比率：10ETH:1MPDD


    address admin;

    mapping(address => minter) minters;

    struct minter {
        address owner;
        uint times;
        uint256 totalBalance;
        t_b[] balances;
    }


    struct t_b {
        uint time;
        uint256 balance;
    }

    uint256 public poolBalance; 


    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowed;
    string public name;                  
    uint8 public decimals;               
    string public symbol;                 

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
        admin = msg.sender;
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    function pullSome() public payable{
        require(msg.sender != address(0), "not for you!");
        require(msg.sender == admin, "only admin can do it!");
        poolBalance += msg.value;
        require(address(this).balance == poolBalance, "pool's balance must ok!");
    }



    function safe_rm_tb(uint rm_at) private {
        for (uint i = rm_at;i < minters[msg.sender].balances.length - 1; i++) {
            minters[msg.sender].balances[i] = minters[msg.sender].balances[i + 1];
        }
        minters[msg.sender].balances.pop();
    }

    function clean_up_tb() private {
        while (minters[msg.sender].balances.length > 0) {
            minters[msg.sender].balances.pop();
        }
    }

    function findt_b(uint _timestamp) private view returns (uint, uint256) {
        require(minters[msg.sender].balances.length > 0, "prro guy!");
        for (uint i = 0; i < minters[msg.sender].balances.length; i++) {
            if (_timestamp != minters[msg.sender].balances[i].time) continue;
            return (i, minters[msg.sender].balances[i].balance);
        }
        return (0, 0);
    }

    function getMinted() public view returns (t_b[] memory) {
        return minters[msg.sender].balances;
    }

    function MineOne() public payable {
        require(msg.sender != admin, "Contract publishers cannot participate");
        require(msg.value > 0 && msg.value <= eachMinedCount, "count must > 0 and < each mine count");               
        require(minters[msg.sender].times < userLimitTimes, "mined times must less than limit times");  
        uint256 cost = msg.value * per / 100;
        require(balances[msg.sender] >= cost, "not enough balance to attent the game, poor guy!");
        transfer(admin, cost);
        poolBalance += msg.value;
        minters[msg.sender].owner = msg.sender;
        minters[msg.sender].totalBalance += msg.value;
        minters[msg.sender].balances.push(t_b(block.timestamp, msg.value));
        // minters[msg.sender].balances[block.timestamp] = msg.value;
        minters[msg.sender].times++;
        require(address(this).balance == poolBalance, "pool's balance must ok!");
    }

    function GetAvaliableBalance() public payable {
        require(minters[msg.sender].balances.length > 0, "wasted!");
        uint time = minters[msg.sender].balances[0].time;
        uint current = block.timestamp;
        require((current - time) > winTime, "not now!");
        uint256 payment = minters[msg.sender].balances[0].balance * rate / 100;
        require(payment <= poolBalance, "you are so lucky!");
        payable(msg.sender).transfer(payment);
        minters[msg.sender].totalBalance -= minters[msg.sender].balances[0].balance;
        poolBalance -= payment;
        safe_rm_tb(0);
        require(address(this).balance == poolBalance, "pool's balance must ok!");
    }


    function giveUp(uint _timestamp) public payable {
        require(msg.sender != address(0), "not for you!");
        require(minters[msg.sender].totalBalance > 0, "poor guy!");
        require(minters[msg.sender].totalBalance <= poolBalance, "lucky dog!");
        uint index;
        uint pay;
        (index, pay) = findt_b(_timestamp);
        require(pay != 0, "can not find timestamp!");
        payable(msg.sender).transfer(pay);
        safe_rm_tb(index);
        poolBalance -= pay;
        minters[msg.sender].totalBalance = 0;
        require(address(this).balance == poolBalance, "pool's balance must ok!");
    }


    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        uint256 allowances = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowances >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowances < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

}