/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity 0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract MyUSDTFinal {
    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transfer(_to, _amount);
    }
}