/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: FiatStableCoinP2pSwap.sol

// Deposit Token -- Done
// Deposit Platform Fee -- Done
// CreateSellAdvertisement -- Done
// SenderBuyOrder -- Done
// CancelBuyOrder -- Done
// WithdrawFromAdvertisement -- Done
// SetPlatformFee -- Done
// AddAllowedTokens -- Done
// ProcessingFee -- Done
// HandleAppeal -- Done
// VaultWithdraw -- Done

contract FiatStableCoinP2pSwap is Ownable {
    // mapping user_address => numberOfAdvertisements
    mapping(address => uint256) numberOfAdvertisements;
    // mapping token_address => vault
    mapping(address => uint256) public vault;

    struct Advertise {
        bool activeBuyOrder;
        bool advertisingStatus;
        bool appealing;
        address user;
        uint256 advertisingBalance;
        uint256 feeDeposited;
        uint256 id;
        string rate;
        address token;
        uint256 buyOrderAmountRequested;
        uint256 minimumOrderRequest;
        uint256 maximumOrderRequest;
        uint256 middleManBalance;
        address buyer;
    }

    uint256 public platformFee;
    address[] public users;
    address[] public allowedTokens;
    Advertise[] public advertise;
    uint256 public advertisingLimit;

    constructor() public {
        platformFee = 1000;
        advertisingLimit = 2;
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function setAdvertisingStatus(uint256 _id, bool _status) public {
        advertise[_id].advertisingStatus = _status;
    }

    function createSellAdvertise(
        address _token,
        uint256 _amount,
        uint256 _min,
        uint256 _max,
        string memory _rate
    ) public {
        require(_amount > 0, "Amount cannot be 0");
        require(tokenIsAllowed(_token), "Token is not allowed!");
        require(
            numberOfAdvertisements[msg.sender] < advertisingLimit,
            "Each user only have 2 advertising limit!"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        numberOfAdvertisements[msg.sender] =
            numberOfAdvertisements[msg.sender] +
            1;
        Advertise memory ads;
        ads.token = _token;
        ads.activeBuyOrder = false;
        ads.feeDeposited = _amount / platformFee;
        ads.advertisingBalance = _amount - ads.feeDeposited;
        ads.advertisingStatus = true;
        ads.appealing = false;
        ads.id = advertise.length;
        ads.rate = _rate;
        ads.user = msg.sender;
        ads.buyOrderAmountRequested = 0;
        ads.minimumOrderRequest = _min;
        ads.maximumOrderRequest = _max;
        ads.middleManBalance = 0;
        advertise.push(ads);
        if (numberOfAdvertisements[msg.sender] == 1) {
            users.push(msg.sender);
        }
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function setPlatformFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }

    function sendBuyOrder(uint256 _id, uint256 _amount) public {
        require(
            !advertise[_id].activeBuyOrder,
            "This Advertise is busy at the moment!"
        );
        require(
            _amount > advertise[_id].minimumOrderRequest &&
                _amount <= advertise[_id].advertisingBalance,
            "_amount is bigger than advertising Balance"
        );
        advertise[_id].activeBuyOrder = true;
        advertise[_id].buyOrderAmountRequested = _amount;
        advertise[_id].middleManBalance = advertise[_id]
            .buyOrderAmountRequested;
        advertise[_id].advertisingBalance =
            advertise[_id].advertisingBalance -
            advertise[_id].middleManBalance;
        advertise[_id].buyer = msg.sender;
    }

    function confirmBuyOrder(uint256 _id, bool _confirmation) public {
        require(
            advertise[_id].user == msg.sender,
            "Msg.sender is not the advertisment owner!"
        );

        if (_confirmation) {
            IERC20(advertise[_id].token).transfer(
                advertise[_id].buyer,
                advertise[_id].middleManBalance
            );
            processingFee(_id);
            // if advertising balance is 0, pop the advertise
            if (advertise[_id].advertisingBalance == 0) {
                advertise[_id] = advertise[advertise.length - 1];
                advertise.pop();
                numberOfAdvertisements[msg.sender] =
                    numberOfAdvertisements[msg.sender] -
                    1;
            } else {
                advertise[_id].middleManBalance = 0;
                advertise[_id].activeBuyOrder = false;
                advertise[_id].buyOrderAmountRequested = 0;
                advertise[_id].buyer = address(0);
            }
        } else {
            advertise[_id].appealing = true;
        }
    }

    function cancelBuyOrder(uint256 _id) public {
        require(
            advertise[_id].buyer == msg.sender || owner() == msg.sender,
            "msg.sender is not buyer!"
        );
        advertise[_id].activeBuyOrder = false;
        advertise[_id].buyer = address(0);
        advertise[_id].advertisingBalance =
            advertise[_id].advertisingBalance +
            advertise[_id].middleManBalance;
        advertise[_id].middleManBalance = 0;
        advertise[_id].buyOrderAmountRequested = 0;
        advertise[_id].appealing = false;
    }

    function withdrawFromAdvertisement(uint256 _id, uint256 _amount) public {
        require(advertise[_id].user == msg.sender, "msg.seder is not user");
        require(
            _amount > advertise[_id].advertisingBalance,
            "amount is bigger than advertising balance"
        );

        if (advertise[_id].advertisingBalance == _amount) {
            uint256 amount = advertise[_id].advertisingBalance +
                advertise[_id].feeDeposited;

            IERC20(advertise[_id].token).transfer(msg.sender, amount);

            advertise[_id] = advertise[advertise.length - 1];
            advertise.pop();
            numberOfAdvertisements[msg.sender] =
                numberOfAdvertisements[msg.sender] -
                1;
        }

        IERC20(advertise[_id].token).transfer(msg.sender, _amount);

        advertise[_id].advertisingBalance =
            advertise[_id].advertisingBalance -
            _amount;
    }

    function processingFee(uint256 _id) internal {
        uint256 fee = advertise[_id].buyOrderAmountRequested / platformFee;
        address token = advertise[_id].token;
        vault[token] = vault[token] + fee;
        advertise[_id].feeDeposited = advertise[_id].feeDeposited - fee;
    }

    function vaultWithdraw(address _token) public onlyOwner {
        uint256 amount = vault[_token];
        IERC20(_token).transfer(owner(), amount);
        vault[_token] = 0;
    }

    function handleAppeal(uint256 _id, bool _conclusion) public onlyOwner {
        // if true, send token to buyer else reset the buy order for seller
        if (_conclusion) {
            IERC20(advertise[_id].token).transfer(
                advertise[_id].buyer,
                advertise[_id].buyOrderAmountRequested
            );
            processingFee(_id);
            if (
                advertise[_id].buyOrderAmountRequested ==
                advertise[_id].advertisingBalance
            ) {
                numberOfAdvertisements[advertise[_id].user] =
                    numberOfAdvertisements[advertise[_id].user] -
                    1;
                advertise[_id] = advertise[advertise.length - 1];
                advertise.pop();
            } else {
                advertise[_id].activeBuyOrder = false;
                advertise[_id].buyOrderAmountRequested = 0;
                advertise[_id].buyer = address(0);
                advertise[_id].advertisingBalance =
                    advertise[_id].advertisingBalance -
                    advertise[_id].buyOrderAmountRequested;
                advertise[_id].middleManBalance = 0;
                advertise[_id].appealing = false;
            }
        } else {
            cancelBuyOrder(_id);
        }
    }
}