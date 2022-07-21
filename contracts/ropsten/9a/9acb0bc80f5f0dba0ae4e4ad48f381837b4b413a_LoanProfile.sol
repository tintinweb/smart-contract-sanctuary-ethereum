/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;


contract HCTokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}


contract USDTInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
}
contract USDCInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DAITokenInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}



contract LoanProfile {

    event updatedCollectedAmount(uint newAmount);

    string public name = "Mortgage A";
    address public homeOwner = 0xd12F27341F3493c8c33D6069933d9c867E65bDfC;
    uint public loanAmount;
    uint public timePeriod;
    uint public timeCreated;
    uint public collectedAmount; //added collected amount
    address public owner;

    address public HCTokenAddress = 0xb14A8b78e6AA431898eEf94C99fd45bB7be6a4Eb;
    HCTokenInterface HCToken = HCTokenInterface(HCTokenAddress);

    address public USDTAddress = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    USDTInterface USDT = USDTInterface(USDTAddress);

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    USDCInterface USDC = USDCInterface(USDCAddress);

    address public DAITokenAddress = 0x31F42841c2db5173425b5223809CF3A38FEde360;
    DAITokenInterface DAI = DAITokenInterface(DAITokenAddress);

    address[] public investors;

    mapping(address => uint) public investedAmount;
    mapping(address => bool) public hasInvested;
    mapping(address => bool) public isInvesting;

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor(uint _loanAmount, uint _timePeriod) public {
        loanAmount = _loanAmount;
        timePeriod = _timePeriod;
        timeCreated = now;
        owner = msg.sender;
        collectedAmount = 0;

    }
    
    function deposit(uint _amount) public {
        require(_amount > 0, "Amount cannot be 0");
        //deposit stable coin
        USDC.transferFrom(msg.sender, address(this), _amount);
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
        emit updatedCollectedAmount(collectedAmount);

        
    }

    function refund() private onlyOwner {
        require(now >= (timeCreated + timePeriod));
        for(uint i=0; i < investors.length; i++){
            uint balance = investedAmount[investors[i]];
            USDC.transferFrom(address(this), investors[i], balance);
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
        USDC.transferFrom(address(this), homeOwner, collectedAmount);
    }

}