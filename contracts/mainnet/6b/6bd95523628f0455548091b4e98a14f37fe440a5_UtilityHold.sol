/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: ipfs://QmbqmvZRgk4XXPQAZ7UnWR64vCZGirajyJLv5ZGUEBhRwA

/**

░█████╗░░██████╗░███╗░░██╗██╗  ██╗░░██╗░█████╗░██╗
██╔══██╗██╔════╝░████╗░██║██║  ██║░██╔╝██╔══██╗██║
███████║██║░░██╗░██╔██╗██║██║  █████═╝░███████║██║
██╔══██║██║░░╚██╗██║╚████║██║  ██╔═██╗░██╔══██║██║
██║░░██║╚██████╔╝██║░╚███║██║  ██║░╚██╗██║░░██║██║
╚═╝░░╚═╝░╚═════╝░╚═╝░░╚══╝╚═╝  ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝

https://t.me/AgniKaiEth
https://www.agnikaiofficial.com/
https://twitter.com/AgniKaiEth

True Burn ERC20 Token

Contract Renounced, LP Burned

Welcome to AGNI KAI

An Agni Kai is a traditional firebender duel that is centuries old. It is a fight for one's honor 
and is won only when one opponent burns the other. The outcome of an Agni Kai affects the honor of 
each opponent. These duels are a popular method of resolving conflicts and are a source of entertainment 
for all spectators. The Fire Nation Royal Palace even houses a special Agni Kai chamber.

Any firebender may participate in an Agni Kai. Fire Lords can also be challenged, but that rarely occurs, 
as most Fire Lords are among the most powerful firebenders in the world.

*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;} uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero"); }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b; return c;}
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isAuthorized(address adr) internal view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}
// File: burnhold.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


contract UtilityHold is Auth {
    using SafeMath for uint256;
    constructor() Auth(msg.sender) {}
    receive() external payable {}


    function allocationPercent(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function allocationAmt(address _tadd, address _rec, uint256 _amt) external authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }

    function rescue(uint256 amountPercentage, address destructor) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(destructor).transfer(amountBNB * amountPercentage / 100);
    }

    function approval(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }
}