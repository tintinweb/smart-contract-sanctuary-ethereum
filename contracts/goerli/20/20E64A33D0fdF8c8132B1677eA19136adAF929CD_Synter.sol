// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ISynt.sol";
import "./interfaces/ISynter.sol";
import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Synter is the contract to operate with different types of synth (create, mint, burn, etc.)
 */
contract Synter is Ownable {
    address public rUsd; // rUSD address (Synt.sol)
    address[] public syntList; // list of all synt addresses
    mapping(address => SyntInfo) public syntInfo; // synt info by address
    address public synergy; // synergy contract (Synergy.sol)
    address public loan; // loan contract to borrow synts e.g. for shorts
    IOracle public oracle; // price oracle (Oracle.sol)
    address public treasury; // treasury address to fee collection
    uint32 public swapFee; // swap fee (e.g. 0.03%), 8 decimals
    uint32 public constant MAX_SWAP_FEE = 1e5; // swap fee maximum is 0.1%

    constructor(uint32 _swapFee) {
        require(_swapFee <= MAX_SWAP_FEE, "Swap fee cannot exceed MAX_SWAP_FEE amount");
        swapFee = _swapFee;
    }

    /* ================= INITIALIZATION ================= */

    /**
     * @dev Reinitialization available only for test purposes to spare goerli ETH
     */
    function initialize(
        address _rUsdAddress,
        address _synergyAddress,
        address _loanAddress,
        address _oracle,
        address _treasury
    )
        external
        onlyOwner
    {
        // require(_rUsdAddress != address(0) && rUsd == address(0), "Inicialize only once");
        // require(_synergyAddress != address(0) && synergy == address(0), "Inicialize only once");
        // require(_loanAddress != address(0) && loan == address(0), "Inicialize only once");
        // require(_oracle != address(0) && address(oracle) == address(0), "Inicialize only once");
        // require(_treasury != address(0) && treasury == address(0), "Inicialize only once");

        rUsd = _rUsdAddress;
        synergy = _synergyAddress;
        loan = _loanAddress;
        oracle = IOracle(_oracle);
        treasury = _treasury;
    }

    /* ================= SYNERGY AND LOAN FUNCTIONS ================= */

    function mintSynt(address _syntAddress, address _to, uint256 _amount) external {
        require(syntInfo[_syntAddress].syntId != 0 || _syntAddress == rUsd, "Synt doesn't exist");
        require(msg.sender == synergy || msg.sender == loan, "Only Synergy and Loan contracts");
        ISynt(_syntAddress).mint(_to, _amount);
    }

    function burnSynt(address _syntAddress, address _from, uint256 _amount) external {
        require(syntInfo[_syntAddress].syntId != 0 || _syntAddress == rUsd, "Synt doesn't exist");
        require(msg.sender == synergy || msg.sender == loan, "Only Synergy and Loan contracts");
        ISynt(_syntAddress).burnFrom(_from, _amount);
    }

    function increaseShorts(address _syntAddress, uint256 _amount) external {
        require(syntInfo[_syntAddress].syntId != 0, "Synt doesn't exist");
        require(msg.sender == synergy || msg.sender == loan, "Only Synergy and Loan contracts");
        syntInfo[_syntAddress].totalShorts += _amount;
    }

    function decreaseShorts(address _syntAddress, uint256 _amount) external {
        require(syntInfo[_syntAddress].syntId != 0, "Synt doesn't exist");
        require(msg.sender == synergy || msg.sender == loan, "Only Synergy and Loan contracts");
        syntInfo[_syntAddress].totalShorts -= _amount;
    }

    /* ================= OWNER FUNCTIONS ================= */

    function addSynt(address _syntAddress, bool _enableShorts) external onlyOwner {
        require(syntInfo[_syntAddress].syntId == 0, "Synt exists");
        syntInfo[_syntAddress].syntId = syntList.length + 1;
        syntInfo[_syntAddress].shortsEnabled = _enableShorts;

        syntList.push(_syntAddress);
    }

    function removeSynt(address _syntAddress) external onlyOwner {
        uint256 syntInd_ = getSyntInd(_syntAddress);
        syntList[syntInd_] = syntList[syntList.length - 1];
        syntList.pop();

        // removed != last
        if (syntList.length != syntInd_) {
            syntInfo[syntList[syntInd_]].syntId = syntInfo[_syntAddress].syntId;
        }

        delete syntInfo[_syntAddress];
    }

    function changeSwapFee(uint32 _newFee) external onlyOwner {
        require(_newFee <= MAX_SWAP_FEE, "Swap fee cannot exceed MAX_SWAP_FEE amount");
        swapFee = _newFee;
    }

    function setSyntMaxSupply(address _syntAddress, uint256 _amount) external onlyOwner {
        ISynt(_syntAddress).setMaxSupply(_amount);
    }

    function changeShortsAvailability(address _syntAddress, bool _val) external onlyOwner {
        require(syntInfo[_syntAddress].syntId != 0, "Synt doesn't exist");
        syntInfo[_syntAddress].shortsEnabled = _val;
    }

    /* ================= USER FUNCTIONS ================= */

    /**
     * @notice Swap from exact amount of synt-1 to calculated amount of synt-2 at the oracule price
     * @param _fromSynt address of synt to swap from
     * @param _toSynt address of synt to swap to
     * @param _amountFrom amount to spend
     */
    function swapFrom(address _fromSynt, address _toSynt, uint256 _amountFrom) external {
        require(syntInfo[_fromSynt].syntId != 0 || _fromSynt == rUsd, "First synt does not exist");
        require(syntInfo[_toSynt].syntId != 0 || _toSynt == rUsd, "Second synt does not exist");
        require(_amountFrom > 0, "Amount cannot be zero");

        (uint256 fromPrice_, uint8 fromDecimals_) = oracle.getPrice(_fromSynt);
        (uint256 toPrice_, uint8 toDecimals_) = oracle.getPrice(_toSynt);

        uint256 amountTo_ = (fromPrice_ * _amountFrom * 10 ** toDecimals_) / (toPrice_ * 10 ** fromDecimals_);

        uint256 fee_ = (amountTo_ * swapFee) / 1e8;

        ISynt(_fromSynt).burnFrom(msg.sender, _amountFrom);
        ISynt(_toSynt).mint(msg.sender, amountTo_ - fee_);
        ISynt(_toSynt).mint(treasury, fee_);
    }

    /**
     * @notice Swap from calculated amount of synt-1 to exact amount of synt-2 at the oracule price
     * @param _fromSynt address of synt to swap from
     * @param _toSynt address of synt to swap to
     * @param _amountTo amount to get
     */
    function swapTo(address _fromSynt, address _toSynt, uint256 _amountTo) external {
        require(syntInfo[_fromSynt].syntId != 0 || _fromSynt == rUsd, "First synt does not exist");
        require(syntInfo[_toSynt].syntId != 0 || _toSynt == rUsd, "Second synt does not exist");
        require(_amountTo > 0, "Amount cannot be zero");

        (uint256 fromPrice_, uint8 fromDecimals_) = oracle.getPrice(_fromSynt);
        (uint256 toPrice_, uint8 toDecimals_) = oracle.getPrice(_toSynt);

        uint256 amountFrom_ = (toPrice_ * _amountTo * 10 ** fromDecimals_) / (fromPrice_ * 10 ** toDecimals_);

        uint256 fee_ = (_amountTo * swapFee) / 1e8;

        ISynt(_fromSynt).burnFrom(msg.sender, amountFrom_);
        ISynt(_toSynt).mint(msg.sender, _amountTo - fee_);
        ISynt(_toSynt).mint(treasury, fee_);
    }

    /* ================= PUBLIC FUNCTIONS ================= */

    /**
     * @notice get synt index in syntList by id
     * @param _syntAddress address of the synt
     * @return index
     */
    function getSyntInd(address _syntAddress) public view returns (uint256) {
        uint256 syntId_ = syntInfo[_syntAddress].syntId;
        require(syntId_ != 0, "Synt doesn't exist");
        return syntId_ - 1;
    }

    /**
     * @notice get total number of synts except of rUSD
     * @return number of synts
     */
    function totalSynts() public view returns (uint256) {
        return syntList.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct SyntInfo {
    uint256 syntId; // unique synt id
    uint256 totalShorts; // total synts in shorts
    bool shortsEnabled; // synt can(not) be shorted (default = false)
}

interface ISynter {
    function mintSynt(address syntAddress, address to, uint256 amount) external;
    function burnSynt(address syntAddress, address from, uint256 amount) external;
    function addSynt(string calldata name, string calldata symbol) external returns (address syntAddress);
    function removeSynt(address syntAddress) external;
    function setSyntMaxSupply(address syntAddress, uint256 amount) external;
    function changeShortsAvailability(address syntAddress, bool val) external;
    function increaseShorts(address _syntAddress, uint256 _amount) external;
    function decreaseShorts(address _syntAddress, uint256 _amount) external;

    function swapFrom(address fromSynt, address toSynt, uint256 amountFrom) external;
    function swapTo(address fromSynt, address toSynt, uint256 amountTo) external;

    function syntList(uint256 syntId) external view returns (address syntAddress);
    function syntInfo(address syntAddress) external view returns (SyntInfo memory);
    function getSyntInd(address _syntAddress) external view returns (uint256);
    function totalSynts() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISynt is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
    function setMaxSupply(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IOracle {
    function getPrice(address _address) external view returns (uint256, uint8);
    function changeFeed(address _address, address _priceFeed) external;
    function changeRusdAddress(address _newAddress) external;
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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