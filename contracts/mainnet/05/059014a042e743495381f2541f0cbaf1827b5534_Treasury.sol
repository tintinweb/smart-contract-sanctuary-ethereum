/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

/**
 * SPDX-License-Identifier: unlicensed
 */

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

abstract contract Auth {
    address internal _owner;
    mapping(address => bool) public isAuthorized;

    constructor(address owner) {
        _owner = owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Auth: owner only");
        _;
    }

    modifier authorized() {
        require(isAuthorized[msg.sender], "Auth: authorized only");
        _;
    }

    function setAuthorization(address address_, bool authorization) public onlyOwner {
        isAuthorized[address_] = authorization;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address payable owner) public onlyOwner {
        _owner = owner;
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
}

contract Treasury is Auth {
    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private weth;
    address private token;

    constructor(address tokenAddress) Auth(msg.sender) {
        weth = IUniswapV2Router(router).WETH();
        token = tokenAddress;
        IERC20(token).approve(router, type(uint).max);
    }

    function withdraw(address to, uint amount, uint minimum, uint gasFee, uint deadline) external authorized {
        if (gasFee == 0) {
            IERC20(token).transfer(to, amount);
        } else {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = weth;

            uint balance = IERC20(token).balanceOf(address(this));

            IUniswapV2Router(router).swapTokensForExactETH(gasFee, amount, path, msg.sender, deadline);

            uint remaining = amount - (balance - IERC20(token).balanceOf(address(this)));

            require(remaining >= minimum, "$VXON Treasury: insufficient amount");

            IERC20(token).transfer(to, remaining);
        }
    }
}