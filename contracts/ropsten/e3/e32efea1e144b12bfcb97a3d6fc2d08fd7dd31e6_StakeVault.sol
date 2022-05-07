/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
// File: interfaces/IToken.sol


pragma solidity 0.8.12;

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(uint256 amount) external;

    function balanceOf(address _user) external returns (uint256);

    /**
     @return taxAmount // total Tax Amount
     @return taxType // How the tax will be distributed
    */
    function calculateTransferTax(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 taxAmount, uint8 taxType);
}

// File: interfaces/IVault.sol


pragma solidity 0.8.12;

interface IVault {
    /**
    * @param amount total amount of tokens to recevie
    * @param _type type of spread to execute.
      Stake Vault - Reservoir Collateral - Treasury
      0: do nothing
      1: Buy Spread 5 - 5 - 3
      2: Sell Spread 5 - 5 - 8
      @return bool as successful spread op
    **/
    function spread(
        uint256 amount,
        uint8 _type,
        address _customTaxSender
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/StakeVault.sol



pragma solidity 0.8.12;




contract StakeVault is Ownable, IVault {
    IToken public token;

    struct TaxDistribution {
        uint256 treasury;
        uint256 foundation;
        uint256 vault;
        uint256 total;
    }

    mapping(address => bool) public whitelist;
    mapping(address => TaxDistribution) public taxDistribution;

    address public foundation;
    address public treasury;

    event AddedWhitelist(address indexed _user);
    event RemovedWhitelist(address indexed _user);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Not Whitelist");
        _;
    }

    constructor(address _token) {
        token = IToken(_token);
        taxDistribution[address(0)] = TaxDistribution(0, 0, 1, 1); //Tax Distribution for transfers, all for vault
        taxDistribution[address(1)] = TaxDistribution(3, 5, 5, 13); //Tax Distribution for buys
        taxDistribution[address(2)] = TaxDistribution(8, 5, 5, 18); //Tax Distribution for sells
    }

    function addWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
        emit AddedWhitelist(_user);
    }

    function removeWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
        emit RemovedWhitelist(_user);
    }

    function editTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Cant do that");
        treasury = _newTreasury;
    }

    function editFoundation(address _newFoundation) external onlyOwner {
        require(_newFoundation != address(0), "Cant do that");
        foundation = _newFoundation;
    }

    function withdraw(uint256 amount) external onlyWhitelist {
        require(amount <= token.balanceOf(address(this)), "Not enough funds");
        IToken(token).transfer(msg.sender, amount);
    }

    function spread(
        uint256 amount,
        uint8 _type,
        address custom
    ) external override onlyWhitelist returns (bool) {
        require(_type > 0, "Wrong Implementation");

        TaxDistribution storage _spread = _type < 4
            ? taxDistribution[address(uint160(_type - 1))]
            : taxDistribution[custom];
        if (_spread.total == 0)
            // if custom taxes have not been setup, use transfers Distribution
            _spread = taxDistribution[address(0)];
        require(amount > token.balanceOf(address(this)), "Insufficient funds");
        receiveFunds(
            amount,
            _spread.vault,
            _spread.foundation,
            _spread.treasury
        );
        return true;
    }

    ///@notice it sends funds from the user/contract calling the function and distributes the token into the three categories
    ///@param _received Amount of tokens to work with
    ///@param _vault Percentage that stays in the vault
    ///@param _collateral Percentage that goes to the
    function receiveFunds(
        uint256 _received,
        uint256 _vault,
        uint256 _collateral,
        uint256 _treasury
    ) internal {
        uint256 total = _vault + _collateral + _treasury;
        uint256 vaultAmount = (_received * _vault) / total;
        uint256 collateralAmount = (_received * _collateral) / total;
        uint256 _trove = _received - vaultAmount - collateralAmount;

        token.transferFrom(msg.sender, address(this), vaultAmount);
        token.transferFrom(msg.sender, foundation, collateralAmount);
        token.transferFrom(msg.sender, treasury, _trove);
    }

    function taxCustomDistribution(
        address _user,
        uint256 _total,
        uint256 _treasure,
        uint256 _foundation,
        uint256 _vault
    ) external onlyOwner {
        require(_treasure + _foundation + _vault == _total, "Fee mismatch");
        taxDistribution[_user] = TaxDistribution(
            _treasure,
            _foundation,
            _vault,
            _total
        );
    }
}