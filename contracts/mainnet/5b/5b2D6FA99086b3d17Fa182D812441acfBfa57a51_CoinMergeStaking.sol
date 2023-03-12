/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface ERC20 {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract CoinMergeStaking {
    event Stake(address Stakee, address Token, uint256 Amount);
    event Fund(address Token, uint256 Amount);
    event Restake(address Stake, address Token);
    event Withdraw(address Stakee, address Token, uint256 Amount);
    event UpdateRate(address Token, uint256 PayoutAmount, uint256 MinimumStake, uint256 Interval);
    event NewTokenRequest(address Token);

    mapping(address => bool) m_Adjustable;
    mapping(address => uint256) m_Rates;
    mapping(address => uint256) m_Denoms;
    mapping(address => uint256) m_Intervals;
    mapping(address => uint256) m_Pools;
    mapping(address => address) m_Admins;
    mapping(address => uint256) m_Fees;
    mapping(address => uint256) m_FeeBalances;
    mapping(address => mapping(address => uint256)) m_Balances;
    mapping(address => mapping(address => uint256)) m_Deposits;
    mapping(address => mapping(address => uint256)) m_Timestamps;
    mapping(address => mapping(address => uint256)) m_Earnings;
    mapping(address => mapping(address => uint256[])) m_ItemizedEarnings;
    mapping(address => mapping(address => uint256)) m_Requests;

    bool m_Locked = false;
    address m_Owner;
    uint256 m_NativeFee;

    modifier Lock {
        m_Locked = true;
        _;
        m_Locked = false;
    }
    constructor(){
        m_Owner = msg.sender;
    }
    function viewStakeBalance(address _token) external view returns (uint256) {
        return m_Balances[msg.sender][_token];
    }
    function viewStakeEarnings(address _token) external view returns (uint256) {
        uint256 _amount = _getCurrentEarnings(msg.sender, _token);
        return m_Earnings[msg.sender][_token] + _amount;
    }
    function viewStakingTimestamp(address _token) external view returns (uint256) {
        return m_Timestamps[msg.sender][_token];
    }
    function payoutInterval(address _token) external view returns (uint256) {
        return m_Intervals[_token];
    }
    function minimumStake(address _token) external view returns (uint256) {
        return m_Denoms[_token];
    }
    function viewPoolBalance(address _token) external view returns (uint256) {
        return m_Pools[_token];
    }
    function viewRate(address _token) external view returns (uint256, uint256) {
        uint8 _decimals = ERC20(_token).decimals();
        return (m_Rates[_token]/(10**_decimals), m_Denoms[_token]/(10**_decimals));
    }
    function intervalsElapsed(address _token) external view returns (uint256) {
        if(m_Balances[msg.sender][_token] == 0)
            return 0;
        uint256 _seconds = block.timestamp - m_Timestamps[msg.sender][_token];
        if(_seconds < m_Intervals[_token])
            return 0;
        return _seconds / m_Intervals[_token];
    }
    function setNativeFee(uint256 _value) external {
        require(msg.sender == m_Owner);
        m_NativeFee = _value;
    }
    function createTokenRequest(address _token) external payable {
        m_Requests[_token][msg.sender] += msg.value;
        require(m_Requests[_token][msg.sender] >= m_NativeFee, "Fee requirement not met"); // requirement comes second to support fee changes
        emit NewTokenRequest(_token);
    }
    function approveTokenAdminWithNative(address _token, address _admin) external {
        require(msg.sender == m_Owner);
        require(m_Requests[_token][_admin] >= m_NativeFee, "Fee requirement not met");
        uint256 _remainder = m_Requests[_token][_admin] - m_NativeFee;
        if(_remainder > 0)
            payable(_admin).transfer(_remainder);
        payable(m_Owner).transfer(m_Requests[_token][_admin]);
        m_Admins[_token] = _admin;
        m_Adjustable[_token] = true;
    }
    /*
    *!!! _fee later divides the deposit amount !!!
    *eg: 100 = 1%
    *eg: 50 = 2%
    *eg: 20 = 5%
    */
    function approveTokenAdminWithTokenFee(address _token, address _admin, uint256 _fee) external {
        require(msg.sender == m_Owner);
        m_Fees[_token] = _fee;
        m_Admins[_token] = _admin;
        m_Adjustable[_token] = true;
    }
    function setTokenAdminManual(address _token, address _admin) external {
        require(msg.sender == m_Owner);
        m_Admins[_token] = _admin;
        m_Adjustable[_token] = true;
    }
    function allowRateAdjustment(address _token) external {
        require(msg.sender == m_Owner);
        m_Adjustable[_token] = true;
    }
    /*
    *!!!Do no multiply decimals into the rate or denom!!!
    *Interval must be based in seconds
    *eg: 1 day = 86400
    *example: 0x0, 5, 100, 86400 = 5 tokens per 100 staked paid out each day
    */
    function setRate(address _token, uint256 _rate, uint256 _denom, uint256 _interval) external {
        require(msg.sender == m_Admins[_token]);
        require(m_Adjustable[_token]);
        require(_interval > 0);
        uint8 _decimals = ERC20(_token).decimals();
        _denom = _denom * (10 ** _decimals);
        _rate = _rate * (10 ** _decimals);
        m_Rates[_token] = _rate;
        m_Denoms[_token] = _denom;
        m_Intervals[_token] = _interval;
        m_Adjustable[_token] = false;
        emit UpdateRate(_token, _rate, _denom, _interval);
    }
    /*
    *!!!Ensure _amount is a product of decimals!!!
    *eg: 1,000,000 of a token with 9 decimals is 1,000,000,000,000,000
    *Tokens deposited with this function CANNOT be reclaimed
    */
    function depositTokensToPool(address _token, uint256 _amount) external {
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if(m_Fees[_token] > 0){
            uint256 _fee = _amount / m_Fees[_token];
            _amount -= _fee;
            ERC20(_token).transfer(m_Owner, _fee);
        }
        m_Pools[_token] += _amount;
        emit Fund(_token, _amount);
    }       
    /*
    *!!!Ensure _amount is a product of decimals!!!
    *eg: 1,000,000 of a token with 9 decimals is 1,000,000,000,000,000
    *Any time tokens are added stake is calculated, added, and timestamp reset
    *No earnings are awarded if it has been less than 24 hours since previous deposit
    */  
    function depositTokensToStake(address _token, uint256 _amount) external returns (uint256) {     
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        m_Deposits[msg.sender][_token] += _amount;
        uint256 _previousEarnings = _claimDividends(msg.sender, _token);
        _amount += _previousEarnings;
        m_Earnings[msg.sender][_token] += _previousEarnings;
        m_Balances[msg.sender][_token] += _amount;
        if(_previousEarnings == 0)
            m_Timestamps[msg.sender][_token] = block.timestamp;
        emit Stake(msg.sender, _token, _amount);
        return _previousEarnings;
    }
    function reStake(address _token) external returns (uint256) {
        uint256 _amount = _claimDividends(msg.sender, _token);
        m_Earnings[msg.sender][_token] += _amount;
        m_Balances[msg.sender][_token] += _amount;
        emit Restake(msg.sender, _token);
        return _amount;
    }
    function withdraw(address _token) external returns (uint256) {
        require(!m_Locked, "Recursion Prevented");
        uint256 _amount = m_Balances[msg.sender][_token];
        require(_amount > 0, "No tokens to withdraw");
        uint256 _earnings = _claimDividends(msg.sender, _token);
        m_Earnings[msg.sender][_token] += _earnings;
        m_Deposits[msg.sender][_token] = 0;         
        m_Balances[msg.sender][_token] = 0;
        ERC20(_token).transfer(msg.sender, _amount+_earnings);
        emit Withdraw(msg.sender, _token, _amount+_earnings);
        return _earnings;
    }    
    // Removes all deposited tokens without adding earnings
    // Earnings since last deposit or reStake will be lost with this operation
    // Earnings are added from prior multiple deposits or restakes are left for later withdraw and will continue to accumulate if their balance is great enough
    function safetyWithdraw(address _token) external {
        uint256 _amount = m_Deposits[msg.sender][_token];  
        m_Deposits[msg.sender][_token] = 0;      
        m_Balances[msg.sender][_token] -= _amount;  
        ERC20(_token).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _token, _amount);
    }
    function transferOwnership(address _owner) external {
        require(msg.sender == m_Owner);
        m_Owner = _owner;
    }
    // Balance held must be greater than denominator (eg: cannot earn if 800 held and payout is 1 per 1000)
    function _claimDividends(address _address, address _token) private Lock returns (uint256) {
        if(block.timestamp - m_Timestamps[_address][_token] < m_Intervals[_token])
            return 0;
        if(m_Balances[_address][_token] < m_Denoms[_token])
            return 0;
        uint256 _amount = _getCurrentEarnings(_address, _token);
        require(m_Pools[_token] >= _amount, "Inadequate backing funds available");
        m_Pools[_token] -= _amount;
        m_Timestamps[msg.sender][_token] = block.timestamp;
        return _amount;
    }
    function _getCurrentEarnings(address _address, address _token) private view returns (uint256) {
        return m_Rates[_token] * ((block.timestamp - m_Timestamps[_address][_token]) / m_Intervals[_token]) * (m_Balances[_address][_token] / m_Denoms[_token]);
    }
}