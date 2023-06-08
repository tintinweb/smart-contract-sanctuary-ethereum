// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address recipient) external returns (uint256);
}

contract Presale is Ownable, ReentrancyGuard {
    bool public publicSaleOpen;
    bool public whitelistEnabled;
    bool public claimEnabled;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public contributions;
    uint256 public totalContributed;
    uint256 public totalTokensToClaim;

    uint256 public minEthAmount;
    uint256 public maxContribution;

    uint256 public HARDCAP;
    uint256 public SOFTCAP;

    IERC20 public presaleToken;

    event WhitelistUpdated(address[] addresses, bool whitelisted);
    event WhitelistEnabledToggled(bool isWhitelistEnabled);
    event PublicSaleToggled(bool isOpen);
    event ClaimToggled(bool isEnabled);
    event PresaleTokensPurchased(address indexed buyer, uint256 ethAmount);
    event PresaleTokensClaimed(address indexed claimer, uint256 tokenAmount);
    event RefundClaimed(address indexed claimer, uint256 amount);
    event Withdraw(address indexed wallet, uint256 amount);

    constructor(
        uint256 _minEthAmount,
        uint256 _maxContribution,
        uint256 _softcap,
        uint256 _hardcap,
        bool _whitelistEnabled
    ) {
        HARDCAP = _hardcap;
        SOFTCAP = _softcap;
        minEthAmount = _minEthAmount;
        maxContribution = _maxContribution;
        whitelistEnabled = _whitelistEnabled;
    }

    modifier onlyWhitelisted() {
        if (whitelistEnabled) {
            require(whitelist[msg.sender], "Address is not whitelisted");
        }
        _;
    }

    function addToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            address account = _addresses[i];
            if (!whitelist[account]) {
                whitelist[account] = true;
            }
        }
        emit WhitelistUpdated(_addresses, true);
    }

    function removeFromWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            address account = _addresses[i];
            if (whitelist[account]) {
                delete whitelist[account];
            }
        }
        emit WhitelistUpdated(_addresses, false);
    }

    function toggleWhitelistEnagled() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
        emit WhitelistEnabledToggled(publicSaleOpen);
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
        emit PublicSaleToggled(publicSaleOpen);
    }

    function toggleClaimEnabled() external onlyOwner {
        claimEnabled = !claimEnabled;
        emit ClaimToggled(claimEnabled);
    }
    
    function changeParams(uint256 _minContribution, uint256 _maxContribution, uint256 _softcap, uint256 _hardcap) external onlyOwner {
        minEthAmount = _minContribution;
        maxContribution = _maxContribution;
        SOFTCAP = _softcap;
        HARDCAP = _hardcap;
    }

    function buyPresale() external payable onlyWhitelisted nonReentrant {
        require(publicSaleOpen && !claimEnabled, "Public sale is not open");
        require(msg.value >= minEthAmount, "Below minimum contribution");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Exceeds maximum contribution");
        require(totalContributed + msg.value <= HARDCAP, "Hard cap reached");

        contributions[msg.sender] += msg.value;
        totalContributed += msg.value;
        
        // // Transfer received ETH to the designated wallet
        // (bool sent, ) = payable(wallet).call{value: msg.value}("");
        // require(sent, "Failed to send Ether");
        
        emit PresaleTokensPurchased(msg.sender, msg.value);
    }

    function claim() external nonReentrant {
        require(claimEnabled && address(presaleToken) != address(0), "Claiming is not enabled");
        require(totalContributed >= SOFTCAP, "Softcap not reached");
        require(totalContributed > 0, "No contributions made");
        require(contributions[msg.sender] > 0, "No contribution found");

        uint256 contributionPercent = getContributionPercent(msg.sender);
        uint256 tokenAmount = (contributionPercent * totalTokensToClaim) / 100 ether;

        require(tokenAmount > 0, "No tokens available for claim");
        require(
            presaleToken.transfer(msg.sender, tokenAmount),
            "Failed to transfer presale tokens"
        );

        contributions[msg.sender] = 0;
        emit PresaleTokensClaimed(msg.sender, tokenAmount);
    }

    function refund() external nonReentrant {
        require(claimEnabled && address(presaleToken) != address(0), "Claiming is not enabled");
        require(totalContributed < SOFTCAP, "Softcap reached");
        require(contributions[msg.sender] > 0, "No contribution found");
        
        uint contributed = contributions[msg.sender];
        
        (bool sent, ) = payable(msg.sender).call{value: contributed}("");
        require(sent, "Failed to send Ether");

        contributions[msg.sender] = 0;
        emit RefundClaimed(msg.sender, contributed);
    }

    function setPresaleToken(address _tokenAddress, uint256 _totalTokensToClaim) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_totalTokensToClaim > 0, "Invalid total tokens to claim");
        presaleToken = IERC20(_tokenAddress);
        totalTokensToClaim = _totalTokensToClaim;
    }

    function getContribution(address _address) external view returns(uint256) {
      return contributions[_address];
    }
    
    function getContributionPercent(address _address) public view returns(uint256) {
      return (contributions[_address] * 100 ether) / totalContributed;
    }
    
    // Helper function to check if an address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }
    // This function allows to send ETH to the contract
    receive() external payable { }

    // This function allows the contract owner to withdraw all the ETH from the contract
    function WithdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: balance}("");
        require(sent, "Failed to send Ether");
        emit Withdraw(owner(), balance);
    }

    // This function returns the balance of the contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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