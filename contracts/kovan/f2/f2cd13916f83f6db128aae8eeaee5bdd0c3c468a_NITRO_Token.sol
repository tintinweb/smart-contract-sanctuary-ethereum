pragma solidity 0.8.12;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./IContract.sol";

contract NITRO_Token is ERC20, Ownable {
    constructor(address teamAddress_, address marketingAddress_) ERC20("NITRO", "$NITRO") {
        _mint(msg.sender, 5e27);
        
        teamAddress = teamAddress_;
        marketingAddress = marketingAddress_;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isPair[uniswapV2Pair] = true;
    }
    
    function setBPAddrss(address _bp) public onlyOwner {
        require(address(BP)== address(0), "$NITRO: Can only be initialized once");
        BP = BPContract(_bp);
    }
    
    function setBpEnabled() public onlyOwner {
        bpEnabled = true;
    }
    
    function setBotProtectionDisableForever() public onlyOwner {
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }
    
    // function to allow admin to enable trading..
    function enabledTrading() public onlyOwner {
        require(!tradingEnabled, "$NITRO: Trading already enabled..");
        tradingEnabled = true;
        liquidityAddedAt = block.timestamp;
    }
    
    // function to allow admin to remove an address from fee..
    function excludedFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    // function to allow admin to add an address for fees..
    function includedForFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    // function to allow users to check ad address is it an excluded from fee or not..
    function _isExcludedFromFee(address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }
    
    // function to allow users to check an address is pair or not..
    function _isPairAddress(address account) public view returns (bool) {
        return isPair[account];
    }
    
    // function to allow admin to add an address on pair list..
    function addPair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = true;
    }
    
    // function to allow admin to remove an address from pair address..
    function removePair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = false;
    }
    
    // function to allow admin to set team address..
    function setTeamAddress(address teamAdd) public onlyOwner {
        teamAddress = teamAdd;
    }
    
    // function to allow admin to set Marketing Address..
    function setMarketingAddress(address marketingAdd) public onlyOwner {
        marketingAddress = marketingAdd;
    }
    
    // function to allow admin to add an address on blacklist..
    function addOnBlacklist(address account) public onlyOwner {
        require(!isBlacklisted[account], "$NITRO: Already added..");
        require(canBlacklistOwner, "$NITRO: No more blacklist");
        isBlacklisted[account] = true;
    }
    
    // function to allow admin to remove an address from blacklist..
    function removeFromBlacklist(address account) public onlyOwner {
        require(isBlacklisted[account], "$NITRO: Already removed..");
        isBlacklisted[account] = false;
    }
    
    // function to allow admin to stop adding address to blacklist..
    function stopBlacklisting() public onlyOwner {
        require(canBlacklistOwner, "$NITRO: Already stoped..");
        canBlacklistOwner = false;
    }
    
    // function to allow admin to set maximum Tax amout..
    function setMaxTaxAmount(uint256 amount) public onlyOwner {
        maxTaxAmount = amount;
    }
    
    // function to allow admin to set all fees..
    function setFees(uint256 sellTeamFee_, uint256 sellLiquidityFee_) public onlyOwner {
        _teamFee = sellTeamFee_;
        _liquidityFee = sellLiquidityFee_;
    }
    
    // function to allow admin to enable Swap and auto liquidity function..
    function enableSwapAndLiquify() public onlyOwner {
        require(!swapAndLiquifyEnabled, "$NITRO: Already enabled..");
        swapAndLiquifyEnabled = true;
    }
    
    // function to allow admin to disable Swap and auto liquidity function..
    function disableSwapAndLiquify() public onlyOwner {
        require(swapAndLiquifyEnabled, "$NITRO: Already disabled..");
        swapAndLiquifyEnabled = false;
    }
    
    // function to allow admin to set first 5 block buy & sell fee..
    function set_first_5_B_Fee(uint256 _fee) public onlyOwner {
        _first_5_B_Fee = _fee;
    }

    function addApprover(address approver) public onlyOwner {
        _approver[approver] = true;
    }

    function burn(uint256 amount) public {
        require(amount > 0, "$NITRO: amount must be greater than 0");
        _burn(msg.sender, amount);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "$NITRO: amount must be greater than 0");
        require(recipient != address(0), "$NITRO: recipient is the zero address");
        require(tokenAddress != address(this), "$NITRO: Not possible to transfer $NITRO");
        IContract(tokenAddress).transfer(recipient, amount);
    }
    
    // function to allow admin to transfer BNB from this contract..
    function transferBNB(uint256 amount, address payable recipient) public onlyOwner {
        recipient.transfer(amount);
    }

    receive() external payable {
        
    }
}