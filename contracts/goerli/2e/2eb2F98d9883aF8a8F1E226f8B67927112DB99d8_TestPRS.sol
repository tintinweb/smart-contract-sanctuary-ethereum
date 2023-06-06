// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IPulseX.sol";
import "./Distributor.sol";

contract TestPRS is ERC20, Ownable {

	uint256[] public reflectionFee;
	uint256[] public burnFee;
	
	uint256 public swapTokensAtAmount;
	uint256 public distributorGas;
	
	IPulseXRouter public pulseXRouter;
    address public pulseXPair;
	address public burnAddress;
	Distributor distributor;
	
	bool private swapping;
	bool public distributionEnabled;
	
	mapping (address => bool) isDividendExempt;
	mapping (address => bool) public isExcludedFromFee;
	mapping (address => bool) public isAutomatedMarketMakerPairs;
	
	event AccountExcludeFromFee(address account, bool status);
	event SwapTokensAmountUpdated(uint256 amount);
	event AutomatedMarketMakerPairUpdated(address pair, bool value);
	event BurnFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);
    event ReflectionFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);

	constructor(address owner) ERC20("TestPRS", "PRS") {
	
	   burnAddress = address(0x0000000000000000000000000000000000000369);
	   pulseXRouter = IPulseXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pulseXPair = IPulseXFactory(pulseXRouter.factory()).createPair(address(this), pulseXRouter.WETH());
	   
	   distributor = new Distributor();
	   
	   reflectionFee.push(200);
	   reflectionFee.push(200);
	   reflectionFee.push(0);
	   
	   burnFee.push(100);
	   burnFee.push(100);
	   burnFee.push(0);
	   
	   isExcludedFromFee[address(owner)] = true;
       isExcludedFromFee[address(this)] = true;
	   
	   isDividendExempt[address(pulseXPair)] = true;
       isDividendExempt[address(this)] = true;
	   isDividendExempt[address(burnAddress)] = true;
	   
	   isAutomatedMarketMakerPairs[address(pulseXPair)] = true;   
	   swapTokensAtAmount = 1555369 * (10 ** 18);
	   distributorGas = 250000;
	   
	   distributionEnabled = true;
	   _mint(address(owner), 1555369000000 * (10 ** 18));
    }
	
	receive() external payable {}
	
	function excludeFromFee(address account, bool status) external onlyOwner {
	   require(isExcludedFromFee[account] != status, "Account is already the value of 'status'");
	   
	   isExcludedFromFee[account] = status;
	   emit AccountExcludeFromFee(account, status);
	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	    require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10 ** 18), "Minimum `500` token per swap required");
		
		swapTokensAtAmount = amount;
		emit SwapTokensAmountUpdated(amount);
  	}
	
	function setReflectionFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(burnFee[0] + buy  <= 1000 , "Max fee limit reached for 'BUY'");
		require(burnFee[1] + sell <= 1000 , "Max fee limit reached for 'SELL'");
		require(burnFee[2] + p2p  <= 1000 , "Max fee limit reached for 'P2P'");
		
		reflectionFee[0] = buy;
		reflectionFee[1] = sell;
		reflectionFee[2] = p2p;
		emit ReflectionFeeUpdated(buy, sell, p2p);
	}
	
	function setBurnFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(reflectionFee[0] + buy  <= 1000 , "Max fee limit reached for 'BUY'");
		require(reflectionFee[1] + sell <= 1000 , "Max fee limit reached for 'SELL'");
		require(reflectionFee[2] + p2p  <= 1000 , "Max fee limit reached for 'P2P'");
		
		burnFee[0] = buy;
		burnFee[1] = sell;
		burnFee[2] = p2p;
		emit BurnFeeUpdated(buy, sell, p2p);
	}
	
	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != address(0), "Zero address");
		
		isAutomatedMarketMakerPairs[address(pair)] = value;
		emit AutomatedMarketMakerPairUpdated(pair, value);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20){      
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (canSwap && !swapping && isAutomatedMarketMakerPairs[recipient]) 
		{
			swapping = true;
			swapTokensForPLS(swapTokensAtAmount);
			distributor.deposit{value: address(this).balance};
			swapping = false;
        }
		
		if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) 
		{
            super._transfer(sender, recipient, amount);
        }
		else 
		{
		    (uint256 txnBurnFee, uint256 txnReflectionFee) = collectFee(amount, isAutomatedMarketMakerPairs[recipient], !isAutomatedMarketMakerPairs[sender] && !isAutomatedMarketMakerPairs[recipient]);
			if(txnBurnFee > 0) 
			{
			    super._transfer(sender, address(burnAddress), txnBurnFee);
			}
			if(txnReflectionFee > 0) 
			{
			    super._transfer(sender, address(this), txnReflectionFee);
			}
			super._transfer(sender, recipient, amount - txnBurnFee - txnReflectionFee);
        }
		
		if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
		if(distributionEnabled) 
		{
		   try distributor.process(distributorGas) {} catch {}
		}
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256, uint256) {
        uint256 neBurnFee = amount * (p2p ? burnFee[2] : sell ? burnFee[1] : burnFee[0]) / 10000;
		uint256 newReflectionFee = amount * (p2p ? reflectionFee[2] : sell ? reflectionFee[1] : reflectionFee[0]) / 10000;
        return (neBurnFee, newReflectionFee);
    }
	
	function swapTokensForPLS(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pulseXRouter.WETH();
		
        _approve(address(this), address(pulseXRouter), tokenAmount);
        pulseXRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function setIsDividendExempt(address holder, bool status) external onlyOwner {
       isDividendExempt[holder] = status;
       if(status)
	   {
            distributor.setShare(holder, 0);
       }
	   else
	   {
            distributor.setShare(holder, balanceOf(holder));
       }
    }
	
	function setDistributionStatus(bool status) external onlyOwner {
        distributionEnabled = status;
    }
	
	function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(minPeriod, minDistribution);
    }
	
	function setDistributorGas(uint256 gas) external onlyOwner {
       require(gas < 750000, "Gas is greater than limit");
       distributorGas = gas;
    }
}