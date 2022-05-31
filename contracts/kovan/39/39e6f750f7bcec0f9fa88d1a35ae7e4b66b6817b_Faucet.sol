/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


/**
 * @dev signature of external (deployed) contract (ERC20 token)
 * only methods we will use
 */
interface ERC20Token {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals()  external view returns (uint8);
  
}

contract Faucet {
    ERC20Token token;
    constructor (address tokenAddress)  {
            token = ERC20Token(tokenAddress);

    }

    function getFree1000Tokens() external {
         try token.transfer(msg.sender, 1000e18) returns (bool result) { 
            require(result,"transfer failed, out of tokens?");
           
        } catch {
            require(false,"transfer failed, out of tokens?");
        }
    }

}