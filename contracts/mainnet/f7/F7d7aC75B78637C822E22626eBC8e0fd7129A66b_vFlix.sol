// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract vFlix {

    address public admin;

    modifier onlyAdmin()
    {
        require( msg.sender == admin, "Caller is not admin" );
        _;
    }

    constructor()
    {
        admin = msg.sender;
    }

    function pay( address payee, uint256 fee, uint256 cost, uint8 v, bytes32 r, bytes32 s ) 
        external payable
    {
        bytes memory message = abi.encode( payee, fee, cost );
        bool validSignature = _signatureIsValid( message, v, r, s );
        require( validSignature, "Invalid signature" );

        require( msg.value == cost, "Insufficient payment" );

        uint256 commission = cost * fee / 1000;
        payable( payee ).transfer( cost - commission );
        payable( admin ).transfer( commission );
    }

    function payToken( IERC20 token, address payee, uint256 fee, uint256 cost, uint8 v, bytes32 r, bytes32 s ) 
        external
    {
        bytes memory message = abi.encode( token, payee, fee, cost );
        bool validSignature = _signatureIsValid( message, v, r, s );
        require( validSignature, "Invalid signature" );

        require( token.balanceOf( msg.sender ) >= cost, "Insufficient balance" );

        uint256 commission = cost * fee / 1000;
        bool successPayee = token.transferFrom( msg.sender, payee, cost - commission );
        bool successAdmin = token.transferFrom( msg.sender, admin, commission );
        require( successPayee && successAdmin, "Token transfer failed. Missing approval?" );
    }

    function setAdmin( address _admin ) 
        external onlyAdmin
    {
        admin = _admin;
    }

    function withdraw() 
        external onlyAdmin 
    {
        uint256 amount = address( this ).balance;
        require( amount > 0, "Balance is zero" );
        payable( admin ).transfer( amount );
    }

    function _signatureIsValid( bytes memory message, uint8 v, bytes32 r, bytes32 s ) 
        internal view returns ( bool )
    {
        bytes32 messageHash = keccak256( message );
        bytes32 messageHashed = keccak256( abi.encodePacked( "\x19Ethereum Signed Message:\n32", messageHash ) );
        return ecrecover( messageHashed, v, r, s ) == admin;
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
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