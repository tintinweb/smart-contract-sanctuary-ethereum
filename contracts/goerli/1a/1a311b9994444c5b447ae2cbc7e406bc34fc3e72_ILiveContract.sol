/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
interface IERC20{
   
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}

contract ILiveContract {
    address public erc20Address;
    address public adminReceiver;

    event Transfer( uint256 packageId, uint256 amount, address walletAddress, uint256 userId, address check);

    function setERC20Address(address _address) external {
        erc20Address = _address;
    }

    function setAdminReceiver(address _address) external {
        adminReceiver = _address;
    }

    function transferByWalletUser(
        uint256 packageId,
        uint256 userId,
        uint256 amount
    ) external {
        address sender = msg.sender;

        IERC20 erc20Token = IERC20(erc20Address);

        require(
            erc20Token.allowance(sender, address(this)) >= amount,
            "Allowance insuffice"
        );
        require(erc20Token.balanceOf(sender) >= amount, "Insuffice balance");

        erc20Token.transferFrom(sender, adminReceiver, amount);
        emit Transfer(packageId, amount, sender, userId, address(this));
    }
}