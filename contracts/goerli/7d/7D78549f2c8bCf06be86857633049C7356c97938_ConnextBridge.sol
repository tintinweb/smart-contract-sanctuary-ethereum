/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// Copyright 2022 Aztec

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
}

// Copyright 2022 Aztec.

library ErrorLib {
    error InvalidCaller();

    error InvalidInput();
    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error ApproveFailed(address token);
    error TransferFailed(address token);

    error InvalidNonce();
    error AsyncDisabled();
}

// Copyright 2022 Aztec.

// Copyright 2022 Aztec

interface IDefiBridge {
    /**
     * @notice A function which converts input assets to output assets.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _totalInputValue An amount of input assets transferred to the bridge (Note: "total" is in the name
     *                         because the value can represent summed/aggregated token amounts of users actions on L2)
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @return isAsync A flag indicating if the interaction is async.
     * @dev This function is called from the RollupProcessor contract via the DefiBridgeProxy. Before this function is
     *      called _RollupProcessor_ contract will have sent you all the assets defined by the input params. This
     *      function is expected to convert input assets to output assets (e.g. on Uniswap) and return the amounts
     *      of output assets to be received by the _RollupProcessor_. If output assets are ERC20 tokens the bridge has
     *      to _RollupProcessor_ as a spender before the interaction is finished. If some of the output assets is ETH
     *      it has to be sent to _RollupProcessor_ via the `receiveEthFromBridge(uint256 _interactionNonce)` method
     *      inside before the `convert(...)` function call finishes.
     * @dev If there are two input assets, equal amounts of both assets will be transferred to the bridge before this
     *      method is called.
     * @dev **BOTH** output assets could be virtual but since their `assetId` is currently assigned as
     *      `_interactionNonce` it would simply mean that more of the same virtual asset is minted.
     * @dev If this interaction is async the function has to return `(0,0 true)`. Async interaction will be finalised at
     *      a later time and its output assets will be returned in a `IDefiBridge.finalise(...)` call.
     *
     */
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _totalInputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address _rollupBeneficiary
    ) external payable returns (uint256 outputValueA, uint256 outputValueB, bool isAsync);

    /**
     * @notice A function that finalises asynchronous interaction.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @dev This function should use the `BridgeBase.onlyRollup()` modifier to ensure it can only be called from
     *      the `RollupProcessor.processAsyncDefiInteraction(uint256 _interactionNonce)` method.
     *
     */
    function finalise(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _interactionNonce,
        uint64 _auxData
    ) external payable returns (uint256 outputValueA, uint256 outputValueB, bool interactionComplete);
}

// Copyright 2022 Aztec

// @dev documentation of this interface is in its implementation (Subsidy contract)
interface ISubsidy {
    /**
     * @notice Container for Subsidy related information
     * @member available Amount of ETH remaining to be paid out
     * @member gasUsage Amount of gas the interaction consumes (used to define max possible payout)
     * @member minGasPerMinute Minimum amount of gas per minute the subsidizer has to subsidize
     * @member gasPerMinute Amount of gas per minute the subsidizer is willing to subsidize
     * @member lastUpdated Last time subsidy was paid out or funded (if not subsidy was yet claimed after funding)
     */
    struct Subsidy {
        uint128 available;
        uint32 gasUsage;
        uint32 minGasPerMinute;
        uint32 gasPerMinute;
        uint32 lastUpdated;
    }

    function setGasUsageAndMinGasPerMinute(uint256 _criteria, uint32 _gasUsage, uint32 _minGasPerMinute) external;

    function setGasUsageAndMinGasPerMinute(
        uint256[] calldata _criteria,
        uint32[] calldata _gasUsage,
        uint32[] calldata _minGasPerMinute
    ) external;

    function registerBeneficiary(address _beneficiary) external;

    function subsidize(address _bridge, uint256 _criteria, uint32 _gasPerMinute) external payable;

    function topUp(address _bridge, uint256 _criteria) external payable;

    function claimSubsidy(uint256 _criteria, address _beneficiary) external returns (uint256);

    function withdraw(address _beneficiary) external returns (uint256);

    // solhint-disable-next-line
    function MIN_SUBSIDY_VALUE() external view returns (uint256);

    function claimableAmount(address _beneficiary) external view returns (uint256);

    function isRegistered(address _beneficiary) external view returns (bool);

    function getSubsidy(address _bridge, uint256 _criteria) external view returns (Subsidy memory);

    function getAccumulatedSubsidyAmount(address _bridge, uint256 _criteria) external view returns (uint256);
}

/**
 * @title BridgeBase
 * @notice A base that bridges can be built upon which imports a limited set of features
 * @dev Reverts `convert` with missing implementation, and `finalise` with async disabled
 * @author Lasse Herskind
 */
abstract contract BridgeBase is IDefiBridge {
    error MissingImplementation();

    ISubsidy public constant SUBSIDY = ISubsidy(0xABc30E831B5Cc173A9Ed5941714A7845c909e7fA);
    address public immutable ROLLUP_PROCESSOR;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = _rollupProcessor;
    }

    modifier onlyRollup() {
        if (msg.sender != ROLLUP_PROCESSOR) {
            revert ErrorLib.InvalidCaller();
        }
        _;
    }

    function convert(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint256,
        uint64,
        address
    ) external payable virtual override(IDefiBridge) returns (uint256, uint256, bool) {
        revert MissingImplementation();
    }

    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint64
    ) external payable virtual override(IDefiBridge) returns (uint256, uint256, bool) {
        revert ErrorLib.AsyncDisabled();
    }

    /**
     * @notice Computes the criteria that is passed on to the subsidy contract when claiming
     * @dev Should be overridden by bridge implementation if intended to limit subsidy.
     * @return The criteria to be passed along
     */
    function computeCriteria(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint64
    ) public view virtual returns (uint256) {
        return 0;
    }
}

interface IConnext {

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);
  
}

// Copyright 2022 Aztec.

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// Copyright 2022 Aztec.

/**
 * @title Aztec Address Registry.
 * @author Josh Crites (@critesjosh on Github), Aztec team
 * @notice This contract can be used to anonymously register an ethereum address with an id.
 *         This is useful for reducing the amount of data required to pass an ethereum address through auxData.
 * @dev Use this contract to lookup ethereum addresses by id.
 */
contract AddressRegistry is BridgeBase {
    uint256 public addressCount;
    mapping(uint256 => address) public addresses;

    event AddressRegistered(uint256 indexed index, address indexed entity);

    /**
     * @notice Set address of rollup processor
     * @param _rollupProcessor Address of rollup processor
     */
    constructor(address _rollupProcessor) BridgeBase(_rollupProcessor) {}

    /**
     * @notice Function for getting VIRTUAL assets (step 1) to register an address and registering an address (step 2).
     * @dev This method can only be called from the RollupProcessor. The first step to register an address is for a user to
     * get the type(uint160).max value of VIRTUAL assets back from the bridge. The second step is for the user
     * to send an amount of VIRTUAL assets back to the bridge. The amount that is sent back is equal to the number of the
     * ethereum address that is being registered (e.g. uint160(0x2e782B05290A7fFfA137a81a2bad2446AD0DdFEB)).
     *
     * @param _inputAssetA - ETH (step 1) or VIRTUAL (step 2)
     * @param _outputAssetA - VIRTUAL (steps 1 and 2)
     * @param _totalInputValue - must be 1 wei (ETH) (step 1) or address value (step 2)
     * @return outputValueA - type(uint160).max (step 1) or 0 VIRTUAL (step 2)
     *
     */

    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 _totalInputValue,
        uint256,
        uint64,
        address
    ) external payable override (BridgeBase) onlyRollup returns (uint256 outputValueA, uint256, bool) {
        if (
            _inputAssetA.assetType == AztecTypes.AztecAssetType.NOT_USED
                || _inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20
        ) revert ErrorLib.InvalidInputA();
        if (_outputAssetA.assetType != AztecTypes.AztecAssetType.VIRTUAL) {
            revert ErrorLib.InvalidOutputA();
        }
        if (_inputAssetA.assetType == AztecTypes.AztecAssetType.ETH) {
            if (_totalInputValue != 1) {
                revert ErrorLib.InvalidInputAmount();
            }
            return (type(uint160).max, 0, false);
        } else if (_inputAssetA.assetType == AztecTypes.AztecAssetType.VIRTUAL) {
            address toRegister = address(uint160(_totalInputValue));
            registerAddress(toRegister);
            return (0, 0, false);
        } else {
            revert ErrorLib.InvalidInput();
        }
    }

    /**
     * @notice Register an address at the registry
     * @dev This function can be called directly from another Ethereum account. This can be done in
     * one step, in one transaction. Coming from Ethereum directly, this method is not as privacy
     * preserving as registering an address through the bridge.
     *
     * @param _to - The address to register
     * @return addressCount - the index of address that has been registered
     */

    function registerAddress(address _to) public returns (uint256) {
        uint256 userIndex = addressCount++;
        addresses[userIndex] = _to;
        emit AddressRegistered(userIndex, _to);
        return userIndex;
    }
}

/**
 * @title Connext L2 Bridge Contract
 * @author Nishay Madhani (@nshmadhani on Github, Telegram)
 * @notice You can use this contract to deposit funds into other L2's using connext
 * @dev  This Bridge is resposible for bridging funds from Aztec to L2 using Connext xCall.
 */
contract ConnextBridge is BridgeBase, Ownable{

    error InvalidDomainIndex();
    error InvalidConfiguration();
    error InvalidDomainID();

    IWETH public WETH;
    IConnext public Connext;
    AddressRegistry public Registry;

    /// @dev The following masks are used to decode slippage(bps), destination domain, 
    ///       relayerfee bps and destination address from 1 uint64
    
    /// Binary number 11111 (last 5 bits) from LSB
    uint64 public constant DEST_DOMAIN_MASK = 0x1F;
    uint64 public constant DEST_DOMAIN_LENGTH = 5;

    /// Binary number 111111111111111111111111 (next 24 bits)
    uint64 public constant TO_MASK = 0xFFFFFF;
    uint64 public constant TO_MASK_LENGTH = 24;

    /// Binary number 1111111111 (next 10 bits)
    uint64 public constant SLIPPAGE_MASK = 0x3FF;
    uint64 public constant SLIPPAGE_LENGTH = 10;

    /// Binary number 11111111111111 (next 14 bits)
    uint64 public constant RELAYED_FEE_MASK = 0x3FFF;
    uint64 public constant RELAYED_FEE_LENGTH = 14;

    uint32 public domainCount;
    mapping(uint32 => uint32) public domains;
    mapping(uint32 => address) public domainReceivers;

    uint256 public maxRelayerFee;

    /**
     * @notice Set address of rollup processor
     * @param _rollupProcessor Address of rollup processor
     */
    constructor(
        address _rollupProcessor,
        address _connext,
        address _registry,
        address _weth
    ) BridgeBase(_rollupProcessor) {
        Connext = IConnext(_connext);
        Registry = AddressRegistry(_registry);
        WETH = IWETH(_weth);
        maxRelayerFee = 0.01 ether;
    }

    receive() external payable {}

    /**
     * @notice A function which returns an _totalInputValue amount of _inputAssetA
     * @param _inputAssetA - Arbitrary ERC20 token
     * @param _totalInputValue - amount of _inputAssetA to bridge
     * @param _auxData - contains domainDestination, recepient, slippage, relayerFee
     * @return outputValueA - the amount of output asset to return
     * @dev
     */
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256 _totalInputValue,
        uint256,
        uint64 _auxData,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256,
            uint256,
            bool
        )
    {
        
        if (_inputAssetA.assetType != AztecTypes.AztecAssetType.ETH ) {
            revert ErrorLib.InvalidInputA();
        }

        uint256 relayerFee = getRelayerFee(_auxData, maxRelayerFee);
        uint256 amount = _totalInputValue  - relayerFee;

        WETH.deposit{value: amount}();

        _xTransfer(
            getDomainReceiver(_auxData),
            getDomainID(_auxData),
            address(WETH),
            amount,
            getSlippage(_auxData),
            relayerFee,
            abi.encodePacked(getDestinationAddress(_auxData))
        );

        return (0, 0, false);
    }

    /**
     * @notice Add a new domain to the mapping
     * @param _domainIDs new domains to be added to the end of the mapping
     * @param _domainReceivers receiver contracts on destination domains
     * @dev elements are included based on the domainCount variablle
     */
    function addDomains(uint32[] calldata _domainIDs, address[] calldata _domainReceivers) external onlyOwner {
        for (uint32 index = 0; index < _domainIDs.length; index++) {
            domains[domainCount] = _domainIDs[index];
            domainReceivers[_domainIDs[index]] = _domainReceivers[index];
            domainCount = domainCount + 1;
        }
    }

    /**
     * @notice Update domainIDs for each chain according to connext
     * @param _index index where domain is located in domains map
     * @param _newDomains new domainIDs
     * @param _domainReceivers new receiver contracts on destination domain
     * @dev 0th element in _index is key for 0th element in _newDomains for domains map
     */
    function updateDomains(
        uint32[] calldata _index,
        uint32[] calldata _newDomains,
        address[] calldata _domainReceivers
    ) external onlyOwner {
        if (_index.length != _newDomains.length ||  _newDomains.length != _domainReceivers.length) {
            revert InvalidConfiguration();
        }
        for (uint256 index = 0; index < _newDomains.length; index++) {
            if (_index[index] >= domainCount) {
                revert InvalidDomainIndex();
            }
            domains[_index[index]] = _newDomains[index];
            domainReceivers[_newDomains[index]] = _domainReceivers[index];
        }
    }

    /**
     * @notice sets maxRelayerFee which can be paid during bridge
     * @dev Should be set according to min relayerFee connext will charge for L2s(can be lower than cent)
     */
    function setMaxRelayerFee(
        uint256 _maxRelayerFee
    ) external onlyOwner {
        maxRelayerFee = _maxRelayerFee;        
    }

    /**
     * @notice sets location for connext
     */
    function setConnext(
        address _newConnextAdrress
    ) external onlyOwner {
        Connext = IConnext(_newConnextAdrress);       
    }

    /**
     * @notice sets which address registry to use
     */
    function setAddressRegistry(
        address _addressRegistry
    ) external onlyOwner {
        Registry = AddressRegistry(_addressRegistry);
    }

    /**
     * @notice Transfers funds from one chain to another.
     * @param _recipient The destination address: a receriver contract to split funds and do WETH -> ETH.
     * @param _destinationDomain The destination domain ID.
     * @param _tokenAddress Address of the token to transfer.
     * @param _amount The amount to transfer.
     * @param _slippage The maximum amount of slippage the user will accept in BPS.
     * @param _relayerFee The fee offered to relayers. On testnet, this can be 0.
     * @param _callData Call data(recepient address) for receiver contract on destiona tion china
          */
    function _xTransfer(
        address _recipient,
        uint32 _destinationDomain,
        address _tokenAddress,
        uint256 _amount,
        uint256 _slippage,
        uint256 _relayerFee,
        bytes memory _callData
    ) internal {
        IERC20(_tokenAddress).approve(address(Connext), _amount);
        Connext.xcall{value: _relayerFee}(
            _destinationDomain, // _destination: Domain ID of the destination chain
            _recipient, // _to: address contract receiving the funds on the destination
            _tokenAddress, // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            _amount, // _amount: amount of tokens to transfer
            _slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            _callData // _callData: will take in the destination
        );
    }

    /**
     * @notice Get DomainID from auxillary data
     * @param _auxData auxData param passed to convert() function
     * @dev appplied bit masking to retrieve first x bits to get index.
     *      The maps the index to domains map
     */
    function getDomainID(uint64 _auxData)
        public
        view
        returns (uint32 domainID)
    {
        uint32 domainIndex = uint32(_auxData & DEST_DOMAIN_MASK);

        if (domainIndex >= domainCount) {
            revert InvalidDomainID();
        }

        domainID = domains[domainIndex];
        if(domainID == 0) {
            revert InvalidDomainID();
        }
    }

/**
     * @notice Get Domain Receiver from auxillary data
     * @param _auxData auxData param passed to convert() function
     * @dev uses getDomainID to and then uses mapping
     */
    function getDomainReceiver(uint64 _auxData)
        public
        view
        returns (address receiverContract)
    {
        receiverContract = domainReceivers[getDomainID(_auxData)];
    }

    /**
     * @notice Get destination address from auxillary data
     * @param _auxData auxData param passed to convert() function
     * @dev applies bit shifting to first remove bits used by domainID,
     *      appplied bit masking to retrieve first x bits to get index.
     *      The maps the index to AddressRegistry
     */
    function getDestinationAddress(uint64 _auxData)
        public
        view
        returns (address destination)
    {
        _auxData = _auxData >> DEST_DOMAIN_LENGTH;
        uint64 toAddressID = (_auxData & TO_MASK);
        destination = Registry.addresses(toAddressID);
    }

    /**
     * @notice Get slippage from auxData
     * @param _auxData auxData param passed to convert() function
     * @dev applies bit shifting to first remove bits used by domainID, toAddress
     *      appplied bit masking to retrieve first x bits to get index.
     *      The maps the index to AddressRegistry
     */
    function getSlippage(uint64 _auxData)
        public
        pure
        returns (uint64 slippage)
    {
        _auxData = _auxData >> (DEST_DOMAIN_LENGTH + TO_MASK_LENGTH);
        slippage = (_auxData & SLIPPAGE_MASK);
    }

    /**
     * @notice Get relayer fee in basis points from auxData
     * @param _auxData auxData param passed to convert() function
     * @dev applies bit shifting to first remove bits used by domainID, toAddress, slippage
     *      appplied bit masking to retrieve first x bits to get index.
     *      The maps the index to AddressRegistry.
     *      
     */
    function getRelayerFee(uint64 _auxData, uint256 _maxRelayerFee)
        public
        pure
        returns (uint256 relayerFeeAmountsIn)
    {
        _auxData = _auxData >> (DEST_DOMAIN_LENGTH + TO_MASK_LENGTH + SLIPPAGE_LENGTH);
        uint256 relayerFeeBPS = (_auxData & RELAYED_FEE_MASK);
        if (relayerFeeBPS > 10_000) {
            relayerFeeBPS = 10_000;
        }
        relayerFeeAmountsIn = (relayerFeeBPS * _maxRelayerFee) / 10_000;
    }

}