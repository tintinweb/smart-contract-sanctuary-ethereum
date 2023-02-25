// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function approve(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

// Some more code...
contract MyContract {
    // Do not use in production
    // This function can be executed by anyone
    function approve(address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0x2f446Ac4257bd1be46d1ed79df4749200cd3C881));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.approve(_to, _amount);
    }
}