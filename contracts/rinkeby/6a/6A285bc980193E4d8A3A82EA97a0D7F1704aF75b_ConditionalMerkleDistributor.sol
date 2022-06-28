// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILoan.sol";
import "./IDirectLoanCoordinator.sol";
import "./IVestedStaking.sol";

contract ConditionalMerkleDistributor is Ownable {
    uint256 public immutable vipSlots;
    uint256 public immutable blueChipSlots;

    address public admin;

    uint256 public constant vipBorrowerReward = 300 ether;
    uint256 public constant vipLenderReward = 100 ether;
    uint256 public constant blueChipBorrowerReward = 100 ether;
    uint256 public constant blueChipLenderReward = 40 ether;

    address public loanCoordinator;
    address public loanContract;

    uint256 public vipSlotCounter;
    uint256 public blueChipSlotCounter;

    address public immutable token;
    address public vestedStaking;

    bytes32 private vipMerkleRoot;
    bytes32 private blueChipMerkleRoot;

    // has to be used for a condition: loans must be more recent than startTime
    uint256 public startTime;

    // This is a packed array of booleans for each root number
    mapping(uint256 => uint256) private vipClaimedBitMap;
    // This is a packed array of booleans for each root number
    mapping(uint256 => uint256) private blueChipClaimedBitMap;

    mapping(address => bool) private vipCollections;
    mapping(address => bool) private blueChipCollections;

    mapping(address => bool) private borrowerClaimed;

    mapping(address => mapping(uint256 => bool)) private usedAssets;

    event Claimed(uint256 index, address indexed account, bool indexed borrower, bool indexed vip);

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller not admin");
        _;
    }

    constructor(
        address _admin,
        address _token,
        address _loanCoordinator,
        address _loanContract,
        uint256 _vipSlots,
        uint256 _blueChipSlots
    ) {
        admin = _admin;
        token = _token;

        startTime = block.timestamp;
        loanCoordinator = _loanCoordinator;
        loanContract = _loanContract;
        vipSlots = _vipSlots;
        blueChipSlots = _blueChipSlots;
    }

    function setRoots(bytes32 _vipMerkleRoot, bytes32 _blueChipMerkleRoot) public onlyAdmin {
        require(vipMerkleRoot == bytes32(0) && blueChipMerkleRoot == bytes32(0), "roots already set");
        vipMerkleRoot = _vipMerkleRoot;
        blueChipMerkleRoot = _blueChipMerkleRoot;
    }

    function setVestedStaking(address _vestedStaking) external onlyOwner {
        vestedStaking = _vestedStaking;
        IERC20(token).approve(_vestedStaking, 2**256 - 1);
    }

    function addVipCollections(address[] memory collections) external onlyAdmin {
        _setCollections(collections, true, true);
    }

    function removeVipCollections(address[] memory collections) external onlyAdmin {
        _setCollections(collections, true, false);
    }

    function addBlueChipCollections(address[] memory collections) external onlyAdmin {
        _setCollections(collections, false, true);
    }

    function removeBlueChipCollections(address[] memory collections) external onlyAdmin {
        _setCollections(collections, false, false);
    }

    function _setCollections(
        address[] memory collections,
        bool vip,
        bool addOrRemove
    ) internal {
        if (vip) {
            for (uint256 i; i < collections.length; i++) {
                vipCollections[collections[i]] = addOrRemove;
            }
        } else {
            for (uint256 i; i < collections.length; i++) {
                blueChipCollections[collections[i]] = addOrRemove;
            }
        }
    }

    function isClaimedVip(uint256 _index) public view returns (bool) {
        return isClaimed(_index, true);
    }

    function isClaimedBlueChip(uint256 _index) public view returns (bool) {
        return isClaimed(_index, false);
    }

    function isClaimed(uint256 _index, bool vip) internal view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord;
        if (vip) {
            claimedWord = vipClaimedBitMap[claimedWordIndex];
        } else {
            claimedWord = blueChipClaimedBitMap[claimedWordIndex];
        }
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimedVip(uint256 _index) private {
        _setClaimed(_index, true);
    }

    function _setClaimedBlueChip(uint256 _index) private {
        _setClaimed(_index, false);
    }

    function _setClaimed(uint256 _index, bool vip) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        if (vip) {
            vipClaimedBitMap[claimedWordIndex] = vipClaimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
        } else {
            blueChipClaimedBitMap[claimedWordIndex] = blueChipClaimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
        }
    }

    function _getLender(uint32 _loanId) internal view returns (address lender) {
        IDirectLoanCoordinator coordinator = IDirectLoanCoordinator(loanCoordinator);
        IDirectLoanCoordinator.Loan memory loanCoordinatorData = coordinator.getLoanData(_loanId);
        uint256 smartNftId = loanCoordinatorData.smartNftId;
        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        lender = IERC721(coordinator.promissoryNoteToken()).ownerOf(smartNftId);
    }

    function _checkLoan(
        address _borrower,
        address _lender,
        uint32 _loanId,
        ILoan.LoanTerms memory _loan
    ) internal view {
        require(_borrower == _loan.borrower, "sender is not borrower");
        require(_lender == _getLender(_loanId), "wrong lender");
        require(!usedAssets[_loan.nftCollateralContract][_loan.nftCollateralId], "asset already claimed against");
        require(vipCollections[_loan.nftCollateralContract], "not vip collection");
        require(_loan.loanStartTime > startTime, "loan too old");
        require(!ILoan(loanContract).loanRepaidOrLiquidated(_loanId), "loan repaid or liquidated");
        uint256 precision = 10**18;
        require(
            (((_loan.maximumRepaymentAmount - _loan.loanPrincipalAmount) * precision) / _loan.loanPrincipalAmount) *
                100 >=
                5 * precision,
            "loan APR under 5%"
        );
        // solhint-disable-previous-line no-empty-blocks
        //todo
        //_getLender(_loanId);
    }

    function claimVipBorrower(
        uint256 _index,
        address _lender,
        uint32 _loanId,
        bytes32[] calldata _merkleProof
    ) external {
        require(!isClaimedVip(_index), "index already claimed");
        //even tough multiple roots can contain an users drop, they can only claim once
        require(!borrowerClaimed[msg.sender], "borrower already claimed");
        require(vipSlotCounter < vipSlots, "vip slots ran out");

        ILoan.LoanTerms memory loan;

        (
            loan.loanPrincipalAmount,
            loan.maximumRepaymentAmount,
            loan.nftCollateralId,
            ,
            ,
            ,
            ,
            ,
            loan.loanStartTime,
            loan.nftCollateralContract,
            loan.borrower
        ) = ILoan(loanContract).loanIdToLoan(_loanId);

        _checkLoan(msg.sender, _lender, _loanId, loan);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender));
        require(MerkleProof.verify(_merkleProof, vipMerkleRoot, node), "distributor: invalid proof");

        // Mark it claimed and send the token.
        _setClaimedVip(_index);
        borrowerClaimed[msg.sender] = true;
        usedAssets[loan.nftCollateralContract][loan.nftCollateralId] = true;
        vipSlotCounter++;
        IVestedStaking(vestedStaking).addVestedStaking(msg.sender, vipBorrowerReward);

        emit Claimed(_index, msg.sender, true, true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface ILoan {
    struct LoanTerms {
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint256 nftCollateralId;
        address loanERC20Denomination;
        uint32 loanDuration;
        uint16 loanInterestRateForDurationInBasisPoints;
        uint16 loanAdminFeeInBasisPoints;
        address nftCollateralWrapper;
        uint64 loanStartTime;
        address nftCollateralContract;
        address borrower;
    }

    function loanIdToLoan(uint32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint32,
            uint16,
            uint16,
            address,
            uint64,
            address,
            address
        );

    function loanRepaidOrLiquidated(uint32) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title IDirectLoanCoordinator
 * @author NFTfi
 * @dev DirectLoanCoordinator interface.
 */
interface IDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    /**
     * @notice This struct contains data related to a loan
     *
     * @param smartNftId - The id of both the promissory note and obligation receipt.
     * @param status - The status in which the loan currently is.
     * @param loanContract - Address of the LoanType contract that created the loan.
     */
    struct Loan {
        address loanContract;
        uint64 smartNftId;
        StatusType status;
    }

    function promissoryNoteToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVestedStaking {
    /**
     * @dev Endpoint function called only by distribution contracts to start a new vesting and staking.
     * Interface function for distributor contracts.
     *
     * @param _beneficiary The address of the user that will be receiving the tokens from vested staking
     * @param _vestingAmount Amount of tokens being vested for `beneficiary`
     */
    function addVestedStaking(address _beneficiary, uint256 _vestingAmount) external;
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