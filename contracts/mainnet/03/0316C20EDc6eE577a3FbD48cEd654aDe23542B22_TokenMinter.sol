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
    ///// Collection ///////////////////////////
    error AddressZero();
    error MetadataIsFrozen();
    error MintingIsFrozen();
    error PriceTooLow();
    error MaxSupplyReached();
    error MaxSupplyReachedForAddress();
    error CurrentSupplyExceedsMaxSupply();
    error TokenDoesNotExist();
    ///// TokenMinter /////////////////////
    error WithdrawalParamsAccessDenied();
    error NoBalanceToWithdraw();
    error AddressZeroForWithdraw();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICybaspaceGenesisCollection {
    function mint(address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokenMinter {
    /// @notice triggers whenever a withdrawaladdress gets changed
    /// @param txSender the address that initiated the address change
    /// @param to the new withdrawaladress
    /// @param changedAddress name of adress that is changed
    event WithdrawalAddressSet(
        address indexed txSender,
        address indexed to,
        string changedAddress
    );
    /// @notice triggers whenever a withdrawaladdress gets changed
    /// @param txSender the address that initiated the dev share change
    /// @param oldValue the dev share before
    /// @param newValue the dev share after 
    event devShareSet(
        address indexed txSender,
        uint256 oldValue,
        uint256 newValue
    );
    /// @notice triggers whenever a shareholder receives their share of a withdrawal
    /// @param txSender the address that initiated the withdrawal
    /// @param to the address of the shareholder receiving this part of the withdrawal
    /// @param amount the amount of eth received by `to`
    event PaidOut(address indexed txSender, address indexed to, uint256 amount);
    /// @notice triggers whenever funds are withdrawn
    /// @param txSender the sender of the transaction
    /// @param amount the amount of eth withdrawn
    event Withdrawn(address indexed txSender, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./abstract/CustomErrors.sol";
import "./interfaces/ICybaspaceGenesisCollection.sol";
import "./interfaces/ITokenMinter.sol";

contract TokenMinter is Ownable, CustomErrors, ITokenMinter {
    ICybaspaceGenesisCollection public collection;

    uint256 public devShare;

    address public withdrawalDevTeam;
    address public withdrawalCompany;

    ///// MODIFIERS ////////////////////////////////////////////////
    modifier checkAddress(address _address) {
        if (_address == address(0)) revert AddressZero();
        _;
    }

    ////////////////////////////////////////////////////////////////

    /**
     * @param _collection Address of the CybaspaceGenesis collection contract
     * @param _devShare Share of funds for dev team
     */
    constructor(ICybaspaceGenesisCollection _collection, uint256 _devShare) {
        collection = _collection;
        devShare = _devShare;
    }

    /**
     * @dev Mints a CybaspaceGenesisToken to the given address
     *
     * @param _to Address which will receive the token
     */
    function mintToken(address _to) external payable {
        collection.mint(_to, msg.value);
    }

    /**
     * @notice Set dev team wallet can only decrease dev share, company wallet only increase
     * @dev Sets dev share
     *
     * @param _devShare New dev share value
     */
    function setDevShare(uint256 _devShare) external onlyOwner {
        uint256 oldShare = devShare;
        devShare = _devShare;
        emit devShareSet(_msgSender(), oldShare, devShare);
    }

    /**
     * @notice Callable only by the currently set dev team wallet / owner of contract if not set
     * @dev Sets withdrawal address for dev team to equal the specified value
     *
     * @param _address New address value for withdrawing funds for dev team
     */
    function setAddressDevTeam(
        address _address
    ) external checkAddress(_address) onlyOwner {
        withdrawalDevTeam = _address;
        emit WithdrawalAddressSet(_msgSender(), _address, "withdrawalDevTeam");
    }

    /**
     * @notice Callable only by the currently set company wallet / owner of contract if not set
     * @dev Sets withdrawal address for company to equal the specified value
     *
     * @param _address New address value for withdrawing funds for company
     */
    function setAddressCompany(
        address _address
    ) external checkAddress(_address) onlyOwner {
        withdrawalCompany = _address;
        emit WithdrawalAddressSet(_msgSender(), _address, "withdrawalCompany");
    }

    /**
     * @notice Callable only by the owner of this contract / deployer wallet
     * @dev withdraws funds according to share rule for involved participants
     */
    function withdraw() external onlyOwner {
        if (address(this).balance <= 0) revert CurrentSupplyExceedsMaxSupply();
        if (withdrawalDevTeam == address(0)) revert AddressZeroForWithdraw();
        if (withdrawalCompany == address(0)) revert AddressZeroForWithdraw();

        uint256 balance = address(this).balance;

        uint256 shareDevTeamFunds = ((balance * devShare) / 10000);
        uint256 shareCompanyFunds = ((balance * (10000 - devShare)) / 10000);

        payable(withdrawalDevTeam).transfer(shareDevTeamFunds);
        emit PaidOut(_msgSender(), withdrawalDevTeam, shareDevTeamFunds);
        payable(withdrawalCompany).transfer(shareCompanyFunds);
        emit PaidOut(_msgSender(), withdrawalCompany, shareCompanyFunds);

        emit Withdrawn(_msgSender(), balance);
    }
}