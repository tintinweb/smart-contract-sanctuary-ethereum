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
    error TokenDoesNotExist();
    ///// TokenMinter /////////////////////
    error NotWhitelisted();
    error LengthsMismatch();
    error MaxSupplyReached();
    error CurrentSupplyExceedsMaxSupply();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICybaspaceGenesisToken {
    function mint(address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

import './abstract/CustomErrors.sol';
import './interfaces/ICybaspaceGenesisToken.sol';

contract TokenMinter is Ownable, CustomErrors {
    ICybaspaceGenesisToken public gstToken;

    uint256 public gstTokenPrice;

    uint256 public maxSupply;
    uint256 public currentSupply;

    mapping(address => bool) public whitelisted;
    mapping(uint256 => uint256) public tokenIdToInvestmentAmount;

    ///// MODIFIERS ////////////////////////////////////////////////
    modifier checkAddress(address _address) {
        if (_address == address(0)) revert AddressZero();

        _;
    }

    modifier checkStatus(address _account) {
        if (whitelisted[_account] != true) revert NotWhitelisted();

        _;
    }

    ////////////////////////////////////////////////////////////////

    /**
     * @param _gstToken Address of the CybaspaceGenesis token contract
     * @param _maxSupply Maximum amount of tokens that can be minted
     */
    constructor(ICybaspaceGenesisToken _gstToken, uint256 _maxSupply) {
        maxSupply = _maxSupply;
        gstToken = _gstToken;
    }

    /**
     * @dev Mints a CybaspaceGenesisToken to the given address
     *
     * @param _to Address which will receive the token
     */
    function mintCybaspaceGenesisToken(
        address _to
    ) external payable checkAddress(_to) checkStatus(_msgSender()) {
        if (currentSupply + 1 > maxSupply) revert MaxSupplyReached();

        tokenIdToInvestmentAmount[++currentSupply] = msg.value;

        gstToken.mint(_to, currentSupply);
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
     * @dev Alters the whitelisted status of the given addresses to the given boolean at the same place in the array
     *
     * @param _accounts Array of wallet addresses whose status needs to be altered
     * @param _statuses Array of booleans which imply if the address is whitelisted or not
     */
    function alterWhitelistedStatus(
        address[] memory _accounts,
        bool[] memory _statuses
    ) external onlyOwner {
        if (_accounts.length != _statuses.length) revert LengthsMismatch();

        uint256 length = _accounts.length;

        for (uint256 i = 0; i < length; ) {
            whitelisted[_accounts[i]] = _statuses[i];

            unchecked {
                i++;
            }
        }
    }
}