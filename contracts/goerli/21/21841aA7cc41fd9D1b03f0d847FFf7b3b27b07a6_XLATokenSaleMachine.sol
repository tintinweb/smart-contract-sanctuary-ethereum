// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20Mintable.sol";

contract XLATokenSaleMachine is Ownable {
    uint256 public constant referralReward = 4;  // TODO Should this be private or public?
    uint256 private constant k = 1;
    uint256 private constant initialPrice = 1;

    address payable public receiverOfEarnings;
    address public affiliateManager;

    mapping(bytes32 => address) public affiliatePartners;

    IERC20Mintable public presaleToken;

    bool public paused;

    event Bought(uint256 amount, uint256 price);
    event AffiliatePartnerAdded(bytes32 affCode, address partnerAddress);


    /**
     * @dev Throws if the presale is paused
     */
    modifier notPaused() {
        require(!paused, "Sale is paused");
        _;
    }

    /**
     * @dev Throws if presale is NOT paused
     */
    modifier isPaused() {
        require(paused, "Presale is not paused");
        _;
    }

    /**
     * @dev Throws if address is not affiliateManager
     */
    modifier onlyAffiliateManager() {
        require(affiliateManager == msg.sender || owner() == msg.sender, "Sender is not affiliateManager");
        _;
    }

    constructor(
        address _xlaToken,
        address payable _receiverOfEarnings
    ) {
        require(
            _receiverOfEarnings != address(0),
            "Receiver wallet cannot be 0"
        );
        receiverOfEarnings = _receiverOfEarnings;
        presaleToken = IERC20Mintable(_xlaToken);
        affiliateManager = msg.sender;
        paused = true; //@dev start as paused
    }

    /**
     * @notice Do the math for square root using Babylonian method
     * @param x value you want to do square root for
     */
    function sqrt(uint x) public pure returns (uint y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Calculate how much user have to pay for given amount of xla tokens
     * @param _amount amount of tokens user wants to buy
     */
    function calculateCost(uint256 _amount) public view returns (uint256 cost) {
        cost = ((k/10) * presaleToken.totalSupply() + initialPrice) * _amount + (k/10) / 2 * (k/10)**2;
    }

    /**
     * @notice Calculate amount of tokens user will receive
     * @param _cost amount user want to spend for xla tokens
     */
    function calculateAmount(uint256 _cost) public view returns (uint256 amount) {
        amount = 10;
    }

    /**
     * @notice Buy XLA tokens based on msg.value user sends to this function
     * @param _affCode code of the affiliation partner
     */
    function buyFixedEthCost(bytes32 _affCode) external payable {
        uint256 amount = calculateAmount(msg.value);
        presaleToken.mint(msg.sender, amount);
        receiverOfEarnings.transfer(msg.value);

        if (_affCode != "" && affiliatePartners[_affCode] != address(0)) {
            address partner = affiliatePartners[_affCode];
            uint256 affiliateAmount = amount / 100 * referralReward;
            presaleToken.mint(partner, affiliateAmount);
        }

        // TODO check whether we should redistribute ETH in the split contract
        emit Bought(amount, msg.value);
    }

    /**
     * @notice Buy fixed amount of xla tokens
     * @param _amount Fixed amount of token user want to buy
     * @param _affCode code of the affiliation partner
     */
    function buyFixedTokenAmount(uint256 _amount, bytes32 _affCode) external payable {
        uint256 cost = calculateCost(_amount);
        require(cost == msg.value, "Value sent doesn't match cost");

        presaleToken.mint(msg.sender, _amount);
        receiverOfEarnings.transfer(msg.value);
        // TODO check whether we should redistribute ETH in the split contract

        if (_affCode != "" && affiliatePartners[_affCode] != address(0)) {
            address partner = affiliatePartners[_affCode];
            uint256 affiliateAmount = _amount / 100 * referralReward;
            presaleToken.mint(partner, affiliateAmount);
        }

        emit Bought(_amount, msg.value);
    }

    /**
     * @notice Check whether given amount is enough to distribute earned revenue
     * @param _amount amount to check
     */
    function _distributeRevenue(uint256 _amount) internal pure returns(bool) {
        // TODO Add logic for calculating whether payer can distributeRevenue
        return true;
    }

    /**
     * @notice Sets the address allowed to withdraw the proceeds from presale
     * @param _receiverOfEarnings address of the receiver
     */
    function setReceiverOfEarnings(address payable _receiverOfEarnings)
        external
        onlyOwner
    {
        require(
            _receiverOfEarnings != receiverOfEarnings,
            "Receiver already configured"
        );
        require(_receiverOfEarnings != address(0), "Receiver cannot be 0");
        receiverOfEarnings = _receiverOfEarnings;
    }

    /**
     * @notice Sets the address allowed to add / remove affiliate partners
     * @param _affiliateManager address of the manager
     */
    function setAffiliateManager(address _affiliateManager) external onlyOwner {
        require(
            affiliateManager != _affiliateManager,
            "affiliateManager already configured"
        );
        require(_affiliateManager != address(0), "AffiliateManager cannot be 0");
        affiliateManager = _affiliateManager;
    }

    /**
     * @notice Sets affiliate partner
     * @param _affCode code for affiliation
     * @param _partnerAddress address of the affiliate partner
     */
    function setAffiliatePartner(
        bytes32 _affCode,
        address _partnerAddress
    ) external onlyAffiliateManager {
        affiliatePartners[_affCode] = _partnerAddress;
        emit AffiliatePartnerAdded(_affCode, _partnerAddress);
    }

    /**
     * @notice Pauses the presale
     */
    function pause() external onlyOwner notPaused {
        paused = true;
    }

    /**
     * @notice Unpauses the presale
     */
    function unpause() external onlyOwner isPaused {
        paused = false;
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20Mintable is IERC20Metadata {

    /**
     * @dev Mint the amount of to provided address 'to'
     */
    function mint(address to, uint256 amount) external;
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