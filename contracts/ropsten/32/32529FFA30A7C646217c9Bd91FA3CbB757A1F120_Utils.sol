/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}
// ETH TESTNET = 0x32529FFA30A7C646217c9Bd91FA3CbB757A1F120
// ETH MAINNET = 0x2Be226d0D7c49e01e9f78A04fAc65D9ad45eaB5f
contract Utils {
    
    struct TokenInfo {
        address token;
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
        uint256 allowance;
    }
    
    function balances(address owner, address spender, address[] memory token) public view returns(uint256, TokenInfo[] memory) {
        
        TokenInfo[]memory info = new TokenInfo[](token.length);

        for(uint256 i = 0 ; i < token.length; i++) {
            info[i].token = token[i];
            info[i].name = IERC20(token[i]).name();
            info[i].symbol = IERC20(token[i]).symbol();
            info[i].decimals = IERC20(token[i]).decimals();
            info[i].balance = IERC20(token[i]).balanceOf(owner);
            info[i].allowance = IERC20(token[i]).allowance(owner, spender); 
        }
        return (owner.balance, info);
    }
   
  
}