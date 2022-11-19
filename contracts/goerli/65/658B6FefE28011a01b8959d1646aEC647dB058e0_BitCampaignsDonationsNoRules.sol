// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BitCampaignsDonationsNoRules is Ownable
{

    address public donationWalletAddress;
    address public feeWalletAddress;
    address public adminWalletAddress;

    bool public donationEnabled;
    bool public receiveEnabled;
    bool public donationFeeEnabled = true;
    uint256 constant BASIS_POINTS = 10000;
    uint256 public donationFee; // 50 = .5%

    mapping(address => bool) private approvedERC20;

    event DonatedETHToCampaign(uint256 amount, address _from, uint256 _campaignIndex);
    event DonatedERC20ToCampaign(uint256 amount, address _from, uint256 _campaignIndex, address _contract);

    modifier onlyAdmin() {
        require(msg.sender == adminWalletAddress || msg.sender == owner());
        _;
    }

    constructor() {
        donationWalletAddress = 0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e; //Hardcode later
        feeWalletAddress = 0xdD92ADeA037A7a6206A5e39644F26621D01CE4e4; //Hardcode later
        adminWalletAddress = 0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e; //Hardcode later
        donationFee = 5; //Hardcode later
    }

    function donateETH(uint256 campaignIndex) public payable {

        require(msg.value > 0, "Value Sent Must be Greater Than 0");

        uint256 amountToDonate = msg.value;
        uint256 feeToPay = 0;

        if(donationFeeEnabled) {
            feeToPay = (msg.value * donationFee) / BASIS_POINTS;
            amountToDonate -= feeToPay;
        }

        if (feeToPay > 0) {
            (bool payFee, ) = payable(feeWalletAddress).call {value: feeToPay}("");
            require(payFee);
        }

        (bool payRemainder, ) = payable(donationWalletAddress).call {value: amountToDonate}("");
        require(payRemainder);

        emit DonatedETHToCampaign(msg.value, msg.sender, campaignIndex);
    }

    function donateERC20(address erc20Contract, uint256 amount, uint256 campaignIndex) public {

        require(amount > 0, "Must be above 0");

        uint256 amountToDonate = amount;
        uint256 feeToPay = 0;

        if(donationFeeEnabled) {
            feeToPay = (amount * donationFee) / BASIS_POINTS;
            amountToDonate -= feeToPay;
        }

        if (feeToPay > 0) {
            IERC20(erc20Contract).transferFrom(
                msg.sender,
                feeWalletAddress,
                feeToPay
            );
        }

        IERC20(erc20Contract).transferFrom(
            msg.sender,
            donationWalletAddress,
            amountToDonate
        );

        emit DonatedERC20ToCampaign(amountToDonate + feeToPay, msg.sender, campaignIndex, erc20Contract);
    }

    function recoverEthFor(uint256 amount, address to) public onlyAdmin {

        require(to != address(0), "Invalid address");

        (bool withdrawl, ) = payable(to).call {value: amount}("");
        require(withdrawl);

    }

    function recoverERC20For(address _contract, uint256 amount, address to) public  onlyOwner {

        IERC20(_contract).transferFrom(
            address(this),
            to,
            amount
        );

    }

    function setAdminWalletAddress(address _wallet) public onlyAdmin {
        adminWalletAddress = _wallet;
    }

    function setDonationWalletAddress(address _wallet) public onlyAdmin {
        donationWalletAddress = _wallet;
    }

    function setFeeWalletAddress(address _wallet) public onlyAdmin {
        feeWalletAddress = _wallet;
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