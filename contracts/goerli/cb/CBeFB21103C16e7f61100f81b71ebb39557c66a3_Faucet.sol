pragma solidity 0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Signature over the hash of essential data
    struct DataSignature {
        // we are able to pack these two unsigned ints into a
        uint248 deadline; // deadline defined in ETH1 blocks
        uint8 v; // signature component 1

        bytes32 r; // signature component 2
        bytes32 s; // signature component 3
    }

interface ITransactionRouter {
    /// @notice function to register the ETH2 validator by depositing 32ETH to EF deposit contract
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerValidator(
        address _user,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        DataSignature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable;
}

interface IWETH {
    function withdraw(uint wad) external;

    function balanceOf(address _user) view external returns(uint256);
}

/// @notice Contract to accumulate Ethereum used for creating new knot's in the Stakehouse universe
contract Faucet is Ownable {

    /// @notice notify about balance threshold update
    /// @param newThreshold - new threshold user should posses
    event BalanceThresholdUpdated(uint256 newThreshold);

    /// @notice Hardcoded Goerli WETH address
    IWETH public WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    /// @notice Transaction manager used for forming knots in the stakehouse universe
    ITransactionRouter public TransactionRouter;

    /// @dev Only accepted amount to be deposited for validator (Full validator amount)
    uint256 public constant DEPOSIT_AMOUNT = 32 ether;

    /// @dev threshold the user should posses
    uint256 public VALUE_THRESHOLD;

    /// @notice set TransactionRouter adaptor address
    /// @param _trxRouter - Address of the transaction router
    function setTransactionRouter(address _trxRouter) external onlyOwner {
        require(_trxRouter != address(0), 'Transaction router is 0');

        TransactionRouter = ITransactionRouter(_trxRouter);
    }

    /// @notice Do an emergency withdrawal
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice Do accumulated WETH unwrapping
    function unwrap() public {
        uint256 balance = WETH.balanceOf(address(this));

        if (balance > 0) {
            WETH.withdraw(balance);
        }
    }

    /// @notice Update the balance threshold
    /// @param _amount - new balance threshold
    function updateBalanceThreshold(uint256 _amount) external onlyOwner {
        require(_amount >= 0 && _amount <= DEPOSIT_AMOUNT, 'Invalid threshold');

        VALUE_THRESHOLD = _amount;

        emit BalanceThresholdUpdated(_amount);
    }

    /// @notice function to register the ETH2 validator by depositing 32ETH to EF deposit contract
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerValidator(
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        DataSignature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable {
        require(
            msg.value >= VALUE_THRESHOLD,
            'Value sent should meet or exceed the THRESHOLD'
        );

        unwrap();

        TransactionRouter.registerValidator{value: DEPOSIT_AMOUNT}(
            msg.sender,
            _blsPublicKey,
            _ciphertext,
            _aesEncryptorKey,
            _encryptionSignature,
            _dataRoot
        );
    }

    receive() external payable {}
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