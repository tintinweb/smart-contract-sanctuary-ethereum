/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// File: contracts/Staking.sol


pragma solidity ^0.8.7;


contract TokenFarm {
    string public name = "Token Farm";
    address public owner;
    IERC20 public  rshameemToken;
    IERC20 public  shameemToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(address _rshameem, address _shameem) {
        rshameemToken = IERC20(_rshameem);
        shameemToken = IERC20(_shameem);
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public payable{
        require(_amount > 0, "amount cannot be 0");

        shameemToken.transferFrom(msg.sender, address(this), _amount);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }


    function unstakeTokens() public {
        
        uint balance = stakingBalance[msg.sender];

        require(balance > 0, "staking balance cannot be 0");

        shameemToken.transfer(msg.sender, balance);

        stakingBalance[msg.sender] = 0;
        
        isStaking[msg.sender] = false;
    }

    function issueTokens() public {
        require(msg.sender == owner, "caller must be the owner");
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0) {
                rshameemToken.transfer(recipient, balance/2);
            }
        }
    }
}


interface IERC20 {

    function transfer(address recipient, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

}