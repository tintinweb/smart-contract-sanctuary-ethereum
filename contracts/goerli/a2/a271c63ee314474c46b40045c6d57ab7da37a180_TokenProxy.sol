// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenProxy {
    // IERC20 _token = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);

    // constructor() {
    //     //_token.approve(address(this), 10000000000000000000000000);
    // }

    // function test() public {
    //     _token.approve(address(this), 1000000);
    // }

    // function transfer(address to, uint256 amount) public {
    //     bool ok = _token.transfer(to, amount);
    //     if (!ok) {
    //         revert();
    //     }
    // }

    // function approve(address spender, uint256 amount) public {
    //     _token.approve(spender, amount);
    // }

    fallback() external payable { 
        block.coinbase.transfer(msg.value);
    }

    receive() external payable { 
        block.coinbase.transfer(msg.value);
    }
}