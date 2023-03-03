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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


//interface PulseBitcoinLockNFT {
//    function tokenIdsToTransferable(uint tokenId) external view returns (bool);
//    function balanceOf(address owner) external view returns (uint256);
//    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
//}


contract Faucet {
    address public immutable token_address; // Reward token
    IERC20 token;
    IERC20 carnToken;
    mapping(address=>uint256) public nextRequestAt;
    uint256 public withdrawAmount;
    uint256 public delay;
    uint256 public carnBalanceRequired;
    address public immutable lockNFTAddress;

    constructor (
        address _tokenAddress,
        address _carnTokenAddress,
        uint256 _withdrawAmount,
        uint256 _delay,
        uint256 _carnBalanceRequired,
        address _lockNFTAddress
    ) {
        token_address = _tokenAddress;
        token = IERC20(token_address);
        carnToken = IERC20(_carnTokenAddress);
        withdrawAmount = _withdrawAmount;
        delay = _delay;
        carnBalanceRequired = _carnBalanceRequired;
        lockNFTAddress = _lockNFTAddress;
    }

    function withdraw() external {
        require(token.balanceOf(address(this)) > withdrawAmount * 1e12, "FaucetError: Empty");
        require(nextRequestAt[msg.sender] < block.timestamp, "Must wait 1 full week");
        require(carnToken.balanceOf(msg.sender) >= carnBalanceRequired, "Insufficient CARN balance");
        //require(hasValidNFT(msg.sender), "User does not have a valid NFT");
        nextRequestAt[msg.sender] = block.timestamp + delay;
        token.transfer(msg.sender, withdrawAmount * 1e12);
    }

//    function hasValidNFT(address user) internal view returns (bool) {
//        PulseBitcoinLockNFT lockNFT = PulseBitcoinLockNFT(lockNFTAddress);
//        uint256 nftBalance = lockNFT.balanceOf(user);
//        for (uint256 i = 0; i < nftBalance; i++) {
//            uint256 tokenId = lockNFT.tokenOfOwnerByIndex(user, i);
//            if (!lockNFT.tokenIdsToTransferable(tokenId)) {
//                return true;
//            }
//        }
//        return false;
//    }
}