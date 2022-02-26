pragma solidity ^0.8.0;

/// @title Abacus Controller
/// @author Gio Medici
/// @notice Protocol directory
contract AbacusController {

    /* ======== ADDRESS ======== */

    address public admin;
    address public abcTreasury;
    address public abcToken;
    address public veAbcToken;
    address public epochVault;
    address public vaultFactory;

    /* ======== UINT ======== */

    uint256 public spread;
    uint256 public bribeCut;
    uint256 public abcCostOfVaultCreation;
    uint256 public premiumFee;
    uint256 public vaultClosureFee;

    /* ======== BOOLEAN ======== */

    bool public beta;

    /* ======== MAPPING ======== */

    mapping(address => mapping(uint => address)) public nftVault;
    mapping(address => uint) public collectionMultiplier;

    /* ======== MODIFIERS ======== */

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
        beta = true;
    }

    /* ======== SETTERS ======== */

    /// @notice configure Treasury 
    function setTreasury(address _abcTreasury) onlyAdmin external {
        abcTreasury = _abcTreasury;
    }

    /// @notice configure ABC
    function setToken(address _token) onlyAdmin external {
        abcToken = _token;
    }

    /// @notice configure veABC
    function setVeToken(address _veToken) onlyAdmin external {
        veAbcToken = _veToken;
    }

    /// @notice configure Epoch Vault
    function setEpochVault(address _epochVault) onlyAdmin external {
        epochVault = _epochVault;
    }

    /// @notice  configure Vault Factory
    function setVaultFactory(address _factory) onlyAdmin external {
        vaultFactory = _factory;
    }

    /// @notice set the spread which sets the sales tax 
    function setSpread(uint256 _spread) onlyAdmin external {
        spread = _spread;
    }

    /// @notice configure the protocol to beta phase
    function setBetaStatus(bool _status) onlyAdmin external {
        beta = _status;
    }

    /// @notice set the piece of bribes paid that are taken as a bribe fee
    function setBribeCut(uint256 _amount) onlyAdmin external {
        bribeCut = _amount;
    }

    /// @notice set the cost to pay for premium space
    function setPremiumFee(uint256 _amount) onlyAdmin external {
        premiumFee = _amount;
    }

    /// @notice set the cost (in ABC) to close a Spot pool
    function setClosureFee(uint256 _amount) onlyAdmin external {
        vaultClosureFee = _amount;
    }
}