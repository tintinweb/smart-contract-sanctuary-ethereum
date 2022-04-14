// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title Treasury
 * @author Steve Harmeyer
 * @notice This is the treasury contract. This allows us to send funds (both
 * dev allocations and presale USDT) to a central contract from where we can
 * fund a liquidity pool, etc. This is basically a multisig wallet requiring
 * multiple people from the dev team to approve actions.
 */
contract Treasury {
    // Owners
    mapping(address => bool) owners;
    uint256 public ownerCount;

    // What percent of owners need to approve an action?
    uint256 public votePercent = 75;

    // Actions mapping
    mapping(bytes32 => address[]) public actions;

    // Events
    event VotePassed(bytes32 hash_);
    event OwnerAdded(address owner_);
    event OwnerRemoved(address owner_);
    event Transfer(address token_, address to_, uint256 amount_);
    event VotePercentUpdated(uint256 percent_);

    // Constructor
    constructor()
    {
        _addOwner(msg.sender);
    }

    /**
     * Is an owner?
     * @param address_ Address to check.
     * @return bool
     */
    function isOwner(address address_) public view returns (bool)
    {
        return owners[address_];
    }

    /**
     * Add owner.
     * @param owner_ Address of new owner.
     */
    function addOwner(address owner_) external onlyOwner
    {
        require(!isOwner(owner_), "Owner already exists");
        bytes32 hash = keccak256(abi.encode("addOwner", owner_));
        _vote(hash);
        if(!_passes(hash)) return;
        _addOwner(owner_);
    }

    /**
     * Remove owner.
     * @param owner_ Address of owner to remove.
     */
    function removeOwner(address owner_) external onlyOwner
    {
        require(isOwner(owner_), "Address is not owner");
        bytes32 hash = keccak256(abi.encode("removeOwner", owner_));
        _vote(hash);
        if(!_passes(hash)) return;
        _removeOwner(owner_);
    }

    /**
     * Transfer.
     * @param token_ Token address.
     * @param to_ Recipient address.
     * @param amount_ Amount to send.
     */
    function transfer(address token_, address to_, uint256 amount_) external onlyOwner
    {
        IERC20 _token_ = IERC20(token_);
        require(_token_.balanceOf(address(this)) >= amount_, "Insufficient funds");
        bytes32 hash = keccak256(abi.encode("transfer", token_, to_, amount_));
        _vote(hash);
        if(!_passes(hash)) return;
        _transfer(_token_, to_, amount_);
    }

    /**
     * Set vote percent.
     * @param percent_ New vote percent.
     */
    function setVotePercent(uint256 percent_) external onlyOwner
    {
        bytes32 hash = keccak256(abi.encode("setVotePercent", percent_));
        _vote(hash);
        if(!_passes(hash)) return;
        _setVotePercent(percent_);
    }

    /**
     * Add vote
     * @param hash_ Action hash.
     */
    function _vote(bytes32 hash_) internal
    {
        bool voted = false;
        for(uint256 i = 0; i < actions[hash_].length; i ++) {
            if(msg.sender == actions[hash_][i]) {
                voted = true;
            }
        }
        require(!voted, "Already voted");
        actions[hash_].push(msg.sender);
    }

    /**
     * Passes vote?
     * @param hash_ Action hash.
     * @return bool
     */
    function _passes(bytes32 hash_) internal returns (bool)
    {
        bool _passes_ = actions[hash_].length * 100 / ownerCount >= votePercent;
        if(_passes_) delete actions[hash_];
        emit VotePassed(hash_);
        return _passes_;
    }

    /**
     * Add owner.
     * @param owner_ Owner address.
     */
    function _addOwner(address owner_) internal
    {
        if(owners[owner_]) return;
        owners[owner_] = true;
        ownerCount ++;
        emit OwnerAdded(owner_);
    }

    /**
     * Remove owner.
     * @param owner_ Owner address.
     */
    function _removeOwner(address owner_) internal
    {
        owners[owner_] = false;
        ownerCount --;
        emit OwnerRemoved(owner_);
    }

    /**
     * Transfer.
     * @param token_ Token contract.
     * @param to_ Recipient address.
     * @param amount_ Amount to send.
     */
    function _transfer(IERC20 token_, address to_, uint256 amount_) internal
    {
        token_.transfer(to_, amount_);
        emit Transfer(address(token_), to_, amount_);

    }

    /**
     * Set vote percent.
     * @param percent_ New percent.
     */
    function _setVotePercent(uint256 percent_) internal
    {
        votePercent = percent_;
        emit VotePercentUpdated(percent_);
    }

    // Owner modifier
    modifier onlyOwner()
    {
        require(isOwner(msg.sender), "Unauthorized");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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