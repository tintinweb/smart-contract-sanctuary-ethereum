/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface I_ICO_Token{
     function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external; 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ICO_Contract{
    
    uint public StartTime;
    uint public EndTime;
    bool public isSale_Open;
    address public Owners_Wallet;
    address public TokenAddress;
    address public Owner;
    uint public Rate;
    I_ICO_Token Token;
    uint public MaxTokensToSell;
    uint public RemainingTokensToSell;
    uint public numberOfPresaleTokensHolder;
    uint public Amount_Rate;                   //1000 tokens for 1 ether

    mapping(address => uint) public PresaleHolders;
    mapping(address => bool) public BlackList_Addresses;


    constructor(address _Owners_Wallet){
        StartTime = block.timestamp;
        EndTime =  block.timestamp + 10 days;
        isSale_Open = true;
        Owners_Wallet = _Owners_Wallet;
        Owner = msg.sender;
        MaxTokensToSell = 50000000000000000000000;
        RemainingTokensToSell = MaxTokensToSell;
        Rate = 1 ether;
        Amount_Rate = 1000;

    }

    function Setup_Address(address _Contract_Address)public onlyOwner{
    require(_Contract_Address!=address(0),"zero address is disallowed");
    Token = I_ICO_Token(_Contract_Address);
    TokenAddress = _Contract_Address;
    isSale_Open = true;
    }

    modifier onlyOwner(){
    require(msg.sender == Owner,"only onwer can use it");
    _;}


    function CloseSale() public onlyOwner{
        require(isSale_Open,"sale is already not started yet");
        isSale_Open = false;
    }

    function SetUpBlackListAddress(address BAddress,bool flag)public onlyOwner{
        BlackList_Addresses[BAddress] = flag;
    }
    
    
    function BuyTokens(uint Amount)public payable returns(bool){
     require(BlackList_Addresses[msg.sender]!=true,"blcklist addresses canonot take part in presale");
     require(block.timestamp > StartTime && block.timestamp < EndTime,"sale is not started yet");
     require(msg.value >= Rate,"minimum price is 1 ether");
     require(Amount <= MaxTokensToSell,"we offer limited amount of tokens in presale");

     uint PToken = (Amount * Amount_Rate) * 10 ** 18;   
     payable(Owners_Wallet).transfer(msg.value);
     Token.mint(msg.sender,PToken);
     PresaleHolders[msg.sender]=PToken;
     numberOfPresaleTokensHolder+=1;
     RemainingTokensToSell-=PToken;
     return true;
    }

    function CheckingRemainingPresaleTokens()public view returns(uint){
     return RemainingTokensToSell;
    }

    function updateRate(uint _Rate) public onlyOwner{
        Rate = _Rate;
    }
 
    function ChangeOwner(address NewOwner)public onlyOwner returns(bool){
    require(NewOwner!=address(0),"zero address cannot b an owner");
    require(BlackList_Addresses[NewOwner]!=true,"it is a blacklist address");
    Owner = NewOwner;
    return true;
    }
    function GetTokenName() public view returns(string memory){
      return Token.name();
    }
     function GetSymbol() public view returns(string memory){
      return Token.symbol();
    }
     function decimalss() public view returns(uint){
      return Token.decimals();
    }
    function OverAllTotalSupply() public view returns(uint){
     return Token.totalSupply();
      
    }

}