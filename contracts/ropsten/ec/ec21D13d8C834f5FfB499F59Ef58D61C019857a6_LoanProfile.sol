/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity ^0.5.0;


contract HCTokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract HCUSDInterface {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}



contract LoanProfile {
    string public name = "Loan Profile";
    address public homeOwner = 0xd12F27341F3493c8c33D6069933d9c867E65bDfC;
    uint public loanAmount;
    uint public timePeriod;
    uint public timeCreated;
    uint public collectedAmount; //added collected amount
    address public owner;

    address public HCTokenAddress = 0xb14A8b78e6AA431898eEf94C99fd45bB7be6a4Eb;
    HCTokenInterface HCToken = HCTokenInterface(HCTokenAddress);

    address public HCUSDAddress = 0x4a1ba0E033F8004a4D1203AF31FD7b901451489E;
    HCUSDInterface HCUSD = HCUSDInterface(HCUSDAddress);

    address[] public investors;

    mapping(address => uint) public investedAmount;
    mapping(address => bool) public hasInvested;
    mapping(address => bool) public isInvesting;

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor(uint _loanAmount,uint _timePeriod) public {
        loanAmount = _loanAmount;
        timePeriod = _timePeriod;
        timeCreated = now;
        owner = msg.sender;
        collectedAmount = 0;

    }
    
    function deposit(uint _amount) public {
        require(_amount > 0, "Amount cannot be 0");
        //deposit stable coin
        HCUSD.transferFrom(msg.sender, address(this), _amount);
        //update investedAmount
        investedAmount[msg.sender] = investedAmount[msg.sender] + _amount;
        //add to investors array if havent stake 
        if(!hasInvested[msg.sender]) {
            investors.push(msg.sender);
        } 
        //update staking status
        isInvesting[msg.sender] = true;
        hasInvested[msg.sender] = true;
        //update collected amount
        collectedAmount= collectedAmount + _amount;

        
    }

    function refund() private onlyOwner {
        require(now >= (timeCreated + timePeriod));
        for(uint i=0; i < investors.length; i++){
            uint balance = investedAmount[investors[i]];
            HCUSD.transferFrom(address(this), investors[i], balance);
        }
       
    }

    function issueToken() public onlyOwner {
        for (uint i=0; i<investors.length; i++) {
            address recipient = investors[i];
            uint balance = investedAmount[recipient];
            if (balance > 0) {
                HCToken.transfer(recipient, balance);
            }
        }
    }
    function loanFulfilled() private onlyOwner {
        require(collectedAmount == loanAmount);
        HCUSD.transferFrom(address(this), homeOwner, collectedAmount);
    }

}