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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract CustomErrors {
    ///// Tokens ///////////////////////////
    error AddressZero();
    error MetadataIsFrozen();
    error MintingIsFrozen();
    error PriceTooLow();
    error TokenDoesNotExist();
    ///// TokenMinter /////////////////////
    error NotWhitelisted();
    error LengthsMismatch();
    error MaxSupplyReached();
    error MaxSupplyReachedForAddress();
    error CurrentSupplyExceedsMaxSupply();
    error NoBalanceToWithdraw();
    error AddressZeroForWithdraw();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICybaspaceGenesisToken {
    function mint(address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokenMinter {
    /// @notice triggers whenever a shareholder receives their share of a withdrawal
    /// @param txSender the address that initiated the withdrawal
    /// @param to the address of the shareholder receiving this part of the withdrawal
    /// @param amount the amount of eth received by `to`
    event PaidOut(
        address indexed txSender,
        address indexed to,
        uint256 amount
    );
    /// @notice triggers whenever funds are withdrawn
    /// @param txSender the sender of the transaction
    /// @param amount the amount of eth withdrawn
    event Withdrawn(address indexed txSender, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

import './abstract/CustomErrors.sol';
import './interfaces/ICybaspaceGenesisToken.sol';
import './interfaces/ITokenMinter.sol';

contract TokenMinter is Ownable, CustomErrors, ITokenMinter {
    ICybaspaceGenesisToken public token;

    // uint256 cstTokenPrice = 50000000000000000; == 0.05 ETH.
    uint256 public tokenPrice;

    uint256 public maxSupplyPerAddress;
    uint256 public maxSupply;
    uint256 public currentSupply;

    address private withdrawlCreate3labs;
    address private withdrawlCybaspace;

    mapping(address => uint8) public mintedAddresses;

    ///// MODIFIERS ////////////////////////////////////////////////
    modifier checkAddress(address _address) {
        if (_address == address(0)) revert AddressZero();

        _;
    }

    modifier checkPrice(uint256 price) {
        if (price < tokenPrice) revert PriceTooLow();

        _;
    }

    ////////////////////////////////////////////////////////////////

    /**
     * @param _token Address of the CybaspaceGenesis token contract
     * @param _maxSupply Maximum amount of tokens that can be minted
     */
    constructor(ICybaspaceGenesisToken _token, uint256 _maxSupply, uint256 _maxSupplyPerAddress, uint256 _tokenPrice) {
        maxSupply = _maxSupply;
        maxSupplyPerAddress = _maxSupplyPerAddress;
        token = _token;
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Mints a CybaspaceGenesisToken to the given address
     *
     * @param _to Address which will receive the token
     */
    function mintToken(
        address _to
    ) external payable checkAddress(_to) checkPrice(msg.value) {
        if (currentSupply + 1 > maxSupply) revert MaxSupplyReached();

        // allow only maxSupplyPerAddress mints per address
        if (mintedAddresses[_to] >= maxSupplyPerAddress) revert MaxSupplyReachedForAddress();
        mintedAddresses[_to] = mintedAddresses[_to] + 1;

        ++currentSupply;

        token.mint(_to, currentSupply);
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets maxSupply to equal the specified value
     *
     * @param _maxSupply New maxSupply value
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < currentSupply) revert CurrentSupplyExceedsMaxSupply();
        maxSupply = _maxSupply;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets cstTokenPrice to equal the specified value
     *
     * @param _tokenPrice New cstTokenPrice value
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets withdrawlCreate3labs to equal the specified value
     *
     * @param _address New address value for funds for Create3Labs
     */
    function setAddressCreate3Labs(address _address) external onlyOwner {
        withdrawlCreate3labs = _address;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev Sets withdrawlCybaspace to equal the specified value
     *
     * @param _address New address value for funds for Cybaspace
     */
    function setAddressCybaspace(address _address) external onlyOwner {
        withdrawlCybaspace = _address;
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev withdraws funds according to 90/10 rule for involved participants
     */
    function withdraw() external onlyOwner {
        if (address(this).balance <= 0) revert CurrentSupplyExceedsMaxSupply();
        if (withdrawlCreate3labs == address(0)) revert AddressZeroForWithdraw();
        if (withdrawlCybaspace == address(0)) revert AddressZeroForWithdraw();

        uint256 balance = address(this).balance;

        uint256 shareCreate3LabsFunds = (balance * 10 / 100);
        uint256 shareCybaSpaceFunds = (balance * 90 / 100);

        payable(withdrawlCreate3labs).transfer(shareCreate3LabsFunds);
        emit PaidOut(_msgSender(), withdrawlCreate3labs, shareCreate3LabsFunds);
        payable(withdrawlCybaspace).transfer(shareCybaSpaceFunds);
        emit PaidOut(_msgSender(), withdrawlCybaspace, shareCybaSpaceFunds);

        emit Withdrawn(_msgSender(), balance);

    }
}