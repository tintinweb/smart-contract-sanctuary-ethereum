/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;



contract utake {

    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    uint _maxSupply;
    address _admin;
    uint month;
    uint _reward3;
    uint _reward6;
    uint _reward12;
    uint minimumTokenDeposit;
    bool public adminAllow;

    struct StakeData {
        uint withdrow_date;
        uint deposit_data;
        uint amount;
        uint reward;
        uint arrayIndex;
        address _address;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => StakeData[]) depositHistory;

    mapping(address => mapping(uint => StakeData)) public deposits;
    mapping(address => uint[]) _avaibleWithdraws;

   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event ReduceApproved(address indexed _owner, address indexed _spender, uint256 _tokens);
    event AdminChanged(address indexed _from, address indexed _to);
    event NewDeposit(address indexed _account, uint _amount);
    event NewWithdraw(address indexed _account, uint _amount);

    constructor() {
        _name = "utake";
        _symbol = "UTE";
        _decimals = 16;
        _maxSupply = 100000000 * 10** _decimals;
        _totalSupply = 80000000 * 10** _decimals;
        minimumTokenDeposit = 10 ** _decimals;
        _admin = msg.sender;
        balances[_admin] = _totalSupply;
        adminAllow = false;
        month = 2592000;
        _reward3 = 25;
        _reward6 = 30;
        _reward12 = 35;
    }
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin!");
        _;
    }



    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function admin() public view returns(address) {
        return _admin;
    }

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function maxSupply() public view returns(uint) {
        return _maxSupply;
    }
    
    function balanceOf(address _tokenOwner) public view returns(uint) {
        return balances[_tokenOwner];
    }

    function allowance(address _tokenOwner, address _spender) public view returns(uint) {
        return allowed[_tokenOwner][_spender];
    }

    function reward() external view returns(uint, uint, uint) {
        return (_reward3, _reward6, _reward12);
    }


    function getAvaibleWithdraws() external view returns(uint[] memory) {
        return _avaibleWithdraws[msg.sender];
    }


    function getAvaibleWithdrawsAdmin(address _user) onlyAdmin external view returns(uint[] memory) {
        return _avaibleWithdraws[_user];
    }

    function getMinimumTokenDeposit() external view returns(uint) {
        return minimumTokenDeposit;
    }
    // 

    function getDepositHistory(address _user) onlyAdmin external view returns(StakeData[] memory) {
        return depositHistory[_user];
    }
    


    function transfer(address _to, uint _tokens) public returns (bool) {
        require(adminAllow || _to == _admin || msg.sender == _admin, "You are not allowed to transfer tokens!");
        require(balances[msg.sender] >= _tokens, "Not enough funds!");
        require(msg.sender != address(0), "Wrong address!");
        balances[msg.sender] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint _tokens) external returns (bool) {
        require(msg.sender != address(0), "Wrong address!");
        allowed[msg.sender][_spender] += _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function reduceAllovance(address _spender, uint _tokens) external returns(bool) {
        require(msg.sender != address(0), "Wrong address!");
        allowed[msg.sender][_spender] -= _tokens;
        emit ReduceApproved(msg.sender, _spender, _tokens);
        return true;
    }

    function transferFrom(address _from, address _to, uint _tokens) public returns (bool) {
        require(msg.sender != address(0), "Wrong address!");
        require(balances[_from] >= _tokens, "Not enough funds!");
        require(allowed[_from][msg.sender] >= _tokens, "Too low allowance!");
        allowed[_from][msg.sender] -= _tokens;
        balances[_from] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }


    function deposit(uint _amount, uint _amountMouth) external returns(bool) {
        require(msg.sender != address(0), "Wrong address!");
        require(_amountMouth == 3 || _amountMouth == 6 || _amountMouth == 12, "Wrong month count");

        require(balances[msg.sender] >= _amount, "Not enough funds!");
        require(_amount >= minimumTokenDeposit, "Not enough funds!");

        uint reward_ = calcReward(_amount, _amountMouth);
        require(_totalSupply + reward_ <= _maxSupply, "Max supply is reached!");
        _totalSupply += reward_;
        balances[msg.sender] -= _amount;
        balances[address(this)] += (_amount + reward_);
        allowed[address(this)][msg.sender] += (_amount + reward_);

        _avaibleWithdraws[msg.sender].push(block.timestamp);
        StakeData storage a = deposits[msg.sender][block.timestamp];

        a.deposit_data = block.timestamp;
        a.withdrow_date = block.timestamp + (month * _amountMouth);
        a.amount = _amount;
        a.reward = reward_;
        a._address = msg.sender;
        a.arrayIndex = _avaibleWithdraws[msg.sender].length-1;
        depositHistory[msg.sender].push(a);
        emit NewDeposit(msg.sender, _amount);
        return true;
    } 

    function withdraw(uint _timestamp) external returns(bool) {
        require(msg.sender != address(0), "Wrong address!");
        StakeData storage a = deposits[msg.sender][_timestamp];
        require(msg.sender == a._address, "You can not withdraw from this account!");

        if(a.withdrow_date <= block.timestamp) {
            if (_avaibleWithdraws[msg.sender].length == 1) {
                _avaibleWithdraws[msg.sender].pop();
            }
            else{
                if (_avaibleWithdraws[msg.sender][a.arrayIndex] != _avaibleWithdraws[msg.sender][_avaibleWithdraws[msg.sender].length-1]){
                    StakeData storage a2 = deposits[msg.sender][_avaibleWithdraws[msg.sender][_avaibleWithdraws[msg.sender].length-1]];
                    a2.arrayIndex = a.arrayIndex;
                    _avaibleWithdraws[msg.sender][a.arrayIndex] = _avaibleWithdraws[msg.sender][_avaibleWithdraws[msg.sender].length-1];
                    _avaibleWithdraws[msg.sender].pop();

                }else{
                    _avaibleWithdraws[msg.sender].pop();
                }
            }
            transferFrom(address(this), msg.sender, a.amount + a.reward);
            emit NewWithdraw(msg.sender, a.amount + a.reward);
            return true;
        }
        else {
            revert();
        }
    }

    function multiple_transfer(address[] calldata _addresses, uint[] calldata _amounts, uint _totAmount) onlyAdmin external returns(bool){
        require(balances[msg.sender] >= _totAmount, "Not enoph founds to to the transfers");
        uint indx = _addresses.length;
        for(uint i = 0; i < indx; i++){
            transfer(_addresses[i], _amounts[i]);
        }
        return true;
    }

    function changeAdminAllow(bool _allow) external onlyAdmin returns(bool){
        require(_allow != adminAllow, "Is alredy what you asked for!");
        adminAllow = _allow;
        return true;
    }

    function calcReward(uint _amount, uint _amountMouth) internal view returns(uint reward_) {
        if (_amountMouth == 12) {
            reward_ = ((_amount / 10000) * _reward12) * _amountMouth;
        }
        else if (_amountMouth == 6) {
            reward_ = ((_amount / 10000) * _reward6) * _amountMouth;
        }
        else {
            reward_ = ((_amount / 10000) * _reward3) * _amountMouth;
        }
    } 

    function setMinimumTokenDeposit(uint _token) onlyAdmin public {
        minimumTokenDeposit = _token;
    }

    function mint(uint _value, address _to) onlyAdmin public {
        require(msg.sender != address(0), "Wrong address!");
        require(_to != address(0), "Wrong address!");
        require(_totalSupply + _value <= _maxSupply, "Minted amount is higher then the max supply");

        balances[_to] += _value;
        _totalSupply += _value;
    }

    function burn(uint _value) onlyAdmin public {
        require(msg.sender != address(0), "Wrong address!");
        require(balances[msg.sender] >= _value, "Not enough funds!");
        
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        
    }


    function renonceAdminship() external onlyAdmin returns(bool) {
        _admin = address(0);
        emit AdminChanged(_admin, address(0));
        return true;
    }

    function transferAdminship(address _to) external onlyAdmin returns(bool) {
        _admin = _to;
        emit AdminChanged(_admin, _to);
        return true;
    }

    function setReward(uint _amountMouth, uint _r) external onlyAdmin returns(bool) {
        require(_amountMouth == 3 || _amountMouth == 6 || _amountMouth == 12, "Wrong month count");
        require(_r >= 0 && _r <= 10000, "Basis point owerflow");
        if (_amountMouth == 12) {
            _reward12 = _r;
        }
        else if (_amountMouth == 6) {
            _reward6 = _r;
        }
        else {
           _reward3 = _r; 
        }
        return true;
    }
}