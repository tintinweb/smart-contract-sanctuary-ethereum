/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// File: contracts/3_Ballot.sol

pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


interface token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns(uint balance);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

} 

contract BhamRToken is  Owned, SafeMath {

    uint public startDate;
    uint public bonusEnds;
    uint public endDate;
    token public reward;
    uint public Ownerbalance;

    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        address BhamRTokenAddress =0x05bab4fe3FDc481b321892570b0653150b08de04 ;
        bonusEnds = now + 18 weeks;
        endDate = now + 24 weeks;
        reward = token(BhamRTokenAddress);


    }
    function getbalance() public returns(uint) {
        uint test = reward.balanceOf(this);
        return (test);
    }
    // ------------------------------------------------------------------------
    // 600 BhamR Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now <= bonusEnds) {
            tokens =  msg.value * 800;
        } else {
            tokens = msg.value * 600;
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        reward.transfer(msg.sender, tokens);
        //Cialfor : The owner will get the amount transferred to this contract
        uint amount = address(this).balance;
        owner.transfer(amount);
    }
    //function to withdraw funds during crowdsale
    function safeWithdrawal() public onlyOwner {
            uint amount = address(this).balance;
            owner.transfer(amount);
    }
    //function to end crowdsale
    function endCrowdsale() public onlyOwner {
        endDate = now;
    }

    function withdrawTokens() public onlyOwner{
        Ownerbalance = reward.balanceOf(this);
        reward.transfer(owner, Ownerbalance);

    }

}