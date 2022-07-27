// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../meta-cell/interfaces/ICellRepository.sol";
import "../interfaces/IAdmin.sol";
import "../interfaces/IEnhancerRepository.sol";
import "../interfaces/IMintable.sol";
import "../interfaces/IModuleBox.sol";
import "../libs/CellData.sol";
import "./interfaces/IMarketPlace.sol";

contract MarketPlace is IAdmin, IMarketPlace, IModuleBox, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping(uint256 => uint256) private enhancersAmount;
    mapping(uint256 => uint256) private modulesOnSale;
    mapping(uint256 => uint256) private nanoCellOnSale;

    uint256[] private sellingMetaCells;

    Counters.Counter private enhancerIds;
    EnumerableSet.UintSet private nanoCells;
    EnumerableSet.UintSet private modules;

    address private laboratory;
    address private madToken;
    address private metaCellToken;
    address private nanoCellToken;
    address private feeWallet;
    address private moduleToken;
    uint256 private madTokenPrice;
    uint256 private feeQuote;

    constructor(
        address _metaCellToken,
        address _nanoCellToken,
        address _madToken,
        address _moduleToken
    ) {
        _addAdmin(msg.sender);
        metaCellToken = _metaCellToken;
        nanoCellToken = _nanoCellToken;
        madToken = _madToken;
        moduleToken = _moduleToken;
        feeWallet = msg.sender;
        madTokenPrice = 100000000;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    function addAdmin(address _admin) external override onlyOwner {
        _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external override onlyOwner {
        _removeAdmin(_admin);
    }

    function setMADToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        emit TokenAdressChanged(madToken, _address);
        madToken = _address;
    }

    function setMetaCellToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        emit TokenAdressChanged(metaCellToken, _address);
        metaCellToken = _address;
    }

    function setNanoCellToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        emit TokenAdressChanged(nanoCellToken, _address);
        nanoCellToken = _address;
    }

    function setLaboratory(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        emit LaboratoryAddressChanged(laboratory, _address);
        laboratory = _address;
    }

    function setModulesAddress(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        emit ModuleAddressChanged(moduleToken, _address);
        moduleToken = _address;
    }

    function getMADToken() external view override returns (address) {
        return madToken;
    }

    function withdrawTokens(address token, address to)
        external
        override
        isAdmin
    {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
    }

    function getMetaCellToken() external view override returns (address) {
        return metaCellToken;
    }

    function getNanoCellToken() external view override returns (address) {
        return nanoCellToken;
    }

    function getLaboratory() external view override returns (address) {
        return laboratory;
    }

    function setMADTokenPrice(uint256 _price) external override isAdmin {
        require(_price > 0, "Invalid price");
        emit TokenPriceChanged(madTokenPrice, _price);
        madTokenPrice = _price;
    }

    function getMADTokenPrice() external view override returns (uint256) {
        return madTokenPrice;
    }

    function setFeeWallet(address payable _feeWallet) external isAdmin {
        require(_feeWallet != address(0), "Address should not be empty");
        emit WalletAddressChanged(feeWallet, _feeWallet);
        feeWallet = _feeWallet;
    }

    function getFeeWallet() external view returns (address) {
        return feeWallet;
    }

    function setFeeQuota(uint256 _feeQuote) external isAdmin {
        require(_feeQuote <= 100, "Invalid fee quote");
        emit FeeQuoteAmountUpdated(feeQuote, _feeQuote);
        feeQuote = _feeQuote;
    }

    function getFeeQuote() external view returns (uint256) {
        return feeQuote;
    }

    function getFeeAmount(uint256 _price) public view returns (uint256) {
        return _price.mul(feeQuote).div(100);
    }

    function getModuleAddress() external view override returns (address) {
        return moduleToken;
    }

    function buyMADToken(uint256 _amount) external payable override {
        require(_amount > 0, "Invalid amount");
        require(
            msg.value == _amount.mul(madTokenPrice) / 1 ether,
            "Not enough ether to buy"
        );

        IMintable(madToken).mint(msg.sender, _amount);
        payable(feeWallet).transfer(msg.value);
    }

    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external override isAdmin {
        require(_probability <= 100, "Invalid probability");
        enhancerIds.increment();
        uint256 _newId = enhancerIds.current();

        CellEnhancer.Enhancer memory newEnhancer = CellEnhancer.Enhancer({
            id: _newId,
            typeId: _typeId,
            probability: _probability,
            basePrice: _basePrice,
            name: _name,
            tokenAddress: _tokenAddress
        });
        enhancersAmount[_newId] = _amount;
        IEnhancerRepository(laboratory).addAvailableEnhancers(newEnhancer);

        emit EnhancerCreated(
            msg.sender,
            _newId,
            _typeId,
            _probability,
            _basePrice,
            _amount,
            _name,
            _tokenAddress,
            block.timestamp
        );
    }

    function buyEnhancerForETH(uint256 enhancerId, uint256 amount)
        external
        payable
        override
    {
        require(
            enhancersAmount[enhancerId] >= amount,
            "Not enough enhancer amount"
        );
        CellEnhancer.Enhancer memory enhancer = IEnhancerRepository(laboratory)
            .getEnhancerInfo(enhancerId);
        require(
            enhancer.tokenAddress == address(0),
            "You can not buy this enhancer"
        );
        require(
            enhancer.basePrice.mul(amount) <= msg.value,
            "Not enough funds"
        );
        payable(feeWallet).transfer(msg.value);
        _buyEnhancer(enhancerId, amount);
        emit EnhancerBought(
            msg.sender,
            enhancerId,
            amount,
            msg.value,
            block.timestamp
        );
    }

    function buyEnhancerForToken(
        address tokenAddress,
        uint256 enhancerId,
        uint256 amount
    ) external override {
        require(
            enhancersAmount[enhancerId] >= amount,
            "Not enough enhancer amount"
        );
        require(tokenAddress != address(0), "Incorrect address");
        CellEnhancer.Enhancer memory enhancer = IEnhancerRepository(laboratory)
            .getEnhancerInfo(enhancerId);
        require(
            enhancer.tokenAddress == tokenAddress,
            "You can not buy this enhancer"
        );
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            enhancer.basePrice.mul(amount)
        );
        _buyEnhancer(enhancerId, amount);
        emit EnhancerBought(
            msg.sender,
            enhancerId,
            amount,
            enhancer.basePrice.mul(amount),
            block.timestamp
        );
    }

    function _buyEnhancer(uint256 _enhancerId, uint256 _amount) private {
        IEnhancerRepository(laboratory).increaseEnhancersAmount(
            msg.sender,
            _enhancerId,
            _amount
        );
        enhancersAmount[_enhancerId] = enhancersAmount[_enhancerId].sub(
            _amount
        );
    }

    function modifyEnhancer(
        CellEnhancer.Enhancer memory _enhancer,
        uint256 _amount
    ) external override isAdmin {
        CellEnhancer.Enhancer memory enhancer = IEnhancerRepository(laboratory)
            .getEnhancerInfo(_enhancer.id);
        require(enhancer.id < type(uint256).max, "Invalid enhancer");
        require(
            enhancer.typeId == _enhancer.typeId,
            "Enhancer type doesnt match"
        );
        require(
            enhancer.tokenAddress == _enhancer.tokenAddress,
            "Wrong token address"
        );
        require(_enhancer.probability <= 100, "Invalid probability");
        IEnhancerRepository(laboratory).addAvailableEnhancers(_enhancer);
        if (_amount > 0) {
            enhancersAmount[_enhancer.id] = _amount;
        }

        emit EnhancerModified(
            msg.sender,
            _enhancer.id,
            _enhancer.typeId,
            _enhancer.probability,
            _enhancer.basePrice,
            _amount,
            _enhancer.name,
            _enhancer.tokenAddress,
            block.timestamp
        );
    }

    function addEnhancersAmount(uint256 _id, uint256 _amount)
        external
        override
        isAdmin
    {
        require(
            IEnhancerRepository(laboratory).getEnhancerInfo(_id).id !=
                type(uint256).max,
            "Non-existent enhancer"
        );
        uint256 amount = enhancersAmount[_id].add(_amount);
        enhancersAmount[_id] = amount;

        emit EnhancersAmountIncreased(
            msg.sender,
            _id,
            enhancersAmount[_id],
            block.timestamp
        );
    }

    function getEnhancersAmount(uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        return enhancersAmount[_id];
    }

    function removeEnhancerFromSale(uint256 id)
        external
        override(IMarketPlaceEnhancer)
        isAdmin
    {
        enhancersAmount[id] = 0;
        emit EnhancerRemoved(msg.sender, id, block.timestamp);
    }

    function getEnhancer(uint256 _id)
        external
        view
        override
        returns (CellEnhancer.Enhancer memory)
    {
        return IEnhancerRepository(laboratory).getEnhancerInfo(_id);
    }

    function getAllEnhancers()
        external
        view
        override
        returns (CellEnhancer.Enhancer[] memory)
    {
        return IEnhancerRepository(laboratory).getAllEnhancers();
    }

    function getOnSaleMetaCells()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        address[] memory metaCellsOwners = new address[](
            sellingMetaCells.length
        );
        for (uint256 i = 0; i < metaCellsOwners.length; i++) {
            metaCellsOwners[i] = IERC721(metaCellToken).ownerOf(
                sellingMetaCells[i]
            );
        }
        return (metaCellsOwners, sellingMetaCells);
    }

    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable
        override
    {
        // remove token from sale list
        uint256 index = getCellIndex(_tokenId);
        require(index != type(uint256).max, "Token is not found in cell list");

        // save cell before remove from old owner:
        CellData.Cell memory cell = ICellRepository(metaCellToken).getMetaCell(
            _tokenId
        );
        require(msg.value == cell.price, "Incorrect price");
        // 1. Internal operations

        // update cell with new owner:
        cell.onSale = false;
        ICellRepository(metaCellToken).updateMetaCell(
            cell,
            IERC721(metaCellToken).ownerOf(_tokenId)
        );

        uint256 feeAmount = getFeeAmount(cell.price);
        // 2. External operations
        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(metaCellToken).safeTransferFrom(
            _oldOwner,
            msg.sender,
            _tokenId,
            ""
        );

        

        if (sellingMetaCells.length > 1) {
            sellingMetaCells[index] = sellingMetaCells[
                sellingMetaCells.length - 1
            ];
        }
        sellingMetaCells.pop();

        // send funds to _oldOwner
        _oldOwner.transfer(msg.value.sub(feeAmount));

        emit MetaCellSold(
            _oldOwner,
            _tokenId,
            msg.sender,
            cell.price,
            feeAmount,
            block.timestamp
        );
    }

    function getCellIndex(uint256 _tokenId) internal view returns (uint256) {
        uint256 index;
        for (index = 0; index < sellingMetaCells.length; index++) {
            if (sellingMetaCells[index] == _tokenId) {
                return index;
            }
        }

        return type(uint256).max;
    }

    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice)
        external
        override
    {
        require(
            _newPrice > 0 && _newPrice != type(uint256).max,
            "Invalid price"
        );
        require(_tokenId != type(uint256).max, "Invalid token");

        CellData.Cell memory cell = ICellRepository(metaCellToken).getMetaCell(
            _tokenId
        );
        require(
            msg.sender == IERC721(metaCellToken).ownerOf(_tokenId),
            "You are not the owner"
        );
        cell.price = _newPrice;

        // update cell in repository
        ICellRepository(metaCellToken).updateMetaCell(cell, msg.sender);

        emit MetaCellPriceUpdated(
            IERC721(metaCellToken).ownerOf(_tokenId),
            _tokenId,
            _newPrice,
            block.timestamp
        );
    }

    function removeMetaCellFromSale(uint256 _tokenId) external override {
        // remove token from sale list
        uint256 index = getCellIndex(_tokenId);
        require(index != type(uint256).max, "Invalid token index");

        CellData.Cell memory cell = ICellRepository(metaCellToken).getMetaCell(
            _tokenId
        );
        require(
            msg.sender == IERC721(metaCellToken).ownerOf(_tokenId),
            "You are not the owner"
        );

        cell.onSale = false;

        // update cell in repository; marketplace should be allowed caller
        ICellRepository(metaCellToken).updateMetaCell(cell, msg.sender);

        if (sellingMetaCells.length > 1) {
            sellingMetaCells[index] = sellingMetaCells[
                sellingMetaCells.length - 1
            ];
        }
        sellingMetaCells.pop();

        emit MetaCellRemovedFromMarketPlace(
            msg.sender,
            _tokenId,
            block.timestamp
        );
    }

    function sellMetaCell(uint256 _tokenId, uint256 _price) external override {
        require(_price > 0 && _price != type(uint256).max, "Invalid price");
        require(_tokenId != type(uint256).max, "Invalid token");

        CellData.Cell memory cell = ICellRepository(metaCellToken).getMetaCell(
            _tokenId
        );
        require(
            msg.sender == IERC721(metaCellToken).ownerOf(_tokenId),
            "You are not the owner"
        );
        require(!cell.onSale, "Token already added to sale list");

        // set price and sale flag for cell
        cell.price = _price;
        cell.onSale = true;

        // update cell in repository
        ICellRepository(metaCellToken).updateMetaCell(cell, msg.sender);

        // add to array of selling tokens
        sellingMetaCells.push(_tokenId);

        emit MetaCellAddedToMarketplace(
            msg.sender,
            _tokenId,
            _price,
            block.timestamp
        );
    }

    function buyModule(uint256 id) external override {
        address oldOwnerOf = IERC721(moduleToken).ownerOf(id);
        uint256 price = modulesOnSale[id];
        require(modulesOnSale[id] != 0, "Empty price");
        require(oldOwnerOf != msg.sender, "You are the owner");
        require(
            IERC20(madToken).balanceOf(msg.sender) > price,
            "Not enough funds"
        );
        IERC20(madToken).transferFrom(msg.sender, address(this), price);
        uint256 feeAmount = getFeeAmount(price);
        IERC20(madToken).approve(address(this), price.sub(feeAmount));
        IERC20(madToken).transferFrom(
            address(this),
            oldOwnerOf,
            price.sub(feeAmount)
        );

        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(moduleToken).safeTransferFrom(oldOwnerOf, msg.sender, id, "");
        delete modulesOnSale[id];
        EnumerableSet.remove(modules, id);
        emit ModuleSold(
            oldOwnerOf,
            id,
            msg.sender,
            price,
            feeAmount,
            block.timestamp
        );
    }

    function sellModule(uint256 id, uint256 price) external override {
        require(!EnumerableSet.contains(modules, id), "Module is on sale");
        require(price != 0, "Invalid price");
        require(
            IERC721(moduleToken).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        modulesOnSale[id] = price;
        EnumerableSet.add(modules, id);
        emit ModuleAddedToMarketPlace(msg.sender, id, price, block.timestamp);
    }

    function removeModuleFromSale(uint256 id) external override {
        require(modulesOnSale[id] != 0, "Module is not on sale");
        require(
            IERC721(moduleToken).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        delete modulesOnSale[id];
        EnumerableSet.remove(modules, id);
        emit ModuleRemovedFromMarketPlace(msg.sender, id, block.timestamp);
    }

    function getModulesOnSale()
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(modules);
    }

    function getModulePrice(uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return modulesOnSale[id];
    }

    function updateModulesPrice(uint256 id, uint256 price) external override {
        require(
            IERC721(moduleToken).ownerOf(id) == msg.sender,
            "You are not the owner"
        );
        require(
            EnumerableSet.contains(modules, id),
            "Module is not not on sale"
        );
        require(price > 0, "Invalid price");
        modulesOnSale[id] = price;
        emit ModulePriceUpdated(msg.sender, id, price, block.timestamp);
    }

    function buyNanoCell(uint256 id) external override {
        address oldOwnerOf = IERC721(nanoCellToken).ownerOf(id);
        uint256 price = nanoCellOnSale[id];
        require(price != 0, "Empty price");
        require(oldOwnerOf != msg.sender, "You are the owner");
        require(
            IERC20(madToken).balanceOf(msg.sender) > price,
            "Not enough funds"
        );
        IERC20(madToken).transferFrom(msg.sender, address(this), price);
        uint256 feeAmount = getFeeAmount(price);
        IERC20(madToken).approve(address(this), price.sub(feeAmount));
        IERC20(madToken).transferFrom(
            address(this),
            oldOwnerOf,
            price.sub(feeAmount)
        );

        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(nanoCellToken).safeTransferFrom(oldOwnerOf, msg.sender, id, "");
        delete nanoCellOnSale[id];
        EnumerableSet.remove(nanoCells, id);
        emit NanoCellSold(
            oldOwnerOf,
            id,
            msg.sender,
            price,
            feeAmount,
            block.timestamp
        );
    }

    function sellNanoCell(uint256 id, uint256 price) external override {
        require(price != 0, "Invalid price");
        require(
            IERC721(nanoCellToken).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        require(!EnumerableSet.contains(nanoCells, id), "NanoCell is on sale");
        nanoCellOnSale[id] = price;
        EnumerableSet.add(nanoCells, id);
        emit NanoCellAddedToMarketPlace(msg.sender, id, price, block.timestamp);
    }

    function removeNanoCellFromSale(uint256 id) external override {
        require(nanoCellOnSale[id] != 0, "NanoCell is not on sale");
        require(
            IERC721(nanoCellToken).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        delete nanoCellOnSale[id];
        EnumerableSet.remove(nanoCells, id);
        emit NanoCellRemovedFromMarketPlace(msg.sender, id, block.timestamp);
    }

    function getNanoCellsOnSale()
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(nanoCells);
    }

    function getNanoCellPrice(uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return nanoCellOnSale[id];
    }

    function updateNanoCellPrice(uint256 id, uint256 price) external override {
        require(
            IERC721(nanoCellToken).ownerOf(id) == msg.sender,
            "You are not the owner"
        );
        require(
            EnumerableSet.contains(nanoCells, id),
            "NanoCell is not on sale"
        );
        require(price > 0, "Invalid price");
        nanoCellOnSale[id] = price;
        emit NanoCellPriceUpdated(msg.sender, id, price, block.timestamp);
    }

    function setPricePerBox(uint256 price) external override isAdmin {
        pricePerBox = price;
        emit ModuleBoxPriceChanged(price, block.timestamp);
    }

    function getPricePerBox() external view override returns (uint256) {
        return pricePerBox;
    }

    function buyBox(address owner) external override {
        require(
            IERC20(madToken).balanceOf(msg.sender) >= pricePerBox,
            "Not enough funds"
        );

        //TODO: ideally we should send mad directly to feeWallet
        IERC20(madToken).transferFrom(msg.sender, address(this), pricePerBox);

        boxCounter.increment();
        Modules.ModuleBox memory box = Modules.ModuleBox(
            boxCounter.current(),
            owner,
            block.number + 10
        ); // TODO define random range

        boxes[box.id] = box;
        EnumerableSet.add(boxIds[owner], box.id);
        emit ModuleBoxCreated(owner, box.id, box.expired);
    }

    function openBox(uint256 id) external override {
        require(id > 0, "Incorect Box Id");
        require(msg.sender == boxes[id].owner, "You do not own of the box");
        require(block.number >= boxes[id].expired, "Not ready to be opened");

        EnumerableSet.remove(boxIds[msg.sender], id);
        delete boxes[id];
        uint256 moduleId = IMintable(moduleToken).mint(msg.sender, 1);

        emit ModuleBoxOpened(msg.sender, id, moduleId, block.timestamp);
    }

    function getBoxById(uint256 id)
        external
        view
        override
        returns (Modules.ModuleBox memory)
    {
        return boxes[id];
    }

    function getUserBoxes(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(boxIds[owner]);
    }

    function numberOfEnhancersType() external view override returns (uint256) {
        return enhancerIds.current();
    }

    function withdrawETH(address payable to) external isAdmin {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "../../libs/CellData.sol";
/**
 * @title Interface for interaction with particular cell
 */
interface ICellRepository {
    

    function addMetaCell(CellData.Cell memory _cell) external;

    function removeMetaCell(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external;

    function getMetaCell(uint256 _tokenId)
        external
        view
        returns (CellData.Cell memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceSetter {
    /**
     * @dev function that sets ERC20 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC20 token
     */
    function setMADToken(address _address) external;

    /**
     * @dev function that sets MetaCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of MetaCell token
     */
    function setMetaCellToken(address _address) external;

    /**
     * @dev function that sets NanoCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of NanoCell token
     */
    function setNanoCellToken(address _address) external;

    /**
     * @dev function that sets laboratory contract address.
     * @dev emits LaboratoryAddressChanged
     * @param _address is address of Laboratory address
     */
    function setLaboratory(address _address) external;

    /**
     * @dev set modules contract address
     * @dev emits ModulesAddressChanged
     */
    function setModulesAddress(address _address) external;

    /**
     * @dev function thats sets price of ERC20 token.
     * @dev emits TokenPriceChanged
     * @param _price is amount per 1 ERC20 token
     */
    function setMADTokenPrice(uint256 _price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceNanoCell {
    /**
     * @dev function that buyer buy NanoCell from seller
     */
    function buyNanoCell(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellNanoCell(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeNanoCellFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellsOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellPrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateNanoCellPrice(uint256 id, uint256 price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceModule {
    /**
     * @dev transfers module from one user to another
     */
    function buyModule(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellModule(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeModuleFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getModulesOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getModulePrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateModulesPrice(uint256 id, uint256 price) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceMetaCell {
    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable;

    /**
     * @dev Marks meta cell token as available for selling
     * @param _tokenId id of the cell
     * @param _price selling price
     */
    function sellMetaCell(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Updates token sell price
     * @param _tokenId id of the cell
     * @param _newPrice new price of the token
     */
    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice) external;

    /**
     * @dev Marks token as unavailable for selling
     * @param _tokenId id of the cell
     */
    function removeMetaCellFromSale(uint256 _tokenId) external;

    /**
     * @dev Returns all tokens that on sale now as an array of IDs
     */
    function getOnSaleMetaCells()
        external
        view
        returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceMAD {
    /**
     * @dev function that returns price per 1 token.
     */
    function getMADTokenPrice() external view returns (uint256);

    /**
     * @dev payable function thata allows to buy ERC20 token for ether
     * @param _amount amount of ERC20 tokens to buy
     */
    function buyMADToken(uint256 _amount) external payable;

    /**
     * @dev withdraw MAD rokens to owner
     */
    function withdrawTokens(address token, address to) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IMarketPlaceGetter {
    /**
     * @dev Returns MAD token address
     * @return address of MAD token
     */
    function getMADToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getMetaCellToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getNanoCellToken() external view returns (address);

    /**
     * @dev  returns modules contract address
     */
    function getModuleAddress() external view returns (address module);

    /**
     * @dev function that returns ERC721 token address
     */
    function getLaboratory() external view returns (address laboratory);

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/**
 * @title IMarketPlaceEvent - interface that contains the define of events 
 */
interface IMarketPlaceEvent {
    /**
     * @dev Emits when token adress is changed
     * @param oldToken is old address token
     * @param newToken is token address that will be changed
     */
    event TokenAdressChanged(address oldToken, address newToken);

    /**
     * @dev Emits when Laboratory adress is changed
     * @param oldLaboratory is old Laboratory address
     * @param newLaboratory is new Laboratory address
     */
    event LaboratoryAddressChanged(address oldLaboratory, address newLaboratory);

    /**
     * @dev Emits when modules token adress is changed
     * @param oldModules is old modules address
     * @param newModules is new modules address
     */
    event ModuleAddressChanged(address oldModules, address newModules);

    /**
     * @dev Emits when wallet adress is changed
     * @param oldWallet is old wallet address
     * @param newWallet is new wallet address
     */
    event WalletAddressChanged(address oldWallet, address newWallet);

    /**
     * @dev Emits when fee amount is changed
     * @param oldFeeAmount is old fee amount
     * @param newFeeAmount is new fee amount
     */
    event FeeQuoteAmountUpdated(uint256 oldFeeAmount, uint256 newFeeAmount);

    /**
     * @dev Emits when token price is changed
     * @param oldPrice is old price of token
     * @param newPrice is new price of token
     */
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);

    /**
     * @dev Emits when account successfully added MetaCell to marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param price is ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellAddedToMarketplace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when account successfully added NanoCell to marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param price is MDMA price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellAddedToMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when account successfully added Module to marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param price is MDMA price of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleAddedToMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 price, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed MetaCell from marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed NanoCell from marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully removed Module from marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought MetaCell from seller
     * @param seller is seller address of MetaCell
     * @param tokenId is id of the MetaCell that sold
     * @param buyer is buyer address that buyed the MetaCell
     * @param price is the ETH price at the time MetaCell sold
     * @param fee is the ETH fee charged
     * @param timestamp is the time that event emitted
     */
    event MetaCellSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought NanoCell from seller
     * @param seller is seller address of NanoCell
     * @param tokenId is id of the NanoCell that sold
     * @param buyer is buyer address that buyed the NanoCell
     * @param price is the MDMA token price at the time NanoCell sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event NanoCellSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when buyer successfully bought Module from seller
     * @param seller is seller address of Module
     * @param tokenId is id of the Module that sold
     * @param buyer is buyer address that buyed the Module
     * @param price is the MDMA token price at the time Module sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event ModuleSold(
        address indexed seller, 
        uint256 indexed tokenId, 
        address indexed buyer, 
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated MetaCell price
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param newPrice is new ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellPriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated NanoCell price
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param newPrice is new ETH price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellPriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when owner updated Module price
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param newPrice is new ETH price of Module
     * @param timestamp is the time that event emitted
     */
    event ModulePriceUpdated(
        address indexed ownerOf, 
        uint256 indexed tokenId, 
        uint256 indexed newPrice, 
        uint256 timestamp
    );

    /**
     * @dev Emits when admin created the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerCreated(
        address admin,
        uint256 indexed id, 
        uint256 indexed typeId, 
        uint256 indexed probability, 
        uint256 basePrice,
        uint256 amount, 
        string name,
        address tokenAddress,
        uint256 timestamp
    );
    
    /**
     * @dev Emits when admin increased the amount of Enhancers
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param amount is the current amount after admin increasing the Enhancers
     * @param timestamp is the time that event emitted
     */
    event EnhancersAmountIncreased(
        address indexed admin, 
        uint256 indexed id, 
        uint256 amount, 
        uint256 timestamp
    );

    /**
     * @dev Emits when admin modified the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerModified(
        address admin,
        uint256 indexed id, 
        uint256 indexed typeId, 
        uint256 indexed probability, 
        uint256 basePrice,
        uint256 amount, 
        string name,
        address tokenAddress,
        uint256 timestamp
    );

    /**
     * @dev Emits when admin removed the Enhancer from MarketPlace
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param timestamp is the time that event emitted
     */
    event EnhancerRemoved(
        address indexed admin, 
        uint256 indexed id, 
        uint256 timestamp
    );

    /**
     * @dev Emits when user successfully bought Enhancer
     * @param buyer is buyer address
     * @param id is id of Enhancer
     * @param amount is the amount of Enhancers buyer has buyed
     * @param price is the ETH price that buyer has paid
     * @param timestamp is the time that event emitted
     */
    event EnhancerBought(
        address indexed buyer, 
        uint256 indexed id, 
        uint256 indexed amount, 
        uint256 price,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;
import "../../libs/Enhancer.sol";

interface IMarketPlaceEnhancer {
    /**
     * @notice Buy enhancer for ETH
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be equal to address zero
     * - Base price multiple `amount` must be less than msg.value
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForETH(
        uint256 enhancerId, 
        uint256 amount
    ) external 
        payable;

    /**
     * @notice Buy enhancer for token address
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be not equal to address zero
     * - Token address to pay must be equal to `tokenAddress`
     * @param tokenAddress is token address
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForToken(
        address tokenAddress,
        uint256 enhancerId,
        uint256 amount
    ) external;

    /**
     * @dev Returns enhancer info by id
     * @param id is id of Enhancer
     * @return Enhancer info
     */
    function getEnhancer(uint256 id)
        external
        view
        returns (CellEnhancer.Enhancer memory);

    /**
     * @dev returns all available enhancers
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory);

    /**
     * @dev Returns amount of availbale enhancers by given id
     */
    function getEnhancersAmount(uint256 _id) external view returns (uint256);

    function numberOfEnhancersType() external view returns (uint);

    /**
     * @dev Creates enhancer with options
     */
    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external;

    /**
     * @dev Modifies enhancer's info
     * can be changed everything except enhancer's type
     */
    function modifyEnhancer(CellEnhancer.Enhancer memory, uint256) external;

    /**
     * @dev Increases enhancer amount by it's id
     */
    function addEnhancersAmount(uint256 _id, uint256 _amount) external;

    /**
     * @dev Removes enhancer from marketPlace
     */
    function removeEnhancerFromSale(uint256 id) external;

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./IMarketPlaceEvent.sol";
import "./IMarketPlaceGetter.sol";
import "./IMarketPlaceSetter.sol";
import "./IMarketPlaceMetaCell.sol";
import "./IMarketPlaceNanoCell.sol";
import "./IMarketPlaceMAD.sol";
import "./IMarketPlaceModule.sol";
import "./IMarketPlaceEnhancer.sol";


interface IMarketPlace is 
    IMarketPlaceEvent,
    IMarketPlaceGetter,
    IMarketPlaceSetter,
    IMarketPlaceMetaCell,
    IMarketPlaceNanoCell,
    IMarketPlaceMAD,
    IMarketPlaceModule,
    IMarketPlaceEnhancer
{
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Modules {
    struct ModuleBox {
        // id for internal usage;
        uint256 id;
        // owner of module
        address owner;
        // time when module will be ready to be opened
        uint256 expired;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Representation of enhancer options
 */
library CellEnhancer {
    /**
     * @dev Enhancer
     * @param id - enhancer id
     * @param typeId - enhancer type id
     * @param probability - chance of successful enhancement
     * @param basePrice - default price
     * @param baseCurrency - default currency
     * @param enhancersAmount - amount of existing enhancers
     */
    struct Enhancer {
        uint256 id;
        uint8 typeId;
        uint16 probability;
        uint256 basePrice;
        string name;
        address tokenAddress;
        //todo uint256 amount; add
    }

    enum EnhancerType {
        UNKNOWN_ENHANCER,
        STAGE_ENHANCER,
        SPLIT_ENHANCER
    }

    function convertEnhancer(uint8 enhancerType)
        internal
        pure
        returns (EnhancerType)
    {
        if (enhancerType == 1) {
            return EnhancerType.STAGE_ENHANCER;
        } else if (enhancerType == 2) {
            return EnhancerType.SPLIT_ENHANCER;
        }

        return EnhancerType.UNKNOWN_ENHANCER;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_MAD,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO || _class == Class.SPLITTABLE_MAD || _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libs/Module.sol";

abstract contract IModuleBox {
    using Counters for Counters.Counter;
    Counters.Counter internal boxCounter;
    mapping(address => EnumerableSet.UintSet) internal boxIds;
    mapping(uint256 => Modules.ModuleBox) internal boxes;
    uint256 internal pricePerBox;

    event ModuleBoxCreated(address owner, uint256 id, uint256 expired);

    event ModuleBoxOpened(address owner, uint256 id, uint256 moduleId, uint256 timestamp);

    event ModuleBoxPriceChanged(uint256 id, uint256 timestamp);

    /**
     * @dev set price per box
     */
    function setPricePerBox(uint256 price) external virtual;

    /**
     * @dev returns price per 1 box
     */
    function getPricePerBox() external view virtual returns (uint256);

    /**
     * @dev creates lootbox module for user
     * @dev ModuleBoxCreated to be emitted
     */
    function buyBox(address owner) external virtual;

    /**
     * @dev openBox is minting ERC721 token to owner
     * @dev returns tokenId
     * @dev BoxOpened to be emitted
     */
    function openBox(uint256 id) external virtual;

    /**
     * @dev getBoxById returns full info about box
     */
    function getBoxById(uint256 id)
        external
        view
        virtual
        returns (Modules.ModuleBox memory);

    /**
     * @dev returns all available for particular user box ids
     */
    function getUserBoxes(address owner)
        external
        view
        virtual
        returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

abstract contract IMintable {
    function burn(uint256) external virtual;

    function mint(address, uint256) external virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libs/Enhancer.sol";

/**
 * @title Interface for interaction with particular cell
 */
abstract contract IEnhancerRepository {
    using SafeMath for uint256;
    /**
     * @dev emits enhancer amount
     */
    event EnhancerAmountChanged(uint256, uint256);
    /**
     * @dev emits when enhancer is added
     */
    event EnhancerAdded(uint256);

    CellEnhancer.Enhancer[] private availableEnhancers;

    struct Enhancer {
        uint256 id;
        uint256 amount;
    }
    mapping(address => Enhancer[]) internal ownedEnhancers;

    /**
     * @dev Adds available enhancers to storage
     */
    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        virtual;

    function _addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        internal
    {
        uint256 _index = findEnhancerById(_enhancer.id);
        if (_index == type(uint256).max) {
            availableEnhancers.push(_enhancer);
        } else {
            availableEnhancers[_index] = _enhancer;
        }
    }

    /**
     * @dev Returns enhancer info by it's id
     */
    function getEnhancerInfo(uint256 _id)
        public
        view
        returns (CellEnhancer.Enhancer memory)
    {
        uint256 _index = findEnhancerById(_id);
        if (_index == type(uint256).max) {
            CellEnhancer.Enhancer memory _enhancer;
            _enhancer.id = type(uint256).max;
            return _enhancer;
        }
        return availableEnhancers[_index];
    }

    /**
     * @dev Increases amount of enhancers of particular user
     */
    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 i = 0; i < len; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .add(_amount);
                return;
            }
        }

        Enhancer memory _enhancer = Enhancer(_id, _amount);
        ownedEnhancers[_owner].push(_enhancer);
    }

    /**
     * @dev Decreases available user enhancers
     */
    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < ownedEnhancers[_owner].length; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .sub(_amount);
                index = i;
                break;
            }
        }

        if (
            index != type(uint256).max &&
            ownedEnhancers[_owner][index].amount == 0
        ) {
            ownedEnhancers[_owner][index] = ownedEnhancers[_owner][
                ownedEnhancers[_owner].length - 1
            ];
            ownedEnhancers[_owner].pop();
        }
    }

    /**
     * @dev Returns ids of all available enhancers for particular user
     */
    function getUserEnhancers(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = ownedEnhancers[_owner].length;
        uint256[] memory _ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _ids[i] = ownedEnhancers[_owner][i].id;
        }
        return _ids;
    }

    /**
     * @dev Returns types of all enhancers that are stored
     */
    function getEnhancerTypes() external view returns (uint8[] memory) {
        uint8[] memory _types = new uint8[](availableEnhancers.length);

        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            _types[index] = availableEnhancers[index].typeId;
        }

        return _types;
    }

    /**
     * @dev Returns amount of enhancers by it"s id
     * for particular user
     */
    function getEnhancersAmount(address _owner, uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 index = 0; index < len; index++) {
            if (ownedEnhancers[_owner][index].id == id) {
                return ownedEnhancers[_owner][index].amount;
            }
        }
        return 0;
    }

    function findEnhancerById(uint256 _id) private view returns (uint256) {
        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            if (_id == availableEnhancers[index].id) {
                return index;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns all stored enhancer
     * that are available
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory)
    {
        return availableEnhancers;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    modifier isAdmin() {
        require(admins.contains(msg.sender), "You do not have rights");
        _;
    }

    event AdminAdded(address);
    event AdminRemoved(address);

    function addAdmin(address _admin) external virtual;

    function removeAdmin(address _admin) external virtual;

    function _addAdmin(address _admin) internal {
        require(_admin != address(0), "Address should not be empty");
        require(!admins.contains(_admin), "Already added");
        if (!admins.contains(_admin)) {
            admins.add(_admin);
            emit AdminAdded(_admin);
        }
    }

    function _removeAdmin(address _admin) internal {
        require(admins.contains(_admin), "Not exist");
        if (admins.contains(_admin)) {
            admins.remove(_admin);
            emit AdminRemoved(_admin);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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