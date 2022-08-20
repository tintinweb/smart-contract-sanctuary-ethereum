// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Wallet.sol";

error AssetMarketplace__PriceMustBeGreaterThanZero();
error AssetMarketplace__QuantityMustBeGreaterThanZero();
error AssetMarketplace__BuyersCannotBuyTheirOwnAsset();
error AssetMarketplace__SellerDoNotHaveEnoughAssetsToSell();

contract AssetMarketplace is Wallet {
    event AssetAdded(
        uint256 indexed id,
        address indexed owner,
        string name,
        uint256 price,
        uint256 quantity,
        uint256 when
    );
    event AssetBought(uint256 indexed id, address indexed buyer, uint256 indexed quantity, uint256 when);

    struct Asset {
        uint256 id;
        string name;
        uint256 price;
    }

    struct AssetWithQuantity {
        uint256 id;
        string name;
        uint256 price;
        uint256 quantity;
    }

    Asset[] public assets;
    address[] public customers;
    address payable public contractOwner;

    mapping(address => bool) private customerExists;
    mapping(address => mapping(uint256 => uint256)) public customerAssets;

    constructor() payable {
        if (msg.value > 0) {
            deposit();
        }
        contractOwner = payable(msg.sender);
    }

    function updateCustomersList(address _customer) internal {
        if (!customerExists[_customer]) {
            customers.push(_customer);
            customerExists[_customer] = true;
        }
    }

    function getCustomers() public view returns (address[] memory) {
        return customers;
    }

    function addAsset(
        string memory _name,
        uint256 _price,
        uint256 _quantity,
        address _owner
    ) external {
        if (_price <= 0) {
            revert AssetMarketplace__PriceMustBeGreaterThanZero();
        }
        if (_quantity <= 0) {
            revert AssetMarketplace__QuantityMustBeGreaterThanZero();
        }

        uint256 assetId = assets.length;
        assets.push(Asset(assetId, _name, _price));
        customerAssets[_owner][assetId] = _quantity;
        updateCustomersList(_owner);
        emit AssetAdded(assetId, _owner, _name, _price, _quantity, block.timestamp);
    }

    function buyAsset(
        address payable _seller,
        uint256 _assetId,
        uint256 _quantity
    ) external payable {
        if (_seller == msg.sender) {
            revert AssetMarketplace__BuyersCannotBuyTheirOwnAsset();
        }
        if (_quantity <= 0) {
            revert AssetMarketplace__QuantityMustBeGreaterThanZero();
        }
        if (customerAssets[_seller][_assetId] < _quantity) {
            revert AssetMarketplace__SellerDoNotHaveEnoughAssetsToSell();
        }

        uint256 price = assets[_assetId].price;
        uint256 totalPrice = price * _quantity;

        customerAssets[_seller][_assetId] -= _quantity;
        customerAssets[msg.sender][_assetId] += _quantity;

        updateCustomersList(msg.sender);
        transfer(_seller, totalPrice);
        emit AssetBought(_assetId, msg.sender, _quantity, block.timestamp);
    }

    function getAssetsByOwner(address _owner) external view returns (AssetWithQuantity[] memory) {
        return filterAssets(ownerPredicate, uint256(uint160(_owner)));
    }

    function ownerPredicate(Asset storage _asset, uint256 _owner) private view returns (bool) {
        return customerAssets[address(uint160(_owner))][_asset.id] > 0;
    }

    function filterAssets(function(Asset storage, uint256) view returns (bool) _predicate, uint256 _data0)
        private
        view
        returns (AssetWithQuantity[] memory result)
    {
        uint256 counter = 0;
        for (uint256 i = 0; i < assets.length; ++i) {
            if (_predicate(assets[i], _data0)) {
                ++counter;
            }
        }
        result = new AssetWithQuantity[](counter);
        counter = 0;
        for (uint256 i = 0; i < assets.length; ++i) {
            if (_predicate(assets[i], _data0)) {
                result[counter++] = AssetWithQuantity(
                    assets[i].id,
                    assets[i].name,
                    assets[i].price,
                    customerAssets[address(uint160(_data0))][assets[i].id]
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error Wallet__AmountNeedsToBeHigherThanZero();
error Wallet__InsufficientFunds();
error Wallet__TransferFailed();
error Wallet__InvalidAddress();

contract Wallet {
    event Deposit(uint256 indexed amount, uint256 when);
    event Withdraw(uint256 indexed amount, uint256 when);
    event Transfer(address indexed sender, address indexed receiver, uint256 indexed amount, uint256 when);

    mapping(address => uint256) balances;

    modifier amountHigherThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert Wallet__AmountNeedsToBeHigherThanZero();
        }
        _;
    }

    modifier notEnoughFunds(uint256 _amount) {
        if (balances[msg.sender] < _amount) {
            revert Wallet__InsufficientFunds();
        }
        _;
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable amountHigherThanZero(msg.value) {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.value, block.timestamp);
    }

    function withdraw(uint256 _amount) external amountHigherThanZero(_amount) notEnoughFunds(_amount) {
        balances[msg.sender] -= _amount;

        // More GAS efficient
        // (bool success, ) = payable(msg.sender).call{value: _amount}("");
        // if (!success) {
        //     revert Wallet__TransferFailed();
        // }

        // Less GAS efficient
        payable(msg.sender).transfer(_amount);

        emit Withdraw(_amount, block.timestamp);
    }

    function transfer(address _receiver, uint256 _amount)
        public
        payable
        amountHigherThanZero(_amount)
        notEnoughFunds(_amount)
    {
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;
        emit Transfer(msg.sender, _receiver, _amount, block.timestamp);
    }

    function balance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}