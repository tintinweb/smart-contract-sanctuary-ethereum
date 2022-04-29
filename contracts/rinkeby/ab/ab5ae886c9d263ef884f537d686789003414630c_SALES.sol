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
    string phaseOfsales="ICO";
    address _owner;
    event Bought(string phase, uint256 amount);
    event Sold(string phase, uint256 amount);
    event OwnerWithdraw(string phase,uint256 amount);
    event bytesLog(bool sent,bytes data);

    constructor(IERC20 _tokenAddress,uint256 _usdPerEthRate,uint256 _initTokenPerUSDRate) public 
    {
        
        /*
            PhaseIndex: 
            0 = Private Seed Sales
            1 = ICO
            2 = CEX
            3 = DEX
        */
        phaseIndex = 0;

        require(_initTokenPerUSDRate > 0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rate[phaseIndex] = _initTokenPerUSDRate; //1200000000000000; //0.0012;
        usdPerEth = _usdPerEthRate;
        _owner=msg.sender;
        OwnerTokenAddress = address(_tokenAddress);
        
    }

    function getOwnerToken() public returns(address){
        bytes memory payload = abi.encodeWithSignature("_owner()","");  
        (bool success, bytes memory result)= address(this).call(payload);

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

    function setUsdPerEthRate(uint _usdPerEthRate) external onlyOwner {
        require(_usdPerEthRate>0,"Rate not found..");
        usdPerEth = _usdPerEthRate;
    }

    mapping (uint => uint256) rate;

    function setTokenPerWeiRate(uint _TokenPerWeiRate) external onlyOwner {
        require(_TokenPerWeiRate>0,"Rate not found..");
        rate[phaseIndex] = _TokenPerWeiRate;
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

    /*
      send ether and get tokens in exchange; 1 token == 1 ether

        ETH                 = 1000000000000000000 WEI
        ICO                 = 50000000000000000000000000000000 SANDO
        USD Values          = ICO *0.0012
                            = 60000000000 USD

        USD Per ETH         = 30947.9295115 USD
                            = 30948 USD

        MAX Values of ICO   = 1,938,740.6356561394690540531684775 ETH
                            = 1,938,740,635,656,139,469,054,053.1684775 WEI
                            = 1938740635656139469054053 WEI
        Price Rate          = 38774812713 WEI Per TOKEN

        Input SANDO Token   = (Input amount SANDO Toeken) * 38774812713
        Values of SANDO     = WEI

    */

    /*
     rate = (Price of usdc per ETH) / 
     send ether and get tokens in exchange; 1 ether = 1 token * rate
     */
    function buy() payable public 
    {
      uint256 amountTobuy = msg.value*rate[phaseIndex];
      uint256 salesBalance =  token.balanceOf(address(this)); //token.balanceOf(SalesWallet);
      require(amountTobuy > 0, "You need to send some ether");
      require(amountTobuy <= salesBalance, "Not enough tokens in the reserve");
      token.transfer(msg.sender, amountTobuy);
      emit Bought(phaseOfsales, amountTobuy);
    }

/*
    function sell(uint256 amount) public // send tokens to get ether back
    {
      require(amount > 0, "You need to sell at least some tokens");
      uint256 allowance = token.allowance(msg.sender, address(this));
      require(allowance >= amount, "Check the token allowance");
      token.transferFrom(msg.sender, address(this), amount);
      payable(msg.sender).transfer(amount*rate[phaseIndex]);
      emit Sold(phaseOfsales, amount*rate[phaseIndex]);
    }
*/
    function getBalanceWEI() external view returns(uint256){
        return address(this).balance;
    }

    function getValueOfSales() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function OwnerWithdrawAll() public onlyOwner noReentrant{
      payable(msg.sender).transfer(address(this).balance);
      emit OwnerWithdraw(phaseOfsales, address(this).balance);
    }

    function returnTokentoOrigin(uint256 _amountToOrigin) public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(_amountToOrigin > 0, "You need to send some ether");
      require(_amountToOrigin <= salesBalance, "Not enough tokens in the reserve");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, _amountToOrigin);
      emit OwnerWithdraw(phaseOfsales,  _amountToOrigin);

    }

    function returnTokentoOriginAll() public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(salesBalance > 0, "You need to send some ether");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, salesBalance);
      emit OwnerWithdraw(phaseOfsales,  salesBalance);

    }

    fallback() external payable {
    }

    receive() external payable {
    }

}