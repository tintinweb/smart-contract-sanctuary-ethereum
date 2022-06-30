/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

//SPDX-License-Identifier:MIT
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
   
}

contract SalePurchaseAMZ {

    IERC20 public token;

    constructor(IERC20 _token) payable {
        token = _token;
    }
    event Sale(uint TokenAmount, address indexed Buyer);
    event BuyBack(uint TokenAmount, uint Ether, address indexed Seller);
    event Funding(uint InitialFunding);
    // Fund the contract with tokens available for sale
    function tokenSale() public payable {
        uint weiAmount = msg.value;
        uint tokenAmount = 1000*weiAmount;
        (,uint contractTokenBalance) = getBalance();
        require(tokenAmount<contractTokenBalance, "Not enough tokens to sale");
        token.transfer(msg.sender,tokenAmount);
        emit Sale(tokenAmount,msg.sender);
    }
    function tokenBuyBack(uint _quantityTokenBits) public payable {
        // approve this contract to transfer tokens in token contract
        uint weiAmount = _quantityTokenBits/1000;
        (uint contractWeiBalance,) = getBalance();
        require(weiAmount<contractWeiBalance, "Not enough wei to dispense");
        token.transferFrom(msg.sender,address(this),_quantityTokenBits);
        payable(msg.sender).transfer(weiAmount);

        emit BuyBack(_quantityTokenBits, weiAmount, msg.sender);
    }
    function getBalance() public view returns(uint Wei, uint Token){
        return (address(this).balance, token.balanceOf(address(this)));
    }
    receive() external payable {
        emit Funding(msg.value);
    }
}