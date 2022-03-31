/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {OwnedUpgradeabilityProxy} from "../packages/oz/upgradeability/OwnedUpgradeabilityProxy.sol";
/**
 * @author Opyn Team
 * @title AddressBook Module
 */
contract AddressBook is Ownable {
    
    /// @dev OptionFactory key
    bytes32 private constant OPTION_FACTORY = keccak256("OPTION_FACTORY");
    /// @dev Whitelist key
    bytes32 private constant WHITELIST = keccak256("WHITELIST");
    /// @dev Controller key
    bytes32 private constant CONTROLLER = keccak256("CONTROLLER");
    /// @dev MarginPool key
    bytes32 private constant MARGIN_POOL = keccak256("MARGIN_POOL");
    /// @dev MarginCalculator key
    bytes32 private constant MARGIN_CALCULATOR = keccak256("MARGIN_CALCULATOR");
    /// @dev LiquidationManager key
    bytes32 private constant LIQUIDATION_MANAGER = keccak256("LIQUIDATION_MANAGER");
    /// @dev Oracle key
    bytes32 private constant ORACLE = keccak256("ORACLE");

    bytes32 private constant EXCAHNGE = keccak256("EXCAHNGE");
    
    bytes32 private constant ASSET_MANAGEMENT = keccak256("ASSET_MANAGEMENT");

    bytes32 private constant OPTION_SETTLEMENT = keccak256("OPTION_SETTLEMENT");

    bytes32 private constant MILK_PRICER = keccak256("MILK_PRICER");
    
    

    /// @dev mapping between key and address
    mapping(bytes32 => address) private addresses;

    /// @notice emits an event when a new proxy is created
    event ProxyCreated(bytes32 indexed id, address indexed proxy);
    /// @notice emits an event when a new address is added
    event AddressAdded(bytes32 indexed id, address indexed add);

    /**
     * @notice return oTokenFactory address
     * @return OptionFactory address
     */
    function getOptionFactory() external view returns (address) {
        return getAddress(OPTION_FACTORY);
    }

    /**
     * @notice return Whitelist address
     * @return Whitelist address
     */
    function getWhitelist() external view returns (address) {
        return getAddress(WHITELIST);
    }

    /**
     * @notice return Controller address
     * @return Controller address
     */
    function getController() external view returns (address) {
        return getAddress(CONTROLLER);
    }

    /**
     * @notice return MarginPool address
     * @return MarginPool address
     */
    function getMarginPool() external view returns (address) {
        return getAddress(MARGIN_POOL);
    }

    /**
     * @notice return MarginCalculator address
     * @return MarginCalculator address
     */
    function getMarginCalculator() external view returns (address) {
        return getAddress(MARGIN_CALCULATOR);
    }

    /**
     * @notice return LiquidationManager address
     * @return LiquidationManager address
     */
    function getLiquidationManager() external view returns (address) {
        return getAddress(LIQUIDATION_MANAGER);
    }

    /**
     * @notice return Oracle address
     * @return Oracle address
     */
    function getOracle() external view returns (address) {
        return getAddress(ORACLE);
    }

    /**
     * @notice return Exchange address
     * @return Exchange address
     */
    function getExchange() external view returns (address) {
        return getAddress(EXCAHNGE);
    }
    
    function getMilkPricer() external view returns (address) {
        return getAddress(MILK_PRICER);
    }

    function setMilkPricer(address _milkPricer) external onlyOwner {
        setAddress(MILK_PRICER, _milkPricer);
    }
       /**
     * @notice return AssetManagement address
     * @return AssetManagement address
     */
    function getAssetManagement() external view returns (address) {
        return getAddress(ASSET_MANAGEMENT);
    }

    function setAssetManagement(address _assetManagement) external onlyOwner {
        setAddress(ASSET_MANAGEMENT, _assetManagement);
    }

    function setOptionSettlement(address _optionSettlement) external onlyOwner{
        setAddress(OPTION_SETTLEMENT, _optionSettlement);
    }
   

     function getOptionSettlement() external view returns (address) {
        return getAddress(OPTION_SETTLEMENT);
    }

    /**
     * @notice set Exchange address
     * @dev can only be called by the addressbook owner
     * @param _exchange Exchange address
     */
    function setExchange(address _exchange) external onlyOwner {
        setAddress(EXCAHNGE, _exchange);
    }

 
    /**
     * @notice set OptionFactory address
     * @dev can only be called by the addressbook owner
     * @param _otokenFactory OptionFactory address
     */
    function setOptionFactory(address _otokenFactory) external onlyOwner {
        setAddress(OPTION_FACTORY, _otokenFactory);
    }

    /**
     * @notice set Whitelist address
     * @dev can only be called by the addressbook owner
     * @param _whitelist Whitelist address
     */
    function setWhitelist(address _whitelist) external onlyOwner {
        setAddress(WHITELIST, _whitelist);
    }

    /**
     * @notice set Controller address
     * @dev can only be called by the addressbook owner
     * @param _controller Controller address
     */
    function setController(address _controller) external onlyOwner {
        setAddress(CONTROLLER, _controller);
    }

    /**
     * @notice set MarginPool address
     * @dev can only be called by the addressbook owner
     * @param _marginPool MarginPool address
     */
    function setMarginPool(address _marginPool) external onlyOwner {
        setAddress(MARGIN_POOL, _marginPool);
    }

    /**
     * @notice set MarginCalculator address
     * @dev can only be called by the addressbook owner
     * @param _marginCalculator MarginCalculator address
     */
    function setMarginCalculator(address _marginCalculator) external onlyOwner {
        setAddress(MARGIN_CALCULATOR, _marginCalculator);
    }

    /**
     * @notice set LiquidationManager address
     * @dev can only be called by the addressbook owner
     * @param _liquidationManager LiquidationManager address
     */
    function setLiquidationManager(address _liquidationManager) external onlyOwner {
        setAddress(LIQUIDATION_MANAGER, _liquidationManager);
    }

    /**
     * @notice set Oracle address
     * @dev can only be called by the addressbook owner
     * @param _oracle Oracle address
     */
    function setOracle(address _oracle) external onlyOwner {
        setAddress(ORACLE, _oracle);
    }

    /**
     * @notice return an address for specific key
     * @param _key key address
     * @return address
     */
    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    /**
     * @notice set a specific address for a specific key
     * @dev can only be called by the addressbook owner
     * @param _key key
     * @param _address address
     */
    function setAddress(bytes32 _key, address _address) public onlyOwner {
        addresses[_key] = _address;

        emit AddressAdded(_key, _address);
    }

    /**
     * @dev function to update the implementation of a specific component of the protocol
     * @param _id id of the contract to be updated
     * @param _newAddress address of the new implementation
     **/
    function updateImpl(bytes32 _id, address _newAddress) public onlyOwner {
        address payable proxyAddress = payable(address(uint160(getAddress(_id))));

        if (proxyAddress == address(0)) {
            bytes memory params = abi.encodeWithSignature("initialize(address,address)", address(this), owner());
            OwnedUpgradeabilityProxy proxy = new OwnedUpgradeabilityProxy();
            setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
            proxy.upgradeToAndCall(_newAddress, params);
        } else {
            OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(proxyAddress);
            proxy.upgradeTo(_newAddress);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;
import "./UpgradeabilityProxy.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /// @dev Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     * @param _newProxyOwner address of new proxy owner
     */
    function setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        setUpgradeabilityOwner(_newOwner);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param _implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
     * to initialize whatever is needed through a low level call.
     * @param _implementation representing the address of the new implementation to be set.
     * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address _implementation, bytes calldata _data) public payable onlyProxyOwner {
        upgradeTo(_implementation);
        (bool success, ) = address(this).call{value: msg.value}(_data);
        require(success);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Proxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /// @dev Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

    /**
     * @dev Tells the address of the current implementation
     * @return impl address of the current implementation
     */
    function implementation() public override view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address representing the new implementation to be set
     */
    function setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public virtual view returns (address);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Actions} from "../libs/Actions.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * ERROR CODE
 * EX1: order's maker not exist
 * EX2: taker balance not enough
 * EX3: taker allwance not enough
 * EX4: fillableTaker Token not enough
 * EX5: bathTakeOrder
 * EX6: fillableTakerAmount not enough
 * EX7: maker balance not enough
 * EX8: order Expired
 * EX9: order status error
 * EX10: cancel order remaining not enough
 * EX11: makerToken balance not enough
 * EX12: makerToken allowance not enough
 * EX13: order not match
 * EX14: buy order balance not enough
 * EX15: sell order balance not enough
 * EX16: no oToken can claim
 * EX17: order not expiry
 * EX18: must be buy order
 */

interface Controller {
    function operate(Actions.ActionArgs[] memory _actions) external;
}

interface OptionSettlementInterface {
    struct Position {
        bytes32 optionId;
        uint256 optionAmount; // 当有卖单成交，此数量增加
        address depositAsset; // 抵押资产的类型
        uint256 depositAmount; // 抵押资产数量
        uint8 pType; //0 不存在， 1 初始化，2 已经撤回，3 已关闭 。。。
    }

    function optionHoldInfo(uint256, bytes32) external returns (uint256);

    function addOptionHold(
        uint256,
        bytes32,
        uint256
    ) external;

    function subOptionHold(
        uint256,
        bytes32,
        uint256
    )external; 

    function optionWriteInfo(uint256, bytes32)
        external
        returns (Position memory);

    function setOptionWriteInfo(
        uint256,
        bytes32,
        uint256,
        address,
        uint256
    ) external;

     function subOptionWriteInfo(
        uint256,
        bytes32,
        uint256,
        uint256
    ) external;


}

interface OptionFactoryInterface {
    struct Option {
        bytes32 optionId;
        address collateral;
        address underlying;
        address strikeAsset;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    function idToOption(bytes32) external returns (Option memory);
}

interface AssetManagementInterface {
    function assetVault(uint256, address) external returns (uint256);

    function moveAsset(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount
    ) external;
}

contract MockExchangeTest is Ownable {
    struct Sign {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct OptionOrder {
        address premiumToken;
        bytes32 optionId;
        uint256 premiumAmount;
        uint256 optionAmount;
        address maker;
        uint256 accountId;
        uint256 expiry;
        uint8 direction; // 0 sell , 1 buy
        uint8 close;  // 0 非平仓订单, 1 平仓订单
    }

    struct OptionOrderInfo {
        uint256 filledPremiumAmount;
        uint256 filledOptionAmount;
        uint8 status;  // 0 不存在, 1 部分成交, 2 全部成交, 3 撤单
    }

    mapping(bytes32 => OptionOrderInfo) public optionOrderMap;
    mapping(address => mapping(address => uint256)) public userToken;
    mapping(address => mapping(address => uint256)) public sellerToken; // can redeem amount
    mapping(address => bool) bots;
    address public takerTokenAdr;
    address public controller;
    AddressBookInterface public addressBook;
    address public optionFactory;
    address public assetManagementAdr;
    address public optionSettlementAdr;
    address public marginPool;

    uint8 public OPTION_DECIMALS = 8;

   
    event OptionSettlement(
        address premiumToken,
        bytes32 optionId,
        bytes32 buyOrderId,
        bytes32 sellOrderId,
        uint256 filledPremiumAmount,
        uint256 filledOptionAmount
    );

    modifier onlyBot() {
        require(bots[msg.sender], "onlyBot");
        _;
    }

    constructor() {
       
    }

    function addBot(address _bot) public onlyOwner(){
        bots[_bot] = true;
    }

    function removeBot(address _bot) public onlyOwner(){
        bots[_bot] = false;
    }


    function checkOrderSign(
        Sign memory sign,
        bytes32 orderHash,
        address orderSigner
    ) public returns (address) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,address verifyingContract)"
                ),
                keccak256(bytes("OptionOrder")),
                keccak256(bytes("1")),
                address(this)
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, orderHash)
        );
        address signer = ecrecover(hash, sign.v, sign.r, sign.s);
        require(signer == orderSigner, "invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
    }

    
    function getOrderHash(OptionOrder memory order)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "OptionOrder(address premiumToken,bytes32 optionId,uint256 premiumAmount,"
                        "uint256 optionAmount,address maker,uint256 accountId,uint256 expiry,uint8 direction,uint8 close)"
                    ),
                    order.premiumToken,
                    order.optionId,
                    order.premiumAmount,
                    order.optionAmount,
                    order.maker,
                    order.accountId,
                    order.expiry,
                    order.direction,
                    order.close
                )
            );
    }

    function testOrderSign(OptionOrder memory bOrder,Sign memory bSign) public{
        bytes32 bOrderHash = getOrderHash(bOrder);
        checkOrderSign(bSign, bOrderHash, bOrder.maker);
    }

    function settlement(
        OptionOrder memory bOrder,
        Sign memory bSign,
        Sign memory sSign,
        OptionOrder memory sOrder,
        uint256 dealOptionAmount,
        uint256 dealPremiumAmount,
        bytes32 optionId
    ) external onlyBot() {
        // check sign
        bytes32 bOrderHash = getOrderHash(bOrder);
        bytes32 sOrderHash = getOrderHash(sOrder);
        checkOrderSign(bSign, bOrderHash, bOrder.maker);
        checkOrderSign(sSign, sOrderHash, sOrder.maker);
        // check order exist
        OptionOrderInfo memory bOrderInfo = optionOrderMap[bOrderHash];
        OptionOrderInfo memory sOrderInfo = optionOrderMap[sOrderHash];
        

        OptionFactoryInterface.Option memory option = OptionFactoryInterface(optionFactory).idToOption(optionId);

        // check optionId
        require(option.optionId == bOrder.optionId, "optionId errror");
        require(block.timestamp < option.expiry,"option expiry");
        // check account asset balance
        checkBaseOrder(bOrder, sOrder, bOrderInfo, sOrderInfo);
        // check order
        (
            uint256 minNeedCollateralAmount,
            uint256 sellerExpectPremium
        ) = getCollateralAndPremium(
                option,
                bOrder,
                sOrder,
                bOrderInfo.filledOptionAmount,
                sOrderInfo.filledPremiumAmount,
                dealOptionAmount,
                dealPremiumAmount
            );

        // transferCollateralAndPremium(
        //     bOrder,
        //     sOrder,
        //     dealOptionAmount,
        //     minNeedCollateralAmount,
        //     sellerExpectPremium
        // );

        // // update order info
        // if (sOrder.optionAmount - sOrderInfo.filledOptionAmount > dealOptionAmount) {
        //     sOrderInfo.status = 1;
        // } else {
        //     sOrderInfo.status = 2;
        // }
        // sOrderInfo.filledOptionAmount += dealOptionAmount;
        // sOrderInfo.filledPremiumAmount += sellerExpectPremium;

        // if (bOrder.premiumAmount - bOrderInfo.filledPremiumAmount > sellerExpectPremium) {
        //     bOrderInfo.status = 1;
        // } else {
        //     bOrderInfo.status = 2;
        // }
        // bOrderInfo.filledOptionAmount += dealOptionAmount;
        // bOrderInfo.filledPremiumAmount += sellerExpectPremium;
        // optionOrderMap[bOrderHash] = bOrderInfo;
        // optionOrderMap[sOrderHash] = sOrderInfo;

        // emit OptionSettlement(
        //     sOrder.premiumToken,
        //     optionId,
        //     bOrderHash,
        //     sOrderHash,
        //     sellerExpectPremium,
        //     minNeedCollateralAmount
        // );
    }

    function checkBaseOrder(
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        OptionOrderInfo memory bOrderInfo,
        OptionOrderInfo memory sOrderInfo
    ) internal {
        require(
            bOrder.premiumToken == sOrder.premiumToken &&
                bOrder.optionId == sOrder.optionId,
            "sellOrder and buyOrder not match"
        );
        require(
            bOrderInfo.status == 0 || bOrderInfo.status == 1,
            "bOrder status error"
        );
        require(
            sOrderInfo.status == 0 || sOrderInfo.status == 1,
            "sOrder status error"
        );
        require(
            block.timestamp < bOrder.expiry && block.timestamp < sOrder.expiry,
            "settlement:EX8"
        );

        // check account owner
        require(
            IERC721(assetManagementAdr).ownerOf(bOrder.accountId) ==
                bOrder.maker,
            "buyer account error"
        );
        require(
            IERC721(assetManagementAdr).ownerOf(sOrder.accountId) ==
                sOrder.maker,
            "seller account error"
        );
    }

    function getCollateralAndPremium(
        OptionFactoryInterface.Option memory option,
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        uint256 sFilledOptionAmount,
        uint256 bFilledPremiumAmount,
        uint256 dealOptionAmount,
        uint256 dealPremiumAmount
    )
        public
        returns (uint256 minNeedCollateralAmount, uint256 sellerExpectPremium)
    {
        // check seller collateral
        minNeedCollateralAmount = getCollateralAmount(dealOptionAmount, option);

        // check buyer price >= seller price
        // seller expect premium
        uint256 sellerExpectPremium = (dealOptionAmount *
            sOrder.premiumAmount) / sOrder.optionAmount;
        // buyer expect pay to seller premium
        uint256 buyerExpectPremium = (dealOptionAmount * bOrder.premiumAmount) /
            bOrder.optionAmount;
        require(
            dealPremiumAmount >= sellerExpectPremium,
            "not met seller price"
        );
        require(dealPremiumAmount <= buyerExpectPremium, "not met buyer price");

        // check order balance
        require(
            dealOptionAmount <= (sOrder.optionAmount - sFilledOptionAmount),
            "sOder optionAmount not enough"
        );
        require(
            dealPremiumAmount <= (bOrder.premiumAmount - bFilledPremiumAmount),
            "bOder premiumAmount not enough"
        );
    }

    function transferCollateralAndPremium(
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        uint256 dealOptionAmount,
        uint256 collateralAmount,
        uint256 premiumAmount
    ) internal {
        uint256 bAccountId = bOrder.accountId;
        uint256 sAccountId = sOrder.accountId;
        bytes32 optionId = sOrder.optionId;
        address premiumToken = sOrder.premiumToken;
        OptionFactoryInterface.Option memory option = OptionFactoryInterface(
            optionFactory
        ).idToOption(sOrder.optionId);
        address collateral = option.collateral;

        // for buyer
        if(bOrder.close == 1){
            OptionSettlementInterface(optionSettlementAdr).subOptionWriteInfo(
                bAccountId,
                optionId,
                dealOptionAmount,
                collateralAmount
            );
            AssetManagementInterface(assetManagementAdr).moveAsset(
                0,
                bAccountId,
                collateral,
                collateralAmount
            );
        }else{
            OptionSettlementInterface(optionSettlementAdr).addOptionHold(
                bAccountId,
                optionId,
                dealOptionAmount
            );
            AssetManagementInterface(assetManagementAdr).moveAsset(
                bAccountId,
                sAccountId,
                premiumToken,
                premiumAmount
            );
        }
        
        // for seller
        if(sOrder.close == 1){
            OptionSettlementInterface(optionSettlementAdr).subOptionHold(
                sAccountId,
                optionId,
                dealOptionAmount
            ); 
            AssetManagementInterface(assetManagementAdr).moveAsset(
                sAccountId,
                0,
                premiumToken,
                premiumAmount
            );
        }else{      
            OptionSettlementInterface(optionSettlementAdr).setOptionWriteInfo(
                sAccountId,
                optionId,
                dealOptionAmount,
                collateral,
                collateralAmount
            ); 
            AssetManagementInterface(assetManagementAdr).moveAsset(
                sAccountId,
                0,
                collateral,
                collateralAmount
            );
        }
    }

    function getCollateralAmount(
        uint256 oAmount,
        OptionFactoryInterface.Option memory option
    ) public returns (uint256) {
        uint8 decimals = ERC20(option.collateral).decimals();
        if (option.isPut) {
            return (10**decimals) * option.strikePrice * oAmount / (10**OPTION_DECIMALS);
        } else {
            return (10**decimals) * oAmount / (10**OPTION_DECIMALS);
        }
    }

    function cancelOrder(bytes32 orderHash) external onlyBot{
        OptionOrderInfo memory orderInfo = optionOrderMap[orderHash];
        orderInfo.status = 3;
        optionOrderMap[orderHash] = orderInfo;
    }

    function setTakerToken(address _takerToken) external onlyOwner {
        takerTokenAdr = _takerToken;
    }

    function init(address _controller) external onlyOwner {
        controller = _controller;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

import {MarginVault} from "./MarginVault.sol";

/**
 * @title Actions
 * @author Opyn Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;

        bytes price;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
        // vault type, 0 for spread/max loss and 1 for naked margin vault
        uint256 vaultType;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        address owner;
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
        // orderId
        bytes orderId;
    }

    struct LiquidateArgs {
        // address of the vault owner to liquidate
        address owner;
        // address of the liquidated collateral receiver
        address receiver;
        // vault id to liquidate
        uint256 vaultId;
        // amount of debt(otoken) to repay
        uint256 amount;
        // chainlink round id
        uint256 roundId;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "Actions: can only parse arguments for open vault actions");
        require(_args.owner != address(0), "Actions: cannot open vault for an invalid account");

        // if not _args.data included, vault type will be 0 by default
        uint256 vaultType;

        if (_args.data.length == 32) {
            // decode vault type from _args.data
            vaultType = abi.decode(_args.data, (uint256));
        }

        // for now we only have 2 vault types
        require(vaultType < 2, "Actions: cannot open vault with an invalid type");

        return OpenVaultArgs({owner: _args.owner, vaultId: _args.vaultId, vaultType: vaultType});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "Actions: can only parse arguments for mint actions");
        require(_args.owner != address(0), "Actions: cannot mint from an invalid account");

        return
            MintArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount,
                price: _args.data
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "Actions: can only parse arguments for burn actions");
        require(_args.owner != address(0), "Actions: cannot burn from an invalid account");

        return
            BurnArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositArgs(ActionArgs memory _args) internal pure returns (DepositArgs memory) {
        require(
            (_args.actionType == ActionType.DepositLongOption) || (_args.actionType == ActionType.DepositCollateral),
            "Actions: can only parse arguments for deposit actions"
        );
        require(_args.owner != address(0), "Actions: cannot deposit to an invalid account");

        return
            DepositArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawArgs(ActionArgs memory _args) internal pure returns (WithdrawArgs memory) {
        require(
            (_args.actionType == ActionType.WithdrawLongOption) || (_args.actionType == ActionType.WithdrawCollateral),
            "Actions: can only parse arguments for withdraw actions"
        );
        require(_args.owner != address(0), "Actions: cannot withdraw from an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw to an invalid account");

        return
            WithdrawArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(address sender,ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "Actions: can only parse arguments for redeem actions");
        require(_args.secondAddress != address(0), "Actions: cannot redeem to an invalid account");

        return RedeemArgs({owner:sender, receiver: _args.secondAddress, otoken: _args.asset, amount: _args.amount});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(
            _args.actionType == ActionType.SettleVault,
            "Actions: can only parse arguments for settle vault actions"
        );
        require(_args.owner != address(0), "Actions: cannot settle vault for an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw payout to an invalid account");

        return SettleVaultArgs({owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress,orderId: _args.data});
    }

    function _parseLiquidateArgs(ActionArgs memory _args) internal pure returns (LiquidateArgs memory) {
        require(_args.actionType == ActionType.Liquidate, "Actions: can only parse arguments for liquidate action");
        require(_args.owner != address(0), "Actions: cannot liquidate vault for an invalid account owner");
        require(_args.secondAddress != address(0), "Actions: cannot send collateral to an invalid account");
        require(_args.data.length == 32, "Actions: cannot parse liquidate action with no round id");

        // decode chainlink round id from _args.data
        uint256 roundId = abi.decode(_args.data, (uint256));

        return
            LiquidateArgs({
                owner: _args.owner,
                receiver: _args.secondAddress,
                vaultId: _args.vaultId,
                amount: _args.amount,
                roundId: roundId
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a call action
     * @param _args general action arguments structure
     * @return arguments for a call action
     */
    function _parseCallArgs(ActionArgs memory _args) internal pure returns (CallArgs memory) {
        require(_args.actionType == ActionType.Call, "Actions: can only parse arguments for call actions");
        require(_args.secondAddress != address(0), "Actions: target address cannot be address(0)");

        return CallArgs({callee: _args.secondAddress, data: _args.data});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface AddressBookInterface {
    /* Getters */


    function getOptionFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
    
    function getExchange() external view returns (address);

    function getAssetManagement() external view returns (address);

    function getOptionSettlement() external view returns (address);
    

    /* Setters */


    function setOptionFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;

    function setExchange(address _exchange) external;
    
    function setAssetManagement(address _assetManagement) external;

    function setOptionSettlement(address _optionSettlement) external;
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

// pragma experimental ABIEncoderV2;

// import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    // using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid short otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length),
                "MarginVault: invalid short otoken index"
            );
            address existingShort = _vault.shortOtokens[_index];
            require(
                (existingShort == _shortOtoken) || (existingShort == address(0)),
                "MarginVault: short otoken address mismatch"
            );

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index]+_amount;
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "MarginVault: invalid short otoken index");
        require(_vault.shortOtokens[_index] == _shortOtoken, "MarginVault: short otoken address mismatch");

        uint256 newShortAmount = _vault.shortAmounts[_index]-_amount;

        if (newShortAmount == 0) {
            delete _vault.shortOtokens[_index];
        }
        _vault.shortAmounts[_index] = newShortAmount;
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid long otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length),
                "MarginVault: invalid long otoken index"
            );
            address existingLong = _vault.longOtokens[_index];
            require(
                (existingLong == _longOtoken) || (existingLong == address(0)),
                "MarginVault: long otoken address mismatch"
            );

            _vault.longAmounts[_index] = _vault.longAmounts[_index]+(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "MarginVault: invalid long otoken index");
        require(_vault.longOtokens[_index] == _longOtoken, "MarginVault: long otoken address mismatch");

        uint256 newLongAmount = _vault.longAmounts[_index]-(_amount);

        if (newLongAmount == 0) {
            delete _vault.longOtokens[_index];
        }
        _vault.longAmounts[_index] = newLongAmount;
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid collateral amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length),
                "MarginVault: invalid collateral token index"
            );
            address existingCollateral = _vault.collateralAssets[_index];
            require(
                (existingCollateral == _collateralAsset) || (existingCollateral == address(0)),
                "MarginVault: collateral token address mismatch"
            );

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index]+_amount;
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "MarginVault: invalid collateral asset index");
        require(_vault.collateralAssets[_index] == _collateralAsset, "MarginVault: collateral token address mismatch");

        uint256 newCollateralAmount = _vault.collateralAmounts[_index]-(_amount);

        if (newCollateralAmount == 0) {
            delete _vault.collateralAssets[_index];
        }
        _vault.collateralAmounts[_index] = newCollateralAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "../interfaces/AddressBookInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author Opyn Team
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid oToken addresses, product hashes, collateral addresses, and callee addresses.
 */
contract Whitelist is Ownable {
    /// @notice AddressBook module address
    address public addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track whitelisted collateral
    mapping(address => bool) internal whitelistedCollateral;
    /// @dev mapping to track whitelisted oTokens
    mapping(bytes32 => bool) internal whitelistedOption;
    /// @dev mapping to track whitelisted callee addresses for the call action
    mapping(address => bool) internal whitelistedCallee;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address indexed collateral);
    /// @notice emits an event when an oToken is whitelisted by the OptionFactory module
    event OptionWhitelisted(bytes32 indexed option);
    /// @notice emits an event when an oToken is blacklisted by the OptionFactory module
    event OptionBlacklisted(bytes32 indexed option);
    /// @notice emits an event when a callee address is whitelisted by the owner address
    event CalleeWhitelisted(address indexed _callee);
    /// @notice emits an event when a callee address is blacklisted by the owner address
    event CalleeBlacklisted(address indexed _callee);

    /**
     * @notice check if the sender is the optionFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getOptionFactory(),
            "Whitelist: Sender is not OtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collateral asset that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollateral(address _collateral) external view returns (bool) {
        return whitelistedCollateral[_collateral];
    }

    /**
     * @notice check if an oToken is whitelisted
     * @param _option oToken address
     * @return boolean, True if the oToken is whitelisted
     */
    function isWhitelistedOption(bytes32 _option) external view returns (bool) {
        return whitelistedOption[_option];
    }

    /**
     * @notice check if a callee address is whitelisted for the call action
     * @param _callee callee destination address
     * @return boolean, True if the address is whitelisted
     */
    function isWhitelistedCallee(address _callee) external view returns (bool) {
        return whitelistedCallee[_callee];
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        require(whitelistedCollateral[_collateral], "Whitelist: Collateral is not whitelisted");
        require(
            (_isPut && (_strike == _collateral)) || (!_isPut && (_collateral == _underlying)),
            "Whitelist: Only allow fully collateralized products"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than Option as collateral. WhitelistOption() is used to whitelist Option contracts.
     * @param _collateral collateral asset address
     */
    function whitelistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = true;

        emit CollateralWhitelisted(_collateral);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collateral collateral asset address
     */
    function blacklistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = false;

        emit CollateralBlacklisted(_collateral);
    }

    /**
     * @notice allows the OtokenFactory module to whitelist a new option
     * @dev can only be called from the OtokenFactory address
     * @param _optionId _optionId
     */
    function whitelistOption(bytes32 _optionId) external onlyFactory {
        whitelistedOption[_optionId] = true;

        emit OptionWhitelisted(_optionId);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _optionId _optionId
     */
    function blacklistOption(bytes32 _optionId) external onlyOwner {
        whitelistedOption[_optionId] = false;

        emit OptionBlacklisted(_optionId);
    }

    /**
     * @notice allows the owner to whitelist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function whitelistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = true;

        emit CalleeWhitelisted(_callee);
    }

    /**
     * @notice allows the owner to blacklist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function blacklistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = false;

        emit CalleeBlacklisted(_callee);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {MarginPoolInterface} from "../interfaces/MarginPoolInterface.sol";

interface MarginCalcilatorInterface {
    function getPayout(bytes32 optionId, uint256 _amount)
        external
        view
        returns (uint256);
}

interface AssetManagementInterface {
    function assetVault(uint256, address) external returns (uint256);

    function moveAsset(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount
    ) external;
}

interface OptionFactoryInterface {
    function idToOption(bytes32 id)
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );
}

/**
 * ERROR CODE
 * AM1: Invalid address
 * AM2: asset not in whitelist
 * AM3: asset allowance not enough
 * AM4: asset balance not enough
 * AM5: msg.sender not hold accountId
 * AM6: accountId asset not enough
 * AM7: only Ex
 * AM8:
 */
/**
 * @author Milk Team
 * @title OptionSettlement
 * @notice Option Settlement
 *
 */
contract OptionSettlement is Ownable {
    struct Position {
        bytes32 optionId;
        uint256 optionAmount; // 当有卖单成交，此数量增加
        address depositAsset; // 抵押资产的类型
        uint256 depositAmount; // 抵押资产数量
        uint8 pType; //0 不存在, 1 使用中, 2 已结算
    }
    AddressBookInterface public addressBook;
    mapping(uint256 => mapping(bytes32 => uint256)) public optionHoldInfo;

    mapping(uint256 => mapping(bytes32 => Position)) public optionWriteInfo;

    address public exchange;
    address public assetManagement;
    address public calculator;
    address public optionFactory;

    modifier onlyEx() {
        require(msg.sender == exchange, "AM7");
        _;
    }

    event addOptionHoldLog(uint256 accountId, bytes32 optionId, uint256 amount);
    event subOptionHoldLog(uint256 accountId, bytes32 optionId, uint256 amount);

    event setOptionWriteInfoLog(
        uint256 sAccountId,
        bytes32 optionId,
        uint256 optionAmount,
        address collateral,
        uint256 collateralAmount
    );

    event subOptionWriteInfoLog(
        uint256 sAccountId,
        bytes32 optionId,
        uint256 optionAmount,
        uint256 collateralAmount
    );

    event ClaimLog(
        uint256 accountId,
        bytes32 optionId,
        address collateral,
        uint256 collateralAmount
    );

    event SettleLog(
        uint256 accountId,
        bytes32 optionId,
        address collateral,
        uint256 collateralAmount
    );

    constructor(address _addressBook) {
        require(_addressBook != address(0), "AM1");
        addressBook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }

    function addOptionHold(
        uint256 accountId,
        bytes32 optionId,
        uint256 amount
    ) external onlyEx {
        optionHoldInfo[accountId][optionId] += amount;
        emit addOptionHoldLog(accountId, optionId, amount);
    }

    function subOptionHold(
        uint256 accountId,
        bytes32 optionId,
        uint256 amount
    ) external onlyEx {
        require(
            optionHoldInfo[accountId][optionId] >= amount,
            "subOptionHold amount not enough"
        );
        optionHoldInfo[accountId][optionId] -= amount;
        emit subOptionHoldLog(accountId, optionId, amount);
    }

    function setOptionWriteInfo(
        uint256 sAccountId,
        bytes32 optionId,
        uint256 optionAmount,
        address collateral,
        uint256 collateralAmount
    ) external onlyEx {
        Position memory position = optionWriteInfo[sAccountId][optionId];

        if (position.pType == 1) {
            position.optionAmount += optionAmount;
            position.depositAmount += collateralAmount;
        } else if(position.pType == 0) {
            position.optionAmount = optionAmount;
            position.depositAmount = collateralAmount;
            position.pType = 1;
            position.depositAsset = collateral;
            position.optionId = optionId;
        }
        optionWriteInfo[sAccountId][optionId] = position;
        emit setOptionWriteInfoLog(
            sAccountId,
            optionId,
            optionAmount,
            collateral,
            collateralAmount
        );
    }

    function subOptionWriteInfo(
        uint256 sAccountId,
        bytes32 optionId,
        uint256 optionAmount,
        uint256 collateralAmount
    ) external onlyEx {
        Position memory position = optionWriteInfo[sAccountId][optionId];
        require(position.pType == 1, "position type error");
        require(
            position.optionAmount >= optionAmount &&
                position.depositAmount >= collateralAmount,
            "position optionAmount error"
        );
        position.optionAmount -= optionAmount;
        position.depositAmount -= collateralAmount;
        optionWriteInfo[sAccountId][optionId] = position;
        emit subOptionWriteInfoLog(
            sAccountId,
            optionId,
            optionAmount,
            collateralAmount
        );
    }


    // option holder claim
    function claim(uint256 accountId, bytes32 optionId) external {
        require(
            ERC721(assetManagement).ownerOf(accountId) == msg.sender,
            "sender accountId error"
        );
        
        (, ,address collateral, , uint256 expiry, ) = OptionFactoryInterface(optionFactory)
            .idToOption(optionId);
        // require(block.timestamp >expiry,"not expiried");
        uint256 optionAmount = optionHoldInfo[accountId][optionId];
        require(optionAmount > 0, "no optionAmount");
        uint256 payout = MarginCalcilatorInterface(calculator).getPayout(
            optionId,
            optionAmount
        );
        require(payout > 0, "no payout ");
        

        AssetManagementInterface(assetManagement).moveAsset(
            0,
            accountId,
            collateral,
            payout
        );
        optionHoldInfo[accountId][optionId] = 0;
        emit ClaimLog(accountId, optionId, collateral, payout);
    }

    // option writer settle
    function settle(uint256 accountId, bytes32 optionId) external {
        require(
            ERC721(assetManagement).ownerOf(accountId) == msg.sender,
            "sender accountId error"
        );

        (, , , , uint256 expiry, ) = OptionFactoryInterface(optionFactory)
            .idToOption(optionId);
        // require(block.timestamp >expiry,"not expiried");
        Position memory position = optionWriteInfo[accountId][optionId];

        uint256 payout = MarginCalcilatorInterface(calculator).getPayout(
            optionId,
            position.optionAmount
        );
        uint256 remainCollateral = position.depositAmount - payout;
        require(remainCollateral > 0, "no remainCollateral");
        AssetManagementInterface(assetManagement).moveAsset(
            0,
            accountId,
            position.depositAsset,
            remainCollateral
        );
        position.optionAmount = 0;
        position.depositAmount = 0;
        position.pType = 2;

        optionWriteInfo[accountId][optionId] = position;
        emit SettleLog(
            accountId,
            optionId,
            position.depositAsset,
            remainCollateral
        );
    }


    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    function _refreshConfigInternal() internal {
        exchange = addressBook.getExchange();
        assetManagement = addressBook.getAssetManagement();
        calculator = addressBook.getMarginCalculator();
        optionFactory = addressBook.getOptionFactory();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface MarginPoolInterface {
    /* Getters */
    function addressBook() external view returns (address);

    function farmer() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Admin-only functions */
    function setFarmer(address _farmer) external;

    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external;

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function batchTransferToPool(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;

    function batchTransferToUser(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {MarginPoolInterface} from "../interfaces/MarginPoolInterface.sol";

/**
 * ERROR CODE 
 * AM1: Invalid address
 * AM2: asset not in whitelist
 * AM3: asset allowance not enough
 * AM4: asset balance not enough
 * AM5: msg.sender not hold accountId
 * AM6: accountId asset not enough
 * AM7: only Ex
 * AM8: 
 */
/**
 * @author Milk Team
 * @title AssetManagement Module
 */
contract AssetManagement is ERC721, Ownable {
    uint176 public nextId = 1;

    AddressBookInterface public addressBook;
    MarginPoolInterface public pool;
    address public exchange;
    address public manager;
    address public optionSettlement;
    mapping(uint256 => mapping(address => uint256)) public assetVault;
    
    mapping(address => bool) public whitelistedAsset;

    event DepositLog(
        address sender,
        uint256 indexed accountIndex,
        address indexed asset,
        uint256 amount
    );

    event WithdrawLog(
        address sender,
        uint256 indexed accountIndex,
        address indexed asset,
        uint256 amount
    );

    event MoveAssetLog(
        uint256 indexed fromAccount,
        uint256 indexed toAccount,
        address indexed asset,
        uint256 amount
    );
   
    modifier onlyExOrOs() {
        require(msg.sender == exchange || msg.sender == optionSettlement , "AM7");
        _;
    }

    modifier depositCheck(address _asset, uint256 _amount) {
        require(_asset != address(0),"AM1");
        require(whitelistedAsset[_asset],"AM2");
        require(IERC20(_asset).allowance(msg.sender, address(pool)) >= _amount && _amount > 0 ,"AM3");
        require(IERC20(_asset).balanceOf(msg.sender) >= _amount,"AM4");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _addressBook
    ) ERC721(_name, _symbol) {
        require(_addressBook != address(0), "AM1");
        addressBook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }


    function addWhitelistedAsset(address _asset) external onlyOwner{
        whitelistedAsset[_asset] = true; 
    }    

    function mintDeposit(address _asset, uint256 _amount)
        external depositCheck(_asset,_amount)
    returns (uint256 accountId){
        _safeMint(msg.sender, (accountId = nextId++));
        _deposit(_asset, _amount, accountId);
    }

    function deposit(
        uint256 _accountId,
        address _asset,
        uint256 _amount
    ) external depositCheck(_asset,_amount){
        _deposit(_asset, _amount, _accountId);
    }

    function _deposit(
        address asset,
        uint256 amount,
        uint256 accountId
    ) internal {
        pool.transferToPool(asset,msg.sender,amount);
        assetVault[accountId][asset] += amount;
        emit DepositLog(msg.sender, accountId, asset, amount);
    }

    function withdraw(  
        uint256 _accountId,
        address _asset,
        uint256 _amount 
    ) external {
        require(_asset != address(0),"AM1");
        require(whitelistedAsset[_asset],"AM2");
        
        require(this.ownerOf(_accountId) == msg.sender,"AM5");
        require(assetVault[_accountId][_asset] >= _amount && _amount > 0,"AM6");
        
        pool.transferToUser(_asset,msg.sender,_amount);
        assetVault[_accountId][_asset] -= _amount;
        emit WithdrawLog(msg.sender, _accountId, _asset, _amount);
    }

    function moveAsset( 
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount
    ) external onlyExOrOs() {
        require(assetVault[_fromAccountId][_asset] >= _amount,"AM6");
        assetVault[_fromAccountId][_asset] -= _amount;
        assetVault[_toAccountId][_asset] += _amount;
        emit MoveAssetLog(_fromAccountId, _toAccountId, _asset, _amount);
    }


    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    function _refreshConfigInternal() internal {
        pool = MarginPoolInterface(addressBook.getMarginPool());
        exchange = addressBook.getExchange();
        optionSettlement = addressBook.getOptionSettlement();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Actions} from "../libs/Actions.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";

/**
 * ERROR CODE
 * EX1: order's maker not exist
 * EX2: taker balance not enough
 * EX3: taker allwance not enough
 * EX4: fillableTaker Token not enough
 * EX5: bathTakeOrder
 * EX6: fillableTakerAmount not enough
 * EX7: maker balance not enough
 * EX8: order Expired
 * EX9: order status error
 * EX10: cancel order remaining not enough
 * EX11: makerToken balance not enough
 * EX12: makerToken allowance not enough
 * EX13: order not match
 * EX14: buy order balance not enough
 * EX15: sell order balance not enough
 * EX16: no oToken can claim
 * EX17: order not expiry
 * EX18: must be buy order
 */

interface Controller {
    function operate(Actions.ActionArgs[] memory _actions) external;
}

interface OptionSettlementInterface {
    struct Position {
        bytes32 optionId;
        uint256 optionAmount; // 当有卖单成交，此数量增加
        address depositAsset; // 抵押资产的类型
        uint256 depositAmount; // 抵押资产数量
        uint8 pType; //0 不存在， 1 初始化，2 已经撤回，3 已关闭 。。。
    }

    function optionHoldInfo(uint256, bytes32) external returns (uint256);

    function addOptionHold(
        uint256,
        bytes32,
        uint256
    ) external;

    function subOptionHold(
        uint256,
        bytes32,
        uint256
    )external; 

    function optionWriteInfo(uint256, bytes32)
        external
        returns (Position memory);

    function setOptionWriteInfo(
        uint256,
        bytes32,
        uint256,
        address,
        uint256
    ) external;

     function subOptionWriteInfo(
        uint256,
        bytes32,
        uint256,
        uint256
    ) external;


}

interface OptionFactoryInterface {
    struct Option{
        address underlying;
        address strikeAsset;
        address collateral;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    function idToOption(bytes32) external returns (Option memory);
}

interface AssetManagementInterface {
    function assetVault(uint256, address) external returns (uint256);

    function moveAsset(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount
    ) external;
}

contract Exchange is Ownable {
    struct Sign {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct OptionOrder {
        address premiumToken;
        bytes32 optionId;
        uint256 premiumAmount;
        uint256 optionAmount;
        address maker;
        uint256 accountId;
        uint256 expiry;
        uint8 direction; // 0 sell , 1 buy
        uint8 close;  // 0 非平仓订单, 1 平仓订单
    }

    struct OptionOrderInfo {
        uint256 filledPremiumAmount;
        uint256 filledOptionAmount;
        uint8 status;  // 0 不存在, 1 部分成交, 2 全部成交, 3 撤单
    }

    mapping(bytes32 => OptionOrderInfo) public optionOrderMap;
    mapping(address => mapping(address => uint256)) public userToken;
    mapping(address => mapping(address => uint256)) public sellerToken; // can redeem amount
    mapping(address => bool) bots;
    address public takerTokenAdr;
    address public controller;
    AddressBookInterface public addressBook;
    address public optionFactory;
    address public assetManagementAdr;
    address public optionSettlementAdr;


    uint8 public OPTION_DECIMALS = 8;

   
    event OptionSettlement(
        address premiumToken,
        bytes32 optionId,
        bytes32 buyOrderId,
        bytes32 sellOrderId,
        uint256 filledPremiumAmount,
        uint256 filledOptionAmount
    );

    modifier onlyBot() {
        require(bots[msg.sender], "onlyBot");
        _;
    }

    constructor(address _addressBook) {
        addressBook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }

    function addBot(address _bot) public onlyOwner(){
        bots[_bot] = true;
    }

    function removeBot(address _bot) public onlyOwner(){
        bots[_bot] = false;
    }

    function checkOrderSign(
        Sign memory sign,
        bytes32 orderHash,
        address orderSigner
    ) public {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,address verifyingContract)"
                ),
                keccak256(bytes("OptionOrder")),
                keccak256(bytes("1")),
                address(this)
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, orderHash)
        );
        address signer = ecrecover(hash, sign.v, sign.r, sign.s);
        require(signer == orderSigner, "invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
    }

    // ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x0000000000000000000000000000000000000000000000000000000000000000",1,1,1,1,"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",1,1,1,1]
    function getOrderHash(OptionOrder memory order)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "OptionOrder(address premiumToken,bytes32 optionId,uint256 premiumAmount,"
                        "uint256 optionAmount,address maker,uint256 accountId,uint256 expiry,uint8 direction,uint8 close)"
                    ),
                    order.premiumToken,
                    order.optionId,
                    order.premiumAmount,
                    order.optionAmount,
                    order.maker,
                    order.accountId,
                    order.expiry,
                    order.direction,
                    order.close
                )
            );
    }

    function settlement(
        OptionOrder memory bOrder,
        Sign memory bSign,
        OptionOrder memory sOrder,
        Sign memory sSign,
        uint256 dealOptionAmount,
        uint256 dealPremiumAmount,
        bytes32 optionId
    ) external onlyBot() {
        // check sign
        bytes32 bOrderHash = getOrderHash(bOrder);
        bytes32 sOrderHash = getOrderHash(sOrder);
        checkOrderSign(bSign, bOrderHash, bOrder.maker);
        checkOrderSign(sSign, sOrderHash, sOrder.maker);
        // check order exist
        OptionOrderInfo memory bOrderInfo = optionOrderMap[bOrderHash];
        OptionOrderInfo memory sOrderInfo = optionOrderMap[sOrderHash];
        

        OptionFactoryInterface.Option memory option = OptionFactoryInterface(optionFactory).idToOption(optionId);

        // check optionId
        require(option.collateral != address(0), "optionId not exist");
        require(optionId == sOrder.optionId,"optionId errror");
        require(block.timestamp < option.expiry,"option expiry");
        // check account asset balance
        checkBaseOrder(bOrder, sOrder, bOrderInfo, sOrderInfo);
        // check order
        (
            uint256 minNeedCollateralAmount,
            uint256 sellerExpectPremium
        ) = getCollateralAndPremium(
                option,
                bOrder,
                sOrder,
                bOrderInfo.filledOptionAmount,
                sOrderInfo.filledPremiumAmount,
                dealOptionAmount,
                dealPremiumAmount
            );

        transferCollateralAndPremium(
            bOrder,
            sOrder,
            dealOptionAmount,
            minNeedCollateralAmount,
            sellerExpectPremium
        );

        // update order info
        if (sOrder.optionAmount - sOrderInfo.filledOptionAmount > dealOptionAmount) {
            sOrderInfo.status = 1;
        } else {
            sOrderInfo.status = 2;
        }
        sOrderInfo.filledOptionAmount += dealOptionAmount;
        sOrderInfo.filledPremiumAmount += sellerExpectPremium;

        if (bOrder.premiumAmount - bOrderInfo.filledPremiumAmount > sellerExpectPremium) {
            bOrderInfo.status = 1;
        } else {
            bOrderInfo.status = 2;
        }
        bOrderInfo.filledOptionAmount += dealOptionAmount;
        bOrderInfo.filledPremiumAmount += sellerExpectPremium;
        optionOrderMap[bOrderHash] = bOrderInfo;
        optionOrderMap[sOrderHash] = sOrderInfo;

        emit OptionSettlement(
            sOrder.premiumToken,
            optionId,
            bOrderHash,
            sOrderHash,
            sellerExpectPremium,
            minNeedCollateralAmount
        );
    }

    function checkBaseOrder(
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        OptionOrderInfo memory bOrderInfo,
        OptionOrderInfo memory sOrderInfo
    ) internal {
        require(
            bOrder.premiumToken == sOrder.premiumToken &&
                bOrder.optionId == sOrder.optionId,
            "sellOrder and buyOrder not match"
        );
        require(
            bOrderInfo.status == 0 || bOrderInfo.status == 1,
            "bOrder status error"
        );
        require(
            sOrderInfo.status == 0 || sOrderInfo.status == 1,
            "sOrder status error"
        );
        require(
            block.timestamp < bOrder.expiry && block.timestamp < sOrder.expiry,
            "settlement:EX8"
        );

        // check account owner
        require(
            IERC721(assetManagementAdr).ownerOf(bOrder.accountId) ==
                bOrder.maker,
            "buyer account error"
        );
        require(
            IERC721(assetManagementAdr).ownerOf(sOrder.accountId) ==
                sOrder.maker,
            "seller account error"
        );
    }

    function getCollateralAndPremium(
        OptionFactoryInterface.Option memory option,
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        uint256 sFilledOptionAmount,
        uint256 bFilledPremiumAmount,
        uint256 dealOptionAmount,
        uint256 dealPremiumAmount
    )
        internal
        returns (uint256 minNeedCollateralAmount, uint256 sellerExpectPremium)
    {
        // check seller collateral
        minNeedCollateralAmount = getCollateralAmount(dealOptionAmount, option);
        // require(condition);
        // check buyer price >= seller price
        // seller expect premium
        uint256 sellerExpectPremium = (dealOptionAmount *
            sOrder.premiumAmount) / sOrder.optionAmount;
        // buyer expect pay to seller premium
        uint256 buyerExpectPremium = (dealOptionAmount * bOrder.premiumAmount) /
            bOrder.optionAmount;
        require(
            dealPremiumAmount >= sellerExpectPremium,
            "not met seller price"
        );
        require(dealPremiumAmount <= buyerExpectPremium, "not met buyer price");

        // check order balance
        require(
            dealOptionAmount <= (sOrder.optionAmount - sFilledOptionAmount),
            "sOder optionAmount not enough"
        );
        require(
            dealPremiumAmount <= (bOrder.premiumAmount - bFilledPremiumAmount),
            "bOder premiumAmount not enough"
        );
        return (minNeedCollateralAmount,sellerExpectPremium);
    }

    function transferCollateralAndPremium(
        OptionOrder memory bOrder,
        OptionOrder memory sOrder,
        uint256 dealOptionAmount,
        uint256 collateralAmount,
        uint256 premiumAmount
    ) internal {
        uint256 bAccountId = bOrder.accountId;
        uint256 sAccountId = sOrder.accountId;
        bytes32 optionId = sOrder.optionId;
        address premiumToken = sOrder.premiumToken;
        OptionFactoryInterface.Option memory option = OptionFactoryInterface(
            optionFactory
        ).idToOption(sOrder.optionId);
        address collateral = option.collateral;

        // for buyer
        if(bOrder.close == 1){
            OptionSettlementInterface(optionSettlementAdr).subOptionWriteInfo(
                bAccountId,
                optionId,
                dealOptionAmount,
                collateralAmount
            );
            AssetManagementInterface(assetManagementAdr).moveAsset(
                0,
                bAccountId,
                collateral,
                collateralAmount
            );
            AssetManagementInterface(assetManagementAdr).moveAsset(
                bAccountId,
                sAccountId,
                premiumToken,
                premiumAmount
            );
        }else{
            OptionSettlementInterface(optionSettlementAdr).addOptionHold(
                bAccountId,
                optionId,
                dealOptionAmount
            );
            AssetManagementInterface(assetManagementAdr).moveAsset(
                bAccountId,
                sAccountId,
                premiumToken,
                premiumAmount
            );
        }
        
        // for seller
        if(sOrder.close == 1){
            OptionSettlementInterface(optionSettlementAdr).subOptionHold(
                sAccountId,
                optionId,
                dealOptionAmount
            ); 
            // AssetManagementInterface(assetManagementAdr).moveAsset(
            //     sAccountId,
            //     0,
            //     premiumToken,
            //     premiumAmount
            // );
        }else{      
            OptionSettlementInterface(optionSettlementAdr).setOptionWriteInfo(
                sAccountId,
                optionId,
                dealOptionAmount,
                collateral,
                collateralAmount
            ); 
            AssetManagementInterface(assetManagementAdr).moveAsset(
                sAccountId,
                0,
                collateral,
                collateralAmount
            );
        }
    }

    function getCollateralAmount(
        uint256 oAmount,
        OptionFactoryInterface.Option memory option
    ) public returns (uint256) {
        uint8 decimals = ERC20(option.collateral).decimals();
        if (option.isPut) {
            return (10**decimals) * option.strikePrice * oAmount / (10**OPTION_DECIMALS);
        } else {
            return (10**decimals) * oAmount / (10**OPTION_DECIMALS);
        }
    }

    function cancelOrder(bytes32 orderHash) external onlyBot{
        OptionOrderInfo memory orderInfo = optionOrderMap[orderHash];
        orderInfo.status = 3;
        optionOrderMap[orderHash] = orderInfo;
    }

    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    function _refreshConfigInternal() internal {
        assetManagementAdr = addressBook.getAssetManagement();
        optionSettlementAdr = addressBook.getOptionSettlement();
        optionFactory = addressBook.getOptionFactory();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

pragma experimental ABIEncoderV2;

import {MarginVault} from "../libs/MarginVault.sol";

interface MarginCalculatorInterface {
    function addressBook() external view returns (address);

    function getExpiredPayoutRate(address _otoken) external view returns (uint256);

    function getExcessCollateral(MarginVault.Vault calldata _vault, uint256 _vaultType)
        external
        view
        returns (uint256 netValue, bool isExcess);

    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

// import {SafeMath} from "../packages/oz/SafeMath.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {FixedPointInt256 as FPI} from "../libs/FixedPointInt256.sol";
import {MarginVault} from "../libs/MarginVault.sol";

interface OptionFactoryInterface {
    function idToOption(bytes32 id) external view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );
} 

/**
 * @title MarginCalculator
 * @author Opyn
 * @notice Calculator module that checks if a given vault is valid, calculates margin requirements, and settlement proceeds
 */
contract MarginCalculator is Ownable {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    /// @dev decimals option upper bound value, spot shock and oracle deviation
    uint256 internal constant SCALING_FACTOR = 27;

    /// @dev decimals used by strike price and oracle price
    uint256 internal constant BASE = 8;

    /// @notice auction length
    uint256 public constant AUCTION_TIME = 3600;

    /// @dev struct to store all needed vault details
    struct VaultDetails {
        address shortUnderlyingAsset;
        address shortStrikeAsset;
        address shortCollateralAsset;
        address longUnderlyingAsset;
        address longStrikeAsset;
        address longCollateralAsset;
        uint256 shortStrikePrice;
        uint256 shortExpiryTimestamp;
        uint256 shortCollateralDecimals;
        uint256 longStrikePrice;
        uint256 longExpiryTimestamp;
        uint256 longCollateralDecimals;
        uint256 collateralDecimals;
        uint256 vaultType;
        bool isShortPut;
        bool isLongPut;
        bool hasLong;
        bool hasShort;
        bool hasCollateral;
    }

    /// @dev oracle deviation value (1e27)
    uint256 internal oracleDeviation;

    /// @dev FixedPoint 0
    FPI.FixedPointInt internal ZERO = FPI.fromScaledUint(0, BASE);

    /// @dev mapping to store dust amount per option collateral asset (scaled by collateral decimals)
    mapping(address => uint256) internal dust;

    /// @dev mapping to store array of time to expiry for a given product
    mapping(bytes32 => uint256[]) internal timesToExpiryForProduct;

    /// @dev mapping to store option upper bound value at specific time to expiry for a given product (1e27)
    mapping(bytes32 => mapping(uint256 => uint256)) internal maxPriceAtTimeToExpiry;

    /// @dev mapping to store shock value for spot price of a given product (1e27)
    mapping(bytes32 => uint256) internal spotShock;

    /// @dev oracle module
    OracleInterface public oracle;

    /// @notice emits an event when collateral dust is updated
    event CollateralDustUpdated(address indexed collateral, uint256 dust);
    /// @notice emits an event when new time to expiry is added for a specific product
    event TimeToExpiryAdded(bytes32 indexed productHash, uint256 timeToExpiry);
    /// @notice emits an event when new upper bound value is added for a specific time to expiry timestamp
    event MaxPriceAdded(bytes32 indexed productHash, uint256 timeToExpiry, uint256 value);
    /// @notice emits an event when spot shock value is updated for a specific product
    event SpotShockUpdated(bytes32 indexed product, uint256 spotShock);
    OptionFactoryInterface public optionFactory;
    /**
     * @notice constructor
     * @param _oracle oracle module address
     */
    constructor(address _oracle,address _optionFactory) {
        require(_oracle != address(0), "MarginCalculator: invalid oracle address");

        oracle = OracleInterface(_oracle);
        optionFactory = OptionFactoryInterface(_optionFactory);
    }

    /**
     * @notice set dust amount for collateral asset (1e27)
     * @dev can only be called by owner
     * @param _collateral collateral asset address
     * @param _dust dust amount
     */
    function setCollateralDust(address _collateral, uint256 _dust) external onlyOwner {
        require(_dust > 0, "MarginCalculator: dust amount should be greater than zero");

        dust[_collateral] = _dust;
    }

    /**
     * @notice set product upper bound values
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timesToExpiry array of times to expiry timestamp
     * @param _values upper bound values array
     */
    function setUpperBoundValues(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256[] calldata _timesToExpiry,
        uint256[] calldata _values
    ) external onlyOwner {
        require(_timesToExpiry.length > 0, "MarginCalculator: invalid times to expiry array");
        require(_timesToExpiry.length == _values.length, "MarginCalculator: invalid values array");

        // get product hash
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        uint256[] storage expiryArray = timesToExpiryForProduct[productHash];

        // check that this is the first expiry to set
        // if not, the last expiry should be less than the new one to insert (to make sure the array stay in order)
        require(
            (expiryArray.length == 0) || (_timesToExpiry[0] > expiryArray[expiryArray.length.sub(1)]),
            "MarginCalculator: expiry array is not in order"
        );

        for (uint256 i = 0; i < _timesToExpiry.length; i++) {
            // check that new times array is in order
            if (i.add(1) < _timesToExpiry.length) {
                require(_timesToExpiry[i] < _timesToExpiry[i.add(1)], "MarginCalculator: time should be in order");
            }

            require(_values[i] > 0, "MarginCalculator: no expiry upper bound value found");

            // add new upper bound value for this product at specific time to expiry
            maxPriceAtTimeToExpiry[productHash][_timesToExpiry[i]] = _values[i];

            // add new time to expiry to array
            expiryArray.push(_timesToExpiry[i]);
        }
    }

    /**
     * @notice set option upper bound value for specific time to expiry (1e27)
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @param _value upper bound value
     */
    function updateUpperBoundValue(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry,
        uint256 _value
    ) external onlyOwner {
        require(_value > 0, "MarginCalculator: invalid option upper bound value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        require(
            maxPriceAtTimeToExpiry[productHash][_timeToExpiry] != 0,
            "MarginCalculator: upper bound value not found"
        );

        // update upper bound value for the time to expiry
        maxPriceAtTimeToExpiry[productHash][_timeToExpiry] = _value;
    }

    /**
     * @notice set spot shock value, scaled to 1e27
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _shockValue spot shock value
     */
    function setSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _shockValue
    ) external onlyOwner {
        require(_shockValue > 0, "MarginCalculator: invalid spot shock value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        spotShock[productHash] = _shockValue;
    }

    /**
     * @notice set oracle deviation (1e27)
     * @dev can only be called by owner
     * @param _deviation deviation value
     */
    function setOracleDeviation(uint256 _deviation) external onlyOwner {
        oracleDeviation = _deviation;
    }

    /**
     * @notice get dust amount for collateral asset
     * @param _collateral collateral asset address
     * @return dust amount (1e27)
     */
    function getCollateralDust(address _collateral) external view returns (uint256) {
        return dust[_collateral];
    }

    /**
     * @notice get times to expiry for a specific product
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return array of times to expiry
     */
    function getTimesToExpiry(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256[] memory) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);
        return timesToExpiryForProduct[productHash];
    }

    /**
     * @notice get option upper bound value for specific time to expiry
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @return option upper bound value (1e27)
     */
    function getMaxPrice(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return maxPriceAtTimeToExpiry[productHash][_timeToExpiry];
    }

    /**
     * @notice get spot shock value
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return _shockValue spot shock value (1e27)
     */
    function getSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return spotShock[productHash];
    }

    /**
     * @notice get oracle deviation
     * @return oracle deviation value (1e27)
     */
    function getOracleDeviation() external view returns (uint256) {
        return oracleDeviation;
    }

    /**
     * @notice return the collateral required for naked margin vault, in collateral asset decimals
     * @dev _shortAmount, _strikePrice and _underlyingPrice should be scaled by 1e8
     * @param _underlying underlying asset address
     * @param _strike strike asset address
     * @param _collateral collateral asset address
     * @param _shortAmount amount of short otoken
     * @param  _strikePrice otoken strike price
     * @param _underlyingPrice otoken underlying price
     * @param _shortExpiryTimestamp otoken expiry timestamp
     * @param _collateralDecimals otoken collateral asset decimals
     * @param _isPut otoken type
     * @return collateral required for a naked margin vault, in collateral asset decimals
     */
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        // scale short amount from 1e8 to 1e27 (oToken is always in 1e8)
        FPI.FixedPointInt memory shortAmount = FPI.fromScaledUint(_shortAmount, BASE);
        // scale short strike from 1e8 to 1e27
        FPI.FixedPointInt memory shortStrike = FPI.fromScaledUint(_strikePrice, BASE);
        // scale short underlying price from 1e8 to 1e27
        FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(_underlyingPrice, BASE);

        // return required margin, scaled by collateral asset decimals, explicitly rounded up
        return
            FPI.toScaledUint(
                _getNakedMarginRequired(
                    productHash,
                    shortAmount,
                    shortStrike,
                    shortUnderlyingPrice,
                    _shortExpiryTimestamp,
                    _isPut
                ),
                _collateralDecimals,
                false
            );
    }

    function getPayout(bytes32 optionId, uint256 _amount) public view returns (uint256) {
        uint256 rate = getExpiredPayoutRate(optionId);
        return rate*(_amount)/(10**BASE);
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in collateral
     * @param optionId optionId
     * @return how much collateral can be taken out by 1 otoken unit, scaled by 1e8,
     * or how much collateral can be taken out for 1 (1e8) oToken
     */
    function getExpiredPayoutRate(bytes32 optionId) public view returns (uint256) {
        // require(_otoken != address(0), "MarginCalculator: Invalid token address");

        // OtokenInterface otoken = OtokenInterface(_otoken);
        (
            address underlying,
            address strikeAsset,
            address collateral,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut
        ) = optionFactory.idToOption(optionId);

        // require(block.timestamp >= expiry, "MarginCalculator: Option not expired yet");

        FPI.FixedPointInt memory cashValueInStrike = _getExpiredCashValue(
            underlying,
            strikeAsset,
            expiry,
            strikePrice,
            isPut
        );

        FPI.FixedPointInt memory cashValueInCollateral = _convertAmountOnExpiryPrice(
            cashValueInStrike,
            strikeAsset,
            collateral,
            expiry
        );

        // the exchangeRate was scaled by 1e8, if 1e8 otoken can take out 1 USDC, the exchangeRate is currently 1e8
        // we want to return: how much USDC units can be taken out by 1 (1e8 units) oToken
        uint256 collateralDecimals = uint256(ERC20Interface(collateral).decimals());
        return cashValueInCollateral.toScaledUint(collateralDecimals, true);
    }

    // structs to avoid stack too deep error
    // struct to store shortAmount, shortStrike and shortUnderlyingPrice scaled to 1e27
    struct ShortScaledDetails {
        FPI.FixedPointInt shortAmount;
        FPI.FixedPointInt shortStrike;
        FPI.FixedPointInt shortUnderlyingPrice;
    }

    /**
     * @notice check if a specific vault is undercollateralized at a specific chainlink round
     * @dev if the vault is of type 0, the function will revert
     * @param _vault vault struct
     * @param _vaultType vault type (0 for max loss/spread and 1 for naked margin vault)
     * @param _vaultLatestUpdate vault latest update (timestamp when latest vault state change happened)
     * @param _roundId chainlink round id
     * @return isLiquidatable, true if vault is undercollateralized, liquidation price and collateral dust amount
     */
    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        // liquidation is only supported for naked margin vault
        require(_vaultType == 1, "MarginCalculator: invalid vault type to liquidate");

        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // can not liquidate vault that have no short position
        if (!vaultDetails.hasShort) return (false, 0, 0);

        require(block.timestamp < vaultDetails.shortExpiryTimestamp, "MarginCalculator: can not liquidate expired position");

        (uint256 price, uint256 timestamp) = oracle.getChainlinkRoundData(
            vaultDetails.shortUnderlyingAsset,
            uint80(_roundId)
        );

        // check that price timestamp is after latest timestamp the vault was updated at
        require(
            timestamp > _vaultLatestUpdate,
            "MarginCalculator: auction timestamp should be post vault latest update"
        );

        // another struct to store some useful short otoken details, to avoid stack to deep error
        ShortScaledDetails memory shortDetails = ShortScaledDetails({
            shortAmount: FPI.fromScaledUint(_vault.shortAmounts[0], BASE),
            shortStrike: FPI.fromScaledUint(vaultDetails.shortStrikePrice, BASE),
            shortUnderlyingPrice: FPI.fromScaledUint(price, BASE)
        });

        bytes32 productHash = _getProductHash(
            vaultDetails.shortUnderlyingAsset,
            vaultDetails.shortStrikeAsset,
            vaultDetails.shortCollateralAsset,
            vaultDetails.isShortPut
        );

        // convert vault collateral to a fixed point (1e27) from collateral decimals
        FPI.FixedPointInt memory depositedCollateral = FPI.fromScaledUint(
            _vault.collateralAmounts[0],
            vaultDetails.collateralDecimals
        );

        FPI.FixedPointInt memory collateralRequired = _getNakedMarginRequired(
            productHash,
            shortDetails.shortAmount,
            shortDetails.shortStrike,
            shortDetails.shortUnderlyingPrice,
            vaultDetails.shortExpiryTimestamp,
            vaultDetails.isShortPut
        );

        // if collateral required <= collateral in the vault, the vault is not liquidatable
        if (collateralRequired.isLessThanOrEqual(depositedCollateral)) {
            return (false, 0, 0);
        }

        FPI.FixedPointInt memory cashValue = _getCashValue(
            shortDetails.shortStrike,
            shortDetails.shortUnderlyingPrice,
            vaultDetails.isShortPut
        );

        // get the amount of collateral per 1 repaid otoken
        uint256 debtPrice = _getDebtPrice(
            depositedCollateral,
            shortDetails.shortAmount,
            cashValue,
            shortDetails.shortUnderlyingPrice,
            timestamp,
            vaultDetails.collateralDecimals,
            vaultDetails.isShortPut
        );

        return (true, debtPrice, dust[vaultDetails.shortCollateralAsset]);
    }

    /**
     * @notice calculate required collateral margin for a vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault, scaled to 1e27
     */
    function getMarginRequired(MarginVault.Vault memory _vault, uint256 _vaultType)
        external
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        VaultDetails memory vaultDetail = _getVaultDetails(_vault, _vaultType);
        return _getMarginRequired(_vault, vaultDetail);
    }

    /**
     * @notice returns the amount of collateral that can be removed from an actual or a theoretical vault
     * @dev return amount is denominated in the collateral asset for the oToken in the vault, or the collateral asset in the vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type (0 for spread/max loss, 1 for naked margin)
     * @return excessCollateral the amount by which the margin is above or below the required amount
     * @return isExcess True if there is excess margin in the vault, False if there is a deficit of margin in the vault
     * if True, collateral can be taken out from the vault, if False, additional collateral needs to be added to vault
     */
    function getExcessCollateral(MarginVault.Vault memory _vault, uint256 _vaultType)
        public
        view
        returns (uint256, bool)
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // include all the checks for to ensure the vault is valid
        _checkIsValidVault(_vault, vaultDetails);

        // if the vault contains no oTokens, return the amount of collateral
        if (!vaultDetails.hasShort && !vaultDetails.hasLong) {
            uint256 amount = vaultDetails.hasCollateral ? _vault.collateralAmounts[0] : 0;
            return (amount, true);
        }

        // get required margin, denominated in collateral, scaled in 1e27
        (FPI.FixedPointInt memory collateralAmount, FPI.FixedPointInt memory collateralRequired) = _getMarginRequired(
            _vault,
            vaultDetails
        );
        FPI.FixedPointInt memory excessCollateral = collateralAmount.sub(collateralRequired);

        bool isExcess = excessCollateral.isGreaterThanOrEqual(ZERO);
        uint256 collateralDecimals = vaultDetails.hasLong
            ? vaultDetails.longCollateralDecimals
            : vaultDetails.shortCollateralDecimals;
        // if is excess, truncate the tailing digits in excessCollateralExternal calculation
        uint256 excessCollateralExternal = excessCollateral.toScaledUint(collateralDecimals, isExcess);
        return (excessCollateralExternal, isExcess);
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in strike asset
     * @dev for a call, return Max (0, underlyingPriceInStrike - otoken.strikePrice)
     * @dev for a put, return Max(0, otoken.strikePrice - underlyingPriceInStrike)
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _expiryTimestamp otoken expiry timestamp
     * @param _strikePrice otoken strike price
     * @param _strikePrice true if otoken is put otherwise false
     * @return cash value of an expired otoken, denominated in the strike asset
     */
    function _getExpiredCashValue(
        address _underlying,
        address _strike,
        uint256 _expiryTimestamp,
        uint256 _strikePrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // strike price is denominated in strike asset
        FPI.FixedPointInt memory strikePrice = FPI.fromScaledUint(_strikePrice, BASE);
        FPI.FixedPointInt memory one = FPI.fromScaledUint(1, 0);

        // calculate the value of the underlying asset in terms of the strike asset
        FPI.FixedPointInt memory underlyingPriceInStrike = _convertAmountOnExpiryPrice(
            one, // underlying price is 1 (1e27) in term of underlying
            _underlying,
            _strike,
            _expiryTimestamp
        );

        return _getCashValue(strikePrice, underlyingPriceInStrike, _isPut);
    }

    /// @dev added this struct to avoid stack-too-deep error
    struct OtokenDetails {
        address otokenUnderlyingAsset;
        address otokenCollateralAsset;
        address otokenStrikeAsset;
        uint256 otokenExpiry;
        bool isPut;
    }

    /**
     * @notice calculate the amount of collateral needed for a vault
     * @dev vault passed in has already passed the checkIsValidVault function
     * @param _vault theoretical vault that needs to be checked
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault,
     * scaled to 1e27
     */
    function _getMarginRequired(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        FPI.FixedPointInt memory shortAmount = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vault.shortAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory longAmount = _vaultDetails.hasLong
            ? FPI.fromScaledUint(_vault.longAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory collateralAmount = _vaultDetails.hasCollateral
            ? FPI.fromScaledUint(_vault.collateralAmounts[0], _vaultDetails.collateralDecimals)
            : ZERO;
        FPI.FixedPointInt memory shortStrike = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vaultDetails.shortStrikePrice, BASE)
            : ZERO;

        // struct to avoid stack too deep error
        OtokenDetails memory otokenDetails = OtokenDetails(
            _vaultDetails.hasShort ? _vaultDetails.shortUnderlyingAsset : _vaultDetails.longUnderlyingAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortCollateralAsset : _vaultDetails.longCollateralAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortStrikeAsset : _vaultDetails.longStrikeAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortExpiryTimestamp : _vaultDetails.longExpiryTimestamp,
            _vaultDetails.hasShort ? _vaultDetails.isShortPut : _vaultDetails.isLongPut
        );

        if (block.timestamp < otokenDetails.otokenExpiry) {
            // it's not expired, return amount of margin required based on vault type
            if (_vaultDetails.vaultType == 1) {
                // this is a naked margin vault
                // fetch dust amount for otoken collateral asset as FixedPointInt, assuming dust is already scaled to 1e27
                FPI.FixedPointInt memory dustAmount = FPI.fromScaledUint(
                    dust[_vaultDetails.shortCollateralAsset],
                    _vaultDetails.collateralDecimals
                );

                // check that collateral deposited in naked margin vault is greater than dust amount for that particular collateral asset
                if (collateralAmount.isGreaterThan(ZERO)) {
                    require(
                        collateralAmount.isGreaterThan(dustAmount),
                        "MarginCalculator: naked margin vault should have collateral amount greater than dust amount"
                    );
                }

                // get underlying asset price for short option
                FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(
                    oracle.getPrice(_vaultDetails.shortUnderlyingAsset),
                    BASE
                );

                // encode product hash
                bytes32 productHash = _getProductHash(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortCollateralAsset,
                    _vaultDetails.isShortPut
                );

                // return amount of collateral in vault and needed collateral amount for margin
                return (
                    collateralAmount,
                    _getNakedMarginRequired(
                        productHash,
                        shortAmount,
                        shortStrike,
                        shortUnderlyingPrice,
                        otokenDetails.otokenExpiry,
                        otokenDetails.isPut
                    )
                );
            } else {
                // this is a fully collateralized vault
                FPI.FixedPointInt memory longStrike = _vaultDetails.hasLong
                    ? FPI.fromScaledUint(_vaultDetails.longStrikePrice, BASE)
                    : ZERO;

                if (otokenDetails.isPut) {
                    FPI.FixedPointInt memory strikeNeeded = _getPutSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            strikeNeeded,
                            otokenDetails.otokenStrikeAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                } else {
                    FPI.FixedPointInt memory underlyingNeeded = _getCallSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            underlyingNeeded,
                            otokenDetails.otokenUnderlyingAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                }
            }
        } else {
            // the vault has expired. calculate the cash value of all the minted short options
            FPI.FixedPointInt memory shortCashValue = _vaultDetails.hasShort
                ? _getExpiredCashValue(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortExpiryTimestamp,
                    _vaultDetails.shortStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;
            FPI.FixedPointInt memory longCashValue = _vaultDetails.hasLong
                ? _getExpiredCashValue(
                    _vaultDetails.longUnderlyingAsset,
                    _vaultDetails.longStrikeAsset,
                    _vaultDetails.longExpiryTimestamp,
                    _vaultDetails.longStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;

            FPI.FixedPointInt memory valueInStrike = _getExpiredSpreadCashValue(
                shortAmount,
                longAmount,
                shortCashValue,
                longCashValue
            );

            // convert amount to be denominated in collateral
            return (
                collateralAmount,
                _convertAmountOnExpiryPrice(
                    valueInStrike,
                    otokenDetails.otokenStrikeAsset,
                    otokenDetails.otokenCollateralAsset,
                    otokenDetails.otokenExpiry
                )
            );
        }
    }

    /**
     * @notice get required collateral for naked margin position
     * if put:
     * a = min(strike price, spot shock * underlying price)
     * b = max(strike price - spot shock * underlying price, 0)
     * marginRequired = ( option upper bound value * a + b) * short amount
     * if call:
     * a = min(1, strike price / (underlying price / spot shock value))
     * b = max(1- (strike price / (underlying price / spot shock value)), 0)
     * marginRequired = (option upper bound value * a + b) * short amount
     * @param _productHash product hash
     * @param _shortAmount short amount in vault, in FixedPointInt type
     * @param _strikePrice strike price of short otoken, in FixedPointInt type
     * @param _underlyingPrice underlying price of short otoken underlying asset, in FixedPointInt type
     * @param _shortExpiryTimestamp short otoken expiry timestamp
     * @param _isPut otoken type, true if put option, false for call option
     * @return required margin for this naked vault, in FixedPointInt type (scaled by 1e27)
     */
    function _getNakedMarginRequired(
        bytes32 _productHash,
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // find option upper bound value
        FPI.FixedPointInt memory optionUpperBoundValue = _findUpperBoundValue(_productHash, _shortExpiryTimestamp);
        // convert spot shock value of this product to FixedPointInt (already scaled by 1e27)
        FPI.FixedPointInt memory spotShockValue = FPI.FixedPointInt(int256(spotShock[_productHash]));

        FPI.FixedPointInt memory a;
        FPI.FixedPointInt memory b;
        FPI.FixedPointInt memory marginRequired;

        if (_isPut) {
            a = FPI.min(_strikePrice, spotShockValue.mul(_underlyingPrice));
            b = FPI.max(_strikePrice.sub(spotShockValue.mul(_underlyingPrice)), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        } else {
            FPI.FixedPointInt memory one = FPI.fromScaledUint(1e27, SCALING_FACTOR);
            a = FPI.min(one, _strikePrice.div(_underlyingPrice.div(spotShockValue)));
            b = FPI.max(one.sub(_strikePrice.div(_underlyingPrice.div(spotShockValue))), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        }

        return marginRequired;
    }

    /**
     * @notice find upper bound value for product by specific expiry timestamp
     * @dev should return the upper bound value that correspond to option time to expiry, of if not found should return the next greater one, revert if no value found
     * @param _productHash product hash
     * @param _expiryTimestamp expiry timestamp
     * @return option upper bound value
     */
    function _findUpperBoundValue(bytes32 _productHash, uint256 _expiryTimestamp)
        internal
        view
        returns (FPI.FixedPointInt memory)
    {
        // get time to expiry array of this product hash
        uint256[] memory timesToExpiry = timesToExpiryForProduct[_productHash];

        // check that this product have upper bound values stored
        require(timesToExpiry.length != 0, "MarginCalculator: product have no expiry values");

        uint256 optionTimeToExpiry = _expiryTimestamp.sub(block.timestamp);

        // check that the option time to expiry is in the expiry array
        require(
            timesToExpiry[timesToExpiry.length.sub(1)] >= optionTimeToExpiry,
            "MarginCalculator: product have no upper bound value"
        );

        // loop through the array and return the upper bound value in FixedPointInt type (already scaled by 1e27)
        for (uint8 i = 0; i < timesToExpiry.length; i++) {
            if (timesToExpiry[i] >= optionTimeToExpiry)
                return FPI.fromScaledUint(maxPriceAtTimeToExpiry[_productHash][timesToExpiry[i]], SCALING_FACTOR);
        }
    }

    /**
     * @dev returns the strike asset amount of margin required for a put or put spread with the given short oTokens, long oTokens and amounts
     *
     * marginRequired = max( (short amount * short strike) - (long strike * min (short amount, long amount)) , 0 )
     *
     * @return margin requirement denominated in the strike asset
     */
    function _getPutSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        return FPI.max(_shortAmount.mul(_shortStrike).sub(_longStrike.mul(FPI.min(_shortAmount, _longAmount))), ZERO);
    }

    /**
     * @dev returns the underlying asset amount required for a call or call spread with the given short oTokens, long oTokens, and amounts
     *
     *                           (long strike - short strike) * short amount
     * marginRequired =  max( ------------------------------------------------- , max (short amount - long amount, 0) )
     *                                           long strike
     *
     * @dev if long strike = 0, return max( short amount - long amount, 0)
     * @return margin requirement denominated in the underlying asset
     */
    function _getCallSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        // max (short amount - long amount , 0)
        if (_longStrike.isEqual(ZERO)) {
            return FPI.max(_shortAmount.sub(_longAmount), ZERO);
        }

        /**
         *             (long strike - short strike) * short amount
         * calculate  ----------------------------------------------
         *                             long strike
         */
        FPI.FixedPointInt memory firstPart = _longStrike.sub(_shortStrike).mul(_shortAmount).div(_longStrike);

        /**
         * calculate max ( short amount - long amount , 0)
         */
        FPI.FixedPointInt memory secondPart = FPI.max(_shortAmount.sub(_longAmount), ZERO);

        return FPI.max(firstPart, secondPart);
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on a live price
     * @dev function includes the amount and applies .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on an expiry price
     * @dev function includes the amount and apply .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnExpiryPrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB,
        uint256 _expiry
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        (uint256 priceA, bool priceAFinalized) = oracle.getExpiryPrice(_assetA, _expiry);
        (uint256 priceB, bool priceBFinalized) = oracle.getExpiryPrice(_assetB, _expiry);
        require(priceAFinalized && priceBFinalized, "MarginCalculator: price at expiry not finalized yet");
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice return debt price, how much collateral asset per 1 otoken repaid in collateral decimal
     * ending price = vault collateral / vault debt
     * if auction ended, return ending price
     * else calculate starting price
     * for put option:
     * starting price = max(cash value - underlying price * oracle deviation, 0)
     * for call option:
     *                      max(cash value - underlying price * oracle deviation, 0)
     * starting price =  ---------------------------------------------------------------
     *                                          underlying price
     *
     *
     *                  starting price + (ending price - starting price) * auction elapsed time
     * then price = --------------------------------------------------------------------------
     *                                      auction time
     *
     *
     * @param _vaultCollateral vault collateral amount
     * @param _vaultDebt vault short amount
     * @param _cashValue option cash value
     * @param _spotPrice option underlying asset price (in USDC)
     * @param _auctionStartingTime auction starting timestamp (_spotPrice timestamp from chainlink)
     * @param _collateralDecimals collateral asset decimals
     * @param _isPut otoken type, true for put, false for call option
     * @return price of 1 debt otoken in collateral asset scaled by collateral decimals
     */
    function _getDebtPrice(
        FPI.FixedPointInt memory _vaultCollateral,
        FPI.FixedPointInt memory _vaultDebt,
        FPI.FixedPointInt memory _cashValue,
        FPI.FixedPointInt memory _spotPrice,
        uint256 _auctionStartingTime,
        uint256 _collateralDecimals,
        bool _isPut
    ) internal view returns (uint256) {
        // price of 1 repaid otoken in collateral asset, scaled to 1e27
        FPI.FixedPointInt memory price;
        // auction ending price
        FPI.FixedPointInt memory endingPrice = _vaultCollateral.div(_vaultDebt);

        // auction elapsed time
        uint256 auctionElapsedTime = block.timestamp.sub(_auctionStartingTime);

        // if auction ended, return ending price
        if (auctionElapsedTime >= AUCTION_TIME) {
            price = endingPrice;
        } else {
            // starting price
            FPI.FixedPointInt memory startingPrice;

            {
                // store oracle deviation in a FixedPointInt (already scaled by 1e27)
                FPI.FixedPointInt memory fixedOracleDeviation = FPI.fromScaledUint(oracleDeviation, SCALING_FACTOR);

                if (_isPut) {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO);
                } else {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO).div(_spotPrice);
                }
            }

            // store auctionElapsedTime in a FixedPointInt scaled by 1e27
            FPI.FixedPointInt memory auctionElapsedTimeFixedPoint = FPI.fromScaledUint(auctionElapsedTime, 18);
            // store AUCTION_TIME in a FixedPointInt (already scaled by 1e27)
            FPI.FixedPointInt memory auctionTime = FPI.fromScaledUint(AUCTION_TIME, 18);

            // calculate price of 1 repaid otoken, scaled by the collateral decimals, expilictly rounded down
            price = startingPrice.add(
                (endingPrice.sub(startingPrice)).mul(auctionElapsedTimeFixedPoint).div(auctionTime)
            );

            // cap liquidation price to ending price
            if (price.isGreaterThan(endingPrice)) price = endingPrice;
        }

        return price.toScaledUint(_collateralDecimals, true);
    }

    /**
     * @notice get vault details to save us from making multiple external calls
     * @param _vault vault struct
     * @param _vaultType vault type, 0 for max loss/spreads and 1 for naked margin vault
     * @return vault details in VaultDetails struct
     */
    function _getVaultDetails(MarginVault.Vault memory _vault, uint256 _vaultType)
        internal
        view
        returns (VaultDetails memory)
    {
        VaultDetails memory vaultDetails = VaultDetails(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            false,
            false
        );

        // check if vault has long, short otoken and collateral asset
        vaultDetails.hasLong = _isNotEmpty(_vault.longOtokens);
        vaultDetails.hasShort = _isNotEmpty(_vault.shortOtokens);
        vaultDetails.hasCollateral = _isNotEmpty(_vault.collateralAssets);

        vaultDetails.vaultType = _vaultType;

        // get vault long otoken if available
        if (vaultDetails.hasLong) {
            OtokenInterface long = OtokenInterface(_vault.longOtokens[0]);
            (
                vaultDetails.longCollateralAsset,
                vaultDetails.longUnderlyingAsset,
                vaultDetails.longStrikeAsset,
                vaultDetails.longStrikePrice,
                vaultDetails.longExpiryTimestamp,
                vaultDetails.isLongPut
            ) = long.getOtokenDetails();
            vaultDetails.longCollateralDecimals = uint256(ERC20Interface(vaultDetails.longCollateralAsset).decimals());
        }

        // get vault short otoken if available
        if (vaultDetails.hasShort) {
            OtokenInterface short = OtokenInterface(_vault.shortOtokens[0]);
            (
                vaultDetails.shortCollateralAsset,
                vaultDetails.shortUnderlyingAsset,
                vaultDetails.shortStrikeAsset,
                vaultDetails.shortStrikePrice,
                vaultDetails.shortExpiryTimestamp,
                vaultDetails.isShortPut
            ) = short.getOtokenDetails();
            vaultDetails.shortCollateralDecimals = uint256(
                ERC20Interface(vaultDetails.shortCollateralAsset).decimals()
            );
        }

        if (vaultDetails.hasCollateral) {
            vaultDetails.collateralDecimals = uint256(ERC20Interface(_vault.collateralAssets[0]).decimals());
        }

        return vaultDetails;
    }

    /**
     * @dev calculate the cash value obligation for an expired vault, where a positive number is an obligation
     *
     * Formula: net = (short cash value * short amount) - ( long cash value * long Amount )
     *
     * @return cash value obligation denominated in the strike asset
     */
    function _getExpiredSpreadCashValue(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortCashValue,
        FPI.FixedPointInt memory _longCashValue
    ) internal pure returns (FPI.FixedPointInt memory) {
        return _shortCashValue.mul(_shortAmount).sub(_longCashValue.mul(_longAmount));
    }

    /**
     * @dev check if asset array contain a token address
     * @return True if the array is not empty
     */
    function _isNotEmpty(address[] memory _assets) internal pure returns (bool) {
        return _assets.length > 0 && _assets[0] != address(0);
    }

    /**
     * @dev ensure that:
     * a) at most 1 asset type used as collateral
     * b) at most 1 series of option used as the long option
     * c) at most 1 series of option used as the short option
     * d) asset array lengths match for long, short and collateral
     * e) long option and collateral asset is acceptable for margin with short asset
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     */
    function _checkIsValidVault(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails) internal pure {
        // ensure all the arrays in the vault are valid
        require(_vault.shortOtokens.length <= 1, "MarginCalculator: Too many short otokens in the vault");
        require(_vault.longOtokens.length <= 1, "MarginCalculator: Too many long otokens in the vault");
        require(_vault.collateralAssets.length <= 1, "MarginCalculator: Too many collateral assets in the vault");

        require(
            _vault.shortOtokens.length == _vault.shortAmounts.length,
            "MarginCalculator: Short asset and amount mismatch"
        );
        require(
            _vault.longOtokens.length == _vault.longAmounts.length,
            "MarginCalculator: Long asset and amount mismatch"
        );
        require(
            _vault.collateralAssets.length == _vault.collateralAmounts.length,
            "MarginCalculator: Collateral asset and amount mismatch"
        );

        // ensure the long asset is valid for the short asset
        require(
            _isMarginableLong(_vault, _vaultDetails),
            "MarginCalculator: long asset not marginable for short asset"
        );

        // ensure that the collateral asset is valid for the short asset
        require(
            _isMarginableCollateral(_vault, _vaultDetails),
            "MarginCalculator: collateral asset not marginable for short asset"
        );
    }

    /**
     * @dev if there is a short option and a long option in the vault, ensure that the long option is able to be used as collateral for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if long is marginable or false if not
     */
    function _isMarginableLong(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        if (_vaultDetails.vaultType == 1)
            require(!_vaultDetails.hasLong, "MarginCalculator: naked margin vault cannot have long otoken");

        // if vault is missing a long or a short, return True
        if (!_vaultDetails.hasLong || !_vaultDetails.hasShort) return true;

        return
            _vault.longOtokens[0] != _vault.shortOtokens[0] &&
            _vaultDetails.longUnderlyingAsset == _vaultDetails.shortUnderlyingAsset &&
            _vaultDetails.longStrikeAsset == _vaultDetails.shortStrikeAsset &&
            _vaultDetails.longCollateralAsset == _vaultDetails.shortCollateralAsset &&
            _vaultDetails.longExpiryTimestamp == _vaultDetails.shortExpiryTimestamp &&
            _vaultDetails.isLongPut == _vaultDetails.isShortPut;
    }

    /**
     * @dev if there is short option and collateral asset in the vault, ensure that the collateral asset is valid for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if marginable or false
     */
    function _isMarginableCollateral(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        bool isMarginable = true;

        if (!_vaultDetails.hasCollateral) return isMarginable;

        if (_vaultDetails.hasShort) {
            isMarginable = _vaultDetails.shortCollateralAsset == _vault.collateralAssets[0];
        } else if (_vaultDetails.hasLong) {
            isMarginable = _vaultDetails.longCollateralAsset == _vault.collateralAssets[0];
        }

        return isMarginable;
    }

    /**
     * @notice get a product hash
     * @param _underlying option underlying asset
     * @param _strike option strike asset
     * @param _collateral option collateral asset
     * @param _isPut option type
     * @return product hash
     */
    function _getProductHash(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));
    }

    /**
     * @notice get option cash value
     * @dev this assume that the underlying price is denominated in strike asset
     * cash value = max(underlying price - strike price, 0)
     * @param _strikePrice option strike price
     * @param _underlyingPrice option underlying price
     * @param _isPut option type, true for put and false for call option
     */
    function _getCashValue(
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_isPut) return _strikePrice.isGreaterThan(_underlyingPrice) ? _strikePrice.sub(_underlyingPrice) : ZERO;

        return _underlyingPrice.isGreaterThan(_strikePrice) ? _underlyingPrice.sub(_strikePrice) : ZERO;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
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

    function decimals() external view returns (uint8);

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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

import "../libs/SignedConverter.sol";
import  "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title FixedPointInt256
 * @author Opyn Team
 * @notice FixedPoint library
 */
library FixedPointInt256 {
    using SignedSafeMath for int256;
    using SignedConverter for int256;
    using SafeMath for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 8.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.08 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

/**
 * @title SignedConverter
 * @author Opyn Team
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author MilkTeam
 * @title MockERC20
 */

contract MockERC20 is ERC20 {

    uint8  private decimal;
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) public {
        decimal = _decimals;
    }

    function decimals() public view override returns (uint8){
        return decimal;
    }
    function mint(address account,uint256 amount) public{
        _mint(account, amount);
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MarginPool is Ownable{
    // using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice AddressBook module
    address public addressBook;
    /// @dev the address that has the ability to withdraw excess assets in the pool
    address public farmer;
    /// @dev mapping between an asset and the amount of the asset in the pool
    mapping(address => uint256) internal assetBalance;

    /**
     * @notice contructor
     * @param _addressBook AddressBook module
     */
    constructor(address _addressBook) {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event when marginpool receive funds from controller
    event TransferToPool(address indexed asset, address indexed user, uint256 amount);
    /// @notice emits an event when marginpool transfer funds to controller
    event TransferToUser(address indexed asset, address indexed user, uint256 amount);
    /// @notice emit event after updating the farmer address
    event FarmerUpdated(address indexed oldAddress, address indexed newAddress);
    /// @notice emit event when an asset gets harvested from the pool
    event AssetFarmed(address indexed asset, address indexed receiver, uint256 amount);

    /**
     * @notice check if the sender is the Controller module
     */
    modifier onlyControllerOrAssetManagement() {
        require(
            msg.sender == AddressBookInterface(addressBook).getController()
            || msg.sender == AddressBookInterface(addressBook).getAssetManagement(),
            "MarginPool: Sender is not Controller or AssetManagement"
        );

        _;
    }

    /**
     * @notice check if the sender is the farmer address
     */
    modifier onlyFarmer() {
        require(msg.sender == farmer, "MarginPool: Sender is not farmer");

        _;
    }

    /**
     * @notice transfers an asset from a user to the pool
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets from
     * @param _amount amount of the token to transfer from _user
     */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) public onlyControllerOrAssetManagement {
        require(_amount > 0, "MarginPool: transferToPool amount is equal to 0");
        assetBalance[_asset] = assetBalance[_asset]+(_amount);

        // transfer _asset _amount from _user to pool
        IERC20(_asset).safeTransferFrom(_user, address(this), _amount);
        emit TransferToPool(_asset, _user, _amount);
    }

    /**
     * @notice transfers an asset from the pool to a user
     * @param _asset address of the asset to transfer
     * @param _user address of the user to transfer assets to
     * @param _amount amount of the token to transfer to _user
     */
    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) public onlyControllerOrAssetManagement {
        require(_user != address(this), "MarginPool: cannot transfer assets to oneself");
        assetBalance[_asset] = assetBalance[_asset]-(_amount);

        // transfer _asset _amount from pool to _user
        IERC20(_asset).safeTransfer(_user, _amount);
        emit TransferToUser(_asset, _user, _amount);
    }

    /**
     * @notice get the stored balance of an asset
     * @param _asset asset address
     * @return asset balance
     */
    function getStoredBalance(address _asset) external view returns (uint256) {
        return assetBalance[_asset];
    }

    /**
     * @notice transfers multiple assets from users to the pool
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to pool
     */
    function batchTransferToPool(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external onlyControllerOrAssetManagement {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToPool array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from _user to pool
            transferToPool(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice transfers multiple assets from the pool to users
     * @param _asset addresses of the assets to transfer
     * @param _user addresses of the users to transfer assets to
     * @param _amount amount of each token to transfer to _user
     */
    function batchTransferToUser(
        address[] memory _asset,
        address[] memory _user,
        uint256[] memory _amount
    ) external onlyControllerOrAssetManagement {
        require(
            _asset.length == _user.length && _user.length == _amount.length,
            "MarginPool: batchTransferToUser array lengths are not equal"
        );

        for (uint256 i = 0; i < _asset.length; i++) {
            // transfer _asset _amount from pool to _user
            transferToUser(_asset[i], _user[i], _amount[i]);
        }
    }

    /**
     * @notice function to collect the excess balance of a particular asset
     * @dev can only be called by the farmer address. Do not farm otokens.
     * @param _asset asset address
     * @param _receiver receiver address
     * @param _amount amount to remove from pool
     */
    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external onlyFarmer {
        require(_receiver != address(0), "MarginPool: invalid receiver address");

        uint256 externalBalance = IERC20(_asset).balanceOf(address(this));
        uint256 storedBalance = assetBalance[_asset];

        require(_amount <= externalBalance-(storedBalance), "MarginPool: amount to farm exceeds limit");
        // todo
        IERC20(_asset).safeTransfer(_receiver, _amount);

        emit AssetFarmed(_asset, _receiver, _amount);
    }

    /**
     * @notice function to set farmer address
     * @dev can only be called by MarginPool owner
     * @param _farmer farmer address
     */
    function setFarmer(address _farmer) external onlyOwner {
        emit FarmerUpdated(farmer, _farmer);

        farmer = _farmer;
    }
}

pragma solidity =0.8.4;


import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {WhitelistInterface} from "../interfaces/WhitelistInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @title A factory to create Opyn oTokens
 * @author Milk Team 
 * @notice Create new oTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for oToken logic contract
 */
contract OptionFactory {
    // using SafeMath for uint256;
    /// @notice Opyn AddressBook contract that records the address of the Whitelist module and the Otoken impl address. */
    address public addressBook;

    /// @notice array of all created otokens */
    bytes32[] public options;


    mapping(bytes32 => Option) public idToOption;
    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    struct Option{
        address underlying;
        address strikeAsset;
        address collateral;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    constructor(address _addressBook){
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event OptionCreated(
        bytes32 optionId,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    /**
     * @notice create new option
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newOtoken address of the newly created option
     */

    function createOption(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (bytes32) {
        require(_expiry > block.timestamp, "OptionFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "OptionFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        // require(_expiry.sub(28800).mod(86400) == 0, "OptionFactory: Option has to expire 08:00 UTC");
        bytes32 id = getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        require(idToOption[id].collateral == address(0), "OptionFactory: Option already created");
    
        Option memory option = Option(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        

        address whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAsset,
                _isPut
            ),
            "OptionFactory: Unsupported Product"
        );

        require(!_isPut || _strikePrice > 0, "OptionFactory: Can't create a $0 strike put option");

    
        idToOption[id] = option;
        options.push(id);

        WhitelistInterface(whitelist).whitelistOption(id);

        emit OptionCreated(
            id,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        return id;
    }

    /**
     * @notice get the total oTokens created by the factory
     * @return length of the oTokens array
     */
    function getOptionsLength() external view returns (uint256) {
        return options.length;
    }

  

    /**
     * @dev hash oToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an oToken
     */
    function getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOption(address _option) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOption(bytes32 _option) external;

    function blacklistOption(bytes32 _option) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface AssetManagementInterface {
    function moveAsset( 
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount
    ) external;
}

contract MockExchange {
    function moveAsset( 
        uint256 _fromAccountId,
        uint256 _toAccountId,
        address _asset,
        uint256 _amount,
        address assetManagementAdr
    ) public{
        AssetManagementInterface(assetManagementAdr).moveAsset(_fromAccountId, _toAccountId, _asset, _amount);
    } 
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.8.4;

import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @author Opyn Team
 * @title Oracle Module
 * @notice The Oracle module sets, retrieves, and stores USD prices (USD per asset) for underlying, collateral, and strike assets
 * manages pricers that are used for different assets
 */
contract Oracle is Ownable {
    // using SafeMath for uint256;

    /// @dev structure that stores price of asset and timestamp when the price was stored
    struct Price {
        uint256 price;
        uint256 timestamp; // timestamp at which the price is pushed to this oracle
    }

    /// @dev mapping of asset pricer to its locking period
    /// locking period is the period of time after the expiry timestamp where a price can not be pushed
    mapping(address => uint256) internal pricerLockingPeriod;
    /// @dev mapping of asset pricer to its dispute period
    /// dispute period is the period of time after an expiry price has been pushed where a price can be disputed
    mapping(address => uint256) internal pricerDisputePeriod;
    /// @dev mapping between an asset and its pricer
    mapping(address => address) internal assetPricer;
    /// @dev mapping between asset, expiry timestamp, and the Price structure at the expiry timestamp
    mapping(address => mapping(uint256 => Price)) internal storedPrice;
    /// @dev mapping between stable asset and price
    mapping(address => uint256) internal stablePrice;
    //// @dev disputer is a role defined by the owner that has the ability to dispute a price during the dispute period
    address internal disputer;

    /// @notice emits an event when the disputer is updated
    event DisputerUpdated(address indexed newDisputer);
    /// @notice emits an event when the pricer is updated for an asset
    event PricerUpdated(address indexed asset, address indexed pricer);
    /// @notice emits an event when the locking period is updated for a pricer
    event PricerLockingPeriodUpdated(address indexed pricer, uint256 lockingPeriod);
    /// @notice emits an event when the dispute period is updated for a pricer
    event PricerDisputePeriodUpdated(address indexed pricer, uint256 disputePeriod);
    /// @notice emits an event when an expiry price is updated for a specific asset
    event ExpiryPriceUpdated(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 price,
        uint256 onchainTimestamp
    );
    /// @notice emits an event when the disputer disputes a price during the dispute period
    event ExpiryPriceDisputed(
        address indexed asset,
        uint256 indexed expiryTimestamp,
        uint256 disputedPrice,
        uint256 newPrice,
        uint256 disputeTimestamp
    );
    /// @notice emits an event when a stable asset price changes
    event StablePriceUpdated(address indexed asset, uint256 price);

    /**
     * @notice sets the pricer for an asset
     * @dev can only be called by the owner
     * @param _asset asset address
     * @param _pricer pricer address
     */
    function setAssetPricer(address _asset, address _pricer) external onlyOwner {
        require(_pricer != address(0), "Oracle: cannot set pricer to address(0)");
        require(stablePrice[_asset] == 0, "Oracle: could not set a pricer for stable asset");

        assetPricer[_asset] = _pricer;

        emit PricerUpdated(_asset, _pricer);
    }

    /**
     * @notice sets the locking period for a pricer
     * @dev can only be called by the owner
     * @param _pricer pricer address
     * @param _lockingPeriod locking period
     */
    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external onlyOwner {
        pricerLockingPeriod[_pricer] = _lockingPeriod;

        emit PricerLockingPeriodUpdated(_pricer, _lockingPeriod);
    }

    /**
     * @notice sets the dispute period for a pricer
     * @dev can only be called by the owner
     * for a composite pricer (ie CompoundPricer) that depends on or calls other pricers, ensure
     * that the dispute period for the composite pricer is longer than the dispute period for the
     * asset pricer that it calls to ensure safe usage as a dispute in the other pricer will cause
     * the need for a dispute with the composite pricer's price
     * @param _pricer pricer address
     * @param _disputePeriod dispute period
     */
    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external onlyOwner {
        pricerDisputePeriod[_pricer] = _disputePeriod;

        emit PricerDisputePeriodUpdated(_pricer, _disputePeriod);
    }

    /**
     * @notice set the disputer address
     * @dev can only be called by the owner
     * @param _disputer disputer address
     */
    function setDisputer(address _disputer) external onlyOwner {
        disputer = _disputer;

        emit DisputerUpdated(_disputer);
    }

    /**
     * @notice set stable asset price
     * @dev price should be scaled by 1e8
     * @param _asset asset address
     * @param _price price
     */
    function setStablePrice(address _asset, uint256 _price) external onlyOwner {
        require(assetPricer[_asset] == address(0), "Oracle: could not set stable price for an asset with pricer");

        stablePrice[_asset] = _price;

        emit StablePriceUpdated(_asset, _price);
    }

    /**
     * @notice dispute an asset price during the dispute period
     * @dev only the disputer can dispute a price during the dispute period, by setting a new one
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @param _price the correct price
     */
    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external {
        require(msg.sender == disputer, "Oracle: caller is not the disputer");
        require(!isDisputePeriodOver(_asset, _expiryTimestamp), "Oracle: dispute period over");

        Price storage priceToUpdate = storedPrice[_asset][_expiryTimestamp];

        require(priceToUpdate.timestamp != 0, "Oracle: price to dispute does not exist");

        uint256 oldPrice = priceToUpdate.price;
        priceToUpdate.price = _price;

        emit ExpiryPriceDisputed(_asset, _expiryTimestamp, oldPrice, _price, block.timestamp);
    }

    /**
     * @notice submits the expiry price to the oracle, can only be set from the pricer
     * @dev asset price can only be set after the locking period is over and before the dispute period has started
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @param _price asset price at expiry
     */
    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external {
        require(msg.sender == assetPricer[_asset], "Oracle: caller is not authorized to set expiry price");
        require(isLockingPeriodOver(_asset, _expiryTimestamp), "Oracle: locking period is not over yet");
        require(storedPrice[_asset][_expiryTimestamp].timestamp == 0, "Oracle: dispute period started");

        storedPrice[_asset][_expiryTimestamp] = Price(_price, block.timestamp);
        emit ExpiryPriceUpdated(_asset, _expiryTimestamp, _price, block.timestamp);
    }

    /**
     * @notice get a live asset price from the asset's pricer contract
     * @param _asset asset address
     * @return price scaled by 1e8, denominated in USD
     * e.g. 17568900000 => 175.689 USD
     */
    function getPrice(address _asset) external view returns (uint256) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            require(assetPricer[_asset] != address(0), "Oracle: Pricer for this asset not set");

            price = OpynPricerInterface(assetPricer[_asset]).getPrice();
        }

        return price;
    }

    /**
     * @notice get the asset price at specific expiry timestamp
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return price scaled by 1e8, denominated in USD
     * @return isFinalized True, if the price is finalized, False if not
     */
    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool) {
        uint256 price = stablePrice[_asset];
        bool isFinalized = true;

        if (price == 0) {
            price = storedPrice[_asset][_expiryTimestamp].price;
            isFinalized = isDisputePeriodOver(_asset, _expiryTimestamp);
        }

        return (price, isFinalized);
    }

    /**
     * @notice get the pricer for an asset
     * @param _asset asset address
     * @return pricer address
     */
    function getPricer(address _asset) external view returns (address) {
        return assetPricer[_asset];
    }

    /**
     * @notice get the disputer address
     * @return disputer address
     */
    function getDisputer() external view returns (address) {
        return disputer;
    }

    /**
     * @notice get a pricer's locking period
     * locking period is the period of time after the expiry timestamp where a price can not be pushed
     * @dev during the locking period an expiry price can not be submitted to this contract
     * @param _pricer pricer address
     * @return locking period
     */
    function getPricerLockingPeriod(address _pricer) external view returns (uint256) {
        return pricerLockingPeriod[_pricer];
    }

    /**
     * @notice get a pricer's dispute period
     * dispute period is the period of time after an expiry price has been pushed where a price can be disputed
     * @dev during the dispute period, the disputer can dispute the submitted price and modify it
     * @param _pricer pricer address
     * @return dispute period
     */
    function getPricerDisputePeriod(address _pricer) external view returns (uint256) {
        return pricerDisputePeriod[_pricer];
    }

    /**
     * @notice get historical asset price and timestamp
     * @dev if asset is a stable asset, will return stored price and timestamp equal to block.timestamp
     * @param _asset asset address to get it's historical price
     * @param _roundId chainlink round id
     * @return price and round timestamp
     */
    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256) {
        uint256 price = stablePrice[_asset];
        uint256 timestamp = block.timestamp;

        if (price == 0) {
            require(assetPricer[_asset] != address(0), "Oracle: Pricer for this asset not set");

            (price, timestamp) = OpynPricerInterface(assetPricer[_asset]).getHistoricalPrice(_roundId);
        }

        return (price, timestamp);
    }

    /**
     * @notice check if the locking period is over for setting the asset price at a particular expiry timestamp
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return True if locking period is over, False if not
     */
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) public view returns (bool) {
        uint256 price = stablePrice[_asset];

        if (price == 0) {
            address pricer = assetPricer[_asset];
            uint256 lockingPeriod = pricerLockingPeriod[pricer];

            return block.timestamp > _expiryTimestamp+lockingPeriod;
        }

        return true;
    }

    /**
     * @notice check if the dispute period is over
     * @param _asset asset address
     * @param _expiryTimestamp expiry timestamp
     * @return True if dispute period is over, False if not
     */
    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) public view returns (bool) {
        uint256 priceUint = stablePrice[_asset];

        if (priceUint == 0) {
            // check if the pricer has a price for this expiry timestamp
            Price memory price = storedPrice[_asset][_expiryTimestamp];
            if (price.timestamp == 0) {
                return false;
            }

            address pricer = assetPricer[_asset];
            uint256 disputePeriod = pricerDisputePeriod[pricer];

            return block.timestamp > price.timestamp+disputePeriod;
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(uint80 _roundId) external view returns (uint256, uint256);
}