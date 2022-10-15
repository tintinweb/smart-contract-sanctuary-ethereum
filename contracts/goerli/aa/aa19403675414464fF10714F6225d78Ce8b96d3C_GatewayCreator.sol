// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Gateway.sol";

contract GatewayCreator {
    /* ========== STATE VARIABLES ========== */
    Gateway[] public gateways;
    mapping(address => bool) isGateway;

    /* ========== Events  ========== */
    event GatewayCreated(
        uint256 indexed contractId,
        address indexed contractAddress,
        address creator
    );

    event Owners(address indexed contractAddress, address[] owners);

    /* ========== Modifiers  ========== */
    modifier isRegistered() {
        require(isGateway[msg.sender], "caller must be created by the Gateway");
        _;
    }

    /* ========== Functions  ========== */
    function createGateway(
        string memory _name,
        string memory _businessAddress,
        string memory _email,
        string memory _website
    ) public payable {
        uint256 walletId = gateways.length;
        Gateway newWallet = new Gateway(
            _name,
            _businessAddress,
            _email,
            _website
        );

        address walletAddress = address(newWallet);
        require(
            !isGateway[walletAddress],
            "createGateway : wallet already exists"
        );

        gateways.push(newWallet);
        isGateway[walletAddress] = true;

        emit GatewayCreated(walletId, walletAddress, msg.sender);
    }

    function numberOfGatewaysCreated() public view returns (uint256) {
        return gateways.length;
    }

    function getGateway(uint256 _index)
        public
        view
        returns (address _walletAddress, uint256 _balance)
    {
        Gateway wallet = gateways[_index];
        _walletAddress = address(wallet);
        _balance = address(wallet).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Gateway is Ownable {
    uint256 public purchaseId = 1;

    string public name;
    string public businessAddress;
    string public email;
    string public website;

    struct Purchase {
        string[] items;
        uint256[] amount;
    }

    mapping(uint256 => Purchase) private s_purchases;

    event itemPurchased(
        string[] indexed items,
        uint256[] indexed amount,
        uint256 indexed id
    );

    constructor(
        string memory _name,
        string memory _businessAddress,
        string memory _email,
        string memory _website
    ) {
        name = _name;
        businessAddress = _businessAddress;
        email = _email;
        website = _website;
    }

    function pay(string[] memory _items, uint256[] memory _amount)
        external
        payable
    {
        require(
            _items.length == _amount.length,
            "Each Item should have an amount"
        );
        s_purchases[purchaseId] = Purchase(_items, _amount);
        emit itemPurchased(_items, _amount, purchaseId);
        purchaseId++;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function getPurchaseById(uint256 _purchaseId)
        external
        view
        returns (Purchase memory)
    {
        return s_purchases[_purchaseId];
    }

    receive() external payable {}

    fallback() external payable {}
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