// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICustomERC20.sol";

contract CustomERC20 is ICustomERC20, Ownable {
    mapping(address => Beneficiar) public beneficiaries;
    bool public isLocked;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function allowance(address _account, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowed[_account][spender];
    }

    function decimals() external pure virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(
            value <= balances[msg.sender],
            "ERC20: Transfer more value than msg.sender balance"
        );

        _transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            value <= balances[from],
            "ERC20: transfer more value than balance from address"
        );
        require(
            value <= allowed[from][msg.sender],
            "ERC20: allowed value is less than "
        );

        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;

        return true;
    }

    /**
     * @dev Transfer tokens from the owner to the distribution contract
     *
     * Returns tokens amount in contract
     *
     * Emits a {Transfer} event.
     */
    function deposit(uint256 _amount) external override onlyOwner {
        require(balances[msg.sender] >= _amount, "Not enough funds");
        _transfer(msg.sender, address(this), _amount);
    }

    /**
     * @dev Add array of beneficaries with their amount.
     *
     * @param _beneficiaries - array of beneficaries
     * @param _amount - array of amount for each beneficiary reward
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _amount
    ) external override onlyOwner {
        require(
            _beneficiaries.length == _amount.length,
            "The length of two arrays is not equal"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _addBeneficiary(_beneficiaries[i], _amount[i]);
        }
    }

    /**
     * @dev Add beneficary with amount.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - how much beneficiary reward token amounts is
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiary(address _beneficiary, uint256 _amount)
        external
        override
        onlyOwner
    {
        _addBeneficiary(_beneficiary, _amount);
    }

    /**
     * @dev Decrease the amount of rewards for a beneficiary.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - for how much should decrease rewards amount
     *
     * Emits a {BeneficiaryReward} event.
     */
    function decreaseReward(address _beneficiary, uint256 _amount)
        external
        override
        onlyOwner
    {
        require(
            beneficiaries[_beneficiary].reward != 0,
            "Beneficiary is not exists"
        );
        require(
            !beneficiaries[_beneficiary].isClaimed,
            "Reward tokens is already withdrawn"
        );
        uint256 _reward = beneficiaries[_beneficiary].reward;
        require(
            _reward > _amount,
            "Beneficiary reward amount is less or equals zero"
        );

        beneficiaries[_beneficiary].reward -= _amount;
        emit BeneficiaryReward(_beneficiary, _reward);
    }

    /**
     * @dev Transfer amount of reward tokens back to the owner.
     *
     * @param _amount - amount of reward that should be withdrowed
     *
     * Emits a {Transfer} event.
     */
    function emergencyWithdraw(uint256 _amount) external override onlyOwner {
        require(
            balances[address(this)] >= _amount,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, _amount);
    }

    /**
     * @dev Lock/unlock rewards for beneficiary.
     *
     * Emits a {LockedReward} event.
     */
    function lockRewards(bool isLock) external override onlyOwner {
        isLocked = isLock;
    }

    /**
     * @dev Transfer reward tokens to beneficiary. Can be called when reward is not locked.
     *
     * no params
     *
     * Emits a {Transfer} event.
     */
    function claim() external override {
        require(!isLocked, "Reward is locked");
        require(
            !beneficiaries[msg.sender].isClaimed,
            "Reward tokens is already withdrawn"
        );
        uint256 _reward = beneficiaries[msg.sender].reward;
        require(_reward != 0, "Reward is zero");
        require(
            balances[address(this)] >= _reward,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, _reward);
        beneficiaries[msg.sender].isClaimed = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            balances[from] = fromBalance - amount;
        }
        balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _addBeneficiary(address _beneficiary, uint256 _amount) private {
        require(
            beneficiaries[_beneficiary].reward == 0,
            "Beneficiary is already added"
        );
        beneficiaries[_beneficiary].reward = _amount;
        emit AdddedBeneficiary(_beneficiary, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the CustomERC20 extends from ERC20 standard as defined in the EIP and some custom functions.
 */
interface ICustomERC20 is IERC20, IERC20Metadata {
    /**
     * @dev Emitted when the new beneficiary is added with reward amount
     */
    event AdddedBeneficiary(address indexed _beneficiary, uint256 _amount);

    /**
     * @dev Emitted when the beneficiary reward amount is decrease
     */
    event BeneficiaryReward(address indexed _beneficiary, uint256 _amount);

    struct Beneficiar {
        uint256 reward;
        bool isClaimed;
    }

    /**
     * @dev Transfer tokens from the owner to the distribution contract
     *
     * Returns tokens amount in contract
     *
     * Emits a {Transfer} event.
     */
    function deposit(uint256 _amount) external;

    /**
     * @dev Add array of beneficaries with their amount.
     *
     * @param _beneficiaries - array of beneficaries
     * @param _amount - array of amount for each beneficiary reward
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _amount
    ) external;

    /**
     * @dev Add beneficary with amount.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - how much beneficiary reward token amounts is
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiary(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Decrease the amount of rewards for a beneficiary.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - for how much should decrease rewards amount
     *
     * Emits a {BeneficiaryReward} event.
     */
    function decreaseReward(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Transfer amount of reward tokens back to the owner.
     *
     * @param _amount - amount of reward that should be withdrowed
     *
     * Emits a {Transfer} event.
     */
    function emergencyWithdraw(uint256 _amount) external;

    /**
     * @dev Lock/unlock rewards for beneficiary.
     *
     * Emits a {LockedReward} event.
     */
    function lockRewards(bool isLock) external;

    /**
     * @dev Transfer reward tokens to beneficiary. Can be called when reward is not locked.
     *
     * no params
     *
     * Emits a {Transfer} event.
     */
    function claim() external;
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