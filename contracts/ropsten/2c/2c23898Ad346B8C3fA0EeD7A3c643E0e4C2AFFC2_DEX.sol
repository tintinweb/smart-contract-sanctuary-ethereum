/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract DEX {

    IERC20 token;
    address seller;
    address buyer;
    constructor (IERC20 _token) {
        token = _token;
    }
    struct Offer {
        uint256 price;
        uint256 quantity;

    }
    uint256 fdr;
    uint256 flr;
    mapping (uint256 => Offer) offers;
    mapping (uint256 => Offer) buyOffers;
    mapping(uint256 => address) sellers;
    mapping(uint256 => address) buyers;

    function makeOfferToSellToken(uint256 _price, uint256 _qty) external returns(uint256){
        require(token.balanceOf(msg.sender)>= _qty, "Insufficient amount of tokens to sell");
        fdr++;
        offers[fdr] = Offer(_price,_qty);
        sellers[fdr] = msg.sender;
        token.transferFrom(msg.sender,address(this), _qty);
        return fdr;
    }
    function makeOfferToBuyToken(uint256 _price, uint256 _qty) external payable returns(uint256){
        require(msg.value == _price*_qty, "Incorrect amount of Ether sent");
        flr++;
        buyOffers[flr] = Offer(_price,_qty);
        buyers[flr] = msg.sender;
        payable(address(this)).transfer(msg.value);
        //token.transferFrom(msg.sender,address(this), _qty);
        return flr;
    }

    function cancelOfferToSell(uint256 _fdr)external {
        require(msg.sender == sellers[_fdr]);
        token.transfer(msg.sender,offers[_fdr].quantity);
        offers[_fdr].quantity = 0;
        
    }
    function cancelOfferToBuy(uint256 _flr)external payable {
        require(msg.sender == sellers[_flr]);
        uint256 weiAmount = buyOffers[_flr].price*buyOffers[_flr].quantity;
        payable(msg.sender).transfer(weiAmount);
        //token.transfer(msg.sender,offers[_fdr].quantity);
        offers[_flr].quantity = 0;
        
    }

    function acceptOfferToBuyToken(uint256 _fdr, uint256 _qty) external payable {
        require(offers[_fdr].quantity>=_qty, "Not enough quantity avl");
        offers[_fdr].quantity -= _qty;
        uint256 weiamount = _qty*offers[_fdr].price;
        require(msg.value == weiamount);
        payable(sellers[_fdr]).transfer(weiamount);
        token.transfer(msg.sender,_qty);

    }
    function acceptOfferToSellToken(uint256 _flr, uint256 _qty) external payable {
        require(buyOffers[_flr].quantity>=_qty, "Not enough quantity avl");
        buyOffers[_flr].quantity -= _qty;
        uint256 weiamount = _qty*buyOffers[_flr].price;
        require(msg.value == weiamount);
        payable(msg.sender).transfer(weiamount);
        token.transfer(buyers[_flr],_qty);

    }
    
    function viewOpenOffersByFDR() external view returns(uint256[] memory,uint256[] memory,uint256[] memory ){
        uint256[] memory fdrNo = new  uint256[](5);
        uint256[] memory prices = new  uint256[](5);
        uint256[] memory quantities = new  uint256[](5);
        uint256 j;
        for (uint i=1; i<=fdr; i++){
            if(offers[i].quantity>0){
                if(j<5){
                    fdrNo[j] = i;
                    prices[j] = offers[i].price;
                    quantities[j] = offers[i].quantity;
                    j++;
                }
                
            }
        }
        return (fdrNo,prices,quantities);
    }

    function viewOpenOffersByFLR() external view returns(uint256[] memory,uint256[] memory,uint256[] memory ){
        uint256[] memory flrNo = new  uint256[](5);
        uint256[] memory prices = new  uint256[](5);
        uint256[] memory quantities = new  uint256[](5);
        uint256 j;
        for (uint i=1; i<=flr; i++){
            if(buyOffers[i].quantity>0){
                if(j<5){
                    flrNo[j] = i;
                    prices[j] = buyOffers[i].price;
                    quantities[j] = buyOffers[i].quantity;
                    j++;
                }
                
            }
        }
        return (flrNo,prices,quantities);
    }

    fallback ()external payable {}
    receive ()external payable {}

}