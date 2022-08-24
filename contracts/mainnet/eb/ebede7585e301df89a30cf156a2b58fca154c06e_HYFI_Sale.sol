// SPDX-License-Identifier: Apache-2.0
/**
 * Created on 2022-07-13 19:10
 * @summary:
 * @author: tata
 */
pragma solidity ^0.8.12;

import "@hyfi-corp/presale/contracts/interfaces/IHYFI_PriceCalculator.sol";
import "@hyfi-corp/presale/contracts/interfaces/IHYFI_Referrals.sol";
import "@hyfi-corp/presale/contracts/interfaces/IHYFI_Presale.sol";
import "@hyfi-corp/vault/contracts/interfaces/IHYFI_Vault.sol";
import "./OfflineReservations/interfaces/IHYFI_OfflineReservationsForSale.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title HYFI Sale smart contract
 * @dev The implementation of HYFI sale stage functionality
 * that handles buying and claiming process of vault tickets
 */
contract HYFI_Sale is Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IHYFI_OfflineReservationsForSale public offline;
    IHYFI_PriceCalculator public calc;
    IHYFI_Referrals public referrals;
    IHYFI_Vault public vault;
    IHYFI_Presale public presale;

    mapping(address => BuyerData) buyerInfo;
    mapping(address => uint256) claimed;

    uint256 public startTime;
    uint256 public totalUnitAmount;
    uint256 public totalAmountSold;
    address internal collectorWallet;
    address[] internal _buyersAddressList;
    bool public saleEnded;

    struct BuyerData {
        uint256 totalAmountBought;
        uint256 referralAmountBought;
        mapping(uint256 => uint256) referrals;
        uint256[] referralsList;
    }

    event AllUnitsSold(uint256 unitAmount);
    event CurrencyWithdrawn(address from, address to, uint256 amount);
    event ERC20Withdrawn(
        address from,
        address to,
        uint256 amount,
        address tokenAddress
    );
    event FundsRetrieved(address addr, uint256 amount);
    event UnitSold(
        address buyer,
        string token,
        uint256 amount,
        uint256 referral
    );
    event VaultsClaimed(address user, uint256 amount);
    event VaultsMinted(address to, uint256 amount);
    event SaleEndedUpdated(bool saleEnded);

    modifier addressNotZero(address addr) {
        require(
            addr != address(0),
            "Passed parameter has zero address declared"
        );
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount > 0, "Passed amount is equal to zero");
        _;
    }

    modifier ongoingSale() {
        require(
            block.timestamp >= startTime,
            "You can not buy any units, sale has not started yet"
        );
        require(!saleEnded, "You can no longer buy any units, sale is ended");
        _;
    }

    modifier possiblePurchaseUntilHardcap(uint256 amount) {
        require(
            totalAmountSold + amount <= totalUnitAmount,
            "Hardcap is reached, can not buy that many units"
        );
        _;
    }

    modifier canClaim(address user) {
        require(
            _availableForClaim(user) > 0,
            "You have not bought any units in order to claim or claimed all purchased units"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Initializer, used instead of constructor in the upgradable approach
     * @param _priceCalculatorContractAddress address of the PriceCalculator contract
     * @param _referralsContractAddress address of the Referrals contract
     * @param _presaleContractAddress address of the Presale contract
     * @param _vaultContractAddress address of the Vault NFT contract
     * @param _collectorWallet address of the wallet which assets are transfered to, normally should be multisig wallet
     * @param _startTime timestamp of sale start
     * @param _totalUnitAmount the total number of vault tickets available for sale during sale stage
     */
    function initialize(
        address _priceCalculatorContractAddress,
        address _referralsContractAddress,
        address _presaleContractAddress,
        address _vaultContractAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _totalUnitAmount
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        calc = IHYFI_PriceCalculator(_priceCalculatorContractAddress);
        referrals = IHYFI_Referrals(_referralsContractAddress);
        presale = IHYFI_Presale(_presaleContractAddress);
        vault = IHYFI_Vault(_vaultContractAddress);
        collectorWallet = _collectorWallet;
        startTime = _startTime;
        totalUnitAmount = _totalUnitAmount;
    }

    /**
     * @dev purchase of Vault tickets using erc-20 tokens - USDT, USDC, HYFI
     * @param token the name of the erc-20 token, can be USDT or USDC
     * @param buyWithHYFI marker is purchase is done with HYFI tokens, if yes, 50% is paid with token (USDT/USDC) and 50% with HYFI
     * @param amount the amount of Vault tickets user is going to to buy
     * @param referralCode the string of the referral code presented as integer
     */
    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        uint256 referralCode
    )
        external
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        require(
            keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDT")) ||
                keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDC")),
            "No stable coin provided"
        );
        uint256 discount = calc.discountPercentageCalculator(
            amount,
            msg.sender,
            1
        );
        if (buyWithHYFI) {
            _buyWithHYFIToken(token, amount, discount, referralCode);
            _updateData("HYFI", amount, msg.sender, referralCode);
        } else {
            _buyWithMainToken(token, amount, discount, referralCode);
            _updateData(token, amount, msg.sender, referralCode);
        }
        _mintVaults(msg.sender, amount);
    }

    /**
     * @dev purchase of Vault tickets using ether
     * @param amount the amount of Vault tickets user is going to to buy
     * @param referralCode the string of the referral code presented as integer
     */
    function buyWithCurrency(uint256 amount, uint256 referralCode)
        external
        payable
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        _buyWithCurrency(
            amount,
            calc.discountPercentageCalculator(amount, msg.sender, 1),
            referralCode
        );
        _updateData("ETH", amount, msg.sender, referralCode);
        _mintVaults(msg.sender, amount);
    }

    /**
     * @dev claiming of Vault tickets reserved beforehand on presale or offline
     */
    function claimVaults()
        external
        virtual
        addressNotZero(msg.sender)
        canClaim(msg.sender)
        ongoingSale
    {
        uint256 _claimAmount;
        _claimAmount = _availableForClaim(msg.sender);
        _claim(msg.sender, _claimAmount);
    }

    /**
     * @dev withdraw the stuck ether from the contract
     * @param recipient address of the recipient
     * @param amount the amount of ether for withdrawal
     */
    function withdrawCurrency(address recipient, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            address(this).balance >= amount,
            "Contract does not have enough currency"
        );
        (bool success, ) = payable(recipient).call{gas: 200_000, value: amount}(
            ""
        );
        require(success);
        emit CurrencyWithdrawn(recipient, msg.sender, amount);
    }

    /**
     * @dev withdraw the stuck erc-20 tokens from the contract
     * @param tokenAddress the address of the erc-20 token
     * @param recipient address of the recipient
     * @param amount the amount of ether for withdrawal
     */
    function withdrawERC20Tokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= amount,
            "Contract does not have enough ERC20 tokens"
        );
        IERC20Upgradeable(tokenAddress).safeTransfer(recipient, amount);

        emit ERC20Withdrawn(
            recipient,
            msg.sender,
            amount,
            address(tokenAddress)
        );
    }

    /**
     * @dev set the new start time of the sale stage
     * @param newStartTime the new start time of the sale stage
     */
    function setStartTime(uint256 newStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTime = newStartTime;
    }

    /**
     * @dev set the new total amount of Vault tickets on the sale stage
     * @param newAmount the new amount of tickets
     */
    function setTotalUnitAmount(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        totalUnitAmount = newAmount;
    }

    /**
     * @dev set the new collector address
     * @param newCollector the new collector address
     */
    function setCollectorWalletAddress(address newCollector)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        collectorWallet = newCollector;
    }

    /**
     * @dev set the new PriceCalculator address
     * @param newOfflineReservations the new OfflineReservations contract address
     */
    function setOfflineReservationsAddress(address newOfflineReservations)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        offline = IHYFI_OfflineReservationsForSale(newOfflineReservations);
    }

    /**
     * @dev set the new PriceCalculator address
     * @param newPriceCalculator the new PriceCalculator address
     */
    function setPriceCalculatorAddress(address newPriceCalculator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        calc = IHYFI_PriceCalculator(newPriceCalculator);
    }

    /**
     * @dev set the new ReferralCalculator address
     * @param newReferral the new Referral address
     */
    function setReferralAddress(address newReferral)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrals = IHYFI_Referrals(newReferral);
    }

    /**
     * @dev set the new Presale smart contracts address
     * @param newPresale the new Presale address
     */
    function setPresaleAddress(address newPresale)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presale = IHYFI_Presale(newPresale);
    }

    /**
     * @dev set the new Vault NFT smart contracts address
     * @param newVault the new Vault address
     */
    function setVaultAddress(address newVault)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vault = IHYFI_Vault(newVault);
    }

    /**
     * @dev set the marker if the sale stage is ended
     * @param ended true if the sale is ended
     */
    function setSaleEnded(bool ended) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleEnded = ended;
        emit SaleEndedUpdated(saleEnded);
    }

    /**
     * @dev get buyer data
     * @param user address of the buyer
     * @return user total amount of units purchased,
     *         user total amount of units purchased using referraal codes,
     *         user used referral code list
     */
    function getBuyerData(address user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            buyerInfo[user].totalAmountBought,
            buyerInfo[user].referralAmountBought,
            buyerInfo[user].referralsList
        );
    }

    /**
     * @dev get the number of referral codes used by the user during sale stage
     * @param user buyer address
     * @param referral used referral code
     * @return how many times the referral code is used by the user
     */
    function getBuyerReferralData(address user, uint256 referral)
        external
        view
        returns (uint256)
    {
        return buyerInfo[user].referrals[referral];
    }

    /**
     * @dev get the total amount of buyers during sale stage
     * @return total number of buyers
     */

    function getTotalAmountOfBuyers() external view returns (uint256) {
        return (_buyersAddressList.length);
    }

    /**
     * @dev get the array of buyers during sale stage
     * @return array of buyers addresses
     */
    function getAllBuyers() external view returns (address[] memory) {
        return (_buyersAddressList);
    }

    /**
     * @dev get the total number of already claimed Vaults by the user
     * @param user the user address
     * @return total number of claimed Vault tickets
     */
    function getClaimed(address user) external view returns (uint256) {
        return claimed[user];
    }

    /**
     * @dev get the total number of available Vault tickets for the claim
     * is calculated in the way: (totally reserved on presale + offline) - claimed in total
     * @param user the user address
     * @return total number tickets available for claiming
     */
    function getAvailableForClaim(address user)
        external
        view
        returns (uint256)
    {
        return _availableForClaim(user);
    }

    /**
     * @dev get the total number of reserved Vault tickets during presale stage + offline
     * @param user the user address
     * @return total number of reserved Vault tickets
     */
    function getTotalReservedAmount(address user)
        external
        view
        returns (uint256)
    {
        return _totalReservedAmount(user);
    }

    /**
     * @dev the processor of buying Vault tickets with main tokens (USDT/USDC)
     * @param token the token name (USDT or USDC)
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithMainToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.simpleTokenPaymentCalculator(
            token,
            unitAmount,
            discount,
            referralCode
        );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData(token).tokenAddress),
            priceTotal
        );
    }

    /**
     * @dev the processor of buying Vault tickets with 50%/50% main tokens (USDT/USDC) / HYFI tokens
     * @param token the token name (USDT or USDC)
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithHYFIToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 HYFItokenPayment;
        uint256 stableCoinPaymentAmount;
        (stableCoinPaymentAmount, HYFItokenPayment) = calc
            .mixedTokenPaymentCalculator(
                token,
                unitAmount,
                discount,
                referralCode
            );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData(token).tokenAddress),
            stableCoinPaymentAmount
        );
        _buyWithERC20(
            IERC20Upgradeable(calc.getTokenData("HYFI").tokenAddress),
            HYFItokenPayment
        );
    }

    /**
     * @dev the processor of transfering erc-20 tokens from the buyer to collector
     * @param tokenAddress erc-20 token address
     * @param priceTotal the amount of erc-20 tokens which should be transferred
     */
    function _buyWithERC20(IERC20Upgradeable tokenAddress, uint256 priceTotal)
        internal
        virtual
    {
        require(
            tokenAddress.balanceOf(msg.sender) >= priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        tokenAddress.safeTransferFrom(msg.sender, collectorWallet, priceTotal);
    }

    /**
     * @dev the processor of buying Vault tickets with ether
     * @param unitAmount the amount of tickets
     * @param discount the discount amount
     * @param referralCode the refferal code used in purchase
     */
    function _buyWithCurrency(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.currencyPaymentCalculator(
            unitAmount,
            discount,
            referralCode
        );
        require(
            msg.value == priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        (bool success, ) = payable(collectorWallet).call{
            gas: 200_000,
            value: priceTotal
        }("");
        require(success);
    }

    /**
     * @dev the processor for updating storage variables after purchase
     * it updates buyer information, and calls referral code information update
     * @param token the token name (USDT or USDC or HYFI (if is bought with 50/50 scheme) or ETH)
     * @param unitAmount the amount of bought tickets
     * @param buyer the user address
     * @param referralCode the referral code used in purchase
     */
    function _updateData(
        string memory token,
        uint256 unitAmount,
        address buyer,
        uint256 referralCode
    ) internal virtual {
        totalAmountSold += unitAmount;
        calc.setAmountBoughtWithReferral(token, unitAmount);
        if (buyerInfo[buyer].totalAmountBought == 0) {
            _buyersAddressList.push(buyer);
        }
        buyerInfo[buyer].totalAmountBought += unitAmount;
        if (totalAmountSold >= totalUnitAmount) {
            saleEnded = true;
            emit AllUnitsSold(unitAmount);
        }
        if (referralCode != 0) {
            _updateReferral(unitAmount, referralCode, buyer);
        }
        emit UnitSold(buyer, token, unitAmount, referralCode);
    }

    /**
     * @dev the processor for updating storage variables related to referral code after purchase
     * it updates buyer information referral code used, and calls referral code information update
     * @param unitAmount the amount of bought tickets
     * @param referralCode the referral code used in purchase
     * @param buyer the user address
     */
    function _updateReferral(
        uint256 unitAmount,
        uint256 referralCode,
        address buyer
    ) internal virtual {
        /* If the buyer has yet to buy any units using this referral code,
           add the code to the buyer referral list (which referral codes did they use) */
        if (buyerInfo[buyer].referrals[referralCode] == 0) {
            buyerInfo[buyer].referralsList.push(referralCode);
        }
        // Add bought unit amount corresponding to the referral used  during the purchase
        buyerInfo[buyer].referrals[referralCode] += unitAmount;
        referrals.updateAmountBoughtWithReferral(referralCode, unitAmount);
        // Add to the total amount bought using referral code
        buyerInfo[buyer].referralAmountBought += unitAmount;
    }

    /**
     * @dev the processor of claiming Vault tickets, updates the total number of claimed tickets by the user and mints Vault NFTs
     * @param user the claimer address
     * @param unitAmount the amount of tickets user is going to claim
     */
    function _claim(address user, uint256 unitAmount) internal {
        claimed[user] = claimed[user] + unitAmount;
        _mintVaults(user, unitAmount);
        emit VaultsClaimed(user, unitAmount);
    }

    /**
     * @dev processor of minting Vault NFTs (tickets)
     * @param user the address the NFT Vault should be mint to
     * @param unitAmount the amount of Vault tickets to mint
     */
    function _mintVaults(address user, uint256 unitAmount) internal {
        vault.safeMint(user, unitAmount);
        emit VaultsMinted(user, unitAmount);
    }

    /**
     * @dev internal method which gets the total number of available Vault tickets for the claim
     * is calculated in the way: (totally reserved on presale + offline) - claimed in total
     * @param user the user address
     * @return total number of available for claim Vault tickets
     */
    function _availableForClaim(address user) internal view returns (uint256) {
        return _totalReservedAmount(user) - claimed[user];
    }

    /**
     * @dev the internal method which gets the total number of reserved Vault tickets during presale stage + offline
     * @param user the user address
     * @return total number of reserved Vault tickets
     */
    function _totalReservedAmount(address user)
        internal
        view
        returns (uint256)
    {
        uint256 totalAmountBought = presale.getBuyerReservedAmount(user);
        if (address(offline) != address(0)) {
            totalAmountBought =
                totalAmountBought +
                offline.getBuyerReservedAmount(user);
        }
        return totalAmountBought;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

interface IHYFI_OfflineReservationsForSale {
    function getBuyers() external view returns (address[] memory);

    function getBuyerReservedAmount(address user)
        external
        view
        returns (uint256);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IHYFI_Vault is IAccessControlUpgradeable {
    function MINTER_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function safeMint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_Referrals {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function REFERRAL_SETTER() external view returns (bytes32);

    function addMultipleToReferralList(
        uint256 referralDiscount,
        uint256[] memory referralCode
    ) external;

    function addToReferralCodeList(uint256 referralCode) external;

    function addToReferralList(uint256 referralDiscount, uint256 referralCode)
        external;

    function getAllUsedReferralCodeList()
        external
        view
        returns (uint256[] memory);

    function getAmountBoughtWithReferral(uint256 referralCode)
        external
        view
        returns (uint256);

    function getReferralDiscountAmount(uint256 referralCode)
        external
        view
        returns (uint256 discountAmount);

    function getReferralDiscountAmountByRange(uint256 referralCode)
        external
        view
        returns (uint256);

    function getReferralInfo(uint256 amount)
        external
        view
        returns (string[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize() external;

    function removeFromReferralList(uint256 referralCode) external;

    function removeReferralInfoLayer(uint256 referralDiscount) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function updateAmountBoughtWithReferral(
        uint256 referralCode,
        uint256 amount
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_PriceCalculator {
    struct TokenData {
        address tokenAddress;
        uint256 totalAmountBought;
        uint256 decimals;
    }

    function CALCULATOR_SETTER() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function HYFI_SETTER_ROLE() external view returns (bytes32);

    function HYFIexchangeRate() external view returns (uint256);

    function currencyPaymentCalculator(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) external view returns (uint256 paymentAmount);

    function discountAmountCalculator(uint256 discount, uint256 value)
        external
        pure
        returns (uint256 discountAmount);

    function discountPercentageCalculator(uint256 unitAmount, address buyer)
        external
        view
        returns (uint256 discountPrecentage);
        
    function discountPercentageCalculator(uint256 unitAmount, address buyer, uint256 stage)
        external
        view
        returns (uint256 discountPrecentage);

    function distrPercWithHYFI() external view returns (uint256);

    function getLatestETHPrice() external view returns (int256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getTokenData(string memory token)
        external
        view
        returns (TokenData memory);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(
        address _whitelistCotractAddress,
        address _referralsContractAddress,
        address USDTtokenAddress,
        address USDCtokenAddress,
        address HYFItokenAddress,
        uint256 _unitPrice,
        uint256 _HYFIexchangeRate
    ) external;

    function mixedTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    )
        external
        view
        returns (uint256 stableCoinPaymentAmount, uint256 HYFIPaymentAmount);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setAmountBoughtWithReferral(string memory token, uint256 amount)
        external;

    function setHYFIexchangeRate(uint256 newExchangeRate) external;

    function setNewReferralsImplementation(address newReferrals) external;

    function setNewWhitelistImplementation(address newWhitelist) external;

    function setUnitPrice(uint256 newPrice) external;

    function simpleTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) external view returns (uint256 paymentAmount);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unitPrice() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_Presale {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function buyWithCurrency(uint256 amount, uint256 referralCode) external;

    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        uint256 referralCode
    ) external;

    function endTime() external view returns (uint256);

    function getAllBuyers() external view returns (address[] memory);

    function getBuyerData(address addr)
        external
        view
        returns (
            uint256,
            uint256,
            string[] memory
        );

    function getBuyerReservedAmount(address addr)
        external
        view
        returns (uint256);

    function getBuyerFromListById(uint256 id) external view returns (address);

    function getBuyerReferralData(address addr, uint256 referral)
        external
        view
        returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getTotalAmountOfBuyers() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(
        address _priceCalculatorContractAddress,
        address _referralsContractAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setCollectorWalletAddress(address newAddress) external;

    function setNewPriceCalculatorImplementation(address newPriceCalculator)
        external;

    function setNewReferralImplementation(address newReferral) external;

    function setNewSaleTime(uint256 newStartTime, uint256 newEndTime) external;

    function setTotalUnitAmount(uint256 newAmount) external;

    function startTime() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function totalAmountSold() external view returns (uint256);

    function totalUnitAmount() external view returns (uint256);

    function withdrawCurrency(address recipient, uint256 amount) external;

    function withdrawERC20Tokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external returns (bool);
}