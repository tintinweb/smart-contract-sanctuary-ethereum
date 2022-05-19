//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IQuadPassport.sol";
import "./interfaces/IQuadGovernance.sol";
import "./interfaces/IQuadReader.sol";
import "./storage/QuadReaderStore.sol";
import "./storage/QuadPassportStore.sol";
import "./storage/QuadGovernanceStore.sol";

/// @title Data Reader Contract for Quadrata Passport
/// @author Fabrice Cheng, Theodore Clapp
/// @notice All accessor functions for reading and pricing quadrata attributes

 contract QuadReader is IQuadReader, UUPSUpgradeable, QuadReaderStore {

    /// @dev initializer (constructor)
    /// @param _governance address of the IQuadGovernance contract
    /// @param _passport address of the IQuadPassport contract
    function initialize(
        address _governance,
        address _passport
    ) public initializer {
        require(_governance != address(0), "GOVERNANCE_ADDRESS_ZERO");
        require(_passport != address(0), "PASSPORT_ADDRESS_ZERO");

        governance = IQuadGovernance(_governance);
        passport = IQuadPassport(_passport);
    }

    function _authorizeUpgrade(address) internal view override {
        require(governance.hasRole(GOVERNANCE_ROLE, msg.sender), "INVALID_ADMIN");
    }

    /// @notice Query the values of an attribute for a passport holder (payable with ERC20)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _tokenAddr address of the ERC20 token to use as a payment
    /// @param _excluded The list of issuers to ignore. Keep empty for full list
    /// @return the values of the attribute from all issuers ignoring the excluded list
    function getAttributesExcluding(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr,
        address[] memory _excluded
    ) public override returns(bytes32[] memory, uint256[] memory, address[] memory) {
        _validateAttributeQuery(_account, _tokenId, _attribute);
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) = _applyFilter(_account, _attribute, _excludedIssuers(_excluded));

        _doTokenPayments(_attribute, _tokenAddr, issuers, _account);

        return (attributes, epochs, issuers);
    }

    /// @notice Query the values of an attribute for a passport holder (free)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _excluded The list of issuers to ignore. Keep empty for full list
    /// @return the values of the attribute from all issuers ignoring the excluded list
    function getAttributesFreeExcluding(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] memory _excluded
    ) public override view returns(bytes32[] memory, uint256[] memory, address[] memory) {
        _validateAttributeQuery(_account, _tokenId, _attribute);
        require(governance.pricePerAttribute(_attribute) == 0, "ATTRIBUTE_NOT_FREE");
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) =  _applyFilter(_account, _attribute, _excludedIssuers(_excluded));
        return (attributes, epochs, issuers);
    }

    /// @notice Query the values of an attribute for a passport holder (payable ETH)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _excluded The list of issuers to ignore. Keep empty for full list
    /// @return the values of an attribute from all issuers ignoring the excluded list
    function getAttributesETHExcluding(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] memory _excluded
    ) public override payable returns(bytes32[] memory, uint256[] memory, address[] memory) {
        _validateAttributeQuery(_account, _tokenId, _attribute);
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) = _applyFilter(_account, _attribute, _excludedIssuers(_excluded));

        _doETHPayments(_attribute, issuers, _account);

        return (attributes, epochs, issuers);
    }

    /// @notice Get all values of an attribute for a passport holder (payable ETH)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @return all values from all issuers
    function getAttributesETH(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    )external override payable returns(bytes32[] memory, uint256[] memory, address[] memory) {
        return getAttributesETHExcluding(_account, _tokenId, _attribute, new address[](0));
    }

    /// @notice Get all values of an attribute for a passport holder (free)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @return all values of the the attribute from all issuers
    function getAttributesFree(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    )external override view returns(bytes32[] memory, uint256[] memory, address[] memory) {
        return getAttributesFreeExcluding(_account, _tokenId, _attribute, new address[](0));
    }

    /// @notice Get all values of an attribute for a passport holder (payable with ERC20)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _tokenAddr address of the ERC20 token to use as a payment
    /// @return all values of the attribute from all issuers
    function getAttributes(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr
    )external override returns(bytes32[] memory, uint256[] memory, address[] memory) {
        return getAttributesExcluding(_account, _tokenId, _attribute, _tokenAddr, new address[](0));
    }

    /// @notice Query the values of an attribute for a passport holder (payable ETH)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _tokenAddr address of the ERC20 token to use as a payment
    /// @param _onlyIssuers The list of issuers to query from. If empty, nothing is returned
    /// @return the values of the attribute from the specified subset list `_issuers` of all issuers
    function getAttributesIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr,
        address[] calldata _onlyIssuers
    ) external override returns(bytes32[] memory, uint256[] memory, address[] memory) {
        _validateAttributeQuery(_account, _tokenId, _attribute);
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) = _applyFilter(_account, _attribute, _includedIssuers(_onlyIssuers));

        _doTokenPayments(_attribute, _tokenAddr, issuers, _account);

        return (attributes, epochs, issuers);
    }

    /// @notice Query the values of an attribute for a passport holder (Free)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _onlyIssuers The list of issuers to query from. If empty, nothing is returned
    /// @return the values of the attribute from the specified subset list `_issuers` of all issuers
    function getAttributesFreeIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external override view returns(bytes32[] memory, uint256[] memory, address[] memory) {
        require(governance.pricePerAttribute(_attribute) == 0, "ATTRIBUTE_NOT_FREE");
        _validateAttributeQuery(_account, _tokenId, _attribute);
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) =  _applyFilter(_account, _attribute, _includedIssuers(_onlyIssuers));

        return (attributes, epochs, issuers);
    }

    /// @notice Query the values of an attribute for a passport holder (Payable ETH)
    /// @param _account address of the passport holder to query
    /// @param _tokenId tokenId of the Passport (1 for now)
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _onlyIssuers The list of issuers to query from. If empty, nothing is returned
    /// @return the values of the attribute from the specified subset list `_issuers` of all issuers
    function getAttributesETHIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external override payable returns(bytes32[] memory, uint256[] memory, address[] memory) {
        _validateAttributeQuery(_account, _tokenId, _attribute);
        (
            bytes32[] memory attributes,
            uint256[] memory epochs,
            address[] memory issuers
        ) = _applyFilter(_account, _attribute, _includedIssuers(_onlyIssuers));

        _doETHPayments(_attribute, issuers, _account);

        return (attributes, epochs, issuers);
    }

    /// @notice removes `_issuers` if they are deactivated
    /// @param _issuers The list of issuers to include
    /// @return `_issuers` - deactivated issuers
    function _includedIssuers(
        address[] calldata _issuers
    ) internal view returns(address[] memory) {
        address[] memory issuers = _issuers;

        uint256 gaps = 0;
        for(uint256 i = 0; i < issuers.length; i++) {
            if(governance.getIssuerStatus(_issuers[i]) == QuadGovernanceStore.IssuerStatus.DEACTIVATED) {
                issuers[i] = address(0);
                gaps++;
            }
        }


        address[] memory newIssuers = new address[](issuers.length - gaps);
        uint256 formattedIndex = 0;
        for(uint256 i = 0; i < issuers.length; i++) {
            if(issuers[i] == address(0)){
                continue;
            }

            newIssuers[formattedIndex++] = issuers[i];
        }

        return newIssuers;
    }

    /// @notice removes `_issuers` from the full list of supported issuers
    /// @param _issuers The list of issuers to remove
    /// @return the subset of `governance.issuers` - `_issuers`
    function _excludedIssuers(
        address[] memory _issuers
    ) internal view returns(address[] memory) {
        QuadGovernanceStore.Issuer[] memory issuerData = governance.getIssuers();
        address[] memory issuers = new address[](governance.getIssuersLength());

        uint256 gaps = 0;
        for(uint256 i = 0; i < issuers.length; i++) {
            if(issuerData[i].status == QuadGovernanceStore.IssuerStatus.DEACTIVATED) {
                gaps++;
                continue;
            }
            issuers[i] = issuerData[i].issuer;
            for(uint256 j = 0; j < _issuers.length; j++) {
                if(issuers[i] == _issuers[j]) {
                    issuers[i] = address(0);
                    gaps++;
                    break;
                }
            }
        }

        // close the gap(s)
        uint256 newLength = governance.getIssuersLength() - gaps;

        address[] memory newIssuers  = new address[](newLength);
        uint256 formattedIndex = 0;
        for(uint256 i = 0; i < issuers.length; i++) {
            if(issuers[i] == address(0)){
                continue;
            }

            newIssuers[formattedIndex++] = issuers[i];
        }
        return newIssuers;
    }

    /// @notice creates a list of attribute values from filtered issuers that have attested to the data
    /// @param _account address of the passport holder to query
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _issuers The list of issuers to query from. If they haven't issued anything, they are removed
    /// @return the filter non-null values
    function _applyFilter(
        address _account,
        bytes32 _attribute,
        address[] memory _issuers
    ) internal view returns (bytes32[] memory, uint256[] memory, address[] memory) {
        // find gap values
        ApplyFilterVars memory vars;
        for(uint256 i = 0; i < _issuers.length; i++) {
            if(governance.eligibleAttributes(_attribute)) {
                if(!_isDataAvailable(_account, _attribute, _issuers[i])) {
                    vars.gaps++;
                }
            } else if(governance.eligibleAttributesByDID(_attribute)) {
                if(!_isDataAvailable(_account,keccak256("DID"),_issuers[i])) {
                    vars.gaps++;
                    continue;
                }
                QuadPassportStore.Attribute memory dID = passport.attributes(_account,keccak256("DID"), _issuers[i]);
                if(!_isDataAvailableByDID(dID.value, _attribute, _issuers[i])) {
                    vars.gaps++;
                }
            }
        }

        vars.delta = _issuers.length - vars.gaps;

        bytes32[] memory attributes = new bytes32[](vars.delta);
        uint256[] memory epochs = new uint256[](vars.delta);
        address[] memory issuers = new address[](vars.delta);

        QuadPassportStore.Attribute memory attribute;
        for(uint256 i = 0; i < _issuers.length; i++) {
            if(governance.eligibleAttributesByDID(_attribute)) {
                if(!_isDataAvailable(_account,keccak256("DID"),_issuers[i])) {
                    continue;
                }
                QuadPassportStore.Attribute memory dID = passport.attributes(_account, keccak256("DID"), _issuers[i]);
                if(!_isDataAvailableByDID(dID.value, _attribute, _issuers[i])) {
                    continue;
                }

                attribute = passport.attributesByDID(dID.value,_attribute, _issuers[i]);
                attributes[vars.filteredIndex] = attribute.value;
                epochs[vars.filteredIndex] = attribute.epoch;
                issuers[vars.filteredIndex] = _issuers[i];
                vars.filteredIndex++;
                continue;
            }

            if(!_isDataAvailable(_account, _attribute, _issuers[i])) {
                continue;
            }

            attribute = passport.attributes(_account,_attribute, _issuers[i]);
            attributes[vars.filteredIndex] = attribute.value;
            epochs[vars.filteredIndex] = attribute.epoch;
            issuers[vars.filteredIndex] = _issuers[i];
            vars.filteredIndex++;
        }

        require(_safetyCheckIssuers(issuers), "NO_DATA_FOUND");

        return (attributes, epochs, issuers);
    }

    /// @notice safty checks for all getAttribute functions
    /// @param _account address of the passport holder to query
    /// @param _tokenId token id of erc1155
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    function _validateAttributeQuery(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) internal view {
        require(_account != address(0), "ACCOUNT_ADDRESS_ZERO");
        require(governance.eligibleTokenId(_tokenId), "PASSPORT_TOKENID_INVALID");
        require(passport.balanceOf(_account, _tokenId) == 1, "PASSPORT_DOES_NOT_EXIST");
        require(governance.eligibleAttributes(_attribute)
            || governance.eligibleAttributesByDID(_attribute),
            "ATTRIBUTE_NOT_ELIGIBLE"
        );
    }

    /// @notice Distrubte the fee to query an attribute to issuers and protocol
    /// @dev If 0 issuers are able to provide data, 100% of fee goes to quadrata
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _issuers The providers of the attributes
    /// @param _account The account used for figuring how much it will cost to query
    function _doETHPayments(
        bytes32 _attribute,
        address[] memory _issuers,
        address _account
    ) internal {
        uint256 amountETH = calculatePaymentETH(_attribute, _account);
        if (amountETH > 0) {
            require(
                 msg.value == amountETH,
                "INSUFFICIENT_PAYMENT_AMOUNT"
            );
            require(
                payable(address(passport)).send(amountETH),
                "FAILED_TO_SEND_PAYMENT"
            );
            uint256 amountIssuer = _issuers.length == 0 ? 0 : amountETH * governance.revSplitIssuer() / 1e2;
            uint256 amountProtocol = amountETH - amountIssuer;
            for(uint256 i = 0; i < _issuers.length; i++) {
                passport.increaseAccountBalanceETH(governance.issuersTreasury(_issuers[i]), amountIssuer / _issuers.length);
            }
            passport.increaseAccountBalanceETH(governance.treasury(), amountProtocol);
        }
    }

    /// @notice Distrubte the fee to query an attribute to issuers and protocol
    /// @dev If 0 issuers are able to provide data, 100% of fee goes to quadrata
    /// @param _attribute keccak256 of the attribute type to query (ex: keccak256("DID"))
    /// @param _tokenPayment address of erc20 payment method
    /// @param _issuers The providers of the attributes
    /// @param _account The account used for figuring how much it will cost to query
    function _doTokenPayments(
        bytes32 _attribute,
        address _tokenPayment,
        address[] memory _issuers,
        address _account
    ) internal {
        uint256 amountToken = calculatePaymentToken(_attribute, _tokenPayment, _account);
        if (amountToken > 0) {
            IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(_tokenPayment);
            require(
                erc20.transferFrom(msg.sender, address(passport), amountToken),
                "INSUFFICIENT_PAYMENT_ALLOWANCE"
            );
            uint256 amountIssuer = _issuers.length == 0 ? 0 : amountToken * governance.revSplitIssuer() / 10 ** 2;
            uint256 amountProtocol = amountToken - amountIssuer;
            for(uint256 i = 0; i < _issuers.length; i++) {
                passport.increaseAccountBalance(_tokenPayment,governance.issuersTreasury(_issuers[i]), amountIssuer / _issuers.length);
            }
            passport.increaseAccountBalance(_tokenPayment, governance.treasury(), amountProtocol);
        }
    }


    /// @dev Calculate the amount of token required to call `getAttribute`
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @param _tokenPayment address of the ERC20 tokens to use as payment
    /// @param _account account getting requested for attributes
    /// @return the amount of ERC20 necessary to query the attribute
    function calculatePaymentToken(
        bytes32 _attribute,
        address _tokenPayment,
        address _account
    ) public override view returns(uint256) {
        IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(_tokenPayment);
        uint256 tokenPrice = governance.getPrice(_tokenPayment);

        uint256 price = _issuersContain(_account,keccak256("IS_BUSINESS")) == keccak256("TRUE") ? governance.pricePerBusinessAttribute(_attribute) : governance.pricePerAttribute(_attribute);
        // Convert to Token Decimal
        uint256 amountToken = (price * (10 ** (erc20.decimals())) / tokenPrice) ;
        return amountToken;
    }

    /// @dev Calculate the amount of $ETH required to call `getAttributeETH`
    /// @param _attribute keccak256 of the attribute type (ex: keccak256("COUNTRY"))
    /// @param _account account getting requested for attributes
    /// @return the amount of $ETH necessary to query the attribute
    function calculatePaymentETH(
        bytes32 _attribute,
        address _account
    ) public override view returns(uint256) {
        uint256 tokenPrice = governance.getPriceETH();
        uint256 price = _issuersContain(_account,keccak256("IS_BUSINESS")) == keccak256("TRUE") ? governance.pricePerBusinessAttribute(_attribute) : governance.pricePerAttribute(_attribute);
        uint256 amountETH = (price * 1e18 / tokenPrice) ;
        return amountETH;
    }

    /// @dev Used to determine if issuer has returned something useful
    /// @param _account the value to check existence on
    /// @param _attribute the value to check existence on
    /// @param _issuer the issuer in question
    /// @return whether or not we found a value
    function _isDataAvailable(
        address _account,
        bytes32 _attribute,
        address _issuer
    ) internal view returns(bool) {
        QuadPassportStore.Attribute memory attrib = passport.attributes(_account, _attribute, _issuer);
        return attrib.value != bytes32(0) && attrib.epoch != 0;
    }

    /// @dev Used to determine if issuer has returned something useful
    /// @param _dID the value to check existsance on
    /// @param _attribute the value to check existsance on
    /// @param _issuer the issuer in question
    /// @return whether or not we found a value
    function _isDataAvailableByDID(
        bytes32 _dID,
        bytes32 _attribute,
        address _issuer
    ) internal view returns(bool) {
        QuadPassportStore.Attribute memory attrib = passport.attributesByDID(_dID, _attribute, _issuer);
        return attrib.value != bytes32(0) && attrib.epoch != 0;
    }

    /// @dev Used to determine if issuers have an attribute
    /// @param _attribute the value to check existsance on
    /// @param _account account getting requested for attributes
    /// @return unique bytes32 hash or bytes32(0) if issuers have the attribute
    function _issuersContain(
        address _account,
        bytes32 _attribute
    ) internal view returns(bytes32) {
        for(uint256 i = 0; i < governance.getIssuersLength(); i++) {
            bytes32 value = passport.attributes(_account, _attribute, governance.issuers(i).issuer).value;
            if(value != bytes32(0)) {
                return value;
            }
        }
        return bytes32(0);
    }

    /// @dev Used to determine if any of the attributes is valid
    /// @param _issuers the value to check existsance on
    /// @return whether or not we found a value
    function _safetyCheckIssuers(
        address[] memory _issuers
    ) internal pure returns(bool) {
        for(uint256 i = 0; i < _issuers.length; i++) {
            if(_issuers[i] == address(0))
                return false;
        }
        return true;
    }
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC1155/IERC1155Upgradeable.sol";
import "../storage/QuadPassportStore.sol";

interface IQuadPassport is IERC1155Upgradeable {

    function mintPassport(
        QuadPassportStore.MintConfig calldata config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttribute(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt,
        bytes calldata _sig
    ) external payable;

    function setAttributeIssuer(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt
    ) external ;

    function burnPassport(uint256 _tokenId) external;

    function burnPassportIssuer(address _account, uint256 _tokenId) external;

    function setGovernance(address _governanceContract) external;

    function withdrawETH(address payable _to) external returns (uint256);

    function withdrawToken(address payable _to, address _token)
        external
        returns (uint256);


    function attributes(address, bytes32, address) external view returns (QuadPassportStore.Attribute memory);

    function attributesByDID(bytes32, bytes32, address) external view returns (QuadPassportStore.Attribute memory);

    function increaseAccountBalanceETH(address, uint256) external;

    function increaseAccountBalance(address, address, uint256) external;



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/QuadGovernanceStore.sol";

interface IQuadGovernance {
    function setTreasury(address _treasury) external;

    function setPassportContractAddress(address _passportAddr) external;

    function updateGovernanceInPassport(address _newGovernance) external;

    function setPassportVersion(uint256 _version) external;

    function setMintPrice(uint256 _mintPrice) external;

    function setEligibleTokenId(uint256 _tokenId, bool _eligibleStatus) external;

    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) external;

    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) external;

    function setAttributePrice(bytes32 _attribute, uint256 _price) external;

    function setBusinessAttributePrice(bytes32 _attribute, uint256 _price) external;

    function setAttributeMintPrice(bytes32 _attribute, uint256 _price) external;

     function setOracle(address _oracleAddr) external;

     function setRevSplitIssuer(uint256 _split) external;

     function setIssuer(address _issuer, address _treasury) external;

     function deleteIssuer(address _issuer) external;

     function allowTokenPayment(
        address _tokenAddr,
        bool _isAllowed
    ) external;

    function getEligibleAttributesLength() external view returns(uint256);

    function getPrice(address _tokenAddr) external view returns (uint);

    function getPriceETH() external view returns (uint);

    function mintPrice() external view returns (uint256);

    function eligibleTokenId(uint256) external view returns(bool);

    function issuersTreasury(address) external view returns (address);

    function mintPricePerAttribute(bytes32) external view returns(uint256);

    function eligibleAttributes(bytes32) external view returns(bool);

    function eligibleAttributesByDID(bytes32) external view returns(bool);

    function eligibleAttributesArray(uint256) external view returns(bytes32);

    function pricePerAttribute(bytes32) external view returns(uint256);

    function pricePerBusinessAttribute(bytes32) external view returns(uint256);

    function revSplitIssuer() external view returns (uint256);

    function treasury() external view returns (address);

    function hasRole(bytes32, address) external view returns(bool);

    function getIssuersLength() external view returns (uint256);

    function getIssuers() external view returns (QuadGovernanceStore.Issuer[] memory);

    function issuers(uint256) external view returns(QuadGovernanceStore.Issuer memory);

    function getIssuerStatus(address _issuer) external view returns(QuadGovernanceStore.IssuerStatus);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IQuadReader {

    function getAttributesExcluding(
            address _account,
            uint256 _tokenId,
            bytes32 _attribute,
            address _tokenAddr,
            address[] calldata _excludedIssuers
        ) external returns(bytes32[] memory, uint256[] memory, address[] memory);


    function getAttributesFreeExcluding(
            address _account,
            uint256 _tokenId,
            bytes32 _attribute,
            address[] calldata _excludedIssuers
        ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);


    function getAttributesETHExcluding(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _excludedIssuers
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesETH(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesFree(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributes(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr
    ) external returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr,
        address[] calldata _onlyIssuers
    ) external returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesFreeIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesETHIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function calculatePaymentToken(
        bytes32 _attribute,
        address _tokenPayment,
        address _account
    ) external view returns(uint256);

    function calculatePaymentETH(
        bytes32 _attribute,
        address _account
    ) external view returns(uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IQuadPassport.sol";
import "../interfaces/IQuadGovernance.sol";

contract QuadReaderStore {

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    IQuadGovernance public governance;
    IQuadPassport public passport;

    struct ApplyFilterVars {
        uint256 gaps;
        uint256 delta;
        uint256 filteredIndex;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IQuadPassport.sol";
import "../interfaces/IQuadGovernance.sol";

contract QuadPassportStore {

    struct Attribute {
        bytes32 value;
        uint256 epoch;
    }

    /// @dev MintConfig is defined to prevent 'stack frame too deep' during compilation
    /// @notice This struct is used to abstract mintPassport function parameters
    /// `account` EOA/Contract to mint the passport
    /// `tokenId` tokenId of the Passport (1 for now)
    /// `quadDID` Quadrata Decentralized Identity (raw value)
    /// `aml` keccak256 of the AML status value
    /// `country` keccak256 of the country value
    /// `isBusiness` flag identifying if a wallet is a business or individual
    /// `issuedAt` epoch when the passport has been issued by the Issuer
    struct MintConfig {
        address account;
        uint256 tokenId;
        bytes32 quadDID;
        bytes32 aml;
        bytes32 country;
        bytes32 isBusiness;
        uint256 issuedAt;
    }


    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");

    IQuadGovernance public governance;

    // Hash => bool
    mapping(bytes32 => bool) internal _usedHashes;

    // Passport attributes
    // Wallet => (Attribute Name => (Issuer => Attribute))
    mapping(address => mapping(bytes32 => mapping(address => Attribute))) internal _attributes;
    // DID => (AttributeType => (Issuer => Attribute(value, epoch)))
    mapping(bytes32 => mapping(bytes32 => mapping(address => Attribute))) internal _attributesByDID;

    // Accounting
    // ERC20 => Account => balance
    mapping(address => mapping(address => uint256)) internal _accountBalances;
    mapping(address => uint256) internal _accountBalancesETH;


    string public symbol;
    string public name;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IQuadPassport.sol";

contract QuadGovernanceStore {

    struct Config {
        uint256  revSplitIssuer; // 50 means 50%;
        uint256  passportVersion;
        uint256  mintPrice; // Price in $ETH
        IQuadPassport  passport;
        address  oracle;
        address  treasury;
    }

    enum IssuerStatus {
        ACTIVE,
        DEACTIVATED
    }

    struct Issuer {
        address issuer;
        IssuerStatus status;
        // TODO: should we add `bytes data;` in the struct
    }

    // Admin Functions
    bytes32[] public eligibleAttributesArray;
    mapping(uint256 => bool) public eligibleTokenId;
    mapping(bytes32 => bool) public eligibleAttributes;
    mapping(bytes32 => bool) public eligibleAttributesByDID;
    // Price in $USD (1e6 decimals)
    mapping(bytes32 => uint256) public pricePerAttribute;
    // Price in $ETH
    mapping(bytes32 => uint256) public mintPricePerAttribute;

    mapping(address => bool) public eligibleTokenPayments;
    mapping(address => address) public issuersTreasury;

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");

    Config public config;

    mapping(bytes32 => uint256) public pricePerBusinessAttribute;

    Issuer[] public issuers;
    mapping(address => uint256) internal issuerIndices;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {

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