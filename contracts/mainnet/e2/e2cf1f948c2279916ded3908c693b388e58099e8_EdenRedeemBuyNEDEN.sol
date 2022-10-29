/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

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

// File: contracts/call.sol

pragma solidity 0.8.17;


interface EDEN { 
	function setMetadataManager(address newMetadataManager) external returns (bool);
    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);
}

contract EdenRedeemBuyNEDEN{
    IERC20 NEDENtoken = IERC20(0x837f31811B51976b585b141B2ee39DA4C9BBc0AD);
    address public owner = 0x5C95123b1c8d9D8639197C81a829793B469A9f32;
    uint256 public fee = 300000000000000000000000000;
    // 30M $NEDEN to redeem

	function setMetadataManager(address newMetadataManager) public {
        require(msg.sender == owner);
		EDEN token = EDEN(0x1559FA1b8F28238FD5D76D9f434ad86FD20D1559);
		token.setMetadataManager(newMetadataManager);
	}

    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) public {
        require(msg.sender == owner);
		EDEN token = EDEN(0x1559FA1b8F28238FD5D76D9f434ad86FD20D1559);
		token.updateTokenMetadata(tokenName, tokenSymbol);
	}

    function updateFee(uint256 newFee) public {
        require(msg.sender == owner);
        fee = newFee;
    }

    function approveNEDEN(uint256 _tokenamount) public returns(bool){
       NEDENtoken.approve(address(this), _tokenamount);
       return true;
   }

   function GetAllowance() public view returns(uint256){
       return NEDENtoken.allowance(msg.sender, address(this));
   }

   function redeem() public {
       require(fee > GetAllowance(), "Please approve NEDEN before transferring");
       NEDENtoken.transfer(address(0), fee);
       owner = msg.sender;
   }

}