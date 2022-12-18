/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
/**
 * @dev Define interface verifier
 */
interface IVerifierRollup {
    function verifyProof(
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC,
        uint256[1] calldata input
    ) external view returns (bool);
}

contract AAVFOP is Ownable {

    // Product information struct
    struct ProductInformation {
        string name;
        uint256 price;
        uint256 amount;
    }

    // Store name
    string public storeName;
    // ZK verifier
    IVerifierRollup public zkVerifier;

    // Number of Purchases
    uint256 public lastPurchaseIndex;

    // Number of products
    uint256 public lastProduct;

    mapping(uint256 => ProductInformation) public ProductInfo;

    /**
     * @dev Emitted when a new payment is received
     */
    event Payment(address indexed client, uint256 amount, uint256 lastPurchaseIndex, uint256 indexed productIndex);

    /**
     * @dev Emitted when a new product is added or modified
     */
    event Product(string name, uint256 indexed productIndex, uint256 price, uint256 amount);

    /**
     * @dev Emitted when funds are claimed
     */
    event Claimed(address indexed destAddr, uint256 amount);

    constructor(
        string memory _storeName,
        IVerifierRollup _zkVerifier
    ) {
        storeName = _storeName;
        zkVerifier = _zkVerifier;
    }


    function buy(
        uint256 amount, // Units of product
        uint256 productIndex,
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC
    ) external payable {
        // Check product exists
        require(
            keccak256(abi.encode(ProductInfo[productIndex].name)) != keccak256(abi.encode("")),
            "OnlinePurchaseSystem::buy: PRODUCT_DOES_NOT_EXIST"
        );

        // Check product exists
        require(
            ProductInfo[productIndex].amount != 0,
            "OnlinePurchaseSystem::buy: PRODUCT_SOLD_OUT"
        );

        // Check that amount * productPrice == msg.Value
        require(
            amount * ProductInfo[productIndex].price == msg.value,
            "OnlinePurchaseSystem::buy: INCORRECT_AMOUNT"
        );

        // Verify proof
        require(
            zkVerifier.verifyProof(proofA, proofB, proofC, [uint256(uint160(msg.sender))]),
            "OnlinePurchaseSystem::buy: INVALID_PROOF"
        );

        lastPurchaseIndex++;
        ProductInfo[productIndex].amount -= amount;

        emit Payment(msg.sender, amount, lastPurchaseIndex, productIndex);
    }

    // Add product
    function addProduct(string memory name, uint256 price, uint256 amount) external onlyOwner {
        require(
            keccak256(abi.encode(name)) != keccak256(abi.encode("")),
            "OnlinePurchaseSystem::addProduct: PRODUCT_NAME_CANT_BE_EMPTY"
        );
        lastProduct++;

        ProductInfo[lastProduct].name = name;
        ProductInfo[lastProduct].price = price;
        ProductInfo[lastProduct].amount = amount;

        emit Product(name, lastProduct, price, amount);
    }

    // Modify product
    function modifyProduct(string memory name, uint256 productIndex, uint256 price, uint256 amount) external onlyOwner {
        require(
            keccak256(abi.encode(ProductInfo[productIndex].name)) != keccak256(abi.encode("")),
            "OnlinePurchaseSystem::modifyProduct: PRODUCT_DOES_NOT_EXIST"
        );
        require(
            keccak256(abi.encode(name)) != keccak256(abi.encode("")),
            "OnlinePurchaseSystem::modifyProduct: PRODUCT_NAME_CANT_BE_EMPTY"
        );
        ProductInfo[productIndex].name = name;
        ProductInfo[productIndex].price = price;
        ProductInfo[productIndex].amount = amount;

        emit Product(name, productIndex, price, amount);
    }

    function claimFunds(address destAddr, uint256 amount) external onlyOwner {
        // Transfer ether
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = destAddr.call{value: amount}(
            new bytes(0)
        );

        require(success, "OnlinePurchaseSystem::claimFunds: ETH_TRANSFER_FAILED");
        emit Claimed(destAddr, amount);
    }
}