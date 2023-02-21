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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConnext} from "./interfaces/IConnext.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {AddressRegistry} from "./registry/AddressRegistry.sol";

/**
 * @title Connext L2 Bridge Contract
 * @author Nishay Madhani (@nshmadhani on Github, Telegram)
 * @notice You can use this contract to deposit funds into other L2's using connext
 * @dev  This Bridge is resposible for bridging funds from Aztec to L2 using Connext xCall.
 */
contract ConnextBridge {

    error InvalidDomainIndex();
    error InvalidConfiguration();
    error InvalidDomainID();

    IWETH public constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

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


    constructor(
        address _connext,
        address _registry
    ) {
        Connext = IConnext(_connext);
        Registry = AddressRegistry(_registry);
        maxRelayerFee = 0.01 ether;
    }

    receive() external payable {}

  
    function convert(
        uint256 _totalInputValue,
        uint64 _auxData,
        address
    )
        external
        payable
        returns (
            uint256,
            uint256,
            bool
        )
    {
        

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
    function addDomains(uint32[] calldata _domainIDs, address[] calldata _domainReceivers) external  {
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
    ) external  {
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
    ) external {
        maxRelayerFee = _maxRelayerFee;        
    }

    /**
     * @notice sets location for connext
     */
    function setConnext(
        address _newConnextAdrress
    ) external  {
        Connext = IConnext(_newConnextAdrress);       
    }

    /**
     * @notice sets which address registry to use
     */
    function setAddressRegistry(
        address _addressRegistry
    ) external  {
        Registry = AddressRegistry(_addressRegistry);
    }

    function _xTransfer(
        address _recipient,
        uint32 _destinationDomain,
        address _tokenAddress,
        uint256 _amount,
        uint256 _slippage,
        uint256 _relayerFee,
        bytes memory _callData
    ) public {

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

    function deposit(
        uint256 _totalInputValue,
        uint64 _auxData
    ) public payable {

        uint256 relayerFee = getRelayerFee(_auxData, maxRelayerFee);
        uint256 amount = _totalInputValue  - relayerFee;

        WETH.deposit{value: amount}();

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;


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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.0;

/**
 * @title Aztec Address Registry.
 * @author Josh Crites (@critesjosh on Github), Aztec team
 * @notice This contract can be used to anonymously register an ethereum address with an id.
 *         This is useful for reducing the amount of data required to pass an ethereum address through auxData.
 * @dev Use this contract to lookup ethereum addresses by id.
 */
contract AddressRegistry {
    uint256 public addressCount;
    mapping(uint256 => address) public addresses;

    event AddressRegistered(uint256 indexed index, address indexed entity);

    constructor() {}
    
    function registerAddress(address _to) public returns (uint256) {
        uint256 userIndex = addressCount++;
        addresses[userIndex] = _to;
        emit AddressRegistered(userIndex, _to);
        return userIndex;
    }
}