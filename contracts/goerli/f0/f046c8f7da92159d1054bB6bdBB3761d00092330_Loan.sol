// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ISynt.sol";
import "./interfaces/ILoan.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ISynter.sol";
import "./interfaces/IOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Loan is the contract to borrow synts for shorts or other purposes
 */
contract Loan is Ownable {
    event Borrowed(address indexed synt, bytes32 indexed borrowId, uint256 amountBorrowed, uint256 amountPledged);
    event Deposited(bytes32 indexed borrowId, uint256 amount);
    event Repayed(bytes32 indexed borrowId, uint256 amount);
    event Withdrawed(bytes32 indexed borrowId, uint256 amount);
    event LoanClosed(bytes32 indexed borrowId);
    event Liquidated(address indexed user, bytes32 indexed borrowId, uint256 syntAmount);

    ISynt public rUsd; // rUsd address
    ISynter public synter; // address of the Synter contract
    IOracle public oracle; // oracle to get synt prices
    ITreasury public treasury; // treasury address to collect rewards
    uint32 public minCollateralRatio; // min collateral ration e.g. 1.2 (8 decimals)
    uint32 public liquidationCollateralRatio; // collateral ratio to enough to liquidate e.g. 1.2 (8 decimals)
    uint32 public liquidationPenalty; // rewards for liquidation e.g 0.1 (8 decimals)
    uint32 public treasuryFee; // treasury liquidation fee e.g. 0.2 (8 decimals)
    mapping(bytes32 => UserLoan) public loans;
    mapping(address => bytes32[]) public userLoans;

    constructor(
        uint32 _minCollateralRatio,
        uint32 _liquidationCollateralRatio,
        uint32 _liquidationPenalty,
        uint32 _treasuryFee
    ) {
        require(
            _liquidationCollateralRatio <= _minCollateralRatio,
            "liquidationCollateralRatio should be <= minCollateralRatio"
        );
        require(
            1e8 + _liquidationPenalty + _treasuryFee <= _liquidationCollateralRatio,
            "1 + liquidationPenalty + treasuryFee should be <= liquidationCollateralRatio"
        );
        minCollateralRatio = _minCollateralRatio;
        liquidationCollateralRatio = _liquidationCollateralRatio;
        liquidationPenalty = _liquidationPenalty;
        treasuryFee = _treasuryFee;
    }

    /* ================= INITIALIZATION ================= */
    /**
     * @dev Reinitialization available only for test purposes to spare goerli ETH
     */
    function initialize(address _rUsd, address _synter, address _oracle, address _treasury) external onlyOwner {
        // require(_rUsd != address(0) && address(rUsd) == address(0), "Inicialize only once");
        // require(_synter != address(0) && address(synter) == address(0), "Inicialize only once");
        // require(_treasury != address(0) && address(treasury) == address(0), "Inicialize only once");
        // require(_oracle != address(0) && address(oracle) == address(0), "Inicialize only once");

        rUsd = ISynt(_rUsd);
        synter = ISynter(_synter);
        oracle = IOracle(_oracle);
        treasury = ITreasury(_treasury);
    }

    /* ================= USER FUNCTIONS ================= */

    /**
     * @notice Borrow synt and pay rUSD as a collateral
     * @param _syntAddress address of synt to borrow
     * @param _amountToBorrow amount of synt to borrow
     * @param _amountToPledge amount of rUSD to leave as a collateral
     */
    function borrow(address _syntAddress, uint256 _amountToBorrow, uint256 _amountToPledge) external {
        require(synter.syntInfo(_syntAddress).shortsEnabled, "Shorts for the synt should be turned on");
        require(_amountToBorrow != 0, "Borrow ammount cannot be zero");

        bytes32 borrowId_ = keccak256(abi.encode(msg.sender, msg.data, block.number, userLoans[msg.sender].length));
        require(loans[borrowId_].user == address(0), "Cannot duplicate loans");

        userLoans[msg.sender].push(borrowId_);
        loans[borrowId_] = UserLoan({
            user: msg.sender,
            syntAddress: _syntAddress,
            borrowed: _amountToBorrow,
            collateral: _amountToPledge,
            minCollateralRatio: minCollateralRatio,
            liquidationCollateralRatio: liquidationCollateralRatio,
            liquidationPenalty: liquidationPenalty,
            treasuryFee: treasuryFee,
            loanIndex: uint32(userLoans[msg.sender].length - 1)
        });

        uint32 collateralRatio_ = collateralRatio(borrowId_);
        require(collateralRatio_ >= minCollateralRatio, "Collateral ration less than minCollateralRatio");

        rUsd.transferFrom(msg.sender, address(this), _amountToPledge);
        synter.increaseShorts(_syntAddress, _amountToBorrow);
        synter.mintSynt(_syntAddress, msg.sender, _amountToBorrow);

        emit Borrowed(_syntAddress, borrowId_, _amountToBorrow, _amountToPledge);
    }

    /**
     * @notice Deposit rUSD to collateral by borrowId to increase collateral rate and escape liquidation
     * @param _borrowId uniquie id of the loan
     * @param _amount amoount of rUSD to deposit
     */
    function deposit(bytes32 _borrowId, uint256 _amount) external {
        UserLoan storage loan = loans[_borrowId];

        require(loan.user == msg.sender, "Cannot deposit to someone else's loan");

        loan.collateral += _amount;
        rUsd.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(_borrowId, _amount);
    }

    /**
     * @notice Repay debt and return collateral
     * @param _borrowId uniquie id of the loan
     * @param _amountToRepay amount of synt to repay
     */
    function repay(bytes32 _borrowId, uint256 _amountToRepay) external {
        UserLoan storage loan = loans[_borrowId];

        require(loan.user == msg.sender, "Cannot repay someone else's loan");

        loan.borrowed -= _amountToRepay;
        synter.decreaseShorts(loan.syntAddress, _amountToRepay);
        synter.burnSynt(loan.syntAddress, msg.sender, _amountToRepay);

        emit Repayed(_borrowId, _amountToRepay);
    }

    /**
     * @notice Withdraw rUSD from collateral
     * @param _borrowId uniquie id of the loan
     * @param _amount amount of rUSD to withdraw
     */
    function withdraw(bytes32 _borrowId, uint256 _amount) external {
        UserLoan storage loan = loans[_borrowId];

        require(loan.user == msg.sender, "Cannot withdraw from someone else's loan");

        loan.collateral -= _amount;

        uint32 collateralRatio_ = collateralRatio(_borrowId);
        require(
            collateralRatio_ >= loan.minCollateralRatio || collateralRatio_ == 0,
            "Result ration less than minCollateralRatio"
        );

        rUsd.transfer(msg.sender, _amount);

        emit Withdrawed(_borrowId, _amount);

        if (loan.collateral == 0 && loan.borrowed == 0) {
            // close loan
            uint32 loanIndex_ = loan.loanIndex;
            uint256 totalLoans_ = userLoans[msg.sender].length;
            userLoans[msg.sender][loanIndex_] = userLoans[msg.sender][totalLoans_ - 1];
            userLoans[msg.sender].pop();
            // change index of the last collateral which was moved
            if (userLoans[msg.sender].length != loanIndex_) {
                loans[userLoans[msg.sender][loanIndex_]].loanIndex = loanIndex_;
            }
            delete loans[_borrowId];

            emit LoanClosed(_borrowId);
        }
    }

    /**
     * @notice Function to liquidate under-collaterized positions
     * @dev This function has no UI in the protocol app
     * @param _borrowId unique borrow id
     */
    function liquidate(bytes32 _borrowId) external {
        UserLoan storage loan = loans[_borrowId];
        require(loan.user != address(0), "Loan doesn't exist");
        require(collateralRatio(_borrowId) < loan.liquidationCollateralRatio, "Cannot liquidate yet");

        (uint256 rUsdPrice_, uint8 rUsdDecimals_) = oracle.getPrice(address(rUsd));
        (uint256 syntPrice_, uint8 syntDecimals_) = oracle.getPrice(address(loan.syntAddress));

        uint256 neededSynt_ = (
            loan.minCollateralRatio * loan.borrowed * syntPrice_ * 10 ** rUsdDecimals_
                - loan.collateral * rUsdPrice_ * 10 ** (8 + syntDecimals_)
        )
            / (
                syntPrice_ * 10 ** rUsdDecimals_
                    * (loan.minCollateralRatio - (1e8 + loan.liquidationPenalty + loan.treasuryFee))
            );

        uint256 liquidatedRusd_ = (
            neededSynt_ * syntPrice_ * (1e8 + loan.liquidationPenalty + loan.treasuryFee) * 10 ** rUsdDecimals_
        ) / (rUsdPrice_ * 10 ** (8 + syntDecimals_));

        uint256 liquidatorReward_ =
            liquidatedRusd_ * (1e8 + loan.liquidationPenalty) / (1e8 + loan.liquidationPenalty + loan.treasuryFee);

        uint256 treasuryReward_ =
            liquidatedRusd_ * loan.treasuryFee / (1e8 + loan.liquidationPenalty + loan.treasuryFee);

        // if CR dropped too low
        // we pay the liquidator at the expense of other people's collateral
        // and reimburse the losses at the expense of the treasury manually

        if (liquidatorReward_ + treasuryReward_ <= loan.collateral) {
            unchecked {
                loan.collateral -= liquidatorReward_ + treasuryReward_;
            }
        } else {
            loan.collateral = 0;
        }
        if (neededSynt_ <= loan.borrowed) {
            unchecked {
                loan.borrowed -= neededSynt_;
            }
        } else {
            loan.borrowed = 0;
        }

        synter.burnSynt(loan.syntAddress, msg.sender, neededSynt_);
        rUsd.transfer(address(treasury), treasuryReward_);
        rUsd.transfer(msg.sender, liquidatorReward_);

        emit Liquidated(loan.user, _borrowId, neededSynt_);

        if (loan.collateral == 0 && loan.borrowed == 0) {
            // close loan
            uint32 loanIndex_ = loan.loanIndex;
            uint256 totalLoans_ = userLoans[msg.sender].length;
            userLoans[msg.sender][loanIndex_] = userLoans[msg.sender][totalLoans_ - 1];
            userLoans[msg.sender].pop();
            // change index of the last collateral which was moved
            if (userLoans[msg.sender].length != loanIndex_) {
                loans[userLoans[msg.sender][loanIndex_]].loanIndex = loanIndex_;
            }
            delete loans[_borrowId];

            emit LoanClosed(_borrowId);
        }
    }

    /* ================= PUBLIC FUNCTIONS ================= */

    /**
     * @notice Calculate collateral ratio for given borrowId
     * @dev returns 18 decimal
     * @param _borrowId uniquie id of the loan
     * @return collateralRatio_ collateral ratio
     */
    function collateralRatio(bytes32 _borrowId) public view returns (uint32 collateralRatio_) {
        UserLoan storage loan = loans[_borrowId];
        require(loan.user != address(0), "Loan doesn't exist");

        (uint256 rUsdPrice_, uint8 rUsdDecimals_) = oracle.getPrice(address(rUsd));
        (uint256 syntPrice_, uint8 syntDecimals_) = oracle.getPrice(address(loan.syntAddress));

        if (syntPrice_ * loan.borrowed != 0) {
            collateralRatio_ = uint32(
                rUsdPrice_ * loan.collateral * 10 ** (8 + syntDecimals_)
                    / (syntPrice_ * loan.borrowed * 10 ** rUsdDecimals_)
            );
        } else if (loan.borrowed == 0) {
            collateralRatio_ = 0;
        } else {
            collateralRatio_ = type(uint32).max;
        }
    }
    /**
     * @notice Calculate user CR after mint
     * @dev For front-end purposes
     */

    function predictCollateralRatio(
        bytes32 _borrowId,
        address _syntAddress,
        uint256 _amountToBorrow,
        uint256 _amountToPledge,
        bool _increase
    )
        public
        view
        returns (uint256 collateralRatio_)
    {
        UserLoan memory loan = loans[_borrowId];

        uint256 newBorrowed_;
        uint256 newCollateral_;

        if (_increase) {
            newBorrowed_ = loan.borrowed + _amountToBorrow;
            newCollateral_ = loan.collateral + _amountToPledge;
        } else {
            newBorrowed_ = loan.borrowed - _amountToBorrow;
            newCollateral_ = loan.collateral - _amountToPledge;
        }

        (uint256 rUsdPrice_, uint8 rUsdDecimals_) = oracle.getPrice(address(rUsd));
        (uint256 syntPrice_, uint8 syntDecimals_) = oracle.getPrice(_syntAddress);

        if (syntPrice_ * newBorrowed_ != 0) {
            collateralRatio_ = uint32(
                rUsdPrice_ * newCollateral_ * 10 ** (8 + syntDecimals_)
                    / (syntPrice_ * newBorrowed_ * 10 ** rUsdDecimals_)
            );
        } else if (newBorrowed_ == 0) {
            collateralRatio_ = 0;
        } else {
            collateralRatio_ = type(uint32).max;
        }
    }

    /**
     * @notice Get total shorts for the synt
     * @param _syntAddress synt address
     * @return uint256
     */
    function totalShorts(address _syntAddress) public view returns (uint256) {
        require(synter.syntInfo(_syntAddress).syntId != 0, "Synt doesn't exist");
        return synter.syntInfo(_syntAddress).totalShorts;
    }

    /**
     * @notice Get total longs for the synt
     * @param _syntAddress synt address
     * @return uint256
     */
    function totalLongs(address _syntAddress) public view returns (uint256) {
        require(synter.syntInfo(_syntAddress).syntId != 0, "Synt doesn't exist");
        return ISynt(_syntAddress).totalSupply();
    }

    /**
     * @notice Can shorts be created for the synt or not
     * @param _syntAddress synt address
     * @return bool
     */
    function shortsEnabled(address _syntAddress) public view returns (bool) {
        require(synter.syntInfo(_syntAddress).syntId != 0, "Synt doesn't exist");
        return synter.syntInfo(_syntAddress).shortsEnabled;
    }

    /* ================= OWNER FUNCTIONS ================= */

    function setMinCollateralRatio(uint32 _minCollateralRatio) external onlyOwner {
        require(
            liquidationCollateralRatio <= _minCollateralRatio,
            "liquidationCollateralRatio should be <= minCollateralRatio"
        );
        minCollateralRatio = _minCollateralRatio;
    }

    function setLiquidationCollateralRatio(uint32 _liquidationCollateralRatio) external onlyOwner {
        require(
            _liquidationCollateralRatio <= minCollateralRatio,
            "liquidationCollateralRatio should be <= minCollateralRatio"
        );
        require(
            1e8 + liquidationPenalty + treasuryFee <= _liquidationCollateralRatio,
            "1 + liquidationPenalty + treasuryFee should be <= liquidationCollateralRatio"
        );
        liquidationCollateralRatio = _liquidationCollateralRatio;
    }

    function setLiquidationPenalty(uint32 _liquidationPenalty) external onlyOwner {
        require(
            1e8 + _liquidationPenalty + treasuryFee <= liquidationCollateralRatio,
            "1 + liquidationPenalty + treasuryFee should be <= liquidationCollateralRatio"
        );
        liquidationPenalty = _liquidationPenalty;
    }

    function setTreasuryFee(uint32 _treasuryFee) external onlyOwner {
        require(
            1e8 + liquidationPenalty + _treasuryFee <= liquidationCollateralRatio,
            "1 + liquidationPenalty + treasuryFee should be <= liquidationCollateralRatio"
        );
        treasuryFee = _treasuryFee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITreasury {
    function withdrawEth(uint256 amount) external;
    function withdrawTokens(address tokenAddress, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct UserLoan {
    address user; // user address
    address syntAddress; // address of borrowed synt
    uint256 borrowed; // total synt borrowed
    uint256 collateral; // collateral in rUSD
    uint32 minCollateralRatio; // minCollateralRation at the moment of borrowing (8 decimals)
    uint32 liquidationCollateralRatio; // liquidationCollateralRation at the moment of borrowing (8 decimals)
    uint32 liquidationPenalty; // liquidationPenalty at the moment of borrowing (8 decimals)
    uint32 treasuryFee; // treasury fee for liquidation at the moment of borrowing (8 decimals)
    uint32 loanIndex; // index of the loan in user's loans list
}

interface ILoan {
    function borrow(address _syntAddress, uint256 _amountToBorrow, uint256 _amountToPledge) external;
    function deposit(bytes32 borrowId, uint256 amount) external; // add rUSD to collateral to escape liquidation
    function repay(bytes32 borrowId, uint256 amount) external;
    function withdraw(bytes32 borrowId, uint256 amount) external; // withdraw rUSD
    function collateralRatio(bytes32 borrowId) external view returns (uint32);
    function predictCollateralRatio(
        bytes32 borrowId,
        address syntAddress,
        uint256 amountToBorrow,
        uint256 amountToPledge,
        bool increase
    )
        external
        view
        returns (uint256);
    function minCollateralRatio() external view returns (uint32);
    function liquidationCollateralRatio() external view returns (uint32);
    function liquidationPenalty() external view returns (uint32);
    function treasuryFee() external view returns (uint32);
    function totalShorts(address syntAddress) external view returns (uint256);
    function totalLongs(address syntAddress) external view returns (uint256);
    function shortsEnabled(address syntAddress) external view returns (bool);
    function setMinCollateralRatio(uint32 _minCollateralRatio) external;
    function setLiquidationCollateralRatio(uint32 _liquidationCollateralRatio) external;
    function setLiquidationPenalty(uint32 _liquidationPenalty) external;
    function setTreasuryFee(uint32 _treasuryFee) external;
    function liquidate(bytes32 borrowId) external;
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