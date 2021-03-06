pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract USTMSale01 {
    address public _beneficiary;
   
    uint public _deadline;
    uint public _price;
    token public _tokenReward;
    mapping(address => uint256) public balanceOf;
    event FundTransfer(address backer, uint amount, bool isContribution);
    event ErrorNotEnoughTokens(uint tryingtobuy, uint available);
    event ErrorOrderToSmall(uint sent, uint required);
    event ErrorOrderTooBig(uint sent, uint required);
    bool public _saleclosed = true;

    bool public _beneficiaryWithdraw = true;
    uint public _minimum;
    uint public _maximum;
    uint public _tokenbalance;
    uint public _etherbalance;
    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Constructor() public 
    {
       
        
    }
    
    function StartSale( address beneficiary,
        uint durationInDays,
        uint tokenPriceMillionth,
        address addressOfTokenUsedAsReward,
        uint minimumMillionth,
        uint maximumMillionth,
        uint totalInt) public
    {
        require (_saleclosed);
        require(_beneficiaryWithdraw);
        
        uint millionth = 1000000000000;
        _beneficiary = beneficiary;
        _deadline = now + durationInDays * 1 days;
        _price = tokenPriceMillionth * millionth;
        _tokenReward = token(addressOfTokenUsedAsReward);
        _minimum = minimumMillionth * millionth;
        _maximum = maximumMillionth * millionth;
        _tokenbalance = totalInt * 1 ether;
        _etherbalance = 0;
        _saleclosed= false;
        _beneficiaryWithdraw = false;
    }
    
    function StopSale() public
    {
        _saleclosed = true;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        
        if (msg.sender == _beneficiary)
            return;
        
        require(!_saleclosed);
        
        uint amount = msg.value;
        if (amount < _minimum)
        {
            emit ErrorOrderToSmall(amount, _minimum);
            require(false);
        }
        
        if (amount > _maximum)
        {
            emit ErrorOrderTooBig(amount, _maximum);
            require(false);
        }
            
        uint tosend = amount / _price * 1 ether;
        if (tosend > _tokenbalance)
        {
            emit ErrorNotEnoughTokens(tosend, _tokenbalance);
            require(false);
        }
            
        
       _tokenReward.transfer(msg.sender, tosend);
       emit FundTransfer(msg.sender, amount, true);
       _tokenbalance-=tosend;
       _etherbalance+=amount;
    }

    modifier afterDeadline() { if (now >= _deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        _saleclosed = true;
    }
    
    function HardClear() public
    {
        _saleclosed = true;
        _beneficiaryWithdraw=true;
    }

    function WithDraw() public{
        require(msg.sender == _beneficiary);
        require(_saleclosed);
   
            uint amount = _tokenbalance;
            
            if (amount > 0) 
            {
                _tokenReward.transfer(msg.sender, amount);
                emit FundTransfer(msg.sender, amount, true);
                _tokenbalance = 0;
               
            }
        

       if (_etherbalance > 0)
       {

           msg.sender.send(_etherbalance);
           emit FundTransfer(_beneficiary, _etherbalance, true);
           _etherbalance = 0;
          
       }
       _beneficiaryWithdraw = true;
        
    }




    
    
}