// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RaffleErc20__NotEnoughSent();
error RaffleErc20__RewardsNotEqualToWinners();
error RaffleErc20__NftAddressesDoNotMatchWinners();
error RaffleErc20__NftAddressesDoNotMatchIds();
error RaffleErc20__WinnersDoNotMatchNftIds();

interface IERC721 {
     function transferFrom(address from, address to, uint256 tokenId) external;
     function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Contract that holds ERC20 and ERC721 tokens while the lottery is being processed
/// @author VAIOT team
/// @notice This contract should solely be used for storing tokens and paying out winners of the lottery
/// @dev In order to use this smart contract properly the author of the giveaway should send
/// ERC721 or ERC20 tokens to this smart contract's address. After sending the tokens we can
/// call transferERC20 to send ERC20 tokens to the winners, transferERC721 to send NFTs to winners and
/// getERC20Balance, getERC721Balance to check the balance of ERC20/ERC721 tokens.

contract RaffleERC20 is Ownable {

    /// @notice Transfer ERC20 tokens to the winners
    /// @param _token - address of the ERC20 token
    /// @param _addresses - array of addresses of the winners of the lottery for example ["0x", "0x2", ...]
    /// @param _rewards - array of the amount of tokens each winner should get. Input the amount of tokens
    /// for example if the top 3 winners should get 30, 20 and 10 tokens respectively you should input
    /// [30,20,10]

    function transferERC20(
        address _token,
        address payable[] memory _addresses,
        uint256[] memory _rewards 
    ) public onlyOwner {
        if (_addresses.length != _rewards.length) {
            revert RaffleErc20__RewardsNotEqualToWinners();
        }
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_token).transfer(_addresses[i], _rewards[i] * (10 ** 18));
        }
    }

    /// @notice Transfer ERC721 tokens to the winners
    /// @param _NFTAddresses - array of the NFT Collection Addresses
    /// @param _winners - array of addresses of the winners of the lottery for example ["0x", "0x2", ...]
    /// @param _NFTIds - array containing IDs of tokens from certain NFT collections

    function transferERC721(
        address[] memory _NFTAddresses, 
        address[] memory _winners, 
        uint256[] memory _NFTIds
    ) external onlyOwner {
        if (_NFTAddresses.length != _winners.length) {
            revert RaffleErc20__NftAddressesDoNotMatchWinners();
        }
        if (_NFTAddresses.length != _NFTIds.length) {
            revert RaffleErc20__NftAddressesDoNotMatchIds();
        }
        if (_winners.length != _NFTIds.length) {
            revert RaffleErc20__WinnersDoNotMatchNftIds();
        }
        for (uint i=0; i<_winners.length; i++) {
            IERC721 NFT = IERC721(_NFTAddresses[i]);
            NFT.transferFrom(address(this), _winners[i], _NFTIds[i]);
        }
    }

    /// @notice Get the ERC20 holdings of the smart contract
    /// @param _token - address of the ERC20 token

    function getERC20Balance(
        address _token
    ) public view onlyOwner returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Get the ERC721 holdings of the smart contract
    /// @param _token - address of the ERC721 collection

    function getERC721Balance(
        address _token
    ) public view onlyOwner returns (uint) {
        return IERC721(_token).balanceOf(address(this));
    }
}