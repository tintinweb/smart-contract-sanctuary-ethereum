/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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
}

contract Vaccine{
    
    address public owner;

    
    mapping(string => address) private vaccineManufacturer;
    mapping(string => uint256) private manufactureDate;
    mapping(string => uint256) private expiryDate;
    mapping(string => string) private typeVaccine;

    mapping(address => bool) public isManufacturer;

    constructor() public {
        owner = msg.sender;
    }
    
    function addManufacturer(address _account) public {
        require(msg.sender == owner, "Only contract creator can redistribute");

        isManufacturer[_account] = true;
    }

    function addVaccine(string memory _vaccineCode,uint256 _manufactureDate,uint256 _expiryDate,string memory _typeVaccine) public {
        require(isManufacturer[msg.sender] == true, "Only Manufactuer may add Vaccine");

        vaccineManufacturer[_vaccineCode] = msg.sender;
        manufactureDate[_vaccineCode] = _manufactureDate;
        expiryDate[_vaccineCode] = _expiryDate;
        typeVaccine[_vaccineCode] = _typeVaccine;

    }

    function vaccineData(string memory _vaccineCode) public view returns(uint256)
    {
        return manufactureDate[_vaccineCode];
    }


}