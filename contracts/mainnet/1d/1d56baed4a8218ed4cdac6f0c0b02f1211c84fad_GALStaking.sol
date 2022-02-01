// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GALStaking is IERC20Metadata {

    struct StakeInfo {
        uint256 tokenId;
        uint256 unlockTime;
        address owner;
    }

    IERC721 public immutable GAL;
    uint256 public constant MULTIPLIER = 1e12;
    uint256 public lockDuration = 7 days;

    uint256 accRPS;
    uint256 lastETHBalance;

    // Info of each user that stakes tokens.
    mapping(uint256 => StakeInfo) private _receipt;
    mapping(address => uint256) private _debt;
    mapping(address => uint256[]) private _stakedListOf;

    constructor(IERC721 _GAL) {
        GAL = _GAL;
    }

    function name() external pure override returns (string memory) {
        return "GAL DP";
    }

    function symbol() external pure override returns (string memory) {
        return "GALDP";
    }

    function decimals() external pure override returns (uint8) {
        return 0;
    }

    function totalSupply() public view override returns (uint256) {
        return GAL.balanceOf(address(this));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _stakedListOf[account].length;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("Not allowed");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function stakedListOf(address account) external view returns (uint256[] memory) {
        return _stakedListOf[account];
    }

    function getStakeInfo(uint256 tokenId) external view returns (uint256, uint256, address) {
        return (
            _receipt[tokenId].tokenId,
            _receipt[tokenId].unlockTime,
            _receipt[tokenId].owner
        );
    }

    // View function to see pending ETH rewards
    function pendingETHRewards(address account) external view returns (uint256) {
        uint256 currentRPS = accRPS;
        uint256 stakedGALCount = totalSupply();
        uint256 stakedCount = balanceOf(account);

        if(stakedCount == 0) {
            return 0;
        }

        if (stakedGALCount != 0) {
            uint256 ETHSupply = address(this).balance;
            uint256 ETHReward = ETHSupply - lastETHBalance;
            currentRPS += (ETHReward * MULTIPLIER) / stakedGALCount;
        }
        return ((stakedCount * currentRPS) / MULTIPLIER) - _debt[account];
    }

    function deposit(uint256[] calldata tokenIds) external {
        _deposit(tokenIds, msg.sender);
    }

    function withdraw(uint256[] calldata tokenIds) external {
        _withdraw(tokenIds, msg.sender);
    }

    // Deposit A GAL token for staking.
    function _deposit(uint256[] calldata tokenIds, address holder) internal {
        _refreshRewards();

        uint256 pending;
        uint256 stakedCount = balanceOf(holder);
        if(stakedCount > 0) {
            pending = ((stakedCount * accRPS) / MULTIPLIER) - _debt[holder];
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _receipt[tokenIds[i]] = StakeInfo(tokenIds[i], block.timestamp + lockDuration, holder);
            _stakedListOf[holder].push(tokenIds[i]);
        }
        _debt[holder] = ((stakedCount + tokenIds.length) * accRPS) / MULTIPLIER;    

        if(pending > 0) {
            _sendRewards(holder, pending);
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            GAL.transferFrom(holder, address(this), tokenIds[i]);
        }

        emit Transfer(address(0), msg.sender, tokenIds.length);
    }

    // Withdraw staked GAL + ETH rewards.
    function _withdraw(uint256[] calldata tokenIds, address holder) internal {
        _refreshRewards();

        uint256 stakedCount = balanceOf(holder);
        uint256 pending = ((stakedCount * accRPS) / MULTIPLIER) - _debt[holder];
        _debt[holder] += pending;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            StakeInfo memory stakeInfo = _receipt[tokenIds[i]];
            require(stakeInfo.owner == holder, "GALStaking: Unauthorized");
            require(block.timestamp >= stakeInfo.unlockTime, "GALStaking: Too early");
            delete _receipt[tokenIds[i]];

            // delete from the list of NFTs for holder
            uint256[] memory listOfNFTs = _stakedListOf[holder];
            uint256 length = listOfNFTs.length;
            for (uint256 j = 0; j < length; j++) {
                if (listOfNFTs[j] == tokenIds[i]) {
                    _stakedListOf[holder][j] = listOfNFTs[length - 1];
                    _stakedListOf[holder].pop();
                    break;
                }
            }
            GAL.transferFrom(address(this), holder, tokenIds[i]);
        }

        if(pending > 0) {
            _sendRewards(holder, pending);
        }
        emit Transfer(msg.sender, address(0), tokenIds.length);
    }

    // Update reward variables
    function _refreshRewards() internal {
        uint256 ETHSupply = address(this).balance;
        uint256 ETHReward = ETHSupply - lastETHBalance;
        if(ETHReward == 0) {
            return;
        }

        uint256 stakedGALCount = totalSupply();
        if (stakedGALCount == 0) {
            return;
        }

        accRPS += (ETHReward * MULTIPLIER) / stakedGALCount;
        lastETHBalance = ETHSupply;
    }

    function _sendRewards(address _to, uint256 _amount) internal {
        uint256 ETHBal = address(this).balance;
        if (_amount > ETHBal) {
            lastETHBalance = 0;
            (bool success, ) = _to.call{ value : ETHBal }("");
            require(success, "Transfer failed.");
        } else {
            lastETHBalance = ETHBal - _amount;
            (bool success, ) = _to.call{ value : _amount }("");
            require(success, "Transfer failed.");
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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