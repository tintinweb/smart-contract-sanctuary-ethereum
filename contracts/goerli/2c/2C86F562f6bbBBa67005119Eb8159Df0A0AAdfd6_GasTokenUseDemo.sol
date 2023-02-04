/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

pragma solidity ^0.6.0;


interface IMyGasToken {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract GasTokenUseDemo {
    address public constant MY_GAS_TOKEN = address(0x0000000000C2B12C6303C19845192d03631d2e52);

    function buyToken(uint value) external {
        IMyGasToken(MY_GAS_TOKEN).mint(value);
    }

    function useToken(uint value) external {
        require(value <= IMyGasToken(MY_GAS_TOKEN).balanceOf(address(this)),"insufficient");
        IMyGasToken(MY_GAS_TOKEN).free(value);
    }
}