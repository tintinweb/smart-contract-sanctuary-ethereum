// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './HyksosBase.sol';

interface IOrcs is IERC721 {
    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }
    enum   Actions { UNSTAKED, FARMING, TRAINING }
    struct Action  { address owner; uint88 timestamp; Actions action; }
    function orcs(uint256 _id) external returns(Orc memory);
    function activities(uint256 _id) external returns(Action memory);
    function claimable(uint256 id) external view returns (uint256);
    function claim(uint256[] calldata ids) external;
    function doAction(uint256 id, Actions action_) external;
}

contract HyksosEtherorcs is HyksosBase {
    
    IOrcs immutable public nft;
    IERC20 immutable public erc20;

    uint256 constant public MIN_DEPOSIT = 4 ether; // TBD


    constructor(address _zug, address _orcs, address _autoCompound, uint256 _depositLength, uint256 _roiPctg) HyksosBase(_autoCompound, _depositLength, _roiPctg) {
        nft = IOrcs(_orcs);
        erc20 = IERC20(_zug);
    }

    function payErc20(address _receiver, uint256 _amount) internal override {
        require(erc20.transfer(_receiver, _amount));
    }

    function depositErc20(uint256 _amount) external override {
        require(_amount >= MIN_DEPOSIT, "Deposit amount too small.");
        erc20BalanceMap[msg.sender] += _amount;
        pushDeposit(_amount, msg.sender);
        totalErc20Balance += _amount;
        require(erc20.transferFrom(msg.sender, address(this), _amount));
        emit Erc20Deposit(msg.sender, _amount);
    }

    function withdrawErc20(uint256 _amount) external override {
        require(_amount <= erc20BalanceMap[msg.sender], "Withdrawal amount too big.");
        totalErc20Balance -= _amount;
        erc20BalanceMap[msg.sender] -= _amount;
        require(erc20.transfer(msg.sender, _amount));
        emit Erc20Withdrawal(msg.sender, _amount);
    }

    function depositNft(uint256 _id) external override {
        depositedNfts[_id].timeDeposited = uint88(block.timestamp);
        depositedNfts[_id].owner = msg.sender;
        depositedNfts[_id].rateModifier = nft.orcs(_id).zugModifier;
        uint256 loanAmount = calcReward(depositLength, depositedNfts[_id].rateModifier) * roiPctg / 100;
        selectShareholders(_id, loanAmount);
        totalErc20Balance -= loanAmount;
        nft.transferFrom(msg.sender, address(this), _id);
        nft.doAction(_id, IOrcs.Actions.FARMING);
        require(erc20.transfer(msg.sender, loanAmount));
        emit NftDeposit(msg.sender, _id);
    }

    function withdrawNft(uint256 _id) external override {
        require(depositedNfts[_id].timeDeposited + depositLength < block.timestamp, "Too early to withdraw.");
        uint256 reward = nft.claimable(_id);
        nft.doAction(_id, IOrcs.Actions.UNSTAKED);
        uint256 nftWorkValue = calcReward(depositLength, depositedNfts[_id].rateModifier);
        distributeRewards(_id, reward, nftWorkValue);
        nft.transferFrom(address(this), depositedNfts[_id].owner, _id);
        emit NftWithdrawal(depositedNfts[_id].owner, _id);
        delete depositedNfts[_id];
    }

    function calcReward(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256) {
        return timeDiff * (4 + zugModifier) * 1 ether / 1 days;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './DepositQueue.sol';
import './IHyksos.sol';

abstract contract HyksosBase is IHyksos, DepositQueue {

    struct DepositedNft {
        uint256 timeDeposited;
        address owner;
        uint16 rateModifier;
        Deposit[] shareholders;
    }

    IAutoCompound immutable public autoCompound;
    uint256 immutable public roiPctg;
    uint256 immutable public depositLength;

    mapping(address => uint256) internal erc20BalanceMap;
    mapping(uint256 => DepositedNft) internal depositedNfts;
    uint256 internal totalErc20Balance;

    constructor(address _autoCompound, uint256 _depositLength, uint256 _roiPctg) {
        autoCompound = IAutoCompound(_autoCompound);
        roiPctg = _roiPctg;
        depositLength = _depositLength;
    }

    function payErc20(address _receiver, uint256 _amount) internal virtual;

    function distributeRewards(uint256 _id, uint256 _reward, uint256 _nftWorkValue) internal {
            withdrawNftAndRewardCaller(_id, _reward, _nftWorkValue);
    }

    function withdrawNftAndRewardCaller(uint256 _id, uint256 _reward, uint256 _nftWorkValue) internal {
        for (uint i = 0; i < depositedNfts[_id].shareholders.length; i++) {
            Deposit memory d = depositedNfts[_id].shareholders[i];
            uint256 payback = d.amount * 100 / roiPctg;
            payRewardAccordingToStrategy(d.sender, payback);
        }
        payErc20(msg.sender, _reward - _nftWorkValue);
    }

    function selectShareholders(uint256 _id, uint256 _loanAmount) internal {
        require(totalErc20Balance >= _loanAmount, "Not enough erc-20 tokens in pool to fund a loan.");
        // loop variables
        uint256 selectedAmount;
        uint256 depositAmount;
        uint256 resultingAmount;
        uint256 usedAmount;
        uint256 leftAmount;

        while (!isDepositQueueEmpty()) {
            Deposit memory d = getTopDeposit();
            if (erc20BalanceMap[d.sender] == 0) {
                popDeposit();
                continue;
            }
            if (erc20BalanceMap[d.sender] < d.amount) {
                depositAmount = erc20BalanceMap[d.sender];
            } else {
                depositAmount = d.amount;
            }
            resultingAmount = selectedAmount + depositAmount;
            if (resultingAmount > _loanAmount) {
                usedAmount = _loanAmount - selectedAmount;
                leftAmount = depositAmount - usedAmount;
                setTopDepositAmount(leftAmount);
                depositedNfts[_id].shareholders.push(Deposit(usedAmount, d.sender));
                erc20BalanceMap[d.sender] -= usedAmount;
                return;
            } else {
                depositedNfts[_id].shareholders.push(Deposit(depositAmount, d.sender));
                selectedAmount = resultingAmount;
                erc20BalanceMap[d.sender] -= depositAmount;
                popDeposit();
                if (resultingAmount == _loanAmount) {
                    return;
                }
            }
        }
        // if while loop does not return early, we don't have enough bananas.
        revert("Not enough deposits.");
    }

    function payRewardAccordingToStrategy(address _receiver, uint256 _amount) internal {
        if (autoCompound.getStrategy(_receiver)) {
            erc20BalanceMap[_receiver] += _amount;
            pushDeposit(_amount, _receiver);
            totalErc20Balance += _amount;
        } else {
            payErc20(_receiver, _amount);
        }
    }

    function erc20Balance(address _addr) external view override returns(uint256) {
        return erc20BalanceMap[_addr];
    }

    function totalErc20() external view override returns(uint256) {
        return totalErc20Balance;
    }

    function depositedNft(uint256 _id) external view returns(DepositedNft memory) {
        return depositedNfts[_id];
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
pragma solidity 0.8.10;

contract DepositQueue {
    struct Deposit {
        uint256 amount;
        address sender;
    }

    Deposit[] private depositQueue;
    uint256 private topIndex;

    function isDepositQueueEmpty() internal view returns(bool) {
        return depositQueue.length <= topIndex;
    }

    modifier nonEmpty() {
        require(!isDepositQueueEmpty());
        _;
    }

    function pushDeposit(uint256 _amount, address _sender) internal {
        depositQueue.push(Deposit(_amount, _sender));
    }

    function popDeposit() internal nonEmpty {
        delete depositQueue[topIndex];
        topIndex++;
    }

    function getTopDeposit() internal nonEmpty view returns(Deposit memory) {
        return depositQueue[topIndex];
    }

    function setTopDepositAmount(uint256 _amount) internal nonEmpty {
        depositQueue[topIndex].amount = _amount;
    }

    function numDeposits() public view returns(uint256) {
        return depositQueue.length - topIndex;
    }

    function getDeposit(uint256 _index) external view nonEmpty returns(Deposit memory) {
        require(topIndex + _index < depositQueue.length, 'Index out of bounds');
        return depositQueue[topIndex + _index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IHyksos {
    
    function depositErc20(uint256 _amount) external;
    function withdrawErc20(uint256 _amount) external;
    function depositNft(uint256 _id) external;
    function withdrawNft(uint256 _id) external;
    function erc20Balance(address _addr) external view returns(uint256);
    function totalErc20() external view returns(uint256);

    event Erc20Deposit(address indexed addr, uint256 value);
    event Erc20Withdrawal(address indexed addr, uint256 value);
    event NftDeposit(address indexed addr, uint256 id);
    event NftWithdrawal(address indexed addr, uint256 id);
}

interface IAutoCompound {
    function getStrategy(address _user) external view returns(bool);
}