// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./libs/Aggregator.sol";
import "./storage/LibFeatureStorage.sol";


contract ElementExSwapV2 is Aggregator {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    event FeatureFunctionUpdated(
        bytes4 indexed methodID,
        address oldFeature,
        address newFeature
    );

    function registerFeatures(Feature[] calldata features) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < features.length; ++i) {
                registerFeature(features[i]);
            }
        }
    }

    function registerFeature(Feature calldata feature) public onlyOwner {
        unchecked {
            address impl = feature.feature;
            require(impl != address(0), "registerFeature: invalid feature address.");

            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
            stor.featureNames[impl] = feature.name;

            Method[] calldata methods = feature.methods;
            for (uint256 i = 0; i < methods.length; ++i) {
                bytes4 methodID = methods[i].methodID;
                address oldFeature = stor.featureImpls[methodID];
                if (oldFeature == address(0)) {
                    stor.methodIDs.push(methodID);
                }
                stor.featureImpls[methodID] = impl;
                stor.methodNames[methodID] = methods[i].methodName;
                emit FeatureFunctionUpdated(methodID, oldFeature, impl);
            }
        }
    }

    function unregister(bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            uint256 removedFeatureCount;
            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

            // Update storage.featureImpls
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 methodID = methodIDs[i];
                address impl = stor.featureImpls[methodID];
                if (impl != address(0)) {
                    removedFeatureCount++;
                    stor.featureImpls[methodID] = address(0);
                }
                emit FeatureFunctionUpdated(methodID, impl, address(0));
            }
            if (removedFeatureCount == 0) {
                return;
            }

            // Remove methodIDs from storage.methodIDs
            bytes4[] storage storMethodIDs = stor.methodIDs;
            for (uint256 i = storMethodIDs.length; i > 0; --i) {
                bytes4 methodID = storMethodIDs[i - 1];
                if (stor.featureImpls[methodID] == address(0)) {
                    if (i != storMethodIDs.length) {
                        storMethodIDs[i - 1] = storMethodIDs[storMethodIDs.length - 1];
                    }
                    delete storMethodIDs[storMethodIDs.length - 1];
                    storMethodIDs.pop();

                    if (removedFeatureCount == 1) { // Finished
                        return;
                    }
                    --removedFeatureCount;
                }
            }
        }
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    uint256 private constant STORAGE_ID_FEATURE = 1 << 128;
    fallback() external payable {
        assembly {
            // Copy methodID to memory 0x00~0x04
            calldatacopy(0, 0, 4)

            // Store LibFeatureStorage.slot to memory 0x20~0x3F
            mstore(0x20, STORAGE_ID_FEATURE)

            // Calculate impl.slot and load impl from storage
            let impl := sload(keccak256(0, 0x40))
            if iszero(impl) {
                // revert("Not implemented method.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000174e6f7420696d706c656d656e746564206d6574686f642e0000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }

            calldatacopy(0, 0, calldatasize())
            if iszero(delegatecall(gas(), impl, 0, calldatasize(), 0, 0)) {
                // Failed, copy the returned data and revert.
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Success, copy the returned data and return.
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    function getFeature(address featureAddr) public view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

        // Calculate feature.methods.length
        uint256 methodsLength = 0;
        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                ++methodsLength;
            }
        }

        // Set methodIs
        uint256 j = 0;
        Method[] memory methods = new Method[](methodsLength);
        for (uint256 i = 0; i < stor.methodIDs.length && j < methodsLength; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                methods[j] = Method(methodID, stor.methodNames[methodID]);
                ++j;
            }
        }

        feature.feature = featureAddr;
        feature.name = stor.featureNames[featureAddr];
        feature.methods = methods;
        return feature;
    }

    function getFeatureByMethodID(bytes4 methodID) external view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        address featureAddr = stor.featureImpls[methodID];
        return getFeature(featureAddr);
    }

    function getFeatureImpl(bytes4 methodID) external view returns (address impl) {
        return LibFeatureStorage.getStorage().featureImpls[methodID];
    }

    function getFeatures() external view returns (
        uint256 featuresCount,
        address[] memory features,
        string[] memory names,
        uint256[] memory featureMethodsCount
    ) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }
            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        features = new address[](featuresCount);
        names = new string[](featuresCount);
        featureMethodsCount = new uint256[](featuresCount);
        for (uint256 i = 0; i < featuresCount; ++i) {
            features[i] = addrs[i];
            names[i] = stor.featureNames[addrs[i]];
            featureMethodsCount[i] = methodsCount[i];
        }
        return (featuresCount, features, names, featureMethodsCount);
    }

    function getMethodIDs() external view returns (uint256 count, bytes4[] memory methodIDs) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        return (stor.methodIDs.length, stor.methodIDs);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }

    function rescueETH(address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferEth(to, address(this).balance);
    }

    function rescueERC20(address asset, address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferERC20TokensWithoutCheckResult(asset, to, IERC20(asset).balanceOf(address(this)));
    }

    function rescueERC721(address asset, uint256[] calldata ids , address recipient) external onlyOwner {
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())

            switch recipient
            case 0 { mstore(0x24, caller()) }
            default { mstore(0x24, recipient) }

            for { let offset := ids.offset } lt(offset, calldatasize()) { offset := add(offset, 0x20) } {
                // tokenID
                mstore(0x44, calldataload(offset))
                if iszero(call(gas(), asset, 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        IERC1155(asset).safeBatchTransferFrom(address(this), to, ids, amounts, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../fixins/FixinTokenSpender.sol";
import "../storage/LibAggregatorStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Structs.sol";


abstract contract Aggregator is Ownable, ReentrancyGuard, FixinTokenSpender {

    uint256 private constant SEAPORT_MARKET_ID = 1;
    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    uint256 private constant ELEMENT_MARKET_ID = 2;
    address public constant ELEMENT = 0x8D6022B8A421B08E9E4cEf45E46f1c83C85d402F;

    // markets.slot == 1
    // markets.data.slot == keccak256(markets.slot) == 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6
    uint256 private constant MARKETS_DATA_SLOT = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;

    // 168 bits(ethValue)
    uint256 private constant ETH_VALUE_MASK = (1 << 168) - 1;

    // [80 bits(unused) + 8 bits(isActive) + 8 bits(isLibrary) + 160 bits(proxy)]
    uint256 private constant PROXY_MASK = (1 << 160) - 1;
    uint256 private constant IS_LIBRARY_MASK = 0xff << 160;
    uint256 private constant ACTIVE_MASK = 0xff << 168;

    function getMarket(uint256 marketId) external view returns (Structs.Market memory) {
        return LibAggregatorStorage.getStorage().markets[marketId];
    }

    function getMarkets() external view returns (
        uint256 marketsCount,
        address[] memory proxies,
        bool[] memory isLibrary,
        bool[] memory isActive
    ) {
        Structs.Market[] storage markets = LibAggregatorStorage.getStorage().markets;
        proxies = new address[](markets.length);
        isLibrary = new bool[](markets.length);
        isActive = new bool[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            proxies[i] = markets[i].proxy;
            isLibrary[i] = markets[i].isLibrary;
            isActive[i] = markets[i].isActive;
        }
        return (markets.length, proxies, isLibrary, isActive);
    }

    function addMarket(address proxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.getStorage().markets.push(Structs.Market(proxy, isLibrary, true));
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLibrary) external onlyOwner {
        Structs.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.proxy = newProxy;
        market.isLibrary = isLibrary;
    }

    function setMarketActive(uint256 marketId, bool isActive) external onlyOwner {
        Structs.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.isActive = isActive;
    }

    function getConverter() external view returns (address) {
        return LibAggregatorStorage.getStorage().converter;
    }

    function setConverter(address converter) external onlyOwner {
        LibAggregatorStorage.getStorage().converter = converter;
    }

    function approveERC20(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function batchBuyWithETH(bytes calldata tradeDatas) external payable {
        _trade(tradeDatas);
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function batchBuyWithERC20s(
        Structs.ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeDatas,
        bytes calldata conversions,
        address[] calldata dustTokens
    ) external payable {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        // convert any assets if needed
        _convertAssets(conversions);

        // trade
        _trade(tradeDatas);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function _trade(bytes calldata tradeDatas) internal {
        assembly {
            let anySuccess
            let itemLength
            let end := add(tradeDatas.offset, tradeDatas.length)
            let ptr := mload(0x40) // free memory pointer

            // nextOffset == offset + 28bytes[2bytes(marketId) + 1bytes(continueIfFailed) + 21bytes(ethValue) + 4bytes(itemLength)] + itemLength
            for { let offset := tradeDatas.offset } lt(offset, end) { offset := add(add(offset, 28), itemLength) } {
                // head == [16 bits(marketId) + 8 bits(continueIfFailed) + 168 bits(ethValue) + 32 bits(itemLength) + 32 bits(item)]
                let head := calldataload(offset)

                // itemLength = (head >> 32) & 0xffffffff
                itemLength := and(shr(32, head), 0xffffffff)

                // itemOffset == offset + 28
                // Copy item to memory ptr
                calldatacopy(ptr, add(offset, 28), itemLength)

                // marketId = head >> (8 + 168 + 32 + 32) = head >> 240
                let marketId := shr(240, head)

                // Seaport
                if eq(marketId, SEAPORT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // SEAPORT.call{value: ethValue}(item)
                    if iszero(call(gas(), SEAPORT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // ElementEx
                if eq(marketId, ELEMENT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // ELEMENT.call{value: ethValue}(item)
                    if iszero(call(gas(), ELEMENT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // Others
                // struct Market {
                //        address proxy;
                //        bool isLibrary;
                //        bool isActive;
                //  }
                // [80 bits(unused) + 8 bits(isActive) + 8 bits(isLibrary) + 160 bits(proxy)]
                // market.slot = markets.data.slot + marketId
                // market = sload(market.slot)
                let market := sload(add(MARKETS_DATA_SLOT, marketId))

                // if (!market.isActive)
                if iszero(and(market, ACTIVE_MASK)) {
                    // if (!continueIfFailed)
                    if iszero(and(shr(232, head), 0xff)) {
                         // revert("Inactive market.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x00000010496e616374697665206d61726b65742e000000000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    continue
                }

                // if (!market.isLibrary)
                if iszero(and(market, IS_LIBRARY_MASK)) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // market.proxy.call{value: ethValue}(item)
                    if iszero(call(gas(), and(market, PROXY_MASK), and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // market.proxy.delegatecall(item)
                if iszero(delegatecall(gas(), and(market, PROXY_MASK), ptr, itemLength, 0, 0)) {
                    _revertOrContinue(head)
                    continue
                }
                anySuccess := 1
            }

            // if (!anySuccess)
            if iszero(anySuccess) {
                if gt(tradeDatas.length, 0) {
                    if iszero(returndatasize()) {
                        // revert("No order succeeded.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x000000134e6f206f72646572207375636365656465642e000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    // revert(returnData)
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            function _revertOrContinue(head) {
                // continueIfFailed = (head >> (168 + 32 + 32)) & 0xff = (head >> 232) & 0xff
                // if (!continueIfFailed)
                if iszero(and(shr(232, head), 0xff)) {
                    if iszero(returndatasize()) {
                        mstore(0, head)
                        revert(0, 0x20)
                    }
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function batchBuyWithETHSimulate(Structs.TradeDetails[] calldata tradeDetails) external payable {
        // simulate trade and revert
        bytes memory error = abi.encodePacked(_simulateTrade(tradeDetails));
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function batchBuyWithERC20sSimulate(
        Structs.ERC20Pair[] calldata erc20Pairs,
        Structs.TradeDetails[] calldata tradeDetails,
        bytes calldata conversions,
        address[] calldata dustTokens
    ) external payable {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        // convert any assets if needed
        _convertAssets(conversions);

        uint256 result = _simulateTrade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        bytes memory error = abi.encodePacked(result);
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function _simulateTrade(Structs.TradeDetails[] calldata tradeDetails) internal returns (uint256 result) {
        unchecked {
            LibAggregatorStorage.Storage storage stor = LibAggregatorStorage.getStorage();
            for (uint256 i = 0; i < tradeDetails.length; ++i) {
                Structs.TradeDetails calldata item = tradeDetails[i];
                // get market details
                Structs.Market memory market = stor.markets[item.marketId];

                // market should be active
                if (market.isActive) {
                    // execute trade
                    (bool success, ) = market.isLibrary ?
                        market.proxy.delegatecall(item.tradeData) :
                        market.proxy.call{value: item.value}(item.tradeData);

                    // check if the call passed successfully
                    if (success) {
                        result |= 1 << i;
                    }
                }
            }
            return result;
        }
    }

    function _transferERC20Pairs(Structs.ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _convertAssets(bytes calldata conversions) internal {
        if (conversions.length > 0) {
            address converter = LibAggregatorStorage.getStorage().converter;
            require(converter != address(0), "Converter is not set.");

            assembly {
                let itemLength
                let end := add(conversions.offset, conversions.length)
                let ptr := mload(0x40) // free memory pointer

                // nextOffset == offset + 28bytes + itemLength
                for { let offset := conversions.offset } lt(offset, end) { offset := add(add(offset, 28), itemLength) } {
                    // head == [32 bits(itemLength) + 8 bits(continueIfFailed) + 184 bits(unused) + 32 bits(item)]
                    let head := calldataload(offset)

                    // itemLength = head >> (8 + 184 + 32) = head >> 224
                    itemLength := shr(224, head)

                    // itemOffset == offset + 28
                    // Copy item to memory ptr
                    calldatacopy(ptr, add(offset, 28), itemLength)

                    // converter.delegatecall(item)
                    if iszero(delegatecall(gas(), converter, ptr, itemLength, 0, 0)) {
                        // continueIfFailed = (head >> (184 + 32)) & 0xff = (head >> 216) & 0xff
                        // if (!continueIfFailed)
                        if iszero(and(shr(216, head), 0xff)) {
                            if iszero(returndatasize()) {
                                mstore(0, head)
                                revert(0, 0x20)
                            }
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i = 0; i < tokens.length; ) {
            _transferERC20TokensWithoutCheckResult(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibFeatureStorage {

    uint256 constant STORAGE_ID_FEATURE = 1 << 128;

    struct Storage {
        // Mapping of methodID -> feature implementation
        mapping(bytes4 => address) featureImpls;
        // Mapping of feature implementation -> feature name
        mapping(address => string) featureNames;
        // Record methodIDs
        bytes4[] methodIDs;
        // Mapping of methodID -> method name
        mapping(bytes4 => string) methodNames;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := STORAGE_ID_FEATURE }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(address token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20Tokens(address token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    function _transferERC20TokensFromWithoutCheckResult(address token, address owner, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
                mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x44), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
            }
        }
    }

    function _transferERC20TokensWithoutCheckResult(address token, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transfer(address,uint256)
                mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x24), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, 0, 0)
            }
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address recipient, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                if iszero(call(gas(), recipient, amount, 0, 0, 0, 0)) {
                    // revert("_transferEth/TRANSFER_FAILED")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000001c5f7472616e736665724574682f5452414e534645525f4641494c4544)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../libs/Structs.sol";

library LibAggregatorStorage {

    uint256 constant STORAGE_ID_AGGREGATOR = 0;

    struct Storage {
        address converter;
        Structs.Market[] markets;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_AGGREGATOR }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


abstract contract ReentrancyGuard {

    constructor() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        if (stor.reentrancyStatus == 0) {
            stor.reentrancyStatus = 1;
        }
    }

    modifier nonReentrant() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        require(stor.reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        stor.reentrancyStatus = 2;
        _;
        stor.reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library Structs {

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        bool isLibrary;
        bool isActive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../libs/Structs.sol";

library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 2 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}