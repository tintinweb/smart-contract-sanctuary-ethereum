// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ZoraProtocolFeeSettings} from "./auxiliary/ZoraProtocolFeeSettings/ZoraProtocolFeeSettings.sol";

/// @title ZoraModuleManager
/// @author tbtstl <[email protected]>
/// @notice This contract allows users to approve registered modules on ZORA V3
contract ZoraModuleManager {
    /// @notice The EIP-712 type for a signed approval
    /// @dev keccak256("SignedApproval(address module,address user,bool approved,uint256 deadline,uint256 nonce)")
    bytes32 private constant SIGNED_APPROVAL_TYPEHASH = 0x8413132cc7aa5bd2ce1a1b142a3f09e2baeda86addf4f9a5dacd4679f56e7cec;

    /// @notice The EIP-712 domain separator
    bytes32 private immutable EIP_712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ZORA")),
                keccak256(bytes("3")),
                _chainID(),
                address(this)
            )
        );

    /// @notice The module fee NFT contract to mint from upon module registration
    ZoraProtocolFeeSettings public immutable moduleFeeToken;

    /// @notice The registrar address that can register modules
    address public registrar;

    /// @notice Mapping of users and modules to approved status
    /// @dev User address => Module address => Approved
    mapping(address => mapping(address => bool)) public userApprovals;

    /// @notice Mapping of modules to registered status
    /// @dev Module address => Registered
    mapping(address => bool) public moduleRegistered;

    /// @notice The signature nonces for 3rd party module approvals
    mapping(address => uint256) public sigNonces;

    /// @notice Ensures only the registrar can register modules
    modifier onlyRegistrar() {
        require(msg.sender == registrar, "ZMM::onlyRegistrar must be registrar");
        _;
    }

    /// @notice Emitted when a user's module approval is updated
    /// @param user The address of the user
    /// @param module The address of the module
    /// @param approved Whether the user added or removed approval
    event ModuleApprovalSet(address indexed user, address indexed module, bool approved);

    /// @notice Emitted when a module is registered
    /// @param module The address of the module
    event ModuleRegistered(address indexed module);

    /// @notice Emitted when the registrar address is updated
    /// @param newRegistrar The address of the new registrar
    event RegistrarChanged(address indexed newRegistrar);

    /// @param _registrar The initial registrar for the manager
    /// @param _feeToken The module fee token contract to mint from upon module registration
    constructor(address _registrar, address _feeToken) {
        require(_registrar != address(0), "ZMM::must set registrar to non-zero address");

        registrar = _registrar;
        moduleFeeToken = ZoraProtocolFeeSettings(_feeToken);
    }

    /// @notice Returns true if the user has approved a given module, false otherwise
    /// @param _user The user to check approvals for
    /// @param _module The module to check approvals for
    /// @return True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module) external view returns (bool) {
        return userApprovals[_user][_module];
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |             ,-----------------.
    //        / \            |ZoraModuleManager|
    //      Caller           `--------+--------'
    //        | setApprovalForModule()|
    //        | ---------------------->
    //        |                       |
    //        |                       |----.
    //        |                       |    | set approval for module
    //        |                       |<---'
    //        |                       |
    //        |                       |----.
    //        |                       |    | emit ModuleApprovalSet()
    //        |                       |<---'
    //      Caller           ,--------+--------.
    //        ,-.            |ZoraModuleManager|
    //        `-'            `-----------------'
    //        /|\
    //         |
    //        / \
    /// @notice Allows a user to set the approval for a given module
    /// @param _module The module to approve
    /// @param _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _module, bool _approved) public {
        _setApprovalForModule(_module, msg.sender, _approved);
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |                  ,-----------------.
    //        / \                 |ZoraModuleManager|
    //      Caller                `--------+--------'
    //        | setBatchApprovalForModule()|
    //        | --------------------------->
    //        |                            |
    //        |                            |
    //        |         _____________________________________________________
    //        |         ! LOOP  /  for each module                           !
    //        |         !______/           |                                 !
    //        |         !                  |----.                            !
    //        |         !                  |    | set approval for module    !
    //        |         !                  |<---'                            !
    //        |         !                  |                                 !
    //        |         !                  |----.                            !
    //        |         !                  |    | emit ModuleApprovalSet()   !
    //        |         !                  |<---'                            !
    //        |         !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //      Caller                ,--------+--------.
    //        ,-.                 |ZoraModuleManager|
    //        `-'                 `-----------------'
    //        /|\
    //         |
    //        / \
    /// @notice Sets approvals for multiple modules at once
    /// @param _modules The list of module addresses to set approvals for
    /// @param _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(address[] memory _modules, bool _approved) public {
        // Store the number of module addresses provided
        uint256 numModules = _modules.length;

        // Loop through each address
        for (uint256 i = 0; i < numModules; ) {
            // Ensure that it's a registered module and set the approval
            _setApprovalForModule(_modules[i], msg.sender, _approved);

            // Cannot overflow as array length cannot exceed uint256 max
            unchecked {
                ++i;
            }
        }
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |                  ,-----------------.
    //        / \                 |ZoraModuleManager|
    //      Caller                `--------+--------'
    //        | setApprovalForModuleBySig()|
    //        | --------------------------->
    //        |                            |
    //        |                            |----.
    //        |                            |    | recover user address from signature
    //        |                            |<---'
    //        |                            |
    //        |                            |----.
    //        |                            |    | set approval for module
    //        |                            |<---'
    //        |                            |
    //        |                            |----.
    //        |                            |    | emit ModuleApprovalSet()
    //        |                            |<---'
    //      Caller                ,--------+--------.
    //        ,-.                 |ZoraModuleManager|
    //        `-'                 `-----------------'
    //        /|\
    //         |
    //        / \
    /// @notice Sets approval for a module given an EIP-712 signature
    /// @param _module The module to approve
    /// @param _user The user to approve the module for
    /// @param _approved A boolean, whether or not to approve a module
    /// @param _deadline The deadline at which point the given signature expires
    /// @param _v The 129th byte and chain ID of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function setApprovalForModuleBySig(
        address _module,
        address _user,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(_deadline == 0 || _deadline >= block.timestamp, "ZMM::setApprovalForModuleBySig deadline expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP_712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(SIGNED_APPROVAL_TYPEHASH, _module, _user, _approved, _deadline, sigNonces[_user]++))
            )
        );

        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        require(recoveredAddress != address(0) && recoveredAddress == _user, "ZMM::setApprovalForModuleBySig invalid signature");

        _setApprovalForModule(_module, _user, _approved);
    }

    //         ,-.
    //         `-'
    //         /|\
    //          |               ,-----------------.          ,-----------------------.
    //         / \              |ZoraModuleManager|          |ZoraProtocolFeeSettings|
    //      Registrar           `--------+--------'          `-----------+-----------'
    //          |   registerModule()     |                               |
    //          |----------------------->|                               |
    //          |                        |                               |
    //          |                        ----.                           |
    //          |                            | register module           |
    //          |                        <---'                           |
    //          |                        |                               |
    //          |                        |            mint()             |
    //          |                        |------------------------------>|
    //          |                        |                               |
    //          |                        |                               ----.
    //          |                        |                                   | mint token to registrar
    //          |                        |                               <---'
    //          |                        |                               |
    //          |                        ----.                           |
    //          |                            | emit ModuleRegistered()   |
    //          |                        <---'                           |
    //      Registrar           ,--------+--------.          ,-----------+-----------.
    //         ,-.              |ZoraModuleManager|          |ZoraProtocolFeeSettings|
    //         `-'              `-----------------'          `-----------------------'
    //         /|\
    //          |
    //         / \
    /// @notice Registers a module
    /// @param _module The address of the module
    function registerModule(address _module) public onlyRegistrar {
        require(!moduleRegistered[_module], "ZMM::registerModule module already registered");

        moduleRegistered[_module] = true;
        moduleFeeToken.mint(registrar, _module);

        emit ModuleRegistered(_module);
    }

    //         ,-.
    //         `-'
    //         /|\
    //          |               ,-----------------.
    //         / \              |ZoraModuleManager|
    //      Registrar           `--------+--------'
    //          |    setRegistrar()      |
    //          |----------------------->|
    //          |                        |
    //          |                        ----.
    //          |                            | set registrar
    //          |                        <---'
    //          |                        |
    //          |                        ----.
    //          |                            | emit RegistrarChanged()
    //          |                        <---'
    //      Registrar           ,--------+--------.
    //         ,-.              |ZoraModuleManager|
    //         `-'              `-----------------'
    //         /|\
    //          |
    //         / \
    /// @notice Sets the registrar for the ZORA Module Manager
    /// @param _registrar the address of the new registrar
    function setRegistrar(address _registrar) public onlyRegistrar {
        require(_registrar != address(0), "ZMM::setRegistrar must set registrar to non-zero address");
        registrar = _registrar;

        emit RegistrarChanged(_registrar);
    }

    /// @notice Updates a module approval for a user
    /// @param _module The address of the module
    /// @param _user The address of the user
    /// @param _approved Whether the user is adding or removing approval
    function _setApprovalForModule(
        address _module,
        address _user,
        bool _approved
    ) private {
        require(moduleRegistered[_module], "ZMM::must be registered module");

        userApprovals[_user][_module] = _approved;

        emit ModuleApprovalSet(msg.sender, _module, _approved);
    }

    /// @notice The EIP-155 chain id
    function _chainID() private view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721TokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title ZoraProtocolFeeSettings
/// @author tbtstl <[email protected]>
/// @notice This contract allows an optional fee percentage and recipient to be set for individual ZORA modules
contract ZoraProtocolFeeSettings is ERC721 {
    /// @notice The address of the contract metadata
    address public metadata;
    /// @notice The address of the contract owner
    address public owner;
    /// @notice The address of the ZORA Module Manager
    address public minter;

    /// @notice The metadata of a module fee setting
    /// @param feeBps The basis points fee
    /// @param feeRecipient The recipient of the fee
    struct FeeSetting {
        uint16 feeBps;
        address feeRecipient;
    }

    /// @notice Mapping of modules to fee settings
    /// @dev Module address => FeeSetting
    mapping(address => FeeSetting) public moduleFeeSetting;

    /// @notice Ensures only the owner of a module fee NFT can set its fee
    /// @param _module The address of the module
    modifier onlyModuleOwner(address _module) {
        uint256 tokenId = moduleToTokenId(_module);
        require(ownerOf(tokenId) == msg.sender, "onlyModuleOwner");
        _;
    }

    /// @notice Emitted when the fee for a module is updated
    /// @param module The address of the module
    /// @param feeRecipient The address of the fee recipient
    /// @param feeBps The basis points of the fee
    event ProtocolFeeUpdated(address indexed module, address feeRecipient, uint16 feeBps);

    /// @notice Emitted when the contract metadata is updated
    /// @param newMetadata The address of the new metadata
    event MetadataUpdated(address indexed newMetadata);

    /// @notice Emitted when the contract owner is updated
    /// @param newOwner The address of the new owner
    event OwnerUpdated(address indexed newOwner);

    constructor() ERC721("ZORA Module Fee Switch", "ZORF") {
        _setOwner(msg.sender);
    }

    /// @notice Initialize the Protocol Fee Settings
    /// @param _minter The address that can mint new NFTs (expected ZoraModuleManager address)
    function init(address _minter, address _metadata) external {
        require(msg.sender == owner, "init only owner");
        require(minter == address(0), "init already initialized");

        minter = _minter;
        metadata = _metadata;
    }

    //        ,-.
    //        `-'
    //        /|\
    //         |             ,-----------------------.
    //        / \            |ZoraProtocolFeeSettings|
    //      Minter           `-----------+-----------'
    //        |          mint()          |
    //        | ------------------------>|
    //        |                          |
    //        |                          ----.
    //        |                              | derive token ID from module address
    //        |                          <---'
    //        |                          |
    //        |                          ----.
    //        |                              | mint token to given address
    //        |                          <---'
    //        |                          |
    //        |     return token ID      |
    //        | <------------------------|
    //      Minter           ,-----------+-----------.
    //        ,-.            |ZoraProtocolFeeSettings|
    //        `-'            `-----------------------'
    //        /|\
    //         |
    //        / \
    /// @notice Mint a new protocol fee setting for a module
    /// @param _to The address to send the protocol fee setting token to
    /// @param _module The module for which the minted token will represent
    function mint(address _to, address _module) external returns (uint256) {
        require(msg.sender == minter, "mint onlyMinter");
        uint256 tokenId = moduleToTokenId(_module);
        _mint(_to, tokenId);

        return tokenId;
    }

    //          ,-.
    //          `-'
    //          /|\
    //           |                ,-----------------------.
    //          / \               |ZoraProtocolFeeSettings|
    //      ModuleOwner           `-----------+-----------'
    //           |      setFeeParams()        |
    //           |--------------------------->|
    //           |                            |
    //           |                            ----.
    //           |                                | set fee parameters
    //           |                            <---'
    //           |                            |
    //           |                            ----.
    //           |                                | emit ProtocolFeeUpdated()
    //           |                            <---'
    //      ModuleOwner           ,-----------+-----------.
    //          ,-.               |ZoraProtocolFeeSettings|
    //          `-'               `-----------------------'
    //          /|\
    //           |
    //          / \
    /// @notice Sets fee parameters for a module fee NFT
    /// @param _module The module to apply the fee settings to
    /// @param _feeRecipient The fee recipient address to send fees to
    /// @param _feeBps The bps of transaction value to send to the fee recipient
    function setFeeParams(
        address _module,
        address _feeRecipient,
        uint16 _feeBps
    ) external onlyModuleOwner(_module) {
        require(_feeBps <= 10000, "setFeeParams must set fee <= 100%");
        require(_feeRecipient != address(0) || _feeBps == 0, "setFeeParams fee recipient cannot be 0 address if fee is greater than 0");

        moduleFeeSetting[_module] = FeeSetting(_feeBps, _feeRecipient);

        emit ProtocolFeeUpdated(_module, _feeRecipient, _feeBps);
    }

    //       ,-.
    //       `-'
    //       /|\
    //        |             ,-----------------------.
    //       / \            |ZoraProtocolFeeSettings|
    //      Owner           `-----------+-----------'
    //        |       setOwner()        |
    //        |------------------------>|
    //        |                         |
    //        |                         ----.
    //        |                             | set owner
    //        |                         <---'
    //        |                         |
    //        |                         ----.
    //        |                             | emit OwnerUpdated()
    //        |                         <---'
    //      Owner           ,-----------+-----------.
    //       ,-.            |ZoraProtocolFeeSettings|
    //       `-'            `-----------------------'
    //       /|\
    //        |
    //       / \
    /// @notice Sets the owner of the contract
    /// @param _owner The address of the owner
    function setOwner(address _owner) external {
        require(msg.sender == owner, "setOwner onlyOwner");
        _setOwner(_owner);
    }

    //       ,-.
    //       `-'
    //       /|\
    //        |             ,-----------------------.
    //       / \            |ZoraProtocolFeeSettings|
    //      Owner           `-----------+-----------'
    //        |     setMetadata()       |
    //        |------------------------>|
    //        |                         |
    //        |                         ----.
    //        |                             | set metadata
    //        |                         <---'
    //        |                         |
    //        |                         ----.
    //        |                             | emit MetadataUpdated()
    //        |                         <---'
    //      Owner           ,-----------+-----------.
    //       ,-.            |ZoraProtocolFeeSettings|
    //       `-'            `-----------------------'
    //       /|\
    //        |
    //       / \
    /// @notice Sets the metadata of the contract
    /// @param _metadata The address of the metadata
    function setMetadata(address _metadata) external {
        require(msg.sender == owner, "setMetadata onlyOwner");
        _setMetadata(_metadata);
    }

    /// @notice Computes the fee for a given uint256 amount
    /// @param _module The module to compute the fee for
    /// @param _amount The amount to compute the fee for
    /// @return The amount to be paid out to the fee recipient
    function getFeeAmount(address _module, uint256 _amount) external view returns (uint256) {
        return (_amount * moduleFeeSetting[_module].feeBps) / 10000;
    }

    /// @notice Returns the module address for a given token ID
    /// @param _tokenId The token ID
    /// @return The module address
    function tokenIdToModule(uint256 _tokenId) public pure returns (address) {
        return address(uint160(_tokenId));
    }

    /// @notice Returns the token ID for a given module
    /// @dev We don't worry about losing the top 20 bytes when going from uint256 -> uint160 since we know token ID must have derived from an address
    /// @param _module The module address
    /// @return The token ID
    function moduleToTokenId(address _module) public pure returns (uint256) {
        return uint256(uint160(_module));
    }

    /// @notice Returns the token URI for a given token ID
    /// @param _tokenId The token ID
    /// @return The token URI
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(metadata != address(0), "ERC721Metadata: no metadata address");

        return IERC721TokenURI(metadata).tokenURI(_tokenId);
    }

    /// @notice Sets the contract metadata in `setMetadata`
    /// @param _metadata The address of the metadata
    function _setMetadata(address _metadata) private {
        metadata = _metadata;

        emit MetadataUpdated(_metadata);
    }

    /// @notice Sets the contract owner in `setOwner`
    /// @param _owner The address of the owner
    function _setOwner(address _owner) private {
        owner = _owner;

        emit OwnerUpdated(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IRoyaltyEngineV1} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ZoraProtocolFeeSettings} from "../../auxiliary/ZoraProtocolFeeSettings/ZoraProtocolFeeSettings.sol";
import {OutgoingTransferSupportV1} from "../OutgoingTransferSupport/V1/OutgoingTransferSupportV1.sol";

/// @title FeePayoutSupportV1
/// @author tbtstl <[email protected]>
/// @notice This contract extension supports paying out protocol fees and royalties
contract FeePayoutSupportV1 is OutgoingTransferSupportV1 {
    /// @notice The ZORA Module Registrar
    address public immutable registrar;

    /// @notice The ZORA Protocol Fee Settings
    ZoraProtocolFeeSettings immutable protocolFeeSettings;

    /// @notice The Manifold Royalty Engine
    IRoyaltyEngineV1 royaltyEngine;

    /// @notice Emitted when royalties are paid
    /// @param tokenContract The ERC-721 token address of the royalty payout
    /// @param tokenId The ERC-721 token ID of the royalty payout
    /// @param recipient The recipient address of the royalty
    /// @param amount The amount paid to the recipient
    event RoyaltyPayout(address indexed tokenContract, uint256 indexed tokenId, address recipient, uint256 amount);

    /// @param _royaltyEngine The Manifold Royalty Engine V1 address
    /// @param _protocolFeeSettings The ZoraProtocolFeeSettingsV1 address
    /// @param _wethAddress WETH address
    /// @param _registrarAddress The Registrar address, who can update the royalty engine address
    constructor(
        address _royaltyEngine,
        address _protocolFeeSettings,
        address _wethAddress,
        address _registrarAddress
    ) OutgoingTransferSupportV1(_wethAddress) {
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        protocolFeeSettings = ZoraProtocolFeeSettings(_protocolFeeSettings);
        registrar = _registrarAddress;
    }

    /// @notice Update the address of the Royalty Engine, in case of unexpected update on Manifold's Proxy
    /// @dev emergency use only – requires a frozen RoyaltyEngineV1 at commit 4ae77a73a8a73a79d628352d206fadae7f8e0f74
    ///  to be deployed elsewhere, or a contract matching that ABI
    /// @param _royaltyEngine The address for the new royalty engine
    function setRoyaltyEngineAddress(address _royaltyEngine) public {
        require(msg.sender == registrar, "setRoyaltyEngineAddress only registrar");
        require(
            ERC165Checker.supportsInterface(_royaltyEngine, type(IRoyaltyEngineV1).interfaceId),
            "setRoyaltyEngineAddress must match IRoyaltyEngineV1 interface"
        );
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    /// @notice Pays out the protocol fee to its fee recipient
    /// @param _amount The sale amount
    /// @param _payoutCurrency The currency to pay the fee
    /// @return The remaining funds after paying the protocol fee
    function _handleProtocolFeePayout(uint256 _amount, address _payoutCurrency) internal returns (uint256) {
        // Get fee for this module
        uint256 protocolFee = protocolFeeSettings.getFeeAmount(address(this), _amount);

        // If no fee, return initial amount
        if (protocolFee == 0) return _amount;

        // Get fee recipient
        (, address feeRecipient) = protocolFeeSettings.moduleFeeSetting(address(this));

        // Payout protocol fee
        _handleOutgoingTransfer(feeRecipient, protocolFee, _payoutCurrency, 50000);

        // Return remaining amount
        return _amount - protocolFee;
    }

    /// @notice Pays out royalties for given NFTs
    /// @param _tokenContract The NFT contract address to get royalty information from
    /// @param _tokenId, The Token ID to get royalty information from
    /// @param _amount The total sale amount
    /// @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
    /// @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
    /// @return The remaining funds after paying out royalties
    function _handleRoyaltyPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 _gasLimit
    ) internal returns (uint256, bool) {
        // If no gas limit was provided or provided gas limit greater than gas left, just pass the remaining gas.
        uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;

        // External call ensuring contract doesn't run out of gas paying royalties
        try this._handleRoyaltyEnginePayout{gas: gas}(_tokenContract, _tokenId, _amount, _payoutCurrency) returns (uint256 remainingFunds) {
            // Return remaining amount if royalties payout succeeded
            return (remainingFunds, true);
        } catch {
            // Return initial amount if royalties payout failed
            return (_amount, false);
        }
    }

    /// @notice Pays out royalties for NFTs based on the information returned by the royalty engine
    /// @dev This method is external to enable setting a gas limit when called - see `_handleRoyaltyPayout`.
    /// @param _tokenContract The NFT Contract to get royalty information from
    /// @param _tokenId, The Token ID to get royalty information from
    /// @param _amount The total sale amount
    /// @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
    /// @return The remaining funds after paying out royalties
    function _handleRoyaltyEnginePayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) external payable returns (uint256) {
        // Ensure the caller is the contract
        require(msg.sender == address(this), "_handleRoyaltyEnginePayout only self callable");

        // Get the royalty recipients and their associated amounts
        (address payable[] memory recipients, uint256[] memory amounts) = royaltyEngine.getRoyalty(_tokenContract, _tokenId, _amount);

        // Store the number of recipients
        uint256 numRecipients = recipients.length;

        // If there are no royalties, return the initial amount
        if (numRecipients == 0) return _amount;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient and amount
        address recipient;
        uint256 amount;

        // Payout each royalty
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            recipient = recipients[i];
            amount = amounts[i];

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            _handleOutgoingTransfer(recipient, amount, _payoutCurrency, 50000);

            emit RoyaltyPayout(_tokenContract, _tokenId, recipient, amount);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to royalty amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        return amountRemaining;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Module Naming Support V1
/// @author kulkarohan <[email protected]>
/// @notice This contract extension supports naming modules
contract ModuleNamingSupportV1 {
    /// @notice The module name
    string public name;

    /// @notice Sets the name of a module
    /// @param _name The module name to set
    constructor(string memory _name) {
        name = _name;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH} from "./IWETH.sol";

/// @title OutgoingTransferSupportV1
/// @author tbtstl <[email protected]>
/// @notice This contract extension supports paying out funds to an external recipient
contract OutgoingTransferSupportV1 {
    using SafeERC20 for IERC20;

    IWETH immutable weth;

    constructor(address _wethAddress) {
        weth = IWETH(_wethAddress);
    }

    /// @notice Handle an outgoing funds transfer
    /// @dev Wraps ETH in WETH if the receiver cannot receive ETH, noop if the funds to be sent are 0 or recipient is invalid
    /// @param _dest The destination for the funds
    /// @param _amount The amount to be sent
    /// @param _currency The currency to send funds in, or address(0) for ETH
    /// @param _gasLimit The gas limit to use when attempting a payment (if 0, gasleft() is used)
    function _handleOutgoingTransfer(
        address _dest,
        uint256 _amount,
        address _currency,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0 || _dest == address(0)) {
            return;
        }

        // Handle ETH payment
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "_handleOutgoingTransfer insolvent");

            // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
            uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;
            (bool success, ) = _dest.call{value: _amount, gas: gas}("");
            // If the ETH transfer fails (sigh), wrap the ETH and try send it as WETH.
            if (!success) {
                weth.deposit{value: _amount}();
                IERC20(address(weth)).safeTransfer(_dest, _amount);
            }
        } else {
            IERC20(_currency).safeTransfer(_dest, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @title IReserveAuctionListingAdjustableBufferIncrementEth
/// @author jgeary
/// @notice Interface for Reserve Auction w/ Listing Fee, Adjustable Buffer & Increment ETH
interface IReserveAuctionListingAdjustableBufferIncrementEth {
    /// @notice Creates an auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    /// @param _duration The length of time the auction should run after the first bid
    /// @param _reservePrice The minimum bid amount to start the auction
    /// @param _sellerFundsRecipient The address to send funds to once the auction is complete
    /// @param _startTime The time that users can begin placing bids
    /// @param _listingFeeBps The fee to send to the lister of the auction
    /// @param _listingFeeRecipient The address listing the auction
    /// @param _timeBuffer Time buffer in seconds
    /// @param _percentIncrement The minimum percent increase for a new bid
    function createAuction(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _reservePrice,
        address _sellerFundsRecipient,
        uint256 _startTime,
        uint256 _listingFeeBps,
        address _listingFeeRecipient,
        uint16 _timeBuffer,
        uint8 _percentIncrement
    ) external;

    /// @notice Updates the reserve price for a given auction
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    /// @param _reservePrice The new reserve price
    function setAuctionReservePrice(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external;

    /// @notice Cancels the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function cancelAuction(address _tokenContract, uint256 _tokenId) external;

    /// @notice Places a bid on the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function createBid(address _tokenContract, uint256 _tokenId) external payable;

    /// @notice Ends the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function settleAuction(address _tokenContract, uint256 _tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721TransferHelper} from "../../../../transferHelpers/ERC721TransferHelper.sol";
import {FeePayoutSupportV1} from "../../../../common/FeePayoutSupport/FeePayoutSupportV1.sol";
import {ModuleNamingSupportV1} from "../../../../common/ModuleNamingSupport/ModuleNamingSupportV1.sol";
import {IReserveAuctionListingAdjustableBufferIncrementEth} from "./IReserveAuctionListingAdjustableBufferIncrementEth.sol";

/// @title Reserve Auction Listing Adjustable Buffer Increment ETH
/// @author jgeary
/// @notice Module adding Adjustable Buffer Increment to Reserve Auction Listing Fee ETH
contract ReserveAuctionListingAdjustableBufferIncrementEth is
    IReserveAuctionListingAdjustableBufferIncrementEth,
    ReentrancyGuard,
    FeePayoutSupportV1,
    ModuleNamingSupportV1
{
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @notice The minimum amount of time left in an auction after a new bid is created
    uint16 constant DEFAULT_TIME_BUFFER = 15 minutes;

    /// @notice The minimum percentage difference between two bids
    uint8 constant DEFAULT_MIN_BID_INCREMENT_PERCENTAGE = 10;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The ZORA ERC-721 Transfer Helper
    ERC721TransferHelper public immutable erc721TransferHelper;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _erc721TransferHelper The ZORA ERC-721 Transfer Helper address
    /// @param _royaltyEngine The Manifold Royalty Engine address
    /// @param _protocolFeeSettings The ZORA Protocol Fee Settings address
    /// @param _weth The WETH token address
    constructor(
        address _erc721TransferHelper,
        address _royaltyEngine,
        address _protocolFeeSettings,
        address _weth
    )
        FeePayoutSupportV1(_royaltyEngine, _protocolFeeSettings, _weth, ERC721TransferHelper(_erc721TransferHelper).ZMM().registrar())
        ModuleNamingSupportV1("Reserve Auction Listing Adjustable Buffer Increment ETH")
    {
        erc721TransferHelper = ERC721TransferHelper(_erc721TransferHelper);
    }

    ///                                                          ///
    ///                            EIP-165                       ///
    ///                                                          ///

    /// @notice Implements EIP-165 for standard interface detection
    /// @dev `0x01ffc9a7` is the IERC165 interface id
    /// @param _interfaceId The identifier of a given interface
    /// @return If the given interface is supported
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == type(IReserveAuctionListingAdjustableBufferIncrementEth).interfaceId || _interfaceId == 0x01ffc9a7;
    }

    ///                                                          ///
    ///                        AUCTION STORAGE                   ///
    ///                                                          ///

    /// @notice The metadata for a given auction
    /// @param seller The address of the seller
    /// @param reservePrice The reserve price to start the auction
    /// @param sellerFundsRecipient The address where funds are sent after the auction
    /// @param highestBid The highest bid of the auction
    /// @param highestBidder The address of the highest bidder
    /// @param duration The length of time that the auction runs after the first bid is placed
    /// @param startTime The time that the first bid can be placed
    /// @param listingFeeRecipient The address that listed the auction
    /// @param firstBidTime The time that the first bid is placed
    /// @param listingFeeBps The fee that is sent to the lister of the auction
    /// @param timeBuffer Time buffer in seconds
    /// @param percentIncrement The minimum percent increase for a new bid
    struct Auction {
        address seller;
        uint96 reservePrice;
        address sellerFundsRecipient;
        uint96 highestBid;
        address highestBidder;
        uint48 duration;
        uint48 startTime;
        address listingFeeRecipient;
        uint80 firstBidTime;
        uint16 listingFeeBps;
        uint16 timeBuffer;
        uint8 percentIncrement;
    }

    /// @notice The auction for a given NFT, if one exists
    /// @dev ERC-721 token contract => ERC-721 token id => Auction
    mapping(address => mapping(uint256 => Auction)) public auctionForNFT;

    ///                                                          ///
    ///                         CREATE AUCTION                   ///
    ///                                                          ///

    //     ,-.
    //     `-'
    //     /|\
    //      |             ,------------------------.
    //     / \            |ReserveAuctionListingEth|
    //   Caller           `-----------+------------'
    //     |      createAuction()     |
    //     | ------------------------->
    //     |                          |
    //     |                          |----.
    //     |                          |    | store auction metadata
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | emit AuctionCreated()
    //     |                          |<---'
    //   Caller           ,-----------+------------.
    //     ,-.            |ReserveAuctionListingEth|
    //     `-'            `------------------------'
    //     /|\
    //      |
    //     / \

    /// @notice Emitted when an auction is created
    /// @param tokenContract The ERC-721 token address of the created auction
    /// @param tokenId The ERC-721 token id of the created auction
    /// @param auction The metadata of the created auction
    event AuctionCreated(address indexed tokenContract, uint256 indexed tokenId, Auction auction);

    /// @notice Creates an auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    /// @param _duration The length of time the auction should run after the first bid
    /// @param _reservePrice The minimum bid amount to start the auction
    /// @param _sellerFundsRecipient The address to send funds to once the auction is complete
    /// @param _startTime The time that users can begin placing bids
    /// @param _listingFeeBps The fee to send to the lister of the auction
    /// @param _listingFeeRecipient The address listing the auction
    function createAuction(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _reservePrice,
        address _sellerFundsRecipient,
        uint256 _startTime,
        uint256 _listingFeeBps,
        address _listingFeeRecipient,
        uint16 _timeBuffer,
        uint8 _percentIncrement
    ) external nonReentrant {
        // Get the owner of the specified token
        address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);

        // Ensure the caller is the owner or an approved operator
        require(msg.sender == tokenOwner || IERC721(_tokenContract).isApprovedForAll(tokenOwner, msg.sender), "ONLY_TOKEN_OWNER_OR_OPERATOR");

        // Ensure the funds recipient is specified
        require(_sellerFundsRecipient != address(0), "INVALID_FUNDS_RECIPIENT");

        // Ensure the listing fee does not exceed 10,000 basis points
        require(_listingFeeBps <= 10000, "INVALID_LISTING_FEE");

        // Get the auction's storage pointer
        Auction storage auction = auctionForNFT[_tokenContract][_tokenId];

        if (_timeBuffer > 0) {
            require(_timeBuffer >= 1 minutes && _timeBuffer <= 1 hours, "INVALID_TIME_BUFFER");
            auction.timeBuffer = _timeBuffer;
        }

        if (_percentIncrement > 0) {
            require(_percentIncrement < 50, "INVALID_PERCENT_INCREMENT");
            auction.percentIncrement = _percentIncrement;
        }

        // Store the associated metadata
        auction.seller = tokenOwner;
        auction.reservePrice = uint96(_reservePrice);
        auction.sellerFundsRecipient = _sellerFundsRecipient;
        auction.duration = uint48(_duration);
        auction.startTime = uint48(_startTime);
        auction.listingFeeRecipient = _listingFeeRecipient;
        auction.listingFeeBps = uint16(_listingFeeBps);

        emit AuctionCreated(_tokenContract, _tokenId, auction);
    }

    ///                                                          ///
    ///                      UPDATE RESERVE PRICE                ///
    ///                                                          ///

    //     ,-.
    //     `-'
    //     /|\
    //      |             ,------------------------.
    //     / \            |ReserveAuctionListingEth|
    //   Caller           `-----------+------------'
    //     | setAuctionReservePrice() |
    //     | ------------------------->
    //     |                          |
    //     |                          |----.
    //     |                          |    | update reserve price
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | emit AuctionReservePriceUpdated()
    //     |                          |<---'
    //   Caller           ,-----------+------------.
    //     ,-.            |ReserveAuctionListingEth|
    //     `-'            `------------------------'
    //     /|\
    //      |
    //     / \

    /// @notice Emitted when a reserve price is updated
    /// @param tokenContract The ERC-721 token address of the updated auction
    /// @param tokenId The ERC-721 token id of the updated auction
    /// @param auction The metadata of the updated auction
    event AuctionReservePriceUpdated(address indexed tokenContract, uint256 indexed tokenId, Auction auction);

    /// @notice Updates the reserve price for a given auction
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    /// @param _reservePrice The new reserve price
    function setAuctionReservePrice(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external nonReentrant {
        // Get the auction for the specified token
        Auction storage auction = auctionForNFT[_tokenContract][_tokenId];

        // Ensure the auction has not started
        require(auction.firstBidTime == 0, "AUCTION_STARTED");

        // Ensure the caller is the seller
        require(msg.sender == auction.seller, "ONLY_SELLER");

        // Update the reserve price
        auction.reservePrice = uint96(_reservePrice);

        emit AuctionReservePriceUpdated(_tokenContract, _tokenId, auction);
    }

    ///                                                          ///
    ///                         CANCEL AUCTION                   ///
    ///                                                          ///

    //     ,-.
    //     `-'
    //     /|\
    //      |             ,------------------------.
    //     / \            |ReserveAuctionListingEth|
    //   Caller           `-----------+------------'
    //     |      cancelAuction()     |
    //     | ------------------------->
    //     |                          |
    //     |                          |----.
    //     |                          |    | emit AuctionCanceled()
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | delete auction
    //     |                          |<---'
    //   Caller           ,-----------+------------.
    //     ,-.            |ReserveAuctionListingEth|
    //     `-'            `------------------------'
    //     /|\
    //      |
    //     / \

    /// @notice Emitted when an auction is canceled
    /// @param tokenContract The ERC-721 token address of the canceled auction
    /// @param tokenId The ERC-721 token id of the canceled auction
    /// @param auction The metadata of the canceled auction
    event AuctionCanceled(address indexed tokenContract, uint256 indexed tokenId, Auction auction);

    /// @notice Cancels the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function cancelAuction(address _tokenContract, uint256 _tokenId) external nonReentrant {
        // Get the auction for the specified token
        Auction memory auction = auctionForNFT[_tokenContract][_tokenId];

        // Ensure the auction has not started
        require(auction.firstBidTime == 0, "AUCTION_STARTED");

        // Ensure the caller is the seller or a new owner of the token
        require(msg.sender == auction.seller || msg.sender == IERC721(_tokenContract).ownerOf(_tokenId), "ONLY_SELLER_OR_TOKEN_OWNER");

        emit AuctionCanceled(_tokenContract, _tokenId, auction);

        // Remove the auction from storage
        delete auctionForNFT[_tokenContract][_tokenId];
    }

    ///                                                          ///
    ///                           CREATE BID                     ///
    ///                                                          ///

    //     ,-.
    //     `-'
    //     /|\
    //      |             ,------------------------.                ,--------------------.
    //     / \            |ReserveAuctionListingEth|                |ERC721TransferHelper|
    //   Caller           `-----------+------------'                `---------+----------'
    //     |        createBid()       |                                       |
    //     | ------------------------->                                       |
    //     |                          |                                       |
    //     |                          |                                       |
    //     |    ___________________________________________________________________
    //     |    ! ALT  /  First bid?  |                                       |    !
    //     |    !_____/               |                                       |    !
    //     |    !                     |----.                                  |    !
    //     |    !                     |    | start auction                    |    !
    //     |    !                     |<---'                                  |    !
    //     |    !                     |                                       |    !
    //     |    !                     |----.                                  |    !
    //     |    !                     |    | transferFrom()                   |    !
    //     |    !                     |<---'                                  |    !
    //     |    !                     |                                       |    !
    //     |    !                     |----.                                       !
    //     |    !                     |    | transfer NFT from seller to escrow    !
    //     |    !                     |<---'                                       !
    //     |    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //     |    ! [refund previous bidder]                                    |    !
    //     |    !                     |----.                                  |    !
    //     |    !                     |    | transfer ETH to bidder           |    !
    //     |    !                     |<---'                                  |    !
    //     |    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //     |                          |                                       |
    //     |                          |                                       |
    //     |    _______________________________________________               |
    //     |    ! ALT  /  Bid placed within time buffer?       !              |
    //     |    !_____/               |                        !              |
    //     |    !                     |----.                   !              |
    //     |    !                     |    | extend auction    !              |
    //     |    !                     |<---'                   !              |
    //     |    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!              |
    //     |    !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!              |
    //     |                          |                                       |
    //     |                          |----.                                  |
    //     |                          |    | emit AuctionBid()                |
    //     |                          |<---'                                  |
    //   Caller           ,-----------+------------.                ,---------+----------.
    //     ,-.            |ReserveAuctionListingEth|                |ERC721TransferHelper|
    //     `-'            `------------------------'                `--------------------'
    //     /|\
    //      |
    //     / \

    /// @notice Emitted when a bid is placed
    /// @param tokenContract The ERC-721 token address of the auction
    /// @param tokenId The ERC-721 token id of the auction
    /// @param firstBid If the bid started the auction
    /// @param extended If the bid extended the auction
    /// @param auction The metadata of the auction
    event AuctionBid(address indexed tokenContract, uint256 indexed tokenId, bool firstBid, bool extended, Auction auction);

    /// @notice Places a bid on the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function createBid(address _tokenContract, uint256 _tokenId) external payable nonReentrant {
        // Get the auction for the specified token
        Auction storage auction = auctionForNFT[_tokenContract][_tokenId];

        // Cache the seller
        address seller = auction.seller;

        // Ensure the auction exists
        require(seller != address(0), "AUCTION_DOES_NOT_EXIST");

        // Ensure the auction has started or is valid to start
        require(block.timestamp >= auction.startTime, "AUCTION_NOT_STARTED");

        // Cache more auction metadata
        uint256 firstBidTime = auction.firstBidTime;
        uint256 duration = auction.duration;

        // Used to emit whether the bid started the auction
        bool firstBid;

        // If this is the first bid, start the auction
        if (firstBidTime == 0) {
            // Ensure the bid meets the reserve price
            require(msg.value >= auction.reservePrice, "RESERVE_PRICE_NOT_MET");

            // Store the current time as the first bid time
            auction.firstBidTime = uint80(block.timestamp);

            // Mark this bid as the first
            firstBid = true;

            // Transfer the NFT from the seller into escrow for the duration of the auction
            // Reverts if the seller did not approve the ERC721TransferHelper or no longer owns the token
            erc721TransferHelper.transferFrom(_tokenContract, seller, address(this), _tokenId);

            // Else this is a subsequent bid, so refund the previous bidder
        } else {
            // Ensure the auction has not ended
            require(block.timestamp < (firstBidTime + duration), "AUCTION_OVER");

            // Cache the highest bid
            uint256 highestBid = auction.highestBid;

            // Used to store the minimum bid required to outbid the highest bidder
            uint256 minValidBid;

            // Calculate the minimum bid required (10% higher than the highest bid)
            // Cannot overflow as the highest bid would have to be magnitudes higher than the total supply of ETH
            uint8 minPercentIncrement;
            if (auction.percentIncrement > 0) {
                minPercentIncrement = auction.percentIncrement;
            } else {
                minPercentIncrement = DEFAULT_MIN_BID_INCREMENT_PERCENTAGE;
            }
            unchecked {
                minValidBid = highestBid + ((highestBid * minPercentIncrement) / 100);
            }

            // Ensure the incoming bid meets the minimum
            require(msg.value >= minValidBid, "MINIMUM_BID_NOT_MET");

            // Refund the previous bidder
            _handleOutgoingTransfer(auction.highestBidder, highestBid, address(0), 50000);
        }

        // Store the attached ETH as the highest bid
        auction.highestBid = uint96(msg.value);

        // Store the caller as the highest bidder
        auction.highestBidder = msg.sender;

        // Used to emit whether the bid extended the auction
        bool extended;

        // Used to store the auction time remaining
        uint256 timeRemaining;

        // Get the auction time remaining
        // Cannot underflow as `firstBidTime + duration` is ensured to be greater than `block.timestamp`
        unchecked {
            timeRemaining = firstBidTime + duration - block.timestamp;
        }

        // If the bid is placed within time buffer, extend the auction
        uint16 timeBuffer;
        if (auction.timeBuffer > 0) {
            timeBuffer = auction.timeBuffer;
        } else {
            timeBuffer = DEFAULT_TIME_BUFFER;
        }
        if (timeRemaining < timeBuffer) {
            // Add (time buffer - remaining time) to the duration so that the buffer remains
            // Cannot underflow as `timeRemaining` is ensured to be less than `timeBuffer`
            unchecked {
                auction.duration += uint48(timeBuffer - timeRemaining);
            }

            // Mark the bid as one that extended the auction
            extended = true;
        }

        emit AuctionBid(_tokenContract, _tokenId, firstBid, extended, auction);
    }

    ///                                                          ///
    ///                         SETTLE AUCTION                   ///
    ///                                                          ///

    //     ,-.
    //     `-'
    //     /|\
    //      |             ,------------------------.
    //     / \            |ReserveAuctionListingEth|
    //   Caller           `-----------+------------'
    //     |      settleAuction()     |
    //     | ------------------------->
    //     |                          |
    //     |                          |----.
    //     |                          |    | validate auction ended
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | handle royalty payouts
    //     |                          |<---'
    //     |                          |
    //     |                          |
    //     |    __________________________________________________________
    //     |    ! ALT  /  listing fee configured for this auction?        !
    //     |    !_____/               |                                   !
    //     |    !                     |----.                              !
    //     |    !                     |    | handle listing fee payout    !
    //     |    !                     |<---'                              !
    //     |    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //     |    !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    //     |                          |
    //     |                          |----.
    //     |                          |    | handle seller funds recipient payout
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | transfer NFT from escrow to winning bidder
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | emit AuctionEnded()
    //     |                          |<---'
    //     |                          |
    //     |                          |----.
    //     |                          |    | delete auction from contract
    //     |                          |<---'
    //   Caller           ,-----------+------------.
    //     ,-.            |ReserveAuctionListingEth|
    //     `-'            `------------------------'
    //     /|\
    //      |
    //     / \

    /// @notice Emitted when an auction has ended
    /// @param tokenContract The ERC-721 token address of the auction
    /// @param tokenId The ERC-721 token id of the auction
    /// @param auction The metadata of the settled auction
    event AuctionEnded(address indexed tokenContract, uint256 indexed tokenId, Auction auction);

    /// @notice Ends the auction for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The id of the ERC-721 token
    function settleAuction(address _tokenContract, uint256 _tokenId) external nonReentrant {
        // Get the auction for the specified token
        Auction memory auction = auctionForNFT[_tokenContract][_tokenId];

        // Cache the time of the first bid
        uint256 firstBidTime = auction.firstBidTime;

        // Ensure the auction had started
        require(firstBidTime != 0, "AUCTION_NOT_STARTED");

        // Ensure the auction has ended
        require(block.timestamp >= (firstBidTime + auction.duration), "AUCTION_NOT_OVER");

        // Payout associated token royalties, if any
        (uint256 remainingProfit, ) = _handleRoyaltyPayout(_tokenContract, _tokenId, auction.highestBid, address(0), 300000);

        // Payout the module fee, if configured by the owner
        remainingProfit = _handleProtocolFeePayout(remainingProfit, address(0));

        // Cache the listing fee recipient
        address listingFeeRecipient = auction.listingFeeRecipient;

        // Payout the listing fee, if a recipient exists
        if (listingFeeRecipient != address(0)) {
            // Get the listing fee from the remaining profit
            uint256 listingFee = (remainingProfit * auction.listingFeeBps) / 10000;

            // Transfer the amount to the listing fee recipient
            _handleOutgoingTransfer(listingFeeRecipient, listingFee, address(0), 50000);

            // Update the remaining profit
            remainingProfit -= listingFee;
        }

        // Transfer the remaining profit to the funds recipient
        _handleOutgoingTransfer(auction.sellerFundsRecipient, remainingProfit, address(0), 50000);

        // Transfer the NFT to the winning bidder
        IERC721(_tokenContract).transferFrom(address(this), auction.highestBidder, _tokenId);

        emit AuctionEnded(_tokenContract, _tokenId, auction);

        // Remove the auction from storage
        delete auctionForNFT[_tokenContract][_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ZoraModuleManager} from "../ZoraModuleManager.sol";

/// @title Base Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides shared utility for ZORA transfer helpers
contract BaseTransferHelper {
    /// @notice The ZORA Module Manager
    ZoraModuleManager public immutable ZMM;

    /// @param _moduleManager The ZORA Module Manager referred to for transfer permissions
    constructor(address _moduleManager) {
        require(_moduleManager != address(0), "must set module manager to non-zero address");

        ZMM = ZoraModuleManager(_moduleManager);
    }

    /// @notice Ensures a user has approved the module they're calling
    /// @param _user The address of the user
    modifier onlyApprovedModule(address _user) {
        require(isModuleApproved(_user), "module has not been approved by user");
        _;
    }

    /// @notice If a user has approved the module they're calling
    /// @param _user The address of the user
    function isModuleApproved(address _user) public view returns (bool) {
        return ZMM.isModuleApproved(_user, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BaseTransferHelper} from "./BaseTransferHelper.sol";

/// @title ERC-721 Transfer Helper
/// @author tbtstl <[email protected]>
/// @notice This contract provides modules the ability to transfer ZORA user ERC-721s with their permission
contract ERC721TransferHelper is BaseTransferHelper {
    constructor(address _approvalsManager) BaseTransferHelper(_approvalsManager) {}

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyApprovedModule(_from) {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyApprovedModule(_from) {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}