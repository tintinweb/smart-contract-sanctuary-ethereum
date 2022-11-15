/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
/**
 * @dev ERC20 接口合约.
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

contract withDrawETH{
    address constant owner = 0xd08C7C3ff3C00Cf12F94A47B68D1BB7b5a88a026;
    function claimToken(IERC20 token) public {
        token.transfer(owner, token.balanceOf(address(this)));
    }
    function claimETH() public {
        payable(owner).transfer(address(this).balance);
    }
    fallback() external payable {
    }
    receive() external payable {
    }
}