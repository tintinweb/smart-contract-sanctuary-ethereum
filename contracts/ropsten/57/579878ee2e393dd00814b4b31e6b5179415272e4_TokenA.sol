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

    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap private holders;

    uint256  minHoldingAmount = 1 * 10 **18;  // 6000000 * 10 **18

    uint256  tokenASupply = 168016801680 * 10 ** 18;

    uint256  preSaletotalSupply = 43771200000 * 10 ** 18;

    address  public marketingWallet;

    address  public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address  public peggedBTC;

    uint256  public tokenPrice = 100000000000000000;

    // sell tax
    uint256  public sellDividendPer = 8;

    uint256  public sellMarketingPer = 2;

    uint256  public sellDeadPer = 1;

    uint256  public sellLiquidityPer = 4;

    // buy tax
    uint256  public buyDividendPer = 5;

    uint256  public buyMarketingPer = 3;

    uint256  public buyDeadPer = 1;

    uint256  public buyLiquidityPer = 3;

    uint256 public maxLength = 9999;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event Sell(address indexed seller, uint256 amount, uint256 time);

    event Buy(address indexed buyer, uint256 amount, uint256 time);

    constructor (address preSale, address teamWallet, address developmentWallet, address airdropWallet, address lockerWallet, address presaleAndLiquidity)  ERC20("PiratePennies", "PRP") {
        _mint(preSale, preSaletotalSupply);  // To create a launchpad on pinksale

        _mint(developmentWallet, ((tokenASupply * 4)/100));
        _mint(teamWallet, ((tokenASupply * 5)/100));
        _mint(airdropWallet, ((tokenASupply * 15)/100)); 
        _mint(lockerWallet, ((tokenASupply * 20)/100));
        _mint(presaleAndLiquidity, ((tokenASupply * 26)/100));  

       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
       uniswapV2Router = _uniswapV2Router;              
    }

    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return tokenASupply;
    }

    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setMinHoldingAmount(uint256 amount) public onlyOwner {
        minHoldingAmount = amount;
    }

    function setDeadWallet(address account) public onlyOwner {
        deadWallet = account;
    }

    function setMarketingWallet(address account) public onlyOwner {
        marketingWallet = account;
    }

    function setPeggedBTC(address account) public onlyOwner {
        peggedBTC = account;
    }

    function setMaxLength(uint256 amount) public onlyOwner {
        maxLength = amount;
    }

    function setBuyTaxes(uint256 liquidity, uint256 dividendFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
        buyDividendPer = dividendFee;
        buyLiquidityPer = liquidity;
        buyMarketingPer = marketingFee;
        buyDeadPer = deadFee;
    }

    function setSellTaxes(uint256 liquidity, uint256 dividendFee, uint256 marketingFee, uint256 deadFee) external onlyOwner {
        sellDividendPer = dividendFee;
        sellLiquidityPer = liquidity;
        sellMarketingPer = marketingFee;
        sellDeadPer = deadFee;
    } 

    function sell(uint256 amount) public {
        uint256 max;
        require(balanceOf(msg.sender) >= amount, "Not enough balance");   
        transfer(address(this), amount - (amount * sellDeadPer)/100);
        transfer(deadWallet, (amount * sellDeadPer)/100);
        uint256[] memory amts = swapTokensForEth((amount * sellLiquidityPer / 2) / 100); 
        uint256[] memory marketingAmt = swapTokensForEth((amount * sellMarketingPer) / 100); 
        uint256 dividedTax = ((amount * sellDividendPer) / 100) /  EnumerableMap.length(holders);

        if(EnumerableMap.length(holders) < maxLength ){
            max = EnumerableMap.length(holders);
        } else{
            max = maxLength;
        }
        for(uint256 i = 0; i < max; i++){
            (address holder, ) = EnumerableMap.at(holders, i);
            swapExactTokensForTokens(dividedTax, holder);
        }                
        addLiquidity( (amount * sellLiquidityPer / 2) /100, amts[1]);
        payable(msg.sender).transfer((tokenPrice * amount)/10**18);
        payable(marketingWallet).transfer(marketingAmt[1]);
        emit Sell(msg.sender, amount, block.timestamp);
    }

    function buy(uint256 amount) public payable{
        uint256 max;
        require(msg.value  >= (tokenPrice * amount)/10**18, "Less Amount");
        _transfer(address(this), msg.sender, amount - ((amount * (buyLiquidityPer + buyMarketingPer + buyDividendPer)) / 100));
        transfer(deadWallet, (amount * buyDeadPer)/100);
        uint256[] memory amts = swapTokensForEth((amount * buyLiquidityPer / 2) / 100); 
        uint256[] memory marketingAmt = swapTokensForEth((amount * buyMarketingPer) / 100);
        uint256 dividedTax = ((amount * buyDividendPer) / 100) /  EnumerableMap.length(holders);
        if(EnumerableMap.length(holders) < maxLength ){
            max = EnumerableMap.length(holders);
        } else{
            max = maxLength;
        }
        for(uint256 i = 0; i < max; i++){
            (address holder, ) = EnumerableMap.at(holders, i);
            swapExactTokensForTokens(dividedTax, holder);
        }
        addLiquidity( (amount * buyLiquidityPer /2)/100, amts[1]);
        payable(marketingWallet).transfer(marketingAmt[1]);
        emit Buy(msg.sender, amount, block.timestamp);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {     
        if(balanceOf(sender) >= minHoldingAmount){ 
            if(!sender.isContract())   {
                EnumerableMap.set(holders, sender, balanceOf(sender));
            }                          
        }else{
            EnumerableMap.remove(holders, sender);   
        }
        if(balanceOf(recipient) >= minHoldingAmount){
            if(!recipient.isContract())   {
                EnumerableMap.set(holders, recipient, balanceOf(recipient));
            }
        }else{
            EnumerableMap.remove(holders, recipient);   
        }
        super._transfer(sender, recipient, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint[] memory amounts){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] =uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        amounts =uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        return amounts;
    }

    function swapExactTokensForTokens(uint256 tokenAmount, address account)private returns (uint[] memory amounts){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = peggedBTC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        amounts =uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
        return amounts;
    }

    receive() external payable {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function totalHolders() public view returns (uint256){
        return EnumerableMap.length(holders);
    }

    function deposit() public onlyOwner payable{}
   
}