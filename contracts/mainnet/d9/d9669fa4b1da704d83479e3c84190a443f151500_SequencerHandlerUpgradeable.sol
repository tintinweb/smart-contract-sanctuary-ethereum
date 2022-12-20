// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/ISequencerHandler.sol";
import "../interfaces/iRouterCrossTalk.sol";
import "../interfaces/iGBridge.sol";
import "../interfaces/IFeeManagerGeneric.sol";
import "../interfaces/IDepositExecute.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERCHandler.sol";

/// @title Handles Sequencer deposits and deposit executions.
/// @author Router Protocol
/// @notice This contract is intended to be used with the Bridge contract.
contract SequencerHandlerUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ISequencerHandler
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ----------------------------------------------------------------- //
    //                        DS Section Starts                          //
    // ----------------------------------------------------------------- //

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    bytes32 public constant resourceID = 0x2222222222222222222222222222222222222222222222222222222222222222;

    iGBridge private bridge;
    iFeeManagerGeneric private feeManager;
    uint8 private _chainid;

    // destinationChainId => depositNonce => DepositRecord
    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    // destinationChainId => depositNonce => ExecuteRecord
    mapping(uint8 => mapping(uint64 => ExecuteRecord)) private _executeRecords;

    // destinationChainId => true if unsupported and false if supported
    mapping(uint8 => bool) private _unsupportedChains;

    // destinationChainId => defaultGasLimit
    mapping(uint8 => uint256) private defaultGas;

    // destinationChainId => defaultGasPrice
    mapping(uint8 => uint256) private defaultGasPrice;

    struct ExecuteRecord {
        bool isExecuted;
        bool _status;
        bytes _callback;
    }

    struct DepositRecord {
        uint8 _srcChainID;
        uint8 _destChainID;
        uint64 _nonce;
        address _srcAddress;
        address _destAddress;
        bytes _genericData;
        bytes _ercData;
        uint256 _gasLimit;
        uint256 _gasPrice;
        address _feeToken;
        uint256 _fees;
        bool _isTransferFirst;
    }

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
    }

    event ReplayEvent(
        uint8 indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64 indexed depositNonce,
        uint256 widgetID
    );

    modifier notUnsupportedChain(uint8 chainID) {
        require(!isChainUnsupported(chainID), "Unsupported chain");
        _;
    }

    // ----------------------------------------------------------------- //
    //                        DS Section Ends                            //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Init Section Starts                        //
    // ----------------------------------------------------------------- //

    function __SequencerHandlerUpgradeable_init(address _bridge) internal initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _bridge);
        _setupRole(FEE_SETTER_ROLE, msg.sender);

        bridge = iGBridge(_bridge);
        _chainid = bridge.fetch_chainID();
    }

    function __SequencerHandlerUpgradeable_init_unchained() internal initializer {}

    function initialize(address _bridge) external initializer {
        __SequencerHandlerUpgradeable_init(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                        Init Section Ends                          //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Mapping Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Maps the two contracts on cross chain enviroment.
    /// @dev Use this function to map your contracts across chains.
    /// @param linker RouterLinker object to be verified.
    function MapContract(RouterLinker calldata linker) external virtual {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(msg.sender == crossTalk.fetchLinkSetter(), "Only Link Setter");
        crossTalk.Link(linker._chainID, linker._linkedContract);
    }

    /// @notice Function UnMaps the two contracts on cross chain enviroment.
    /// @dev Use this function to unmap your contracts across chains.
    /// @param linker RouterLinker object to be verified.
    function UnMapContract(RouterLinker calldata linker) external virtual {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(msg.sender == crossTalk.fetchLinkSetter(), "Only Link Setter");
        crossTalk.Unlink(linker._chainID);
    }

    // ----------------------------------------------------------------- //
    //                        Mapping Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Deposit Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Fetches if a chain is unsupported.
    /// @dev Some chains may be unsupported from time to time due to unforseen circumstances.
    /// @param _destChainId chainId for the destination chain defined by Router Protocol.
    /// @return Returns true if chain is unsupported and false if supported.
    function isChainUnsupported(uint8 _destChainId) public view returns (bool) {
        return _unsupportedChains[_destChainId];
    }

    /// @notice Used to set/unset a chain as unsupported chain.
    /// @dev Some chains may be unsupported from time to time due to unforseen circumstances.
    /// @param _destChainId chainId for the destination chain defined by Router Protocol.
    /// @param _shouldUnsupport True to unsupport a chain and false to remove from unsupported chains.
    function unsupportChain(uint8 _destChainId, bool _shouldUnsupport) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unsupportedChains[_destChainId] = _shouldUnsupport;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithERC(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);

        // Handle ERC20
        _depositERC(_erc20, _swapData, _nonce);
        //Handle ERC20

        _depositRecords[_destChainID][_nonce]._ercData = abi.encode(_erc20, _swapData);
        _depositRecords[_destChainID][_nonce]._isTransferFirst = _isTransferFirst;

        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithETH(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external payable virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);

        // Handle ERC20
        _depositETH(_erc20, _swapData, msg.value, _nonce);
        //Handle ERC20

        _depositRecords[_destChainID][_nonce]._ercData = abi.encode(_erc20, _swapData);
        _depositRecords[_destChainID][_nonce]._isTransferFirst = _isTransferFirst;

        return _nonce;
    }

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls.
    /// @dev Can only be used when the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    function genericDeposit(
        uint8 _destChainID,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external virtual override notUnsupportedChain(_destChainID) nonReentrant returns (uint64) {
        require(defaultGas[_destChainID] != 0, "Dest gas not set");
        require(defaultGasPrice[_destChainID] != 0, "Dest gas price not set");

        uint64 _nonce = _genericDeposit(_destChainID, _generic, _gasLimit, _gasPrice, _feeToken);
        return _nonce;
    }

    /// @notice Function for generic deposit.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _genericData data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @return _nonce for the generic transaction.
    function _genericDeposit(
        uint8 _destChainID,
        bytes memory _genericData,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) internal virtual returns (uint64) {
        uint64 _nonce = bridge.genericDeposit(_destChainID, resourceID);
        iRouterCrossTalk crossTalk = iRouterCrossTalk(msg.sender);
        address destAddress = crossTalk.fetchLink(_destChainID);

        uint256 gasLimit = defaultGas[_destChainID] > _gasLimit ? defaultGas[_destChainID] : _gasLimit;
        uint256 gasPrice = defaultGasPrice[_destChainID] > _gasPrice ? defaultGasPrice[_destChainID] : _gasPrice;

        uint256 fees = deductFee(_destChainID, _feeToken, gasLimit, gasPrice);

        _depositRecords[_destChainID][_nonce] = DepositRecord(
            _chainid,
            _destChainID,
            _nonce,
            msg.sender,
            destAddress,
            _genericData,
            bytes("dummy_data"),
            gasLimit,
            gasPrice,
            _feeToken,
            fees,
            false
        );
        return _nonce;
    }

    /// @notice Function for erc20 deposit.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    function _depositERC(
        bytes memory _erc20,
        bytes calldata _swapData,
        uint64 _nonce
    ) internal virtual {
        (
            uint8 destinationChainID,
            bytes32 _resourceID,
            uint256[] memory flags,
            address[] memory path,
            bytes[] memory dataTx,
            address feeTokenAddress
        ) = abi.decode(_erc20, (uint8, bytes32, uint256[], address[], bytes[], address));

        require(!isChainUnsupported(destinationChainID), "Unsupported chain");

        IDepositExecute.SwapInfo memory swapDetails = this.unpackDepositData(_swapData);

        swapDetails.depositer = msg.sender;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.feeTokenAddress = feeTokenAddress;
        swapDetails.dataTx = dataTx;
        swapDetails.depositNonce = _nonce;

        swapDetails.handler = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        require(swapDetails.handler != address(0), "rid not mapped to handler");

        IDepositExecute depositHandler = IDepositExecute(swapDetails.handler);
        depositHandler.deposit(_resourceID, destinationChainID, swapDetails.depositNonce, swapDetails);
    }

    function _depositETH(
        bytes memory _data,
        bytes calldata ercdata,
        uint256 amount,
        uint64 nonce
    ) internal virtual {
        (, bytes32 _resourceID) = abi.decode(_data, (uint8, bytes32));
        address depositHandlerAddress = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        IERCHandler depositHandler = IERCHandler(depositHandlerAddress);
        address weth = depositHandler._WETH();

        IWETH(weth).deposit{ value: amount }();
        require(IWETH(weth).transfer(msg.sender, amount));

        _depositERC(_data, ercdata, nonce);
    }

    /// @notice Function used to unpack the deposit data for erc20 swap details.
    /// @param data swap data to be unpacked.
    /// @return depositData swap details.
    function unpackDepositData(bytes calldata data)
        external
        view
        virtual
        returns (IDepositExecute.SwapInfo memory depositData)
    {
        IDepositExecute.SwapInfo memory swapDetails;
        uint256 isDestNative;

        (
            swapDetails.srcTokenAmount,
            swapDetails.srcStableTokenAmount,
            swapDetails.destStableTokenAmount,
            swapDetails.destTokenAmount,
            isDestNative,
            swapDetails.lenRecipientAddress,
            swapDetails.lenSrcTokenAddress,
            swapDetails.lenDestTokenAddress
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256));

        //Note: to avoid stack too deep error, we are decoding it again.
        (, , , , , , , , swapDetails.widgetID) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        swapDetails.isDestNative = isDestNative == 0 ? false : true;
        swapDetails.index = 288; // 32 * 6 -> 9
        bytes memory recipient = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenRecipientAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenRecipientAddress;
        bytes memory srcToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenSrcTokenAddress]);
        swapDetails.index = swapDetails.index + swapDetails.lenSrcTokenAddress;
        bytes memory destStableToken = bytes(
            data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]
        );
        swapDetails.index = swapDetails.index + swapDetails.lenDestTokenAddress;
        bytes memory destToken = bytes(data[swapDetails.index:swapDetails.index + swapDetails.lenDestTokenAddress]);

        bytes20 srcTokenAddress;
        bytes20 destStableTokenAddress;
        bytes20 destTokenAddress;
        bytes20 recipientAddress;
        assembly {
            srcTokenAddress := mload(add(srcToken, 0x20))
            destStableTokenAddress := mload(add(destStableToken, 0x20))
            destTokenAddress := mload(add(destToken, 0x20))
            recipientAddress := mload(add(recipient, 0x20))
        }
        swapDetails.srcTokenAddress = srcTokenAddress;
        swapDetails.destStableTokenAddress = address(destStableTokenAddress);
        swapDetails.destTokenAddress = destTokenAddress;
        swapDetails.recipient = address(recipientAddress);

        return swapDetails;
    }

    /// @notice Function fetches deposit record.
    /// @param _ChainID Destination chainID of the deposit defined by Router Protocol
    /// @param  _nonce Nonce of the deposit
    /// @return Deposit Record for the chainId and nonce data
    function fetchDepositRecord(uint8 _ChainID, uint64 _nonce) external view returns (DepositRecord memory) {
        return _depositRecords[_ChainID][_nonce];
    }

    /// @notice Function fetches execute record.
    /// @param _ChainID Destination chainID of the deposit defined by Router Protocol
    /// @param  _nonce Nonce of the deposit
    /// @return Execute Record for the chainId and nonce data
    function fetchExecuteRecord(uint8 _ChainID, uint64 _nonce) external view returns (ExecuteRecord memory) {
        return _executeRecords[_ChainID][_nonce];
    }

    // ----------------------------------------------------------------- //
    //                        Deposit Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Execute Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function Executes a cross chain request on destination chain.
    /// @dev Can only be triggered by bridge.
    /// @param  _data Cross chain data received from relayer consisting of the deposit record.
    function executeProposal(bytes calldata _data)
        external
        virtual
        override
        onlyRole(BRIDGE_ROLE)
        nonReentrant
        returns (bool)
    {
        DepositRecord memory depositData = decodeData(_data);
        ExecuteRecord memory executeRecords = _executeRecords[depositData._srcChainID][depositData._nonce];

        require(executeRecords.isExecuted == false, "Already executed");
        if (!depositData._destAddress.isContract()) {
            executeRecords._callback = "";
            executeRecords._status = false;
            executeRecords.isExecuted = true;
            _executeRecords[depositData._srcChainID][depositData._nonce] = executeRecords;
            return true;
        }

        if (
            keccak256(depositData._ercData) == keccak256(bytes("dummy_data")) &&
            (depositData._ercData).length == (bytes("dummy_data")).length
        ) {
            // passing 0 for settlement token and amount as we don't know it yet
            executeGeneric(depositData, address(0), 0);
        } else if (depositData._isTransferFirst) {
            (address settlementToken, uint256 returnAmount) = executeErc(depositData);
            executeGeneric(depositData, settlementToken, returnAmount);
        } else {
            // passing 0 for settlement token and amount as we don't know it yet
            executeGeneric(depositData,address(0), 0);
            executeErc(depositData);
        }

        return true;
    }

    /// @notice Function Executes a cross chain request on destination chain for generic transaction.
    /// @dev Can only be triggered by bridge.
    /// @param depositData deposit data for the transaction.
    /// @param settlementToken address of the settlement token.
    /// @param returnAmount amount of settlement token paid to the recipient.
    function executeGeneric(DepositRecord memory depositData, address settlementToken, uint256 returnAmount) internal virtual {
        ExecuteRecord memory executeRecords = _executeRecords[depositData._srcChainID][depositData._nonce];
        (bool success, bytes memory callback) = depositData._destAddress.call(
            abi.encodeWithSelector(
                0xa620f64f, // routerSync(uint8,address,bytes,address,amount)
                depositData._srcChainID,
                depositData._srcAddress,
                depositData._genericData,
                settlementToken,
                returnAmount
            )
        );
        executeRecords._status = success;
        executeRecords._callback = callback;
        executeRecords.isExecuted = true;
        _executeRecords[depositData._srcChainID][depositData._nonce] = executeRecords;
    }
    

    /// @notice Function Executes a cross chain request on destination chain for erc20 transaction.
    /// @dev Can only be triggered by bridge.
    /// @param depositData deposit data for the transaction.
    function executeErc(DepositRecord memory depositData) internal virtual returns(address, uint256){
        (bytes memory _erc20, bytes memory _swapData) = abi.decode(depositData._ercData, (bytes, bytes));

        (, bytes32 _resourceID, uint256[] memory flags, address[] memory path, bytes[] memory dataTx, ) = abi.decode(
            _erc20,
            (uint8, bytes32, uint256[], address[], bytes[], address)
        );

        IDepositExecute.SwapInfo memory swapDetails = this.unpackDepositData(_swapData);

        address settlementToken;
        swapDetails.dataTx = dataTx;
        swapDetails.flags = flags;
        swapDetails.path = path;
        swapDetails.index = depositData._srcChainID;
        swapDetails.depositNonce = depositData._nonce;

        address depositHandlerAddress = bridge.fetch_resourceIDToHandlerAddress(_resourceID);
        IDepositExecute depositHandler = IDepositExecute(depositHandlerAddress);
        (settlementToken, swapDetails.returnAmount) = depositHandler.executeProposal(swapDetails, _resourceID);
        return (settlementToken, swapDetails.returnAmount);
    }

    /// @notice Used to decode the deposit data received from bridge.
    /// @param _data Cross chain deposit data received from relayer.
    /// @return depositData is returned
    function decodeData(bytes calldata _data) internal pure virtual returns (DepositRecord memory) {
        DepositRecord memory depositData;
        (
            depositData._srcChainID,
            depositData._nonce,
            depositData._srcAddress,
            depositData._destAddress,
            depositData._genericData,
            depositData._ercData,
            depositData._isTransferFirst
        ) = abi.decode(_data, (uint8, uint64, address, address, bytes, bytes, bool));

        return depositData;
    }

    // ----------------------------------------------------------------- //
    //                        Execute Section Ends                       //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches the chainID.
    /// @return chainId
    function fetch_chainID() external view override returns (uint8) {
        return _chainid;
    }

    /// @notice Function fetches the bridge address.
    /// @return bridge address
    function fetchBridge() external view returns (address) {
        return address(bridge);
    }

    /// @notice Function sets the bridge address.
    /// @dev Can only be called by the default admin
    /// @param _bridge Address of the bridge contract.
    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = iGBridge(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Section Starts                     //
    // ----------------------------------------------------------------- //

    /// @notice Function fetches the fee manager address.
    /// @return feeManager address
    function fetchFeeManager() external view returns (address) {
        return address(feeManager);
    }

    /// @notice Function Sets the fee manager address.
    /// @dev Can only be called by the default admin
    /// @param _feeManager Address of the fee manager contract.
    function setFeeManager(address _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = iFeeManagerGeneric(_feeManager);
    }

    /// @notice Function Fetches the default Gas for a destination chain.
    /// @param _chainID chainId of the destination chain.
    /// @return defaultGasLimit
    function fetchDefaultGas(uint8 _chainID) external view returns (uint256) {
        return defaultGas[_chainID];
    }

    /// @notice Function Fetches the default gas price for a destination chain.
    /// @param _chainID chainId of the destination chain.
    /// @return defaultGasPrice
    function fetchDefaultGasPrice(uint8 _chainID) external view returns (uint256) {
        return defaultGasPrice[_chainID];
    }

    /// @notice Function Sets default gas fees for destination chain.
    /// @param _chainID ChainID of the destination chain.
    /// @param _defaultGas Default gas limit for a destination chain.
    function setDefaultGas(uint8[] memory _chainID, uint256[] memory _defaultGas) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_chainID.length == _defaultGas.length, "Array length mismatch");
        for (uint256 i = 0; i < _chainID.length; i++) {
            defaultGas[_chainID[i]] = _defaultGas[i];
        }
    }

    /// @notice Function Sets default gas fees for destination chain.
    /// @param _chainID ChainID of the destination chain.
    /// @param _defaultGasPrice Default gas price for a destination chain.
    function setDefaultGasPrice(uint8[] memory _chainID, uint256[] memory _defaultGasPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_chainID.length == _defaultGasPrice.length, "Array length mismatch");
        for (uint256 i = 0; i < _chainID.length; i++) {
            defaultGasPrice[_chainID[i]] = _defaultGasPrice[i];
        }
    }

    /// @notice Calculates fees for a cross chain call.
    /// @param destinationChainID id of the destination chain.
    /// @param feeTokenAddress Address fee token.
    /// @param gasLimit Gas limit required for cross chain call.
    /// @param gasPrice Gas price required for cross chain call.
    /// @return totalFees
    function calculateFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        (uint256 feeFactor, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);

        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        uint256 _gasLimit = gasLimit < defaultGas[destinationChainID] ? defaultGas[destinationChainID] : gasLimit;
        uint256 _gasPrice = gasPrice < defaultGasPrice[destinationChainID]
            ? defaultGasPrice[destinationChainID]
            : gasPrice;

        uint256 fees;

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = bridgeFees + ((feeFactor * _gasPrice * _gasLimit) / (10**decimalsToDivide));
            return fees;
        }

        fees = bridgeFees + (feeFactor * _gasLimit * _gasPrice);
        return fees;
    }

    /// @notice Function used to deduct fee for generic deposit.
    /// @param destinationChainID chainId of the destination chain defined by Router Protocol.
    /// @param feeTokenAddress fee token for payment of fees.
    /// @param gasLimit gas limit for the call.
    /// @param gasPrice gas price for the call.
    /// @return totalFee for generic deposit.
    function deductFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gasLimit,
        uint256 gasPrice
    ) internal virtual returns (uint256) {
        (uint256 feeFactor, ) = feeManager.getFee(destinationChainID, feeTokenAddress);

        uint256 fees;
        uint8 feeTokenDecimals = IERC20MetadataUpgradeable(feeTokenAddress).decimals();

        if (feeTokenDecimals < 18) {
            uint8 decimalsToDivide = 18 - feeTokenDecimals;
            fees = (feeFactor * gasPrice * gasLimit) / (10**decimalsToDivide);
        } else {
            fees = feeFactor * gasLimit * gasPrice;
        }

        IERC20Upgradeable(feeTokenAddress).safeTransferFrom(msg.sender, address(feeManager), fees);
        return fees;
    }

    /**
        @notice Function to replay a transaction which was stuck due to underpricing of gas.
        @param  _destChainID Destination ChainID
        @param  _depositNonce Nonce for the transaction.
        @param  _gasLimit Gas limit allowed for the transaction.
        @param  _gasPrice Gas Price for the transaction.
    **/
    function replayDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external override {
        DepositRecord storage record = _depositRecords[_destChainID][_depositNonce];
        uint256 preGasPrice = record._gasPrice;
        uint256 preGasLimit = record._gasLimit;

        require(record._srcAddress == msg.sender, "Unauthorized transaction");

        require(preGasLimit <= _gasLimit, "Gas Limit >= previous GasLimit");

        require(preGasPrice < _gasPrice, "Gas Price > previous Price");

        uint256 fees = deductFee(_destChainID, record._feeToken, _gasLimit, _gasPrice);
        emit ReplayEvent(_destChainID, resourceID, record._nonce, 0);

        record._gasLimit = _gasLimit;
        record._gasPrice = _gasPrice;
        record._fees += fees;
    }

    /// @notice Function Sets the fee for a fee token on to feemanager
    /// @dev Can only be called by fee setter.
    /// @param destinationChainID ID of the destination chain.
    /// @param feeTokenAddress Address of fee token.
    /// @param feeFactor FeeFactor for the cross chain call.
    /// @param bridgeFee Base Fee for bridge.
    /// @param accepted Bool value for enabling and disabling feetoken.
    function setFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external onlyRole(FEE_SETTER_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, feeFactor, bridgeFee, accepted);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Section Ends                       //
    // ----------------------------------------------------------------- //
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
pragma solidity ^0.8.2;

/**
    @title Interface for handler that handles sequencer deposits and deposit executions.
    @author Router Protocol.
 */
interface ISequencerHandler {
    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithERC(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external returns (uint64);

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls as well as ERC20 cross-chain calls at once.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _erc20 data regarding the transaction for erc20.
    /// @param _swapData data regarding the swapDetails for erc20 transaction.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    /// @param _isTransferFirst sequence for erc20 and generic call. True for prioritizing erc20 over generic call.
    function genericDepositWithETH(
        uint8 _destChainID,
        bytes memory _erc20,
        bytes calldata _swapData,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken,
        bool _isTransferFirst
    ) external payable returns (uint64);

    /// @notice Function fired to trigger Cross Chain Communication.
    /// @dev Used to transact generic calls.
    /// @dev Can only be used when the contract is not paused and the dest chain is not unsupported.
    /// @dev Only callable by crosstalk contracts on supported chains and only when contract is not paused.
    /// @param _destChainID chainId of the destination chain defined by Router Protocol.
    /// @param _generic data for generic cross-chain call.
    /// @param _gasLimit gas limit for the call.
    /// @param _gasPrice gas price for the call.
    /// @param _feeToken fee token for payment of fees.
    function genericDeposit(
        uint8 _destChainID,
        bytes memory _generic,
        uint256 _gasLimit,
        uint256 _gasPrice,
        address _feeToken
    ) external returns (uint64);

    /// @notice Function Executes a cross chain request on destination chain.
    /// @dev Can only be triggered by bridge.
    /// @param  _data Cross chain data recived from relayer consisting of the deposit record.
    function executeProposal(bytes calldata _data) external returns (bool);

    /// @notice Function to replay a transaction which was stuck due to underpricing of gas.
    /// @param  _destChainID Destination ChainID
    /// @param  _depositNonce Nonce for the transaction.
    /// @param  _gasLimit Gas limit allowed for the transaction.
    /// @param  _gasPrice Gas Price for the transaction.
    function replayDeposit(
        uint8 _destChainID,
        uint64 _depositNonce,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) external;

    /// @notice Fetches chainID for the native chain
    function fetch_chainID() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iRouterCrossTalk {

    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _interface , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    function Link(uint8 _chainID , address _linkedContract) external;

    function Unlink(uint8 _chainID ) external;

    function fetchLinkSetter( ) external view returns( address);

    function fetchLink( uint8 _chainID ) external view returns( address);

    function fetchBridge( ) external view returns ( address );

    function fetchHandler( ) external view returns ( address );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface iGBridge {
    function genericDeposit(uint8 _destChainID, bytes32 _resourceID) external returns (uint64);

    function fetch_chainID() external view returns (uint8);

    /// @notice Used to re-emit deposit event for generic deposit
    /// @notice Can only be called by Generic handler
    function replayGenericDeposit(
        uint8 _destChainID,
        bytes32 _resourceID,
        uint64 _depositNonce
    ) external;

    function fetch_resourceIDToHandlerAddress(bytes32 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface iFeeManagerGeneric {
    function withdrawFee(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external;

    function getFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface IDepositExecute {
    struct SwapInfo {
        address feeTokenAddress;
        uint64 depositNonce;
        uint256 index;
        uint256 returnAmount;
        address recipient;
        address stableTokenAddress;
        address handler;
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        uint256 destStableTokenAmount;
        uint256 destTokenAmount;
        uint256 lenRecipientAddress;
        uint256 lenSrcTokenAddress;
        uint256 lenDestTokenAddress;
        bytes20 srcTokenAddress;
        address srcStableTokenAddress;
        bytes20 destTokenAddress;
        address destStableTokenAddress;
        bytes[] dataTx;
        uint256[] flags;
        address[] path;
        address depositer;
        bool isDestNative;
        uint256 widgetID;
    }

    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param destinationChainID Chain ID deposit is expected to be bridged to.
    /// @param depositNonce This value is generated as an ID by the Bridge contract.
    /// @param swapDetails Swap details
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo calldata swapDetails
    ) external;

    /// @notice It is intended that proposals are executed by the Bridge contract.
    function executeProposal(SwapInfo calldata swapDetails, bytes32 resourceID) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERCHandler {
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);

    function toggleFeeStatus(bool status) external;

    function getFeeStatus() external view returns (bool);

    function _ETH() external view returns (address);

    function _WETH() external view returns (address);

    function resourceIDToTokenContractAddress(bytes32 resourceID) external view returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    // function setTokenDecimals(
    //     address[] calldata tokenAddress,
    //     uint8[] calldata destinationChainID,
    //     uint8[] calldata decimals
    // ) external;

    /// @notice Sets oneSplitAddress for the handler
    /// @param contractAddress Address of oneSplit contract
    function setOneSplitAddress(address contractAddress) external;

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param contractAddress Address of contract for qhich liquidity pool needs to be created.
    function setLiquidityPool(address contractAddress, address lpAddress) external;

    // function setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external;

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    /// @notice Function to set the bridge fee.
    /// @dev Can only be called by resource setter.
    /// @param destinationChainID chainId for destination chain.
    /// @param feeTokenAddress address of the fee token.
    /// @param transferFee fee for cross-chain transfer.
    /// @param exchangeFee fee for cross-chain swaps.
    /// @param accepted true if the fee token is an accepted fee token.
    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag for burnanble status.
    function setBurnable(address contractAddress, bool status) external;

    /// @notice Used to manually release funds from ERC safes.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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