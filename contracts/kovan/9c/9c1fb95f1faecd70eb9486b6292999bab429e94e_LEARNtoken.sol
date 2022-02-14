/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

library SafeMath { 
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract owned {
    FakeDaiToken fakedaitoken;
    address dean;

    using SafeMath for uint256;
    
    constructor() {
        dean = msg.sender;
        fakedaitoken = FakeDaiToken(0x04DF6e4121c27713ED22341E7c7Df330F56f289B);
    }

    modifier onlyOwner {
        require(msg.sender == dean,
        "only dean can call this function"
        );
        _;
    }

}

interface FakeDaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    }

contract LEARNtoken is IERC20, owned {

    event Bought(uint256 amount);
    event Redemption(uint256 amount);
    event RebatePaid(uint256 amount);

    string public constant name = "LEARNtoken";
    string public constant symbol = "LEARN";
    uint8 public constant decimals = 18;  

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;

   constructor(uint256 total) {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public override view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function checklearnprice() public view returns (uint256) {
        return fakedaitoken.balanceOf(address(this)) / balances[address(this)];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] -numTokens;
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function buylearn(uint256 buyqty) external {
        uint256 daiamount = ((buyqty / 100) * (10 ** 18));
        uint256 fakedaiBalance = fakedaitoken.balanceOf(address(msg.sender));
        require(daiamount > 0, "You need to send some DAI");
        require(fakedaiBalance > daiamount, "Not enough DAI");
        fakedaitoken.transfer(address(this), daiamount);
        balances[address(msg.sender)] += buyqty;
        totalSupply_ += buyqty;
        emit Bought(buyqty);
    }

    function redeemlearn(uint redeemqty) external {
        uint dairebate = ((redeemqty * 100) * (10 ** 18));
        uint userBalance = balanceOf(address(msg.sender));
        uint reserveBalance = fakedaitoken.balanceOf(address(this));
        require(redeemqty > 0, "select rebate quantity");
        require(dairebate <= reserveBalance, "not enough DAI in the reserve");
        require(userBalance > redeemqty, "not enough LEARN");
        fakedaitoken.transfer(address(msg.sender), dairebate);
        transfer(address(this), redeemqty);
        emit Redemption(dairebate);
    }

    function giverebate(uint givedai) public {
        uint dairebate = ((givedai) * (10 ** 18));
        require(dairebate <= fakedaitoken.balanceOf(address(msg.sender)),
        "not enough USDC");
        uint fakedaiBalance = fakedaitoken.balanceOf(address(msg.sender));
        require(givedai > 0, "You need to send some USDC");
        require(fakedaiBalance > givedai, "Not enough USDC");
        fakedaitoken.transfer(address(this), givedai);
        emit RebatePaid(dairebate);

    }

}