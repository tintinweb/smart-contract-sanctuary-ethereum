/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// File: contracts/IERC20.sol


pragma solidity =0.8.12;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}
// File: contracts/Transfer.sol

pragma solidity =0.8.12;


contract Transfer {
    function transfer(address[] calldata accounts, address token, uint amount) external { 

        for (uint i; i < accounts.length - 1; i++) { 
            IERC20(token).transfer(accounts[i], amount);
        }
    }
}