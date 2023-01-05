/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IHoodcoin {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract HoodCoin is IHoodcoin {

    string public constant name = "HoodCoin";
    string public constant symbol = "HDC";
    uint8 public constant decimals = 18;
    uint public remainingToken = 1000000000000000000000;
    uint weiRaised;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 1000 ether;


   constructor() {
    balances[msg.sender] = totalSupply_;
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
        balances[receiver] = balances[receiver]+numTokens;
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

    function buyTokens(address _investor) public payable {
        uint256 weiAmount = msg.value;
        require(_preValidatePurchase(weiAmount));

    // update state
    weiRaised = weiRaised + weiAmount;
    
    // Calculate the token amount
     uint256 tokens = _calculateToken(weiAmount);
    
    // Transfer them to the investor address
     _processPurchase(_investor, tokens);
    }

    function _preValidatePurchase(uint amount) internal view returns(bool){
        if(amount <= remainingToken){
            return true;
        }
        return false;
    }

    function _deliverTokens(address _investor, uint256 _tokenAmount) internal {
        HoodCoin.transfer(_investor, _tokenAmount);
    }

    function _processPurchase(address _investor, uint256 _tokenAmount) internal
    {
      _deliverTokens(_investor, _tokenAmount);
    }

function _calculateToken(uint256 _weiAmount)
    internal
    pure
    returns (uint256)
    {
      return _weiAmount;
    }
}