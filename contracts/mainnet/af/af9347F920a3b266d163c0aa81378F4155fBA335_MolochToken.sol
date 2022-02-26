/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}

interface IMOLOCH { 
    function totalShares() external view returns (uint256);
    function totalLoot() external view returns (uint256);
    function memberAddressByDelegateKey(address user) external view returns (address);
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
}

contract MolochToken {
    IMOLOCH public moloch;
    string public constant name = 'DHCCO3 shares and loot';
    string public constant symbol = 'DHCCO3';
    uint256 public constant decimals = 18;

    constructor(address _moloch) {
        moloch = IMOLOCH(_moloch);
    }
    
    function totalSupply() public view returns (uint256) {
        return moloch.totalShares() + moloch.totalLoot() * (10 ** decimals);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 shares;
        uint256 loot;
        address memberAddress = moloch.memberAddressByDelegateKey(account);
        (,shares,loot,,,) = moloch.members(memberAddress);
        
        return shares + loot * (10 ** decimals);
    }

}