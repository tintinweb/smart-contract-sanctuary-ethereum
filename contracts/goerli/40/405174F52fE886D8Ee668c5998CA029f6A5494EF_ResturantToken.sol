/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

// File: github/karthik311297/TOKEN-CURATED-RESTURANTS/contracts/ResturantToken.sol


pragma solidity >=0.6.6 <0.7.0;

contract ResturantToken{
    uint public totalSupply;
    address payable public minter;
    uint public tokenPrice;
    mapping (address=>uint)  public balanceOf;
    mapping (address => mapping(address => uint)) allowance;

    constructor(uint _totalSupply,uint _tokenPrice)public{
        totalSupply=_totalSupply;
        balanceOf[msg.sender]=_totalSupply;
        minter=msg.sender;
        tokenPrice=_tokenPrice;
    }
    function transfer(address _to,uint _tokens) public returns(bool) {
        require(balanceOf[msg.sender] >= _tokens);
        
        balanceOf[msg.sender]-=_tokens;
        
        balanceOf[_to]+=_tokens;
        
        return true;
    }
    function transferFrom(address _from,uint _tokens) public returns(bool){
        require(balanceOf[_from] >= _tokens);
        require(allowance[_from][msg.sender] >= _tokens);
        balanceOf[_from]-=_tokens;
        balanceOf[msg.sender]+=_tokens;
        allowance[_from][msg.sender]-=_tokens;
        return true;
    }
    
    function approve(address _spender,uint _tokens) public returns(bool){
        allowance[msg.sender][_spender]=_tokens;
        return true;
    }
    
    function buyTokens(uint _tokens) public payable returns(bool){
        require(msg.sender!=minter);
        require(balanceOf[minter] > _tokens);
        require(msg.value == _tokens*tokenPrice);
        balanceOf[minter]-=_tokens;
        balanceOf[msg.sender]+=_tokens;
        return true;
    }
    function mintTokens(uint _tokens) public returns(bool) {
        require(msg.sender == minter);
        totalSupply+=_tokens;
        balanceOf[minter]+=_tokens;
        return true;
    }
    function exchangeTokensforEther(uint _tokens) public  {
        require(msg.sender!=minter);        
        require(balanceOf[msg.sender] >= _tokens);
        uint exchangeEther=_tokens*tokenPrice;
        require(exchangeEther <= address(this).balance);
        balanceOf[msg.sender]-=_tokens;
        msg.sender.transfer(exchangeEther);
    }
    function changeTokenPrice(uint _tokenPrice) public{
        require(msg.sender == minter);
        tokenPrice=_tokenPrice;
    }    
    function withdrawContractEther() public {
        minter.transfer(address(this).balance);
    }
    
}


//address: 0x90Ca384e6C2733f439ed4EE76488818D60683217