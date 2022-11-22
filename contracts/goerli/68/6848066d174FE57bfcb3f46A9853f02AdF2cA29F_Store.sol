// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

library StoreLib {
    function createId(string memory _string, address _address)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_string, _address)));
    }
}

contract Store {
    address payable private admin;
    address[] private clientAddresses;

    struct Product {
        uint256 id;
        string name;
        uint256 price;
        uint256 quantity;
        uint256 blockNumber;
        address payable owner;
    }

    mapping(uint256 => Product) public products;
    Product[] public ownedProducts;
    uint256[] private viewProducts;
    uint256[] private viewOwnedProducts;

    constructor() {
        admin = payable(msg.sender);
    }

    receive() external payable {} // Fallback

    modifier AdminOnly() {
        require(msg.sender == admin, "This action isn't allowed");
        _;
    }

    event NewProductLog(
        uint256 id,
        string name,
        uint256 price,
        uint256 quantity,
        uint256 blockNumber,
        address indexed owner
    );
    event BuyProductLog(
        uint256 id,
        string name,
        uint256 price,
        uint256 quantity,
        uint256 blockNumber,
        address indexed purchasedBy
    );

    function createProduct(
        string calldata _name,
        uint256 _price,
        uint256 _quantity
    ) external AdminOnly {
        uint256 productId = StoreLib.createId(_name, msg.sender);

        require(bytes(_name).length > 0, "The name is not valid");
        require(_price > 0, "The price is not valid");

        products[productId].id = productId;
        products[productId].name = _name;
        products[productId].price = _price;
        products[productId].quantity = products[productId].quantity + _quantity;
        products[productId].blockNumber = block.number;
        products[productId].owner = payable(msg.sender);
        viewProducts.push(productId);
        emit NewProductLog(
            productId,
            _name,
            _price,
            _quantity,
            block.number,
            msg.sender
        );
    }

    function buyProductsID(uint256 _id) external payable {
        //require(products[_id].quantity == 0, "The product is out of stock");
        products[_id].quantity = products[_id].quantity - 1;

        ownedProducts.push(
            Product({
                id: products[_id].id,
                name: products[_id].name,
                price: products[_id].price,
                quantity: 1,
                blockNumber: block.number,
                owner: payable(msg.sender)
            })
        );

        viewOwnedProducts.push(products[_id].id);

        clientAddresses.push(msg.sender);
        emit BuyProductLog(
            products[_id].id,
            products[_id].name,
            products[_id].price,
            1,
            products[_id].blockNumber,
            msg.sender
        );
    }

    function returnProduct(uint256 _index) external returns (bool success) {
        require(ownedProducts.length > 0, "You don't own any products");

        Product storage _owned = ownedProducts[_index];
        Product storage _product = products[_owned.id];

        // require(
        //     block.number - ownedProducts[_index].blockNumber >= 100,
        //     "You cannot return the product anymore"
        // );

        _product.quantity = _product.quantity + _owned.quantity;
        _product.owner = admin;

        delete ownedProducts[_index];
        return true;
    }

    function viewAllPurchasesByClientAddresses()
        public
        view
        returns (address[] memory)
    {
        return clientAddresses;
    }

    function viewProductIds() public view returns (uint256[] memory) {
        return viewProducts;
    }

    function viewOwnedProductIds() public view returns (uint256[] memory) {
        return viewOwnedProducts;
    }

    function withdrawFunds(uint256 _amount) external AdminOnly {
        admin.transfer(_amount);
    }

    function storeBalance() external view AdminOnly returns (uint256) {
        return address(this).balance;
    }

    function setAdmin(address _new) external {
        require(_new != address(0), "Invalid address");
        admin = payable(_new);
    }
}