pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/Interfaces/Medianizer.sol";
import "../common/BaseWithStorage/Admin.sol";
import "../Catalyst/ERC20GroupCatalyst.sol";
import "../Catalyst/ERC20GroupGem.sol";
import "./PurchaseValidator.sol";


/// @title StarterPack contract that supports SAND, DAI and ETH as payment
/// @notice This contract manages the purchase and distribution of StarterPacks (bundles of Catalysts and Gems)
contract StarterPackV1 is Admin, MetaTransactionReceiver, PurchaseValidator {
    using SafeMathWithRequire for uint256;
    uint256 internal constant DAI_PRICE = 44000000000000000;
    uint256 private constant DECIMAL_PLACES = 1 ether;

    ERC20 internal immutable _sand;
    Medianizer private immutable _medianizer;
    ERC20 private immutable _dai;
    ERC20Group internal immutable _erc20GroupCatalyst;
    ERC20Group internal immutable _erc20GroupGem;

    bool _sandEnabled;
    bool _etherEnabled;
    bool _daiEnabled;

    uint256[] private _starterPackPrices;
    uint256[] private _previousStarterPackPrices;
    uint256 private _gemPrice;
    uint256 private _previousGemPrice;

    // The timestamp of the last pricechange
    uint256 private _priceChangeTimestamp;

    address payable internal _wallet;

    // The delay between calling setPrices() and when the new prices come into effect.
    // Minimizes the effect of price changes on pending TXs
    uint256 private constant PRICE_CHANGE_DELAY = 1 hours;

    event Purchase(address indexed buyer, Message message, uint256 price, address token, uint256 amountPaid);

    event SetPrices(uint256[] prices, uint256 gemPrice);

    struct Message {
        uint256[] catalystIds;
        uint256[] catalystQuantities;
        uint256[] gemIds;
        uint256[] gemQuantities;
        uint256 nonce;
    }

    // ////////////////////////// Functions ////////////////////////

    /// @notice Set the wallet receiving the proceeds
    /// @param newWallet Address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "WALLET_ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    /// @notice Enable / disable DAI payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setDAIEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _daiEnabled = enabled;
    }

    /// @notice Return whether DAI payments are enabled
    /// @return Whether DAI payments are enabled
    function isDAIEnabled() external view returns (bool) {
        return _daiEnabled;
    }

    /// @notice Enable / disable ETH payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setETHEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _etherEnabled = enabled;
    }

    /// @notice Return whether ETH payments are enabled
    /// @return Whether ETH payments are enabled
    function isETHEnabled() external view returns (bool) {
        return _etherEnabled;
    }

    /// @dev Enable / disable the specific SAND payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setSANDEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _sandEnabled = enabled;
    }

    /// @notice Return whether SAND payments are enabled
    /// @return Whether SAND payments are enabled
    function isSANDEnabled() external view returns (bool) {
        return _sandEnabled;
    }

    /// @notice Purchase StarterPacks with SAND
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details

    function purchaseWithSand(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_sandEnabled, "SAND_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        _handlePurchaseWithERC20(buyer, _wallet, address(_sand), amountInSand);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_sand), amountInSand);
    }

    /// @notice Purchase StarterPacks with Ether
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithETH(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external payable {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_etherEnabled, "ETHER_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 ETHRequired = getEtherAmountWithSAND(amountInSand);
        require(msg.value >= ETHRequired, "NOT_ENOUGH_ETHER_SENT");

        _wallet.transfer(ETHRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(0), ETHRequired);

        if (msg.value - ETHRequired > 0) {
            // refund extra
            (bool success, ) = msg.sender.call{value: msg.value - ETHRequired}("");
            require(success, "REFUND_FAILED");
        }
    }

    /// @notice Purchase StarterPacks with DAI
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithDAI(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_daiEnabled, "DAI_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 DAIRequired = amountInSand.mul(DAI_PRICE).div(DECIMAL_PLACES);
        _handlePurchaseWithERC20(buyer, _wallet, address(_dai), DAIRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_dai), DAIRequired);
    }

    /// @notice Enables admin to withdraw all remaining tokens
    /// @param to The destination address for the purchased Catalysts and Gems
    /// @param catalystIds The IDs of the catalysts to be transferred
    /// @param gemIds The IDs of the gems to be transferred
    function withdrawAll(
        address to,
        uint256[] calldata catalystIds,
        uint256[] calldata gemIds
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");

        address[] memory catalystAddresses = new address[](catalystIds.length);
        for (uint256 i = 0; i < catalystIds.length; i++) {
            catalystAddresses[i] = address(this);
        }
        address[] memory gemAddresses = new address[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            gemAddresses[i] = address(this);
        }
        uint256[] memory unsoldCatalystQuantities = _erc20GroupCatalyst.balanceOfBatch(catalystAddresses, catalystIds);
        uint256[] memory unsoldGemQuantities = _erc20GroupGem.balanceOfBatch(gemAddresses, gemIds);

        _erc20GroupCatalyst.batchTransferFrom(address(this), to, catalystIds, unsoldCatalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), to, gemIds, unsoldGemQuantities);
    }

    /// @notice Enables admin to change the prices of the StarterPack bundles
    /// @param prices Array of new prices that will take effect after a delay period
    /// @param gemPrice New price for gems that will take effect after a delay period

    function setPrices(uint256[] calldata prices, uint256 gemPrice) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _previousStarterPackPrices = _starterPackPrices;
        _starterPackPrices = prices;
        _previousGemPrice = _gemPrice;
        _gemPrice = gemPrice;
        _priceChangeTimestamp = now;
        emit SetPrices(prices, gemPrice);
    }

    /// @notice Get current StarterPack prices
    /// @return pricesBeforeSwitch Array of prices before price change
    /// @return pricesAfterSwitch Array of prices after price change
    /// @return gemPriceBeforeSwitch Gem price before price change
    /// @return gemPriceAfterSwitch Gem price after price change
    /// @return switchTime The time the latest price change will take effect, being the time of the price change plus the price change delay

    function getPrices()
        external
        view
        returns (
            uint256[] memory pricesBeforeSwitch,
            uint256[] memory pricesAfterSwitch,
            uint256 gemPriceBeforeSwitch,
            uint256 gemPriceAfterSwitch,
            uint256 switchTime
        )
    {
        switchTime = 0;
        if (_priceChangeTimestamp != 0) {
            switchTime = _priceChangeTimestamp + PRICE_CHANGE_DELAY;
        }
        return (_previousStarterPackPrices, _starterPackPrices, _previousGemPrice, _gemPrice, switchTime);
    }

    /// @notice Returns the amount of ETH for a specific amount of SAND
    /// @param sandAmount An amount of SAND
    /// @return The amount of ETH
    function getEtherAmountWithSAND(uint256 sandAmount) public view returns (uint256) {
        uint256 ethUsdPair = _getEthUsdPair();
        return sandAmount.mul(DAI_PRICE).div(ethUsdPair);
    }

    // ////////////////////////// Internal ////////////////////////

    /// @dev Gets the ETHUSD pair from the Medianizer contract
    /// @return The pair as an uint256
    function _getEthUsdPair() internal view returns (uint256) {
        bytes32 pair = _medianizer.read();
        return uint256(pair);
    }

    /// @dev Function to calculate the total price in SAND of the StarterPacks to be purchased
    /// @dev The price of each StarterPack relates to the catalystId
    /// @param catalystIds Array of catalystIds to be purchase
    /// @param catalystQuantities Array of quantities of those catalystIds to be purchased
    /// @return Total price in SAND
    function _calculateTotalPriceInSand(
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemQuantities
    ) internal returns (uint256) {
        require(catalystIds.length == catalystQuantities.length, "INVALID_INPUT");
        (uint256[] memory prices, uint256 gemPrice) = _priceSelector();
        uint256 totalPrice;
        for (uint256 i = 0; i < catalystIds.length; i++) {
            uint256 id = catalystIds[i];
            uint256 quantity = catalystQuantities[i];
            totalPrice = totalPrice.add(prices[id].mul(quantity));
        }
        for (uint256 i = 0; i < gemQuantities.length; i++) {
            uint256 quantity = gemQuantities[i];
            totalPrice = totalPrice.add(gemPrice.mul(quantity));
        }
        return totalPrice;
    }

    /// @dev Function to determine whether to use old or new prices
    /// @return Array of prices

    function _priceSelector() internal returns (uint256[] memory, uint256) {
        uint256[] memory prices;
        uint256 gemPrice;
        // No price change:
        if (_priceChangeTimestamp == 0) {
            prices = _starterPackPrices;
            gemPrice = _gemPrice;
        } else {
            // Price change delay has expired.
            if (now > _priceChangeTimestamp + PRICE_CHANGE_DELAY) {
                _priceChangeTimestamp = 0;
                prices = _starterPackPrices;
                gemPrice = _gemPrice;
            } else {
                // Price change has occured:
                prices = _previousStarterPackPrices;
                gemPrice = _previousGemPrice;
            }
        }
        return (prices, gemPrice);
    }

    /// @dev Function to handle purchase with SAND or DAI
    function _handlePurchaseWithERC20(
        address buyer,
        address payable paymentRecipient,
        address tokenAddress,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        uint256 amountForDestination = amount;
        require(token.transferFrom(buyer, paymentRecipient, amountForDestination), "PAYMENT_TRANSFER_FAILED");
    }

    // /////////////////// CONSTRUCTOR ////////////////////

    constructor(
        address starterPackAdmin,
        address sandContractAddress,
        address initialMetaTx,
        address payable initialWalletAddress,
        address medianizerContractAddress,
        address daiTokenContractAddress,
        address erc20GroupCatalystAddress,
        address erc20GroupGemAddress,
        address initialSigningWallet,
        uint256[] memory initialStarterPackPrices,
        uint256 initialGemPrice
    ) public PurchaseValidator(initialSigningWallet) {
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _admin = starterPackAdmin;
        _sand = ERC20(sandContractAddress);
        _medianizer = Medianizer(medianizerContractAddress);
        _dai = ERC20(daiTokenContractAddress);
        _erc20GroupCatalyst = ERC20Group(erc20GroupCatalystAddress);
        _erc20GroupGem = ERC20Group(erc20GroupGemAddress);
        _starterPackPrices = initialStarterPackPrices;
        _previousStarterPackPrices = initialStarterPackPrices;
        _gemPrice = initialGemPrice;
        _previousGemPrice = initialGemPrice;
        _sandEnabled = true; // Sand is enabled by default
        _etherEnabled = true; // Ether is enabled by default
    }
}

pragma solidity 0.6.5;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMathWithRequire for uint256;

    uint256 constant DECIMALS_18 = 1000000000000000000;
    uint256 constant DECIMALS_12 = 1000000000000;
    uint256 constant DECIMALS_9 = 1000000000;
    uint256 constant DECIMALS_6 = 1000000;

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divbyzero");
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "undeflow");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    // TODO test
    function rt6_3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(5) / 6;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpFive = tmp**5;
            require(tmpFive > tmp, "overflow");
            tmp = ((a / tmpFive) + (tmp * 5)) / 6;
        }
    }
}

pragma solidity 0.6.5;


/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

pragma solidity 0.6.5;

import "./Admin.sol";


contract MetaTransactionReceiver is Admin {
    mapping(address => bool) internal _metaTransactionContracts;

    /// @dev emiited when a meta transaction processor is enabled/disabled
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @dev Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @dev check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity 0.6.5;


/**
 * @title Medianizer contract
 * @dev From MakerDAO (https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B#code)
 */
interface Medianizer {
    function read() external view returns (bytes32);
}

pragma solidity 0.6.5;


contract Admin {
    address internal _admin;

    /// @dev emitted when the contract administrator is changed.
    /// @param oldAdmin address of the previous administrator.
    /// @param newAdmin address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @dev gives the current administrator of this contract.
    /// @return the current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev change the administrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin allowed");
        _;
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../BaseWithStorage/ERC20Group.sol";
import "./CatalystDataBase.sol";
import "../BaseWithStorage/ERC20SubToken.sol";
import "./CatalystValue.sol";


contract ERC20GroupCatalyst is CatalystDataBase, ERC20Group {
    /// @dev add Catalyst, if one of the catalyst to be added in the batch need to have a value override, all catalyst added in that batch need to have override
    /// if this is not desired, they can be added in a separated batch
    /// if no override are needed, the valueOverrides can be left emopty
    function addCatalysts(
        ERC20SubToken[] memory catalysts,
        MintData[] memory mintData,
        CatalystValue[] memory valueOverrides
    ) public {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        require(catalysts.length == mintData.length, "INVALID_INCONSISTENT_LENGTH");
        for (uint256 i = 0; i < mintData.length; i++) {
            uint256 id = _addSubToken(catalysts[i]);
            _setMintData(id, mintData[i]);
            if (valueOverrides.length > i) {
                _setValueOverride(id, valueOverrides[i]);
            }
        }
    }

    function addCatalyst(
        ERC20SubToken catalyst,
        MintData memory mintData,
        CatalystValue valueOverride
    ) public {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        uint256 id = _addSubToken(catalyst);
        _setMintData(id, mintData);
        _setValueOverride(id, valueOverride);
    }

    function setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) external {
        // CatalystMinter hardcode the value for efficiency purpose, so a change here would require a new deployment of CatalystMinter
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) public ERC20Group(metaTransactionContract, admin, initialMinter) {}
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../BaseWithStorage/ERC20Group.sol";


contract ERC20GroupGem is ERC20Group {
    function addGems(ERC20SubToken[] calldata catalysts) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        for (uint256 i = 0; i < catalysts.length; i++) {
            _addSubToken(catalysts[i]);
        }
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) public ERC20Group(metaTransactionContract, admin, initialMinter) {}
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SigUtil.sol";
import "../common/BaseWithStorage/Admin.sol";


contract PurchaseValidator is Admin {
    address private _signingWallet;

    // A parallel-queue mapping to nonces.
    mapping(address => mapping(uint128 => uint128)) public queuedNonces;

    /// @notice Function to get the nonce for a given address and queue ID
    /// @param _buyer The address of the starterPack purchaser
    /// @param _queueId The ID of the nonce queue for the given address.
    /// The default is queueID=0, and the max is queueID=2**128-1
    /// @return uint128 representing the requestied nonce
    function getNonceByBuyer(address _buyer, uint128 _queueId) external view returns (uint128) {
        return queuedNonces[_buyer][_queueId];
    }

    /// @notice Check if a purchase message is valid
    /// @param buyer The address paying for the purchase & receiving tokens
    /// @param catalystIds The catalyst IDs to be purchased
    /// @param catalystQuantities The quantities of the catalysts to be purchased
    /// @param gemIds The gem IDs to be purchased
    /// @param gemQuantities The quantities of the gems to be purchased
    /// @param nonce The current nonce for the user. This is represented as a
    /// uint256 value, but is actually 2 packed uint128's (queueId + nonce)
    /// @param signature A signed message specifying tx details
    /// @return True if the purchase is valid
    function isPurchaseValid(
        address buyer,
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemIds,
        uint256[] memory gemQuantities,
        uint256 nonce,
        bytes memory signature
    ) public returns (bool) {
        require(_checkAndUpdateNonce(buyer, nonce), "INVALID_NONCE");
        bytes32 hashedData = keccak256(abi.encodePacked(catalystIds, catalystQuantities, gemIds, gemQuantities, buyer, nonce));

        address signer = SigUtil.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);
        return signer == _signingWallet;
    }

    /// @notice Get the wallet authorized for signing purchase-messages.
    /// @return the address of the signing wallet
    function getSigningWallet() external view returns (address) {
        return _signingWallet;
    }

    /// @notice Update the signing wallet address
    /// @param newSigningWallet The new address of the signing wallet
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "SENDER_NOT_ADMIN");
        _signingWallet = newSigningWallet;
    }

    /// @dev Function for validating the nonce for a user.
    /// @param _buyer The address for which we want to check the nonce
    /// @param _packedValue The queueId + nonce, packed together.
    /// EG: for queueId=42 nonce=7, pass: "0x0000000000000000000000000000002A00000000000000000000000000000007"
    function _checkAndUpdateNonce(address _buyer, uint256 _packedValue) private returns (bool) {
        uint128 queueId = uint128(_packedValue / 2**128);
        uint128 nonce = uint128(_packedValue % 2**128);
        uint128 currentNonce = queuedNonces[_buyer][queueId];
        if (nonce == currentNonce) {
            queuedNonces[_buyer][queueId] = currentNonce + 1;
            return true;
        }
        return false;
    }

    constructor(address initialSigningWallet) public {
        _signingWallet = initialSigningWallet;
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./ERC20SubToken.sol";
import "../common/Libraries/SafeMath.sol";
import "../common/Libraries/AddressUtils.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/Libraries/BytesUtil.sol";

import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";


contract ERC20Group is SuperOperators, MetaTransactionReceiver {
    uint256 internal constant MAX_UINT256 = ~uint256(0);

    /// @notice emitted when a new Token is added to the group.
    /// @param subToken the token added, its id will be its index in the array.
    event SubToken(ERC20SubToken subToken);

    /// @notice emitted when `owner` is allowing or disallowing `operator` to transfer tokens on its behalf.
    /// @param owner the address approving.
    /// @param operator the address being granted (or revoked) permission to transfer.
    /// @param approved whether the operator is granted transfer right or not.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Minter(address minter, bool enabled);

    /// @notice Enable or disable the ability of `minter` to mint tokens
    /// @param minter address that will be given/removed minter right.
    /// @param enabled set whether the minter is enabled or disabled.
    function setMinter(address minter, bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setMinter(minter, enabled);
    }

    /// @notice check whether address `who` is given minter rights.
    /// @param who The address to query.
    /// @return whether the address has minter rights.
    function isMinter(address who) public view returns (bool) {
        return _minters[who];
    }

    /// @dev mint more tokens of a specific subToken .
    /// @param to address receiving the tokens.
    /// @param id subToken id (also the index at which it was added).
    /// @param amount of token minted.
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external {
        require(_minters[msg.sender], "NOT_AUTHORIZED_MINTER");
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        toPack[bin] = toPack[bin].updateTokenBalance(index, amount, ObjectLib32.Operations.ADD);
        _packedSupplies[bin] = _packedSupplies[bin].updateTokenBalance(index, amount, ObjectLib32.Operations.ADD);
        _erc20s[id].emitTransferEvent(address(0), to, amount);
    }

    /// @dev mint more tokens of a several subToken .
    /// @param to address receiving the tokens.
    /// @param ids subToken ids (also the index at which it was added).
    /// @param amounts for each token minted.
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(_minters[msg.sender], "NOT_AUTHORIZED_MINTER");
        require(ids.length == amounts.length, "INVALID_INCONSISTENT_LENGTH");
        _batchMint(to, ids, amounts);
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 lastBin = MAX_UINT256;
        uint256 bal = 0;
        uint256 supply = 0;
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    bal = toPack[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                    supply = _packedSupplies[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                } else {
                    if (bin != lastBin) {
                        toPack[lastBin] = bal;
                        bal = toPack[bin];
                        _packedSupplies[lastBin] = supply;
                        supply = _packedSupplies[bin];
                        lastBin = bin;
                    }
                    bal = bal.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                    supply = supply.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                }
                _erc20s[ids[i]].emitTransferEvent(address(0), to, amounts[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            toPack[lastBin] = bal;
            _packedSupplies[lastBin] = supply;
        }
    }

    /// @notice return the current total supply of a specific subToken.
    /// @param id subToken id.
    /// @return supply current total number of tokens.
    function supplyOf(uint256 id) external view returns (uint256 supply) {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedSupplies[bin].getValueInBin(index);
    }

    /// @notice return the balance of a particular owner for a particular subToken.
    /// @param owner whose balance it is of.
    /// @param id subToken id.
    /// @return balance of the owner
    function balanceOf(address owner, uint256 id) public view returns (uint256 balance) {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice return the balances of a list of owners / subTokens.
    /// @param owners list of addresses to which we want to know the balance.
    /// @param ids list of subTokens's addresses.
    /// @return balances list of balances for each request.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances) {
        require(owners.length == ids.length, "INVALID_INCONSISTENT_LENGTH");
        balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
    }

    /// @notice transfer a number of subToken from one address to another.
    /// @param from owner to transfer from.
    /// @param to destination address that will receive the tokens.
    /// @param id subToken id.
    /// @param value amount of tokens to transfer.
    function singleTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) external {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        ERC20SubToken erc20 = _erc20s[id];
        require(
            from == msg.sender ||
                msg.sender == address(erc20) ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        fromPack[bin] = fromPack[bin].updateTokenBalance(index, value, ObjectLib32.Operations.SUB);
        toPack[bin] = toPack[bin].updateTokenBalance(index, value, ObjectLib32.Operations.ADD);
        erc20.emitTransferEvent(from, to, value);
    }

    /// @notice transfer a number of different subTokens from one address to another.
    /// @param from owner to transfer from.
    /// @param to destination address that will receive the tokens.
    /// @param ids list of subToken ids to transfer.
    /// @param values list of amount for eacg subTokens to transfer.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        require(ids.length == values.length, "INVALID_INCONSISTENT_LENGTH");
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(
            from == msg.sender || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || _metaTransactionContracts[msg.sender],
            "NOT_AUTHORIZED"
        );
        _batchTransferFrom(from, to, ids, values);
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal {
        uint256 lastBin = MAX_UINT256;
        uint256 balFrom;
        uint256 balTo;
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        for (uint256 i = 0; i < ids.length; i++) {
            if (values[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    balFrom = ObjectLib32.updateTokenBalance(fromPack[bin], index, values[i], ObjectLib32.Operations.SUB);
                    balTo = ObjectLib32.updateTokenBalance(toPack[bin], index, values[i], ObjectLib32.Operations.ADD);
                } else {
                    if (bin != lastBin) {
                        fromPack[lastBin] = balFrom;
                        toPack[lastBin] = balTo;
                        balFrom = fromPack[bin];
                        balTo = toPack[bin];
                        lastBin = bin;
                    }
                    balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                    balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                }
                ERC20SubToken erc20 = _erc20s[ids[i]];
                erc20.emitTransferEvent(from, to, values[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            fromPack[lastBin] = balFrom;
            toPack[lastBin] = balTo;
        }
    }

    /// @notice grant or revoke the ability for an address to transfer token on behalf of another address.
    /// @param sender address granting/revoking the approval.
    /// @param operator address being granted/revoked ability to transfer.
    /// @param approved whether the operator is revoked or approved.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender], "NOT_AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice grant or revoke the ability for an address to transfer token on your behalf.
    /// @param operator address being granted/revoked ability to transfer.
    /// @param approved whether the operator is revoked or approved.
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice return whether an oeprator has the ability to transfer on behalf of another address.
    /// @param owner address who would have granted the rights.
    /// @param operator address being given the ability to transfer.
    /// @return isOperator whether the operator has approval rigths or not.
    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function isAuthorizedToTransfer(address owner, address sender) external view returns (bool) {
        return _metaTransactionContracts[sender] || _superOperators[sender] || _operatorsForAll[owner][sender];
    }

    function isAuthorizedToApprove(address sender) external view returns (bool) {
        return _metaTransactionContracts[sender] || _superOperators[sender];
    }

    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(from != address(0), "INVALID_FROM_ZERO_ADDRESS");
        require(
            from == msg.sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _batchBurnFrom(from, ids, amounts);
    }

    /// @notice burn token for a specific owner and subToken.
    /// @param from fron which address the token are burned from.
    /// @param id subToken id.
    /// @param value amount of tokens to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external {
        require(
            from == msg.sender || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || _metaTransactionContracts[msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(from, id, value);
    }

    /// @notice burn token for a specific subToken.
    /// @param id subToken id.
    /// @param value amount of tokens to burn.
    function burn(uint256 id, uint256 value) external {
        _burn(msg.sender, id, value);
    }

    // ///////////////// INTERNAL //////////////////////////

    function _batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 balFrom = 0;
        uint256 supply = 0;
        uint256 lastBin = MAX_UINT256;
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    balFrom = fromPack[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                    supply = _packedSupplies[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                } else {
                    if (bin != lastBin) {
                        fromPack[lastBin] = balFrom;
                        balFrom = fromPack[bin];
                        _packedSupplies[lastBin] = supply;
                        supply = _packedSupplies[bin];
                        lastBin = bin;
                    }

                    balFrom = balFrom.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                    supply = supply.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                }
                _erc20s[ids[i]].emitTransferEvent(from, address(0), amounts[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            fromPack[lastBin] = balFrom;
            _packedSupplies[lastBin] = supply;
        }
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        ERC20SubToken erc20 = _erc20s[id];
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        fromPack[bin] = ObjectLib32.updateTokenBalance(fromPack[bin], index, value, ObjectLib32.Operations.SUB);
        _packedSupplies[bin] = ObjectLib32.updateTokenBalance(_packedSupplies[bin], index, value, ObjectLib32.Operations.SUB);
        erc20.emitTransferEvent(from, address(0), value);
    }

    function _addSubToken(ERC20SubToken subToken) internal returns (uint256 id) {
        id = _erc20s.length;
        require(subToken.groupAddress() == address(this), "INVALID_GROUP");
        require(subToken.groupTokenId() == id, "INVALID_ID");
        _erc20s.push(subToken);
        emit SubToken(subToken);
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_SUPER_OPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    function _setMinter(address minter, bool enabled) internal {
        _minters[minter] = enabled;
        emit Minter(minter, enabled);
    }

    // ///////////////// UTILITIES /////////////////////////
    using AddressUtils for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;
    using SafeMath for uint256;

    // ////////////////// DATA ///////////////////////////////
    mapping(uint256 => uint256) internal _packedSupplies;
    mapping(address => mapping(uint256 => uint256)) internal _packedTokenBalance;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    ERC20SubToken[] internal _erc20s;
    mapping(address => bool) internal _minters;

    // ////////////// CONSTRUCTOR ////////////////////////////

    struct SubTokenData {
        string name;
        string symbol;
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) internal {
        _admin = admin;
        _setMetaTransactionProcessor(metaTransactionContract, true);
        _setMinter(initialMinter, true);
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./CatalystValue.sol";


contract CatalystDataBase is CatalystValue {
    event CatalystConfiguration(uint256 indexed id, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, uint256 sandUpdateFee);

    function _setMintData(uint256 id, MintData memory data) internal {
        _data[id] = data;
        _emitConfiguration(id, data.minQuantity, data.maxQuantity, data.sandMintingFee, data.sandUpdateFee);
    }

    function _setValueOverride(uint256 id, CatalystValue valueOverride) internal {
        _valueOverrides[id] = valueOverride;
    }

    function _setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        _data[id].minQuantity = minQuantity;
        _data[id].maxQuantity = maxQuantity;
        _data[id].sandMintingFee = uint88(sandMintingFee);
        _data[id].sandUpdateFee = uint88(sandUpdateFee);
        _emitConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    function _emitConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        emit CatalystConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    ///@dev compute a random value between min to 25.
    //. example: 1-25, 6-25, 11-25, 16-25
    function _computeValue(
        uint256 seed,
        uint256 gemId,
        bytes32 blockHash,
        uint256 slotIndex,
        uint32 min
    ) internal pure returns (uint32) {
        return min + uint16(uint256(keccak256(abi.encodePacked(gemId, seed, blockHash, slotIndex))) % (26 - min));
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external override view returns (uint32[] memory values) {
        CatalystValue valueOverride = _valueOverrides[catalystId];
        if (address(valueOverride) != address(0)) {
            return valueOverride.getValues(catalystId, seed, events, totalNumberOfGemTypes);
        }
        values = new uint32[](totalNumberOfGemTypes);

        uint32 numGems;
        for (uint256 i = 0; i < events.length; i++) {
            numGems += uint32(events[i].gemIds.length);
        }
        require(numGems <= MAX_UINT32, "TOO_MANY_GEMS");
        uint32 minValue = (numGems - 1) * 5 + 1;

        uint256 numGemsSoFar = 0;
        for (uint256 i = 0; i < events.length; i++) {
            numGemsSoFar += events[i].gemIds.length;
            for (uint256 j = 0; j < events[i].gemIds.length; j++) {
                uint256 gemId = events[i].gemIds[j];
                uint256 slotIndex = numGemsSoFar - events[i].gemIds.length + j;
                if (values[gemId] == 0) {
                    // first gem : value = roll between ((numGemsSoFar-1)*5+1) and 25
                    values[gemId] = _computeValue(seed, gemId, events[i].blockHash, slotIndex, (uint32(numGemsSoFar) - 1) * 5 + 1);
                    // bump previous values:
                    if (values[gemId] < minValue) {
                        values[gemId] = minValue;
                    }
                } else {
                    // further gem, previous roll are overriden with 25 and new roll between 1 and 25
                    uint32 newRoll = _computeValue(seed, gemId, events[i].blockHash, slotIndex, 1);
                    values[gemId] = (((values[gemId] - 1) / 25) + 1) * 25 + newRoll;
                }
            }
        }
    }

    function getMintData(uint256 catalystId)
        external
        view
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        )
    {
        maxGems = _data[catalystId].maxGems;
        minQuantity = _data[catalystId].minQuantity;
        maxQuantity = _data[catalystId].maxQuantity;
        sandMintingFee = _data[catalystId].sandMintingFee;
        sandUpdateFee = _data[catalystId].sandUpdateFee;
    }

    struct MintData {
        uint88 sandMintingFee;
        uint88 sandUpdateFee;
        uint16 minQuantity;
        uint16 maxQuantity;
        uint16 maxGems;
    }

    uint32 internal constant MAX_UINT32 = 2**32 - 1;

    mapping(uint256 => MintData) internal _data;
    mapping(uint256 => CatalystValue) internal _valueOverrides;
}

pragma solidity 0.6.5;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";

import "./ERC20Group.sol";


contract ERC20SubToken {
    // TODO add natspec, currently blocked by solidity compiler issue
    event Transfer(address indexed from, address indexed to, uint256 value);

    // TODO add natspec, currently blocked by solidity compiler issue
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice the tokenId in ERC20Group
    /// @return the tokenId in ERC20Group
    function groupTokenId() external view returns (uint256) {
        return _index;
    }

    /// @notice the ERC20Group address
    /// @return the address of the group
    function groupAddress() external view returns (address) {
        return address(_group);
    }

    function totalSupply() external view returns (uint256) {
        return _group.supplyOf(_index);
    }

    function balanceOf(address who) external view returns (uint256) {
        return _group.balanceOf(who, _index);
    }

    function decimals() external pure returns (uint8) {
        return uint8(0);
    }

    function transfer(address to, uint256 amount) external returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success) {
        if (msg.sender != from && !_group.isAuthorizedToTransfer(from, msg.sender)) {
            uint256 allowance = _mAllowed[from][msg.sender];
            if (allowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(allowance >= amount, "NOT_AUTHOIZED_ALLOWANCE");
                _mAllowed[from][msg.sender] = allowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool success) {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    function approveFor(
        address from,
        address spender,
        uint256 amount
    ) external returns (bool success) {
        require(msg.sender == from || _group.isAuthorizedToApprove(msg.sender), "NOT_AUTHORIZED");
        _approveFor(from, spender, amount);
        return true;
    }

    function emitTransferEvent(
        address from,
        address to,
        uint256 amount
    ) external {
        require(msg.sender == address(_group), "NOT_AUTHORIZED_GROUP_ONLY");
        emit Transfer(from, to, amount);
    }

    // /////////////////// INTERNAL ////////////////////////

    function _approveFor(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0) && spender != address(0), "INVALID_FROM_OR_SPENDER");
        _mAllowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256 remaining) {
        return _mAllowed[owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _group.singleTransferFrom(from, to, _index, amount);
    }

    // ///////////////////// UTILITIES ///////////////////////
    using SafeMathWithRequire for uint256;

    // //////////////////// CONSTRUCTOR /////////////////////
    constructor(
        ERC20Group group,
        uint256 index,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        _group = group;
        _index = index;
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    // ////////////////////// DATA ///////////////////////////
    ERC20Group internal immutable _group;
    uint256 internal immutable _index;
    mapping(address => mapping(address => uint256)) internal _mAllowed;
    string internal _name;
    string internal _symbol;
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface CatalystValue {
    struct GemEvent {
        uint256[] gemIds;
        bytes32 blockHash;
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external view returns (uint32[] memory values);
}

pragma solidity 0.6.5;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity 0.6.5;


library AddressUtils {
    function toPayable(address _address) internal pure returns (address payable _payable) {
        return address(uint160(_address));
    }

    function isContract(address addr) internal view returns (bool) {
        // for accounts without code, i.e. `keccak256('')`:
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codehash;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

pragma solidity 0.6.5;

import "./SafeMathWithRequire.sol";


library ObjectLib32 {
    using SafeMathWithRequire for uint256;
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
     * @dev Return the bin number and index within that bin where ID is
     * @param tokenId Object type
     * @return bin Bin number
     * @return index ID's index within that bin
     */
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        bin = (tokenId * TYPES_BITS_SIZE) / 256;
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance.add(amount));
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance.sub(amount));
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

pragma solidity 0.6.5;


library BytesUtil {
    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function pointerToBytes(uint256 src, uint256 len) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, src, len);
        return ret;
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function uint256ToBytes(uint256 a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 32), a)
            mstore(0x40, add(m, 64))
            b := m
        }
    }

    function doFirstParamEqualsAddress(bytes memory data, address _address) internal pure returns (bool) {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(_address);
    }

    function doParamEqualsUInt256(
        bytes memory data,
        uint256 i,
        uint256 value
    ) internal pure returns (bool) {
        if (data.length < (36 + (i + 1) * 32)) {
            return false;
        }
        uint256 offset = 36 + i * 32;
        uint256 valuePresent;
        assembly {
            valuePresent := mload(add(data, offset))
        }
        return valuePresent == value;
    }

    function overrideFirst32BytesWithAddress(bytes memory data, address _address) internal pure returns (bytes memory) {
        uint256 dest;
        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)

        bytes memory addressBytes = addressToBytes(_address);
        uint256 src;
        assembly {
            src := add(addressBytes, 32)
        }

        memcpy(dest, src, 20);
        return data;
    }

    function overrideFirstTwo32BytesWithAddressAndInt(
        bytes memory data,
        address _address,
        uint256 _value
    ) internal pure returns (bytes memory) {
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)
        bytes memory bbytes = addressToBytes(_address);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 20);

        assembly {
            dest := add(data, 68)
        } // 48 = 32 (offset) + 4 (func sig) + 32 (next slot)
        bbytes = uint256ToBytes(_value);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 32);

        return data;
    }
}

pragma solidity 0.6.5;

import "./Admin.sol";


contract SuperOperators is Admin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

pragma solidity 0.6.5;


library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0));
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}