// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./EnumerableMap.sol";
import "./Address.sol";

contract TokenA is ERC20, Ownable{

    using Address for address;

    //Create EnumerableMap To store the address
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private holders;

    //MinHoldingAmount
    uint256  private minHoldingAmount = 1 * 10 **18;  // 6000000 * 10 **18
    //TokenASupply
    uint256  private tokenASupply = 168016801680 * 10 ** 18;
    //PreSaleSupply
    uint256  private preSaleTotalSupply = 43771200000 * 10 ** 18;

    //Marketing Wallet
    address  private marketingWallet;
    //Dead Wallet
    address  private deadWallet = 0x000000000000000000000000000000000000dEaD;
    //Pegged BTC Token
    address  private peggedBTC;
    //Token Price
    uint256  private tokenPrice = 100000000000000000;

    //Sell tax
    uint256  private sellDividendPer = 8;
    uint256  private sellMarketingPer = 2;
    uint256  private sellDeadPer = 1;
    uint256  private sellLiquidityPer = 4;

    //Buy tax
    uint256  private buyDividendPer = 5;
    uint256  private buyMarketingPer = 3;
    uint256  private buyDeadPer = 1;
    uint256  private buyLiquidityPer = 3;

    //Max length
    uint256 private maxLength = 9999;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    //Events
    event Sell(address indexed seller, uint256 amount, uint256 time);
    event Buy(address indexed buyer, uint256 amount, uint256 time);

    constructor (address _peggedBTCToken, address _preSaleWallet, address _teamWallet, address _developmentWallet, address _airdropWallet, address _lockerWallet, address _presaleAndLiquidity, address _marketingWallet) ERC20 ("PiratePennies", "PRP"){
        _mint(_preSaleWallet, preSaleTotalSupply);  // To create a launchpad on pinksale

        _mint(_developmentWallet, ((tokenASupply * 4) / 100));    // 4% tokens in development
        _mint(_teamWallet, ((tokenASupply * 5) / 100));           // 5% tokens in team
        _mint(_airdropWallet, ((tokenASupply * 15) / 100 ));      // 15% tokens in airdrop campaign
        _mint(_lockerWallet, ((tokenASupply * 20) / 100 ));       // 20% tokens in currency reserve and 30% tokens burned
        _mint(_presaleAndLiquidity, ((tokenASupply * 26) / 100));  // 26% tokens in presale and liquidity
         

       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

       // set the rest of the contract variables
       uniswapV2Router = _uniswapV2Router;
       marketingWallet     = _marketingWallet;   
       peggedBTC           = _peggedBTCToken;   

    }

    ///@dev Burn the tokens.
    ///@param _amount - Amount of PRP tokens.
    function burn(uint256 _amount) external  {
        _burn(msg.sender, _amount);
    }

    ///@dev Returns the tokenA total supply.
    function totalSupply() public view virtual override returns (uint256) {
        return tokenASupply;
    }

    ///@dev Change the token price.
    ///@param _price - Set the token price in wei.
    function setPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    ///@dev Change the min holding amount.
    ///@param _amount - Amount of PRP tokens.
    function setMinHoldingAmount(uint256 _amount) public onlyOwner {
        minHoldingAmount = _amount;
    }

    ///@dev Change the max length.
    ///@param _len - Set the length.
    function setMaxLength(uint256 _len) public onlyOwner {
        maxLength = _len;
    }

    ///@dev Sets the Buy tax.    
    ///@param _liquidityFee - Buy liquidity fees.
    ///@param _dividendFee  - Buy dividend (Pegged BTC) fees.
    ///@param _marketingFee - Buy marketingFee fees.
    ///@param _deadFee      - Buy deadFee fees.
    function setBuyTaxes(uint256 _liquidityFee, uint256 _dividendFee, uint256 _marketingFee, uint256 _deadFee) external onlyOwner {
        buyDividendPer = _dividendFee;
        buyLiquidityPer = _liquidityFee;
        buyMarketingPer = _marketingFee;
        buyDeadPer = _deadFee;
    }

    ///@dev Sets the Sell tax.    
    ///@param _liquidityFee - Sell liquidity fees.
    ///@param _dividendFee  - Sell dividend (Pegged BTC) fees.
    ///@param _marketingFee - Sell marketingFee fees.
    ///@param _deadFee      - Sell deadFee fees.
    function setSellTaxes(uint256 _liquidityFee, uint256 _dividendFee, uint256 _marketingFee, uint256 _deadFee) external onlyOwner {
        sellDividendPer = _dividendFee;
        sellLiquidityPer = _liquidityFee;
        sellMarketingPer = _marketingFee;
        sellDeadPer = _deadFee;
    } 

    ///@dev Sell the tokens. 
    ///@param _amount - Amount of PRP tokens.
    function sell(uint256 _amount) public {
        uint256 max;
        require(balanceOf(msg.sender) >= _amount, "Not enough balance");  
        // Transfer tokens from user  to contract address and sell tax deducted. 
        transfer(address(this), _amount - (_amount * sellDeadPer)/100);
        //Transfer dead per to deadWallet.
        transfer(deadWallet, (_amount * sellDeadPer)/100);
        //Swap the liquidityPer tokens for BNB
        uint256 amts = swapTokensForEth((_amount * sellLiquidityPer / 2) / 100); 
        //Swap the marketingPer tokens for BNB
        uint256 marketingAmt = swapTokensForEth((_amount * sellMarketingPer) / 100); 
        //Divide the dividend per equally according to holders length.
        uint256 dividedTax = ((_amount * sellDividendPer) / 100) /  EnumerableMap.length(holders);
        if(EnumerableMap.length(holders) < maxLength ){
            max = EnumerableMap.length(holders);
        } else{
            max = maxLength;
        }
        for(uint256 i = 0; i < max; i++){
            //Get the Enumerable Holder Address
            (address holder, ) = EnumerableMap.at(holders, i);
            // Swap PRP tokens to PeggedBTC and distribute to those holders who contain more than 6000000 PRP tokens
            swapExactTokensForTokens(dividedTax, holder);
        } 
        // Add liquidty               
        addLiquidity( (_amount * sellLiquidityPer / 2) / 100, amts);
        // Transfer BNB amount to seller.
        payable(msg.sender).transfer((tokenPrice * _amount) / 10 ** 18);
        //Transfer BNB amount in marketing wallet
        payable(marketingWallet).transfer(marketingAmt);
        emit Sell(msg.sender, _amount, block.timestamp);
    }

    ///@dev Buy the tokens. 
    ///@param _amount - Amount of PRP tokens.
    function buy(uint256 _amount) public payable{
        uint256 max;
        require(msg.value  >= (tokenPrice * _amount) / 10 ** 18, "Less _amount");
        // Transfer tokens from contract to user address and buy tax deducted.
        _transfer(address(this), msg.sender, _amount - ((_amount * (buyLiquidityPer + buyMarketingPer + buyDividendPer)) / 100));
        //Transfer dead per to deadWallet.
        transfer(deadWallet, (_amount * buyDeadPer)/100);
        //Swap the liquidityPer tokens for BNB
     
        uint256 amts = swapTokensForEth((_amount * buyLiquidityPer / 2) / 100); 
        //Swap the marketingPer tokens for BNB
        uint256 marketingAmt = swapTokensForEth((_amount * buyMarketingPer) / 100);
        //Divide the dividend per equally according to holders length.
        uint256 dividedTax = ((_amount * buyDividendPer) / 100) /  EnumerableMap.length(holders);
        if(EnumerableMap.length(holders) < maxLength ){
            max = EnumerableMap.length(holders);
        } else{
            max = maxLength;
        }
        for(uint256 i = 0; i < max; i++){
            //Get the Enumerable Holder Address
            (address holder, ) = EnumerableMap.at(holders, i); 
            // Swap PRP tokens to PeggedBTC and distribute to those holders who contain more than 6000000 PRP tokens
            swapExactTokensForTokens(dividedTax, holder);
        }
        // Add liquidty
        addLiquidity( (_amount * buyLiquidityPer / 2) / 100, amts);
        //Transfer BNB amount in marketing wallet
        payable(marketingWallet).transfer(marketingAmt);
        emit Buy(msg.sender, _amount, block.timestamp);
    }

    ///@dev Override the transfer internal function to set the holders in enumerable map who holds 6000000 PRP tokens.
    ///@param _sender - Cannot be the zero address.
    ///@param _recipient - Cannot be the zero address.
    ///@param _amount - Amount of PRP tokens.
    function _transfer(address _sender, address _recipient, uint256 _amount) internal override {  
        super._transfer(_sender, _recipient, _amount);  
        //Check if sender balance is greater than minholdamount. 
        if(balanceOf(_sender) >= minHoldingAmount){ 
            // check sender address is equal to contract address or not. If not, add sender address in enumerbale map
            if(!_sender.isContract())   {
                EnumerableMap.set(holders, _sender, balanceOf(_sender));
            }                          
        }else{
            EnumerableMap.remove(holders, _sender);           
        }
        //Check if recipient balance is greater than minholdamount. 
        if(balanceOf(_recipient) >= minHoldingAmount){
            if(!_recipient.isContract())   {
                // check recipient address is equal to contract address or not. If not, add sender address in enumerbale map
                EnumerableMap.set(holders, _recipient, balanceOf(_recipient));
            }
        }else{
            EnumerableMap.remove(holders, _recipient);   
        }        
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = address(this);
        path[1] =uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        amounts = uniswapV2Router.swapExactTokensForETH(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        return amounts[1];
    }

    function swapExactTokensForTokens(uint256 _tokenAmount, address _account)private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = peggedBTC;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            _account,
            block.timestamp
        );
       
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

     ///@dev Withdraw the Funds
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    ///@dev Returns the length of totalholders.
    function totalHolders() public view returns (uint256){
        return EnumerableMap.length(holders);
    }

    ///@dev Returns the price of tokens in wei.
    function price() public view returns (uint256){
        return tokenPrice;
    }

    ///@dev Returns the max length.
    function viewMaxLength() public view returns (uint256){
        return maxLength;
    }

    ///@dev Returns the marketing wallet address
    function viewMarketingWallet() public view returns (address){
        return marketingWallet;
    }

    ///@dev Returns the dead wallet address
    function viewDeadWallet() public view returns (address){
        return deadWallet;
    }

    ///@dev Returns the pegged BTC token address
    function viewPeggedBTCToken() public view returns (address){
        return peggedBTC;
    }

    ///@dev Returns the sell tax
    function viewSellTax() public view returns (uint256 dividend, uint256 liquidity, uint256 marketing, uint256 dead){
        return (sellDividendPer , sellLiquidityPer , sellMarketingPer , sellDeadPer);
    }

    ///@dev Returns the buy tax
    function viewBuyTax() public view returns (uint256 dividend, uint256 liquidity, uint256 marketing, uint256 dead){
        return (buyDividendPer , buyLiquidityPer , buyMarketingPer , buyDeadPer);
    }
   
}