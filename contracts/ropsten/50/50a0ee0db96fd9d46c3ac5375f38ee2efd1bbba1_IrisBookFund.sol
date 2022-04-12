/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);    //get the total token supply
    function balanceOf(address account) external view returns (uint);   //get the account balance of account address
    function transfer(address recipient, uint amount) external returns (bool);  //send amount of tokens
    function approve(address spender, uint amount) external returns (bool);     //allow tokens to be withdrawn from sending address
    function allowance(address owner, address spender) external view returns (uint);    //returns the remaining tokens of the address
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);  //define where the tokens are transfering from
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// Iris create her novel as a ERC20 standard token. Named "MyBook"
contract MyBook is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "IRIS BOOK";
    string public symbol = "IBK";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

//Iris creates a donation campaign for her novel. Named "IrisBookFund"
contract IrisBookFund {
    event Launch(address creator, uint goal, uint32 startAt);
    event Cancel(address creator);
    event Pledge(address indexed caller, uint amount);
    event Unpledge(address indexed caller, uint amount);
    event GetBook(address indexed caller, uint amount);
    event GetFund(address creator, uint goal);
    event Refund(address indexed caller, uint amount);

    struct Campaign {
        address creator;    // Creator of campaign
        uint goal;  // Amount of Ethers to raise
        uint pledged;   // Total amount pledged
        uint32 startAt; // Timestamp of start of campaign
        uint32 endAt;   // Timestamp of end of campaign
    }
    Campaign public MyCampaign ;    // 活动 MyCampaign

    IERC20 public immutable MyToken;
    address payable public owner;
    constructor(address _token) payable {
        MyToken = IERC20(_token);
        owner =  payable(msg.sender);
    }

    mapping(address => uint) public pledgedAmount;     // 映射 pledger => amount pledged
    
    //发起人(owner)具有launch、cancel活动的权利
    function launch(
        uint _goal,
        uint32 _startAt
    ) external {
        require(_startAt >= block.timestamp, "Launch failed. Start time is earlier than now.");

        MyCampaign.creator = owner; 
        MyCampaign.goal = _goal * 1 ether;
        MyCampaign.startAt = _startAt;
        MyCampaign.endAt = _startAt + 30 days;

        emit Launch(owner, _goal, _startAt);
    }

    function cancel() external {
        require(msg.sender == owner, "Cancel failed. Please let MyCampaign creator do this.");
        require(block.timestamp < MyCampaign.startAt, "Cancel failed. Campaign did start.");

        delete MyCampaign;

        emit Cancel(msg.sender);
    }

    //参与者可以在活动期间pledge、unpledge
    function pledge() external payable {
        Campaign storage campaign = MyCampaign; //Declaring variable as 'storage' is we r going to update the campaign instruct
        require(block.timestamp >= campaign.startAt, "Pledge failed. Campaign has not started");
        require(block.timestamp <= campaign.endAt, "Pledge failed. Campaign has ended");

        uint amount = 0.02 ether + (campaign.pledged/1e18) * 0.002 ether;  // 1 ether = 1e18 wei = 1e9  //测试输入：前50人捐的值是2e7 Gwei
        require(msg.value == amount,"Amount is wrong");

        campaign.pledged +=  msg.value;
        pledgedAmount[msg.sender] += msg.value;

        emit Pledge(msg.sender, msg.value);
    }

    function unpledge(address payable _to, uint _amount) external {
        Campaign storage campaign = MyCampaign;
        require(block.timestamp <= campaign.endAt, "Unpledge failed. Campaign has ended.");
        require( _amount <= pledgedAmount[msg.sender], "Unpledge amount should be smaller than the amount you pledged");
        
        campaign.pledged -= _amount;
        pledgedAmount[msg.sender] -= _amount;
        
        //transfer Ether from this contract to address from input
        require( _to == msg.sender, "Please switch to the pledge account");
        (bool success, ) = _to.call{ value: _amount } ("");
        require(success,"Failed to send ether");

        emit Unpledge(msg.sender, _amount);
    }

    //活动结束后
    //若达到目标，则参与者getbook、发起人getfund
    function getbook() external {
        require(block.timestamp > MyCampaign.endAt, "getbook failed. Campaign has not ended.");
        require(MyCampaign.pledged >= MyCampaign.goal, "getbook failed. Campaign has not reached its goal.");
        require(pledgedAmount[msg.sender] >= 0 ,"getbook failed. You did not pledge to this campaign.");

        MyToken.transfer(msg.sender, 1);
        MyToken.approve(msg.sender, 1);
        
        emit GetBook(msg.sender, 1);
    }

    function getfund() external {
        require(block.timestamp > MyCampaign.endAt, "getfund failed. Campaign has not ended");
        require(MyCampaign.pledged >= MyCampaign.goal, "getfund failed. Campaign has not reached its goal.");
        require(msg.sender == MyCampaign.creator, "getfund failed. Please let MyCampaign creator do this.");

        uint amount = address(this).balance;
        (bool success, ) = owner.call{ value: amount }("");
        require(success,"Failed to send ether");

        emit GetFund(owner, amount);
    }

    //若没达到目标，则参与者refund
    function refund(address payable _to) external {
        Campaign memory campaign = MyCampaign;
        require(block.timestamp > campaign.endAt, "refund failed. Campaign has not ended.");
        require(campaign.pledged < campaign.goal, "refund failed. Campaign has not reached its goal.");

        uint bal = pledgedAmount[msg.sender];
        pledgedAmount[msg.sender] = 0; //resetting the balance before retransferring the token is to prevent reentrancy effect
        
        require( _to == msg.sender, "Please switch to the pledge account");
        (bool success, ) = _to.call{ value: bal } ("");
        require(success,"Failed to send ether");

        emit Refund(msg.sender, bal);
    }
}