//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";

contract SALES is Ownable
{
    IERC20 public token;
    address public OwnerTokenAddress;
    //uint256 public rate;
    uint256 public usdPerEth;
    uint private phaseIndex;
    //string phaseOfsales="ICO";
    address _owner;
    event Bought(string phase, uint256 amount);
    event Sold(string phase, uint256 amount);
    event OwnerWithdraw(string phase,uint256 amount);
    event bytesLog(bool sent,bytes data);

    /*
            PhaseIndex: 
            999 = Free
            1 = Airdrop
            2 = Seed
            3 = Private
            4 = ICO
            5 = CEX
            6 = DEX
            8 = Pool liquidity
            9 = Founder
    */
    
    /*
      send ether and get tokens in exchange; 1 token == 1 ether

        ETH Per WEI         		= 1000000000000000000 WEI

        Total Supply			    = 100,000,000,000,000.000000000000000000 SANDO

        Token Airdrop       25%     =  25,000,000,000,000.000000000000000000 SANDO
        Token SEED   	     5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Private 	    20%     =  20,000,000,000,000.000000000000000000 SANDO
        Token ICO            5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Presales (CEX) 5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Public (DEX)   5%	    =   5,000,000,000,000.000000000000000000 SANDO
        Token Marketing      5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Pool liquidity 5%	    =   5,000,000,000,000.000000000000000000 SANDO
        Token Founder       15%	    =  15,000,000,000,000.000000000000000000 SANDO
        Token Reserve       10%	    =  10,000,000,000,000.000000000000000000 SANDO

        USD Values SEED     		= 0.0009
        USD Values Private  		= 0.0012
        USD Values ICO      		= 0.0020
        USD Values Public   		= 0.0035

        Example:
        Token Values SEED    	    = SEED *0.0009
                            		= 4,500,000,000 USD

        USD Per ETH         		= 3000 USD
                            		=  USD

        MAX Values of SEED   	    = 1,500,000 ETH
                            		= 1,500,000,000,000,000,000,000,000 WEI
                            		= 1500000000000000000000000 WEI
        Price Rate  SEED       	    = (Token SEED 5%)/(MAX Values of SEED)  TOKEN per WEI
					                = 3,333,333 * (10^18) WEI per Token
                                    = 3333333
        1 WEI per Token             = 0.00000000000333333333333333 WEI per Token

    */

    /*
     rate = (Price of usdc per ETH) / 
     send ether and get tokens in exchange; 1 ether = 1 token * rate
     */
    //constructor
    mapping (uint => string[]) private strphaseOfsales;
    string[] private _strphaseOfsales =["Airdrop","SEED","Private Sales","ICO","CEX","DEX","Marketing","Pool liquidity","Founder","Reserve"];
    bool private sellFucntion = false;

    function initialSales (IERC20 _tokenAddress,uint256 _usdPerEthRate,uint256 _initTokenPerWEIRate) onlyOwner public 
    {
        phaseIndex = 2;

        require(_initTokenPerWEIRate > 0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rate[phaseIndex] = _initTokenPerWEIRate; //1200000000000000; //0.0012;
        usdPerEth = _usdPerEthRate;
        _owner=msg.sender;
        OwnerTokenAddress = address(_tokenAddress);
        
    }

    function getPhaseSeles() public view returns(string[] memory){
        return _strphaseOfsales;
    }

    function getOwnerToken() public returns(address){
        bytes memory payload = abi.encodeWithSignature("_owner()","");  
        bool success;
        bytes memory result;
        (success, result)= address(this).call(payload);

        // Decode data
        address _ownerToken = abi.decode(result, (address));
        return _ownerToken;
    }

    /*
        Protect Reentrancy Attacks check and clear value of request
        use modifier noReentrant()
        before transfer values to msg.sender keep values to temporary variable 
        immediately is done and set values = 0 

    */
    bool internal locked;

    modifier noReentrant() {
        require(!locked,"The list is not complete. please wait a moment.");
        locked = true; //before use function, set status locked is true.
        _;
        locked = false; //after use function is finish, set status locked is false.

    }

    function setState(uint _state) public onlyOwner {
        require(_state>=0,"State not found.");
        phaseIndex = _state;
    }

    function setstrphaseOfsales(uint _state,string memory _stateName,uint256 _initTokenPerWEIRate) public onlyOwner {
        strphaseOfsales[_state].push(_stateName);
        rate[_state] = _initTokenPerWEIRate;
    }

    function setUsdPerEthRate(uint _usdPerEthRate) external onlyOwner {
        require(_usdPerEthRate>0,"Rate not found..");
        usdPerEth = _usdPerEthRate;
    }

    mapping (uint => uint256) rate;

    function setTokenPerWeiRate(uint _state, uint _TokenPerWeiRate) external onlyOwner {
        require(_TokenPerWeiRate>0,"Rate not found..");
        require(_state>=0,"State is not found..");
        rate[_state] = _TokenPerWeiRate;
    }

    function getSenderAddress() public view returns (address) // for debugging purposes
    {
        return (msg.sender);
    }

    function getAddress() public view returns (address)
    {
        return address(this);
    }

    function getTokenAddress() public view returns (address)
    {
        return address(token);
    }

 
    modifier _checkPhase(){
        if((phaseIndex==2)||(phaseIndex==3)||(phaseIndex==4)||(phaseIndex==9)){sellFucntion=false;}
        if((phaseIndex==5)||(phaseIndex==6)){sellFucntion=true;}
        _;
    } 


    function buy() payable _checkPhase public 
    {
      require(sellFucntion==false,"This state is not enabled buy function.");
      uint256 amountTobuy = msg.value*rate[phaseIndex];
      uint256 salesBalance =  token.balanceOf(address(this)); //token.balanceOf(SalesWallet);
      require(amountTobuy > 0, "You need to send some ether");
      require(amountTobuy <= salesBalance, "Not enough tokens in the reserve");
      token.transfer(msg.sender, amountTobuy);
      emit Bought(_strphaseOfsales[phaseIndex], amountTobuy);
    }


    function sell(uint256 amount) payable _checkPhase public // send tokens to get ether back
    {
      require(sellFucntion==true,"This state is not enabled buy function.");  
      require(amount > 0, "You need to sell at least some tokens");
      uint256 allowance = token.allowance(msg.sender, address(this));
      require(allowance >= amount, "Check the token allowance");
      token.transferFrom(msg.sender, address(this), amount);
      payable(msg.sender).transfer(amount*rate[phaseIndex]);
      emit Sold(_strphaseOfsales[phaseIndex], amount*rate[phaseIndex]);
    }

    function getBalanceWEI() external view returns(uint256){
        return address(this).balance;
    }

    function getValueOfSales() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function OwnerWithdrawAll() public onlyOwner noReentrant{
      payable(msg.sender).transfer(address(this).balance);
      emit OwnerWithdraw(_strphaseOfsales[phaseIndex], address(this).balance);
    }

    function returnTokentoOrigin(uint256 _amountToOrigin) public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(_amountToOrigin > 0, "You need to send some ether");
      require(_amountToOrigin <= salesBalance, "Not enough tokens in the reserve");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, _amountToOrigin);
      emit OwnerWithdraw(_strphaseOfsales[phaseIndex],  _amountToOrigin);

    }

    function returnTokentoOriginAll() public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(salesBalance > 0, "You need to send some ether");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, salesBalance);
      emit OwnerWithdraw(_strphaseOfsales[phaseIndex],  salesBalance);

    }

    fallback() external payable {
    }

    receive() external payable {
    }

}