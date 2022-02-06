//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDebuy.sol";

contract Debuy is IDebuy {
    uint256 public constant DEPOSIT_MULTIPLIER = 2000;
    uint256 public constant DEPOSIT_DENOMINATOR = 1000;
    uint256 public constant ACTIVITY_TIMEOUT = 100 days;

    mapping(address => uint256) private _lastActivity;

    Advert[] private _adverts;

    mapping(address => mapping(uint256 => uint256)) private _advertsOfAddress;
    mapping(uint256 => uint256) private _advertOfAddressIndex;
    mapping(address => uint256) private _advertsOfAddressCount;

    mapping(uint256 => uint256) private _advertsForListing;
    mapping(uint256 => uint256) private _advertsForListingIndex;
    uint256 private _advertsForListingCount;

    function lastActivity(address user) external view returns (uint256) {
        return _lastActivity[user];
    }

    function _addAdvertForListing(uint256 _id) private {
        uint256 length = _advertsForListingCount;
        _advertsForListing[_advertsForListingCount] = _id;
        _advertsForListingIndex[_id] = length;
        _advertsForListingCount += 1;
    }

    function _removeAdvertFromListing(uint256 _id) private {
        uint256 lastAdvertIndex = _advertsForListingCount - 1;
        uint256 advertIndex = _advertsForListingIndex[_id];

        if (advertIndex != lastAdvertIndex) {
            uint256 lastAdvertId = _advertsForListing[lastAdvertIndex];

            _advertsForListing[advertIndex] = lastAdvertId;
            _advertsForListingIndex[lastAdvertId] = advertIndex;
        }
        _advertsForListingCount -= 1;

        delete _advertsForListingIndex[_id];
        delete _advertsForListing[lastAdvertIndex];
    }

    function advertsForListingCount() external view returns (uint256) {
        return _advertsForListingCount;
    }

    function advertForListingByIndex(uint256 _index)
        external
        view
        returns (Advert memory, uint256 id)
    {
        return (
            _adverts[_advertsForListing[_index]],
            _advertsForListing[_index]
        );
    }

    function _addAdvertToAddress(address _address, uint256 _id) private {
        uint256 length = _advertsOfAddressCount[_address];
        _advertsOfAddress[_address][length] = _id;
        _advertOfAddressIndex[_id] = length;
        _advertsOfAddressCount[_address] += 1;
    }

    function _removeAdvertFromAddress(address _address, uint256 _id) private {
        uint256 lastAdvertIndex = _advertsOfAddressCount[_address] - 1;
        uint256 advertIndex = _advertOfAddressIndex[_id];

        if (advertIndex != lastAdvertIndex) {
            uint256 lastAdvertId = _advertsOfAddress[_address][lastAdvertIndex];

            _advertsOfAddress[_address][advertIndex] = lastAdvertId;
            _advertOfAddressIndex[lastAdvertId] = advertIndex;
        }
        _advertsOfAddressCount[_address] -= 1;

        delete _advertOfAddressIndex[_id];
        delete _advertsOfAddress[_address][lastAdvertIndex];
    }

    function updateActivity() public {
        _lastActivity[msg.sender] = block.timestamp;
    }

    function advert(uint256 _id) external view returns (Advert memory) {
        return _adverts[_id];
    }

    function totalAdvers() external view returns (uint256) {
        return _adverts.length;
    }

    function advertsOfAddressCount(address _address)
        external
        view
        returns (uint256)
    {
        return _advertsOfAddressCount[_address];
    }

    function advertOfAddressByIndex(address _address, uint256 _index)
        external
        view
        returns (Advert memory, uint256 id)
    {
        return (
            _adverts[_advertsOfAddress[_address][_index]],
            _advertsOfAddress[_address][_index]
        );
    }

    // if _buyer set to zero address then anyone could apply to this advert
    function createAdvert(
        uint256 _price,
        string calldata _title,
        string calldata _description,
        string calldata _region,
        string calldata _ipfs,
        address _buyer
    ) external payable returns (uint256 id) {
        Status status = Status.Created;
        if (msg.value > 0) {
            require(
                msg.value ==
                    (_price * DEPOSIT_MULTIPLIER) / DEPOSIT_DENOMINATOR,
                "Wrong deposit value."
            );
            status = Status.SellerBacked;
        }
        _adverts.push(
            Advert({
                createdAt: block.timestamp,
                status: status,
                price: _price,
                discount: 0,
                title: _title,
                description: _description,
                region: _region,
                ipfs: _ipfs,
                seller: msg.sender,
                buyer: _buyer,
                sellerRatio: DEPOSIT_MULTIPLIER,
                buyerRatio: DEPOSIT_MULTIPLIER
            })
        );

        _addAdvertToAddress(msg.sender, _adverts.length - 1);
        if (_buyer != address(0)) {
            _addAdvertToAddress(_buyer, _adverts.length - 1);
        } else {
            _addAdvertForListing(_adverts.length - 1);
        }

        emit AdvertCreated(msg.sender, _buyer, _adverts.length - 1);

        updateActivity();

        return _adverts.length - 1;
    }

    function applyToAdvert(uint256 _id) external payable {
        if (msg.sender == _adverts[_id].seller) {
            applyToAdvertBySeller(_id);
        } else if (
            msg.sender == _adverts[_id].buyer ||
            _adverts[_id].buyer == address(0)
        ) {
            applyToAdvertByBuyer(_id);
        } else {
            revert("You can't applie to this advert.");
        }
    }

    function applyToAdvertBySeller(uint256 _id) private {
        require(
            msg.value ==
                (_adverts[_id].price * _adverts[_id].sellerRatio) /
                    DEPOSIT_DENOMINATOR,
            "Wrong deposit value."
        );
        if (_adverts[_id].status == Status.Created) {
            _adverts[_id].status = Status.SellerBacked;

            emit SellerBacked(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                (_adverts[_id].price * _adverts[_id].sellerRatio) /
                    DEPOSIT_DENOMINATOR
            );
        } else if (_adverts[_id].status == Status.BuyerBacked) {
            _adverts[_id].status = Status.Active;

            emit AdvertActivated(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                (_adverts[_id].price *
                    _adverts[_id].sellerRatio +
                    _adverts[_id].price *
                    _adverts[_id].buyerRatio) / DEPOSIT_DENOMINATOR
            );
        } else {
            revert("Already applied.");
        }

        updateActivity();
    }

    function applyToAdvertByBuyer(uint256 _id) private {
        require(
            msg.value ==
                (_adverts[_id].price * _adverts[_id].buyerRatio) /
                    DEPOSIT_DENOMINATOR,
            "Wrong deposit value."
        );
        if (_adverts[_id].status == Status.Created) {
            _adverts[_id].status = Status.BuyerBacked;

            emit BuyerBacked(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                (_adverts[_id].price * _adverts[_id].buyerRatio) /
                    DEPOSIT_DENOMINATOR
            );
        } else if (_adverts[_id].status == Status.SellerBacked) {
            _adverts[_id].status = Status.Active;

            emit AdvertActivated(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                (_adverts[_id].price *
                    _adverts[_id].sellerRatio +
                    _adverts[_id].price *
                    _adverts[_id].buyerRatio) / DEPOSIT_DENOMINATOR
            );
        } else {
            revert("Already applied.");
        }
        if (_adverts[_id].buyer == address(0)) {
            _adverts[_id].buyer = msg.sender;
            _addAdvertToAddress(msg.sender, _id);
            _removeAdvertFromListing(_id);
        }

        updateActivity();
    }

    function withdraw(uint256 _id) public {
        require(
            _adverts[_id].status == Status.BuyerBacked ||
                _adverts[_id].status == Status.SellerBacked,
            "Can't withdraw from this advert."
        );
        if (msg.sender == _adverts[_id].buyer) {
            _adverts[_id].status = Status.Created;

            uint256 value = (_adverts[_id].price * _adverts[_id].buyerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = _adverts[_id].buyer.call{value: value}("");
            require(sent, "Failed to send Ether");
            emit Withdrawn(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                _adverts[_id].buyer
            );

            _removeAdvertFromAddress(_adverts[_id].buyer, _id);
            _addAdvertForListing(_id);
            _adverts[_id].buyer = address(0);
        } else if (msg.sender == _adverts[_id].seller) {
            _adverts[_id].status = Status.Created;

            uint256 value = (_adverts[_id].price * _adverts[_id].sellerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = _adverts[_id].seller.call{value: value}("");
            require(sent, "Failed to send Ether");
            emit Withdrawn(
                _adverts[_id].seller,
                _adverts[_id].buyer,
                _id,
                _adverts[_id].seller
            );
        } else {
            revert("You are not a part of this advert.");
        }

        updateActivity();
    }

    function forceClose(uint256 _id) external {
        require(_adverts[_id].status == Status.Active, "Advert is not active.");

        uint256 lastActive;
        address side;

        if (msg.sender == _adverts[_id].seller) {
            side = _adverts[_id].seller;
            lastActive = _lastActivity[_adverts[_id].buyer];
        } else if (msg.sender == _adverts[_id].buyer) {
            side = _adverts[_id].buyer;
            lastActive = _lastActivity[_adverts[_id].seller];
        } else {
            revert("You are not a part of this advert.");
        }

        require(
            block.timestamp > lastActive + ACTIVITY_TIMEOUT,
            "Activity timeout not reached."
        );

        _adverts[_id].status = Status.ForceClosed;

        uint256 value = (_adverts[_id].price *
            _adverts[_id].sellerRatio +
            _adverts[_id].price *
            _adverts[_id].buyerRatio) / DEPOSIT_DENOMINATOR;
        (bool sent, ) = msg.sender.call{value: value}("");
        require(sent, "Failed to send Ether");

        emit ForceClosed(_adverts[_id].seller, _adverts[_id].buyer, _id, side);

        updateActivity();
    }

    function confirmClose(uint256 _id) external {
        require(msg.sender == _adverts[_id].buyer, "You are not a buyer.");
        require(_adverts[_id].status == Status.Active, "Advert is not active.");

        _adverts[_id].status = Status.Finished;

        uint256 value = (_adverts[_id].price * _adverts[_id].sellerRatio) /
            DEPOSIT_DENOMINATOR +
            (_adverts[_id].price * (100 - _adverts[_id].discount)) /
            100;
        (bool sent, ) = _adverts[_id].seller.call{value: value}("");
        require(sent, "Failed to send Ether");

        value =
            (_adverts[_id].price * _adverts[_id].buyerRatio) /
            DEPOSIT_DENOMINATOR -
            (_adverts[_id].price * (100 - _adverts[_id].discount)) /
            100;
        (sent, ) = _adverts[_id].buyer.call{value: value}("");
        require(sent, "Failed to send Ether");

        emit AdvertFinished(_adverts[_id].seller, _adverts[_id].buyer, _id);

        updateActivity();
    }

    function updateBuyer(uint256 _id, address _newBuyer) public {
        require(msg.sender == _adverts[_id].seller, "You are not a seller.");

        if (_adverts[_id].status == Status.BuyerBacked) {
            _adverts[_id].status = Status.Created;

            uint256 value = (_adverts[_id].price * _adverts[_id].buyerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = _adverts[_id].buyer.call{value: value}("");
            require(sent, "Failed to send Ether");
        } else if (
            _adverts[_id].status == Status.SellerBacked ||
            _adverts[_id].status == Status.Created
        ) {} else {
            revert("Advert can't be updated.");
        }
        if (_adverts[_id].buyer != _newBuyer) {
            if (_adverts[_id].buyer != address(0)) {
                _removeAdvertFromAddress(_adverts[_id].buyer, _id);
            }
            if (_newBuyer != address(0)) {
                _addAdvertToAddress(_newBuyer, _id);
            } else {
                _addAdvertForListing(_id);
            }

            _adverts[_id].buyer = _newBuyer;
            emit BuyerUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        }

        updateActivity();
    }

    modifier onlySellerOnCreated(uint256 _id) {
        require(msg.sender == _adverts[_id].seller, "You are not a seller.");
        require(
            _adverts[_id].status == Status.Created,
            "Only empty advert could be updated."
        );
        _;
    }

    function updatePrice(uint256 _id, uint256 _newPrice)
        external
        onlySellerOnCreated(_id)
    {
        _adverts[_id].price = _newPrice;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function updateTitle(uint256 _id, string calldata _newTitle)
        external
        onlySellerOnCreated(_id)
    {
        _adverts[_id].title = _newTitle;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function updateDescription(uint256 _id, string calldata _newDescription)
        external
        onlySellerOnCreated(_id)
    {
        _adverts[_id].description = _newDescription;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function updateIpfs(uint256 _id, string calldata _newIpfs)
        external
        onlySellerOnCreated(_id)
    {
        _adverts[_id].ipfs = _newIpfs;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function updateRegion(uint256 _id, string calldata _newRegion)
        external
        onlySellerOnCreated(_id)
    {
        _adverts[_id].region = _newRegion;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function updateAdvert(
        uint256 _id,
        uint256 _newPrice,
        string calldata _newTitle,
        string calldata _newDescription,
        string calldata _newRegion,
        string calldata _newIpfs,
        address _newBuyer
    ) external onlySellerOnCreated(_id) {
        if (_newPrice != _adverts[_id].price) _adverts[_id].price = _newPrice;
        _adverts[_id].title = _newTitle;
        _adverts[_id].description = _newDescription;
        _adverts[_id].ipfs = _newIpfs;
        _adverts[_id].region = _newRegion;
        if (_newBuyer != _adverts[_id].buyer) updateBuyer(_id, _newBuyer);

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function deleteAdvert(uint256 _id) external {
        require(msg.sender == _adverts[_id].seller, "You are not a seller.");

        if (_adverts[_id].status == Status.Created) {} else if (
            _adverts[_id].status == Status.SellerBacked
        ) {
            withdraw(_id);
        } else if (_adverts[_id].status == Status.BuyerBacked) {
            updateBuyer(_id, address(0));
        } else {
            revert("Advert can't be deleted.");
        }

        _adverts[_id].status = Status.Deleted;
        _removeAdvertFromListing(_id);

        emit AdvertDeleted(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function provideDiscount(uint256 _id, uint256 _discount) external {
        require(_discount <= 100, "Discount could not be more than 100%");
        require(msg.sender == _adverts[_id].seller, "You are not a seller.");
        require(
            _adverts[_id].status == Status.Active,
            "Advert should be active to update ratio."
        );
        require(
            _discount > _adverts[_id].discount,
            "Discount could be only increased."
        );
        _adverts[_id].discount = _discount;

        emit AdvertUpdated(_adverts[_id].seller, _adverts[_id].buyer, _id);
        updateActivity();
    }

    function couldBeForceCloseBySeller(uint256 _id)
        external
        view
        returns (bool)
    {
        uint256 buyerLastActive = _lastActivity[_adverts[_id].buyer];
        if (
            _adverts[_id].status == Status.Active &&
            block.timestamp > buyerLastActive + ACTIVITY_TIMEOUT
        ) return true;
        return false;
    }

    function couldBeForceCloseByBuyer(uint256 _id)
        external
        view
        returns (bool)
    {
        uint256 sellerLastActive = _lastActivity[_adverts[_id].seller];
        if (
            _adverts[_id].status == Status.Active &&
            block.timestamp > sellerLastActive + ACTIVITY_TIMEOUT
        ) return true;
        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDebuy {
    enum Status {
        Created,
        SellerBacked,
        BuyerBacked,
        Active,
        ForceClosed,
        Finished,
        Deleted
    }

    struct Advert {
        uint256 createdAt;
        Status status;
        uint256 price;
        uint256 discount;
        string title;
        string description;
        string region;
        string ipfs;
        address seller;
        address buyer;
        uint256 sellerRatio;
        uint256 buyerRatio;
    }

    event AdvertCreated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id
    );

    event SellerBacked(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        uint256 amount
    );

    event BuyerBacked(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        uint256 amount
    );

    event AdvertActivated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        address side
    );

    event ForceClosed(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id,
        address side
    );

    event AdvertFinished(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id
    );

    event AdvertUpdated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id
    );

    event BuyerUpdated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id
    );

    event AdvertDeleted(
        address indexed seller,
        address indexed buyer,
        uint256 indexed id
    );
}