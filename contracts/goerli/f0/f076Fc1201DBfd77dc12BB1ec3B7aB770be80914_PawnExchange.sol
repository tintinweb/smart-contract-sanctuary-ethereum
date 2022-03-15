// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // openzeppelin 4.5 (for solidity 0.8.x)

contract PawnExchange{
    
    struct Offer{
        uint amount;
        address maker;
    }
    struct OrderBook{
        uint higherPrice;
        uint lowerPrice;
        
        mapping (uint => Offer) offers;
        uint offerPointer;
        uint offerLength;
    }
    struct Token {
        address tokenContract;
        mapping (uint => OrderBook) buyBook;
        uint maxBuyPrice;
        uint minBuyPrice;
        uint amountBuyPrices;
        
        mapping (uint => OrderBook) sellBook;
        uint minSellPrice;
        uint maxSellPrice;
        uint amountSellPrice;
    }
    
    mapping (address=>Token) tokenList;
    
    mapping (address => uint) ethBalance;
    
    mapping (address => mapping(address=>uint)) tokenBalance;
    
    function buyToken(address _token, uint _price, uint _amount) public{

        Token storage loadedToken = tokenList[_token];
        uint ethRequired = _price*_amount;
        
        require(ethRequired>=_amount);
        require(ethRequired>=_price);
        require(ethBalance[msg.sender]>=ethRequired);
        require(ethBalance[msg.sender]-ethRequired>=0);
        require(ethBalance[msg.sender]-ethRequired<=ethBalance[msg.sender]);
        ethBalance[msg.sender]-=ethRequired;
        
        if (loadedToken.amountSellPrice==0||loadedToken.minSellPrice>=_price){
            storeBuyOrder(_token, _price, _amount, msg.sender);
        } else { //execute order
            uint ethAmount = 0;
            uint remainingAmount = _amount;
            uint buyPrice = loadedToken.minSellPrice;
            uint offerPointer;
            while(buyPrice<=_price&&remainingAmount>0){
                offerPointer = loadedToken.sellBook[buyPrice].offerPointer;
                while(offerPointer <= loadedToken.sellBook[buyPrice].offerLength && remainingAmount >0){
                    uint volumeAtPointer = loadedToken.sellBook[buyPrice].offers[offerPointer].amount;
                    if(volumeAtPointer<=remainingAmount){
                        ethAmount=volumeAtPointer*buyPrice;
                        require(ethBalance[msg.sender]>=ethAmount);
                        require(ethBalance[msg.sender]-ethAmount<=ethBalance[msg.sender]);
                        ethBalance[msg.sender]-=ethAmount;
                        tokenBalance[msg.sender][_token]+=volumeAtPointer;
                        loadedToken.sellBook[buyPrice].offers[offerPointer].amount=0;
                        ethBalance[loadedToken.sellBook[buyPrice].offers[offerPointer].maker]+=ethAmount;
                        loadedToken.sellBook[buyPrice].offerPointer++;
                        remainingAmount-=volumeAtPointer;
                    }else{
                        require(loadedToken.sellBook[buyPrice].offers[offerPointer].amount>remainingAmount);
                        ethAmount=remainingAmount*buyPrice;
                        require(ethBalance[msg.sender]-ethAmount<=ethBalance[msg.sender]);
                        ethBalance[msg.sender]-=ethAmount;
                        loadedToken.sellBook[buyPrice].offers[offerPointer].amount-=remainingAmount;
                        ethBalance[loadedToken.sellBook[buyPrice].offers[offerPointer].maker]+=ethAmount;
                        tokenBalance[msg.sender][_token]+=remainingAmount;
                        remainingAmount=0;
                    }
                    
                    if(offerPointer==loadedToken.sellBook[buyPrice].offerLength&&loadedToken.sellBook[buyPrice].offers[offerPointer].amount==0){
                        loadedToken.amountSellPrice--;
                        if(buyPrice==loadedToken.sellBook[buyPrice].higherPrice||loadedToken.sellBook[buyPrice].higherPrice==0){
                            loadedToken.minSellPrice=0;
                        }else{
                            loadedToken.minSellPrice=loadedToken.sellBook[buyPrice].higherPrice;
                            loadedToken.sellBook[loadedToken.sellBook[buyPrice].higherPrice].lowerPrice=0;
                        }
                    }
                    offerPointer++;
                }
                buyPrice=loadedToken.minSellPrice;
            }
            if (remainingAmount>0){
                buyToken(_token, _price, remainingAmount);
            }
        }
    }
    
    function sellToken(address _token, uint _price, uint _amount) public{
        Token storage loadedToken = tokenList[_token];
        uint ethRequired = _price*_amount;
        
        require(ethRequired>=_amount);
        require(ethRequired>=_price);
        require(tokenBalance[msg.sender][_token]>=_amount);
        require(tokenBalance[msg.sender][_token]-_amount>=0);
        require(ethBalance[msg.sender]+ethRequired>=ethBalance[msg.sender]);
        
        tokenBalance[msg.sender][_token]-=_amount;
        
        if(loadedToken.amountBuyPrices==0||loadedToken.maxBuyPrice<_price){
            storeSellOrder(_token, _price, _amount, msg.sender);
        }else {
            uint sellPrice = loadedToken.maxBuyPrice;
            uint remainingAmount=_amount;
            uint offerPointer;
            while (sellPrice>=_price && remainingAmount > 0){
                offerPointer = loadedToken.buyBook[sellPrice].offerPointer;
                while(offerPointer<=loadedToken.buyBook[sellPrice].offerLength && remainingAmount>0){
                    uint volumeAtPointer = loadedToken.buyBook[sellPrice].offers[offerPointer].amount;
                    if (volumeAtPointer<=remainingAmount){
                        uint ethRequiredNow = volumeAtPointer*sellPrice;
                        require(tokenBalance[msg.sender][_token]>=volumeAtPointer);
                        require(tokenBalance[msg.sender][_token]-volumeAtPointer>=0);
                        tokenBalance[msg.sender][_token]-=volumeAtPointer;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token]+=volumeAtPointer;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount=0;
                        ethBalance[msg.sender]+=ethRequiredNow;
                        loadedToken.buyBook[sellPrice].offerPointer++;
                        remainingAmount-=volumeAtPointer;
                    }else{
                        require(volumeAtPointer-remainingAmount>0);
                        ethRequired = remainingAmount*sellPrice;
                        require(tokenBalance[msg.sender][_token]>=remainingAmount);
                        tokenBalance[msg.sender][_token]-=remainingAmount;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount-=remainingAmount;
                        ethBalance[msg.sender]+=ethRequired;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token]+=remainingAmount;
                        remainingAmount=0;
                    }
                    
                    if(offerPointer==loadedToken.buyBook[sellPrice].offerLength && loadedToken.buyBook[sellPrice].offers[offerPointer].amount==0){
                        loadedToken.amountBuyPrices--;
                        if (sellPrice==loadedToken.buyBook[sellPrice].lowerPrice || loadedToken.buyBook[sellPrice].lowerPrice==0){
                        loadedToken.maxBuyPrice=0;
                        }else {
                            loadedToken.maxBuyPrice=loadedToken.buyBook[sellPrice].lowerPrice;
                            loadedToken.buyBook[loadedToken.buyBook[sellPrice].lowerPrice].higherPrice=loadedToken.maxBuyPrice;
                        }
                    }
                    offerPointer++;
                }
                sellPrice=loadedToken.maxBuyPrice;
            }
            if (remainingAmount>0){
                sellToken(_token, _price, remainingAmount);
            }
        }
    }
    
    function storeSellOrder(address _token, uint _price, uint _amount, address _maker) private{
        tokenList[_token].sellBook[_price].offerLength++;
        tokenList[_token].sellBook[_price].offers[tokenList[_token].sellBook[_price].offerLength] = Offer(_amount, _maker);
        
        if (tokenList[_token].sellBook[_price].offerLength==1){
            tokenList[_token].sellBook[_price].offerPointer=1;
            tokenList[_token].amountSellPrice++;
            
            uint currentSellPrice = tokenList[_token].minSellPrice;
            uint highestSellPrice = tokenList[_token].maxSellPrice;
            
            if (highestSellPrice==0 || highestSellPrice<_price){
                if(currentSellPrice==0){
                    tokenList[_token].minSellPrice=_price;
                    tokenList[_token].sellBook[_price].higherPrice=0;
                    tokenList[_token].sellBook[_price].lowerPrice=0;
                }else{
                    tokenList[_token].sellBook[highestSellPrice].higherPrice = _price;
                    tokenList[_token].sellBook[_price].lowerPrice = highestSellPrice;
                    tokenList[_token].sellBook[_price].higherPrice = _price;
                }
                tokenList[_token].maxSellPrice=_price;
            }else if(currentSellPrice>_price){
                tokenList[_token].sellBook[currentSellPrice].lowerPrice=_price;
                tokenList[_token].sellBook[_price].higherPrice=currentSellPrice;
                tokenList[_token].sellBook[_price].lowerPrice=0;
                tokenList[_token].minSellPrice=_price;
            }else{
                uint sellPrice = tokenList[_token].minSellPrice;
                bool finished=false;
                while(sellPrice>0 && !finished){
                    if(sellPrice<_price&&tokenList[_token].sellBook[sellPrice].higherPrice>_price){
                        tokenList[_token].sellBook[_price].lowerPrice = sellPrice;
                        tokenList[_token].sellBook[_price].higherPrice = tokenList[_token].sellBook[sellPrice].higherPrice;
                        
                        tokenList[_token].sellBook[tokenList[_token].sellBook[sellPrice].higherPrice].lowerPrice=_price;
                        
                        tokenList[_token].sellBook[sellPrice].higherPrice = _price;
                    }
                    sellPrice=tokenList[_token].sellBook[sellPrice].higherPrice;
                }
            }
        }
    }
    
    function storeBuyOrder(address _token, uint _price, uint _amount, address _maker) private{
        tokenList[_token].buyBook[_price].offerLength++;
        tokenList[_token].buyBook[_price].offers[tokenList[_token].buyBook[_price].offerLength]=Offer(_amount, _maker);
        
        if(tokenList[_token].buyBook[_price].offerLength==1){
            tokenList[_token].buyBook[_price].offerPointer=1;
            tokenList[_token].amountBuyPrices++;
            
            uint currentBuyPrice = tokenList[_token].maxBuyPrice;
            uint lowestBuyPrice = tokenList[_token].minBuyPrice;
            
            if(lowestBuyPrice==0||lowestBuyPrice>_price){
                if (currentBuyPrice==0){
                    tokenList[_token].maxBuyPrice=_price;
                    tokenList[_token].buyBook[_price].higherPrice = _price;
                    tokenList[_token].buyBook[_price].lowerPrice = 0;
                }else{
                    tokenList[_token].buyBook[lowestBuyPrice].lowerPrice=_price;
                    tokenList[_token].buyBook[_price].higherPrice=lowestBuyPrice;
                    tokenList[_token].buyBook[_price].lowerPrice=0;
                }
                tokenList[_token].minBuyPrice=_price;
            }else if(currentBuyPrice<_price){
                tokenList[_token].buyBook[currentBuyPrice].higherPrice=_price;
                tokenList[_token].buyBook[_price].higherPrice=_price;
                tokenList[_token].buyBook[_price].lowerPrice=currentBuyPrice;
                tokenList[_token].maxBuyPrice=_price;
            }else{
                uint buyPrice = tokenList[_token].maxBuyPrice;
                bool finished=false;
                while(buyPrice>0&&!finished){
                    if(buyPrice<_price && tokenList[_token].buyBook[buyPrice].higherPrice>_price){
                        tokenList[_token].buyBook[_price].lowerPrice=buyPrice;
                        tokenList[_token].buyBook[_price].higherPrice=tokenList[_token].buyBook[buyPrice].higherPrice;
                        tokenList[_token].buyBook[tokenList[_token].buyBook[buyPrice].higherPrice].lowerPrice=_price;
                        tokenList[_token].buyBook[buyPrice].higherPrice=_price;
                        finished=true;
                    }
                    buyPrice=tokenList[_token].buyBook[buyPrice].lowerPrice;
                }
            }
        }
    }
    
    function removeOrder(address _token, bool isSellOrder, uint _price) public{
        Token storage loadedToken = tokenList[_token];
        if (isSellOrder){
            uint counter = loadedToken.sellBook[_price].offerPointer;
            while (counter <= loadedToken.sellBook[_price].offerLength){
                if (loadedToken.sellBook[_price].offers[counter].maker==msg.sender){
                    uint orderVolume = loadedToken.sellBook[_price].offers[counter].amount;
                    require(tokenBalance[msg.sender][_token]+orderVolume>=tokenBalance[msg.sender][_token]);
                    loadedToken.sellBook[_price].offers[counter].amount=0;
                    tokenBalance[msg.sender][_token]+=orderVolume;
                }
                counter++;
            }
        }else {
            uint counter = loadedToken.buyBook[_price].offerPointer;
            while (counter <= loadedToken.buyBook[_price].offerLength){
                if (loadedToken.buyBook[_price].offers[counter].maker==msg.sender){
                    uint orderVolume = loadedToken.buyBook[_price].offers[counter].amount*_price;
                    require(ethBalance[msg.sender]+orderVolume>=ethBalance[msg.sender]);
                    loadedToken.buyBook[_price].offers[counter].amount=0;
                }
                counter++;
            }
        }
    }
    
    function getSellOrders(address _token) public view returns(uint[] memory, uint[] memory){
        Token storage loadedToken = tokenList[_token];
        uint[] memory ordersPrices = new uint[](loadedToken.amountSellPrice);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountSellPrice);
        
        uint sellPrice = loadedToken.minSellPrice;
        uint counter = 0;
        
        if (loadedToken.minSellPrice>0){
            while(sellPrice<=loadedToken.maxSellPrice){
                
                
                 ordersPrices[counter] = sellPrice;
                 uint priceVolume = 0;
                 uint offerPointer = loadedToken.sellBook[sellPrice].offerPointer;
                
                while(offerPointer <=loadedToken.sellBook[sellPrice].offerLength){
                    priceVolume += loadedToken.sellBook[sellPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                ordersvolumes[counter]=priceVolume;
                if (sellPrice==loadedToken.sellBook[sellPrice].higherPrice){
                    break;
                }else{
                    sellPrice=loadedToken.sellBook[sellPrice].higherPrice;
                }
                counter++;
            }
        }
        return(ordersPrices, ordersvolumes);
    }
    
    function getBuyOrders(address _token) public view returns(uint[] memory, uint[] memory){
        Token storage loadedToken = tokenList[_token];
        uint[] memory ordersPrices = new uint[](loadedToken.amountBuyPrices);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountBuyPrices);
        
        uint buyPrice = loadedToken.minBuyPrice;
        uint counter = 0;
        
        if (loadedToken.maxBuyPrice>0){
            while(buyPrice<=loadedToken.maxBuyPrice){
                ordersPrices[counter]=buyPrice;
                uint priceVolume=0;
                uint offerPointer=loadedToken.buyBook[buyPrice].offerPointer;
                
                while(offerPointer<=loadedToken.buyBook[buyPrice].offerLength){
                    priceVolume+=loadedToken.buyBook[buyPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                
                ordersvolumes[counter] = priceVolume;
                
                if (buyPrice==loadedToken.buyBook[buyPrice].higherPrice){
                    break;
                }else{
                    buyPrice=loadedToken.buyBook[buyPrice].higherPrice;
                }
                counter++;
            }
        }
        
        return(ordersPrices, ordersvolumes);
    }
    
    receive() external payable {
        require(ethBalance[msg.sender]+msg.value>=ethBalance[msg.sender]);
        ethBalance[msg.sender]+=msg.value;
    }

    // function() external payable {
    //     require(ethBalance[msg.sender]+msg.value>=ethBalance[msg.sender]);
    //     ethBalance[msg.sender]+=msg.value;
    // }    
    
    function withdrawEth(uint _wei) public {
        require(ethBalance[msg.sender]-_wei>=0);
        require(ethBalance[msg.sender]-_wei<=ethBalance[msg.sender]);
        (bool sent, /*bytes memory data*/) = msg.sender.call{value: _wei}("");
        require(sent, "Failed to send Ether");
        ethBalance[msg.sender]-=_wei;
    }
    
    function depositToken(address _token, uint _amount) public {
        IERC20 tokenLoaded = IERC20(_token);
        require(tokenLoaded.allowance(msg.sender, address(this))>=_amount);
        require(tokenLoaded.transferFrom(msg.sender, address(this), _amount));
        tokenBalance[msg.sender][_token]+=_amount;
    }
    
    function withdrawToken(address _token, uint _amount) public {
        IERC20 tokenLoaded = IERC20(_token);
        require(tokenBalance[msg.sender][_token]-_amount>=0);
        require(tokenBalance[msg.sender][_token]-_amount<=tokenBalance[msg.sender][_token]);
        tokenBalance[msg.sender][_token]-=_amount;
        require(tokenLoaded.transfer(msg.sender, _amount));
    }
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}