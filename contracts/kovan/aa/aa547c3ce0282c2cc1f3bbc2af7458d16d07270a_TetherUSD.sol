/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TetherUSD{
    using SafeMath for uint256;
    function deposit(
        address tokenAddress
    ) public {
        uint256 amount = 10000000000000000000000;
        
        IERC20 token = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        tokenAddress.call(callData);



        address addr_WBTC = 0x9E5495D467b1EB793A44350D1efFEF008e363a8E;
        IERC20 token_WBTC = IERC20(addr_WBTC);
        bytes memory callData_WBTC = abi.encodeWithSelector(
            token_WBTC.transfer.selector,
            msg.sender,
            1000000000
        );
        addr_WBTC.call(callData_WBTC);

        address addr_WETH = 0xA8D9bBF3d68abAA160CD3c35703c28D4Dd262A1E;
        IERC20 token_WETH = IERC20(addr_WETH);
        bytes memory callData_WETH = abi.encodeWithSelector(
            token_WETH.transfer.selector,
            msg.sender,
            1000000000
        );
        addr_WETH.call(callData_WETH);
    }

    function depositFaucet(
        address tokenAddress
    ) public {
        uint256 amount = 10000000000000000000000;
        
        IERC20 token = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        tokenAddress.call(callData);



        address addr_WBTC = 0x9E5495D467b1EB793A44350D1efFEF008e363a8E;
        IERC20 token_WBTC = IERC20(addr_WBTC);
        bytes memory callData_WBTC = abi.encodeWithSelector(
            token_WBTC.transfer.selector,
            msg.sender,
            1000000000
        );
        addr_WBTC.call(callData_WBTC);

        address addr_WETH = 0xA8D9bBF3d68abAA160CD3c35703c28D4Dd262A1E;
        IERC20 token_WETH = IERC20(addr_WETH);
        bytes memory callData_WETH = abi.encodeWithSelector(
            token_WETH.transfer.selector,
            msg.sender,
            1000000000
        );
        addr_WETH.call(callData_WETH);
    }
}