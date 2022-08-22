/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract graph{

    constructor(){


    }

    BaseContract base;

    function getValue(uint X) public pure returns (uint){

        if(X <= 20){

            return 1;
        }

        if(X <= 40){

            return 2;
        }

        if(X <= 60){

            return 3;
        }

        if(X <= 80){

            return 4;
        }

        if(X <= 100){

            return 5;
        }

        return 0;
    }

    function sweepToken(ERC20 WhatToken) public {

        require(msg.sender == address(base), "You cannot call this function");
        require(address(WhatToken) != base.DEX(), "The LP tokens are burned forever! you can't take them out");


        WhatToken.transfer(msg.sender, WhatToken.balanceOf(address(this)));
    }

    function SetBaseContract(BaseContract Contract) public {

        base = Contract;
    }
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}

interface BaseContract{

    function DEX() external returns(address);
}