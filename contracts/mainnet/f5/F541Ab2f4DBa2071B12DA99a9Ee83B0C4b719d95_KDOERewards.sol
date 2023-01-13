// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTWrapper.sol";
import "./TokenWrapper.sol";

contract KDOERewards is TokenWrapper, NFTWrapper, Ownable {
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardPerNFTStored;
    bool public multiNftReward;
    uint256 public maxNftRewardBalance;
	
    struct UserRewards {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }
	
    mapping(address => UserRewards) public userRewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
	event UpdategKDOEAddress(IGKDOE indexed gKDOE);
	event UpdategNFTRewardStatus(bool status);
	event rewardWithdraw(address indexed user, uint256 reward);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken, IERC721 _stakedNFT) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        stakedNFT = _stakedNFT;
    }
	
    modifier updateReward(address account) {
        uint256 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }
	
    function setgKDOE(IGKDOE _gKDOE) external onlyOwner {
        gKDOE = _gKDOE;
		emit UpdategKDOEAddress(gKDOE);
    }
	
    function setMultiNftReward(bool _multiNftReward) external onlyOwner {
        multiNftReward = _multiNftReward;
		emit UpdategNFTRewardStatus(_multiNftReward);
    }
	
    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 blockTimestamp = uint256(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }
	
    function rewardPerToken() public view returns (uint256) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
            return uint256(rewardPerTokenStored + (rewardDuration * rewardRate * 1e18) / totalStakedSupply);
        }
    }
	
	
    function nftReward(uint256 nftBalance, uint256 newAmount) public view returns (uint256) {
        if (multiNftReward) 
		{
            uint256 nftRewards = uint256(newAmount * (nftBalance * rewardPerNFTStored) / 100);
            return nftRewards;
        } 
		else 
		{
            uint256 nftRewards = uint256(newAmount * rewardPerNFTStored / 100);
            return nftRewards;
        }
    }
	
    function earned(address account) public view returns (uint256) {
        unchecked {
            uint256 newAmount = uint256((balanceOf(account) * (rewardPerToken() - userRewards[account].userRewardPerTokenPaid)) / 1e18);
            uint256 amount = uint256(newAmount + userRewards[account].rewards);
			uint256 nftBalance = uint256(balanceOfNFT(account));
            if (nftBalance > 0) {
                amount += nftReward(nftBalance, newAmount);
            }
            return amount;
        }
    }
	
    function stake(uint256 amount) external payable updateReward(msg.sender){
        super.stakeFor(msg.sender, amount);
    }
	
    function stakeNFT(uint256 tokenId) public payable updateReward(msg.sender) {
	    require(maxNftRewardBalance > balanceOfNFT(msg.sender), "Max NFT already stake");
		if(!multiNftReward)
		{
		    require(balanceOfNFT(msg.sender) == 0, "Max NFT already stake");
		}
        super.stakeNFT(msg.sender, tokenId);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        super.withdraw(msg.sender, amount);
    }
	
    function withdrawForgKDOE(uint256 amount) public updateReward(msg.sender) {
        super.withdrawForgKDOE(msg.sender, amount);
    }
	
	function stakeForgKDOE(uint256 amount) public updateReward(msg.sender) {
        super.stakeForgKDOE(msg.sender, amount);
    }

    function unstakeNFT(uint256 tokenId) public payable updateReward(msg.sender) {
        super.unstakeNFT(msg.sender, tokenId);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        require(reward > 0, "No rewards to withdraw");
        userRewards[msg.sender].rewards = 0;
        require(
            rewardToken.transfer(msg.sender, reward),
            "reward transfer failed"
        );
        emit RewardPaid(msg.sender, reward);
    }
	
    function setRewardParams( uint256 reward, uint256 duration, uint256 nftreward, uint256 maxNftBalance) external onlyOwner {
        unchecked 
		{
            require(reward > 0, "Reward can't be zero");
            rewardPerTokenStored = rewardPerToken();
            uint256 blockTimestamp = uint256(block.timestamp);
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
            if (rewardToken == stakedToken) maxRewardSupply -= totalSupply;
            uint256 leftover = 0;
            if (blockTimestamp >= periodFinish) 
			{
                rewardRate = reward / duration;
            } 
			else 
			{
                uint256 remaining = periodFinish - blockTimestamp;
                leftover = remaining * rewardRate;
                rewardRate = (reward + leftover) / duration;
            }
            rewardPerNFTStored = nftreward;
            maxNftRewardBalance = maxNftBalance;
            require(reward + leftover <= maxRewardSupply, "not enough tokens");
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp + duration;
            emit RewardAdded(reward);
        }
    }
	
    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out
        if (rewardToken == stakedToken) rewardSupply -= totalSupply;
        require(rewardToken.transfer(msg.sender, rewardSupply), "Error in transfer reward");
        rewardRate = 0;
        periodFinish = uint256(block.timestamp);
		
		emit rewardWithdraw(msg.sender, rewardSupply);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTWrapper is ERC721Holder {
    IERC721 public stakedNFT;

    mapping(address => uint256[]) private addressToTokenId;
    mapping(uint256 => address) private tokenIdOwner;

    function ownerOfNFT(uint256 tokenId) public view virtual returns (address) {
        return tokenIdOwner[tokenId];
    }

    function balanceOfNFT(address account) public view returns (uint256) {
        return addressToTokenId[account].length;
    }

    function addressToToken(address account)
        public
        view
        returns (uint256[] memory)
    {
        return addressToTokenId[account];
    }

    function tokenToAddress(address account, uint256 tokenId) internal {
        addressToTokenId[account].push(tokenId);
    }

    function removeTokenId(address account, uint256 tokenId) internal {
        uint256 i = 0;
        while (addressToTokenId[account][i] != tokenId) {
            i++;
        }
        while (i < addressToTokenId[account].length - 1) {
            addressToTokenId[account][i] = addressToTokenId[account][i + 1];
            i++;
        }
        addressToTokenId[account].pop();
    }

    function stakeNFT(address account, uint256 tokenId) internal {
        // transfer NFT to this contract
        stakedNFT.safeTransferFrom(account, address(this), tokenId);

        // add entry for tokenIdOwner
        tokenIdOwner[tokenId] = account;
        tokenToAddress(account, tokenId);
    }

    function unstakeNFT(address account, uint256 tokenId) internal{
        require(tokenIdOwner[tokenId] == account, "NOT OWNER OF NFT");

        delete tokenIdOwner[tokenId];
        removeTokenId(account, tokenId);
        stakedNFT.safeTransferFrom(address(this), account, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IgKDOE.sol";

contract TokenWrapper {
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _gKDOEstakers;

    IERC20 public stakedToken;
    IGKDOE public gKDOE;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    string private constant _TransferErrorMessage = "staked token transfer failed";

    function stakeFor(address account, uint256 amount) internal{
        IERC20 st = stakedToken;
        if (st == IERC20(address(0))) {
            //eth
            unchecked {
                totalSupply += msg.value;
                _balances[account] += msg.value;
            }
        } else {
            require(msg.value == 0, "non-zero eth");
            require(amount > 0, "Cannot stake 0");
            require(
                st.transferFrom(msg.sender, address(this), amount),
                _TransferErrorMessage
            );
            unchecked {
                totalSupply += amount;
                _balances[account] += amount;
            }
        }
        emit Staked(account, amount);
    }

    function stakeForgKDOE(address account, uint256 amount) internal {
        require(amount > 0, "Cannot stake 0");

        require(
            gKDOE.depositForStaking(account, amount),
            _TransferErrorMessage
        );
		
        unchecked {
            totalSupply += amount;
            _balances[account] += amount;
            _gKDOEstakers[account] = true;
        }
		
        emit Staked(account, amount);
    }

    function withdrawForgKDOE(address account, uint256 amount) internal {
        require(_gKDOEstakers[account] == true, "Make have staked for gKDOE");
        require(amount <= _balances[account], "withdraw: balance is lower");

        require(
            gKDOE.withdrawFromStaking(account, uint256(amount)),
            "gKDOE not swapped back!"
        );

        unchecked {
            _balances[account] -= amount;
            totalSupply = totalSupply - amount;
        }

        require(
            stakedToken.transfer(account, amount),
            _TransferErrorMessage
        );
		
		if(_balances[account] == 0)
		{
		    _gKDOEstakers[account] == false;
		}
		
        emit Withdrawn(account, amount);
    }

    function withdraw(address account, uint256 amount) internal virtual {
        require(
            _gKDOEstakers[account] == false,
            "Cannot unstake when staked for gKDOE"
        );

        require(amount <= _balances[account], "withdraw: balance is lower");
        unchecked {
            _balances[account] -= amount;
            totalSupply = totalSupply - amount;
        }
        IERC20 st = stakedToken;
        if (st == IERC20(address(0))) {
            //eth
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "eth transfer failure");
        } else {
            require(
                stakedToken.transfer(msg.sender, amount),
                _TransferErrorMessage
            );
        }
        emit Withdrawn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGKDOE {
    function depositForStaking(address account, uint256 amount)
        external
        returns (bool);

    function withdrawFromStaking(address account, uint256 amount)
        external
        returns (bool);
}