/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/cryptography/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


// File @animoca/ethereum-contracts-assets/contracts/token/ERC20/interfaces/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}


// File @animoca/ethereum-contracts-core/contracts/metatx/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }
}


// File contracts/payout/PayoutClaimDistributor.sol
pragma solidity >=0.7.6 <0.8.0;



/// @title PayoutClaimDistributor
/// @notice Through this contract, users could claim ERC20 token s/he is eligible to claim the rewards.
///      - The owner/deployer of the contract could set merkle root, distributor address or lock/unlock the distribution.
///      - Owner sets the ERC20 Token address (`token`) when deploying the contract, the owner also
///        sets distributor address (`distAddress`) through `setDistributorAddress` function from which to distribute the tokens.
///      - Owner should also approve the amount of ERC20 tokens allowed to distribute through this contract.
///      - For owner to set new merkle root through `setMerkleRoot` function, contract distribution should be locked though
///         `setLocked`.
///      - To enable distribution again, it should be unlocked with `setLocked` function.
///      - Users could claim the ERC20 token payout when the distributor is unlocked.

contract PayoutClaimDistributor is Ownable {
    using MerkleProof for bytes32[];

    event SetMerkleRoot(bytes32 indexed merkleRoot);
    event ClaimedPayout(address indexed account, uint256 amount, uint256 batch);
    event DistributionLocked(bool isLocked);
    event SetDistributorAddress(address indexed ownerAddress, address indexed distAddress);

    bytes32 public merkleRoot;
    IERC20 public token;
    address public distAddress;
    bool public isLocked;

    /*
     * Mapping for hash for (address, amount, batch) for claimed status
     */
    mapping(bytes32 => bool) public claimed;

    /// @dev Constructor for setting ERC token address on deployment
    /// @param token_ Address for token to distribute
    /// @dev `distAddress` deployer address will be distributor address by default
    constructor(IERC20 token_) Ownable(msg.sender) {
        token = token_;
        distAddress = msg.sender;
    }

    /// @notice Merkle Root for current period to use for payout.
    ///    - distributor contract should be locked before setting new merkle root
    /// @dev Owner sets merkle hash generated based on the payout set
    /// @dev Reverts if the distribution contract is not locked while setting new merkle root
    /// @dev Emits SetMerkleRoot event.
    /// @param merkleRoot_ bytes32 string of merkle root to set for specific period
    function setMerkleRoot(bytes32 merkleRoot_) public {
        _requireOwnership(_msgSender());
        require(isLocked, "Payout not locked");

        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(merkleRoot_);
    }

    /// @notice Set locked/unlocked status  for PayoutClaim Distributor
    /// @dev Owner lock/unlock each time new merkle root is being generated
    /// @dev Emits DistributionLocked event.
    /// @param isLocked_ = true/false status
    function setLocked(bool isLocked_) public {
        _requireOwnership(_msgSender());
        isLocked = isLocked_;
        emit DistributionLocked(isLocked_);
    }

    /// @notice Distributor address in PayoutClaim Distributor
    /// @dev Wallet that holds token for distribution
    /// @dev Emits SetDistributorAddress event.
    /// @param distributorAddress Distributor address used for distribution of `token` token
    function setDistributorAddress(address distributorAddress) public {
        address msgSender = _msgSender();
        _requireOwnership(msgSender);

        distAddress = distributorAddress;
        emit SetDistributorAddress(msgSender, distributorAddress);
    }

    /// @notice Payout method that user calls to claim
    /// @dev Method user calls for claiming the payout for user
    /// @dev Emits ClaimedPayout event.
    /// @param account Address of the user to claim the payout
    /// @param amount Claimable amount of address
    /// @param batch Unique value for each new merkle root generating
    /// @param merkleProof Merkle proof of the user based on the merkle root
    function claimPayout(
        address account,
        uint256 amount,
        uint256 batch,
        bytes32[] calldata merkleProof
    ) external {
        require(!isLocked, "Payout locked");

        bytes32 leafHash = keccak256(abi.encodePacked(account, amount, batch));

        require(!claimed[leafHash], "Payout already claimed");
        require(merkleProof.verify(merkleRoot, leafHash), "Invalid proof");

        claimed[leafHash] = true;

        IERC20(token).transferFrom(distAddress, account, amount);

        emit ClaimedPayout(account, amount, batch);
    }
}