/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// File: libs/IERC20.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
interface IERC20 {
	function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}
// File: mevtrap.sol

// File: mevtrap.sol


pragma solidity 0.8.17;

/*
Initial parameters:
token: 0x7df3b21371E59385db9BfcfA45301FFD659c43A0
price: 225311000000000
       
min_sale: 56327750000000000
*/

contract TenX{
    address private immutable owner;
    uint256 private price;
    uint256 private minSaleValue;
    address private asset;
    uint private m;
    IERC20 private tokenObj;
    
    constructor(address tokenAddr, uint256 _price, uint256 _minSale){
        /*Initalize the contract.*/
        (owner, minSaleValue, price, asset, m, tokenObj) = (payable(msg.sender), _minSale, _price, tokenAddr, 1, IERC20(tokenAddr));
    }

    function ms() internal view {
        if(msg.sender != owner) {
            revert();
        }

    }

    function updateMetadata(address _asset, uint256 _price, uint256 _minSale) external {
        /*
        Admin function for updating the token that we are giving away
        */
        ms();
        (price, asset, minSaleValue,tokenObj) = (_price, _asset, _minSale, IERC20(_asset));
    }

    function x10() external payable {
        /*

        Function to dispense tokens to lucky people.

        */
        if(m == 1){ 
            m = 2;
            uint256 quantity;
            require(msg.value > 0 && msg.value >= minSaleValue, "Cannot 10x 0!");
            quantity = (msg.value / price) * (10**tokenObj.decimals());
            //emit Purchase(msg.sender, quantity);
            tokenObj.transfer(msg.sender, quantity);
            m = 1;
            }
    }

    function recoverEth() external {
        /*
        Admin only function to withdraw ethereum.
        */
        ms();
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external {
        /*
        Admin only function to withdraw tokens.
        */
        ms();
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    receive() external payable {}
}