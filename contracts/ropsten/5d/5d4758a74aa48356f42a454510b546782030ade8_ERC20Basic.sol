/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

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


contract ERC20Basic is IERC20 {

    string public constant name = "BettaCoin_staking";
    string public constant symbol = "BETTA";
    uint8 public constant decimals = 18;

    address marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    address burnWallet=0x583031D1113aD414F02576BD6afaBfb302140225;
    address shibaWallet =0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    address liquidityWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address teamWallet = 0x3c98AB359579F42C7Cf48aE001eD28E7CE537edd;
    address webDevWallet = 0xd047307BB3e6Dff9FE6E478fdF792De44886f6d7;
    address rewardWallet = 0x6F6F70d02163cfaF37b2d4c1ce289D9Cb7976103;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ =1000000000000000000 * 10**18;


   constructor() {
      
        uint256 liqAmount = 20000000000000000*10**18;
        uint256 webAmount = 20000000000000000*10**18;
        uint256 remaining = totalSupply_ - webAmount - liqAmount;

        balances[liquidityWallet] = liqAmount;
        balances[webDevWallet] = webAmount;

        balances[msg.sender] = remaining;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        
        balances[marketingWallet] = balances[marketingWallet]+  (6*numTokens/100);
        balances[shibaWallet] = balances[shibaWallet]+(1*numTokens/100);
        balances[burnWallet] = balances[burnWallet]+(2*numTokens/100);
        balances[liquidityWallet] = balances[liquidityWallet]+(1*numTokens/100);
        balances[rewardWallet] = balances[rewardWallet]+(2*numTokens/100);

        balances[receiver] = balances[receiver]+(88*numTokens/100);
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

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}