/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract ERC20{
    constructor(uint _totalSupply,
                string memory _Symbol,
                string memory _Name,
                uint8 _Decimal)
    {
        balances[msg.sender] = _totalSupply;
        TotalSupply = _totalSupply;
        Symbol = _Symbol;
        Name = _Name;
        Decimal = _Decimal;
        Owner = msg.sender;
    }
    uint private TotalSupply;
    string public Symbol;
    string public Name;
    uint8 public Decimal;
    address public Owner;
    mapping (address => uint) public balances;
    mapping (address =>mapping(address => uint)) public approval;
//events
event Approval(address indexed _owner, address indexed _spender, uint _amount);
event Transfer(address indexed _from, address indexed  _to, uint _amount);

//modifiers
    modifier balance_check( uint _amount){
        require(balances[Owner] >= _amount,'not enough balance in user account!');
        _;
    }
    modifier address_exist(address _addr){
        require(_addr != address(0),'invalid address!');
        _;
    }
    modifier approval_check(address _spender,uint _amount) {
        _;
        require(approval[msg.sender][_spender] == _amount,'approval unsuccesful!');
    }
    modifier spender_check(address _owner, address _spender,uint _amount){
        require(approval[_owner][_spender] >= _amount,'not enough amount approved for spender by owner!');
        _;  
    }
//functions

    function total_supply() public view returns(uint){
        return TotalSupply;
    }

    function balance_of(address _addr) public view returns(uint)
    {
        return balances[_addr];
    }

    function approve(address _spender,uint _amount) address_exist(_spender) approval_check(_spender,_amount) public returns(bool)
    {
       approval[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
    }

    function transfer(address _to ,uint _amount) address_exist(_to) balance_check(_amount) public {
        balances[Owner] -= _amount;
        balances[_to] += _amount; 
        emit Transfer(Owner, _to, _amount);
    }

    function transfer_from(address _from, address _to, uint _amount) address_exist(_to) spender_check(_from,msg.sender,_amount) public
    {
        approval[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount; 
        emit Transfer(_from, _to, _amount);
    }

    function allowance(address _owner, address _spender)public  view returns(uint){
        return approval[_owner][_spender];
    }

    function increase_allowance(address _spender, uint _amount) address_exist(_spender) public returns (uint previous, uint updated){
        previous = approval[msg.sender][_spender];
        approval[msg.sender][_spender] += _amount;
        updated = approval[msg.sender][_spender];
        emit Approval(msg.sender, _spender, _amount);
    }

    function decrease_allowance(address _spender, uint _amount) address_exist(_spender) public returns (uint previous, uint updated){
        previous = approval[msg.sender][_spender];
        approval[msg.sender][_spender] -= _amount;
        updated = approval[msg.sender][_spender];
        emit Approval(msg.sender, _spender, _amount);
    }
}
contract crowdsale
{
    address  payable public  beneficiary;
    uint public funding_goal;
    uint public deadline;
    uint public price;
    ERC20 public token_reward;
    uint public amount_raised; 
    bool crowdsale_time_over;
    bool funding_goal_reached;
    mapping (address => uint) public investments;
    constructor(
        address  owner,
        uint funding_goal_in_ether,
        uint crowd_sale_end_time_in_minutes,
        uint price_per_token_in_wei,
        address token_contract_address
    ){
///the beneficiary should be same as the account who contains all the tokens!!!
        beneficiary = payable(owner);
        funding_goal = funding_goal_in_ether * 1 ether;
        deadline = crowd_sale_end_time_in_minutes * 1 minutes;
        deadline = block.timestamp + deadline;
        price = price_per_token_in_wei * 1 wei;
        token_reward = ERC20(token_contract_address);
    }
    modifier beneficiary_check{
        require(msg.sender == beneficiary,'only beneficiary can do withdrawal!');
        _;
    }
    modifier crowdsale_time_end_check{
        require(block.timestamp < deadline,'The crowdsale time is over!');
        _;
    }
    modifier crowdsale_check{
        require(block.timestamp > deadline || crowdsale_time_over,'The crowdsale time is not over yet!');
        _;
    }
    modifier funding_goal_check{
        require(funding_goal_reached,'Funding goal not reached!');
        _;
    }
    modifier check_investor{
        require(investments[msg.sender]>0,'Invalid Investor with no deposited amount!');
        _;
    }
    modifier crowdsale_continue{
        require(!crowdsale_time_over ,'crowdsale is stopped by the beneficiary!');
        _;
    }
    function get_total_supply() public view returns(uint){
        return token_reward.total_supply();
    }
    function get_tokens() crowdsale_time_end_check crowdsale_continue payable public 
    {
        uint _amount = msg.value;
        investments[msg.sender] = _amount;
        token_reward.transfer(msg.sender, _amount/price);
        amount_raised += msg.value;
        if (amount_raised >= funding_goal)
        {
            funding_goal_reached = true;
        }
    }
    function withdraw_raised_fund() public crowdsale_check funding_goal_check beneficiary_check {
        (bool check,) = beneficiary.call{value: amount_raised}("");
        amount_raised = 0;
        require(check,'withdrawal failed!');
    }
    function owned_tokens() public view returns(uint){
        return token_reward.balance_of(msg.sender);
    }
    function withdraw_investment() public crowdsale_check check_investor {
    require(!funding_goal_reached,'withdrawal of investment is not possible because crowdsale funding goal has been reached!!');
    address investor = msg.sender;
    (bool check,) = investor.call{value: investments[investor]}("");
    require(check,'withdrawal failed!');
    amount_raised -= investments[investor];
    investments[investor] = 0;
    }
    function stop_crowdsale() public beneficiary_check crowdsale_continue{
        crowdsale_time_over = true;
    }
}