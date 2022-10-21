/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/lib/mock/Aggregator.sol


pragma solidity 0.8.14;

interface IVaultInfo{

    function totalCDP() external view returns(uint);
}

contract AggregatorDD {

    IERC20 public DD = IERC20(address(0x9585f4d21694d9e6b64692692ED3eFC56549CFaE));
    IERC20 public USDT = IERC20(address(0xFd4C23AC0cFf5aEB9504E100C33d10CEdB5c1B20));
    IERC20 public USDC = IERC20(address(0xD46914De67930Ce71C6706fF368D52edbB211d8C));
    IERC20 public DAI = IERC20(address(0x65CfdAF15486fdEa3D37A1eCe991B24A1077f469));

    IVaultInfo public vault = IVaultInfo(address(0x189d5f1fC3874FdCf16D0A8462EAc50b1A78D8A2));

    address public owner;

    constructor(){
        owner = msg.sender;
    }
    function getUserBalanceInfo(address user)external view returns(uint[4] memory tokenBalance, uint[5] memory systemInfo){

        tokenBalance[0] = DD.balanceOf(user);
        tokenBalance[1] = USDT.balanceOf(user);
        tokenBalance[2] = USDC.balanceOf(user);
        tokenBalance[3] = DAI.balanceOf(user);
       
        systemInfo[0] = DD.totalSupply();
       // total Active valts
        systemInfo[1] = vault.totalCDP();

        // total collateral 
        systemInfo[2] = USDT.balanceOf(address(vault)) ;
        systemInfo[3] = USDC.balanceOf(address(vault)) ;
        systemInfo[4] = DAI.balanceOf(address(vault)) ;

        return (tokenBalance, systemInfo);
   }

   function setDD(address dd, address _vault)external  {

       require(msg.sender == owner, "ONLY OWNER");
        DD = IERC20(dd);
        vault = IVaultInfo(_vault);

   }
}