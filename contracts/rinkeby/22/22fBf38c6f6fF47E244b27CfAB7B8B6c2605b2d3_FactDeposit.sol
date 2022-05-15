// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "Ownable.sol";
import "IFactToken.sol";
import "IdeFactToken.sol";

contract FactDeposit is Ownable {
    // Сounter of token Id
    uint256 public tokenId = 0;
    // variables for withdraw
    mapping(uint256 => uint256) public lockTime;
    mapping(uint256 => uint256) public withdrawalAmount;
    // interfaces
    IFactToken FactToken;
    IdeFactToken deFactToken;

    /**
     * @dev This is the function to deposit the selected amount of funds.
     * Before calling the function, you must give approval to this contract.
     * The deposit is possible only for certain periods: 3 months, 6 months, etc.
     * Instead of tokens, NFT is issued, which confirms the right to withdraw funds upon the expiration of the deposit period. 
     * NFT can be stored, transferred and sold.
     * @param _amount deposit amount.
     * @param _numberOfMonths number of months of deposit
     */
    
    function deposit(uint256 _amount, uint8 _numberOfMonths) public {
        require(
            _numberOfMonths == 3 ||
                _numberOfMonths == 6 ||
                _numberOfMonths == 9,
            "Enter the correct number of months of deposit!"
        );
        uint256 time;
        uint256 reward;
        if (_numberOfMonths == 3) {
            time = block.timestamp + 5 * 3; // 2628000 - seconds in one month
            reward = (_amount * 125) / 100 - _amount;
        } else if (_numberOfMonths == 6) {
            time = block.timestamp + 5 * 6;
            reward = (_amount * 150) / 100 - _amount;
        } else {
            time = block.timestamp + 5 * 9;
            reward = (_amount * 175) / 100 - _amount;
        }

        FactToken.transferFrom(msg.sender, address(this), _amount);
        deFactToken.safeMint(msg.sender, tokenId, _numberOfMonths);
        FactToken.mint(address(this), reward);
        lockTime[tokenId] = time;
        withdrawalAmount[tokenId] = _amount + reward;
        tokenId++;
    }
    /**
     * @dev This is a function for withdrawing funds with a reward.
     * Before calling the function, you must give approval to this contract for the nft contract.
     * To withdraw funds, the required period must pass and you must have NFT, 
     * which confirms the right to withdraw funds with rewards.
     * @param _tokenId token ID of the NFT token confirming the right.
     */
    function withdraw(uint256 _tokenId) external {
        require(
            lockTime[_tokenId] <= block.timestamp,
            "You can't claim your reward yet!"
        );
        require(
            msg.sender == deFactToken.ownerOf(_tokenId),
            "You are not the owner of the specified nft!"
        );
        deFactToken.burn(_tokenId);
        FactToken.transfer(msg.sender, withdrawalAmount[_tokenId]);
        withdrawalAmount[_tokenId] = 0;
    }

    function setFactTokenContractAddress(address _FACT) external onlyOwner {
        FactToken = IFactToken(_FACT);
    }

    function setDeFactTokenContractAddress(address _deFACT) external onlyOwner {
        deFactToken = IdeFactToken(_deFACT);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IFactToken {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IdeFactToken {

    function safeMint(
        address _to,
        uint256 _tokenId,
        uint8 _numberOfMonths
    ) external;

    function ownerOf(uint256 _tokenId) external returns (address);

    function burn(uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}