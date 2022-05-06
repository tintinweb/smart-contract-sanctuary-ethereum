/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnerHelper
{
    address public owner;
    address public manager;

    event ChangeOwner(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner, "ERROR: Not owner");
        _;
    }

    modifier onlyManagerAndOwner
    {
        require(msg.sender == manager || msg.sender == owner, "ERROR: Not manager and owner");
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != manager);
        require(_to != address(0x0));

        address from = owner;
        owner = _to;

        emit ChangeOwner(from, _to);
    }

    function transferManager(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != manager);
        require(_to != address(0x0));

        address from = manager;
        manager = _to;

        emit ChangeManager(from, _to);
    }
}

abstract contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() view virtual public returns (uint _supply);
    function balanceOf( address _who ) virtual public view returns (uint _value);
    function transfer( address _to, uint _value) virtual public returns (bool _success);
    function approve( address _spender, uint _value ) virtual public returns (bool _success);
    function allowance( address _owner, address _spender ) virtual public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) virtual public returns (bool _success);
}

contract CGT is ERC20Interface, OwnerHelper
{
    string public name;
    uint public decimals;
    string public symbol;

    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;

    // Total                                         1,000,000,000
    uint constant public maxTotalSupply           = 1000000000 * E18;
    // Sale                                         100,000,000 (10%)
    uint constant public maxSaleSupply            = 100000000 * E18;
    // Marketing                                    180,000,000 (18%)
    uint constant public maxMktSupply             = 180000000 * E18;
    // EcoSystem                                    250,000,000 (25%)
    uint constant public maxEcoSupply             = 250000000 * E18;
    // Stream to Earn                               250,000,000 (25%)
    uint constant public maxS2ESupply             = 250000000 * E18;
    // Reserve                                      100,000,000 (10%)
    uint constant public maxReserveSupply         = 100000000 * E18;
    // Team                                         100,000,000 (10%)
    uint constant public maxTeamSupply            = 100000000 * E18;
    // Advisors                                     20,000,000 (2%)
    uint constant public maxAdvisorSupply         = 20000000 * E18;

    // Lock
    uint constant public teamVestingSupply = 5000000 * E18;
    uint constant public teamVestingLockDate =  12 * month;
    uint constant public teamVestingTime = 20;

    uint constant public advisorVestingSupply = 1000000 * E18;
    uint constant public advisorVestingLockDate =  12 * month;
    uint constant public advisorVestingTime = 20;

    uint public totalTokenSupply;
    uint public tokenIssuedSale;
    uint public tokenIssuedMkt;
    uint public tokenIssuedEco;
    uint public tokenIssuedS2E;
    uint public tokenIssuedRsv;
    uint public tokenIssuedTeam;
    uint public tokenIssuedAdv;

    uint public burnTokenSupply;

    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;

    mapping (uint => uint) public tmVestingTimer;
    mapping (uint => uint) public tmVestingBalances;
    mapping (uint => uint) public advVestingTimer;
    mapping (uint => uint) public advVestingBalances;

    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;
    address public teamWalletAddress;
    address public advisorWalletAddress;

    event SaleIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event EcoIssue(address indexed _to, uint _tokens);
    event S2EIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event AdvIssue(address indexed _to, uint _tokens);

    event Burn(address indexed _from, uint _tokens);

    event TokenUnlock(address indexed _to, uint _tokens);
    event EndSale(uint _date);

    constructor()
    {
        name        = "Cloid Governance Token";
        decimals    = 18;
        symbol      = "CGT";

        totalTokenSupply = maxTotalSupply;
        balances[owner] = totalTokenSupply;

        tokenIssuedSale     = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedEco      = 0;
        tokenIssuedS2E      = 0;
        tokenIssuedRsv      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedAdv      = 0;

        burnTokenSupply     = 0;

        require(maxTeamSupply == teamVestingSupply * teamVestingTime, "ERROR: MaxTeamSupply");
        require(maxAdvisorSupply == advisorVestingSupply * advisorVestingTime, "ERROR: MaxAdvisorSupply");
        require(maxTotalSupply == maxSaleSupply + maxMktSupply + maxEcoSupply + maxS2ESupply + maxReserveSupply + maxTeamSupply + maxAdvisorSupply, "ERROR: MaxTotalSupply");
    }

    function totalSupply() view override public returns (uint)
    {
        return totalTokenSupply;
    }

    function balanceOf(address _who) view override public returns (uint)
    {
        return balances[_who];
    }

    function transfer(address _to, uint _value) override public returns (bool)
    {
        require(isTransferable() == true);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) override public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);

        approvals[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) view override public returns (uint)
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) override public returns (bool)
    {
        require(isTransferable() == true);
        require(approvals[_from][msg.sender] >= _value);

        approvals[_from][msg.sender] = approvals[_from][msg.sender] - _value;

        _transfer(_from, _to, _value);

        return true;
    }

    function saleIssue(address _to) onlyOwner public
    {
        require(tokenIssuedSale == 0);

        uint tokens = maxSaleSupply;
        _transfer(msg.sender, _to, tokens);
        tokenIssuedSale = tokenIssuedSale + tokens;

        emit SaleIssue(_to, tokens);
    }

    function s2eIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedS2E == 0);

        uint tokens = maxS2ESupply;
        _transfer(msg.sender, _to, tokens);
        tokenIssuedS2E = tokenIssuedS2E + tokens;

        emit S2EIssue(_to, tokens);
    }

    function ecoIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedEco == 0);

        uint tokens = maxEcoSupply;
        _transfer(msg.sender, _to, tokens);
        tokenIssuedEco = tokenIssuedEco + tokens;

        emit EcoIssue(_to, tokens);
    }

    function mktIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedMkt == 0);

        uint tokens = maxMktSupply;
        _transfer(msg.sender, _to, tokens);
        tokenIssuedMkt = tokenIssuedMkt + tokens;

        emit MktIssue(_to, tokens);
    }

    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedRsv == 0);

        uint tokens = maxReserveSupply;
        _transfer(msg.sender, _to, tokens);
        tokenIssuedRsv = tokenIssuedRsv + tokens;

        emit RsvIssue(_to, tokens);
    }

    // 팀 Vesting 분배를 하기 전에 미리 옮겨두는 용도의 발행.
    function teamIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedTeam == 0);

        uint tokens = maxTeamSupply;
        _transfer(msg.sender, _to, tokens);

        teamWalletAddress = _to;
    }

    // 어드바이저 Vesting 분배를 하기 전에 미리 옮겨두는 용도의 발행.
    function advisorIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedAdv == 0);

        uint tokens = maxAdvisorSupply;
        _transfer(msg.sender, _to, tokens);

        advisorWalletAddress = _to;
    }

    function teamVestingIssue(address _to, uint _time /* 몇 번째 지급인지 */) public
    {
        require(saleTime == false);
        require(msg.sender == teamWalletAddress || msg.sender == owner, "ERROR: Not team or owner");
        require( _time < teamVestingTime);

        uint nowTime = block.timestamp;
        require( nowTime > tmVestingTimer[_time] );

        uint tokens = teamVestingSupply;

        require(tokens == tmVestingBalances[_time]);
        require(maxTeamSupply >= tokenIssuedTeam + tokens);

        _transfer(msg.sender, _to, tokens);

        tmVestingBalances[_time] = 0;

        tokenIssuedTeam = tokenIssuedTeam + tokens;

        emit TeamIssue(_to, tokens);
    }

    function advisorVestingIssue(address _to, uint _time) public
    {
        require(saleTime == false);
        require(msg.sender == advisorWalletAddress || msg.sender == owner, "ERROR: Not advisor or owner");
        require( _time < advisorVestingTime);

        uint nowTime = block.timestamp;
        require( nowTime > advVestingTimer[_time] );

        uint tokens = advisorVestingSupply;

        require(tokens == advVestingBalances[_time]);
        require(maxAdvisorSupply >= tokenIssuedAdv + tokens);

        _transfer(msg.sender, _to, tokens);

        advVestingBalances[_time] = 0;

        tokenIssuedAdv = tokenIssuedAdv + tokens;

        emit AdvIssue(_to, tokens);
    }

    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }

        return false;
    }

    function setTokenUnlock() onlyManagerAndOwner public
    {
        require(tokenLock == true);
        require(saleTime == false);

        tokenLock = false;
    }

    function setTokenLock() onlyManagerAndOwner public
    {
        require(tokenLock == false);
        tokenLock = true;
    }

    function endSale() onlyOwner public
    {
        require(saleTime == true);
        require(maxSaleSupply == tokenIssuedSale);

        saleTime = false;

        uint nowTime = block.timestamp;
        endSaleTime = nowTime;

        for(uint i = 0; i < teamVestingTime; i++)
        {
            tmVestingTimer[i] = endSaleTime + teamVestingLockDate + (i * month);
            tmVestingBalances[i] = teamVestingSupply;
        }

        for(uint i = 0; i < advisorVestingTime; i++)
        {
            advVestingTimer[i] = endSaleTime + advisorVestingLockDate + (i * month);
            advVestingBalances[i] = advisorVestingSupply;
        }

        emit EndSale(endSaleTime);
    }

    function burnToken(uint _value) onlyManagerAndOwner public
    {
        uint tokens = _value * E18;

        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender] - tokens;

        burnTokenSupply = burnTokenSupply + tokens;
        totalTokenSupply = totalTokenSupply - tokens;

        emit Burn(msg.sender, tokens);
    }

    function close() onlyOwner public
    {
        selfdestruct(payable(msg.sender));
    }

    function _transfer(address _from, address _to, uint256 _value) internal
    {
        require(balances[_from] >= _value, "ERC20: balances is not enough");

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;

        emit Transfer(_from, _to, _value);
    }
}