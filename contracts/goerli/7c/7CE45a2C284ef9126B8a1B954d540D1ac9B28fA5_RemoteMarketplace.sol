/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File contracts/token/IERC677.sol


pragma solidity ^0.8.0;

// adapted from LINK token https://etherscan.io/address/0x514910771af9ca656af840dff83e8264ecf986ca#code
// implements https://github.com/ethereum/EIPs/issues/677
interface IERC677 is IERC20 {
    function transferAndCall(
        address to,
        uint value,
        bytes calldata data
    ) external returns (bool success);

    event Transfer(
        address indexed from,
        address indexed to,
        uint value,
        bytes data
    );
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/RemoteMarketplace.sol



pragma solidity ^0.8.13;


interface IMarketplace {
    function buy(bytes32 projectId, uint256 subscriptionSeconds) external;
    function buyFor(bytes32 projectId, uint256 subscriptionSeconds, address recipient) external;
    function getPurchaseInfo(
        bytes32 projectId,
        address subscriber,
        uint256 subscriptionSeconds,
        uint32[] memory originDomainId,
        uint256 purchaseId
    ) external view returns(address, address, uint256, uint256, uint256);
}

interface IInterchainQueryRouter {
    function query(
        uint32 destinationDomainId,
        address recipientAddress,
        bytes calldata call,
        bytes calldata callback
    ) external returns (uint256);
}

interface IOutbox {
    function dispatch(
        uint32 destinationDomainId, // the chain where MarketplaceV4 is deployed and where messages are sent to. It is a unique ID assigned by hyperlane protocol (e.g. on polygon)
        bytes32 recipientAddress, // the address for the MarketplaceV4 contract. It must have the handle() function (e.g. on polygon)
        bytes calldata messageBody // encoded purchase info
    ) external returns (uint256);
}

/**
 * @title Streamr Remote Marketplace
 * The Remmote Marketplace through which the users on other networks can send cross-chain messages (e.g. buy projects)
 */
contract RemoteMarketplace is Ownable {
    struct PurchaseRequest {
        bytes32 projectId;
        address buyer;
        address subscriber;
        uint256 subscriptionSeconds;
    }

    uint32[] public originDomainId; // contains only one element (the domain id of the chain where RemoteMarketplace is deployed)
    uint32 public destinationDomainId; // the domain id of the chain where MarketplaceV4 is deployed
    address public recipientAddress; // the address of the MarketplaceV4 contract on the destination chain
    IInterchainQueryRouter public queryRouter;
    IOutbox public outbox;

    uint256 public purchaseCount;
    mapping(uint256 => PurchaseRequest) purchases;

    event CrossChainPurchase(bytes32 projectId, address subscriber, uint256 subscriptionSeconds);

    modifier onlyQueryRouter() {
        require(msg.sender == address(queryRouter), "error_onlyQueryRouter");
        _;
    }

    /**
     * @param _destinationDomainId - the domain id of the destination chain assigned by the protocol (e.g. polygon)
     * @param _recipientAddress - the address of the recipient contract (e.g. MarketplaceV4 on polygon)
     * @param _queryRouter - hyperlane query router for the origin chain
     * @param _outboxAddress - hyperlane core address for the chain where RemoteMarketplace is deployed (e.g. gnosis)
     */
    constructor(uint32 _domainId, uint32 _destinationDomainId, address _recipientAddress, address _queryRouter, address _outboxAddress) {
        originDomainId.push(_domainId);
        destinationDomainId = _destinationDomainId;
        recipientAddress = _recipientAddress;
        outbox = IOutbox(_outboxAddress);
        queryRouter = IInterchainQueryRouter(_queryRouter);
    }

    function buy(bytes32 projectId, uint256 subscriptionSeconds) public {
        buyFor(projectId, subscriptionSeconds, msg.sender);
    }

    function buyFor(bytes32 projectId, uint256 subscriptionSeconds, address subscriber) public {
        uint256 purchaseId = purchaseCount + 1;
        purchaseCount = purchaseId;
        queryRouter.query(
            destinationDomainId,
            recipientAddress,
            abi.encodeCall(IMarketplace.getPurchaseInfo, (projectId, subscriber, subscriptionSeconds, originDomainId, purchaseId)),
            abi.encodePacked(this.handleQueryProject.selector)
        );
        purchases[purchaseId] = PurchaseRequest(projectId, msg.sender, subscriber, subscriptionSeconds);
    }

    function handleQueryProject(
        address beneficiary,
        address pricingTokenAddress,
        uint256 subEndTimestamp,
        uint256 price,
        uint256 fee,
        uint256 purchaseId
    ) public onlyQueryRouter {
        PurchaseRequest memory purchase = purchases[purchaseId];
        bytes32 projectId = purchase.projectId;
        address subscriber = purchase.subscriber;
        address buyer = purchase.buyer;
        uint256 subscriptionSeconds = purchase.subscriptionSeconds;
        _handleProjectPurchase(projectId, buyer, subscriber, beneficiary, pricingTokenAddress, subEndTimestamp, price, fee);
        _subscribeToProject(projectId, subscriptionSeconds, subscriber);
        emit CrossChainPurchase(projectId, subscriber, subscriptionSeconds);
    }

    function _handleProjectPurchase(
            bytes32 projectId,
            address buyer,
            address subscriber,
            address beneficiary,
            address pricingTokenAddress,
            uint256 subEndTimestamp,
            uint256 price,
            uint256 fee
        ) private {
        require(price > 0, "error_freeProjectsNotSupportedOnRemoteMarketplace");
        IERC677 pricingToken = IERC677(pricingTokenAddress);
        // transfer price (amount to beneficiary + fee to marketplace owner) from buyer to marketplace
        require(pricingToken.transferFrom(buyer, address(this), price), "error_paymentFailed");
        
        // pricing token is ERC677, so project beneficiary can react to project purchase by implementing onTokenTransfer
        try pricingToken.transferAndCall(beneficiary, price - fee, abi.encodePacked(projectId, subscriber, subEndTimestamp, price, fee)) returns (bool success) {
            require(success, "error_transferAndCallProject");
        } catch {
            // pricing token is NOT ERC677, so project beneficiary can only react to purchase by implementing IPurchaseListener
            require(pricingToken.transfer(beneficiary, price - fee), "error_paymentFailed");
        }

        if (fee > 0) {
            // pricing token is ERC677 and marketplace owner can react to project purchase
            try pricingToken.transferAndCall(owner(), fee, abi.encodePacked(projectId, subscriber, subEndTimestamp, price, fee)) returns (bool success) {
                require(success, "error_transferAndCallFee");
            } catch {
                // pricing token is NOT ERC677 and marketplace owner can NOT react to project purchase
                require(pricingToken.transfer(owner(), fee), "error_paymentFailed");
            }
        }

    }

    function _subscribeToProject(bytes32 projectId, uint256 subscriptionSeconds, address subscriber) private {
        outbox.dispatch(
            destinationDomainId,
            _addressToBytes32(recipientAddress),
            abi.encode(projectId, subscriptionSeconds, subscriber)
        );
    }

    function _addressToBytes32(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}