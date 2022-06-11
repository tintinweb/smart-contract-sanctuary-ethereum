// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPTX.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract ICOTokenCrowdsale is ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;
    
    IPTX internal _token;
    
    bool public crowdsaleFinalized;
    bool public saleRefund;
    
    uint256 private icoCap;
    uint256 public soldTokens;
    
    // Address where funds are collected
    address payable private _wallet;
    
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    constructor (uint256 rate_, address token_, uint256 _icocap) 
    {
        _rate = rate_;
        _wallet = payable(msg.sender);
        _token = IPTX(token_); 
        crowdsaleFinalized = false;
        saleRefund = false;
        icoCap = _icocap;
        Ownable.init();
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return bool after setting the address where funds are collected.
     */
     
    function setWallet(address payable wallet_)public onlyOwner returns(bool) {
        require(wallet_ != address(0),"Invalid minter address!");
        _wallet = wallet_;
        return true;
    }
    
    /**
     * @return the address where funds are collected.
     */

    function wallet() public view returns (address payable) {
        return _wallet;
    }
    

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    function updateRate(uint256 rate_)public onlyOwner{
        _rate = rate_;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        
        require(!crowdsaleFinalized,"Crowdsale is finalized!");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(beneficiary == msg.sender, "Crowdsale: beneficiary is not the sender");
        require(msg.value != 0, "Crowdsale: weiAmount is 0");
        
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    }
    
    function finalizeCrowdsale() public onlyOwner{
        require(!crowdsaleFinalized,"Crowdsale is finalized!");
        crowdsaleFinalized = true;
    }
    
    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        require(soldTokens.add(tokenAmount) <= icoCap , "ICO limit reached");
        
        soldTokens = soldTokens.add(tokenAmount);
        _token.mint(beneficiary, tokenAmount);
    }
    
    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokens = weiAmount;
        tokens = tokens.mul(_rate);
        tokens = tokens.mul(1e16);
        tokens = tokens.div(1e18);
        return tokens;
        
    }
    
    /**
     * @dev Determines how ETH is forwarded to admin.
     */
    function adminWithdraw() public onlyOwner {
        _wallet.transfer(address(this).balance);
    }
    
    
}