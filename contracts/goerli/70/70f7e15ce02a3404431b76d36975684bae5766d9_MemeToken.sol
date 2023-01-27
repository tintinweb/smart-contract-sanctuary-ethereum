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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ITokenImplFacet } from "./interfaces/ITokenImplFacet.sol";
import { LibTokenIds } from "./libs/LibConstants.sol";

contract MemeToken is IERC20 {
    ITokenImplFacet public impl;

    constructor(address _impl) {
        impl = ITokenImplFacet(_impl);
    }

    function name() external view returns (string memory) {
        return impl.tokenName(LibTokenIds.TOKEN_MEME);
    }

    function symbol() external view returns (string memory) {
        return impl.tokenSymbol(LibTokenIds.TOKEN_MEME);
    }

    function decimals() external view returns (uint256) {
        return impl.tokenDecimals(LibTokenIds.TOKEN_MEME);
    }

    function totalSupply() external view override returns (uint256) {
        return impl.tokenTotalSupply(LibTokenIds.TOKEN_MEME);
    }

    function balanceOf(address wallet) external view override returns (uint256) {
        return impl.tokenBalanceOf(LibTokenIds.TOKEN_MEME, wallet);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return impl.tokenTransfer(LibTokenIds.TOKEN_MEME, recipient, amount);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return impl.tokenAllowance(LibTokenIds.TOKEN_MEME, owner, spender);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        return impl.tokenApprove(LibTokenIds.TOKEN_MEME, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return impl.tokenTransferFrom(LibTokenIds.TOKEN_MEME, sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

interface ITokenImplFacet {
    /**
     * @dev Returns the name.
     */
    function tokenName(uint tokenId) external view returns (string memory);

    /**
     * @dev Returns the symbol.
     */
    function tokenSymbol(uint tokenId) external view returns (string memory);

    /**
     * @dev Returns the decimals.
     */
    function tokenDecimals(uint tokenId) external view returns (uint);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function tokenTotalSupply(uint tokenId) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `wallet`.
     */
    function tokenBalanceOf(uint tokenId, address wallet) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function tokenTransfer(uint tokenId, address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function tokenAllowance(uint tokenId, address owner, address spender) external view returns (uint256);

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
    function tokenApprove(uint tokenId, address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function tokenTransferFrom(uint tokenId, address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

library LibConstants {
    bytes32 internal constant EIP712_DOMAIN_HASH = keccak256("EIP712_DOMAIN_HASH");

    bytes32 internal constant MEME_TOKEN_ADDRESS = keccak256("MEME_TOKEN_ADDRESS");
    bytes32 internal constant SERVER_ADDRESS = keccak256("SERVER_ADDRESS");
    bytes32 internal constant TREASURY_ADDRESS = keccak256("TREASURY_ADDRESS");

    uint internal constant MIN_BET_AMOUNT = 10 ether;

    uint internal constant TOKEN_MEME = 1;

    address internal constant WMATIC_POLYGON_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
}

library LibTokenIds {
    uint256 internal constant TOKEN_MEME = 1;
    uint256 internal constant BROADCAST_MSG = 2;
    uint256 internal constant SUPPORTER_INFLUENCE = 3;
}